extends "res://tests/test_forest.gd"
func run() -> void:
	game = load("res://scenes/royal_hall.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await frames(4)
	check(game.cinematic_mode=="pan" and not game.player.active,"Royal arrival preserves its short cinematic camera")
	await preload("res://tests/royal_route.gd").new().run(self)
	await fixtures()
	paused = false
	game.queue_free()
	await frames(25)
	var deadline := Time.get_ticks_msec()+350
	while Time.get_ticks_msec()<deadline: await process_frame
	print("%d passed / %d failed" % [passed,failed])
	quit(0 if failed==0 else 1)

func fresh() -> void:
	game.start_new_game()
	await frames(4)
	game.skip_scene()
	await frames(45)
func fixture_encounter() -> void:
	game.puzzle.phase = game.puzzle.Phase.ENCOUNTER
	game.puzzle.source_lit = true
	game.puzzle.mirror_lit = true
	game.puzzle.rotations.assign([1,1])
	game.puzzle.trace_light()
	game.puzzle.checkpoint_position = game.world.MIRROR+Vector2(0,100)
	game.restore_run(true)
	game.read_grace = 0
	game.player.invulnerable = 0
	game.princess.global_position = Vector2(1536,900)
	move_fixture(Vector2(1810,1050))
	game.encounter.attack_remaining = 0
func fixtures() -> void:
	game.restart_checkpoint()
	await frames(4)
	check(game.puzzle.gate_unlocked and game.world.gate_open and game.player.global_position.distance_to(Vector2(2580,580))<1,"Final passage retry preserves sigil use and starts at the opened doorway")
	check(game.projectiles.active.is_empty() and game.time_power.freeze_remaining==0 and game.encounter.shots_fired==0,"Checkpoint clears flares, temporary time and attack counters")
	await fresh()
	check(game.puzzle.phase==game.puzzle.Phase.RESCUE and not game.puzzle.sigil_released,"Independent new hall run clears all mission progress")
	move_fixture(Vector2(400,1200))
	game.read_grace = 0
	game.shadow.global_position = Vector2(700,1200)
	game.shadow.attack_cooldown = 0
	await frames(6)
	check(game.shadow.active and game.shadow.state==game.shadow.State.CHARGING,"Preserved hunter still charges outside early mission refuges")
	game.projectiles.launch(Vector2(650,1200),game.player.global_position)
	action("borrow_time")
	var shot: Node2D = game.projectiles.active[0]
	var shot_at: Vector2 = shot.global_position
	var hunter_at: Vector2 = game.shadow.global_position
	await frames(60)
	check(shot.global_position==shot_at and game.shadow.global_position==hunter_at,"Borrowed Time retains hunter and old flare freeze behavior in the revised hall")
	await fresh()
	move_fixture(Vector2(830,1000))
	game.interact()
	check(game.puzzle.phase==game.puzzle.Phase.RESCUE and game.hud.message.text.contains("blind"),"Premature mirror interaction explains why it cannot reveal anything yet")
	move_fixture(Vector2(1536,1600))
	game.interact()
	check(not game.puzzle.source_lit and game.hud.message.text.contains("altar"),"Mission order has a narrative explanation; the font cannot bypass the altar warning")
	game.puzzle.ask_for_flame()
	game.puzzle.examine_altar()
	game.flame.reset(50)
	game.interact()
	var ignitions: int = game.audio.cue_counts.get("lamp",0)
	check(game.puzzle.source_lit and game.flame.value==50,"Lighting the mirror font uses fire without an arbitrary added flame fee")
	game.interact()
	check(game.flame.value==100 and game.audio.cue_counts.get("lamp",0)==ignitions,"An already-burning font rekindles safely without replaying the full ignition")
	var solutions: int = 0
	var all_valid: bool = true
	for a in range(4):
		for b in range(4):
			game.puzzle.rotations.assign([a,b])
			game.puzzle.trace_light()
			if game.puzzle.mirror_powered:
				solutions += 1
				all_valid = all_valid and a==1 and b==1 and game.puzzle.beam.size()==4
	check(solutions==1 and all_valid,"All sixteen orientations were traced: exactly the geometrically aligned path illuminates the mirror")
	game.puzzle.rotations.assign([1,2])
	game.puzzle.trace_light()
	game.flame.set_value(0)
	await frames(2)
	check(game.flow==game.Flow.FAILURE and paused,"Flame exhaustion still enters failure in the mirror mission")
	action("replay_intro")
	check(game.flow==game.Flow.FAILURE and not game.player.active,"Replay cannot bypass a zero-flame failure")
	game.restart_checkpoint()
	await frames(3)
	check(game.puzzle.phase==game.puzzle.Phase.MIRROR and game.puzzle.source_lit and game.puzzle.rotations==[1,2],"Altar checkpoint remembers partial reflector work after failure")
	check(game.flame.value>99 and game.player.global_position.distance_to(game.puzzle.checkpoint_position)<1,"Mission retry restores full flame at its new checkpoint instead of repeating the chapter")
	move_fixture(Vector2(1150,1600))
	game.puzzle.no_progress = 40
	check(game.context_hint().contains("Rotate"),"Nearby reflector always advertises its E rotation control")
	move_fixture(Vector2(1900,1500))
	check(game.context_hint().contains("tilted"),"An idle hint explains light redirection without listing orientation numbers")
	move_fixture(Vector2(200,1800))
	Input.action_press("move_left")
	await frames(40)
	release_movement()
	check(game.player.global_position.x>=207,"Original hall boundary still blocks movement")
	move_fixture(Vector2(600,1210))
	Input.action_press("move_up")
	await frames(35)
	release_movement()
	check(game.player.global_position.y>=1180,"Original gothic column bases keep their physical collision")
	fixture_encounter()
	await frames(6)
	check(game.encounter.state==game.encounter.State.CHARGING and game.encounter.charge_remaining>0.8,"Apparition gives a full visible one-second warning before firing")
	var locked: Vector2 = game.encounter.aim
	move_fixture(Vector2(1810,1220))
	var before: float = game.flame.value
	await frames(80)
	check(game.encounter.aim==locked and game.encounter.shots_fired==1,"Apparition aims at the warning location rather than homing after a dodge")
	check(game.encounter.state==game.encounter.State.RECOVERING and game.encounter.recovery_remaining>0,"The attack has a readable recovery window")
	check(before-game.flame.value<1,"Moving off the red mark avoids flame damage")
	game.projectiles.clear()
	game.encounter.reset(true)
	game.encounter.attack_remaining = 0
	game.princess.global_position = Vector2(1536,1000)
	move_fixture(Vector2(1810,1000))
	game.player.invulnerable = 0
	before = game.flame.value
	for i in range(240):
		await frames(1)
		if game.projectiles.hits_reported>0: break
	check(game.projectiles.hits_reported==1 and before-game.flame.value>=5 and before-game.flame.value<6.1,"An undodged apparition flare hits the existing flame for five plus ordinary depletion")
	check(game.player.light_impact>0 and game.player.invulnerable>0,"A hit triggers temporary torch flicker/shrink and damage immunity")
	before = game.flame.value
	game.on_flare_hit(5,game.player.global_position)
	check(game.flame.value==before,"Brief immunity prevents stacked instant damage")
	await frames(50)
	check(game.player.light_impact==0,"The temporary torch radius penalty expires instead of stacking permanently")
	game.projectiles.clear()
	game.projectiles.launch(Vector2(1740,1000),game.player.global_position)
	shot = game.projectiles.active[0]
	shot_at = shot.global_position
	var apparition_at: Vector2 = game.princess.global_position
	game.time_power.reset()
	action("borrow_time")
	await frames(80)
	check(shot.global_position==shot_at and game.princess.global_position==apparition_at and game.encounter.state==game.encounter.State.FROZEN,"Time holds both the hostile apparition and its flying flare")
	game.pause_game()
	var power_before: float = game.time_power.freeze_remaining
	before = game.flame.value
	await frames(40)
	check(game.time_power.freeze_remaining==power_before and game.flame.value==before,"Pause preserves encounter, ability and flame timers")
	game.resume_game()
	game.restart_checkpoint()
	await frames(3)
	check(game.puzzle.mirror_lit and game.encounter.active and game.player.global_position.distance_to(game.world.MIRROR+Vector2(0,100))<1,"Exposed-mirror checkpoint restores the encounter without repeating the light puzzle")
	check(game.projectiles.active.is_empty() and game.encounter.state==game.encounter.State.STALKING and game.time_power.freeze_remaining==0,"Encounter retry starts clean, without duplicate attacks or frozen state")
	move_fixture(game.world.SEAL+Vector2(0,70))
	game.flame.reset(12)
	game.interact()
	check(game.puzzle.seal_armed and game.flame.value==40,"Low-flame seal activation guarantees an affordable standard Borrowed Time attempt")
	before = game.flame.value
	game.princess.global_position = game.world.SEAL+Vector2(0,-230)
	game.interact()
	check(game.puzzle.phase==game.puzzle.Phase.ENCOUNTER and game.hud.message.text.contains("OUTSIDE") and game.flame.value==before,"Outside-ring binding fails with a useful hint and no additional flame penalty")
	game.princess.global_position = game.world.SEAL
	game.interact()
	check(game.puzzle.phase==game.puzzle.Phase.ENCOUNTER and game.hud.message.text.contains("SPACE"),"A live shadow in the seal still requires meaningful Time activation")
	game.time_power.reset()
	action("borrow_time")
	game.interact()
	await frames(35)
	check(game.puzzle.phase==game.puzzle.Phase.REVEALING and not game.player.active,"Binding starts the protected, short illusion-breaking sequence")
	game.restart_checkpoint()
	await frames(4)
	check(game.puzzle.phase==game.puzzle.Phase.ENCOUNTER and game.puzzle.seal_armed and game.player.global_position.distance_to(game.world.SEAL+Vector2(0,70))<1,"Retry during transformation resumes at the ignited seal checkpoint")
	check(game.princess.modulate.a==1 and game.reveal_wash.color.a==0 and game.player.get_node("Camera2D").offset==Vector2(0,-110),"Interrupted reveal resets alpha, dark wash and camera feedback")
	check(game.encounter.active and game.projectiles.active.is_empty() and not game.puzzle.sigil_released,"Interrupted reveal grants no premature sigil and duplicates no projectiles")
	game.begin_conversation(game.EXPOSURE,"exposure")
	before = game.flame.value
	var enemy_at: Vector2 = game.princess.global_position
	await frames(100)
	check(game.princess.global_position==enemy_at and game.flame.value==before and game.projectiles.active.is_empty(),"The player can read mission objectives/dialogue without being attacked or losing flame")
	game.skip_scene()
	check(game.player.active and game.read_grace==5,"Ending dialogue restores control with five seconds of attack grace")
	check(root.find_children("Audio","",true,false).size()==1 and game.get_node("World").find_children("ApparitionEncounter","",false,false).size()==1,"Repeated mission restarts leave one audio director and one apparition controller")
