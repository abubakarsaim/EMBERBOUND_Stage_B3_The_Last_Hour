extends RefCounted
const Art = preload("res://scripts/pixel_art.gd")
static func tree(variant: int) -> Image:
	var img := Image.create(96,128,false,Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	var ink := Color("080e1c")
	Art.polygon(img,[[39,119],[25,125],[32,116],[40,109],[43,70],[36,50],[37,29],[42,39],[44,60],[51,77],[52,108],[65,119],[70,124],[51,119]],ink)
	Art.polygon(img,[[42,115],[45,82],[41,61],[45,68],[50,85],[49,110],[59,119],[49,116]],Color("253047"))
	Art.polygon(img,[[44,109],[46,87],[47,90],[47,112],[43,118],[39,120]],Color("3e4054"))
	Art.polygon(img,[[46,87],[30,77],[22,58],[9,50],[7,40],[13,47],[25,53],[28,64],[35,71],[45,72]],ink)
	Art.polygon(img,[[48,85],[62,65],[78,60],[82,43],[88,36],[85,59],[71,68],[53,91]],ink)
	Art.polygon(img,[[49,73],[52,48],[64,35],[66,15],[71,6],[70,34],[59,50],[56,76]],ink)
	Art.polygon(img,[[34,64],[18,32],[20,15],[24,30],[31,36],[30,24],[35,32],[35,46],[43,62]],ink)
	Art.polygon(img,[[63,66],[70,76],[88,78],[93,87],[86,82],[68,81],[57,77]],ink)
	var rng := RandomNumberGenerator.new()
	rng.seed = 937+variant*41
	for i in range(100):
		var x := rng.randi_range(4,88)
		var y := rng.randi_range(10,68)
		if Vector2(x-45,y-38).length()>42: continue
		Art.rect(img,x,y,rng.randi_range(4,12),rng.randi_range(2,5),[Color("0d1b2b"),Color("15263a"),Color("1c2d42"),Color("243449")][i%4])
	for i in range(12):
		Art.rect(img,34+i%5*5,66+i*3,2,3,Color("334543"))
	return img
static func pillar() -> Image:
	var img := Image.create(40,64,false,Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	Art.rect(img,3,55,34,7,Color("0a111d"))
	Art.rect(img,5,50,30,8,Color("42495c"))
	Art.rect(img,7,50,26,2,Color("737387"))
	Art.polygon(img,[[10,49],[10,13],[18,7],[22,14],[28,11],[30,49]],Color("242f46"))
	Art.polygon(img,[[12,48],[12,15],[17,12],[19,45]],Color("4d5870"))
	Art.rect(img,21,16,3,31,Color("131f34"))
	Art.rect(img,11,25,17,2,Color("111c30"))
	Art.rect(img,11,24,16,1,Color("69738a"))
	return img
static func glyph(canvas: CanvasItem, at: Vector2, which: int, col: Color, scale_value: float = 1.0) -> void:
	var lines: Array = []
	match which:
		0: lines = [Vector4(0,-14,0,12),Vector4(0,2,-11,12),Vector4(0,2,11,12),Vector4(0,-5,-9,-13),Vector4(0,-5,9,-13)]
		1: lines = [Vector4(-10,6,-8,-8),Vector4(-8,-8,0,-14),Vector4(0,-14,8,-8),Vector4(8,-8,10,6),Vector4(-13,6,13,6),Vector4(-3,12,3,12)]
		2: lines = [Vector4(-13,-10,-10,11),Vector4(-10,11,10,11),Vector4(10,11,13,-10),Vector4(13,-10,4,-2),Vector4(4,-2,0,-15),Vector4(0,-15,-4,-2),Vector4(-4,-2,-13,-10)]
	for v in lines:
		canvas.draw_line((at+Vector2(v.x,v.y)*scale_value).snapped(Vector2(2,2)),(at+Vector2(v.z,v.w)*scale_value).snapped(Vector2(2,2)),col,2*scale_value,false)
