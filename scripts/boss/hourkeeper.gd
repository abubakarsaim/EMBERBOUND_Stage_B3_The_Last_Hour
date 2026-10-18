extends Node2D
const Art=preload("res://scripts/pixel_art.gd")
const SHEETS := [preload("res://assets/boss/hourkeeper_idle.png"),preload("res://assets/boss/hourkeeper_charge.png"),preload("res://assets/boss/hourkeeper_stagger.png"),preload("res://assets/boss/hourkeeper_defeat.png"),preload("res://assets/boss/hourkeeper_release.png")]
var clock: float=0
var pose: int=0
var stagger: float=0
var release_remaining: float=0
var defeat_progress: float=0
var defeated: bool=false
var charging: bool=false
var moving: bool=true
var home:=Vector2(1280,1040)
func tick(delta: float) -> void:
	clock+=delta
	stagger=maxf(0,stagger-delta)
	release_remaining=maxf(0,release_remaining-delta)
	if moving and not defeated and not charging and stagger<=0:
		global_position=global_position.move_toward(home+Vector2(sin(clock*0.35)*16,sin(clock*0.28)*9),delta*22)
	pose=3 if defeated else (2 if stagger>0 else (1 if charging else (4 if release_remaining>0 else 0)))
	queue_redraw()
func reset_actor() -> void:
	global_position=home;clock=0;pose=0;stagger=0;release_remaining=0;defeat_progress=0;defeated=false;charging=false;moving=true;modulate=Color.WHITE;visible=true;reset_physics_interpolation()
func _draw() -> void:
	var alpha: float=1-defeat_progress
	if alpha<=0:return
	draw_set_transform(Vector2(0,12),0,Vector2(1,0.32));draw_circle(Vector2.ZERO,104,Color(0.015,0.009,0.03,alpha*0.8));draw_set_transform(Vector2.ZERO)
	for i in range(7,0,-1):draw_circle(Vector2(0,-105),i*23,Color(0.24,0.03,0.15,0.025*alpha))
	var hover: float=roundf(sin(clock*1.8))*2
	var tint:=Color("c8ffff") if pose==2 else Color.WHITE
	tint.a=alpha
	draw_texture_rect_region(SHEETS[pose],Rect2(-96,-248+hover+defeat_progress*50,192,256),Rect2((int(clock*(4 if charging else 2))%4)*96,0,96,128),tint)
	# Broken gears orbit outside the robe; the core and crown remain readable.
	for i in range(8):
		var angle: float=clock*0.3+i*TAU/8
		var at: Vector2=(Vector2(cos(angle)*127,sin(angle)*55-135)+Vector2.from_angle(i*2.3)*defeat_progress*170).snapped(Vector2(2,2))
		Art.ring(self,at,11+i%3,Color(0.56,0.47,0.35,alpha),3)
		for j in range(4):
			var reach:=Vector2.from_angle(j*PI/2+angle)*16
			draw_rect(Rect2(at+reach-Vector2(3,3),Vector2(6,6)),Color(0.59,0.54,0.44,alpha))
		if i%2==0:draw_rect(Rect2(at-Vector2(2,2),Vector2(4,4)),Color(0.45,0.87,0.9,alpha))
