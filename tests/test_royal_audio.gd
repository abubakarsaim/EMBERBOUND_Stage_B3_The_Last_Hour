extends "res://tests/test_stage_a.gd"
## Real mixer transport; run without --fixed-fps.
func run() -> void:
	game = load("res://scenes/royal_hall.tscn").instantiate()
	root.add_child(game)
	await frames(3)
	game.skip_scene()
	await create_timer(0.8,true,false,true).timeout
	game.audio.exploration.play(23.7)
	game.audio.pursuit.play(23.7)
	game.audio.ambience.play(11.7)
	await create_timer(0.9,true,false,true).timeout
	check(game.audio.exploration.playing and game.audio.pursuit.playing and game.audio.ambience.playing,"Royal music, darker stem and hall ambience continue across loop seams")
	check(game.audio.exploration.get_playback_position()<1.3 and game.audio.ambience.get_playback_position()<1.3,"Royal music and ambience actually wrap their local WAV loop boundaries")
	check(absf(game.audio.exploration.get_playback_position()-game.audio.pursuit.get_playback_position())<0.06,"Royal exploration and revelation music stems stay synchronized")
	game.puzzle.phase = game.puzzle.Phase.REVEALING
	game.puzzle.reveal_remaining = 2.6
	game.on_revelation_started()
	await create_timer(0.8,true,false,true).timeout
	check(game.audio.intensity>0.7,"Revelation smoothly introduces the darker music layer")
	for cue in ["royal_door","mirror","royal_seal","dialogue","distort","reveal","passage"]:
		game.audio.play_cue(cue)
		await create_timer(0.05,true,false,true).timeout
	check(game.audio.cue_counts.has("royal_door") and game.audio.cue_counts.has("passage") and game.audio.cue_counts.has("distort"),"Original door, mirror, seal, dialogue, distortion and passage cues reach audio playback")
	game.audio.narrative = true
	await create_timer(0.6,true,false,true).timeout
	check(game.audio.narrative_gain<0.55,"Dialogue gently ducks the hall music and ambience")
	game.audio.toggle_mute()
	await create_timer(0.1,true,false,true).timeout
	check(game.audio.ambience.volume_db<=-79 and game.audio.exploration.volume_db<=-79,"Mute affects both new hall ambience and music")
	game.flow = game.Flow.SUCCESS
	game.audio.set_flow("success")
	await create_timer(1.0,true,false,true).timeout
	check(not game.audio.ambience.playing and not game.audio.exploration.playing,"End-of-chapter transition fades out and stops new music/ambience")
	paused = false
	game.queue_free()
	await frames(25)
	var deadline := Time.get_ticks_msec()+350
	while Time.get_ticks_msec()<deadline: await process_frame
	print("%d passed / %d failed" % [passed,failed])
	quit(0 if failed==0 else 1)
