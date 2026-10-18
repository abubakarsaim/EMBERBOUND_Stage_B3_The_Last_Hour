extends "res://tests/test_forest.gd"
## The parent traverses the existing forest and shrine using real Input actions.
func inspect_royal() -> void:
	check(root.find_children("Audio","",true,false).size()==1,"Three-chapter progression keeps exactly one active audio director")
	check(game.audio.music_volume==0.4 and game.audio.sfx_volume==0.3 and absf(game.flame.value-root.get_node("Journey").carried_flame)<0.01,"Shrine-to-hall handoff preserves flame and audio settings")
	await preload("res://tests/royal_route.gd").new().run(self)

	await preload("res://tests/boss_route.gd").new().run(self)
