extends Control
## Exact-height pixel meter. Avoids the default ProgressBar's theme minimum height.
var value: float = 100.0:
	set(amount):
		value = amount
		queue_redraw()
var max_value: float = 100.0
var show_percentage: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var background := get_theme_stylebox("background") as StyleBoxFlat
	var fill := get_theme_stylebox("fill") as StyleBoxFlat
	draw_rect(Rect2(Vector2.ZERO,size),background.bg_color if background != null else Color("202b40"))
	var ratio := clampf(value/maxf(0.001,max_value),0,1)
	if ratio > 0:
		draw_rect(Rect2(Vector2.ZERO,Vector2(size.x*ratio,size.y)),fill.bg_color if fill != null else Color("f2bf73"))
	draw_line(Vector2(0,0),Vector2(size.x,0),Color(0.7,0.75,0.8,0.2),1,false)
