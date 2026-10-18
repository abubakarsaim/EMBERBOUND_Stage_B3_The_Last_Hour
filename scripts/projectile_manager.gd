extends Node2D
signal flame_hit(amount: float, at: Vector2)
signal dissipated(at: Vector2)
const FLARE = preload("res://scenes/shadow_flare.tscn")
const MAX_ACTIVE: int = 4
var active: Array[Node2D] = []
var shots_fired: int = 0
var hits_reported: int = 0

func launch(origin: Vector2, target: Vector2) -> bool:
	if active.size() >= MAX_ACTIVE:
		return false
	var flare: Node2D = FLARE.instantiate()
	add_child(flare)
	flare.setup(origin,target)
	active.append(flare)
	shots_fired += 1
	return true

func tick(delta: float, hold: bool, knight: Node2D, protected: bool) -> void:
	if protected:
		# Sacred space prevents lingering flares from disrupting a puzzle interaction.
		for flare in active:
			dissipated.emit(flare.global_position)
		clear(false)
		return
	for i in range(active.size()-1,-1,-1):
		var flare: Node2D = active[i]
		var result: String = flare.advance(delta,hold,knight)
		if result == "hit":
			hits_reported += 1
			flame_hit.emit(flare.DAMAGE,flare.global_position)
		elif result == "wall":
			dissipated.emit(flare.global_position)
		if flare.expired:
			active.remove_at(i)
			flare.queue_free()

func freeze_now() -> void:
	for flare in active:
		flare.frozen = true
		flare.queue_redraw()

func clear(reset_counters: bool = true) -> void:
	for flare in active:
		flare.queue_free()
	active.clear()
	if reset_counters:
		shots_fired = 0
		hits_reported = 0
