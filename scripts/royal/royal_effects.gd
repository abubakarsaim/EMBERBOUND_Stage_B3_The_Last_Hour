extends "res://scripts/world_effects.gd"
const RuneArt = preload("res://scripts/forest/forest_art.gd")
var controller: Node
func _process(delta: float) -> void:
	super._process(delta)
func _draw() -> void:
	if world==null: return
	# Jagged moonlight through four original damaged windows.
	for x in [420,960,2110,2640]:
		var light := PackedVector2Array([Vector2(x-70,340),Vector2(x+45,340),Vector2(x+295,1010),Vector2(x+25,1010)])
		draw_colored_polygon(light,Color(0.40,0.58,0.82,0.055))
		for i in range(6):draw_rect(Rect2(Vector2(x+80+i*13,700+i*25),Vector2(2,2)),Color(0.65,0.78,0.92,0.22))
	for at in world.TORCHES:
		for i in range(5,0,-1):draw_circle(at-Vector2(0,62),i*22,Color(1,0.57,0.19,0.019))
		draw_rect(Rect2(at+Vector2(-6,-58),Vector2(12,52)),Color("6b503c"))
		draw_rect(Rect2(at+Vector2(-13,-61),Vector2(26,6)),Color("b18c52"))
		var height := 18+int(sin(clock*8+at.x)*3)
		draw_rect(Rect2(at+Vector2(-7,-62-height),Vector2(14,height)),Color("d8843e"))
		draw_rect(Rect2(at+Vector2(-3,-67-height),Vector2(6,height+6)),Color("ffdfa0"))
	# The clock is a massive stopped hourglass/wheel, with hands that obey Borrowed Time.
	var at: Vector2 = world.CLOCK
	draw_rect(Rect2(at+Vector2(-92,-7),Vector2(184,24)),Color("171e31"))
	draw_rect(Rect2(at+Vector2(-86,-10),Vector2(172,6)),Color("92805f"))
	Art.ring(self,at-Vector2(0,107),84,Color("a98a55"),5)
	Art.ring(self,at-Vector2(0,107),74,Color("3e526d"),3)
	var clock_angle: float = controller.puzzle.clock*0.07 if controller!=null else 0
	for i in range(12):
		var direction := Vector2.from_angle(i*TAU/12)
		draw_line((at-Vector2(0,107)+direction*62).snapped(Vector2(2,2)),(at-Vector2(0,107)+direction*71).snapped(Vector2(2,2)),Color("d4bc83"),3,false)
	draw_line(at-Vector2(0,107),at-Vector2(0,107)+Vector2.from_angle(clock_angle-PI/2)*52,Color("d4e5e4"),3,false)
	draw_line(at-Vector2(0,107),at-Vector2(0,107)+Vector2.from_angle(-clock_angle*0.3)*35,Color("adcfdf"),3,false)
	for x in [-35,35]:draw_rect(Rect2(at+Vector2(x,-29),Vector2(7,26)),Color("7b6d59"))
	RuneArt.glyph(self,at-Vector2(0,107),2,Color("74b7ce"),0.7)
	draw_string(ThemeDB.fallback_font,at+Vector2(-98,48),"[E] THE LAST HOUR",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("b9ccdb"))
	for i in range(6,0,-1):draw_circle(world.CHECKPOINT-Vector2(0,50),i*18,Color(1,0.67,0.25,0.020))
	if world.gate_open:
		for point in [Vector2(1800,940),Vector2(2020,840),Vector2(2260,720),Vector2(2520,580)]:
			RuneArt.glyph(self,point,2,Color("91e7ec"),0.7)
			Art.ring(self,point,23,Color(0.3,0.8,0.85,0.35),2)
		for i in range(6,0,-1):draw_circle(world.EXIT,i*17,Color(0.34,0.78,0.88,0.025))
	if controller!=null:
		var mystery: Node = controller.puzzle
		if controller.cinematic_mode=="" and not mystery.gate_unlocked:
			var goal: Vector2 = mystery.goal()
			var lift := 64+sin(clock*3)*5
			var col := Color("ffdc93")
			Art.ring(self,goal,25,Color(col,0.65),2)
			draw_colored_polygon(PackedVector2Array([goal+Vector2(-10,-lift-12),goal+Vector2(10,-lift-12),goal+Vector2(0,-lift)]),col)
		if mystery.sigil_released and not mystery.gate_unlocked:
			var destination: Vector2 = player.global_position+Vector2(48,-85)
			var sigil: Vector2 = (controller.princess.global_position-Vector2(0,65)).lerp(destination,1-clampf(controller.sigil_flight/2,0,1))
			draw_sigil(sigil)
	# All event arrays inherit A3's hard population caps.
	for particle in particles:draw_rect(Rect2(Art.pixel_snap(particle.at),Vector2(4,4)),Color(particle.color,minf(1,particle.life*2)))
	for event in waves:
		var progress: float = 1-event.life/0.8
		Art.ring(self,event.at,12+progress*event.radius,Color(event.color,(1-progress)*0.8),2)
	for caption in captions:
		var position_value: Vector2 = caption.at-Vector2(ThemeDB.fallback_font.get_string_size(caption.words,HORIZONTAL_ALIGNMENT_LEFT,-1,16).x*0.5,0)
		draw_string(ThemeDB.fallback_font,position_value,caption.words,HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color(caption.color,minf(1,caption.life*2)))

func draw_sigil(at: Vector2) -> void:
	for i in range(5,0,-1):draw_circle(at,i*11,Color(1,0.73,0.3,0.03))
	RuneArt.glyph(self,at,2,Color("ffe3a0"),0.8)
	Art.ring(self,at,27,Color("d9b56d"),2)
