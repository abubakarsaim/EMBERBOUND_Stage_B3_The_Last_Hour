extends Node2D
## Bounded visual-only trail. Grid stains persist for the attempt, sacred light cleanses.
const CELL: float = 24.0
const MAX_CELLS: int = 560
const WALK_RECT := Rect2(96,250,1728,580)
var walk_bounds: Rect2 = WALK_RECT
var sacred_test: Callable
var stains: Dictionary = {}
var insertion_order: Array[Vector2i] = []
var clock: float = 0.0
var emission_remaining: float = 0.0
var last_position := Vector2.INF
var hunter: Node2D
var puzzle: Node2D
var sanctuary := Vector2(800,540)
var draw_timer: float = 0.0
var maintenance_delta: float = 0.0

func tick(delta: float) -> void:
	clock += delta
	emission_remaining -= delta
	draw_timer -= delta
	maintenance_delta += delta
	if hunter == null or puzzle == null:
		return
	# No new trail while time holds the hunter, or after it is trapped.
	if hunter.active and hunter.state != hunter.State.FROZEN and hunter.state != hunter.State.TRAPPED:
		if emission_remaining <= 0.0 and (last_position == Vector2.INF or hunter.global_position.distance_to(last_position) >= 9.0):
			stamp(hunter.global_position)
			last_position = hunter.global_position
			emission_remaining = 0.09
	# Grow/cleanse the bounded grid at 12.5 Hz rather than scanning 560 cells at 60 Hz.
	if draw_timer > 0:
		return
	var elapsed := maintenance_delta
	maintenance_delta = 0
	# Fade cleansed cells without recalculating all stain geometry every frame.
	var remove: Array[Vector2i] = []
	for key in stains:
		var point := cell_position(key)
		if sacred(point):
			stains[key] = maxf(0.0,float(stains[key])-elapsed*2.0)
		elif stains[key] < 1.0:
			stains[key] = minf(1.0,float(stains[key])+elapsed*0.7)
		if stains[key] <= 0.0:
			remove.append(key)
	for key in remove:
		stains.erase(key)
		insertion_order.erase(key)
	if draw_timer <= 0.0:
		queue_redraw()
		draw_timer = 0.08

func sacred(point: Vector2) -> bool:
	if sacred_test.is_valid():
		return sacred_test.call(point)
	if point.distance_to(sanctuary) < 88.0:
		return true
	if puzzle == null:
		return false
	if puzzle.solved and point.distance_to(puzzle.global_position) < puzzle.RADIUS+24:
		return true
	for lamp in puzzle.lamps:
		if lamp.lit and point.distance_to(lamp.global_position) < 50.0:
			return true
	return false

func cell_position(key: Vector2i) -> Vector2:
	return Vector2(key)*CELL+Vector2.ONE*CELL*0.5

func stamp(point: Vector2) -> void:
	if not walk_bounds.has_point(point):
		return
	var center := Vector2i(floori(point.x/CELL),floori(point.y/CELL))
	for offset in [Vector2i.ZERO,Vector2i(-1,0),Vector2i(1,0),Vector2i(0,-1),Vector2i(0,1)]:
		var key: Vector2i = center+offset
		var at := cell_position(key)
		if not walk_bounds.has_point(at) or sacred(at):
			continue
		if not stains.has(key):
			if insertion_order.size() >= MAX_CELLS:
				var oldest: Vector2i = insertion_order.pop_front()
				stains.erase(oldest)
			insertion_order.append(key)
			stains[key] = 0.35
		else:
			stains[key] = minf(1.0,float(stains[key])+0.25)
	queue_redraw()

func clear() -> void:
	stains.clear()
	insertion_order.clear()
	last_position = Vector2.INF
	emission_remaining = 0.0
	clock = 0.0
	draw_timer = 0.0
	maintenance_delta = 0.0
	queue_redraw()

func contains(point: Vector2) -> bool:
	var key := Vector2i(floori(point.x/CELL),floori(point.y/CELL))
	return stains.has(key) and float(stains[key]) > 0.3


func _draw() -> void:
	for key in stains:
		var strength: float = stains[key]
		var seed_value: int = absi(key.x*73+key.y*199)
		var origin := Vector2(key)*CELL
		var center := origin+Vector2(8+seed_value%9,7+(seed_value/5)%11)
		var pulse := 0.96+sin(clock*1.7+seed_value)*0.04
		var radius := float(10+seed_value%12)
		draw_circle(center,radius+8,Color(0.07,0.025,0.11,0.18*strength))
		var silhouette := PackedVector2Array()
		for i in range(12):
			var angle := float(i)*TAU/12.0
			var reach := radius+float((seed_value+i*17)%13)-5.0
			silhouette.append((center+Vector2.from_angle(angle)*reach).snapped(Vector2(2,2)))
		draw_colored_polygon(silhouette,Color(0.011,0.008,0.023,0.62*strength*pulse))
		draw_circle(center,radius*0.60,Color(0.01,0.008,0.025,0.25*strength))
		# Frayed branches and scattered pixels break the grid into creeping, torn edges.
		for i in range(3):
			var angle := float((seed_value+i*91)%360)*PI/180
			var a := (center+Vector2.from_angle(angle)*radius*0.6).snapped(Vector2(2,2))
			var b := (center+Vector2.from_angle(angle)*(radius+10)).snapped(Vector2(2,2))
			draw_line(a,b,Color(0.035,0.015,0.065,0.52*strength),4,false)
			draw_rect(Rect2(b-Vector2(2,2),Vector2(4,4)),Color(0.08,0.025,0.10,0.48*strength))
		if seed_value%4 == 0:
			var a := center-Vector2(4,3)
			draw_line(a,a+Vector2(8,4),Color(0.33,0.065,0.18,0.40*strength),2,false)
			draw_line(a+Vector2(8,4),a+Vector2(10,13),Color(0.24,0.04,0.14,0.40*strength),2,false)
