extends "res://scripts/lamp.gd"
const RuneArt = preload("res://scripts/forest/forest_art.gd")
@export var symbol: int = 0
func _draw() -> void:
	super._draw()
	draw_rect(Rect2(-31,16,62,38),Color("101b2d"))
	RuneArt.glyph(self,Vector2(0,34),symbol,Color("ffcc84") if lit else Color("8bc1d5"),0.7)
	var word: String = ["ROOT","BELL","CROWN"][symbol]
	draw_string(ThemeDB.fallback_font,Vector2(-26,75),word,HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("b8c8d6"))
