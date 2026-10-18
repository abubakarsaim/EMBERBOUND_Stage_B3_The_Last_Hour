extends RefCounted
## Original code-authored pixel sprites. Tiny canvases are drawn once and cached.
## 0 = front three-quarter, 1 = side, 2 = back. No downloaded art is required.
static var knight_cache: Dictionary = {}
static var hunter_cache: Dictionary = {}
const INK := Color("080c18")
const STEEL_DARK := Color("1c2939")
const STEEL := Color("384b60")
const EDGE := Color("8193a1")
const SILVER := Color("c1ccd0")
const RED_DARK := Color("390f27")
const RED := Color("842039")
const RED_LIGHT := Color("c34549")
const GOLD := Color("c69c58")

static func rect(image: Image, x: int, y: int, width: int, height: int, color: Color) -> void:
	var region := Rect2i(x,y,width,height).intersection(Rect2i(0,0,image.get_width(),image.get_height()))
	if region.has_area():
		image.fill_rect(region,color)

static func polygon(image: Image, points: Array, color: Color) -> void:
	var poly := PackedVector2Array()
	for point in points:
		poly.append(Vector2(point[0],point[1]))
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if Geometry2D.is_point_in_polygon(Vector2(x+0.5,y+0.5),poly):
				image.set_pixel(x,y,color)

static func knight_frame(direction: int, frame: int) -> Texture2D:
	var key := direction*10+frame
	if knight_cache.has(key):
		return knight_cache[key]
	var image := Image.create(40,48,false,Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var gait: int = [0,1,0,-1][frame%4]
	# Split cloak hem, dark outline and two warm folds establish the hero's silhouette.
	polygon(image,[[12,16],[26,16],[29,26],[34+gait,42],[27,40],[24,44],[19,40],[11,44],[5-gait,40],[10,27]],INK)
	polygon(image,[[13,17],[25,17],[27,27],[31+gait,40],[25,38],[23,42],[18,38],[10,41],[8-gait,39],[12,26]],RED_DARK)
	polygon(image,[[14,18],[24,18],[25,28],[28+gait,39],[23,37],[21,40],[16,36],[10,39],[13,25]],RED)
	polygon(image,[[14,21],[16,21],[15+gait,34],[12,38],[13,28]],RED_LIGHT)
	polygon(image,[[23,20],[25,21],[26,32],[28,37],[24,35],[22,27]],Color("a52e41"))
	# Greaves and alternating soles: movement animation does not change collision.
	rect(image,12,32,6,11+gait,INK)
	rect(image,21,32,6,11-gait,INK)
	rect(image,13,33,4,7+gait,STEEL)
	rect(image,22,33,4,7-gait,STEEL_DARK)
	rect(image,13,34,1,6,EDGE)
	rect(image,22,34,1,5,EDGE)
	rect(image,11,41+gait,7,3,INK)
	rect(image,21,41-gait,7,3,INK)
	rect(image,12,41+gait,5,1,STEEL)
	rect(image,22,41-gait,5,1,STEEL)
	if direction != 2:
		# Armored torso, layered gorget and asymmetric shoulders.
		polygon(image,[[12,19],[25,19],[27,28],[24,33],[13,33],[10,28]],INK)
		polygon(image,[[13,20],[24,20],[25,28],[22,31],[14,31],[12,27]],STEEL)
		polygon(image,[[13,20],[20,20],[17,29],[13,27]],Color("4c6173"))
		rect(image,13,20,10,2,EDGE)
		rect(image,17,22,2,7,STEEL_DARK)
		rect(image,12,30,13,3,INK)
		rect(image,13,30,11,1,GOLD)
		rect(image,18,30,3,2,Color("edc67e"))
		polygon(image,[[7,19],[13,18],[15,22],[12,25],[6,24]],INK)
		polygon(image,[[8,19],[12,19],[13,22],[11,23],[7,22]],STEEL)
		rect(image,8,19,4,1,EDGE)
		polygon(image,[[25,18],[30,19],[32,23],[27,25],[24,22]],INK)
		polygon(image,[[26,19],[29,20],[30,22],[27,23],[25,21]],STEEL)
		rect(image,26,19,3,1,EDGE)
		rect(image,8,24,4,9,INK)
		rect(image,9,25,2,6,STEEL)
		rect(image,28,24,4,9,INK)
		rect(image,28,25,2,6,STEEL)
		# Kite shield has a bronze rim and a red family mark.
		polygon(image,[[4,25],[9,23],[14,26],[13,35],[9,39],[4,35]],INK)
		polygon(image,[[5,26],[9,25],[13,27],[12,34],[9,37],[5,34]],GOLD)
		polygon(image,[[6,27],[9,26],[12,28],[11,34],[9,36],[6,33]],Color("253346"))
		rect(image,8,28,2,6,RED_LIGHT)
		rect(image,7,30,4,1,RED_LIGHT)
		# Blade held down at rest, pixel-stepped edge and gold crossguard.
		for i in range(11):
			rect(image,29+int(i/3),31+i,3,2,INK)
			rect(image,30+int(i/3),31+i,1,2,SILVER)
		rect(image,26,30,9,2,GOLD)
		rect(image,29,27,2,4,Color("6e4c38"))
	else:
		# The back view puts the cloak over the breastplate, with a silver collar.
		rect(image,11,18,16,3,INK)
		rect(image,12,19,14,1,EDGE)
		polygon(image,[[13,20],[25,20],[28,38],[23,41],[16,37],[10,40]],RED)
		rect(image,14,22,2,12,RED_LIGHT)
	# Helmet: dark steel, a high crest, readable face slit and top rim.
	polygon(image,[[14,6],[23,6],[27,10],[27,18],[23,22],[14,21],[10,17],[10,11]],INK)
	polygon(image,[[15,7],[22,7],[25,10],[25,17],[22,20],[15,19],[12,16],[12,11]],STEEL)
	polygon(image,[[15,8],[20,8],[18,13],[12,14],[13,10]],Color("566b7c"))
	rect(image,15,7,7,1,EDGE)
	rect(image,12,11,1,5,EDGE)
	rect(image,19,7,2,6,SILVER)
	if direction == 0:
		rect(image,12,14,13,3,INK)
		rect(image,14,14,4,1,Color("e2ae67"))
		rect(image,21,14,3,1,Color("e2ae67"))
		rect(image,18,14,2,6,EDGE)
	elif direction == 1:
		rect(image,18,13,9,4,INK)
		rect(image,21,13,5,1,Color("e2ae67"))
		rect(image,25,15,2,4,EDGE)
	else:
		rect(image,15,16,9,2,STEEL_DARK)
		rect(image,19,10,1,7,EDGE)
	polygon(image,[[17,7],[17,3],[20,1],[24,3],[25,6],[22,5],[21,10]],RED_DARK)
	polygon(image,[[18,6],[18,3],[20,2],[23,3],[21,4],[20,8]],RED_LIGHT)
	rect(image,13,21,2,2,GOLD)
	rect(image,23,21,2,2,GOLD)
	var texture := ImageTexture.create_from_image(image)
	knight_cache[key] = texture
	return texture

static func hunter_frame(frame: int) -> Texture2D:
	if hunter_cache.has(frame):
		return hunter_cache[frame]
	var image := Image.create(72,80,false,Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var shift: int = [0,1,0,-1,0,1][frame%6]
	# Horned crown and long predatory arms distinguish this from a small wisp.
	polygon(image,[[29,22],[22,17],[19,4],[26,11],[30,5],[33,17],[38,15],[43,4],[46,13],[54,7],[51,24],[59,31],[65,48],[70,54],[60,52],[57,44],[52,42],[52,56],[58,69],[48,67],[47,74],[39,69],[34,77],[29,69],[20,73],[22,64],[13,67],[18,53],[16,44],[12,49],[4,54],[6,43],[12,30],[23,26]],Color("04050d"))
	polygon(image,[[27,24],[23,15],[28,20],[33,18],[40,18],[47,16],[47,25],[55,34],[59,46],[53,40],[48,40],[46,55],[50,65],[43,62],[38,69],[33,64],[26,67],[28,57],[23,48],[21,38],[16,42],[17,34]],Color("101020"))
	polygon(image,[[27,30],[30,23],[42,22],[47,30],[43,41],[39,50],[39,63],[34,68],[31,52],[27,42]],Color("080910"))
	# Pixel cracks, hanging shrouds, and trailing barbs breathe in discrete frames.
	for i in range(7):
		var x := 20+i*4
		var y := 48+(i%3)*4
		polygon(image,[[x,y],[x+4,y+5],[x+3+shift,69+(i%3)*3],[x-2+shift,64]],Color("141023") if i%2 else Color("0a0914"))
	polygon(image,[[15,33],[10,43],[8,47],[12,44],[18,36]],Color("281329"))
	polygon(image,[[53,33],[61,46],[64,48],[60,40],[56,32]],Color("281329"))
	# Empty face, downward crimson eyes, no friendly round pupils.
	polygon(image,[[25,28],[32,30],[32,33],[27,32]],Color("9d1c42"))
	polygon(image,[[39,30],[47,27],[45,32],[39,33]],Color("9d1c42"))
	rect(image,27,30,4,1,Color("ff6176"))
	rect(image,40,30,4,1,Color("ff6176"))
	rect(image,34,39,2,6,Color("45172d"))
	rect(image,33,44,4,2,Color("5c1732"))
	var texture := ImageTexture.create_from_image(image)
	hunter_cache[frame] = texture
	return texture

static func pixel_snap(point: Vector2) -> Vector2:
	return point.snapped(Vector2(2,2))

static func ring(item: CanvasItem, center: Vector2, radius: float, color: Color, thickness: float = 2.0, start: float = 0.0, end: float = TAU) -> void:
	var count := maxi(12,int(radius*1.4*(end-start)/TAU))
	var previous := pixel_snap(center+Vector2.from_angle(start)*radius)
	for i in range(1,count+1):
		var angle := lerpf(start,end,float(i)/count)
		var next := pixel_snap(center+Vector2.from_angle(angle)*radius)
		item.draw_line(previous,next,color,thickness,false)
		previous = next
