extends Node
signal activated
const COST: float = 15.0
const DURATION: float = 3.0
const COOLDOWN: float = 8.0
var freeze_remaining: float = 0.0
var cooldown_remaining: float = 0.0

func tick(delta: float) -> void:
	freeze_remaining = maxf(0.0, freeze_remaining - delta)
	cooldown_remaining = maxf(0.0, cooldown_remaining - delta)

func try_activate(flame: Node) -> String:
	if cooldown_remaining > 0.0:
		return "Borrowed Time is recharging."
	if flame.value < COST:
		return "You need 15 flame to borrow time."
	# Spending the very last ember correctly triggers the normal failure path.
	if not flame.spend(COST):
		return "You need 15 flame to borrow time."
	freeze_remaining = DURATION
	cooldown_remaining = COOLDOWN
	activated.emit()
	return "Time stands still. E at the east lamp to seal the circle."

func reset() -> void:
	freeze_remaining = 0.0
	cooldown_remaining = 0.0
