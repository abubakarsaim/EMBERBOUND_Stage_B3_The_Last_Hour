extends SceneTree
## Real-time dummy-driver playback test. It validates transport/looping, not audible quality.
var lines: Array[String] = []
var failures: int = 0
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, words: String) -> void:
	lines.append(("PASS " if ok else "FAIL ")+words)
	print(lines[-1])
	if not ok:failures += 1
func run() -> void:
	var game: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.start_new_game()
	game.pause_game()
	game.audio.exploration.play(23.70)
	game.audio.pursuit.play(23.70)
	await create_timer(0.9,true).timeout
	var a: float = game.audio.exploration.get_playback_position()
	var b: float = game.audio.pursuit.get_playback_position()
	check(game.audio.exploration.playing and game.audio.pursuit.playing,"Both stems remain playing after crossing their loop boundary")
	check(a >= 0 and a < 2 and b >= 0 and b < 2,"Both stem playback positions wrap to the beginning")
	check(absf(a-b) < 0.06,"Music stems remain synchronized within one audio block")
	game.audio.set_flow("playing")
	game.shadow.state = game.shadow.State.CHARGING
	await create_timer(0.4,true).timeout
	var high: float = game.audio.intensity
	game.shadow.state = game.shadow.State.STALKING
	game.shadow.global_position = Vector2(1000,540)
	await create_timer(0.3,true).timeout
	check(high>0 and high<1 and game.audio.intensity<high and game.audio.intensity>0,"Danger layer ramps up and down rather than switching abruptly")
	game.audio.set_flow("menu")
	await create_timer(1.0,true).timeout
	check(not game.audio.exploration.playing and not game.audio.pursuit.playing,"Menu fade reaches silence and stops both music players")
	lines.append("Playback positions after wrap: %.4f / %.4f seconds" % [a,b])
	lines.append("%d passed / %d failed" % [5-failures,failures])
	var file := FileAccess.open("res://tests/AUDIO_PLAYBACK_RESULTS.txt",FileAccess.WRITE)
	file.store_string("Godot "+Engine.get_version_info().string+" / Dummy audio driver\n"+"\n".join(lines)+"\n")
	paused = false
	game.queue_free()
	await process_frame
	await create_timer(0.15,true).timeout
	quit(0 if failures == 0 else 1)
