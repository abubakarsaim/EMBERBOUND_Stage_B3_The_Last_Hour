extends Node2D
const Art = preload("res://scripts/forest/forest_art.gd")
@export var symbol: int = 0
var discovered: bool = false
var near: bool = false
var reveal: float = 0.0
var clock: float = 0.0
var viewer: Node2D
func _process(delta: float) -> void:
	clock += delta
	var distance := viewer.global_position.distance_to(global_position) if viewer != null else 9999.0
	var radius: float = maxf(76,viewer.torch_radius*0.74) if viewer != null else 76.0
	reveal = move_toward(reveal,1.0 if distance<radius or discovered else 0.12,delta*3)
	near = distance<84
	queue_redraw()
func _draw() -> void:
	for i in range(5,0,-1):
		draw_circle(Vector2(0,-24),18+i*13,Color(0.25,0.72,0.84,0.016*reveal))
	draw_rect(Rect2(-32,4,64,14),Color("0b1322"))
	draw_rect(Rect2(-30,0,60,8),Color("56647a"))
	draw_colored_polygon(PackedVector2Array([Vector2(-26,0),Vector2(-25,-65),Vector2(-10,-76),Vector2(23,-71),Vector2(28,0)]),Color("24344b"))
	draw_line(Vector2(-23,-63),Vector2(-23,-4),Color("4c6078"),4,false)
	Art.glyph(self,Vector2(0,-35),symbol,Color(0.46,0.89,0.94,reveal),1.2)
	var ordinal: String = ["I","II","III"][symbol]
	draw_string(ThemeDB.fallback_font,Vector2(-6,-83),ordinal,HORIZONTAL_ALIGNMENT_LEFT,-1,19,Color("b4d4dd"))
	if discovered:
		var words: String = ["ROOT / FIRST","BELL / SECOND","CROWN / LAST"][symbol]
		draw_string(ThemeDB.fallback_font,Vector2(-70,36),words,HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("92d7e1"))
	if near:
		draw_string(ThemeDB.fallback_font,Vector2(-42,-110),"[E] READ",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("ffe2a2"))
