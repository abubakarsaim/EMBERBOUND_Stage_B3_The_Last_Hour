extends "res://scripts/game_controller.gd"
const ARRIVAL := [
	["PRINCESS","You came..."],
	["KNIGHT","I promised I would find you."],
	["PRINCESS","Come to the throne. Only you can free me."]]
const RESCUE := [
	["PRINCESS","The royal altar can free me. Surrender your flame there, and our suffering will end."],
	["KNIGHT","Then let the kingdom's light guide us. I will examine it."]]
const WARNING := [
	["KNIGHT","Darkness is flowing TOWARD the ember. This altar would swallow the last light..."],
	["KNIGHT","The old mirror reveals borrowed faces. I must restore its light before I trust her."]]
const EXPOSURE := [
	["FALSE PRINCESS","Turn that light away! Your ember belongs to the Hourkeeper."],
	["KNIGHT","An imitation. I must kindle the royal seal, draw her shadow into it, then hold it in time."]]
const TRUTH := [
	["FALSE PRINCESS","You broke the borrowed face. But she still waits beyond the last hour."],
	["KNIGHT","The real princess is alive?"],
	["FALSE PRINCESS","Bound to the Eternal Flame. The Hourkeeper imprisons her and chains the kingdom's dawn to his clock."],
	["KNIGHT","The royal sigil is free. It will open his chamber. Hold on... I am coming."]]
var cinematic_mode: String = ""
var cinematic_time: float = 0
var camera_from := Vector2.ZERO
var intro_seen: bool = false
var return_zoom: float = 0.5
var transition_pending: bool = false
var nav_timer: float = 0
var route_points := PackedVector2Array()
var step_timer: float = 0
var reveal_flash_done: bool = false
var hall_elapsed: float = 0
var reveal_wash: ColorRect
var read_grace: float = 5
var apparition_trail_timer: float = 0
var last_apparition_stamp := Vector2.INF
var sigil_flight: float = 0
@onready var princess: Node2D = $World/Princess
@onready var dialogue: CanvasLayer = $Dialogue
@onready var intro_camera: Camera2D = $World/IntroCamera
@onready var encounter: Node2D = $World/ApparitionEncounter

func _ready() -> void:
	super._ready()
	var incoming: bool = Journey.arriving_hall
	Journey.arriving_hall = false
	Journey.apply_audio(audio)
	hud.music_slider.value = audio.music_volume
	hud.sfx_slider.value = audio.sfx_volume
	princess.viewer = player
	princess.home = world.PRINCESS
	corruption.walk_bounds = world.BOUNDS
	corruption.sacred_test = world.is_protected
	effects.controller = self
	puzzle.mission_changed.connect(on_mission_changed)
	puzzle.mirror_restored.connect(on_mirror_restored)
	puzzle.seal_ignited.connect(on_seal_ignited)
	puzzle.revelation_started.connect(on_revelation_started)
	encounter.charging.connect(func(_target: Vector2):
		audio.play_cue("charge")
		hud.notify("Her red mark locks your position. Sidestep the flare; she must recover after firing."))
	encounter.fired.connect(on_flare_fired)
	encounter.cancelled.connect(func(): audio.cancel_charge())
	dialogue.advanced.connect(advance_dialogue)
	dialogue.skipped.connect(skip_scene)
	var layer_fx := CanvasLayer.new()
	layer_fx.layer = 3
	add_child(layer_fx)
	reveal_wash = ColorRect.new()
	reveal_wash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	reveal_wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reveal_wash.color = Color(0.015,0.005,0.035,0)
	layer_fx.add_child(reveal_wash)
	var camera: Camera2D = player.get_node("Camera2D")
	camera.limit_right = 3072
	camera.limit_bottom = 2496
	camera.offset = Vector2(0,-110)
	restore_run(false)
	flame.reset(Journey.carried_flame if incoming else 100)
	player.flame_strength = flame.value
	audio.play_cue("royal_door")

func start_new_game() -> void:
	if Journey.campaign:
		Journey.begin_forest = true
		return_to_title()
		return
	puzzle.reset()
	intro_seen = false
	Journey.royal_solved = false
	Journey.next_chapter = ""
	restore_run(false)

func restore_run(_at_checkpoint: bool) -> void:
	puzzle.clear_temporary()
	get_tree().paused = false
	projectiles.clear()
	audio.reset_transients()
	dialogue.close()
	cinematic_mode = ""
	transition_pending = false
	low_warning_remaining = 0
	was_frozen = false
	reveal_flash_done = false
	read_grace = 5
	sigil_flight = 0
	corruption.clear()
	effects.clear()
	flame.reset()
	time_power.reset()
	sync_world()
	world.set_exit_open(puzzle.gate_unlocked)
	checkpoint_active = true
	checkpoint_solved = puzzle.solved
	player.global_position = puzzle.checkpoint_position
	player.velocity = Vector2.ZERO
	player.invulnerable = 1.5
	player.flame_strength = 100
	player.active = true
	shadow.reset(Vector2(1100,2060))
	shadow.navigation_direction = Vector2.ZERO
	shadow.pursuit_speed_scale = 1
	shadow.attack_cooldown = 10
	shadow.active = not puzzle.mirror_lit and not puzzle.solved
	shadow.visible = shadow.active
	princess.global_position = world.PRINCESS
	princess.revealed = puzzle.mirror_lit
	princess.visible = not puzzle.solved
	princess.exposed = puzzle.mirror_lit
	princess.distortion = 0
	princess.frozen = false
	princess.approach = false
	princess.hostile = puzzle.mirror_lit and not puzzle.solved
	princess.modulate.a = 1
	princess.reset_physics_interpolation()
	encounter.reset(princess.hostile)
	player.reset_visuals()
	intro_camera.enabled = false
	var camera: Camera2D = player.get_node("Camera2D")
	camera.offset = Vector2(0,-110)
	camera.make_current()
	camera.reset_smoothing()
	camera.force_update_scroll()
	flow = Flow.PLAYING
	audio.set_flow("playing")
	audio.narrative = false
	hud.hide_screen()
	presentation.start_fade()
	nav_timer = 0
	route_points.clear()
	step_timer = 0
	apparition_trail_timer = 0
	last_apparition_stamp = Vector2.INF
	if not intro_seen and puzzle.phase==puzzle.Phase.RESCUE: begin_intro()
	else: hud.notify("Checkpoint restored: completed missions, reflector angles and the seal are remembered.")

func sync_world() -> void:
	world.encounter_active = puzzle.mirror_lit and not puzzle.solved
	world.seal_armed = puzzle.seal_armed
	world.cleansed = puzzle.solved
	world.light_court = puzzle.phase>=puzzle.Phase.MIRROR

func restart_checkpoint() -> void:
	if not transition_pending: restore_run(true)

func begin_intro() -> void:
	if puzzle.phase>puzzle.Phase.MIRROR or transition_pending or flow not in [Flow.PLAYING,Flow.PAUSED]: return
	get_tree().paused = false
	flow = Flow.PLAYING
	hud.hide_screen()
	dialogue.close()
	player.active = false
	player.velocity = Vector2.ZERO
	shadow.active = false
	projectiles.clear(false)
	audio.cancel_charge()
	audio.set_flow("playing")
	audio.narrative = true
	cinematic_mode = "pan"
	cinematic_time = 0
	camera_from = player.global_position+Vector2(0,-110)
	intro_camera.enabled = true
	intro_camera.global_position = camera_from
	intro_camera.zoom = Vector2.ONE
	intro_camera.make_current()

func advance_cinematic(delta: float) -> void:
	cinematic_time += delta
	if cinematic_mode=="pan":
		var t := clampf(cinematic_time/1.35,0,1)
		intro_camera.global_position = camera_from.lerp(Vector2(1536,600),t*t*(3-2*t))
		intro_camera.zoom = Vector2.ONE*lerpf(1,0.5,t*t*(3-2*t))
		if t>=1:
			cinematic_mode = "arrival"
			dialogue.begin(ARRIVAL,"arrival")
			audio.play_cue("dialogue")
	elif cinematic_mode=="return":
		var t := clampf(cinematic_time/0.6,0,1)
		intro_camera.global_position = camera_from.lerp(player.global_position+Vector2(0,-110),t*t*(3-2*t))
		intro_camera.zoom = Vector2.ONE*lerpf(return_zoom,1.0,t*t*(3-2*t))
		if t>=1:
			intro_camera.enabled = false
			var camera: Camera2D = player.get_node("Camera2D")
			camera.make_current()
			camera.reset_smoothing()
			cinematic_mode = ""
			intro_seen = true
			player.active = true
			shadow.active = not puzzle.mirror_lit and not puzzle.solved
			audio.narrative = false
			hud.notify("CURRENT MISSION / Follow the highlighted goal. E speaks or examines; the mission journal tracks your progress.")

func _physics_process(delta: float) -> void:
	if flow!=Flow.PLAYING or transition_pending: return
	if cinematic_mode!="":
		advance_cinematic(delta)
		return
	hall_elapsed += delta
	read_grace = maxf(0,read_grace-delta)
	was_frozen = time_power.freeze_remaining>0
	time_power.tick(delta)
	if was_frozen and time_power.freeze_remaining<=0: audio.play_cue("time_end")
	sync_world()
	if puzzle.phase!=puzzle.Phase.REVEALING: flame.tick(delta,world.is_protected(player.global_position))
	if flow!=Flow.PLAYING: return
	player.flame_strength = flame.value
	var protected: bool = world.is_protected(player.global_position) or read_grace>0 or puzzle.phase==puzzle.Phase.REVEALING
	shadow.sanctuary_active = protected
	shadow.sanctuary = player.global_position
	shadow.attacks_suppressed = protected
	if shadow.active:
		nav_timer -= delta
		if nav_timer<=0:
			route_points = world.route(shadow.global_position,player.global_position)
			nav_timer = 0.35
		while route_points.size()>0 and shadow.global_position.distance_to(route_points[0])<40: route_points.remove_at(0)
		shadow.navigation_direction = shadow.global_position.direction_to(route_points[0]) if route_points.size()>0 else Vector2.ZERO
		shadow.tick(delta)
	princess.frozen = time_power.freeze_remaining>0
	princess.tick(delta,world.SEAL)
	if puzzle.phase==puzzle.Phase.ENCOUNTER:
		encounter.tick(delta,princess,player,time_power,puzzle.seal_armed,protected)
		apparition_trail_timer -= delta
		if not princess.frozen and apparition_trail_timer<=0 and princess.global_position.distance_to(last_apparition_stamp)>9:
			corruption.stamp(princess.global_position)
			last_apparition_stamp = princess.global_position
			apparition_trail_timer = 0.12
	projectiles.tick(delta,time_power.freeze_remaining>0,player,protected)
	if flow!=Flow.PLAYING: return
	corruption.tick(delta)
	puzzle.tick(delta,player,princess,time_power)
	puzzle.update_feedback(player.global_position,shadow)
	princess.exposed = puzzle.mirror_lit
	if puzzle.phase==puzzle.Phase.REVEALING:
		var progress: float = 1-puzzle.reveal_remaining/2.6
		princess.distortion = progress
		princess.modulate.a = 1-clampf((progress-0.55)/0.45,0,1)
		if progress>0.42 and not reveal_flash_done:
			reveal_flash_done = true
			effects.burst(princess.global_position-Vector2(0,60),Color("a53159"),60)
			effects.wave(world.SEAL,Color("8be7eb"),360)
		var camera: Camera2D = player.get_node("Camera2D")
		camera.offset = Vector2(0,lerpf(-110,-180,clampf(progress*3,0,1)))+Vector2(sin(progress*31),cos(progress*27))*sin(progress*PI)*1.8
	low_warning_remaining = maxf(0,low_warning_remaining-delta)
	if flame.value<25 and low_warning_remaining<=0:
		audio.play_cue("low_flame")
		low_warning_remaining = 8
	step_timer = maxf(0,step_timer-delta)
	if player.active and player.velocity.length()>60 and step_timer<=0:
		audio.play_cue("step")
		step_timer = 0.4
	if puzzle.gate_unlocked and player.global_position.distance_to(world.EXIT)<65: finish_chapter()

func _process(delta: float) -> void:
	if flow==Flow.PLAYING: sigil_flight = maxf(0,sigil_flight-delta)
	super._process(delta)
	if not is_instance_valid(princess): return
	dialogue.box.visible = dialogue.active and flow==Flow.PLAYING
	var enemy: Vector2 = princess.global_position if encounter.active else shadow.global_position
	var danger: float = clampf(1-player.global_position.distance_to(enemy)/440,0,1)
	if cinematic_mode!="" or world.is_protected(player.global_position) or read_grace>0: danger = 0
	audio.set_context(danger,0.35,time_power.freeze_remaining>0)
	audio.revelation = puzzle.phase in [puzzle.Phase.ENCOUNTER,puzzle.Phase.REVEALING]
	if reveal_wash!=null:
		var progress: float = 1-puzzle.reveal_remaining/2.6 if puzzle.phase==puzzle.Phase.REVEALING else 0
		reveal_wash.color.a = sin(progress*PI)*0.34

func interact() -> void:
	if cinematic_mode!="" or puzzle.phase==puzzle.Phase.REVEALING: return
	var at: Vector2 = player.global_position
	if at.distance_to(world.CHECKPOINT)<120 or at.distance_to(world.CLOCK)<120:
		flame.reset()
		audio.play_cue("checkpoint")
		hud.notify("A sacred refuge rekindles your ember. Fire reveals truth; Time gives your hand the chance to break it.")
		return
	if at.distance_to(puzzle.GATE)<115:
		if puzzle.unlock_gate():
			world.set_exit_open(true)
			audio.play_cue("passage")
			effects.wave(Vector2(2755,580),Color("ffe1a0"),220)
			effects.announce(at,"ROYAL SIGIL / THE WAY OPENS",Color("ffdfa1"))
			hud.notify("The released sigil opens the Hourkeeper's chamber. Cross the doorway. Passage checkpoint saved.")
		else: hud.notify("The passage recognizes only a freed royal sigil. Break the false princess's illusion to release it." if not puzzle.gate_unlocked else "The sigil has opened the passage. Continue EAST through the doorway.")
		return
	if at.distance_to(princess.global_position)<135 and puzzle.phase==puzzle.Phase.RESCUE:
		puzzle.ask_for_flame()
		begin_conversation(RESCUE,"rescue")
		return
	if at.distance_to(puzzle.ALTAR)<110 and (puzzle.phase<=puzzle.Phase.ALTAR or at.distance_to(puzzle.ALTAR)<=at.distance_to(puzzle.SOURCE)):
		if puzzle.phase==puzzle.Phase.RESCUE:
			hud.notify("The princess waits by the throne NORTH. Speak to her before trusting her altar.")
		elif puzzle.phase==puzzle.Phase.ALTAR:
			puzzle.examine_altar()
			audio.play_cue("distort")
			effects.burst(puzzle.ALTAR,Color("652141"),26)
			begin_conversation(WARNING,"warning")
		else: hud.notify("Dark veins converge on the empty altar. You were right to keep the flame. The mirror can expose the deception.")
		return
	var old_rotation: Array = puzzle.rotations.duplicate()
	var was_lit: bool = puzzle.mirror_lit
	var reply: String = puzzle.interact(at,time_power,flame,princess.global_position)
	if old_rotation!=puzzle.rotations:
		audio.play_cue("royal_seal")
		effects.wave(at,Color("deb978"),55)
	if was_lit and at.distance_to(world.MIRROR)<110:
		read_grace = maxf(read_grace,3)
		projectiles.clear(false)
	hud.notify(reply)

func on_mission_changed() -> void:
	sync_world()
	read_grace = 5
	projectiles.clear(false)
	audio.cancel_charge()
	effects.wave(player.global_position,Color("d8c28d"),75)
	hud.notify("MISSION UPDATED / "+puzzle.goal_name()+". Checkpoint saved; completed steps are remembered.")

func on_mirror_restored() -> void:
	shadow.active = false
	shadow.visible = false
	princess.revealed = true
	princess.exposed = true
	princess.hostile = true
	encounter.reset(true)
	flame.restore(maxf(25,65-flame.value))
	audio.play_cue("mirror")
	audio.play_cue("distort")
	effects.wave(world.MIRROR,Color("8be7eb"),240)
	effects.burst(princess.global_position-Vector2(0,60),Color("a53159"),40)
	begin_conversation(EXPOSURE,"exposure")

func on_seal_ignited() -> void:
	sync_world()
	read_grace = 5
	projectiles.clear(false)
	audio.cancel_charge()
	audio.play_cue("royal_seal")
	effects.wave(world.SEAL,Color("93ebec"),puzzle.RADIUS)
	effects.announce(world.SEAL,"FIRE BINDS / TIME HOLDS",Color("b4e9e9"))

func on_lamp_lit() -> void:
	audio.play_cue("lamp")
	effects.burst(puzzle.SOURCE-Vector2(0,25),Color("ffe1a0"),24)

func on_revelation_started() -> void:
	player.active = false
	player.velocity = Vector2.ZERO
	shadow.active = false
	encounter.active = false
	projectiles.clear(false)
	audio.cancel_charge()
	audio.play_cue("distort")
	effects.burst(princess.global_position-Vector2(0,55),Color("c9a67b"),28)

func on_puzzle_completed() -> void:
	checkpoint_active = true
	checkpoint_solved = true
	Journey.royal_solved = true
	sync_world()
	shadow.active = false
	shadow.visible = false
	encounter.active = false
	projectiles.clear(false)
	corruption.clear()
	princess.visible = false
	sigil_flight = 2
	flame.restore(35)
	audio.play_cue("reveal")
	effects.wave(world.SEAL,Color("ffdda0"),420)
	effects.burst(princess.global_position-Vector2(0,60),Color("ffd88d"),32)
	begin_conversation(TRUTH,"truth")

func begin_conversation(lines: Array, kind: String) -> void:
	cinematic_mode = kind
	player.active = false
	player.velocity = Vector2.ZERO
	shadow.active = false
	projectiles.clear(false)
	audio.cancel_charge()
	audio.narrative = true
	dialogue.begin(lines,kind)
	audio.play_cue("dialogue")

func advance_dialogue() -> void:
	if flow!=Flow.PLAYING or not dialogue.active: return
	audio.play_cue("dialogue")
	if dialogue.next(): end_dialogue()

func end_dialogue() -> void:
	if cinematic_mode=="arrival" or cinematic_mode=="pan":
		cinematic_mode = "return"
		cinematic_time = 0
		camera_from = intro_camera.global_position
		return_zoom = intro_camera.zoom.x
	else:
		cinematic_mode = ""
		player.active = true
		shadow.active = not puzzle.mirror_lit and not puzzle.solved
		audio.narrative = false
		read_grace = 5
		if puzzle.solved:
			player.get_node("Camera2D").create_tween().tween_property(player.get_node("Camera2D"),"offset",Vector2(0,-110),0.45)
			hud.notify("The real princess is alive. Her released sigil rides your flame. Take it EAST to the sealed passage [E].")

func skip_scene() -> void:
	if dialogue.active or cinematic_mode=="pan":
		dialogue.close()
		end_dialogue()

func _unhandled_input(event: InputEvent) -> void:
	if transition_pending or (event is InputEventKey and event.echo): return
	if event.is_action_pressed("skip_scene") and flow==Flow.PLAYING:
		skip_scene()
		return
	if event.is_action_pressed("replay_intro"):
		if puzzle.phase<=puzzle.Phase.MIRROR: begin_intro()
		else: hud.notify("The imitation is exposed. Complete the current mission; R restores your latest checkpoint.")
		return
	if flow==Flow.PLAYING and cinematic_mode!="":
		if event.is_action_pressed("interact") or event.is_action_pressed("confirm"):
			if cinematic_mode=="pan":
				cinematic_mode = "arrival"
				dialogue.begin(ARRIVAL,"arrival")
			else: advance_dialogue()
		elif event.is_action_pressed("pause") or event.is_action_pressed("restart") or event.is_action_pressed("mute"): super._unhandled_input(event)
		return
	if flow==Flow.PLAYING and event.is_action_pressed("borrow_time"):
		var response: String = time_power.try_activate(flame)
		if response.begins_with("Time stands"):
			response = "Time is held. At the royal seal [E], bind the exposed shadow INSIDE its cyan ring." if puzzle.phase==puzzle.Phase.ENCOUNTER else "Time holds the hunter and every active flare. Keep your ember safe."
		hud.notify(response)
		return
	super._unhandled_input(event)

func on_time_activated() -> void:
	super.on_time_activated()
	if is_instance_valid(princess): princess.frozen = true

func on_shadow_struck() -> void:
	if cinematic_mode=="" and read_grace<=0 and not world.is_protected(player.global_position): super.on_shadow_struck()

func on_flare_hit(amount: float, at: Vector2) -> void:
	if cinematic_mode!="" or read_grace>0: return
	super.on_flare_hit(amount,at)

func on_flare_charging(target: Vector2) -> void:
	shadow.attack_cooldown = 10
	super.on_flare_charging(target)

func return_to_title() -> void:
	Journey.remember(audio)
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/forest.tscn")

func context_hint() -> String:
	if cinematic_mode!="": return "[E / Enter] Continue dialogue   •   [Q] Skip   •   [Esc] Pause / read in safety"
	var at: Vector2 = player.global_position
	if puzzle.phase==puzzle.Phase.REVEALING: return "The illusion breaks. Her stolen royal sigil is returning to the Eternal Flame."
	if at.distance_to(world.CLOCK)<125 or at.distance_to(world.CHECKPOINT)<125: return "[E] Rekindle to 100 flame / Refuge. Completed mission steps survive R retry."
	if at.distance_to(puzzle.GATE)<115:
		if puzzle.gate_unlocked: return "The passage is open. Cross the doorway EAST; the real princess waits beyond."
		return "[E] Use the released royal sigil / Open the Hourkeeper's chamber" if puzzle.sigil_released else "The Hourkeeper's passage requires a freed royal sigil. Follow your current mission."
	if at.distance_to(princess.global_position)<140 and puzzle.phase==puzzle.Phase.RESCUE: return "[E] Speak to the princess. Find out how to free her."
	if at.distance_to(puzzle.ALTAR)<110 and (puzzle.phase<=puzzle.Phase.ALTAR or at.distance_to(puzzle.ALTAR)<=at.distance_to(puzzle.SOURCE)): return "[E] Examine the royal altar. Keep your flame close; something is gathering in its cracks."
	if at.distance_to(puzzle.SOURCE)<110: return "[E] Kindle the light font / Restore flame once lit. Follow its beam toward the royal mirror."
	for i in range(2):
		if at.distance_to(puzzle.REFLECTORS[i])<100: return "[E] Rotate Reflector %s 45 degrees. Watch where the gold beam goes; line up the next receiver." % ["I","II"][i]
	if at.distance_to(world.MIRROR)<110:
		return "[E] Examine the illuminated reflection" if puzzle.mirror_powered else "The mirror needs living fire. Find the golden font; redirect its beam with two reflectors."
	if at.distance_to(world.SEAL)<110 and puzzle.phase==puzzle.Phase.ENCOUNTER:
		if not puzzle.seal_armed: return "[E] Kindle the royal seal. Fire draws the exposed apparition into its binding light."
		if princess.global_position.distance_to(world.SEAL)>puzzle.RADIUS-24: return "Wait in the gold heart. Draw her shadow INSIDE the cyan circle before spending Borrowed Time."
		if time_power.freeze_remaining>0: return "[E] BREAK THE ILLUSION NOW / Her shadow is held inside the seal"
		return "SHADOW INSIDE / [Space] hold her in time, then [E] break the illusion"
	if puzzle.solved: return "The real princess lives. Carry the freed sigil EAST to the Hourkeeper's door [E]."
	if puzzle.phase==puzzle.Phase.ALTAR: return "She asked for your flame at the altar. Go SOUTH along the carpet and examine it [E]."
	if puzzle.phase==puzzle.Phase.MIRROR and puzzle.no_progress>35: return "A tilted mirror turns a beam around a corner. Follow gold from the font to I, then II, then the royal mirror."
	return "Follow the mission marker: "+puzzle.goal_name()+". Gold/cyan objects respond to E."

func finish_chapter() -> void:
	if Journey.campaign:
		enter_hourkeeper()
		return
	if transition_pending: return
	transition_pending = true
	Journey.next_chapter = "hourkeeper_chamber"
	Journey.remember(audio)
	Journey.carried_flame = flame.value
	flow = Flow.PAUSED
	player.active = false
	projectiles.clear()
	audio.set_flow("transition")
	audio.play_cue("royal_door")
	get_tree().paused = true
	var veil := ColorRect.new()
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.color = Color(0.01,0.02,0.05,0)
	hud.add_child(veil)
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(veil,"color:a",1.0,0.7)
	await tween.finished
	veil.queue_free()
	transition_pending = false
	flow = Flow.SUCCESS
	audio.set_flow("success")
	hud.show_screen("success")

func enter_hourkeeper() -> void:
	if transition_pending:return
	transition_pending=true
	Journey.arriving_boss=true
	Journey.next_chapter="hourkeeper_chamber"
	Journey.carried_flame=flame.value
	Journey.remember(audio)
	flow=Flow.PAUSED
	player.active=false
	projectiles.clear()
	audio.set_flow("transition")
	get_tree().paused=true
	var veil:=ColorRect.new()
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.color=Color(0.01,0.02,0.05,0)
	hud.add_child(veil)
	var tween:=create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(veil,"color:a",1.0,0.7)
	await tween.finished
	get_tree().paused=false
	get_tree().change_scene_to_file("res://scenes/hourkeeper.tscn")
