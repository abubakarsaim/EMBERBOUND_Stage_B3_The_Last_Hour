extends Node2D
const Art = preload("res://scripts/pixel_art.gd")
const Glyph = preload("res://scripts/forest/forest_art.gd")
const CHECKPOINT := Vector2(1280,1700)
const EXIT := Vector2(1280,1700)
const BOSS := Vector2(1280,1040)
const CLOCK := Vector2(1280,430)
const PRISON := Vector2(1280,650)
const PEDESTAL := Vector2(1280,1140)
const ROYAL_RUNE := Vector2(1280,1275)
const ANCHORS := [Vector2(760,960),Vector2(1800,960)]
const FONTS := [Vector2(720,1550),Vector2(1840,1550)]
const BOUNDS := Rect2(240,300,2080,1510)
var controller: Node
var checkpoint_lit: bool = true
var gate_open: bool = false
var prison_shape: CollisionShape2D
func _ready() -> void:
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	for rect in [Rect2(208,268,2144,32),Rect2(208,1810,2144,32),Rect2(208,268,32,1574),Rect2(2320,268,32,1574),Rect2(1040,300,480,130)]:add_wall(rect)
	for at in [Vector2(430,700),Vector2(2130,700),Vector2(430,1260),Vector2(2130,1260)]:
		add_wall(Rect2(at-Vector2(42,18),Vector2(84,36)))
		var col:=Sprite2D.new();col.texture=preload("res://assets/royal/column.png");col.position=at-Vector2(0,145);col.scale=Vector2(2,2);col.z_index=1;add_child(col)
	for at in [Vector2(980,1450),Vector2(1580,1450)]:add_wall(Rect2(at-Vector2(35,14),Vector2(70,28)))
	prison_shape=add_wall(Rect2(PRISON-Vector2(100,25),Vector2(200,50)))
func add_wall(rect: Rect2) -> CollisionShape2D:
	var body:=StaticBody2D.new();body.collision_layer=1;body.collision_mask=0;body.position=rect.get_center()
	var shape:=CollisionShape2D.new();var box:=RectangleShape2D.new();box.size=rect.size;shape.shape=box;body.add_child(shape);add_child(body);return shape
func is_protected(at: Vector2) -> bool:
	if controller==null:return false
	var ritual: Node=controller.puzzle
	if ritual.phase>=ritual.Phase.RESCUE:return true
	if at.distance_to(CHECKPOINT)<95:return true
	for point in FONTS:
		if at.distance_to(point)<105:return true
	for i in range(2):
		if (ritual.anchors[i] or ritual.exposed_remaining>0) and at.distance_to(ANCHORS[i])<95:return true
	return ritual.phase==ritual.Phase.CORE and ritual.opening and at.distance_to(controller.boss.global_position+Vector2(0,90))<150
func set_exit_open(open: bool) -> void:gate_open=open
func _draw() -> void:
	draw_rect(Rect2(0,0,2560,2048),Color("050813"))
	draw_rect(Rect2(215,100,2130,202),Color("161a2d"))
	for y in range(110,300,30):
		for x in range(220,2340,64):draw_rect(Rect2(x+(16 if y%60==20 else 0),y,59,26),Color("24283f"))
	draw_rect(BOUNDS,Color("101427"))
	for y in range(302,1810,32):
		for x in range(242,2320,32):
			var hash_value: int=absi(x*31+y*17)
			var shade: float=(hash_value%7)*0.006
			var col:=Color(0.13+shade,0.14+shade,0.21+shade)
			draw_rect(Rect2(x+1,y+1,29,29),col)
			draw_line(Vector2(x+3,y+2),Vector2(x+26,y+2),col.lightened(0.15),2,false)
			if hash_value%9==0:
				draw_line(Vector2(x+9,y+3),Vector2(x+16,y+18),Color("0b1120"),2,false)
				draw_line(Vector2(x+16,y+18),Vector2(x+11,y+28),Color("0b1120"),2,false)
	# Three concentric clockwork rings distinguish the arena from the royal carpet hall.
	for r in [240,430,600]:
		Art.ring(self,BOSS,r,Color("4f4459"),6)
		Art.ring(self,BOSS,r-8,Color("77705b"),2)
	for i in range(24):
		var angle: float=i*TAU/24
		var direction:=Vector2.from_angle(angle)
		draw_line(BOSS+direction*440,BOSS+direction*(469 if i%2==0 else 453),Color("a78762"),4,false)
	for y in range(500,1690,80):
		for x in [1160,1400]:draw_rect(Rect2(x,y,3,40),Color("746345"))
	for i in range(3):
		draw_rect(Rect2(970+i*18,460-i*16,620-i*36,30),Color("202b40"))
		draw_rect(Rect2(970+i*18,460-i*16,620-i*36,3),Color("8a8170"))
	for r in [250,239,224,210]:Art.ring(self,CLOCK,r,Color("977849") if r>230 else Color("364a62"),5)
	for i in range(12):
		var d:=Vector2.from_angle(i*TAU/12)
		draw_line(CLOCK+d*192,CLOCK+d*211,Color("dac28a"),5,false)
		Glyph.glyph(self,CLOCK+d*174,i%3,Color("7aa5bc"),0.6)
	# Two windows, one large east-facing aperture reserved for the dawn shot.
	for at in [Vector2(650,310),Vector2(1910,310)]:
		draw_texture_rect(preload("res://assets/royal/broken_window.png"),Rect2(at-Vector2(100,180),Vector2(200,280)),false)
	for at in [Vector2(980,1450),Vector2(1580,1450)]:
		draw_colored_polygon(PackedVector2Array([at+Vector2(-43,8),at+Vector2(-32,-21),at+Vector2(-8,-30),at+Vector2(14,-10),at+Vector2(41,2),at+Vector2(30,17)]),Color("303d52"))
		draw_line(at+Vector2(-28,-19),at+Vector2(-8,-26),Color("7b8292"),3,false)
	Art.ring(self,CHECKPOINT,86,Color("c6a76b"),3)
	Glyph.glyph(self,CHECKPOINT,2,Color("edcd8d"),1.2)
	draw_string(ThemeDB.fallback_font,CHECKPOINT+Vector2(-145,125),"THE THRESHOLD / CHECKPOINT",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("d9c18b"))
	draw_string(ThemeDB.fallback_font,Vector2(1065,190),"THE ETERNAL CLOCK",HORIZONTAL_ALIGNMENT_LEFT,-1,24,Color("d9c18b"))
