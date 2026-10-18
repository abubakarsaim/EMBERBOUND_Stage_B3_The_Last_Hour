extends CanvasLayer
## Screen-edge threat and a gentle start fade. HUD remains crisp on a higher layer.
var material_fx: ShaderMaterial
var controller: Node
var clock: float = 0.0
var transition: float = 0.0
var threat: float = 0.0

func _ready() -> void:
	layer = 2
	process_mode = Node.PROCESS_MODE_ALWAYS
	var rect := ColorRect.new()
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	material_fx = ShaderMaterial.new()
	material_fx.shader = preload("res://assets/atmosphere.gdshader")
	rect.material = material_fx
	add_child(rect)

func start_fade() -> void:
	transition = 0.7

func _process(delta: float) -> void:
	if controller == null or material_fx == null:
		return
	if controller.flow == controller.Flow.PLAYING:
		clock += delta
		transition = maxf(0,transition-delta*2)
	var point: Vector2 = controller.player.get_global_transform_with_canvas().origin
	var size := get_viewport().get_visible_rect().size
	var distance: float = controller.player.global_position.distance_to(controller.shadow.global_position)
	var desired: float = clampf(1.0-distance/300.0,0,1)*(1.0-controller.flame.value/150.0)
	if controller.puzzle.solved or controller.time_power.freeze_remaining > 0:
		desired = 0
	threat = move_toward(threat,desired,delta*1.5)
	material_fx.set_shader_parameter("ember_uv",point/size)
	material_fx.set_shader_parameter("ember_radius",controller.player.torch_radius)
	material_fx.set_shader_parameter("weakness",1-controller.flame.value/100.0)
	material_fx.set_shader_parameter("threat",threat)
	material_fx.set_shader_parameter("beat",0.5+sin(clock*4.5)*0.5)
	material_fx.set_shader_parameter("freeze",minf(1,controller.time_power.freeze_remaining))
	material_fx.set_shader_parameter("transition",transition)
