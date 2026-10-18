extends Node2D
## Bounded event particles and labels. No physics, costs or puzzle rules live here.
const Art = preload("res://scripts/pixel_art.gd")
const MAX_PARTICLES: int = 160
var particles: Array[Dictionary] = []
var waves: Array[Dictionary] = []
var captions: Array[Dictionary] = []
var clock: float = 0.0
var world: Node2D
var player: Node2D
var puzzle: Node2D
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.seed = 2718

func burst(at: Vector2, color: Color, count: int = 20) -> void:
	for i in range(count):
		if particles.size() >= MAX_PARTICLES:
			particles.pop_front()
		particles.append({"at":at,"velocity":Vector2.from_angle(rng.randf_range(0,TAU))*rng.randf_range(24,105)+Vector2(0,-25),"life":rng.randf_range(0.4,1.1),"color":color})

func announce(at: Vector2, words: String, color: Color) -> void:
	captions.append({"at":at-Vector2(0,80),"words":words,"color":color,"life":1.7})
	if captions.size()>5:
		captions.pop_front()

func wave(at: Vector2, color: Color, radius: float = 180) -> void:
	waves.append({"at":at,"color":color,"life":0.8,"radius":radius})
	if waves.size()>8:
		waves.pop_front()

func clear() -> void:
	particles.clear()
	waves.clear()
	captions.clear()
	queue_redraw()

func _process(delta: float) -> void:
	clock += delta
	for i in range(particles.size()-1,-1,-1):
		particles[i].life -= delta
		particles[i].at += particles[i].velocity*delta
		particles[i].velocity += Vector2(0,25)*delta
		if particles[i].life <= 0:
			particles.remove_at(i)
	for i in range(waves.size()-1,-1,-1):
		waves[i].life -= delta
		if waves[i].life <= 0:
			waves.remove_at(i)
	for i in range(captions.size()-1,-1,-1):
		captions[i].life -= delta
		captions[i].at.y -= delta*11
		if captions[i].life <= 0:
			captions.remove_at(i)
	queue_redraw()

func _draw() -> void:
	if world == null:
		return
	# Sparse drifting dust and fireflies are deterministic and never obscure a target.
	for i in range(24):
		var at := Vector2(120+fmod(float(i)*173+clock*(3+i%3),1680),320+float((i*89)%430))
		var alpha := 0.10+maxf(0,sin(clock+i))*0.24
		draw_rect(Rect2(Art.pixel_snap(at),Vector2(2,2)),Color(0.55,0.73,0.85,alpha))
	# Sanctuary light and a hovering, original pixel-shaped ember.
	var cp: Vector2 = world.CHECKPOINT
	var col := Color("ffd284") if world.checkpoint_lit else Color("8bb9cd")
	for i in range(6,0,-1):
		draw_circle(cp,12+i*12,Color(col,0.018))
	var lift := roundf(sin(clock*1.8)*2)*2
	var center := cp+Vector2(0,-22+lift)
	draw_colored_polygon(PackedVector2Array([center+Vector2(-10,0),center+Vector2(0,-20),center+Vector2(10,0),center+Vector2(0,9)]),col)
	draw_rect(Rect2(center+Vector2(-2,-7),Vector2(4,10)),Color("fff3bd"))
	if world.gate_open:
		for i in range(8,0,-1):
			draw_circle(world.EXIT,i*12,Color(1,0.67,0.25,0.026))
		Art.ring(self,world.EXIT,42,Color("f5ca7d"),2)
		for x in range(1500,1760,38):
			var alpha := 0.3+sin(clock*3-float(x)*0.02)*0.2
			draw_line(Vector2(x,534),Vector2(x+8,540),Color(1,0.77,0.39,alpha),2,false)
			draw_line(Vector2(x+8,540),Vector2(x,546),Color(1,0.77,0.39,alpha),2,false)
	for particle in particles:
		draw_rect(Rect2(Art.pixel_snap(particle.at),Vector2(3,3)),Color(particle.color,minf(1,particle.life*2)))
	for event in waves:
		var progress: float = 1.0-event.life/0.8
		Art.ring(self,event.at,12+progress*event.radius,Color(event.color,(1-progress)*0.8),2)
	for caption in captions:
		var font := ThemeDB.fallback_font
		var size := font.get_string_size(caption.words,HORIZONTAL_ALIGNMENT_LEFT,-1,16)
		var at: Vector2 = caption.at-Vector2(size.x*0.5,0)
		draw_rect(Rect2(at+Vector2(-7,-18),size+Vector2(14,9)),Color(0.02,0.025,0.055,minf(0.9,caption.life)))
		draw_string(font,at,caption.words,HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color(caption.color,minf(1,caption.life*2)))
