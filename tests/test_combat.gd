extends "res://tests/test_stage_a.gd"
## A3 integration tests use the actual controller, hunter, projectiles and physics space.
func fresh() -> void:
	release_movement()
	game.start_new_game()
	game.flame.exposed_drain = 0
	game.flame.protected_drain = 0
	await frames(3)

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await frames(3)
	game.audio.muted = true
	await fresh()
	check(game.audio.extra_cues.size() == 8,"Eight additional combat, fire and transition cue mappings load locally")
	check(game.audio.exploration.playing and game.audio.pursuit.playing,"Both music stems start automatically during gameplay")
	check(game.audio.exploration.stream.loop_mode == AudioStreamWAV.LOOP_FORWARD,"Exploration stream is configured to loop")
	check(is_equal_approx(game.audio.exploration.stream.get_length(),24.0) and is_equal_approx(game.audio.pursuit.stream.get_length(),24.0),"Exploration and pursuit loops have matching 24-second lengths")
	check(game.audio.fire_loop.stream.loop_mode == AudioStreamWAV.LOOP_FORWARD,"Fire ambience is configured to loop")
	game.shadow.attack_cooldown = 0.02
	await frames(5)
	check(game.shadow.state == game.shadow.State.CHARGING and game.projectiles.shots_fired == 0,"Hunter visibly charges before releasing its first flare")
	var mark: Vector2 = game.shadow.locked_target
	Input.action_press("move_down")
	await frames(24)
	release_movement()
	check(game.shadow.locked_target == mark,"Warning mark locks to its initial position rather than homing")
	var observed_attack := false
	var observed_recovery := false
	for i in range(100):
		if game.shadow.state == game.shadow.State.ATTACKING: observed_attack = true
		if game.shadow.state == game.shadow.State.RECOVERING: observed_recovery = true
		await frames(1)
	check(game.projectiles.shots_fired == 1 and observed_attack and observed_recovery,"Charge transitions through attack and recovery with one projectile")
	check(game.flame.value == 100,"Moving off the warning mark dodges the flare")
	await fresh()
	game.player.invulnerable = 0
	game.shadow.attack_cooldown = 0
	await frames(100)
	check(game.projectiles.hits_reported == 1 and game.flame.value == 95,"Actual projectile collision removes exactly five flame")
	var normal_radius: float = lerpf(65,230,game.flame.value/100.0)
	check(game.player.light_impact > 0 and game.player.torch_radius < normal_radius-3,"Flare hit produces a temporary torch-radius dip")
	game.on_flare_hit(5,game.player.global_position)
	check(game.flame.value == 95,"Shared post-hit immunity prevents immediate repeat flame damage")
	await frames(65)
	check(game.player.light_impact == 0 and absf(game.player.torch_radius-normal_radius)<1.0,"Torch radius recovers to its remaining-flame value without a permanent penalty")
	await fresh()
	game.shadow.attack_cooldown = 0
	await frames(12)
	var charge_before: float = game.shadow.charge_remaining
	var cooldown_before: float = game.shadow.attack_cooldown
	action("borrow_time")
	await frames(120)
	check(game.shadow.state == game.shadow.State.FROZEN and game.projectiles.shots_fired == 0,"Borrowed Time holds a charging hunter without releasing a flare")
	check(is_equal_approx(game.shadow.charge_remaining,charge_before) and is_equal_approx(game.shadow.attack_cooldown,cooldown_before),"Freeze preserves the remaining charge and attack interval")
	await frames(120)
	check(game.projectiles.shots_fired == 1,"An interrupted charge resumes and completes after time unfreezes")
	await fresh()
	game.shadow.attack_cooldown = 100
	game.projectiles.launch(Vector2(450,540),game.player.global_position)
	var flare: Node2D = game.projectiles.active[0]
	action("borrow_time")
	var position_before: Vector2 = flare.global_position
	var age_before: float = flare.age
	await frames(80)
	check(flare.frozen and flare.global_position == position_before and flare.age == age_before,"Borrowed Time freezes active projectile position, animation age and lifetime")
	game.pause_game()
	var freeze_before: float = game.time_power.freeze_remaining
	await frames(30)
	check(flare.global_position == position_before and game.time_power.freeze_remaining == freeze_before,"Pause preserves frozen projectiles and the freeze timer")
	game.resume_game()
	await go_to(Vector2(300,650))
	for i in range(200):
		if game.time_power.freeze_remaining <= 0:break
		await frames(1)
	await frames(8)
	check(is_instance_valid(flare) and not flare.frozen and flare.global_position != position_before,"Frozen projectile resumes its original flight after Borrowed Time")
	check(game.flame.value == 85,"Knight can escape the projectile during freeze; only the ability's 15 flame is spent")
	await fresh()
	game.player.global_position = Vector2(1340,540)
	game.shadow.attack_cooldown = 0
	game.projectiles.launch(Vector2(1400,540),game.player.global_position)
	await frames(30)
	check(game.shadow.state != game.shadow.State.CHARGING and game.projectiles.shots_fired == 1,"Protected shrine suspends new ranged attacks")
	check(game.projectiles.active.is_empty() and game.flame.value == 100,"Incoming flares dissolve without damage in protected puzzle space")
	await fresh()
	game.player.global_position = Vector2(1800,540)
	game.player.invulnerable = 0
	game.shadow.attack_cooldown = 100
	game.projectiles.launch(Vector2(1650,540),game.player.global_position)
	await frames(40)
	check(game.projectiles.active.is_empty() and game.flame.value == 100,"Closed gate blocks a projectile using real environment collision")
	await fresh()
	game.shadow.attack_cooldown = 100
	for i in range(20):game.projectiles.launch(Vector2(500,400+i),Vector2(100,400))
	check(game.projectiles.active.size() == 4,"Projectile population is capped at four")
	game.projectiles.tick(5,false,game.player,false)
	check(game.projectiles.active.is_empty(),"Expired missed projectiles are removed")
	game.projectiles.launch(Vector2(500,540),game.player.global_position)
	game.player.hurt_feedback()
	game.shadow.state = game.shadow.State.CHARGING
	game.shadow.charge_remaining = 0.4
	game.restart_checkpoint()
	check(game.projectiles.active.is_empty() and game.projectiles.shots_fired == 0,"Restart removes projectiles and resets attack counters")
	check(game.shadow.charge_remaining == 0 and game.shadow.attack_cooldown == 6 and game.player.light_impact == 0,"Restart resets charging, first-attack grace and temporary light effects")
	await fresh()
	await frames(930)
	check(game.projectiles.shots_fired == 2 and game.flame.value == 90,"Default timing produces two fair five-flame hits over 15.5 seconds, not projectile spam")
	# Actual interaction sound requests, including duplicate-interaction rejection.
	await fresh()
	game.player.global_position = Vector2(1100,435)
	game.audio.muted = false
	var before_count: int = game.audio.cue_counts.get("lamp",0)
	action("interact")
	var first_count: int = game.audio.cue_counts.get("lamp",0)
	action("interact")
	check(first_count == before_count+1 and int(game.audio.cue_counts.get("lamp",0)) == first_count,"First lamp ignition requests fire audio immediately; an already-lit lamp does not replay it")
	check(game.audio.cues.lamp.resource_path.ends_with("ignition.wav") and game.puzzle.lamps[0].ignition>0,"Lamp uses the original fire-ignition WAV alongside its visual ignition pulse")
	game.player.global_position = Vector2(1100,645)
	action("interact")
	var before_final: int = game.audio.cue_counts.get("lamp",0)
	game.player.global_position = Vector2(1340,540)
	game.shadow.global_position = game.puzzle.global_position
	game.time_power.reset()
	action("borrow_time")
	action("interact")
	check(game.puzzle.solved and int(game.audio.cue_counts.get("lamp",0)) == before_final+1,"Final sealing lamp also plays the fire-ignition cue exactly once")
	check(int(game.audio.cue_counts.get("gate",0)) > 0 and int(game.audio.cue_counts.get("success",0)) > 0,"Circle completion requests both the gate unlock and puzzle completion cues")
	game.audio.set_music_volume(0.25)
	game.audio.set_sfx_volume(0.5)
	check(game.audio.music_volume == 0.25 and game.audio.sfx_volume == 0.5,"Separate music and SFX controls update independently")
	game.pause_game()
	check(game.audio.flow == "paused","Pause requests a quiet music transition")
	game.resume_game()
	check(game.audio.flow == "playing","Resume restores the gameplay mix")
	game.flame.set_value(0)
	check(game.audio.flow == "failure","Failure requests music fade-out")
	game.restart_checkpoint()
	check(game.audio.flow == "playing","Retry restarts the gameplay music state")
	game.win()
	check(game.audio.flow == "success","Victory requests music fade-out")
	game.show_menu()
	check(game.audio.flow == "menu","Title screen does not retain the pursuit music state")
	var summary := "%d passed / %d failed" % [passed,failed]
	print(summary)
	logs.append(summary)
	var file := FileAccess.open("res://tests/COMBAT_AUDIO_RESULTS.txt",FileAccess.WRITE)
	file.store_string("Godot " + Engine.get_version_info().string + "\n" + "\n".join(logs) + "\n")
	paused = false
	game.queue_free()
	await process_frame
	OS.delay_msec(100)
	await process_frame
	quit(0 if failed == 0 else 1)
