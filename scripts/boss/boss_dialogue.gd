extends "res://scripts/royal/dialogue.gd"
func refresh() -> void:
	super.refresh()
	if active and speaker.text=="HOURKEEPER":
		var atlas:=AtlasTexture.new();atlas.atlas=preload("res://assets/boss/hourkeeper_idle.png");atlas.region=Rect2(0,0,96,128);portrait.texture=atlas
