extends "res://scripts/game_controller.gd"
## Chapter-specific orchestration; shared player, fire, combat, time and audio remain A3 systems.
const FOREST_START := Vector2(380,2000)
const COURT := Vector2(3970,1300)
const INSCRIPTIONS := [
	"I / ROOT. First, remember the roots that held our kingdom. The bell follows to the northeast.",
	"II / BELL. Second, hear the bell that mourned the sun. Seek the royal tomb to the southeast.",
	"III / CROWN. Last, carry the crown beyond the dark. Three flames remember: ROOT > BELL > CROWN."
]
var elapsed: float = 0
var navigation_timer: float = 0
var hunter_route := PackedVector2Array()
var clue_readings: int = 0
var transition_pending: bool = false
var footsteps: float = 0
var story_line: String = "Aurelion has lost the sun. You carry its last, dwindling flame."
@onready var stones: Array = [$World/RootRune,$World/BellRune,$World/CrownRune]

func _ready() -> void:
	super._ready()
	Journey.arriving = false
	Journey.apply_audio(audio)
	hud.music_slider.value = audio.music_volume
	hud.sfx_slider.value = audio.sfx_volume
	hud.shrine_test_requested.connect(test_shrine)
	hud.hall_test_requested.connect(test_hall)
	hud.boss_test_requested.connect(test_boss)
	puzzle.wrong_order.connect(func():
		audio.play_cue("wrong")
		effects.wave(puzzle.global_position,Color("bb628d"),170))
	corruption.walk_bounds = world.BOUNDS
	corruption.sacred_test = world.is_protected
	corruption.sanctuary = FOREST_START
	for stone in stones: stone.viewer = player
	var camera: Camera2D = player.get_node("Camera2D")
	camera.limit_right = 4608
	camera.limit_bottom = 2816
	player.global_position = FOREST_START
	player.reset_physics_interpolation()
	shadow.global_position = FOREST_START-Vector2(240,0)
	shadow.reset_physics_interpolation()
	camera.reset_smoothing()
	if Journey.begin_forest:
		Journey.begin_forest = false
		start_new_game()

func start_new_game() -> void:
	Journey.campaign = true
	Journey.completed = false
	Journey.arriving_boss = false
	Journey.royal_solved = false
	Journey.next_chapter = ""
	checkpoint_active = true
	checkpoint_solved = false
	puzzle.discovered.fill(false)
	puzzle.reset()
	for stone in stones: stone.discovered = false
	elapsed = 0
	clue_readings = 0
	restore_run(false)

func restart_checkpoint() -> void:
	if not transition_pending: restore_run(true)

func restore_run(_at_checkpoint: bool) -> void:
	get_tree().paused = false
	projectiles.clear()
	audio.reset_transients()
	low_warning_remaining = 0
	was_frozen = false
	corruption.clear()
	effects.clear()
	flame.reset()
	time_power.reset()
	for i in range(world.torch_timers.size()): world.torch_timers[i] = 0
	world.checkpoint_lit = true
	world.set_exit_open(puzzle.solved)
	checkpoint_active = true
	checkpoint_solved = puzzle.solved
	player.global_position = COURT if puzzle.solved else FOREST_START
	player.velocity = Vector2.ZERO
	player.invulnerable = 1.5
	player.flame_strength = 100
	player.active = true
	shadow.active = true
	shadow.sanctuary_active = true
	shadow.sanctuary = player.global_position
	shadow.reset(player.global_position-Vector2(230,0))
	shadow.navigation_direction = Vector2.ZERO
	shadow.pursuit_speed_scale = 1.0
	hunter_route.clear()
	navigation_timer = 0
	footsteps = 0
	player.reset_visuals()
	shadow.reset_physics_interpolation()
	var camera: Camera2D = player.get_node("Camera2D")
	camera.force_update_scroll()
	camera.reset_smoothing()
	presentation.start_fade()
	flow = Flow.PLAYING
	audio.set_flow("playing")
	hud.hide_screen()
	hud.notify("Your journal and kindled braziers are remembered on retry. Begin along the broken road north.")

func _physics_process(delta: float) -> void:
	if flow != Flow.PLAYING or transition_pending: return
	elapsed += delta
	story_line = "Aurelion has lost the sun. You carry its last, dwindling flame."
	if elapsed>5: story_line = "Behind you, the Hourkeeper's hunter follows the light."
	if elapsed>10: story_line = "The princess waits beyond these ruins. Find the three forgotten flames."
	if elapsed>16: story_line = ""
	world.tick(delta)
	was_frozen = time_power.freeze_remaining>0
	time_power.tick(delta)
	if was_frozen and time_power.freeze_remaining<=0: audio.play_cue("time_end")
	var protected: bool = world.is_protected(player.global_position)
	flame.tick(delta,protected)
	if flow != Flow.PLAYING: return
	player.flame_strength = flame.value
	# Reading wards repel melee too; the hunter never parks over an essential interaction.
	shadow.sanctuary_active = protected
	shadow.sanctuary = player.global_position
	shadow.attacks_suppressed = protected
	navigation_timer -= delta
	if navigation_timer<=0:
		hunter_route = world.route(shadow.global_position,player.global_position)
		navigation_timer = 0.3
	while hunter_route.size()>0 and shadow.global_position.distance_to(hunter_route[0])<42:
		hunter_route.remove_at(0)
	shadow.navigation_direction = shadow.global_position.direction_to(hunter_route[0]) if hunter_route.size()>0 else Vector2.ZERO
	var chase_distance: float = shadow.global_position.distance_to(player.global_position)
	shadow.pursuit_speed_scale = move_toward(shadow.pursuit_speed_scale,2.7 if chase_distance>450 else 1.0,delta*1.8)
	shadow.tick(delta)
	projectiles.tick(delta,time_power.freeze_remaining>0,player,protected)
	if flow != Flow.PLAYING: return
	low_warning_remaining = maxf(0,low_warning_remaining-delta)
	if flame.value<25 and low_warning_remaining<=0:
		audio.play_cue("low_flame")
		low_warning_remaining = 8
	corruption.tick(delta)
	puzzle.update_feedback(player.global_position,shadow)
	for i in range(3):
		if not puzzle.discovered[i] and player.global_position.distance_to(stones[i].global_position)<maxf(76,player.torch_radius*0.74):
			discover(i)
	footsteps = maxf(0,footsteps-delta)
	if player.velocity.length()>60 and footsteps<=0:
		audio.play_cue("step")
		footsteps = 0.4
	if puzzle.solved and player.global_position.distance_to(world.EXIT)<50:
		enter_shrine()

func _process(delta: float) -> void:
	super._process(delta)
	if not is_instance_valid(player): return
	var near_fire: float = 0
	for i in range(world.TORCHES.size()):
		if world.torch_timers[i]>0: near_fire = maxf(near_fire,1-player.global_position.distance_to(world.TORCHES[i])/260)
	for lamp in puzzle.lamps:
		if lamp.lit: near_fire = maxf(near_fire,1-player.global_position.distance_to(lamp.global_position)/260)
	near_fire = maxf(near_fire,1-player.global_position.distance_to(FOREST_START)/230)
	var danger: float = clampf(1-player.global_position.distance_to(shadow.global_position)/330,0,1)
	if shadow.state==shadow.State.CHARGING: danger = 0.9
	if world.is_protected(player.global_position): danger *= 0.2
	audio.set_context(danger,near_fire,time_power.freeze_remaining>0)

func discover(index: int) -> void:
	puzzle.discovered[index] = true
	stones[index].discovered = true
	audio.play_cue("rune")
	effects.wave(stones[index].global_position,Color("8fe8e8"),115)
	effects.burst(stones[index].global_position-Vector2(0,40),Color("8fe8e8"),18)
	effects.announce(stones[index].global_position,"INSCRIPTION REMEMBERED",Color("b1f2ed"))
	hud.notify(INSCRIPTIONS[index])

func interact() -> void:
	for i in range(3):
		if player.global_position.distance_to(stones[i].global_position)<90:
			if not puzzle.discovered[i]: discover(i)
			clue_readings += 1
			hud.notify(INSCRIPTIONS[i])
			return
	if player.global_position.distance_to(FOREST_START)<90 or (puzzle.solved and player.global_position.distance_to(COURT)<76):
		flame.reset()
		audio.play_cue("checkpoint")
		hud.notify("The last watchfire restores your ember. FIRST the roots, SECOND the bell, LAST the crown.")
		effects.wave(player.global_position,Color("ffcf88"),100)
		return
	for i in range(world.TORCHES.size()):
		if player.global_position.distance_to(world.TORCHES[i])<72:
			if world.torch_timers[i]<2:
				world.torch_timers[i] = 18
				audio.play_cue("lamp")
				effects.burst(world.TORCHES[i]-Vector2(0,50),Color("ffd087"),16)
				hud.notify("Watchfire kindled: 18 seconds of refuge. Its warmth repels the hunter; your ember is unchanged.")
			else: hud.notify("The watchfire still burns. Its protection lasts %ds." % ceili(world.torch_timers[i]))
			return
	if player.global_position.distance_to(Vector2(1850,2050))<130:
		hud.notify("A deserted watch: 'We rang the bell at sunset. No dawn answered. Her crowned seal still shines to the southeast.'")
		return
	hud.notify(puzzle.interact(player.global_position,shadow,time_power))

func on_lamp_lit() -> void:
	audio.play_cue("lamp")
	var lamp: Node2D = puzzle.nearest_lamp(player.global_position)
	if lamp!=null:
		effects.burst(lamp.global_position-Vector2(0,50),Color("ffd28b"),22)
		effects.wave(lamp.global_position,Color("ffd28b"),92)
		effects.announce(lamp.global_position,"FIRE REMEMBERS",Color("ffe1ad"))

func on_puzzle_completed() -> void:
	checkpoint_active = true
	checkpoint_solved = true
	world.set_exit_open(true)
	projectiles.clear(false)
	shadow.cancel_ranged()
	audio.cancel_charge()
	flame.reset()
	audio.play_cue("gate")
	audio.play_cue("success")
	effects.wave(puzzle.global_position,Color("9ee8e5"),340)
	effects.burst(puzzle.global_position,Color("ffd48a"),48)
	effects.announce(puzzle.global_position,"HER SEAL ANSWERS / CHECKPOINT",Color("ffe1ac"))
	hud.notify("A crowned message glows: 'I am still here. Find the shrine. Bind his shadow.' Flame restored; checkpoint saved.")

func context_hint() -> String:
	if flow != Flow.PLAYING: return "CHAPTER I / THE CURSED FOREST"
	for i in range(3):
		if player.global_position.distance_to(world.CLUES[i])<100: return "[E] Read the inscription / Sacred ground holds the hunter back. Your journal remembers."
	if player.global_position.distance_to(FOREST_START)<90: return "[E] Rekindle / First the ROOT, then the BELL, last the CROWN. Follow the ruined road north."
	for i in range(world.TORCHES.size()):
		if player.global_position.distance_to(world.TORCHES[i])<72: return "[E] Kindle watchfire / Temporary refuge for 18 seconds / No flame cost"
	if player.global_position.distance_to(Vector2(1850,2050))<130: return "[E] Read the abandoned watch's last message"
	if puzzle.solved: return "A message bears the princess's seal. Follow the golden path EAST through the thorn gate."
	var lamp: Node2D = puzzle.nearest_lamp(player.global_position)
	if lamp!=null: return "[E] Kindle %s / Use the journal's FIRST > SECOND > LAST order" % ["ROOT","BELL","CROWN"][lamp.symbol]
	if not puzzle.discovered[0]: return "Find the root memorial NORTH of the last watchfire. Torchlight reveals its hidden symbol."
	if not puzzle.discovered[1]: return "Find the fallen bell tower to the NORTHEAST. Its inscription holds the second symbol."
	if not puzzle.discovered[2]: return "Find the royal tomb to the SOUTHEAST. The princess's crown is the last symbol."
	return "All symbols remembered. Follow the ruins NORTHEAST to the three braziers and the thorn gate."

func enter_shrine() -> void:
	if transition_pending: return
	transition_pending = true
	Journey.campaign = true
	Journey.arriving = true
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
	veil.mouse_filter = Control.MOUSE_FILTER_STOP
	hud.add_child(veil)
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(veil,"color:a",1.0,0.65)
	await tween.finished
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func test_shrine() -> void:
	Journey.campaign = false
	Journey.arriving = true
	Journey.carried_flame = 100
	Journey.remember(audio)
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func on_shadow_struck() -> void:
	if not world.is_protected(player.global_position): super.on_shadow_struck()

func _unhandled_input(event: InputEvent) -> void:
	if not transition_pending: super._unhandled_input(event)

func test_hall() -> void:
	Journey.campaign = false
	Journey.royal_solved = false
	Journey.next_chapter = ""
	Journey.arriving_hall = true
	Journey.carried_flame = 100
	Journey.remember(audio)
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/royal_hall.tscn")

func test_boss() -> void:
	Journey.campaign=false
	Journey.completed=false
	Journey.royal_solved=true
	Journey.arriving_boss=true
	Journey.carried_flame=100
	Journey.remember(audio)
	get_tree().paused=false
	get_tree().change_scene_to_file("res://scenes/hourkeeper.tscn")
