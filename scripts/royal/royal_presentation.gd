extends "res://scripts/presentation.gd"
func _process(delta: float) -> void:
	if controller == null or material_fx == null:
		return
	if controller.flow == controller.Flow.PLAYING:
		clock += delta
		transition = maxf(0,transition-delta*2)
	var point: Vector2 = controller.player.get_global_transform_with_canvas().origin
	var size := get_viewport().get_visible_rect().size
	var enemy: Vector2 = controller.princess.global_position if controller.encounter.active else controller.shadow.global_position
	var distance: float = controller.player.global_position.distance_to(enemy)
	var desired: float = clampf(1.0-distance/300.0,0,1)*(1.0-controller.flame.value/150.0)
	if controller.puzzle.solved or controller.time_power.freeze_remaining > 0 or controller.cinematic_mode!="" or controller.read_grace>0 or controller.world.is_protected(controller.player.global_position):
		desired = 0
	threat = move_toward(threat,desired,delta*1.5)
	material_fx.set_shader_parameter("ember_uv",point/size)
	material_fx.set_shader_parameter("ember_radius",controller.player.torch_radius)
	material_fx.set_shader_parameter("weakness",1-controller.flame.value/100.0)
	material_fx.set_shader_parameter("threat",threat)
	material_fx.set_shader_parameter("beat",0.5+sin(clock*4.5)*0.5)
	material_fx.set_shader_parameter("freeze",minf(1,controller.time_power.freeze_remaining))
	material_fx.set_shader_parameter("transition",transition)
