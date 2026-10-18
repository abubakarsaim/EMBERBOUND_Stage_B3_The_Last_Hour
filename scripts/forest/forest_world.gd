extends Node2D
## Static floor, collision and authored landmarks. Animation lives in a separate layer.
const Art = preload("res://scripts/forest/forest_art.gd")
const CHECKPOINT := Vector2(380,2000)
const EXIT := Vector2(4440,1300)
const BOUNDS := Rect2(128,180,4352,2460)
const CLUES := [Vector2(1050,750),Vector2(2450,500),Vector2(3050,2150)]
const TORCHES := [Vector2(820,1500),Vector2(1800,620),Vector2(2800,1450),Vector2(3530,1870)]
var paths: Array[PackedVector2Array] = [
	PackedVector2Array([Vector2(380,2000),Vector2(850,2000),Vector2(850,900),Vector2(1500,900),Vector2(1500,500),Vector2(2450,500),Vector2(2750,900),Vector2(2800,1400),Vector2(3050,2150),Vector2(3550,2150),Vector2(3870,1300),Vector2(4440,1300)]),
	PackedVector2Array([Vector2(1500,900),Vector2(1800,1450),Vector2(2800,1400),Vector2(3870,1300)]),
	PackedVector2Array([Vector2(850,900),Vector2(1050,750)]),
	PackedVector2Array([Vector2(1800,1450),Vector2(1850,2050),Vector2(2350,2100)])]
var gate_open: bool = false
var checkpoint_lit: bool = true
var gate_shape: CollisionShape2D
var obstacles: Array[Vector3] = []
var torch_timers: Array[float] = [0.0,0.0,0.0,0.0]
var nav := AStarGrid2D.new()
var navigation_builds: int = 0

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_wall(Rect2(96,148,4416,32))
	add_wall(Rect2(96,2640,4416,32))
	add_wall(Rect2(96,148,32,2524))
	add_wall(Rect2(4480,148,32,2524))
	add_wall(Rect2(4310,180,28,1000))
	add_wall(Rect2(4310,1420,28,1220))
	gate_shape = add_wall(Rect2(4310,1180,28,240))
	var rng := RandomNumberGenerator.new()
	rng.seed = 511831
	for i in range(860):
		var at := Vector2(rng.randi_range(160,4260),rng.randi_range(250,2580)).snapped(Vector2(2,2))
		if on_path(at,130) or on_path(at-Vector2(0,110),150) or near_landmark(at,300): continue
		var close := false
		for obstacle in obstacles:
			if at.distance_to(Vector2(obstacle.x,obstacle.y)) < 86:
				close = true
				break
		if close: continue
		var sprite := Sprite2D.new()
		sprite.texture = load("res://assets/forest/twisted_tree_%d.png" % (i%3))
		sprite.position = at+Vector2(0,-120)
		sprite.scale = Vector2.ONE*2
		sprite.z_index = 1
		add_child(sprite)
		var body := StaticBody2D.new()
		body.position = at
		body.collision_layer = 1
		body.collision_mask = 0
		var collision := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 20
		collision.shape = circle
		body.add_child(collision)
		add_child(body)
		obstacles.append(Vector3(at.x,at.y,20))
	for at in [Vector2(970,640),Vector2(1150,650),Vector2(2360,390),Vector2(2570,380),Vector2(2940,2040),Vector2(3180,2040),Vector2(3780,1090),Vector2(4130,1090),Vector2(3780,1500),Vector2(4130,1500)]:
		var sprite := Sprite2D.new()
		sprite.texture = preload("res://assets/forest/broken_pillar.png")
		sprite.position = at-Vector2(0,56)
		sprite.scale = Vector2.ONE*2
		sprite.z_index = 1
		add_child(sprite)
		add_wall(Rect2(at-Vector2(24,12),Vector2(48,24)))
		obstacles.append(Vector3(at.x,at.y,30))
	# The optional watchhouse has physical walls with a broad southern entrance.
	for rect in [Rect2(1700,1940,110,28),Rect2(1890,1940,110,28),Rect2(1700,1940,24,190),Rect2(1980,1940,24,190)]:
		add_wall(rect)
		for x in range(int(rect.position.x),int(rect.end.x)+1,32):
			for y in range(int(rect.position.y),int(rect.end.y)+1,32): obstacles.append(Vector3(x,y,18))
	build_navigation()

func on_path(at: Vector2, radius: float = 95) -> bool:
	for path in paths:
		for i in range(path.size()-1):
			if at.distance_to(Geometry2D.get_closest_point_to_segment(at,path[i],path[i+1])) < radius: return true
	return false

func near_landmark(at: Vector2, radius: float) -> bool:
	for center in [CHECKPOINT,CLUES[0],CLUES[1],CLUES[2],Vector2(3970,1300),Vector2(1850,2050)]:
		if at.distance_to(center) < radius: return true
	for center in TORCHES:
		if at.distance_to(center)<100: return true
	return false

func add_wall(rect: Rect2) -> CollisionShape2D:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = rect.get_center()
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	body.add_child(shape)
	add_child(body)
	return shape

func build_navigation() -> void:
	nav.region = Rect2i(0,0,72,44)
	nav.cell_size = Vector2(64,64)
	nav.offset = Vector2(32,32)
	nav.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	nav.update()
	for y in range(44):
		for x in range(72):
			var at := Vector2(x*64+32,y*64+32)
			var solid := not BOUNDS.grow(-24).has_point(at) or (absf(at.x-4324)<48 and (at.y<1180 or at.y>1420 or not gate_open))
			for obstacle in obstacles:
				if at.distance_to(Vector2(obstacle.x,obstacle.y))<obstacle.z+40:
					solid = true
					break
			nav.set_point_solid(Vector2i(x,y),solid)
	navigation_builds += 1

func nearest_cell(point: Vector2) -> Vector2i:
	var cell := Vector2i(point/64)
	if nav.is_in_boundsv(cell) and not nav.is_point_solid(cell): return cell
	for radius in range(1,5):
		for y in range(-radius,radius+1):
			for x in range(-radius,radius+1):
				var other := cell+Vector2i(x,y)
				if nav.is_in_boundsv(other) and not nav.is_point_solid(other): return other
	return Vector2i(5,30)

func route(from: Vector2, to: Vector2) -> PackedVector2Array:
	return nav.get_point_path(nearest_cell(from),nearest_cell(to))

func set_exit_open(open: bool) -> void:
	gate_open = open
	gate_shape.set_deferred("disabled",open)
	build_navigation()
	queue_redraw()

func tick(delta: float) -> void:
	for i in range(torch_timers.size()):
		torch_timers[i] = maxf(0,torch_timers[i]-delta)

func is_protected(at: Vector2) -> bool:
	if at.distance_to(CHECKPOINT)<90: return true
	for i in range(3):
		if at.distance_to(CLUES[i])<110: return true
	for i in range(TORCHES.size()):
		if torch_timers[i]>0 and at.distance_to(TORCHES[i])<100: return true
	return at.distance_to(Vector2(3970,1300))<245

func _draw() -> void:
	draw_rect(Rect2(0,0,4608,2816),Color("060b16"))
	# Mossy, dappled soil and fragmented paving are cached, not rebuilt per frame.
	for y in range(192,2640,32):
		for x in range(128,4480,32):
			var at := Vector2(x,y)
			var hash_value := absi(x*13+y*71)
			var path := on_path(at)
			var shade := (hash_value%7)*0.004
			var col := Color(0.08+shade,0.12+shade,0.17+shade) if not path else Color(0.18+shade,0.20+shade,0.26+shade)
			if path and hash_value%11<9:
				draw_rect(Rect2(at+Vector2(1,1),Vector2(29,28)),col)
				draw_line(at+Vector2(4,2),at+Vector2(26,2),Color("475064"),2,false)
				if hash_value%3==0:
					draw_line(at+Vector2(12,2),at+Vector2(16,13),Color("121c2a"),2,false)
					draw_line(at+Vector2(16,13),at+Vector2(10,26),Color("121c2a"),2,false)
			else:
				draw_rect(Rect2(at,Vector2(32,32)),col)
				for k in range(3):
					draw_rect(Rect2(at+Vector2(4+k*8,8+(hash_value+k*3)%16),Vector2(4,2)),Color("293747") if path else Color("233d39"))
	for i in range(3):
		var at: Vector2 = CLUES[i]
		draw_circle(at,152,Color("111b2a"))
		for radius in [148,132]:
			preload("res://scripts/pixel_art.gd").ring(self,at,radius,Color("3c485d"),2)
		for j in range(12):
			var p := at+Vector2.from_angle(j*TAU/12)*137
			draw_rect(Rect2(p.snapped(Vector2(2,2)),Vector2(10,6)),Color("516073"))
		# Three recognizable remnants: root-entwined memorial, bell, royal tomb.
		if i==0:
			for j in range(6):
				var p := at+Vector2((j-3)*17,-40)
				draw_line(p,p+Vector2((j-3)*16,38),Color("3c303e"),6,false)
		if i==1:
			draw_rect(Rect2(at+Vector2(-54,-111),Vector2(108,12)),Color("4a4e64"))
			draw_colored_polygon(PackedVector2Array([at+Vector2(-28,-98),at+Vector2(28,-98),at+Vector2(46,-45),at+Vector2(-46,-45)]),Color("76624e"))
			draw_rect(Rect2(at+Vector2(-48,-47),Vector2(96,8)),Color("b09b72"))
			draw_line(at+Vector2(8,-97),at+Vector2(-6,-42),Color("202035"),4,false)
		if i==2:
			draw_rect(Rect2(at+Vector2(-65,-94),Vector2(130,54)),Color("30374c"))
			draw_rect(Rect2(at+Vector2(-70,-99),Vector2(140,9)),Color("657084"))
			Art.glyph(self,at+Vector2(0,-73),2,Color("ae946d"))
	# Deserted watchhouse, an optional refuge and inscription south of the central fork.
	for rect in [Rect2(1700,1940,110,28),Rect2(1890,1940,110,28),Rect2(1700,1940,24,190),Rect2(1980,1940,24,190)]:
		draw_rect(rect,Color("283449"))
		draw_rect(Rect2(rect.position,Vector2(rect.size.x,4)),Color("566176"))
	text(Vector2(1720,2160),"THE ABANDONED WATCH",18,Color("8096b1"))
	# Long thorn wall makes the gate physically unskippable.
	for y in range(180,2640,24):
		if y>1160 and y<1440: continue
		draw_rect(Rect2(4300,y,48,22),Color("172236"))
		draw_line(Vector2(4304,y),Vector2(4348,y+22),Color("3b304a"),4,false)
	for at in [Vector2(4324,1160),Vector2(4324,1440)]:
		draw_rect(Rect2(at-Vector2(46,8),Vector2(92,20)),Color("596279"))
	if not gate_open:
		for y in range(1180,1420,18):
			draw_line(Vector2(4310,y),Vector2(4338,y+12),Color("6591bc"),3,false)
	else:
		text(Vector2(4360,1190),"TO THE SHRINE",18,Color("efd19a"))
	text(Vector2(290,2140),"THE LAST WATCHFIRE",20,Color("d6b77f"))
	text(Vector2(3720,1010),"THE FORGOTTEN FLAMES",23,Color("96b9cc"))

func text(at: Vector2, words: String, size_value: int, col: Color) -> void:
	draw_string(ThemeDB.fallback_font,at,words,HORIZONTAL_ALIGNMENT_LEFT,-1,size_value,col)
