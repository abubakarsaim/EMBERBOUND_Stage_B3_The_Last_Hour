extends Node2D
## A single, dodgeable flare with a locked warning. Borrowed Time holds every timer.
signal charging(target: Vector2)
signal fired(origin: Vector2, target: Vector2)
signal cancelled
const Art = preload("res://scripts/pixel_art.gd")
enum State { DORMANT, STALKING, CHARGING, RECOVERING, FROZEN, BOUND }
const CHARGE: float = 1.05
const INTERVAL: float = 6.8
const RECOVERY: float = 1.6
var active: bool = false
var state: State = State.DORMANT
var resume_state: State = State.STALKING
var charge_remaining: float = 0
var recovery_remaining: float = 0
var attack_remaining: float = 4
var aim := Vector2.ZERO
var origin := Vector2.ZERO
var shots_fired: int = 0
var clock: float = 0
func reset(enabled: bool) -> void:
	active = enabled
	state = State.STALKING if enabled else State.DORMANT
	resume_state = state
	charge_remaining = 0
	recovery_remaining = 0
	attack_remaining = 4
	shots_fired = 0
	clock = 0
	queue_redraw()
func tick(delta: float, actor: Node2D, knight: Node2D, power: Node, armed: bool, protected: bool) -> void:
	origin = actor.global_position
	if not active:
		queue_redraw()
		return
	if power.freeze_remaining>0:
		if state!=State.FROZEN: resume_state = state
		state = State.FROZEN
		queue_redraw()
		return
	if state==State.FROZEN: state = resume_state
	clock += delta
	if protected and state==State.CHARGING:
		state = State.RECOVERING
		charge_remaining = 0
		recovery_remaining = RECOVERY
		attack_remaining = maxf(attack_remaining,3)
		cancelled.emit()
	attack_remaining = maxf(0,attack_remaining-delta)
	if state==State.CHARGING:
		charge_remaining -= delta
		if charge_remaining<=0:
			fired.emit(actor.global_position,aim)
			shots_fired += 1
			attack_remaining = INTERVAL
			recovery_remaining = RECOVERY
			state = State.RECOVERING
	else:
		var target: Vector2 = Vector2(1536,780)
		if armed and knight.global_position.distance_to(Vector2(1536,1000))<400:
			target = Vector2(1536,980)
		elif knight.global_position.distance_to(Vector2(1536,1000))<650:
			target = knight.global_position+actor.global_position.direction_to(knight.global_position)*-135
		# The open throne court has no column bases to snag this floating apparition.
		target = target.clamp(Vector2(1270,720),Vector2(1900,1320))
		actor.global_position = actor.global_position.move_toward(target,delta*(45 if state==State.RECOVERING else 82))
		if state==State.RECOVERING:
			recovery_remaining = maxf(0,recovery_remaining-delta)
			if recovery_remaining<=0: state = State.STALKING
		if state==State.STALKING and attack_remaining<=0 and not protected and actor.global_position.distance_to(knight.global_position)<620:
			state = State.CHARGING
			charge_remaining = CHARGE
			aim = knight.global_position
			charging.emit(aim)
	origin = actor.global_position
	queue_redraw()
func state_label() -> String:
	return ["quiet","stalking","charging","recovering","frozen","bound"][state]
func _draw() -> void:
	if not active: return
	if state==State.CHARGING or (state==State.FROZEN and resume_state==State.CHARGING):
		var frozen: bool = state==State.FROZEN
		var col := Color("86e9ee") if frozen else Color("ed6289")
		var progress := clampf(1-charge_remaining/CHARGE,0,1)
		Art.ring(self,aim,42,col,3)
		draw_line(aim-Vector2(52,0),aim+Vector2(52,0),Color(col,0.5),2,false)
		draw_line(aim-Vector2(0,52),aim+Vector2(0,52),Color(col,0.5),2,false)
		draw_dashed_line(origin-Vector2(0,60),aim-Vector2(0,38),Color(col,0.55),2,12,false)
		Art.ring(self,origin-Vector2(0,65),18+progress*30,col,3)
		for i in range(6):
			var at := origin-Vector2(0,65)+Vector2.from_angle(clock*3+i*TAU/6)*(48-progress*20)
			draw_rect(Rect2(at.snapped(Vector2(2,2)),Vector2(5,5)),col)
