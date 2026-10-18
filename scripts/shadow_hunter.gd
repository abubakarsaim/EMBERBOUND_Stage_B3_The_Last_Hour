extends CharacterBody2D
const Art = preload("res://scripts/pixel_art.gd")
signal struck
signal flare_charging(target: Vector2)
signal flare_fired(origin: Vector2, target: Vector2)
signal flare_cancelled
# The strong/weak-light movement rules are retained underneath these explicit phases.
enum State { STALKING, HUNTING, FROZEN, TRAPPED, REPELLED, CHARGING, ATTACKING, RECOVERING }
const INTERVAL: float = 7.0
const CHARGE_TIME: float = 0.8
const RECOVERY_TIME: float = 1.0
var navigation_direction := Vector2.ZERO
var pursuit_speed_scale: float = 1.0
var state: State = State.STALKING
var visual_frames: Array[Texture2D] = []
var clock: float = 0.0
var attack_windup: float = 0.0
var grace: float = 0.0
var active: bool = false
var knight: CharacterBody2D
var flame: Node
var time_power: Node
var sanctuary := Vector2(800,540)
var sanctuary_active: bool = false
var attacks_suppressed: bool = false
var attack_cooldown: float = 6.0
var charge_remaining: float = 0.0
var recovery_remaining: float = 0.0
var release_remaining: float = 0.0
var locked_target := Vector2.ZERO
var suspended_phase: State = State.STALKING

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for i in range(6):
		visual_frames.append(Art.hunter_frame(i))

func tick(delta: float) -> void:
	if not active or state == State.TRAPPED:
		velocity = Vector2.ZERO
		queue_redraw()
		return
	if time_power.freeze_remaining > 0.0:
		if state != State.FROZEN:
			suspended_phase = state
		state = State.FROZEN
		velocity = Vector2.ZERO
		attack_windup = 0.0
		queue_redraw()
		return
	if state == State.FROZEN:
		state = suspended_phase
	clock += delta
	grace = maxf(grace-delta,0)
	attack_cooldown = maxf(attack_cooldown-delta,0)
	var offset: Vector2 = knight.global_position-global_position
	var distance := offset.length()
	var direction := offset.normalized()
	var strong: bool = flame.value >= 40.0
	var stand_off: float = 85.0+flame.value*0.55 if strong else 0.0
	var pursue_speed := lerpf(165,100,flame.value/100.0)
	var in_sanctuary: bool = sanctuary_active and knight.global_position.distance_to(sanctuary)<64
	if attacks_suppressed or in_sanctuary:
		cancel_ranged()
		attack_cooldown = maxf(attack_cooldown,2.0)
	if state == State.CHARGING:
		charge_remaining = maxf(0,charge_remaining-delta)
		velocity = velocity.move_toward(Vector2.ZERO,1400*delta)
		attack_windup = 0
		move_and_slide()
		if charge_remaining <= 0:
			state = State.ATTACKING
			release_remaining = 0.18
			var aim := (locked_target-global_position).normalized()
			flare_fired.emit(global_position+aim*36,locked_target)
		queue_redraw()
		return
	if state == State.ATTACKING:
		release_remaining -= delta
		velocity = Vector2.ZERO
		if release_remaining <= 0:
			state = State.RECOVERING
			recovery_remaining = RECOVERY_TIME
		queue_redraw()
		return
	var recovering := state == State.RECOVERING and recovery_remaining>0
	if recovering:
		recovery_remaining = maxf(0,recovery_remaining-delta)
	else:
		state = State.STALKING if strong else State.HUNTING
	# Do not fire point-blank. The locked aim never homes after the warning appears.
	if not recovering and not attacks_suppressed and not in_sanctuary and attack_cooldown<=0 and distance>=85 and distance<=520:
		state = State.CHARGING
		locked_target = knight.global_position
		charge_remaining = CHARGE_TIME
		attack_cooldown = INTERVAL
		attack_windup = 0
		flare_charging.emit(locked_target)
		queue_redraw()
		return
	if in_sanctuary:
		state = State.REPELLED
		velocity = -direction*95 if distance<185 else Vector2.ZERO
	elif strong and distance<stand_off-7:
		velocity = -direction*115
	elif distance>stand_off+5:
		velocity = (navigation_direction if navigation_direction != Vector2.ZERO else direction)*pursue_speed*pursuit_speed_scale*(0.75 if recovering else 1.0)
	else:
		velocity = Vector2.ZERO
	# Retain the original telegraphed low-flame close attack.
	if distance<34 and not strong and grace<=0:
		attack_windup += delta
		velocity = Vector2.ZERO
		if attack_windup>=0.65:
			struck.emit()
			attack_windup = 0
			grace = 1.8
			velocity = -direction*220
	else:
		attack_windup = 0
	if grace>1.1:
		velocity = -direction*145
	move_and_slide()
	queue_redraw()

func cancel_ranged() -> void:
	if state == State.CHARGING or state == State.ATTACKING:
		state = State.STALKING
		flare_cancelled.emit()
	charge_remaining = 0
	release_remaining = 0

func reset(at: Vector2) -> void:
	global_position = at
	state = State.STALKING
	suspended_phase = State.STALKING
	attack_windup = 0
	grace = 1.0
	attack_cooldown = 6.0
	charge_remaining = 0
	release_remaining = 0
	recovery_remaining = 0
	attacks_suppressed = false
	velocity = Vector2.ZERO
	reset_physics_interpolation()
	queue_redraw()

func trap() -> void:
	cancel_ranged()
	state = State.TRAPPED
	velocity = Vector2.ZERO
	queue_redraw()

func state_label() -> String:
	return State.keys()[state].capitalize()

func _draw() -> void:
	var frozen := state == State.FROZEN or state == State.TRAPPED
	var weak: float = 1.0-clampf(flame.value/100.0,0,1) if flame != null else 0.0
	var color := Color("7ce9f3") if frozen else Color("dc3157")
	# Heavy aura and discretely animated smoke make a larger visual presence.
	for i in range(8,0,-1):
		draw_set_transform(Vector2(0,-19),0,Vector2(1,0.63))
		draw_circle(Vector2.ZERO,47+i*7,Color(0.01,0.005,0.025,0.035+weak*0.012))
		draw_set_transform(Vector2.ZERO)
	var frame := int(clock*5.0)%6
	var hover := roundf(sin(clock*2.5)*2.0)*2.0
	for i in range(12):
		var phase := fmod(clock*0.3+i*0.083,1.0)
		var angle := float(i)*2.4
		var point := Vector2(cos(angle)*(42+phase*19),-14+sin(angle)*25-phase*44)
		var size := 4.0+(1.0-phase)*6
		draw_rect(Rect2(Art.pixel_snap(point),Vector2(size,size).snapped(Vector2(2,2))),Color(0.09,0.035,0.13,(1-phase)*0.6))
	var tint := Color(0.66,0.85,1.0) if frozen else Color.WHITE
	draw_texture_rect(visual_frames[frame],Rect2(-72,-130+hover,144,160),false,tint)
	# Eyes have a soft outer glow but a hard pixel core.
	for eye in [Vector2(-14,-68+hover),Vector2(12,-70+hover)]:
		for i in range(4,0,-1):
			draw_circle(eye,4+i*3,Color(color,0.035+weak*0.015))
		draw_rect(Rect2(Art.pixel_snap(eye-Vector2(4,1)),Vector2(8,2)),color)
		draw_rect(Rect2(Art.pixel_snap(eye),Vector2(2,2)),Color("ffe7e3") if not frozen else Color.WHITE)
	if frozen:
		Art.ring(self,Vector2(0,-40),58,Color(color,0.75),2)
		Art.ring(self,Vector2(0,4),33,Color(color,0.6),2)
		for i in range(6):
			var a := Vector2.from_angle(float(i)*TAU/6)
			draw_line(Art.pixel_snap(Vector2(0,-40)+a*48),Art.pixel_snap(Vector2(0,-40)+a*64),color,2,false)
	if attack_windup > 0.0:
		# This ring is the original collision/attack footprint, not the large smoke aura.
		Art.ring(self,Vector2.ZERO,40,Color("ff5262"),4,-PI/2,-PI/2+TAU*attack_windup/0.65)

	if state == State.CHARGING:
		var progress := 1.0-charge_remaining/CHARGE_TIME
		var mark := locked_target-global_position
		Art.ring(self,Vector2(0,-52),22+progress*18,Color("ff5575"),3)
		Art.ring(self,mark,29,Color(0.95,0.24,0.4,0.7),2)
		draw_line(mark-Vector2(9,9),mark+Vector2(9,9),Color("ee5978"),2,false)
		draw_line(mark+Vector2(9,-9),mark+Vector2(-9,9),Color("ee5978"),2,false)
		var length := mark.length()
		var aim := mark.normalized()
		for at in range(28,int(length)-12,18):
			var a := aim*at
			draw_line(Art.pixel_snap(a),Art.pixel_snap(a+aim*7),Color(0.8,0.18,0.35,0.5),2,false)
		for i in range(8):
			var a := Vector2.from_angle(i*TAU/8+clock*1.5)
			var point := Vector2(0,-52)+a*(46-progress*25)
			draw_rect(Rect2(Art.pixel_snap(point),Vector2(4,4)),Color("d9476b"))
