extends SceneTree
func _initialize() -> void:
	call_deferred("bake")
func bake() -> void:
	var art=load("res://scripts/boss/boss_art.gd")
	for i in range(5):
		var error: int = art.sheet(i).save_png("res://assets/boss/hourkeeper_%s.png" % ["idle","charge","stagger","defeat","release"][i])
		if error!=OK: quit(1);return
	print("B3_SPRITES_BAKED")
	quit()
