extends Node
## Pure resource logic. The controller supplies whether the knight is protected.
signal extinguished
const MAX_FLAME: float = 100.0
@export var exposed_drain: float = 0.25
@export var protected_drain: float = 0.10
var value: float = MAX_FLAME

func tick(delta: float, protected: bool) -> void:
	set_value(value - delta * (protected_drain if protected else exposed_drain))

func set_value(amount: float) -> void:
	var previous := value
	value = clampf(amount, 0.0, MAX_FLAME)
	if previous > 0.0 and value <= 0.0:
		extinguished.emit()

func restore(amount: float) -> void:
	set_value(value + amount)

func spend(amount: float) -> bool:
	if value < amount:
		return false
	set_value(value - amount)
	return true

func reset(amount: float = MAX_FLAME) -> void:
	value = clampf(amount, 0.0, MAX_FLAME)
