extends Node2D
## Deterministic attacks never overlap: windup -> one hazard -> recovery.
signal flare_requested(origin: Vector2,target: Vector2)
signal damage_requested(amount: float)
signal slow_requested(duration: float)
signal warning(kind: int)
signal recovery_started
signal released(kind: int)
const Art=preload("res://scripts/pixel_art.gd")
enum Kind { FLARE, SWEEP, DISTORTION }
enum State { RECOVERING, WINDUP, RELEASING }
const WINDUPS := [1.1,1.55,1.65]
const SWEEP_INNER: float=115
const SWEEP_OUTER: float=520
const PULSE_RADIUS: float=340
var active: bool=false
var state: State=State.RECOVERING
var kind: Kind=Kind.FLARE
var next_kind: int=0
var remaining: float=3
var elapsed: float=0
var aim:=Vector2.ZERO
var origin:=Vector2.ZERO
var aim_angle: float=0
var hand_angle: float=0
var pulse_radius: float=0
var hit_once: bool=false
var frozen: bool=false
var total_attacks: Array[int]=[0,0,0]
func reset(enabled: bool, first: int=0) -> void:
	active=enabled;state=State.RECOVERING;remaining=3;elapsed=0;next_kind=first
	hit_once=false;frozen=false;pulse_radius=0;total_attacks.fill(0);queue_redraw()
func recover(seconds: float=2.6) -> void:
	state=State.RECOVERING;remaining=seconds;elapsed=0;pulse_radius=0;hit_once=false;queue_redraw()
func begin_attack(boss: Node2D,knight: Node2D) -> void:
	kind=next_kind;next_kind=(next_kind+1)%3
	origin=boss.global_position;aim=knight.global_position;aim_angle=(aim-origin).angle()
	hand_angle=aim_angle-0.8;state=State.WINDUP;remaining=WINDUPS[kind];elapsed=0;hit_once=false
	warning.emit(kind)
func tick(delta: float,boss: Node2D,knight: Node2D,shots: Node,power: Node,protected: bool,channeling: bool) -> void:
	frozen=power.freeze_remaining>0
	if not active or frozen or channeling:queue_redraw();return
	remaining-=delta;elapsed+=delta
	if state==State.RECOVERING:
		if remaining<=0:begin_attack(boss,knight)
	elif state==State.WINDUP:
		if remaining<=0:
			state=State.RELEASING;elapsed=0;total_attacks[kind]+=1
			remaining=[4.6,1.2,0.9][kind]
			released.emit(kind)
			if kind==Kind.FLARE:flare_requested.emit(origin,aim)
	elif kind==Kind.FLARE:
		if remaining<=0 or shots.active.is_empty():finish_attack()
	elif kind==Kind.SWEEP:
		var previous: float=hand_angle
		hand_angle=aim_angle-0.8+clampf(elapsed/1.2,0,1)*1.6
		var offset: Vector2=knight.global_position-origin
		var angle: float=aim_angle+angle_difference(aim_angle,offset.angle())
		var tolerance: float=asin(clampf(33/maxf(1,offset.length()),0,1))
		if not hit_once and not protected and offset.length()>=SWEEP_INNER and offset.length()<=SWEEP_OUTER and angle>=previous-tolerance and angle<=hand_angle+tolerance:
			hit_once=true;damage_requested.emit(8)
		if remaining<=0:finish_attack()
	else:
		var previous: float=pulse_radius
		pulse_radius=clampf(elapsed/0.9,0,1)*(PULSE_RADIUS+32)
		var distance: float=knight.global_position.distance_to(origin)
		if not hit_once and not protected and distance>=previous-24 and distance<=pulse_radius+24:
			hit_once=true;slow_requested.emit(1.6)
		if remaining<=0:finish_attack()
	queue_redraw()
func finish_attack() -> void:
	recover(3.0 if kind==Kind.DISTORTION else 2.6)
	recovery_started.emit()
func state_label() -> String:
	if not active:return "defeated"
	if frozen:return "magic held in time"
	if state==State.RECOVERING:return "recovering"
	return ["shadow flare","clock-hand sweep","time distortion"][kind]+(" charging" if state==State.WINDUP else " released")
func sector(from_angle: float,to_angle: float,color: Color) -> void:
	var poly:=PackedVector2Array()
	for i in range(25):poly.append(origin+Vector2.from_angle(lerpf(from_angle,to_angle,i/24.0))*SWEEP_OUTER)
	for i in range(24,-1,-1):poly.append(origin+Vector2.from_angle(lerpf(from_angle,to_angle,i/24.0))*SWEEP_INNER)
	draw_colored_polygon(poly,color)
func _draw() -> void:
	if not active or state==State.RECOVERING:return
	var crimson:=Color("e87a91") if not frozen else Color("8beaf0")
	if kind==Kind.FLARE and state==State.WINDUP:
		Art.ring(self,aim,43,crimson,3)
		draw_dashed_line(origin-Vector2(0,100),aim-Vector2(0,38),Color(crimson,0.5),2,13,false)
		Art.ring(self,origin-Vector2(0,115),26+(1-remaining/1.1)*35,crimson,3)
	elif kind==Kind.SWEEP:
		sector(aim_angle-0.8,aim_angle+0.8,Color(0.7,0.15,0.3,0.15 if state==State.WINDUP else 0.06))
		for angle in [aim_angle-0.8,aim_angle+0.8]:draw_line(origin+Vector2.from_angle(angle)*SWEEP_INNER,origin+Vector2.from_angle(angle)*SWEEP_OUTER,crimson,3,false)
		draw_arc(origin,SWEEP_OUTER,aim_angle-0.8,aim_angle+0.8,40,crimson,3,false)
		if state==State.RELEASING:
			var direction:=Vector2.from_angle(hand_angle)
			draw_line(origin+direction*SWEEP_INNER,origin+direction*SWEEP_OUTER,Color("30162e"),30,false)
			draw_line(origin+direction*SWEEP_INNER,origin+direction*SWEEP_OUTER,crimson,16,false)
			draw_line(origin+direction*SWEEP_INNER,origin+direction*(SWEEP_OUTER-20),Color("ffe0ad"),4,false)
	else:
		var col:=Color("85dfe8")
		Art.ring(self,origin,PULSE_RADIUS,col,3)
		if state==State.WINDUP:
			var radius: float=45+(1-remaining/1.65)*(PULSE_RADIUS-45)
			Art.ring(self,origin,radius,Color(col,0.5),4)
			draw_circle(origin,PULSE_RADIUS,Color(col,0.035))
		else:
			Art.ring(self,origin,pulse_radius,col,16)
			Art.ring(self,origin,maxf(1,pulse_radius-22),Color(col,0.3),5)
