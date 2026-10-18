extends Node
## Owns game flow and wires small independent gameplay systems together.
enum Flow { MENU, PLAYING, PAUSED, FAILURE, SUCCESS }
const START := Vector2(300, 540)
const CHECKPOINT := Vector2(800, 540)
const HUNTER_START := Vector2(130, 540)
var flow: Flow = Flow.MENU
var checkpoint_active: bool = false
var checkpoint_solved: bool = false
var low_warning_remaining: float = 0.0
var was_frozen: bool = false
var chapter_transition: bool = false
@onready var world: Node2D = $World
@onready var player: CharacterBody2D = $World/Knight
@onready var shadow: CharacterBody2D = $World/Shadow
@onready var puzzle: Node2D = $World/CircleOfLight
@onready var flame: Node = $Flame
@onready var time_power: Node = $BorrowedTime
@onready var hud: CanvasLayer = $HUD
@onready var audio: Node = $Audio
@onready var corruption: Node2D = $World/Corruption
@onready var effects: Node2D = $World/WorldEffects
@onready var presentation: CanvasLayer = $Presentation
@onready var projectiles: Node2D = $World/Projectiles

func _ready() -> void:
	corruption.hunter = shadow
	corruption.puzzle = puzzle
	effects.world = world
	effects.player = player
	effects.puzzle = puzzle
	presentation.controller = self
	shadow.knight = player
	shadow.flame = flame
	shadow.time_power = time_power
	shadow.flare_charging.connect(on_flare_charging)
	shadow.flare_fired.connect(on_flare_fired)
	shadow.flare_cancelled.connect(func(): audio.cancel_charge())
	projectiles.flame_hit.connect(on_flare_hit)
	projectiles.dissipated.connect(func(at: Vector2): effects.burst(at-Vector2(0,38),Color("7696bc"),5))
	hud.music_volume_changed.connect(func(value: float): audio.set_music_volume(value))
	hud.sfx_volume_changed.connect(func(value: float): audio.set_sfx_volume(value))
	flame.extinguished.connect(fail)
	shadow.struck.connect(on_shadow_struck)
	puzzle.completed.connect(on_puzzle_completed)
	puzzle.lamp_lit.connect(on_lamp_lit)
	time_power.activated.connect(on_time_activated)
	hud.start_requested.connect(start_new_game)
	hud.restart_requested.connect(restart_checkpoint)
	hud.resume_requested.connect(resume_game)
	hud.menu_requested.connect(return_to_title)
	show_menu()
	if Journey.arriving:
		Journey.arriving = false
		restore_run(false)
		flame.value = Journey.carried_flame
		player.flame_strength = flame.value
		Journey.apply_audio(audio)
		hud.music_slider.value = audio.music_volume
		hud.sfx_slider.value = audio.sfx_volume
		hud.notify("SHRINE OF LOST HOURS / The princess's seal has led you here.")

func return_to_title() -> void:
	if Journey.campaign:
		Journey.remember(audio)
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/forest.tscn")
	else:
		show_menu()

func _physics_process(delta: float) -> void:
	if flow != Flow.PLAYING:
		return
	was_frozen = time_power.freeze_remaining > 0
	time_power.tick(delta)
	if was_frozen and time_power.freeze_remaining <= 0:
		audio.play_cue("time_end")
	flame.tick(delta,world.is_protected(player.global_position))
	if flow != Flow.PLAYING:
		return
	player.flame_strength = flame.value
	shadow.attacks_suppressed = world.is_protected(player.global_position) or puzzle.solved
	shadow.tick(delta)
	projectiles.tick(delta,time_power.freeze_remaining>0,player,world.is_protected(player.global_position) or puzzle.solved)
	if flow != Flow.PLAYING:
		return
	low_warning_remaining = maxf(0,low_warning_remaining-delta)
	if flame.value < 25 and low_warning_remaining <= 0:
		audio.play_cue("low_flame")
		low_warning_remaining = 8.0
	corruption.tick(delta)
	puzzle.update_feedback(player.global_position,shadow)
	if not checkpoint_active and player.global_position.distance_to(CHECKPOINT) <= 64.0:
		checkpoint_active = true
		world.checkpoint_lit = true
		shadow.sanctuary_active = true
		flame.reset()
		effects.wave(CHECKPOINT,Color("ffce83"),100)
		effects.announce(CHECKPOINT,"EMBER RESTORED / CHECKPOINT",Color("ffe2a6"))
		hud.notify("Checkpoint lit. E here rekindles your flame. R returns here.")
		audio.play_cue("checkpoint")
	if puzzle.solved and player.global_position.distance_to(world.EXIT) < 46.0:
		win()

func _process(delta: float) -> void:
	if is_instance_valid(hud.root):
		hud.refresh(self,delta if flow == Flow.PLAYING else 0.0)
		var distance: float = player.global_position.distance_to(shadow.global_position)
		var danger: float = clampf(1.0-distance/320.0,0,1)*(0.45+0.55*(1-flame.value/100.0))
		if shadow.state == shadow.State.CHARGING or shadow.state == shadow.State.ATTACKING:
			danger = maxf(danger,0.9)
		if puzzle.solved:
			danger = 0
		var near_fire: float = 0
		for lamp in puzzle.lamps:
			if lamp.lit:
				near_fire = maxf(near_fire,1-player.global_position.distance_to(lamp.global_position)/260.0)
		audio.set_context(danger,near_fire,time_power.freeze_remaining>0)

func _unhandled_input(event: InputEvent) -> void:
	if chapter_transition: return
	if event is InputEventKey and event.echo:
		return
	if event.is_action_pressed("mute"):
		audio.toggle_mute()
		return
	if event.is_action_pressed("pause"):
		if flow == Flow.PLAYING:
			pause_game()
		elif flow == Flow.PAUSED:
			resume_game()
		return
	if event.is_action_pressed("restart") and flow != Flow.MENU:
		restart_checkpoint()
		return
	if flow != Flow.PLAYING:
		return
	if event.is_action_pressed("borrow_time"):
		var result: String = time_power.try_activate(flame)
		if flow == Flow.PLAYING:
			# Update immediately so Space then E in the same frame is fair.
			if time_power.freeze_remaining > 0.0:
				shadow.tick(0.0)
			hud.notify(result)
	if event.is_action_pressed("interact"):
		interact()

func interact() -> void:
	if player.global_position.distance_to(CHECKPOINT) < 78.0:
		flame.reset()
		audio.play_cue("checkpoint")
		hud.notify("The sanctuary rekindles your ember to 100.")
		effects.burst(CHECKPOINT-Vector2(0,20),Color("ffd181"),16)
		effects.announce(CHECKPOINT,"FLAME RESTORED",Color("ffdc9b"))
		return
	if not puzzle.solved:
		hud.notify(puzzle.interact(player.global_position,shadow,time_power))
	else:
		hud.notify("Follow the warm light through the eastern arch.")

func start_new_game() -> void:
	if Journey.campaign:
		Journey.begin_forest = true
		return_to_title()
		return
	checkpoint_active = false
	checkpoint_solved = false
	restore_run(false)

func restart_checkpoint() -> void:
	restore_run(checkpoint_active)

func restore_run(at_checkpoint: bool) -> void:
	get_tree().paused = false
	projectiles.clear()
	audio.reset_transients()
	low_warning_remaining = 0
	was_frozen = false
	corruption.clear()
	effects.clear()
	flame.reset()
	time_power.reset()
	puzzle.reset()
	world.checkpoint_lit = at_checkpoint
	shadow.sanctuary_active = at_checkpoint
	player.global_position = CHECKPOINT if at_checkpoint else START
	player.velocity = Vector2.ZERO
	player.invulnerable = 1.5
	player.flame_strength = 100.0
	player.active = true
	shadow.active = true
	shadow.reset(Vector2(560,540) if at_checkpoint else HUNTER_START)
	world.set_exit_open(false)
	# Solving commits a second checkpoint: the trap and gate remain solved on retry.
	if at_checkpoint and checkpoint_solved:
		for lamp in puzzle.lamps:
			lamp.lit = true
		puzzle.solved = true
		shadow.global_position = puzzle.global_position
		shadow.trap()
		world.set_exit_open(true)
	player.reset_visuals()
	shadow.reset_physics_interpolation()
	player.get_node("Camera2D").force_update_scroll()
	player.get_node("Camera2D").reset_smoothing()
	presentation.start_fade()
	flow = Flow.PLAYING
	audio.set_flow("playing")
	hud.hide_screen()
	hud.notify("The shrine lies east. Kindle the two western lamps [E]." if not checkpoint_solved else "Your sealed circle is saved. Reach the eastern arch.")

func show_menu() -> void:
	get_tree().paused = true
	flow = Flow.MENU
	audio.set_flow("menu")
	projectiles.clear()
	player.active = false
	shadow.active = false
	hud.show_screen("menu")

func pause_game() -> void:
	flow = Flow.PAUSED
	audio.set_flow("paused")
	get_tree().paused = true
	hud.show_screen("pause")

func resume_game() -> void:
	if flow != Flow.PAUSED:
		return
	flow = Flow.PLAYING
	audio.set_flow("playing")
	get_tree().paused = false
	hud.hide_screen()

func fail() -> void:
	if flow != Flow.PLAYING:
		return
	flow = Flow.FAILURE
	audio.set_flow("failure")
	audio.play_cue("failure")
	player.active = false
	get_tree().paused = true
	hud.show_screen("failure",checkpoint_active)

func win() -> void:
	if Journey.campaign:
		enter_royal_hall()
		return
	flow = Flow.SUCCESS
	audio.set_flow("success")
	get_tree().paused = true
	player.active = false
	audio.play_cue("success")
	hud.show_screen("success")

func on_shadow_struck() -> void:
	if player.invulnerable > 0.0 or flow != Flow.PLAYING:
		return
	player.invulnerable = 1.8
	player.hurt_feedback()
	effects.burst(player.global_position-Vector2(0,30),Color("ef5c64"),16)
	flame.spend(minf(22.0,flame.value))
	audio.play_cue("hurt")
	hud.notify("The hunter tears at the ember! -22 flame. Return to sanctuary or use Space.")

func on_puzzle_completed() -> void:
	checkpoint_active = true
	checkpoint_solved = true
	world.checkpoint_lit = true
	world.set_exit_open(true)
	projectiles.clear(false)
	audio.cancel_charge()
	audio.play_cue("lamp")
	audio.play_cue("gate")
	flame.restore(35.0)
	effects.wave(puzzle.global_position,Color("ffd084"),240)
	effects.burst(puzzle.global_position,Color("ffe2a4"),40)
	effects.announce(player.global_position,"SHADOW BOUND / +35 FLAME",Color("ffe3a4"))
	effects.announce(Vector2(1690,535),"THE WAY OPENS",Color("ffe3a4"))
	audio.play_cue("success")

func context_hint() -> String:
	if flow != Flow.PLAYING:
		return "EMBERBOUND  /  THE LAST HOUR"
	if player.global_position.distance_to(CHECKPOINT) < 78.0:
		return "[E] Rekindle to 100 flame   /   Checkpoint saved   /   The hunter cannot enter this light."
	if puzzle.solved:
		return "The barrier holds the shadow. Reach the glowing eastern arch to leave the shrine."
	var lamp: Node2D = puzzle.nearest_lamp(player.global_position)
	if lamp != null and not lamp.lit:
		if lamp.final_lamp:
			if puzzle.lit_count() < 2:
				return "The east lamp is the seal. Light the two western lamps first."
			if not puzzle.hunter_inside:
				return "Wait by this lamp. Lure the shadow fully inside the ring, then press Space."
			if time_power.freeze_remaining > 0.0:
				return "[E] SEAL THE CIRCLE NOW! The shadow is frozen inside."
			return "SHADOW INSIDE   >   [Space] Freeze   >   [E] Seal this lamp"
		return "[E] Kindle this lamp"
	if puzzle.lit_count() >= 2:
		return "Stand at the east lamp. Lure inside the ring > [Space] > [E]."
	return "Follow the path east. [E] lights the shrine's two western lamps."

func on_lamp_lit() -> void:
	audio.play_cue("lamp")
	var lamp: Node2D = puzzle.nearest_lamp(player.global_position)
	if lamp != null:
		effects.burst(lamp.global_position-Vector2(0,55),Color("ffd287"),24)
		effects.announce(lamp.global_position,"LAMP KINDLED",Color("ffe0a2"))

func on_time_activated() -> void:
	audio.play_cue("freeze")
	projectiles.freeze_now()
	player.cast_feedback()
	effects.wave(player.global_position,Color("81e6ef"),230)
	effects.burst(player.global_position-Vector2(0,40),Color("82e5ed"),28)

func on_flare_charging(_target: Vector2) -> void:
	audio.play_cue("charge")
	effects.announce(shadow.global_position,"SHADOW FLARE",Color("ed869d"))
	hud.notify("The shadow marks your position. Move away from the red sigil, or press Space.")

func on_flare_fired(origin: Vector2, target: Vector2) -> void:
	audio.cancel_charge()
	if projectiles.launch(origin,target):
		audio.play_cue("launch")
		effects.burst(origin-Vector2(0,38),Color("9f3a64"),10)

func on_flare_hit(amount: float, _at: Vector2) -> void:
	if flow != Flow.PLAYING or player.invulnerable > 0 or world.is_protected(player.global_position):
		return
	player.invulnerable = 1.15
	player.hurt_feedback()
	flame.spend(minf(amount,flame.value))
	player.flame_strength = flame.value
	var torch: Vector2 = player.torch_position()
	effects.burst(torch,Color("97345f"),18)
	effects.wave(torch,Color("c85876"),36)
	effects.announce(player.global_position,"-5 FLAME",Color("ef96a9"))
	audio.play_cue("impact")
	hud.notify("Shadow Flare scorches your light! -5 flame. Move off the marked position.")

func enter_royal_hall() -> void:
	if chapter_transition: return
	chapter_transition = true
	Journey.arriving_hall = true
	Journey.carried_flame = flame.value
	Journey.remember(audio)
	flow = Flow.PAUSED
	player.active = false
	shadow.active = false
	projectiles.clear()
	audio.set_flow("transition")
	get_tree().paused = true
	var veil := ColorRect.new()
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.color = Color(0.01,0.02,0.05,0)
	hud.add_child(veil)
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(veil,"color:a",1.0,0.65)
	await tween.finished
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/royal_hall.tscn")
