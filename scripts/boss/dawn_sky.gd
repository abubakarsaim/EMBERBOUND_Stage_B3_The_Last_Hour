extends CanvasLayer
## Code-native pixel city seen through the castle window, composed at reference size.
var progress: float=0
var canvas: Node2D
func _ready() -> void:
	layer=7
	canvas=Node2D.new();canvas.set_script(preload("res://scripts/boss/dawn_sky_draw.gd"));canvas.owner_layer=self;add_child(canvas)
func _process(_delta: float) -> void:
	canvas.queue_redraw()
