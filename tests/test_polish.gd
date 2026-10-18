extends "res://tests/test_stage_a.gd"
## Additional checks for the presentation pass; the original regression suite is unchanged.
func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await frames(4)
	game.audio.toggle_mute()
	game.start_new_game()
	await frames(5)
	check(game.player.frames.size() == 12,"Knight has three directional views and four gait frames per view")
	check(game.player.frames[0].get_width() == 40 and game.player.frames[0].get_height() == 48,"Knight is authored on a real 40 by 48 pixel canvas")
	check(game.shadow.visual_frames.size() == 6,"Hunter has six discrete animated shroud frames")
	check(game.player.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST,"Knight uses nearest texture filtering")
	check(ProjectSettings.get_setting("physics/common/physics_interpolation"),"Physics interpolation is enabled for smoother rendered motion")
	check(game.player.deceleration > game.player.acceleration,"Braking is faster than acceleration for responsive controls")
	var trail: Node2D = game.corruption
	trail.clear()
	trail.stamp(Vector2(400,540))
	check(trail.stains.size() > 0 and trail.contains(Vector2(400,540)),"Hunter path can leave visible corruption on ordinary stone")
	var old_flame: float = game.flame.value
	trail.tick(0.2)
	check(game.flame.value == old_flame,"Corruption simulation does not change flame or deal damage")
	trail.clear()
	trail.stamp(game.CHECKPOINT)
	check(trail.stains.is_empty(),"Sanctuary resists corruption even before checkpoint activation")
	trail.stamp(Vector2(-100,-100))
	check(trail.stains.is_empty(),"Corruption does not stamp outside the playable courtyard")
	var lamp: Node2D = game.puzzle.lamps[0]
	trail.stamp(lamp.global_position)
	check(trail.contains(lamp.global_position),"An unlit lamp does not incorrectly protect its surroundings")
	lamp.lit = true
	trail.tick(1.0)
	check(not trail.contains(lamp.global_position),"Lighting a lamp cleanses existing nearby corruption")
	trail.clear()
	trail.stamp(lamp.global_position)
	check(trail.stains.is_empty(),"Lit lamps resist newly emitted corruption")
	game.puzzle.solved = true
	trail.stamp(game.puzzle.global_position)
	check(trail.stains.is_empty(),"Completed circle rejects corruption inside its sacred barrier")
	game.start_new_game()
	trail.clear()
	# Traverse enough distinct cells to exercise eviction, not only the easy empty case.
	for i in range(1400):
		trail.stamp(Vector2(108+(i%70)*24,258+int(i/70)*24))
	check(trail.stains.size() == trail.MAX_CELLS,"Stain memory reaches but never exceeds the 560-cell cap")
	check(trail.insertion_order.size() == trail.stains.size(),"Trail eviction keeps its dictionary and insertion queue consistent")
	game.restart_checkpoint()
	check(trail.stains.is_empty(),"Restart clears corruption from the previous attempt")
	game.time_power.try_activate(game.flame)
	game.shadow.tick(0)
	var old_clock: float = game.shadow.clock
	trail.tick(0.2)
	game.shadow.tick(0.2)
	check(trail.stains.is_empty(),"Frozen hunter emits no new corruption")
	check(game.shadow.clock == old_clock,"Frozen hunter also stops its shroud animation clock")
	check(game.player.cast_remaining > 0 and game.effects.waves.size() > 0,"Borrowed Time triggers knight cast feedback and a world shockwave")
	game.pause_game()
	var trail_clock: float = trail.clock
	var effect_clock: float = game.effects.clock
	await frames(30)
	check(trail.clock == trail_clock and game.effects.clock == effect_clock,"Pause stops corruption and world presentation clocks")
	game.resume_game()
	game.restart_checkpoint()
	game.player.hurt_feedback()
	check(game.player.hurt_flash > 0,"Knight has explicit damage feedback")
	game.restart_checkpoint()
	check(game.player.hurt_flash == 0 and game.player.cast_remaining == 0,"Restart clears old hurt and cast effects")
	# The feedback modules are bounded even if many events occur rapidly.
	for i in range(30):
		game.effects.burst(Vector2(400,540),Color.GOLD,20)
		game.effects.wave(Vector2(400,540),Color.CYAN)
		game.effects.announce(Vector2(400,540),"TEST",Color.GOLD)
	check(game.effects.particles.size() <= 160 and game.effects.waves.size() <= 8 and game.effects.captions.size() <= 5,"Particle, shockwave and caption budgets remain bounded")
	game.restart_checkpoint()
	check(game.effects.particles.is_empty() and game.effects.waves.is_empty() and game.effects.captions.is_empty(),"Restart clears transient world feedback")
	game.player.global_position = Vector2(1100,435)
	game.puzzle.update_feedback(game.player.global_position,game.shadow)
	check(game.puzzle.lamps[0].highlight,"Nearby lamp exposes its E interaction highlight")
	game.puzzle.lamps[0].lit = true
	check(game.puzzle.lamps[0].ignition > 0,"Lamp ignition starts a visible activation pulse")
	check(game.presentation.material_fx.shader != null,"Atmosphere shader is local and attached")
	var summary := "%d passed / %d failed" % [passed,failed]
	print(summary)
	logs.append(summary)
	var file := FileAccess.open("res://tests/POLISH_RESULTS.txt",FileAccess.WRITE)
	file.store_string("Godot " + Engine.get_version_info().string + "\n" + "\n".join(logs) + "\n")
	paused = false
	game.queue_free()
	await process_frame
	OS.delay_msec(100)
	await process_frame
	quit(0 if failed == 0 else 1)
