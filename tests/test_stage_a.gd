extends SceneTree
## Integration checks run the real scenes and physics, without test frameworks.
var game: Node
var passed: int = 0
var failed: int = 0
var logs: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, description: String) -> void:
	var line := ("PASS " if condition else "FAIL ") + description
	print(line)
	logs.append(line)
	if condition:
		passed += 1
	else:
		failed += 1

func frames(count: int) -> void:
	for i in range(count):
		await physics_frame
		await process_frame

func action(name: String) -> void:
	var event := InputEventAction.new()
	event.action = name
	event.pressed = true
	game._unhandled_input(event)

func release_movement() -> void:
	for name in ["move_left","move_right","move_up","move_down"]:
		Input.action_release(name)

func go_to(target: Vector2, max_frames: int = 900) -> bool:
	for i in range(max_frames):
		var offset: Vector2 = target-game.player.global_position
		if offset.length() < 7.0:
			release_movement()
			await frames(10)
			return true
		if game.flow != game.Flow.PLAYING:
			release_movement()
			return false
		release_movement()
		if absf(offset.x) > 5.0:
			Input.action_press("move_right" if offset.x > 0 else "move_left")
		if absf(offset.y) > 5.0:
			Input.action_press("move_down" if offset.y > 0 else "move_up")
		await frames(1)
	release_movement()
	return false

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await frames(4)
	check(game.flow == game.Flow.MENU and paused,"Title screen starts with gameplay paused")
	check(game.audio.cues.size() == 4,"Four core local audio mappings load without external downloads")
	game.audio.toggle_mute()
	check(game.audio.muted,"Mute disables sound cues")
	game.audio.toggle_mute()
	check(not game.audio.muted,"Unmute restores sound cues")
	# Keep this accelerated headless run silent; rendered QA exercises playback.
	game.audio.toggle_mute()
	var key_values := {"move_left":KEY_LEFT,"move_right":KEY_RIGHT,"move_up":KEY_UP,"move_down":KEY_DOWN}
	for name in key_values:
		var found := false
		for event in InputMap.action_get_events(name):
			if event is InputEventKey and event.physical_keycode == key_values[name]:
				found = true
		check(found,"Physical arrow mapping: " + name)
	game.start_new_game()
	await frames(5)
	check(game.flow == game.Flow.PLAYING and not paused,"Start enters playable state")
	# Actual Input movement, not direct position changes, verifies normalization.
	Input.action_press("move_right")
	await frames(20)
	check(absf(game.player.velocity.length()-220.0) < 0.1,"Cardinal speed reaches 220 px/s")
	Input.action_press("move_down")
	await frames(20)
	check(absf(game.player.velocity.length()-220.0) < 0.2,"Diagonal movement is normalized")
	release_movement()
	await frames(12)
	check(game.player.velocity.length() < 0.1,"Release decelerates to rest")
	game.player.global_position = Vector2(110,540)
	Input.action_press("move_left")
	await frames(60)
	release_movement()
	check(game.player.global_position.x >= 102.5,"Western environment collision blocks knight")
	game.pause_game()
	var before: float = game.flame.value
	var before_shadow: Vector2 = game.shadow.global_position
	await frames(60)
	check(game.flame.value == before and game.shadow.global_position == before_shadow,"Pause stops flame and enemy simulation")
	game.flame.reset(50)
	game.flame.tick(10,false)
	var exposed: float = game.flame.value
	game.flame.reset(50)
	game.flame.tick(10,true)
	check(is_equal_approx(exposed,47.5) and is_equal_approx(game.flame.value,49.0),"Protected drain is lower: 0.10 vs 0.25 per second")
	game.flame.restore(200)
	check(game.flame.value == 100.0,"Flame restoration clamps to 100")
	game.flame.reset(14)
	game.time_power.reset()
	game.time_power.try_activate(game.flame)
	check(game.flame.value == 14 and game.time_power.freeze_remaining == 0,"Insufficient flame rejects ability without cost")
	game.flame.reset(80)
	game.time_power.try_activate(game.flame)
	check(game.flame.value == 65 and game.time_power.freeze_remaining == 3.0,"Borrowed Time costs exactly 15 and lasts 3 seconds")
	game.time_power.try_activate(game.flame)
	check(game.flame.value == 65,"Cooldown rejects repeat activation without extra cost")
	game.resume_game()
	game.shadow.global_position = Vector2(450,540)
	game.shadow.tick(0)
	before_shadow = game.shadow.global_position
	await frames(120)
	check(game.shadow.global_position == before_shadow and game.shadow.state == game.shadow.State.FROZEN,"Frozen enemy remains stationary for first two seconds")
	await frames(75)
	check(game.time_power.freeze_remaining == 0 and game.shadow.state != game.shadow.State.FROZEN,"Enemy resumes when freeze expires")
	# A paused freeze must retain both timers.
	game.time_power.reset()
	game.time_power.try_activate(game.flame)
	game.pause_game()
	var remaining: float = game.time_power.freeze_remaining
	var cooldown: float = game.time_power.cooldown_remaining
	await frames(30)
	check(game.time_power.freeze_remaining == remaining and game.time_power.cooldown_remaining == cooldown,"Pause preserves freeze and cooldown timers")
	game.resume_game()
	game.flame.set_value(0)
	check(game.flow == game.Flow.FAILURE and paused,"Zero flame enters failure and pauses simulation")
	game.restart_checkpoint()
	check(game.flame.value == 100 and game.player.global_position == game.START,"Failure before checkpoint restarts at entrance with full flame")
	# Check boundary case: spending exactly the final 15 invokes normal failure.
	game.flame.reset(15)
	game.time_power.reset()
	action("borrow_time")
	check(game.flow == game.Flow.FAILURE,"Spending the last 15 flame triggers failure, never negative flame")
	game.start_new_game()
	await frames(5)
	# Low-flame attacks are telegraphed, do resource damage, and have a grace period.
	game.flame.reset(30)
	game.player.invulnerable = 0
	game.shadow.global_position = game.player.global_position+Vector2(25,0)
	game.shadow.grace = 0
	await frames(20)
	check(game.flame.value > 29.0 and game.shadow.attack_windup > 0.0,"Hunter telegraphs before attacking weak flame")
	await frames(25)
	check(game.flame.value < 9.0 and game.flame.value > 7.0,"Telegraphed attack removes 22 flame")
	game.start_new_game()
	await frames(5)
	# Full playthrough follows reachable waypoints with normal movement and real AI.
	check(await go_to(Vector2(800,540)),"Walk from entrance to sanctuary with real physics")
	check(game.checkpoint_active and game.world.checkpoint_lit,"Sanctuary automatically activates checkpoint")
	game.flame.reset(10)
	action("interact")
	check(game.flame.value == 100,"E at sanctuary replenishes flame to prevent resource softlock")
	game.flame.set_value(0)
	game.restart_checkpoint()
	check(game.player.global_position == game.CHECKPOINT and game.flame.value == 100,"Checkpoint retry restores location and full flame")
	await frames(5)
	check(await go_to(Vector2(1345,540)),"Final lamp reachable before puzzle completion")
	action("interact")
	check(not game.puzzle.lamps[2].lit,"Final lamp rejects activation before western lamps")
	check(await go_to(Vector2(1640,540)),"Approach closed exit")
	Input.action_press("move_right")
	await frames(50)
	release_movement()
	check(game.player.global_position.x < 1673.0,"Locked exit has real collision")
	game.restart_checkpoint()
	await frames(4)
	check(await go_to(Vector2(1100,435)),"Reach northwestern lamp")
	action("interact")
	check(game.puzzle.lit_count() == 1,"E lights first lamp")
	check(await go_to(Vector2(1100,645)),"Reach southwestern lamp")
	action("interact")
	check(game.puzzle.lit_count() == 2,"E lights second lamp")
	check(await go_to(Vector2(1350,540)),"Reach eastern seal lamp after both western lamps")
	for i in range(600):
		if game.puzzle.inside_ring(game.shadow.global_position):
			break
		await frames(1)
	check(game.puzzle.inside_ring(game.shadow.global_position),"Real shadow AI follows into the circle despite strong light avoidance")
	action("interact")
	check(not game.puzzle.solved,"Final lamp rejects mobile shadow inside ring")
	# Freeze outside must not satisfy the spatial requirement.
	game.pause_game()
	var inside_position: Vector2 = game.shadow.global_position
	game.shadow.global_position = Vector2(1000,540)
	game.time_power.reset()
	game.time_power.try_activate(game.flame)
	game.puzzle.interact(game.player.global_position,game.shadow,game.time_power)
	check(not game.puzzle.solved,"Frozen shadow outside ring cannot complete puzzle")
	game.shadow.global_position = inside_position
	game.time_power.reset()
	game.resume_game()
	var flame_before: float = game.flame.value
	action("borrow_time")
	action("interact")
	check(game.puzzle.solved and game.puzzle.lit_count() == 3,"Space then E traps shadow and lights final lamp")
	check(game.shadow.state == game.shadow.State.TRAPPED and game.world.gate_open,"Success traps hunter and opens exit")
	check(is_equal_approx(game.flame.value,minf(100,flame_before-15+35)),"Puzzle completion restores 35 flame with clamping")
	game.restart_checkpoint()
	await frames(5)
	check(game.puzzle.solved and game.world.gate_open,"Completed puzzle survives checkpoint restart")
	await go_to(Vector2(1740,540))
	check(game.player.global_position.x > 1713.0,"Knight walks through opened gate using collision physics")
	await go_to(Vector2(1770,540))
	check(game.flow == game.Flow.SUCCESS and paused,"Reaching eastern arch shows Stage A success screen")
	game.start_new_game()
	check(not game.puzzle.solved and not game.checkpoint_active and not game.world.gate_open,"Play again fully resets puzzle, gate and checkpoint")
	# Record test output, including failures, for review.
	var summary := "%d passed / %d failed" % [passed,failed]
	print(summary)
	logs.append(summary)
	var file := FileAccess.open("res://tests/TEST_RESULTS.txt",FileAccess.WRITE)
	file.store_string("Godot " + Engine.get_version_info().string + "\n" + "\n".join(logs) + "\n")
	paused = false
	game.queue_free()
	await process_frame
	OS.delay_msec(100)
	await process_frame
	quit(0 if failed == 0 else 1)
