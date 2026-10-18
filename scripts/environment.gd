extends Node2D
## Existing collision layout retained. Static drawing is cached until a world flag changes.
const Art = preload("res://scripts/pixel_art.gd")
const WALK_RECT := Rect2(90,242,1740,596)
const PROTECTED_RECT := Rect2(970,295,565,490)
const CHECKPOINT := Vector2(800,540)
const EXIT := Vector2(1770,540)
var gate_open: bool = false
var checkpoint_lit: bool = false:
	set(value):
		checkpoint_lit = value
		queue_redraw()
var clock: float = 0.0
var gate_shape: CollisionShape2D
var rubble: Array[Vector2] = []

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_wall(Rect2(70,220,1780,22))
	add_wall(Rect2(70,838,1780,22))
	add_wall(Rect2(70,220,20,640))
	add_wall(Rect2(1830,220,20,640))
	add_wall(Rect2(1685,242,28,233))
	add_wall(Rect2(1685,605,28,233))
	gate_shape = add_wall(Rect2(1685,475,28,130))
	var rng := RandomNumberGenerator.new()
	rng.seed = 583861
	for i in range(150):
		rubble.append(Vector2(rng.randi_range(108,1808),rng.randi_range(254,310) if i%2 else rng.randi_range(775,828)).snapped(Vector2(2,2)))

func add_wall(rect: Rect2) -> CollisionShape2D:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	body.position = rect.get_center()
	body.add_child(shape)
	add_child(body)
	return shape

func set_exit_open(open: bool) -> void:
	gate_open = open
	gate_shape.set_deferred("disabled",open)
	queue_redraw()

func is_protected(point: Vector2) -> bool:
	return PROTECTED_RECT.has_point(point) or point.distance_to(CHECKPOINT)<68.0

func _draw() -> void:
	draw_rect(Rect2(0,0,1920,1080),Color("060a14"))
	# Fractured rock shelves and silhouettes frame the intact playable stone platform.
	for i in range(58):
		var x := float(i)*34
		var h := 22+((i*37)%65)
		draw_rect(Rect2(x,175-h,32,h+60),Color("111b2c"))
		draw_rect(Rect2(x+4,175-h,24,6),Color("253349"))
		draw_rect(Rect2(x,870,32,h+100),Color("101a2c"))
		draw_rect(Rect2(x+4,870,24,4),Color("334155"))
	for i in range(18):
		var x := 24.0+i*112
		dead_tree(Vector2(x,150-(i%3)*20),0.8+(i%2)*0.2)
		dead_tree(Vector2(x+34,1040),1.1)
	draw_rect(Rect2(76,242,1768,644),Color("080d18"))
	draw_rect(WALK_RECT,Color("101728"))
	# Small chipped masonry replaces the old large flat rectangles.
	for row in range(19):
		for col in range(55):
			var x := 90+col*32+(16 if row%2 else 0)
			var y := 242+row*32
			if x+30>1830 or y+30>838:
				continue
			var seed_value := absi(row*157+col*73)
			var tint := float(seed_value%5)*0.008
			var warm_path := y>=466 and y<=594
			var base := Color(0.13+tint,0.16+tint,0.23+tint)
			if warm_path:
				base = Color(0.19+tint,0.19+tint,0.235+tint)
			draw_rect(Rect2(x+2,y+2,28,28),base)
			draw_line(Vector2(x+4,y+2),Vector2(x+27,y+2),Color(base.lightened(0.16),0.7),2,false)
			draw_line(Vector2(x+2,y+4),Vector2(x+2,y+26),Color(base.lightened(0.08),0.6),2,false)
			draw_rect(Rect2(x+4,y+28,24,2),Color("101522"))
			if seed_value%3 == 0:
				var a := Vector2(x+12,y+4)
				draw_line(a,a+Vector2(4,8),Color("111827"),2,false)
				draw_line(a+Vector2(4,8),a+Vector2(0,12),Color("111827"),2,false)
			if seed_value%4 == 0:
				draw_rect(Rect2(x+6+(seed_value%7)*2,y+6,2,2),Color(base.lightened(0.2)))
			if not warm_path and seed_value%5 == 0:
				for i in range(3):
					draw_rect(Rect2(x+2+i*4,y+24-(i%2)*2,4,2),Color("263d3c"))
	# Inlaid borders and warm directional chevrons keep the eastward route obvious.
	for y in [456,620]:
		draw_rect(Rect2(94,y,1572,4),Color("0b101c"))
		for x in range(102,1660,22):
			draw_rect(Rect2(x,y+1,14,2),Color("5b5147"))
	for x in range(245,1635,126):
		if x>1000 and x<1460:
			continue
		draw_line(Vector2(x-6,534),Vector2(x+2,540),Color("a08b61"),2,false)
		draw_line(Vector2(x+2,540),Vector2(x-6,546),Color("a08b61"),2,false)
	# Raised shrine dais: the collision surface remains the same flat, open courtyard.
	draw_circle(Vector2(1240,549),224,Color("080e1d"))
	draw_circle(Vector2(1240,541),224,Color("354055"))
	draw_circle(Vector2(1240,537),216,Color("1b263a"))
	for row in range(-6,7):
		for col in range(-6,7):
			var tile := Vector2(col*30,row*30)
			if tile.length()>187:
				continue
			var point := Vector2(1240,537)+tile
			var tint := float(absi(col*43+row*19)%4)*0.006
			draw_rect(Rect2(point-Vector2(13,13),Vector2(27,27)),Color(0.10+tint,0.15+tint,0.22+tint))
			draw_rect(Rect2(point+Vector2(-11,-13),Vector2(23,2)),Color(0.24,0.31,0.39,0.4))
	Art.ring(self,Vector2(1240,537),217,Color("59617a"),2)
	Art.ring(self,Vector2(1240,537),203,Color("303c53"),4)
	for i in range(24):
		var a := Vector2.from_angle(i*TAU/24)
		draw_line(Art.pixel_snap(Vector2(1240,537)+a*204),Art.pixel_snap(Vector2(1240,537)+a*220),Color("121b2a"),2,false)
	for offset in [Vector2(-155,-130),Vector2(155,-130),Vector2(-155,130),Vector2(155,130)]:
		rune(Vector2(1240,537)+offset,Color("4d7487"),2)
	# Small stones and dead grass sit at the edges, leaving the center unobstructed.
	for i in range(rubble.size()):
		var at := rubble[i]
		draw_rect(Rect2(at+Vector2(2,4),Vector2(12,6)),Color("0c1320"))
		draw_rect(Rect2(at,Vector2(8+i%3*2,4)),Color("3b4559"))
		draw_rect(Rect2(at,Vector2(6,2)),Color("5a6070"))
		if i%3 == 0:
			for j in range(3):
				draw_line(at+Vector2(j*4,0),at+Vector2(j*4-2,-4-j%2*4),Color("344446"),2,false)
	# Boundary walls and broken watch statues are outside the original collision surface.
	for x in range(90,1831,48):
		wall_block(Vector2(x,218),false)
		wall_block(Vector2(x,838),true)
	for x in [215,570,970,1500]:
		statue(Vector2(x,231))
		statue(Vector2(x,870))
	# Sanctuary: a carved sun in pale stone, visibly untouched by corruption.
	draw_circle(CHECKPOINT+Vector2(0,5),73,Color("0a1220"))
	draw_circle(CHECKPOINT,70,Color("3e4553"))
	draw_circle(CHECKPOINT,64,Color("242d3d"))
	Art.ring(self,CHECKPOINT,62,Color("c09b65") if checkpoint_lit else Color("657e96"),2)
	for i in range(12):
		var a := Vector2.from_angle(i*TAU/12)
		draw_line(Art.pixel_snap(CHECKPOINT+a*51),Art.pixel_snap(CHECKPOINT+a*57),Color("c1a26b"),2,false)
	rune(CHECKPOINT,Color("8bafbb"),4)
	# East arch is exactly aligned with its original collision walls.
	for y in range(242,839,32):
		if y<475 or y>605:
			draw_rect(Rect2(1685,y,28,30),Color("344055"))
			draw_rect(Rect2(1687,y+2,24,3),Color("6b6b7d"))
			draw_rect(Rect2(1685,y+26,28,4),Color("161e30"))
	if not gate_open:
		for y in range(480,606,16):
			draw_rect(Rect2(1684,y,32,2),Color("67b7cd"))
		draw_rect(Rect2(1697,475,4,130),Color("72cddd"))
	for at in [Vector2(1698,470),Vector2(1698,614)]:
		draw_rect(Rect2(at-Vector2(24,4),Vector2(48,8)),Color("82838e"))
		rune(at+Vector2(0,-12),Color("c69c61"),2)
	# A readable inscription is cut into a plaque rather than floating on bare tiles.
	draw_rect(Rect2(987,721,512,54),Color("0b1221"))
	draw_rect(Rect2(989,721,508,2),Color("505168"))
	world_text(Vector2(1013,742),"TWO FLAMES. LURE WITHIN. STILL TIME.",16,Color("b6bbcc"))
	world_text(Vector2(1080,763),"SEAL THE THIRD.",16,Color("d7bd8a"))
	world_text(Vector2(1058,320),"SHRINE OF LOST HOURS",22,Color("8b9db6"))
	world_text(Vector2(701,641),"EMBER SANCTUARY",16,Color("ccb586"))
	world_text(Vector2(1736,442),"DAWN",18,Color("c5ab7f"))

func wall_block(at: Vector2, bottom: bool) -> void:
	draw_rect(Rect2(at,Vector2(46,22)),Color("2d374d"))
	draw_rect(Rect2(at+Vector2(2,2),Vector2(42,4)),Color("596075"))
	draw_rect(Rect2(at+Vector2(0,22),Vector2(46,12 if bottom else 2)),Color("141b2e"))
	draw_rect(Rect2(at+Vector2(8,7),Vector2(28,2)),Color("3c465c"))

func statue(at: Vector2) -> void:
	draw_set_transform(at)
	draw_rect(Rect2(-23,-2,46,12),Color("141b2b"))
	draw_rect(Rect2(-21,-5,42,6),Color("586074"))
	draw_rect(Rect2(-16,-12,32,8),Color("303b51"))
	var image := Art.knight_frame(2,0)
	draw_texture_rect(image,Rect2(-32,-86,64,76),false,Color("626e89"))
	draw_rect(Rect2(-4,-60,2,14),Color("9eafbe"))
	draw_set_transform(Vector2.ZERO)

func dead_tree(at: Vector2, scale_value: float) -> void:
	draw_set_transform(at,0,Vector2.ONE*scale_value)
	draw_line(Vector2(0,0),Vector2(-4,-74),Color("0a101e"),10,false)
	for i in range(5):
		var side := -1 if i%2 else 1
		var y := -20-i*11
		draw_line(Vector2(0,y),Vector2(side*(22+i*3),y-23),Color("0a101e"),4,false)
		draw_line(Vector2(side*(18+i*2),y-20),Vector2(side*(15+i*2),y-36),Color("0a101e"),2,false)
	draw_set_transform(Vector2.ZERO)

func rune(at: Vector2, color: Color, scale_value: int) -> void:
	var lines := [Vector4(-3,-4,3,4),Vector4(3,-4,-3,4),Vector4(0,-6,0,6),Vector4(-3,-4,0,-6),Vector4(3,4,0,6)]
	for line in lines:
		draw_line(Art.pixel_snap(at+Vector2(line.x,line.y)*scale_value),Art.pixel_snap(at+Vector2(line.z,line.w)*scale_value),color,2,false)

func world_text(at: Vector2, words: String, size: int, color: Color) -> void:
	draw_string(ThemeDB.fallback_font,at,words,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)
