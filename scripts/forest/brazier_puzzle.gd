extends Node2D
signal completed
signal lamp_lit
signal wrong_order
const RADIUS: float = 210.0
var lamps: Array[Node2D] = []
var solved: bool = false
var discovered: Array[bool] = [false,false,false]
var progress: int = 0
var hunter_inside: bool = false
var wrong_flash: float = 0
var clock: float = 0
func _ready() -> void:
	lamps = [$Root,$Bell,$Crown]
func _process(delta: float) -> void:
	clock += delta
	wrong_flash = maxf(0,wrong_flash-delta)
	queue_redraw()
func reset() -> void:
	solved = false
	progress = 0
	wrong_flash = 0
	for lamp in lamps: lamp.lit = false
func lit_count() -> int:
	return progress
func found_count() -> int:
	var count := 0
	for found in discovered:
		if found: count += 1
	return count
func nearest_lamp(at: Vector2) -> Node2D:
	var closest: Node2D
	var distance := 76.0
	for lamp in lamps:
		var d := at.distance_to(lamp.global_position)
		if d<distance:
			distance = d
			closest = lamp
	return closest
func update_feedback(at: Vector2, _hunter: Node2D) -> void:
	for lamp in lamps: lamp.highlight = at.distance_to(lamp.global_position)<76
func interact(at: Vector2, _hunter: Node2D, _time: Node) -> String:
	var lamp := nearest_lamp(at)
	if lamp == null: return "Three forgotten braziers wait before the thorn gate."
	if solved or lamp.lit: return "This brazier already burns. The fire remembers."
	if found_count()<3: return "The stone is silent. Find all three forest inscriptions; firelight reveals their symbols."
	if lamp.symbol != progress:
		reset()
		wrong_flash = 0.8
		wrong_order.emit()
		return "The flames sigh out. No ember was lost. Read the journal: FIRST > SECOND > LAST."
	lamp.lit = true
	progress += 1
	lamp_lit.emit()
	if progress==3:
		solved = true
		completed.emit()
		return "The princess's seal answers. The thorn gate opens to the shrine. Checkpoint saved."
	return "%s kindled. Follow the next inscription in your journal." % ["ROOT","BELL","CROWN"][lamp.symbol]
func _draw() -> void:
	draw_circle(Vector2.ZERO,235,Color("101b2d"))
	var art = preload("res://scripts/pixel_art.gd")
	art.ring(self,Vector2.ZERO,225,Color("d7ad68") if solved else Color("42617b"),3)
	art.ring(self,Vector2.ZERO,209,Color("243a55"),2)
	for i in range(3):
		var at := Vector2(-50+i*50,0)
		var color := Color("e85982") if wrong_flash>0 else (Color("ffd48a") if progress>i else Color("324b65"))
		draw_rect(Rect2(at-Vector2(13,13),Vector2(26,26)),Color("0b1424"))
		preload("res://scripts/forest/forest_art.gd").glyph(self,at,i,color,0.6)
	if solved:
		art.ring(self,Vector2.ZERO,70+sin(clock)*3,Color("a1e5e5"),2)
		draw_string(ThemeDB.fallback_font,Vector2(-122,207),"HER SEAL / THE WAY OPENS",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("f4d5a1"))
