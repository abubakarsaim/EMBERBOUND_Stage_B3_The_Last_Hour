extends "res://tests/test_stage_a.gd"
## Real scenes, physics and Input actions. Position changes are used only for isolated fixtures.
func move_fixture(at: Vector2) -> void:
	release_movement()
	game.player.global_position = at
	game.player.velocity = Vector2.ZERO
	game.player.reset_physics_interpolation()

func road(points: Array) -> bool:
	for point in points:
		if not await go_to(point,1800):
			print("ROAD BLOCKED ",point," at ",game.player.global_position)
			return false
	return true

func run() -> void:
	game = load("res://scenes/forest.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await frames(4)
	check(game.flow==game.Flow.MENU and paused,"Forest is the opening menu, with gameplay paused")
	check(game.hud.buttons.get_child_count()==4,"Menu exposes campaign start and independent shrine/hall/boss testing")
	game.start_new_game()
	await frames(5)
	check(game.flow==game.Flow.PLAYING and game.checkpoint_active,"Forest starts under immediate control with entrance checkpoint")
	check(game.world.obstacles.size()>100 and game.world.nav.region.size==Vector2i(72,44),"Original trees/ruins have collision and a bounded navigation grid")
	check(game.audio.forest_bed.playing and game.audio.forest_bed.stream.loop_mode==AudioStreamWAV.LOOP_FORWARD,"Original local forest ambience starts and loops")
	check(game.audio.extra_cues.has("step") and game.audio.extra_cues.has("rune"),"Footstep and rune feedback load locally")
	Input.action_press("move_right")
	await frames(25)
	check(absf(game.player.velocity.length()-220)<0.2,"Forest retains responsive A3 movement speed")
	Input.action_press("move_up")
	await frames(20)
	check(absf(game.player.velocity.length()-220)<0.2,"Forest diagonal movement remains normalized")
	release_movement()
	await frames(15)
	check(game.player.velocity.length()<0.1,"Movement decelerates to rest")
	move_fixture(Vector2(150,2000))
	Input.action_press("move_left")
	await frames(40)
	release_movement()
	check(game.player.global_position.x>=140.5,"Forest boundary physically blocks the knight")
	game.restart_checkpoint()
	await frames(3)
	move_fixture(Vector2(1800,1450))
	game.shadow.reset(Vector2(1600,1450))
	game.shadow.attack_cooldown = 0
	var before: float = game.flame.value
	await frames(15)
	check(game.shadow.state==game.shadow.State.CHARGING,"Forest hunter charges a Shadow Flare outside sacred ground")
	await frames(110)
	check(game.projectiles.shots_fired==1 and game.flame.value<before-4.9,"Forest flare flies and damages the existing flame resource")
	game.shadow.attack_cooldown = 100
	game.projectiles.clear()
	game.projectiles.launch(game.player.global_position+Vector2(220,0),game.player.global_position)
	action("borrow_time")
	var flare: Node2D = game.projectiles.active[0]
	var point: Vector2 = flare.global_position
	var enemy: Vector2 = game.shadow.global_position
	await frames(90)
	check(flare.global_position==point and game.shadow.global_position==enemy,"Borrowed Time holds forest hunter and active flares")
	game.pause_game()
	before = game.flame.value
	await frames(30)
	check(game.flame.value==before and flare.global_position==point,"Forest pause freezes combat and flame timers")
	game.resume_game()
	game.restart_checkpoint()
	await frames(3)
	check(game.projectiles.active.is_empty() and game.time_power.freeze_remaining==0 and game.player.light_impact==0,"Retry clears projectiles, freeze and temporary torch damage")
	move_fixture(game.world.TORCHES[0]+Vector2(0,40))
	game.interact()
	var ignition_count: int = game.audio.cue_counts.get("lamp",0)
	check(game.world.torch_timers[0]==18 and game.world.is_protected(game.player.global_position),"Watchfire creates an eighteen-second sacred refuge")
	game.interact()
	check(game.audio.cue_counts.get("lamp",0)==ignition_count,"Repeated interaction does not replay a burning watchfire's ignition")
	game.world.tick(19)
	check(not game.world.is_protected(game.player.global_position),"Temporary watchfire protection expires")
	move_fixture(game.world.CLUES[0]+Vector2(0,70))
	game.shadow.reset(game.player.global_position-Vector2(70,0))
	game.shadow.attack_cooldown = 0
	await frames(30)
	check(game.puzzle.discovered[0] and game.stones[0].discovered,"Knight firelight reveals and records the nearby ROOT symbol")
	check(game.projectiles.active.is_empty() and game.shadow.state!=game.shadow.State.CHARGING,"Reading ward suppresses ranged attacks and clears incoming flares")
	before = game.flame.value
	game.on_shadow_struck()
	check(game.flame.value==before,"Sacred clue reading also rejects close flame strikes")
	game.interact()
	check(game.clue_readings==1 and game.hud.message.text.contains("First"),"Reading communicates explicit logical order")
	game.corruption.stamp(game.world.CLUES[0])
	check(not game.corruption.contains(game.world.CLUES[0]),"Corruption cannot obscure a sacred rune")
	game.corruption.stamp(Vector2(2100,1500))
	check(game.corruption.contains(Vector2(2100,1500)),"Forest corruption works beyond the old shrine's rectangle")
	game.restart_checkpoint()
	check(game.puzzle.discovered[0] and game.flame.value==100,"Entrance retry restores flame and remembers discovered inscriptions")
	# Partial fire progress survives a retry, without permitting an undiscovered solution.
	move_fixture(game.puzzle.lamps[0].global_position+Vector2(0,50))
	game.interact()
	check(game.puzzle.progress==0,"Brazier gate requires all discoverable clues, preventing blind guessing")
	game.puzzle.discovered.fill(true)
	game.interact()
	game.restart_checkpoint()
	check(game.puzzle.progress==1 and game.puzzle.lamps[0].lit,"Correct partial brazier progress survives entrance checkpoint retry")
	check(game.world.is_protected(game.puzzle.lamps[1].global_position),"Brazier court repels attacks and corruption during puzzle interaction")
	# Reset isolated fixtures, then walk the authored forest route with natural drain and active hunter.
	game.start_new_game()
	await frames(3)
	var route_start: float = game.elapsed
	check(await road([Vector2(850,2000),Vector2(850,900),Vector2(1050,820)]),"Actual input traverses ruined path from watchfire to root memorial")
	game.interact()
	await frames(120)
	check(game.puzzle.found_count()==1,"First landmark discovers only its own clue")
	check(await road([Vector2(1500,900),Vector2(1500,500),Vector2(2450,570)]),"Actual input reaches the fallen bell via the northern road")
	game.interact()
	await frames(120)
	check(game.puzzle.discovered[1],"Second landmark records BELL / SECOND")
	check(await road([Vector2(2750,900),Vector2(2800,1400),Vector2(3050,2220)]),"Actual input follows the eastern road to the royal tomb")
	game.interact()
	await frames(120)
	print("FOREST_HUNTER_AT_LAST_CLUE distance=",game.player.global_position.distance_to(game.shadow.global_position)," shots=",game.projectiles.shots_fired)
	check(game.puzzle.found_count()==3 and game.hud.journal.text.contains("CROWN"),"All three clues are discoverable and retained in the visible journal")
	check(game.projectiles.shots_fired>0 and game.corruption.stains.size()>0,"Hunter actively fires and leaves bounded corruption during the complete exploration route")
	check(await road([Vector2(3550,2150),Vector2(3870,1300),Vector2(4250,1300)]),"Actual input reaches the brazier court without maze backtracking")
	Input.action_press("move_right")
	await frames(70)
	release_movement()
	check(game.player.global_position.x<4298,"Closed thorn gate physically blocks progression")
	check(await go_to(game.puzzle.lamps[2].global_position+Vector2(0,50)),"Player can reach the crown brazier before solving")
	before = game.flame.value
	game.interact()
	check(game.puzzle.progress==0 and game.puzzle.wrong_flash>0 and game.flame.value==before,"Wrong order gives feedback with no flame penalty")
	var order_ok := true
	for lamp in game.puzzle.lamps:
		order_ok = await go_to(lamp.global_position+Vector2(0,50)) and order_ok
		game.interact()
		await frames(10)
	check(order_ok and game.puzzle.solved and game.puzzle.progress==3,"Input route plus ROOT > BELL > CROWN solves all braziers")
	check(game.world.gate_open and game.checkpoint_solved and game.flame.value>99,"Completion opens gate, restores fire and commits post-puzzle checkpoint")
	check(game.audio.cue_counts.get("lamp",0)>=ignition_count+3 and game.audio.cue_counts.get("gate",0)>0,"All three braziers ignite and the magical gate has audio feedback")
	print("SCRIPTED_FOREST_TRAVERSAL_SECONDS ",game.elapsed-route_start," (known route; excludes first-time discovery decisions)")
	game.restart_checkpoint()
	await frames(4)
	check(game.player.global_position.distance_to(game.COURT)<1 and game.puzzle.solved and game.world.gate_open,"Post-puzzle retry respawns at court and retains solved gate")
	check(game.projectiles.active.is_empty() and game.get_node("World").find_children("Shadow","",false,false).size()==1,"Checkpoint does not duplicate enemies or projectiles")
	game.flame.set_value(0)
	await frames(2)
	check(game.flow==game.Flow.FAILURE,"Zero flame triggers forest failure")
	game.restart_checkpoint()
	await frames(3)
	game.audio.set_music_volume(0.4)
	game.audio.set_sfx_volume(0.3)
	check(await road([Vector2(4240,1300),Vector2(4360,1300)]),"Opened gate can be crossed using collision physics")
	Input.action_press("move_right")
	for i in range(180):
		await frames(1)
		if is_instance_valid(current_scene) and current_scene.scene_file_path=="res://scenes/main.tscn": break
	release_movement()
	game = current_scene
	await frames(5)
	check(game.scene_file_path=="res://scenes/main.tscn" and game.flow==game.Flow.PLAYING,"Forest automatically transitions into the original playable shrine")
	check(game.audio.music_volume==0.4 and game.audio.sfx_volume==0.3,"Chapter handoff retains independent audio settings")
	check(root.find_children("Audio","",true,false).size()==1,"Scene transition leaves exactly one audio director")
	check(game.flame.value>98 and game.projectiles.active.is_empty(),"Chapter handoff carries flame and creates no stale attacks")
	check(await road([Vector2(800,540),Vector2(1100,435)]),"Campaign shrine remains traversable with original movement and checkpoint")
	game.interact()
	check(await go_to(Vector2(1100,645)),"Campaign reaches second western shrine lamp")
	game.interact()
	check(await go_to(Vector2(1390,540)),"Campaign reaches shrine's final sealing lamp")
	for i in range(800):
		if game.puzzle.inside_ring(game.shadow.global_position): break
		await frames(1)
	action("borrow_time")
	game.interact()
	check(game.puzzle.solved and game.world.gate_open,"Existing Circle of Light remains solvable after forest progression")
	await go_to(Vector2(1740,540))
	for i in range(180):
		await frames(1)
		if is_instance_valid(current_scene) and current_scene.scene_file_path=="res://scenes/royal_hall.tscn":break
	game = current_scene
	await frames(3)
	check(game.scene_file_path=="res://scenes/royal_hall.tscn" and game.flow==game.Flow.PLAYING,"Campaign shrine leads automatically to the Royal Hall")
	await inspect_royal()
	game.start_new_game()
	await frames(8)
	game = current_scene
	check(game.scene_file_path=="res://scenes/forest.tscn" and game.flow==game.Flow.PLAYING and game.puzzle.found_count()==0 and game.puzzle.progress==0,"Victory Play Again starts a fresh forest immediately, clearing old puzzle progress")
	game.return_to_title()
	await frames(5)
	game = current_scene
	check(game.scene_file_path=="res://scenes/forest.tscn" and game.flow==game.Flow.MENU,"Campaign title returns to the forest menu")
	game.test_shrine()
	await frames(5)
	game = current_scene
	check(game.scene_file_path=="res://scenes/main.tscn" and not root.get_node("Journey").campaign and game.flow==game.Flow.PLAYING,"Independent shrine development entry remains available")
	release_movement()
	paused = false
	game.queue_free()
	await frames(25)
	# Fixed-fps advances simulation faster than the mixer thread. Drain it in wall-clock time.
	var mixer_deadline := Time.get_ticks_msec()+350
	while Time.get_ticks_msec()<mixer_deadline: await process_frame
	print("%d passed / %d failed" % [passed,failed])
	quit(0 if failed==0 else 1)

func inspect_royal() -> void:
	pass
