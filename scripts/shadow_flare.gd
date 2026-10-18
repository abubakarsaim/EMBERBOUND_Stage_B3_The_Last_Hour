extends Node2D
## Swept hit checks prevent tunnelling; all timers advance only through the manager.
const Art = preload("res://scripts/pixel_art.gd")
const SPEED: float = 200.0
const DAMAGE: float = 5.0
const LIFE: float = 4.5
const HIT_RADIUS: float = 27.0
var direction := Vector2.RIGHT
var age: float = 0.0
var frozen: bool = false
var expired: bool = false
var trail: Array[Vector2] = []
var trail_time: float = 0.0

func setup(at: Vector2, aim: Vector2) -> void:
	global_position = at
	direction = (aim-at).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	reset_physics_interpolation()

func advance(delta: float, hold: bool, knight: Node2D) -> String:
	if expired:
		return ""
	frozen = hold
	if hold:
		queue_redraw()
		return ""
	age += delta
	if age >= LIFE:
		expired = true
		return "expired"
	var start := global_position
	var end := start+direction*SPEED*delta
	var ray := PhysicsRayQueryParameters2D.create(start,end,1)
	var wall: Dictionary = get_world_2d().direct_space_state.intersect_ray(ray)
	var segment := end-start
	var length_squared := segment.length_squared()
	var player_t := clampf((knight.global_position-start).dot(segment)/maxf(length_squared,0.0001),0,1)
	var closest := start+segment*player_t
	var wall_t: float = 2.0
	if not wall.is_empty():
		wall_t = (Vector2(wall.position)-start).dot(segment)/maxf(length_squared,0.0001)
	if closest.distance_to(knight.global_position) <= HIT_RADIUS and player_t < wall_t:
		global_position = closest
		expired = true
		return "hit"
	if not wall.is_empty():
		global_position = wall.position
		expired = true
		return "wall"
	global_position = end
	trail_time -= delta
	if trail_time <= 0:
		trail.append(global_position)
		if trail.size()>12:
			trail.pop_front()
		trail_time = 0.035
	queue_redraw()
	return ""

func _draw() -> void:
	var crimson := Color("ef4165") if not frozen else Color("8cecf0")
	var purple := Color("61365f") if not frozen else Color("4b889f")
	for i in range(trail.size()):
		var a := float(i+1)/maxi(1,trail.size())
		var point := Art.pixel_snap(trail[i]-global_position+Vector2(0,-38))
		draw_rect(Rect2(point-Vector2(7,5),Vector2(14,10)),Color(purple,a*0.35))
		draw_rect(Rect2(point-Vector2(3,2),Vector2(6,4)),Color(crimson,a*0.40))
	var center := Vector2(0,-38)
	for i in range(4,0,-1):
		draw_circle(center,9+i*4,Color(purple,0.06))
	# Fractured sigil rather than a round orange fireball.
	draw_colored_polygon(PackedVector2Array([center+Vector2(-16,-2),center+Vector2(-5,-8),center+Vector2(0,-14),center+Vector2(6,-6),center+Vector2(15,0),center+Vector2(4,7),center+Vector2(0,13),center+Vector2(-7,5)]),Color("090916"))
	draw_line(center+Vector2(-8,-4),center+Vector2(7,5),crimson,3,false)
	draw_line(center+Vector2(6,-7),center+Vector2(-5,7),crimson,2,false)
	draw_rect(Rect2(center-Vector2(2,3),Vector2(4,6)),Color("f7a6bd") if not frozen else Color("ddffff"))
	for i in range(4):
		var phase := age*8+i*1.8
		var point := center+Vector2(cos(phase)*18,sin(phase)*14)
		draw_rect(Rect2(Art.pixel_snap(point),Vector2(4,4)),Color(purple,0.8))
	if frozen:
		Art.ring(self,center,24,Color(crimson,0.8),2)
	# A small ground footprint communicates the traversed lane.
	draw_rect(Rect2(-7,1,14,3),Color(0.04,0.01,0.08,0.7))
