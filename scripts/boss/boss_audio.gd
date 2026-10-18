extends "res://scripts/audio.gd"
var rescue_music: AudioStreamPlayer
var dawn_music: AudioStreamPlayer
var chapter_phase: int=0
var quiet: bool=false
var combat_gain: float=1
var rescue_gain: float=0
var dawn_gain: float=0
func _ready() -> void:
	super._ready()
	exploration.stream=looping(preload("res://assets/audio/hour_clock.wav"))
	pursuit.stream=looping(preload("res://assets/audio/hour_battle.wav"))
	rescue_music=make_voice();rescue_music.stream=looping(preload("res://assets/audio/hour_rescue.wav"))
	dawn_music=make_voice();dawn_music.stream=looping(preload("res://assets/audio/hour_dawn.wav"))
	for name in ["anchor_break","core_expose","core_hit","clock_sweep","time_pulse","prison_open","flame_return","clock_awaken","boss_fall","clock_lock"]:
		extra_cues[name]=load("res://assets/audio/"+name+".wav")
	extra_cues["dialogue"]=preload("res://assets/audio/dialogue_tick.wav")
	extra_cues["step"]=preload("res://assets/audio/footstep.wav")
func set_flow(next: String) -> void:
	super.set_flow(next)
	if next=="playing" and rescue_music!=null:
		if not rescue_music.playing:rescue_music.play(0)
		if not dawn_music.playing:dawn_music.play(0)
func _process(delta: float) -> void:
	target_intensity=0.95 if chapter_phase==1 else 0.25
	super._process(delta)
	combat_gain=move_toward(combat_gain,1 if chapter_phase<2 else 0,delta*0.65)
	rescue_gain=move_toward(rescue_gain,1 if chapter_phase in [2,3] else 0,delta*0.65)
	dawn_gain=move_toward(dawn_gain,1 if chapter_phase>=4 else 0,delta*0.65)
	var master: float=0 if muted else music_volume
	var duck: float=0.5 if quiet else 1
	exploration.volume_db=gain_db(master*music_gain*combat_gain*0.36*duck)
	pursuit.volume_db=gain_db(master*music_gain*combat_gain*intensity*0.30*duck)
	if rescue_music!=null:
		rescue_music.volume_db=gain_db(master*music_gain*rescue_gain*0.43*duck)
		dawn_music.volume_db=gain_db(master*(0.65 if flow=="success" else music_gain)*dawn_gain*0.45)
		if flow not in ["playing","paused","success"] and music_gain<=0.001:rescue_music.stop();dawn_music.stop()
