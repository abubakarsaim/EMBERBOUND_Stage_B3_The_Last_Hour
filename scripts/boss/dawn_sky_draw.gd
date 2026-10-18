extends Node2D
var owner_layer: CanvasLayer
func _draw() -> void:
	if owner_layer==null or owner_layer.progress<=0:return
	var p: float=owner_layer.progress
	var alpha:=clampf(p*1.7,0,1)
	for y in range(0,720,4):
		var t: float=y/720.0
		var col:=Color("292e55").lerp(Color("daaa78"),clampf(t*1.5,0,1))
		col.a=alpha
		draw_rect(Rect2(0,y,1280,4),col)
	# A stepped sun lifts over the city's original skyline.
	var sun:=Vector2(810,470-p*150).snapped(Vector2(2,2))
	for i in range(8,0,-1):draw_circle(sun,45+i*15,Color(1,0.79,0.4,alpha*0.022))
	for y in range(-70,72,4):
		var half: float=floor(sqrt(maxf(0,70*70-y*y))/2)*2
		draw_rect(Rect2(sun+Vector2(-half,y),Vector2(half*2,4)),Color(1,0.85,0.55,alpha))
	for ridge in range(3):
		var poly:=PackedVector2Array([Vector2(0,720)])
		for x in range(0,1320,40):poly.append(Vector2(x,440+ridge*52+sin(x*0.008+ridge)*24+cos(x*0.019)*11))
		poly.append(Vector2(1280,720))
		draw_colored_polygon(poly,Color(0.15+ridge*0.01,0.19+ridge*0.012,0.29+ridge*0.01,alpha))
	for i in range(22):
		var x: int=i*68-12
		var h: int=60+(i*73)%100
		var y: int=615-h
		draw_rect(Rect2(x,y,58,h+130),Color(0.09,0.12,0.2,alpha))
		draw_colored_polygon(PackedVector2Array([Vector2(x-5,y),Vector2(x+28,y-30),Vector2(x+64,y)]),Color(0.07,0.09,0.16,alpha))
		for a in range(2):
			for b in range(3):draw_rect(Rect2(x+13+a*22,y+19+b*30,5,10),Color(0.9,0.64,0.32,alpha*p*0.75))
	for x in [260,535,1095]:
		draw_rect(Rect2(x,365,70,355),Color(0.06,0.08,0.14,alpha))
		draw_colored_polygon(PackedVector2Array([Vector2(x-8,370),Vector2(x+35,273),Vector2(x+78,370)]),Color(0.05,0.07,0.12,alpha))
		for y in range(380,590,48):draw_rect(Rect2(x+27,y,12,23),Color(0.9,0.67,0.35,alpha*p*0.8))
	# Foreground gothic window jambs keep the vista grounded in the castle.
	draw_rect(Rect2(0,0,90,720),Color(0.035,0.045,0.075,alpha))
	draw_rect(Rect2(1190,0,90,720),Color(0.035,0.045,0.075,alpha))
	for x in [82,1182]:draw_rect(Rect2(x,0,8,720),Color(0.48,0.4,0.29,alpha))
	for i in range(8):
		var inset: int=i*22
		draw_line(Vector2(90+inset,150-i*18),Vector2(640,15-i*2),Color(0.09,0.11,0.17,alpha),18,false)
		draw_line(Vector2(640,15-i*2),Vector2(1190-inset,150-i*18),Color(0.09,0.11,0.17,alpha),18,false)
	draw_rect(Rect2(72,676,1136,44),Color(0.075,0.09,0.14,alpha))
	draw_rect(Rect2(76,674,1128,6),Color(0.53,0.43,0.3,alpha))
