extends "res://scripts/audio.gd"
var forest_bed: AudioStreamPlayer
func _ready() -> void:
	super._ready()
	extra_cues["rune"] = preload("res://assets/audio/rune.wav")
	extra_cues["step"] = preload("res://assets/audio/footstep.wav")
	extra_cues["wrong"] = preload("res://assets/audio/wrong_order.wav")
	forest_bed = make_voice()
	forest_bed.stream = looping(preload("res://assets/audio/forest_ambience.wav"))
func set_flow(next: String) -> void:
	super.set_flow(next)
	if forest_bed!=null and next=="playing" and not forest_bed.playing: forest_bed.play()
func _process(delta: float) -> void:
	super._process(delta)
	if forest_bed==null: return
	forest_bed.volume_db = gain_db((0 if muted else sfx_volume)*music_gain*0.38)
	if flow!="playing" and flow!="paused" and music_gain<=0.001: forest_bed.stop()
