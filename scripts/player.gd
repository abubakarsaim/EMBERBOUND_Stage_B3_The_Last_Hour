extends CharacterBody2D
const Art = preload("res://scripts/pixel_art.gd")
@export var speed: float = 220.0
@export var acceleration: float = 2100.0
@export var deceleration: float = 2600.0
var active: bool = false
var flame_strength: float = 100.0
var facing := Vector2.RIGHT
var walk_clock: float = 0.0
var idle_clock: float = 0.0
var invulnerable: float = 0.0
var hurt_flash: float = 0.0
var cast_remaining: float = 0.0
var torch_radius: float = 230.0
var light_impact: float = 0.0
var frames: Array[Texture2D] = []

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for direction in range(3):
		for frame in range(4):
			frames.append(Art.knight_frame(direction,frame))

func _physics_process(delta: float) -> void:
	if not active:
		velocity = Vector2.ZERO
		return
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = velocity.move_toward(direction * speed, (acceleration if direction != Vector2.ZERO else deceleration) * delta)
	if direction.length_squared() > 0.01:
		facing = direction
	invulnerable = maxf(0.0, invulnerable - delta)
	move_and_slide()

func _process(delta: float) -> void:
	idle_clock += delta
	if velocity.length_squared() > 30.0:
		walk_clock += delta * 10.0
	else:
		walk_clock = 0.0
	cast_remaining = maxf(0.0,cast_remaining-delta)
	hurt_flash = maxf(0.0,hurt_flash-delta)
	light_impact = maxf(0,light_impact-delta)
	var target_radius := lerpf(65.0,230.0,flame_strength/100.0)*(1.0-0.26*light_impact/0.65)
	torch_radius = lerpf(torch_radius,target_radius,1.0-exp(-delta*18))
	queue_redraw()

func cast_feedback() -> void:
	cast_remaining = 0.75

func hurt_feedback() -> void:
	hurt_flash = 0.40
	light_impact = 0.65

func torch_position() -> Vector2:
	return global_position+Vector2(-27 if facing.x < -0.3 else 27,-47)

func reset_visuals() -> void:
	cast_remaining = 0.0
	hurt_flash = 0.0
	light_impact = 0.0
	torch_radius = lerpf(65,230,flame_strength/100.0)
	walk_clock = 0.0
	reset_physics_interpolation()

func _draw() -> void:
	var bob := (2.0 if int(walk_clock)%4 == 1 or int(walk_clock)%4 == 3 else 0.0) if velocity.length() > 10 else (0.0 if sin(idle_clock*2.0)>-0.5 else 1.0)
	var torch_x := -27.0 if facing.x < -0.3 else 27.0
	var torch := Vector2(torch_x,-47-bob)
	var flicker := 1.0+sin(idle_clock*8.0)*0.025+sin(idle_clock*13.0)*0.015
	if light_impact > 0:
		flicker *= 0.87+0.13*sin(idle_clock*42)
	for i in range(9,0,-1):
		draw_circle(torch,torch_radius*flicker*i/9.0,Color(1.0,0.55,0.16,0.008+float(9-i)*0.003))
	# Footprint stays tied to the original small physics body.
	draw_set_transform(Vector2(0,7),0,Vector2(1,0.34))
	draw_circle(Vector2.ZERO,29,Color(0.01,0.015,0.03,0.65))
	draw_set_transform(Vector2.ZERO)
	var direction := 1 if absf(facing.x) >= absf(facing.y) else (2 if facing.y < 0 else 0)
	var frame := int(walk_clock)%4
	var tint := Color(1,0.5,0.5) if hurt_flash > 0.0 and int(hurt_flash*25)%2 else Color.WHITE
	if cast_remaining > 0.0:
		Art.ring(self,Vector2(0,2),30+(0.75-cast_remaining)*100,Color(0.36,0.88,1.0,cast_remaining),2)
		tint = Color(0.72,0.95,1.0)
	if facing.x < -0.3:
		draw_set_transform(Vector2(0,-bob),0,Vector2(-1,1))
	else:
		draw_set_transform(Vector2(0,-bob))
	draw_texture_rect(frames[direction*4+frame],Rect2(-40,-84,80,96),false,tint)
	draw_set_transform(Vector2.ZERO)
	# Torch pixels, embers and cast flare remain independent of body direction.
	draw_rect(Rect2(torch+Vector2(-2,2),Vector2(4,15)),Color("614132"))
	draw_rect(Rect2(torch+Vector2(-5,0),Vector2(10,4)),Color("b79a64"))
	var fire_color := Color("65e4f4") if cast_remaining > 0 else Color("ef9d43")
	if light_impact > 0 and sin(idle_clock*38)>0:
		fire_color = Color("ad5370")
	var flame_height := 13+int(sin(idle_clock*11)*3)
	draw_rect(Rect2(torch+Vector2(-6,-8),Vector2(12,9)),fire_color)
	draw_rect(Rect2(torch+Vector2(-4,-flame_height),Vector2(8,flame_height)),fire_color)
	draw_rect(Rect2(torch+Vector2(-2,-flame_height-4),Vector2(4,6)),fire_color)
	draw_rect(Rect2(torch+Vector2(-2,-7),Vector2(4,8)),Color("fff1b2"))
	for i in range(4):
		var age := fmod(idle_clock*0.6+i*0.27,1.0)
		var point := torch+Vector2(sin(idle_clock+i)*9,-10-age*30)
		draw_rect(Rect2(Art.pixel_snap(point),Vector2(2,2)),Color(fire_color,1.0-age))
	if invulnerable > 0.0 and hurt_flash > 0.0:
		Art.ring(self,Vector2.ZERO,25,Color(1,0.4,0.4,0.7),2)
