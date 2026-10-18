extends RefCounted
## Original 96x128 pixel sprite source; baked sheets are used during play.
const P = preload("res://scripts/pixel_art.gd")
const INK := Color("070914")
const ROBE := Color("201b35")
const STEEL := Color("45526c")
const GOLD := Color("a88253")
const CYAN := Color("88e9e9")
static func frame(pose: int, index: int) -> Image:
	var img := Image.create(96,128,false,Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	var sway: int = [0,2,0,-2][index]
	var lift: int = -7 if pose==1 else (-3 if pose==4 else (4 if pose==3 else 0))
	# Tall split mantle, clockwork pauldrons, three-quarter armored head.
	P.polygon(img,[[33,26],[61,26],[72,42],[71,69],[84+sway,105],[91,119],[73,112],[70,126],[55,117],[45,127],[33,118],[18,125],[21,111],[5,117],[18+sway,83],[23,46]],INK)
	P.polygon(img,[[35,31],[59,30],[67,45],[65,71],[77+sway,108],[68,103],[65,119],[54,110],[45,119],[36,111],[24,118],[29,94],[22,107],[27+sway,71]],ROBE)
	P.polygon(img,[[34,45],[42,55],[36,84],[31,109],[25,113],[32,73]],Color("393149"))
	P.polygon(img,[[57,46],[62,48],[61,77],[70+sway,107],[61,103],[54,74]],Color("4b354a"))
	for i in range(8):
		P.rect(img,42+(i%2)*3,70+i*5,2,4,Color("95724f"))
	# Angular armor, gilded inlays, and a heavy breastplate around the luminous core.
	for points in [[[19,38],[29,31],[38,39],[33,51],[18,47]],[[59,36],[70,30],[80,40],[77,50],[63,49]]]:
		P.polygon(img,points,INK)
	P.polygon(img,[[22,38],[29,34],[35,39],[30,46],[20,44]],STEEL)
	P.polygon(img,[[64,37],[70,34],[77,41],[74,46],[63,45]],STEEL)
	P.rect(img,22,37,11,2,GOLD);P.rect(img,65,36,10,2,GOLD)
	P.polygon(img,[[34,40],[59,40],[65,57],[58,72],[37,71],[29,57]],INK)
	P.polygon(img,[[36,41],[56,41],[61,56],[55,67],[38,67],[33,56]],Color("313f56"))
	P.polygon(img,[[39,43],[53,43],[58,56],[53,63],[40,64],[36,54]],GOLD)
	P.polygon(img,[[42,45],[51,45],[56,55],[51,61],[42,61],[38,54]],Color("0b2035"))
	var core := Color("f1d19a") if pose==2 else CYAN
	if pose==3: core=Color("ec687a")
	if pose==4: core=Color("fff0bd")
	P.polygon(img,[[46,45],[50,51],[54,54],[49,57],[47,63],[44,57],[39,54],[44,51]],core)
	P.rect(img,46,49,2,9,Color("e5ffff"));P.rect(img,42,53,10,2,Color("e5ffff"))
	# Clock-mask, high crown, crimson eye slits and a central hour hand.
	P.polygon(img,[[32,14],[38,7],[56,8],[64,16],[61,33],[54,39],[39,37],[30,28]],INK)
	P.polygon(img,[[36,15],[40,10],[54,11],[59,17],[56,31],[49,35],[38,31],[34,25]],Color("4f5972"))
	P.polygon(img,[[38,17],[54,16],[57,23],[53,31],[41,31],[36,24]],Color("111724"))
	P.rect(img,37,21,7,2,Color("e65478"));P.rect(img,50,21,7,2,Color("e65478"))
	P.rect(img,46,13,2,21,GOLD);P.rect(img,39,13,15,2,GOLD)
	P.polygon(img,[[30,16],[28,1],[38,9],[46,0],[53,9],[66,3],[62,18],[57,14],[40,13]],GOLD)
	P.rect(img,32,16,29,2,Color("d7b47b"))
	# Raised/idle hands with suspended clock fragments and claw-like gauntlets.
	P.polygon(img,[[19,46],[26,48],[20,63+lift],[13,68+lift],[10,63+lift],[15,55]],Color("3b475e"))
	P.polygon(img,[[71,46],[77,45],[82,56+lift],[86,64+lift],[81,68+lift],[74,61+lift]],Color("3b475e"))
	P.rect(img,10,61+lift,9,5,GOLD);P.rect(img,78,61+lift,8,5,GOLD)
	for x in [8,12,16]:P.rect(img,x,65+lift,2,6,Color("8ba2af"))
	for x in [79,83,87]:P.rect(img,x,65+lift,2,6,Color("8ba2af"))
	if pose==1:
		for x in [8,81]:
			P.polygon(img,[[x,49],[x+4,45],[x+7,49],[x+3,54]],CYAN)
	if pose==2:
		P.polygon(img,[[46,42],[50,51],[47,57],[53,65],[46,71],[47,59],[43,51]],Color("ffe8b4"))
	if pose==3:
		P.polygon(img,[[46,11],[50,29],[45,46],[52,62],[44,91],[48,65],[40,47],[46,28]],Color("c95172"))
	return img
static func sheet(pose: int) -> Image:
	var img := Image.create(384,128,false,Image.FORMAT_RGBA8);img.fill(Color.TRANSPARENT)
	for i in range(4):img.blit_rect(frame(pose,i),Rect2i(0,0,96,128),Vector2i(i*96,0))
	return img
