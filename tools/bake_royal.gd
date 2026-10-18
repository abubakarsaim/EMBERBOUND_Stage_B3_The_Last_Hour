extends SceneTree
func _initialize() -> void:
	var art = load("res://scripts/royal/royal_art.gd")
	if art==null:
		quit(1)
		return
	art.sheet(false).save_png("res://assets/royal/princess_idle.png")
	art.sheet(true).save_png("res://assets/royal/false_princess_idle.png")
	art.throne().save_png("res://assets/royal/throne.png")
	art.column().save_png("res://assets/royal/column.png")
	art.banner().save_png("res://assets/royal/torn_banner.png")
	art.window().save_png("res://assets/royal/broken_window.png")
	quit()
