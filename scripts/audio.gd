extends Node
## Local, original WAVs. Two synchronized music stems share the same 24-second loop.
var muted: bool = false
var music_volume: float = 0.65
var sfx_volume: float = 0.75
var voices: Array[AudioStreamPlayer] = []
var cues: Dictionary = {}
var extra_cues: Dictionary = {}
var exploration: AudioStreamPlayer
var pursuit: AudioStreamPlayer
var fire_loop: AudioStreamPlayer
var charge_voice: AudioStreamPlayer
var flow: String = "menu"
var music_gain: float = 0.0
var intensity: float = 0.0
var target_intensity: float = 0.0
var fire_amount: float = 0.0
var fire_gain: float = 0.0
var time_frozen: bool = false
var cue_counts: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Keep the original cue names for the existing controller and regression suite.
	cues = {
		"lamp":preload("res://assets/audio/ignition.wav"),
		"freeze":preload("res://assets/audio/freeze.wav"),
		"success":preload("res://assets/audio/success.wav"),
		"hurt":preload("res://assets/audio/impact.wav")
	}
	extra_cues = {
		"charge":preload("res://assets/audio/charge.wav"),
		"launch":preload("res://assets/audio/launch.wav"),
		"impact":preload("res://assets/audio/impact.wav"),
		"time_end":preload("res://assets/audio/time_end.wav"),
		"low_flame":preload("res://assets/audio/low_flame.wav"),
		"gate":preload("res://assets/audio/gate.wav"),
		"checkpoint":preload("res://assets/audio/checkpoint.wav"),
		"failure":preload("res://assets/audio/failure.wav")
	}
	for i in range(6):
		voices.append(make_voice())
	charge_voice = make_voice()
	charge_voice.stream = extra_cues.charge
	exploration = make_voice()
	exploration.stream = looping(preload("res://assets/audio/exploration.wav"))
	pursuit = make_voice()
	pursuit.stream = looping(preload("res://assets/audio/pursuit.wav"))
	fire_loop = make_voice()
	fire_loop.stream = looping(preload("res://assets/audio/fire_loop.wav"))

func make_voice() -> AudioStreamPlayer:
	var voice := AudioStreamPlayer.new()
	voice.volume_db = -80
	add_child(voice)
	return voice

func looping(source: AudioStreamWAV) -> AudioStreamWAV:
	var stream: AudioStreamWAV = source.duplicate()
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = roundi(stream.get_length()*stream.mix_rate)
	return stream

func set_flow(next: String) -> void:
	flow = next
	if next == "playing":
		if not exploration.playing or not pursuit.playing:
			exploration.play(0)
			pursuit.play(0)
		if not fire_loop.playing:
			fire_loop.play()
	elif next != "paused":
		charge_voice.stop()
	for voice in voices:
		voice.stream_paused = next == "paused"

func set_context(danger: float, near_fire: float, frozen: bool) -> void:
	target_intensity = clampf(danger,0,1)*(0.25 if frozen else 1.0)
	fire_amount = clampf(near_fire,0,1)
	time_frozen = frozen

func _process(delta: float) -> void:
	var target_gain := 1.0 if flow == "playing" else (0.16 if flow == "paused" else 0.0)
	music_gain = move_toward(music_gain,target_gain,delta*1.6)
	intensity = move_toward(intensity,target_intensity,delta*(1.2 if target_intensity>intensity else 0.4))
	fire_gain = move_toward(fire_gain,fire_amount if flow == "playing" else 0,delta*2)
	var music_master := 0.0 if muted else music_volume
	var sfx_master := 0.0 if muted else sfx_volume
	exploration.volume_db = gain_db(music_master*music_gain*0.32*(1-intensity*0.18))
	pursuit.volume_db = gain_db(music_master*music_gain*0.40*intensity)
	fire_loop.volume_db = gain_db(sfx_master*fire_gain*0.20)
	charge_voice.volume_db = gain_db(sfx_master*0.65)
	charge_voice.stream_paused = flow == "paused" or time_frozen
	for voice in voices:
		voice.volume_db = gain_db(sfx_master*0.70)
	if target_gain == 0 and music_gain <= 0.001:
		exploration.stop()
		pursuit.stop()
		fire_loop.stop()

func gain_db(amount: float) -> float:
	return linear_to_db(maxf(amount,0.00001))

func play_cue(cue: String) -> void:
	if muted:
		return
	var stream: AudioStream = cues.get(cue,extra_cues.get(cue))
	if stream == null:
		return
	cue_counts[cue] = int(cue_counts.get(cue,0))+1
	if cue == "charge":
		charge_voice.play()
		return
	for voice in voices:
		if not voice.playing:
			voice.stream_paused = false
			voice.stream = stream
			voice.volume_db = gain_db(sfx_volume*0.70)
			voice.play()
			return

func cancel_charge() -> void:
	charge_voice.stop()

func toggle_mute() -> void:
	muted = not muted
	if muted:
		for voice in voices:
			voice.stop()
		charge_voice.stop()

func set_music_volume(value: float) -> void:
	music_volume = clampf(value,0,1)

func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value,0,1)

func reset_transients() -> void:
	for voice in voices:
		voice.stop()
		voice.stream_paused = false
	charge_voice.stop()
	charge_voice.stream_paused = false
	time_frozen = false
	target_intensity = 0
	intensity = 0
	fire_amount = 0
	fire_gain = 0

func _exit_tree() -> void:
	for child in get_children():
		if child is AudioStreamPlayer:
			child.stop()
			child.stream = null
	voices.clear()
	cues.clear()
	extra_cues.clear()
