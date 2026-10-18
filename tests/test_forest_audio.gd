extends "res://tests/test_stage_a.gd"
## Run without --fixed-fps so real mixer transport can cross a loop boundary.
func run() -> void:
	game = load("res://scenes/forest.tscn").instantiate()
	root.add_child(game)
	await frames(3)
	game.start_new_game()
	game.audio.forest_bed.play(15.7)
	await create_timer(0.9,true,false,true).timeout
	check(game.audio.forest_bed.playing and game.audio.forest_bed.get_playback_position()<1.2,"Forest ambience actually wraps its sixteen-second local WAV loop")
	check(game.audio.exploration.playing and game.audio.pursuit.playing,"A3 synchronized music layers coexist with forest ambience")
	game.audio.play_cue("rune")
	game.audio.play_cue("step")
	check(game.audio.cue_counts.get("rune",0)==1 and game.audio.cue_counts.get("step",0)==1,"Rune and footstep events reach live audio voices")
	game.pause_game()
	await create_timer(0.65,true,false,true).timeout
	check(game.audio.music_gain<0.3 and game.audio.forest_bed.playing,"Pause smoothly ducks forest atmosphere while retaining loop transport")
	game.resume_game()
	game.audio.toggle_mute()
	await create_timer(0.1,true,false,true).timeout
	check(game.audio.forest_bed.volume_db<=-79 and game.audio.exploration.volume_db<=-79,"Mute controls both ambience and music")
	game.show_menu()
	await create_timer(1.0,true,false,true).timeout
	check(not game.audio.forest_bed.playing and not game.audio.exploration.playing,"Title transition fades and stops forest ambience and music")
	paused = false
	game.queue_free()
	await frames(25)
	await create_timer(0.1,true,false,true).timeout
	print("%d passed / %d failed" % [passed,failed])
	quit(0 if failed==0 else 1)
