extends "res://tests/test_stage_a.gd"
## Real-time Dummy mixer transport, not a listening-quality test.
func run() -> void:
	game=load("res://scenes/hourkeeper.tscn").instantiate();root.add_child(game)
	await frames(3);game.skip_scene()
	await create_timer(0.8,true,false,true).timeout
	var music: Array=[game.audio.exploration,game.audio.pursuit,game.audio.rescue_music,game.audio.dawn_music]
	for voice in music:voice.play(23.7)
	await create_timer(0.9,true,false,true).timeout
	var looping: bool=true
	var synced: bool=true
	for voice in music:
		looping=looping and voice.playing and voice.get_playback_position()<1.4
		synced=synced and absf(voice.get_playback_position()-music[0].get_playback_position())<0.06
	check(looping,"All four local boss/ending music stems cross their seamless loop boundary")
	check(synced,"Combat, rescue and dawn stems remain synchronized within one mixer block")
	game.audio.chapter_phase=1;game.set_process(false)
	await create_timer(1.2,true,false,true).timeout
	check(game.audio.intensity>0.8 and game.audio.combat_gain>0.9,"Second phase smoothly increases the darker battle pulse")
	game.audio.chapter_phase=2
	await create_timer(1.8,true,false,true).timeout
	check(game.audio.combat_gain<0.02 and game.audio.rescue_gain>0.98,"Defeat crossfades combat to quiet rescue music")
	game.audio.chapter_phase=4
	await create_timer(1.8,true,false,true).timeout
	check(game.audio.rescue_gain<0.02 and game.audio.dawn_gain>0.98,"Final offering smoothly crossfades to the hopeful dawn composition")
	for cue in ["anchor_break","core_expose","core_hit","clock_sweep","time_pulse","prison_open","flame_return","clock_awaken","boss_fall","clock_lock"]:
		game.audio.play_cue(cue);await create_timer(0.04,true,false,true).timeout
	check(game.audio.cue_counts.has("anchor_break") and game.audio.cue_counts.has("clock_awaken") and game.audio.cue_counts.has("boss_fall"),"All original anchor, boss, prison and clock cues reach playback")
	game.audio.toggle_mute();await create_timer(0.15,true,false,true).timeout
	check(game.audio.dawn_music.volume_db<=-79 and game.audio.rescue_music.volume_db<=-79,"Mute reaches new rescue and dawn music players")
	game.audio.toggle_mute();game.audio.chapter_phase=5;game.audio.set_flow("success")
	await create_timer(0.4,true,false,true).timeout
	check(game.audio.dawn_music.playing and game.audio.dawn_music.volume_db>-79,"Warm dawn music continues quietly over the final credits")
	game.audio.set_flow("menu");await create_timer(1.8,true,false,true).timeout
	check(not game.audio.dawn_music.playing and not game.audio.rescue_music.playing and not game.audio.exploration.playing,"Returning to menus fades and stops every new music voice")
	paused=false;game.queue_free();await frames(25)
	await create_timer(0.35,true,false,true).timeout
	print("%d passed / %d failed" % [passed,failed]);quit(0 if failed==0 else 1)
