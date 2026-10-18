extends "res://scripts/audio.gd"
var ambience: AudioStreamPlayer
var narrative: bool = false
var revelation: bool = false
var narrative_gain: float = 1
func _ready() -> void:
	super._ready()
	exploration.stream = looping(preload("res://assets/audio/royal_music.wav"))
	pursuit.stream = looping(preload("res://assets/audio/royal_revelation.wav"))
	extra_cues["royal_door"] = preload("res://assets/audio/royal_door.wav")
	extra_cues["mirror"] = preload("res://assets/audio/royal_mirror.wav")
	extra_cues["royal_seal"] = preload("res://assets/audio/royal_seal.wav")
	extra_cues["dialogue"] = preload("res://assets/audio/dialogue_tick.wav")
	extra_cues["distort"] = preload("res://assets/audio/illusion_distort.wav")
	extra_cues["reveal"] = preload("res://assets/audio/revelation_finish.wav")
	extra_cues["passage"] = preload("res://assets/audio/royal_passage.wav")
	extra_cues["step"] = preload("res://assets/audio/footstep.wav")
	ambience = make_voice()
	ambience.stream = looping(preload("res://assets/audio/royal_ambience.wav"))
func set_flow(next: String) -> void:
	super.set_flow(next)
	if ambience!=null and next=="playing" and not ambience.playing: ambience.play()
func _process(delta: float) -> void:
	if revelation: target_intensity = maxf(target_intensity,0.82)
	super._process(delta)
	narrative_gain = move_toward(narrative_gain,0.48 if narrative else 1.0,delta*1.5)
	var master: float = 0 if muted else music_volume
	exploration.volume_db = gain_db(master*music_gain*0.36*narrative_gain)
	pursuit.volume_db = gain_db(master*music_gain*0.28*intensity*narrative_gain)
	if ambience!=null:
		ambience.volume_db = gain_db((0 if muted else sfx_volume)*music_gain*0.32*narrative_gain)
		if flow!="playing" and flow!="paused" and music_gain<=0.001: ambience.stop()
