extends Node2D
const Art = preload("res://scripts/pixel_art.gd")
signal completed
signal lamp_lit
const RADIUS: float = 155.0
const INTERACT_DISTANCE: float = 72.0
var solved: bool = false
var hunter_inside: bool = false
var clock: float = 0.0
@onready var lamps: Array = [$WestNorthLamp, $WestSouthLamp, $SealLamp]

func _process(delta: float) -> void:
	clock += delta
	queue_redraw()

func lit_count() -> int:
	var count := 0
	for lamp in lamps:
		if lamp.lit:
			count += 1
	return count

func inside_ring(point: Vector2) -> bool:
	# Count the enemy's complete collision circle, not just its center.
	return global_position.distance_to(point) <= RADIUS - 18.0

func nearest_lamp(point: Vector2) -> Node2D:
	var nearest: Node2D = null
	var distance := INTERACT_DISTANCE
	for lamp in lamps:
		var candidate: float = lamp.global_position.distance_to(point)
		if candidate <= distance:
			nearest = lamp
			distance = candidate
	return nearest

func interact(point: Vector2, hunter: Node, time_power: Node) -> String:
	if solved:
		return "The circle holds. Follow the gold path to the eastern arch."
	var lamp := nearest_lamp(point)
	if lamp == null:
		return "Move close to a lamp and press E."
	if lamp.lit:
		return "This lamp is already burning."
	if not lamp.final_lamp:
		lamp.lit = true
		lamp_lit.emit()
		return "Lamp kindled. The east lamp seals the trap."
	if lit_count() < 2:
		return "Light the two western lamps first."
	if not inside_ring(hunter.global_position):
		return "Lure the shadow fully inside the circle. Stand near the east lamp."
	if time_power.freeze_remaining <= 0.0:
		return "The shadow must be FROZEN. Press Space, then E."
	lamp.lit = true
	solved = true
	hunter.trap()
	completed.emit()
	return "The shadow is bound. +35 flame. The eastern gate is open."

func update_feedback(point: Vector2, hunter: Node) -> void:
	hunter_inside = inside_ring(hunter.global_position)
	var nearest := nearest_lamp(point)
	for lamp in lamps:
		lamp.highlight = lamp == nearest and not lamp.lit
		lamp.seal_ready = lit_count() >= 2 and hunter_inside
		lamp.frozen_ready = lamp.seal_ready and hunter.state == hunter.State.FROZEN

func reset() -> void:
	solved = false
	hunter_inside = false
	for lamp in lamps:
		lamp.lit = false
		lamp.highlight = false
	queue_redraw()


func _draw() -> void:
	var col := Color("e9bd6f") if solved else Color("5b9eb8")
	# Broken eastern arc remains exactly the same logical trap as Stage A.
	Art.ring(self,Vector2.ZERO,RADIUS+8,Color("6a6b7e"),2)
	if solved:
		for i in range(4):
			Art.ring(self,Vector2.ZERO,RADIUS+i*3,Color(col,0.12),4)
		Art.ring(self,Vector2.ZERO,RADIUS,col,4)
	else:
		Art.ring(self,Vector2.ZERO,RADIUS,Color(col,0.8),2,0.35,TAU-0.35)
		if lit_count() >= 2:
			var alpha := 0.6+sin(clock*3)*0.2
			Art.ring(self,Vector2.ZERO,RADIUS,Color(1,0.76,0.35,alpha),4,-0.35,0.35)
	for i in range(16):
		var angle := TAU*i/16
		var a := Vector2.from_angle(angle)
		var center := Art.pixel_snap(a*(RADIUS-15))
		draw_line(center-Vector2(3,5),center+Vector2(3,5),Color(col,0.75),2,false)
		draw_line(center+Vector2(3,-5),center+Vector2(-3,5),Color(col,0.75),2,false)
	Art.ring(self,Vector2.ZERO,44,Color(col,0.38),2)
	draw_line(Vector2(-15,-25),Vector2(15,25),col,2,false)
	draw_line(Vector2(15,-25),Vector2(-15,25),col,2,false)
	draw_line(Vector2(-15,-25),Vector2(15,-25),col,2,false)
	draw_line(Vector2(-15,25),Vector2(15,25),col,2,false)
	# Three lit rune tiles communicate progress without reading a paragraph.
	for i in range(3):
		var point := Vector2(-28+i*28,-190)
		draw_rect(Rect2(point-Vector2(8,8),Vector2(16,16)),Color("0b1424"))
		var glyph_col := Color("f7cb79") if lamps[i].lit else Color("4c637c")
		draw_line(point+Vector2(-4,-5),point+Vector2(4,5),glyph_col,2,false)
		draw_line(point+Vector2(4,-5),point+Vector2(-4,5),glyph_col,2,false)
	if hunter_inside and not solved:
		Art.ring(self,Vector2.ZERO,RADIUS-6,Color(1,0.79,0.36,0.38),2)
