extends Node2D
const Art = preload("res://scripts/pixel_art.gd")
const PALE = preload("res://assets/royal/princess_idle.png")
const FALSE = preload("res://assets/royal/false_princess_idle.png")
var hostile: bool = false
var viewer: Node2D
var clock: float = 0
var exposed: bool = false
var revealed: bool = false
var distortion: float = 0
var approach: bool = false
var frozen: bool = false
var home := Vector2(1536,780)
var shadow_visibility: float = 0
var shadow_side: float = -1

func _process(delta: float) -> void:
	if not frozen: clock += delta
	if viewer != null:
		var distance := viewer.global_position.distance_to(global_position)
		shadow_visibility = move_toward(shadow_visibility,1.0 if distance<maxf(195,viewer.torch_radius) else 0,delta*2.2)
		shadow_side = -1.0 if viewer.global_position.x<global_position.x else 1.0
	queue_redraw()

func tick(delta: float, seal: Vector2) -> void:
	if not frozen and not hostile:
		global_position = global_position.move_toward(seal-Vector2(0,80) if approach else home,delta*95)

func _draw() -> void:
	var flicker := 1.0 if not exposed else (0.65+0.35*sin(clock*19))
	if not revealed:
		for i in range(7,0,-1):draw_circle(Vector2(0,-38),i*15,Color(1,0.75,0.35,0.024*flicker))
	# An independent crowned shape reaches TOWARD the torch instead of away from it.
	if shadow_visibility>0.01 or revealed:
		var length := 60+sin(clock*1.3)*9
		var side := shadow_side
		var silhouette := PackedVector2Array([Vector2(-12,3),Vector2(side*length,-8),Vector2(side*(length+22),-27),Vector2(side*(length+17),-5),Vector2(side*(length+35),3),Vector2(side*(length+12),8),Vector2(side*(length+25),28),Vector2(side*(length-4),18),Vector2(14,15)])
		draw_colored_polygon(silhouette,Color(0.025,0.009,0.045,0.80*maxf(shadow_visibility,0.6 if revealed else 0)))
		if exposed or revealed:draw_line(Vector2(side*(length+9),3),Vector2(side*(length+22),2),Color("b83f63"),3,false)
	var frame := int(clock*2.4)%4
	var hover := roundf(sin(clock*1.8))*2
	if not revealed:
		draw_texture_rect_region(PALE,Rect2(-40,-100+hover,80,112),Rect2(frame*40,0,40,56),Color(1,0.88,0.78) if distortion>0.5 else Color.WHITE)
		if exposed and sin(clock*21)>0.6:
			draw_texture_rect_region(FALSE,Rect2(-64,-143,128,160),Rect2(frame*64,0,64,80),Color(0.6,0.25,0.45,0.3))
	else:
		for i in range(5,0,-1):draw_circle(Vector2(0,-47),i*17,Color(0.33,0.025,0.11,0.035))
		draw_texture_rect_region(FALSE,Rect2(-64,-144+hover,128,160),Rect2(frame*64,0,64,80))
		for i in range(16):
			var age := fmod(clock*0.3+i*0.063,1.0)
			var at := Vector2(sin(i*2.7+clock)*52,-age*133)
			draw_rect(Rect2(at.snapped(Vector2(2,2)),Vector2(4,4)),Color(0.32,0.04,0.15,1-age))
	if frozen and exposed:Art.ring(self,Vector2(0,-48),70,Color("86eff0"),2)
