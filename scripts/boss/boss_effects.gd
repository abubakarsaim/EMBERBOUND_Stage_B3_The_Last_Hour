extends "res://scripts/world_effects.gd"
const Glyph=preload("res://scripts/forest/forest_art.gd")
var controller: Node
func _draw() -> void:
	if controller==null:return
	var p: Node=controller.puzzle
	var dawn: float=controller.dawn_amount
	# Thin corruption veins retreat as the final flame restores dawn.
	for i in range(52):
		var at:=Vector2(330+(i*313)%1880,700+(i*173)%1020)
		if world.is_protected(at):continue
		var col:=Color(0.035,0.012,0.055,0.6*(1-dawn))
		draw_line(at,at+Vector2(34,-16),col,8,false);draw_line(at+Vector2(34,-16),at+Vector2(58,4),col,6,false)
	# Ancient clock: wrong-way motion in combat, silence after defeat, forward motion at dawn.
	var center: Vector2=world.CLOCK
	for length in [142,195]:
		var angle: float=controller.clock_angle*(1 if length==195 else 0.22)-PI/2
		var direction:=Vector2.from_angle(angle)
		draw_line(center-direction*23,center+direction*length,Color("111a2b"),17,false)
		draw_line(center-direction*20,center+direction*(length-4),Color("c4ac76"),9,false)
		draw_line(center,center+direction*(length-12),Color("fff0bf"),2,false)
	Art.ring(self,center,16,Color("dfcf9d"),4)
	# Prison chains explain why the two anchors must fall first.
	for i in range(2):
		var at: Vector2=world.ANCHORS[i]
		if not p.anchors[i]:
			draw_dashed_line(at-Vector2(0,52),world.PRISON-Vector2(0,65),Color(0.3,0.68,0.8,0.45),3,18,false)
		var open: bool=p.exposed_remaining>0 and not p.anchors[i]
		var col:=Color("ffda94") if p.anchors[i] else (Color("8ff0eb") if open else Color("9b4365"))
		Art.ring(self,at,64,col,3);Art.ring(self,at,51,Color("394861"),4)
		draw_colored_polygon(PackedVector2Array([at+Vector2(-34,-18),at+Vector2(-25,-58),at+Vector2(0,-83),at+Vector2(28,-58),at+Vector2(34,-18)]),Color("152237"))
		Glyph.glyph(self,at-Vector2(0,48),i,col,1.2)
		for j in range(4,0,-1):draw_circle(at-Vector2(0,50),j*17,Color(col,0.024 if open or p.anchors[i] else 0.01))
		text(at+Vector2(-61,88),"ANCHOR "+["I","II"][i],col)
		if open:text(at+Vector2(-61,-115),"[E] CHANNEL",Color("ffe4a9"))
	for i in range(2):
		var at: Vector2=world.FONTS[i]
		var ready: bool=p.font_cooldowns[i]<=0
		var col:=Color("f8cd83") if ready else Color("82b4cb")
		for j in range(7,0,-1):draw_circle(at,j*15,Color(col,0.019))
		Art.ring(self,at,77,col,2);Glyph.glyph(self,at,2,col,1.1)
		draw_rect(Rect2(at+Vector2(-24,-24),Vector2(48,26)),Color("444653"));draw_rect(Rect2(at+Vector2(-29,-28),Vector2(58,6)),Color("b2986b"))
		var lift: float=sin(clock*9+i)*3
		draw_colored_polygon(PackedVector2Array([at+Vector2(-13,-31),at+Vector2(-5,-53+lift),at+Vector2(1,-72+lift),at+Vector2(14,-43),at+Vector2(8,-27)]),col)
		if p.phase<p.Phase.ENDING:text(at+Vector2(-88,117),"[E] +30 FLAME" if ready else "RECHARGE %.0fs" % ceilf(p.font_cooldowns[i]),col)
	# Cyan hourglass cage fades after the royal lock is opened.
	var prison_alpha: float=(1-controller.princess.release_progress)*(0.28 if p.solved else (1-p.lit_count()*0.23))
	var prison: Vector2=world.PRISON
	if prison_alpha>0:
		var cyan:=Color(0.42,0.85,0.92,prison_alpha)
		for j in range(6,0,-1):draw_circle(prison-Vector2(0,58),j*23,Color(cyan,prison_alpha*0.012))
		Art.ring(self,prison+Vector2(0,8),116,cyan,4)
		for side in [-1,1]:
			var points:=PackedVector2Array([prison+Vector2(side*112,-171),prison+Vector2(side*88,-137),prison+Vector2(side*34,-71),prison+Vector2(side*98,0),prison+Vector2(side*112,14)])
			draw_polyline(points,cyan,4,false)
		for y in [-172,14]:draw_line(prison+Vector2(-115,y),prison+Vector2(115,y),cyan,5,false)
		Glyph.glyph(self,prison+Vector2(0,54),2,Color("e5c58b"),0.9)
		if p.phase==p.Phase.RESCUE:text(prison+Vector2(-90,100),"[E] ROYAL LOCK",Color("ffe4a9"))
	var boss_at: Vector2=controller.boss.global_position
	if p.phase==p.Phase.ANCHORS:
		Art.ring(self,boss_at,182,Color("874b6c"),4)
		for i in range(8):Glyph.glyph(self,boss_at+Vector2.from_angle(i*TAU/8)*182,i%3,Color("926b91"),0.6)
	elif p.phase==p.Phase.CORE:
		var col:=Color("ffdf8b") if p.aligned else Color("9bb8d4")
		if p.opening:col=Color("8bf0ef")
		Art.ring(self,boss_at,194,Color(col,0.55),3)
		var direction:=Vector2.from_angle(p.barrier_angle)
		draw_line(boss_at-direction*46,boss_at+direction*221,Color("152035"),22,false)
		draw_line(boss_at-direction*46,boss_at+direction*216,col,12,false)
		draw_line(boss_at,boss_at+direction*205,Color("f8e8c3"),3,false)
		Glyph.glyph(self,world.ROYAL_RUNE,2,col,1.4);Art.ring(self,world.ROYAL_RUNE,43,col,3)
		if p.opening:
			Art.ring(self,boss_at-Vector2(0,140),31,Color("ffe3a0"),3)
			Art.ring(self,p.core_point(controller.boss),72,Color("ffc983"),3)
			text(p.core_point(controller.boss)+Vector2(-55,48),"[E] CORE",Color("ffe4a9"))
	if p.phase==p.Phase.DAWN or p.phase>=p.Phase.ENDING:
		var at: Vector2=world.PEDESTAL
		for i in range(6,0,-1):draw_circle(at-Vector2(0,40),i*22,Color(1,0.72,0.27,0.02))
		draw_rect(Rect2(at+Vector2(-55,-20),Vector2(110,32)),Color("343e50"));draw_rect(Rect2(at+Vector2(-47,-55),Vector2(94,37)),Color("5b5960"));draw_rect(Rect2(at+Vector2(-50,-58),Vector2(100,6)),Color("d8b77b"))
		Glyph.glyph(self,at-Vector2(0,38),2,Color("ffe3a0"),1.1)
		if p.phase==p.Phase.DAWN:text(at+Vector2(-90,55),"[E] ETERNAL FLAME",Color("ffe3a0"))
	if p.channel_kind!="":
		var to: Vector2=world.ANCHORS[p.channel_index]-Vector2(0,45) if p.channel_kind=="anchor" else boss_at-Vector2(0,140)
		draw_line(player.torch_position(),to,Color(1,0.7,0.25,0.22),16,false);draw_line(player.torch_position(),to,Color("ffe6a2"),4,false)
	if controller.cinematic_mode=="ending":
		var from: Vector2=player.global_position+Vector2(27,-106)
		if controller.ending_time<4:
			draw_line(from,world.CLOCK,Color(1,0.76,0.3,0.15),32,false);draw_line(from,world.CLOCK,Color("ffe4a1"),5,false)
		for x in [650,1910]:
			var beam:=PackedVector2Array([Vector2(x-70,320),Vector2(x+45,320),Vector2(x+300,1200),Vector2(x+30,1200)])
			draw_colored_polygon(beam,Color(1,0.78,0.4,dawn*0.14))
	for particle in particles:draw_rect(Rect2(Art.pixel_snap(particle.at),Vector2(4,4)),Color(particle.color,minf(1,particle.life*2)))
	for event in waves:
		var progress: float=1-event.life/0.8;Art.ring(self,event.at,12+progress*event.radius,Color(event.color,(1-progress)*0.8),2)
	for caption in captions:text(caption.at-Vector2(80,0),caption.words,Color(caption.color,minf(1,caption.life*2)))
func text(at: Vector2,words: String,col: Color) -> void:draw_string(ThemeDB.fallback_font,at,words,HORIZONTAL_ALIGNMENT_LEFT,-1,17,col)
