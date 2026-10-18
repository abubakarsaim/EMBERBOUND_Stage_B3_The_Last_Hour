extends "res://scripts/player.gd"
## Only the ending pose differs; normal movement/drawing stays inherited.
var offering: float=0
var flame_returned: bool=false
var fallen: bool=false
func _draw() -> void:
	if offering<=0 and not flame_returned and not fallen:
		super._draw();return
	draw_set_transform(Vector2(0,8),0,Vector2(1,0.35));draw_circle(Vector2.ZERO,36,Color(0.02,0.02,0.03,0.65));draw_set_transform(Vector2.ZERO)
	if fallen:
		draw_set_transform(Vector2(0,0),PI/2)
		draw_texture_rect(frames[0],Rect2(-40,-76,80,96),false,Color("aeb6bf"))
		draw_set_transform(Vector2.ZERO)
		return
	draw_texture_rect(frames[0],Rect2(-40,-84,80,96),false,Color("e8d4b0") if not flame_returned else Color("c0bec3"))
	var torch:=Vector2(27,lerpf(-47,-106,offering))
	draw_line(Vector2(23,-48),torch+Vector2(0,10),Color("13243a"),10,false)
	draw_line(Vector2(24,-48),torch+Vector2(1,10),Color("8495a2"),3,false)
	draw_rect(Rect2(torch+Vector2(-2,2),Vector2(4,17)),Color("684939"))
	if not flame_returned:
		for i in range(6,0,-1):draw_circle(torch,i*16,Color(1,0.7,0.24,0.025))
		draw_colored_polygon(PackedVector2Array([torch+Vector2(-8,1),torch+Vector2(-4,-13),torch+Vector2(0,-27),torch+Vector2(8,-7),torch+Vector2(6,3)]),Color("f0b15c"))
		draw_rect(Rect2(torch-Vector2(2,13),Vector2(4,16)),Color("fff0bc"))
