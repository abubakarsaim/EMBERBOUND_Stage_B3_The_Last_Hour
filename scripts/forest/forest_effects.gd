extends "res://scripts/world_effects.gd"
## Forest fog/fire is culled to the camera. Base event arrays remain bounded.
func _draw() -> void:
	if world == null: return
	var camera_rect := Rect2(player.global_position-Vector2(800,500),Vector2(1600,1000))
	for at in [world.CHECKPOINT,world.CLUES[0],world.CLUES[1],world.CLUES[2]]:
		if not camera_rect.grow(150).has_point(at): continue
		for i in range(5,0,-1):
			draw_circle(at,i*20,Color(0.35,0.72,0.84,0.018))
	for i in range(world.TORCHES.size()):
		var at: Vector2 = world.TORCHES[i]
		if not camera_rect.grow(150).has_point(at): continue
		draw_rect(Rect2(at+Vector2(-6,-45),Vector2(12,46)),Color("352535"))
		draw_rect(Rect2(at+Vector2(-12,-44),Vector2(24,5)),Color("a88e63"))
		if world.torch_timers[i]>0:
			for j in range(6,0,-1): draw_circle(at-Vector2(0,49),j*18,Color(1,0.57,0.16,0.023))
			var h := 19+int(sin(clock*9+i)*3)*2
			draw_rect(Rect2(at+Vector2(-8,-48-h),Vector2(16,h)),Color("db793d"))
			draw_rect(Rect2(at+Vector2(-4,-54-h),Vector2(8,h+7)),Color("ffd180"))
			draw_string(ThemeDB.fallback_font,at+Vector2(-25,29),"%ds" % ceili(world.torch_timers[i]),HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("dac390"))
		if player.global_position.distance_to(at)<72:
			draw_string(ThemeDB.fallback_font,at+Vector2(-56,-94),"[E] WATCHFIRE",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("ffe1a2"))
	# Broad, transparent blue-purple wisps do not mask interaction symbols.
	for i in range(14):
		var x := fmod(i*383.0+clock*7,4700.0)-50
		var y := 280.0+(i*233)%2300
		if not camera_rect.grow(400).has_point(Vector2(x,y)): continue
		var points := PackedVector2Array([Vector2(x-250,y),Vector2(x-110,y-13),Vector2(x+90,y-7),Vector2(x+310,y+17),Vector2(x+260,y+30),Vector2(x-170,y+21)])
		draw_colored_polygon(points,Color(0.25,0.33,0.56,0.055))
	for i in range(100):
		var at := Vector2(160+fmod(i*137.0+clock*(2+i%3),4280),240+(i*283)%2300)
		if camera_rect.has_point(at): draw_rect(Rect2(at.snapped(Vector2(2,2)),Vector2(2,2)),Color(0.5,0.8,0.9,0.12+maxf(0,sin(clock+i))*0.23))
	if world.gate_open:
		for i in range(6,0,-1): draw_circle(world.EXIT,i*16,Color(1,0.7,0.27,0.023))
	# Event-only effects from the shared A3 system.
	for particle in particles:
		draw_rect(Rect2(Art.pixel_snap(particle.at),Vector2(3,3)),Color(particle.color,minf(1,particle.life*2)))
	for event in waves:
		var progress: float = 1-event.life/0.8
		Art.ring(self,event.at,12+progress*event.radius,Color(event.color,(1-progress)*0.8),2)
	for caption in captions:
		var at: Vector2 = caption.at-Vector2(ThemeDB.fallback_font.get_string_size(caption.words,HORIZONTAL_ALIGNMENT_LEFT,-1,16).x*0.5,0)
		draw_string(ThemeDB.fallback_font,at,caption.words,HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color(caption.color,minf(1,caption.life*2)))
