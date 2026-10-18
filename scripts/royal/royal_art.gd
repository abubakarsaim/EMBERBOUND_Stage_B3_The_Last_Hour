extends RefCounted
## Original pixel geometry, baked to local PNGs. No asset service or runtime generator required.
const P = preload("res://scripts/pixel_art.gd")
const INK := Color("080b18")
const STONE := Color("283249")
const EDGE := Color("66718a")
const GOLD := Color("ae8550")
const LIGHT := Color("eed196")
static func princess(frame: int, false_form: bool = false) -> Image:
	var img := Image.create(64 if false_form else 40,80 if false_form else 56,false,Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	if false_form:
		var sway: int = [0,1,0,-1][frame]
		P.polygon(img,[[23,15],[40,15],[48,29],[48+sway,45],[59,69],[44,63],[42,77],[32,69],[19,78],[18,65],[5,71],[16,45],[17,28]],INK)
		P.polygon(img,[[23,23],[40,23],[44,41],[52+sway,67],[40,60],[38,72],[29,64],[21,72],[22,58],[12,66],[21,41]],Color("211629"))
		P.polygon(img,[[24,29],[29,33],[25,54],[20,64],[20,46]],Color("716775"))
		P.polygon(img,[[37,30],[40,27],[42,45],[48,62],[39,54]],Color("4c374b"))
		P.polygon(img,[[26,16],[37,16],[39,25],[34,31],[28,28],[23,24]],Color("080b16"))
		P.rect(img,25,21,5,2,Color("f13f65"));P.rect(img,34,21,5,2,Color("f13f65"))
		P.rect(img,27,22,2,1,Color("ffe0d3"));P.rect(img,35,22,2,1,Color("ffe0d3"))
		P.polygon(img,[[21,16],[15,3],[24,10],[30,0],[35,10],[46,3],[41,17]],GOLD)
		P.polygon(img,[[23,15],[19,7],[25,13],[30,4],[35,13],[42,7],[39,16]],Color("493b49"))
		for i in range(7):
			P.rect(img,29+(i%3),32+i*4,2,4,Color("9c274c"))
		P.polygon(img,[[18,29],[12,40],[9,51],[6,52],[8,38],[14,27]],Color("161522"))
		P.polygon(img,[[44,27],[51,39],[55,55],[51,53],[46,39]],Color("161522"))
		return img
	var sway: int = [0,1,0,-1][frame]
	# Pale silhouette, gold circlet, silver-blue folds, long hair and court sleeves.
	P.polygon(img,[[14,20],[26,20],[29,29],[29,38],[36+sway,51],[28,54],[19,52],[9,54],[4+sway,50],[11,37],[11,27]],INK)
	P.polygon(img,[[14,22],[25,22],[26,32],[28,40],[33+sway,50],[26,52],[19,50],[10,52],[7+sway,49],[13,36]],Color("75839c"))
	P.polygon(img,[[15,23],[24,23],[24,35],[29+sway,49],[23,51],[18,48],[10,50],[15,34]],Color("c8d2dc"))
	P.polygon(img,[[16,25],[19,26],[17,41],[14,49],[11,50]],Color("f0eee5"))
	P.polygon(img,[[22,25],[24,27],[23,38],[27,48],[23,47],[20,34]],Color("9daec4"))
	P.rect(img,13,29,14,2,GOLD);P.rect(img,18,29,4,3,LIGHT)
	P.polygon(img,[[11,21],[6,24],[4,35],[8,38],[11,32],[13,27]],Color("c8d2dc"))
	P.polygon(img,[[26,21],[31,25],[34,37],[30,39],[26,29]],Color("b9c8d6"))
	P.rect(img,5,35,3,5,Color("d6bfa9"));P.rect(img,30,36,3,5,Color("d6bfa9"))
	P.polygon(img,[[12,11],[17,6],[24,7],[28,13],[27,24],[24,27],[13,26],[10,23]],Color("514250"))
	P.polygon(img,[[13,12],[16,8],[24,9],[26,13],[24,23],[16,24],[12,21]],Color("bdadb2"))
	P.rect(img,16,13,9,9,Color("dfc7b2"));P.rect(img,17,14,6,7,Color("f0d9c0"))
	P.rect(img,16,16,2,1,Color("48435c"));P.rect(img,23,16,2,1,Color("48435c"))
	P.rect(img,19,21,3,1,Color("a36f76"))
	P.polygon(img,[[12,13],[11,9],[15,11],[18,5],[21,10],[26,7],[26,13]],GOLD)
	P.rect(img,13,11,13,2,LIGHT);P.rect(img,18,9,3,3,Color("ad4c67"))
	P.rect(img,13,14,2,15,Color("cfbca8"));P.rect(img,25,14,2,13,Color("a696a2"))
	P.rect(img,15,24,10,2,Color("e5dfcf"));P.rect(img,19,25,2,2,GOLD)
	return img
static func sheet(false_form: bool = false) -> Image:
	var w := 64 if false_form else 40
	var h := 80 if false_form else 56
	var img := Image.create(w*4,h,false,Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	for frame in range(4):img.blit_rect(princess(frame,false_form),Rect2i(0,0,w,h),Vector2i(frame*w,0))
	return img
static func throne() -> Image:
	var img := Image.create(192,224,false,Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	# Three stepped plinths and a high spired chair with a broken sun crest.
	for i in range(3):
		P.rect(img,8+i*9,210-i*10,176-i*18,10,STONE)
		P.rect(img,10+i*9,210-i*10,172-i*18,2,EDGE)
	P.polygon(img,[[40,182],[40,36],[49,24],[53,4],[60,26],[73,21],[82,8],[90,15],[98,0],[106,15],[116,6],[123,24],[136,28],[139,7],[145,29],[153,40],[153,182]],INK)
	P.polygon(img,[[44,181],[44,38],[57,28],[72,29],[86,16],[97,8],[109,21],[123,30],[139,30],[149,40],[149,181]],GOLD)
	P.polygon(img,[[50,177],[50,44],[64,37],[78,34],[98,19],[118,36],[135,39],[143,47],[143,177]],Color("343447"))
	P.polygon(img,[[64,157],[64,61],[76,46],[96,33],[115,47],[128,63],[128,158]],Color("361626"))
	P.polygon(img,[[69,152],[69,63],[81,50],[96,40],[111,52],[123,66],[123,152]],Color("6c283a"))
	for y in range(64,146,16):
		for x in range(76,124,16):
			P.rect(img,x,y,1,2,GOLD)
	P.rect(img,59,153,76,17,INK);P.rect(img,64,154,65,8,Color("913e47"));P.rect(img,64,163,65,3,GOLD)
	for x in [48,133]:
		P.rect(img,x,142,13,45,INK);P.rect(img,x+2,143,9,40,GOLD);P.rect(img,x+4,144,3,36,LIGHT)
		P.rect(img,x-3,139,20,8,GOLD);P.rect(img,x-1,139,16,2,LIGHT)
	for x in [45,144]:
		for y in range(48,136,9):P.rect(img,x,y,3,5,LIGHT)
	P.polygon(img,[[94,35],[100,37],[96,47],[101,58],[93,67],[96,53],[90,46]],INK)
	# Gold royal crown inset; a crimson time fracture splits it.
	P.polygon(img,[[80,78],[83,95],[111,95],[114,78],[104,84],[97,71],[91,84]],GOLD)
	P.rect(img,85,92,24,2,LIGHT)
	P.rect(img,96,73,2,27,Color("9a4265"))
	return img
static func column() -> Image:
	var img := Image.create(80,168,false,Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	P.rect(img,8,149,64,16,INK);P.rect(img,10,148,60,11,STONE);P.rect(img,12,148,56,2,EDGE)
	P.rect(img,16,140,48,10,GOLD);P.rect(img,18,140,44,2,LIGHT)
	P.rect(img,23,35,34,105,INK);P.rect(img,25,35,30,104,STONE)
	for pair in [[26,Color("59647a")],[32,Color("3f4b64")],[43,Color("1a243b")],[50,Color("697189")]]:P.rect(img,pair[0],36,3,102,pair[1])
	P.rect(img,16,29,48,9,GOLD);P.rect(img,13,21,54,8,STONE);P.rect(img,9,14,62,8,EDGE)
	P.rect(img,14,24,52,2,Color("111a2e"))
	for x in range(16,66,10):
		P.rect(img,x,15,4,6,GOLD)
	P.polygon(img,[[35,45],[41,61],[36,74],[40,90],[35,108],[38,119],[33,111],[36,91],[32,75],[37,60]],Color("10192a"))
	return img
static func banner() -> Image:
	var img := Image.create(64,112,false,Image.FORMAT_RGBA8);img.fill(Color.TRANSPARENT)
	P.rect(img,4,3,56,4,GOLD);P.rect(img,8,6,48,3,INK)
	P.polygon(img,[[10,9],[54,9],[54,96],[47,93],[43,108],[36,101],[29,111],[24,98],[10,103]],Color("2f1026"))
	P.polygon(img,[[13,10],[51,10],[51,94],[44,91],[41,103],[35,96],[29,106],[27,94],[13,98]],Color("782b3f"))
	P.rect(img,15,12,2,81,GOLD);P.rect(img,48,12,2,74,GOLD)
	P.polygon(img,[[22,37],[25,53],[40,53],[43,37],[36,42],[32,31],[28,42]],GOLD)
	P.rect(img,25,51,15,2,LIGHT)
	P.polygon(img,[[21,65],[27,70],[23,74],[29,88],[24,87],[18,74]],INK)
	P.rect(img,35,18,2,59,Color("4b1930"));P.rect(img,19,14,3,46,Color("963d4b"))
	return img
static func window() -> Image:
	var img := Image.create(112,152,false,Image.FORMAT_RGBA8);img.fill(Color.TRANSPARENT)
	P.polygon(img,[[5,147],[5,48],[18,27],[56,0],[94,27],[107,48],[107,147]],INK)
	P.polygon(img,[[11,145],[11,50],[23,32],[56,9],[89,32],[101,50],[101,145]],EDGE)
	P.polygon(img,[[17,141],[17,54],[28,38],[56,18],[84,38],[95,54],[95,141]],Color("233b60"))
	P.rect(img,20,65,72,73,Color("33516f"))
	P.polygon(img,[[37,41],[54,26],[65,36],[61,49],[45,55]],Color("779eaf"))
	P.rect(img,53,28,5,112,STONE);P.rect(img,18,78,77,5,STONE);P.rect(img,31,48,4,91,STONE);P.rect(img,78,49,4,90,STONE)
	P.polygon(img,[[67,79],[82,64],[92,87],[80,112],[63,98]],INK)
	P.polygon(img,[[20,112],[35,96],[47,117],[40,141],[19,140]],INK)
	P.rect(img,10,141,93,7,Color("4b5a73"))
	return img
