extends Node2D
const Art = preload("res://scripts/pixel_art.gd")
@export var final_lamp: bool = false
var lit: bool = false:
	set(value):
		if lit != value:
			ignition = 1.0 if value else 0.0
		lit = value
		queue_redraw()
var highlight: bool = false
var seal_ready: bool = false
var frozen_ready: bool = false
var clock: float = 0.0
var ignition: float = 0.0
var highlight_weight: float = 0.0

func _process(delta: float) -> void:
	clock += delta
	ignition = maxf(0,ignition-delta)
	highlight_weight = move_toward(highlight_weight,1.0 if highlight else 0.0,delta*6)
	queue_redraw()

func _draw() -> void:
	var col := Color("ffd089") if lit else Color("74b9d5")
	var fire := Vector2(0,-50)
	if lit:
		for i in range(6,0,-1):
			draw_circle(fire,12+i*11,Color(1,0.64,0.21,0.025))
	draw_rect(Rect2(-23,0,46,12),Color(0,0.01,0.03,0.65))
	draw_rect(Rect2(-22,-3,44,9),Color("222c40"))
	draw_rect(Rect2(-20,-7,40,6),Color("637184"))
	draw_rect(Rect2(-17,-10,34,4),Color("8b919b"))
	draw_rect(Rect2(-12,-42,24,32),Color("111a2b"))
	draw_rect(Rect2(-10,-40,20,28),Color("35435a"))
	draw_rect(Rect2(-10,-40,4,28),Color("53627a"))
	for y in [-36,-26,-16]:
		draw_rect(Rect2(-10,y,20,2),Color("1b263a"))
	draw_rect(Rect2(-14,-14,28,4),Color("96825c"))
	# Bowl with claw-like bronze brackets and an engraved hourglass.
	draw_rect(Rect2(-17,-44,34,4),Color("bca16c"))
	draw_rect(Rect2(-13,-40,26,4),Color("715f47"))
	draw_rect(Rect2(-20,-51,4,10),Color("7d7565"))
	draw_rect(Rect2(16,-51,4,10),Color("7d7565"))
	draw_rect(Rect2(-18,-53,4,4),Color("c6b28b"))
	draw_rect(Rect2(14,-53,4,4),Color("c6b28b"))
	draw_line(Vector2(-4,-32),Vector2(4,-20),Color(col,0.7),2,false)
	draw_line(Vector2(4,-32),Vector2(-4,-20),Color(col,0.7),2,false)
	if lit:
		var height := 18+int(sin(clock*8.5)*2)*2
		draw_rect(Rect2(-8,-48-height,16,height+4),Color("d4793e"))
		draw_rect(Rect2(-6,-48-height,12,height-2),Color("f4b855"))
		draw_rect(Rect2(-4,-54-height,8,8),Color("f4b855"))
		draw_rect(Rect2(-2,-55,6,11),Color("fff1b5"))
		for i in range(3):
			var phase := fmod(clock*0.8+i*0.33,1)
			draw_rect(Rect2(Art.pixel_snap(Vector2(sin(clock+i)*12,-68-phase*25)),Vector2(2,2)),Color(1,0.75,0.35,1-phase))
	else:
		var rise := 2*roundf(sin(clock*2))
		draw_rect(Rect2(-3,-59+rise,6,10),Color("77c7e2"))
		draw_rect(Rect2(-1,-62+rise,2,16),Color("c1ecf0"))
	if final_lamp:
		var rune_col := Color("f9ce7f") if seal_ready or lit else Color("4a627c")
		if frozen_ready:
			rune_col = Color("9af4ee")
		Art.ring(self,Vector2(0,-55),24,rune_col,2)
		draw_line(Vector2(-8,-69),Vector2(8,-43),rune_col,2,false)
		draw_line(Vector2(8,-69),Vector2(-8,-43),rune_col,2,false)
	if ignition > 0:
		Art.ring(self,Vector2(0,-20),18+(1-ignition)*85,Color(1,0.76,0.35,ignition),2)
	if highlight_weight > 0:
		# Four corners and a raised E make the interaction target unambiguous.
		for side in [-1,1]:
			draw_line(Vector2(side*30,-7),Vector2(side*30,8),Color(1,0.86,0.56,highlight_weight),2,false)
			draw_line(Vector2(side*30,8),Vector2(side*17,8),Color(1,0.86,0.56,highlight_weight),2,false)
		draw_rect(Rect2(-12,-102,24,23),Color(0.025,0.04,0.08,highlight_weight*0.95))
		draw_rect(Rect2(-12,-102,24,2),Color(1,0.82,0.48,highlight_weight))
		draw_string(ThemeDB.fallback_font,Vector2(-5,-84),"E",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color(1,0.91,0.67,highlight_weight))
