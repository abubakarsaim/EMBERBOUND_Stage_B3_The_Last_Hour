extends SceneTree
func _initialize() -> void:
	var art = load("res://scripts/forest/forest_art.gd")
	for i in range(3):
		art.tree(i).save_png("res://assets/forest/twisted_tree_%d.png" % i)
	art.pillar().save_png("res://assets/forest/broken_pillar.png")
	quit()
