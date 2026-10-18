extends Node2D
const Art = preload("res://scripts/pixel_art.gd")
const RuneArt = preload("res://scripts/forest/forest_art.gd")
const CHECKPOINT := Vector2(1536,2200)
const EXIT := Vector2(2820,580)
const PRINCESS := Vector2(1536,780)
const SEAL := Vector2(1536,1000)
const MIRROR := Vector2(830,930)
const CLOCK := Vector2(2310,1470)
const BOUNDS := Rect2(200,300,2660,2020)
const TORCHES := [Vector2(400,700),Vector2(400,1230),Vector2(400,1810),Vector2(2660,890),Vector2(2660,1900)]
var gate_open: bool = false
var encounter_active: bool = false
var seal_armed: bool = false
var cleansed: bool = false
var light_court: bool = false
var checkpoint_lit: bool = true
var gate_shape: CollisionShape2D
var columns: Array[Vector2] = []
var blocks: Array[Rect2] = []
var nav := AStarGrid2D.new()
var reveal_glow: bool = false

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_wall(Rect2(168,268,2724,32))
	add_wall(Rect2(168,2320,2724,32))
	add_wall(Rect2(168,268,32,2084))
	add_wall(Rect2(2860,268,32,2084))
	add_wall(Rect2(2740,300,28,170))
	add_wall(Rect2(2740,690,28,1630))
	gate_shape = add_wall(Rect2(2740,470,28,220),false)
	for x in [600,2470]:
		for y in [650,1150,1650,2150]:
			var at := Vector2(x,y)
			columns.append(at)
			add_sprite("column",at+Vector2(0,-152),Vector2(2,2),1)
			add_wall(Rect2(at-Vector2(44,20),Vector2(88,40)))
	for x in [940,2130]:
		for y in [330,2310]:add_sprite("torn_banner",Vector2(x,y-130),Vector2(2,2),1)
	for x in [420,960,2110,2640]:add_sprite("broken_window",Vector2(x,260),Vector2(2,2),0)
	add_sprite("throne",Vector2(1536,366),Vector2(2,2),1)
	add_wall(Rect2(1396,420,280,180))
	for at in [Vector2(900,1450),Vector2(2170,900),Vector2(2180,2100)]:
		add_wall(Rect2(at-Vector2(28,18),Vector2(56,36)))
	add_wall(Rect2(MIRROR-Vector2(55,45),Vector2(110,42)))
	add_wall(Rect2(CLOCK-Vector2(58,70),Vector2(116,52)))
	build_nav()

func add_sprite(asset: String, at: Vector2, scale_value: Vector2, order: int) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = load("res://assets/royal/%s.png" % asset)
	sprite.position = at
	sprite.scale = scale_value
	sprite.z_index = order
	add_child(sprite)

func add_wall(rect: Rect2, remember: bool = true) -> CollisionShape2D:
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
	if remember: blocks.append(rect)
	return shape

func build_nav() -> void:
	nav.region = Rect2i(0,0,48,39)
	nav.cell_size = Vector2(64,64)
	nav.offset = Vector2(32,32)
	nav.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	nav.update()
	for y in range(39):
		for x in range(48):
			var at := Vector2(x*64+32,y*64+32)
			var solid := not BOUNDS.grow(-22).has_point(at)
			for block in blocks:
				if block.grow(28).has_point(at): solid = true
			if not gate_open and Rect2(2712,442,84,276).has_point(at): solid = true
			nav.set_point_solid(Vector2i(x,y),solid)

func nav_cell(at: Vector2) -> Vector2i:
	var cell := Vector2i(at/64)
	for radius in range(5):
		for y in range(-radius,radius+1):
			for x in range(-radius,radius+1):
				var other := cell+Vector2i(x,y)
				if nav.is_in_boundsv(other) and not nav.is_point_solid(other): return other
	return Vector2i(24,33)

func route(from: Vector2, to: Vector2) -> PackedVector2Array:
	return nav.get_point_path(nav_cell(from),nav_cell(to))

func set_exit_open(open: bool) -> void:
	gate_open = open
	reveal_glow = open
	gate_shape.set_deferred("disabled",open)
	build_nav()
	queue_redraw()

func is_protected(at: Vector2) -> bool:
	if cleansed or gate_open: return true
	if at.distance_to(CHECKPOINT)<125 or at.distance_to(MIRROR)<165 or at.distance_to(CLOCK)<145: return true
	if at.distance_to(Vector2(1536,1530))<125: return true
	if encounter_active: return seal_armed and at.distance_to(SEAL)<80
	if at.distance_to(Vector2(1536,900))<440 or at.distance_to(Vector2(1536,1390))<135: return true
	if light_court:
		# Sacred receivers repel corruption and permit unhurried reading/rotation.
		return Rect2(1030,810,240,840).has_point(at) or Rect2(730,810,500,240).has_point(at) or Rect2(1040,1410,620,240).has_point(at)
	return false

func _draw() -> void:
	draw_rect(Rect2(0,0,3072,2496),Color("060914"))
	# Massive wall faces, damaged moonlit windows, and stepped gold cornices.
	draw_rect(Rect2(176,40,2710,262),Color("141c30"))
	for y in range(52,300,32):
		for x in range(180,2880,64):
			draw_rect(Rect2(x+(16 if y%64==20 else 0),y,60,28),Color("202b41"))
	for y in [272,282,294]:draw_rect(Rect2(186,y,2690,3),Color("7e694e"))
	draw_rect(BOUNDS,Color("11182a"))
	for y in range(304,2320,32):
		for x in range(208,2860,32):
			var hash_value: int = absi(x*23+y*71)
			var shade := (hash_value%7)*0.006
			var base := Color(0.14+shade,0.17+shade,0.23+shade)
			draw_rect(Rect2(x+1,y+1,29,29),base)
			draw_line(Vector2(x+3,y+2),Vector2(x+27,y+2),base.lightened(0.19),2,false)
			if hash_value%5==0:
				draw_line(Vector2(x+12,y+3),Vector2(x+18,y+12),Color("0b1424"),2,false)
				draw_line(Vector2(x+18,y+12),Vector2(x+14,y+27),Color("0b1424"),2,false)
	# Interlaced gold borders, diamond inlays and cracks distinguish this from the shrine.
	for x in [290,1140,1920,2690]:
		draw_rect(Rect2(x,310,3,1998),Color("695b49"))
		for y in range(342,2280,88):
			draw_colored_polygon(PackedVector2Array([Vector2(x,y-8),Vector2(x+8,y),Vector2(x,y+8),Vector2(x-8,y)]),Color("ae8857"))
	for y in [1300,1900]:
		for x in range(320,2650,32):draw_rect(Rect2(x,y,22,2),Color("5c5a61"))
	# Ruined crimson carpet, split hem and frayed threads; no collision snags.
	for y in range(620,2260,16):
		var missing := y>1530 and y<1680
		if not missing:
			draw_rect(Rect2(1352,y,368,16),Color("361327"))
			draw_rect(Rect2(1364,y,344,16),Color("682539") if y%48 else Color("742b3e"))
			for x in [1372,1694]:draw_rect(Rect2(x,y,3,12),Color("b88c56"))
			if y%80==12: RuneArt.glyph(self,Vector2(1536,y+8),2,Color("a5704b"),0.45)
			if y%112==12:draw_line(Vector2(1450,y),Vector2(1490,y+32),Color("1a1325"),4,false)
		else:
			for x in range(1352,1720,20):
				var reach := 10+absi(x*13)%43
				draw_line(Vector2(x,1530),Vector2(x+8,1530+reach),Color("61243a"),3,false)
	# Throne dais: three broad curved tiers, upper platform and sun crest.
	for i in range(3):
		var rect := Rect2(1256+i*16,540-i*20,560-i*32,48)
		draw_rect(rect,Color("202a40"))
		draw_rect(Rect2(rect.position,Vector2(rect.size.x,4)),Color("687187"))
		draw_rect(Rect2(rect.position+Vector2(0,4),Vector2(rect.size.x,2)),Color("a78b5c"))
	# Weathered royal statues with missing heads and fallen swords.
	for at in [Vector2(900,1450),Vector2(2170,900),Vector2(2180,2100)]:
		draw_rect(Rect2(at-Vector2(40,8),Vector2(80,24)),Color("1a2439"))
		draw_rect(Rect2(at-Vector2(35,10),Vector2(70,5)),Color("738097"))
		draw_texture_rect(Art.knight_frame(0,0),Rect2(at+Vector2(-40,-92),Vector2(80,96)),false,Color("657087"))
		draw_rect(Rect2(at+Vector2(-14,-91),Vector2(34,20)),Color("151e30"))
		draw_rect(Rect2(at+Vector2(45,1),Vector2(20,13)),Color("657087"))
	# Shadows have already infected the outer aisles; sacred places remain legible.
	for i in range(75):
		var at := Vector2(340+(i*383)%2330,1200+(i*157)%1000)
		if is_protected(at) or at.distance_to(CLOCK)<180: continue
		var r := float(14+i%4*9)
		var poly := PackedVector2Array()
		for j in range(10):poly.append((at+Vector2.from_angle(j*TAU/10)*(r+(i*j)%17)).snapped(Vector2(2,2)))
		draw_colored_polygon(poly,Color(0.025,0.01,0.045,0.65))
		if i%4==0:draw_line(at,at+Vector2(32,15),Color("58213b"),2,false)
	# Sealed clockwork passage to the east, distinct from a mere doorway.
	for y in range(304,2320,32):
		if y>450 and y<700: continue
		draw_rect(Rect2(2740,y,28,30),Color("28344b"))
		draw_rect(Rect2(2742,y+2,24,3),Color("79758a"))
	for at in [Vector2(2754,458),Vector2(2754,704)]:
		draw_rect(Rect2(at-Vector2(34,8),Vector2(68,16)),Color("b49360"))
	if not gate_open:
		for x in range(2742,2768,8):draw_rect(Rect2(x,470,3,220),Color("6586a6"))
		Art.ring(self,Vector2(2755,580),46,Color("b79764"),3)
		RuneArt.glyph(self,Vector2(2755,580),2,Color("8acee2"))
	# Checkpoint inscription and crests remain on open floor.
	Art.ring(self,CHECKPOINT,96,Color("ac8c5f"),3)
	RuneArt.glyph(self,CHECKPOINT,2,Color("dfbf83"),1.6)
	text(CHECKPOINT+Vector2(-142,135),"THE CROWN'S LAST WATCHFIRE",17,Color("d9c191"))
	text(Vector2(1260,330),"AURELION / THE SILENT CROWN",23,Color("c9aa77"))
	text(Vector2(2500,400),"BEYOND THE LAST HOUR",19,Color("b9c9db"))
	if gate_open:text(EXIT+Vector2(-62,90),"HOURKEEPER",18,Color("f1d396"))

func text(at: Vector2, words: String, font_size: int, col: Color) -> void:
	draw_string(ThemeDB.fallback_font,at,words,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,col)
