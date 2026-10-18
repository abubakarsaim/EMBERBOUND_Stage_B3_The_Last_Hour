extends Node2D
## Permanent mission facts live here; hazards and presentation remain separate.
signal completed
signal lamp_lit
signal mission_changed
signal anchor_disabled(index: int)
signal core_struck(count: int)
signal channel_cancelled(reason: String)
signal anchors_exposed
const RADIUS: float=220
const ANCHORS := [Vector2(760,960),Vector2(1800,960)]
const FONTS := [Vector2(720,1550),Vector2(1840,1550)]
const PRISON := Vector2(1280,650)
const PEDESTAL := Vector2(1280,1140)
const ROYAL_RUNE := Vector2(1280,1275)
enum Phase { ANCHORS, CORE, RESCUE, DAWN, ENDING, COMPLETE }
var phase: Phase=Phase.ANCHORS
var anchors: Array[bool]=[false,false]
var strikes: int=0
var solved: bool=false
var freed: bool=false
var lamps: Array[Node2D]=[]
var exposed_remaining: float=0
var barrier_angle: float=-0.30
var aligned: bool=false
var opening: bool=false
var freeze_serial: int=0
var last_strike_serial: int=-1
var freeze_aligned: bool=false
var channel_kind: String=""
var channel_index: int=0
var channel_time: float=0
var channel_duration: float=1.2
var font_cooldowns: Array[float]=[0,0]
var offering_ready: bool=false
var idle_time: float=0
func reset() -> void:
	phase=Phase.ANCHORS;anchors.fill(false);strikes=0;solved=false;freed=false
	barrier_angle=-0.30;freeze_serial=0;last_strike_serial=-1;offering_ready=false
	clear_temporary()
func clear_temporary() -> void:
	if phase in [Phase.ENDING,Phase.COMPLETE]:phase=Phase.DAWN
	exposed_remaining=0;aligned=false;opening=false;freeze_aligned=false
	channel_kind="";channel_time=0;font_cooldowns.fill(0);idle_time=0
	offering_ready=false;freeze_serial=0;last_strike_serial=-1
func lit_count() -> int:
	return int(anchors[0])+int(anchors[1])
func nearest_lamp(_at: Vector2) -> Node2D:return null
func update_feedback(_at: Vector2,_enemy: Node2D) -> void:pass
func core_point(boss: Node2D) -> Vector2:return boss.global_position+Vector2(0,90)
func is_aligned(boss: Node2D) -> bool:
	return absf(angle_difference(barrier_angle,(ROYAL_RUNE-boss.global_position).angle()))<=0.52
func register_freeze(boss: Node2D) -> void:
	freeze_serial+=1
	freeze_aligned=phase==Phase.CORE and is_aligned(boss)
	opening=freeze_aligned
func expose_anchors() -> void:
	if phase!=Phase.ANCHORS:return
	exposed_remaining=12
	anchors_exposed.emit()
func cancel_channel(reason: String) -> void:
	if channel_kind=="":return
	channel_kind="";channel_time=0;channel_cancelled.emit(reason)
func start_anchor(index: int, at: Vector2) -> String:
	if phase!=Phase.ANCHORS:return "The Chrono Anchors are already broken. Follow the current mission."
	if anchors[index]:return "This anchor is disabled. Its chain no longer feeds the prison."
	if at.distance_to(ANCHORS[index])>100:return "Approach the exposed anchor before channeling."
	if exposed_remaining<=0:return "Anchor shielded. Dodge the next telegraphed attack; its recovery exposes both anchors."
	channel_kind="anchor";channel_index=index;channel_time=0;channel_duration=1.2
	return "CHANNELING FLAME / Stand still for 1.2 seconds. Moving interrupts safely."
func start_core(at: Vector2, boss: Node2D, power: Node) -> String:
	if phase!=Phase.CORE:return "The two anchors must break before the clock core can be reached."
	if power.freeze_remaining<=0:return "The shield is moving. Stand near the core; use SPACE when the hand meets the gold royal symbol."
	if freeze_serial==last_strike_serial:return "One strike per opening. Let the barrier move again; recharge Time, then freeze another gold alignment."
	if not opening:return "Time froze the barrier away from its symbol. Wait for the next gold alignment, then cast again."
	if at.distance_to(core_point(boss))>130:return "Core exposed. Move closer to its golden focus, then E before Time resumes."
	channel_kind="core";channel_time=0;channel_duration=0.85
	return "CHANNELING INTO THE CORE / Stay within the opening until the light strikes."
func tick(delta: float, knight: Node2D, boss: Node2D, power: Node) -> void:
	idle_time+=delta
	for i in range(2):font_cooldowns[i]=maxf(0,font_cooldowns[i]-delta)
	if power.freeze_remaining<=0:
		exposed_remaining=maxf(0,exposed_remaining-delta)
		if phase==Phase.CORE:barrier_angle=fposmod(barrier_angle+delta*0.42,TAU)
		opening=false
	aligned=phase==Phase.CORE and is_aligned(boss)
	if channel_kind=="":return
	var target: Vector2=ANCHORS[channel_index] if channel_kind=="anchor" else core_point(boss)
	var distance_limit: float=105 if channel_kind=="anchor" else 130
	if knight.global_position.distance_to(target)>distance_limit or knight.velocity.length()>18 or Input.get_vector("move_left","move_right","move_up","move_down").length()>0.1:
		cancel_channel("Channel interrupted by movement. No extra flame was lost; approach and press E again.");return
	if channel_kind=="core" and (power.freeze_remaining<=0 or not opening):
		cancel_channel("Time resumed before the strike. Recharge at a fire source and try the next alignment.");return
	channel_time+=delta
	if channel_kind=="anchor":exposed_remaining=maxf(exposed_remaining,channel_duration-channel_time+0.1)
	if channel_time<channel_duration:return
	var completed_kind: String=channel_kind;channel_kind="";channel_time=0;idle_time=0
	if completed_kind=="anchor":
		anchors[channel_index]=true
		anchor_disabled.emit(channel_index)
		if lit_count()==2:
			phase=Phase.CORE;exposed_remaining=0;barrier_angle=-0.30;opening=false
			mission_changed.emit()
	else:
		strikes+=1;last_strike_serial=freeze_serial;opening=false
		core_struck.emit(strikes)
		if strikes>=2:
			phase=Phase.RESCUE;solved=true;mission_changed.emit();completed.emit()
func use_font(index: int, flame: Node) -> String:
	if font_cooldowns[index]>0:return "Ancient fire recharges in %.0f seconds. This light remains a safe refuge." % ceilf(font_cooldowns[index])
	if flame.value>=99.9:return "Your flame is full. This fire source remains available when you need it."
	flame.restore(30);font_cooldowns[index]=16
	return "+30 FLAME / Ancient fire recharges in 16 seconds. Use this refuge while Time recovers."
func mark_freed() -> void:
	freed=true;phase=Phase.DAWN;mission_changed.emit()
func checkpoint_position() -> Vector2:
	match phase:
		Phase.ANCHORS:return Vector2(1280,1700)
		Phase.CORE:return Vector2(1280,1530)
		Phase.RESCUE:return Vector2(1280,800)
		_:return Vector2(1280,1280)
