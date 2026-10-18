extends Node2D
const PALE=preload("res://assets/royal/princess_idle.png")
var clock: float=0
var freed: bool=false
var release_progress: float=0
var approaching: bool=false
var kneeling: bool=false
var knight: Node2D
func tick(delta: float) -> void:
	clock+=delta
	if approaching and knight!=null:
		global_position=global_position.move_toward(knight.global_position+Vector2(83,-12),delta*125)
		kneeling=knight.fallen and global_position.distance_to(knight.global_position+Vector2(83,-12))<4
	queue_redraw()
func _draw() -> void:
	var hover: float=0 if freed else sin(clock*1.8)*4-8
	for i in range(5,0,-1):draw_circle(Vector2(0,-45),i*17,Color(1,0.78,0.4,0.018 if freed else 0.008))
	var rect:=Rect2(-40,-100+hover,80,112) if not kneeling else Rect2(-42,-63,84,78)
	draw_texture_rect_region(PALE,rect,Rect2((int(clock*2)%4)*40,0,40,56),Color.WHITE if freed else Color("bedce7"))
