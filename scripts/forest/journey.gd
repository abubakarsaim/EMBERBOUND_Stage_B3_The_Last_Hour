extends Node
## Session-only chapter handoff. No duplicate worlds or audio players survive a scene change.
var campaign: bool = false
var begin_forest: bool = false
var arriving: bool = false
var arriving_hall: bool = false
var arriving_boss: bool = false
var completed: bool = false
var royal_solved: bool = false
var next_chapter: String = ""
var carried_flame: float = 100.0
var music: float = 0.65
var sfx: float = 0.75
var muted: bool = false
func remember(audio: Node) -> void:
	music = audio.music_volume
	sfx = audio.sfx_volume
	muted = audio.muted
func apply_audio(audio: Node) -> void:
	audio.set_music_volume(music)
	audio.set_sfx_volume(sfx)
	audio.muted = muted
