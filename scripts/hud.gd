extends CanvasLayer
const Meter = preload("res://scripts/meter.gd")
signal start_requested
signal resume_requested
signal restart_requested
signal menu_requested
signal music_volume_changed(value: float)
signal sfx_volume_changed(value: float)
var root: Control
var overlay: Control
var flame_bar: Control
var flame_text: Label
var ability: Label
var objective: Label
var context: Label
var status: Label
var message: Label
var title: Label
var body: Label
var buttons: VBoxContainer
var freeze_wash: ColorRect
var danger_wash: ColorRect
var freeze_bar: Control
var message_timer: float = 0.0
var ui_clock: float = 0.0
var displayed_flame: float = 100.0
var overlay_tween: Tween
var music_slider: HSlider
var sfx_slider: HSlider

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	freeze_wash = panel(Rect2(0,0,1280,720),Color(0.12,0.65,0.9,0.07))
	danger_wash = panel(Rect2(0,0,1280,720),Color(0.65,0.03,0.08,0.07))
	panel(Rect2(24,20,1232,84),Color(0.025,0.035,0.08,0.94))
	panel(Rect2(24,20,3,84),Color("d4aa60"))
	label_at(Rect2(48,31,280,22),"THE LAST EMBER",14,Color("c7b88f"))
	flame_text = label_at(Rect2(220,30,110,26),"100 / 100",17,Color("ffe4a6"))
	flame_bar = Meter.new()
	flame_bar.position = Vector2(48,66)
	flame_bar.size = Vector2(280,15)
	flame_bar.show_percentage = false
	flame_bar.add_theme_font_size_override("font_size",1)
	flame_bar.add_theme_stylebox_override("background",style(Color("26233b")))
	flame_bar.add_theme_stylebox_override("fill",style(Color("efb45c")))
	root.add_child(flame_bar)
	ability = label_at(Rect2(365,34,320,58),"",17,Color("80d8e4"))
	objective = label_at(Rect2(720,32,505,63),"",18,Color("dce4eb"))
	panel(Rect2(24,606,1232,96),Color(0.025,0.035,0.08,0.94))
	context = label_at(Rect2(48,616,1180,26),"",18,Color("ffe4a6"))
	message = label_at(Rect2(48,647,1180,24),"",15,Color("9db6ca"))
	status = label_at(Rect2(48,679,1180,20),"",13,Color("8395b1"))
	freeze_bar = Meter.new()
	freeze_bar.position = Vector2(24,594)
	freeze_bar.size = Vector2(1232,5)
	freeze_bar.max_value = 3.0
	freeze_bar.show_percentage = false
	freeze_bar.add_theme_font_size_override("font_size",1)
	freeze_bar.add_theme_stylebox_override("background",style(Color("183344")))
	freeze_bar.add_theme_stylebox_override("fill",style(Color("77e4ee")))
	root.add_child(freeze_bar)
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(overlay)
	var dim := ColorRect.new()
	dim.color = Color(0.015,0.02,0.045,0.88)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)
	var card := Panel.new()
	card.position = Vector2(352,115)
	card.size = Vector2(576,490)
	var card_style := style(Color("10172b"))
	card_style.border_color = Color("756345")
	card_style.set_border_width_all(1)
	card.add_theme_stylebox_override("panel",card_style)
	overlay.add_child(card)
	title = Label.new()
	title.position = Vector2(388,145)
	title.size = Vector2(504,64)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size",32)
	title.add_theme_color_override("font_color",Color("f2d6a0"))
	overlay.add_child(title)
	body = Label.new()
	body.position = Vector2(398,215)
	body.size = Vector2(484,205)
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size",17)
	body.add_theme_color_override("font_color",Color("b4c5d7"))
	overlay.add_child(body)
	buttons = VBoxContainer.new()
	buttons.position = Vector2(438,438)
	buttons.size = Vector2(404,140)
	buttons.add_theme_constant_override("separation",8)
	overlay.add_child(buttons)
	add_audio_controls()

func add_audio_controls() -> void:
	for i in range(2):
		var label := Label.new()
		label.position = Vector2(380+i*282,625)
		label.text = "Music" if i == 0 else "SFX"
		label.add_theme_font_size_override("font_size",15)
		label.add_theme_color_override("font_color",Color("c5bea9"))
		overlay.add_child(label)
		var slider := HSlider.new()
		slider.position = Vector2(445+i*282,627)
		slider.size = Vector2(170,22)
		slider.min_value = 0
		slider.max_value = 1
		slider.step = 0.05
		slider.value = 0.65 if i == 0 else 0.75
		if i == 0:
			music_slider = slider
			slider.value_changed.connect(func(value: float): music_volume_changed.emit(value))
		else:
			sfx_slider = slider
			slider.value_changed.connect(func(value: float): sfx_volume_changed.emit(value))
		overlay.add_child(slider)

func style(color: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(0)
	box.border_color = Color("4a4c62")
	box.set_border_width_all(1)
	return box

func panel(rect: Rect2, color: Color) -> ColorRect:
	var item := ColorRect.new()
	item.position = rect.position
	item.size = rect.size
	item.color = color
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(item)
	return item

func label_at(rect: Rect2, words: String, size: int, color: Color) -> Label:
	var item := Label.new()
	item.position = rect.position
	item.size = rect.size
	item.text = words
	item.add_theme_font_size_override("font_size",size)
	item.add_theme_color_override("font_color",color)
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(item)
	return item

func make_button(words: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = words
	button.custom_minimum_size = Vector2(404,39)
	button.add_theme_font_size_override("font_size",17)
	button.add_theme_stylebox_override("normal",style(Color("28364a")))
	button.add_theme_stylebox_override("hover",style(Color("44536a")))
	button.add_theme_stylebox_override("focus",style(Color("3d4c62")))
	button.add_theme_stylebox_override("pressed",style(Color("597078")))
	button.pressed.connect(callback)
	buttons.add_child(button)
	if buttons.get_child_count() == 1:
		button.grab_focus()

func show_screen(kind: String, checkpoint_active: bool = false) -> void:
	overlay.show()
	if overlay_tween != null:
		overlay_tween.kill()
	overlay.modulate.a = 0.0
	overlay_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	overlay_tween.tween_property(overlay,"modulate:a",1.0,0.20)
	for child in buttons.get_children():
		buttons.remove_child(child)
		child.queue_free()
	match kind:
		"menu":
			title.text = "EMBERBOUND"
			body.text = "THE LAST HOUR   /   SHRINE TEST\n\nCarry the last ember into the Shrine of Lost Hours.\nBind the hunter in the Circle of Light.\n\nWASD / arrows  Move     E  Kindle lamps\nSpace  Freeze for 3s (15 flame)\nEsc  Pause     R  Restart checkpoint     M  Mute"
			make_button("Enter the shrine",func(): start_requested.emit())
		"pause":
			title.text = "TIME AT REST"
			body.text = "The ember and the hunter wait.\n\nLight both western lamps. Lead the shadow into the ring, then press Space and E by the eastern lamp.\n\nThe sanctuary restores your flame.\nR restarts the current checkpoint."
			make_button("Resume",func(): resume_requested.emit())
			make_button("Restart checkpoint",func(): restart_requested.emit())
			make_button("Title screen",func(): menu_requested.emit())
		"failure":
			title.text = "THE EMBER FADES"
			body.text = "Darkness has claimed this attempt.\n\n" + ("Your sanctuary checkpoint is safe." if checkpoint_active else "The forest entrance awaits.") + "\n\nRestart restores 100 flame and your saved progress.\nBorrowed Time spends 15 flame. Avoid wasting it."
			make_button("Try again from checkpoint",func(): restart_requested.emit())
			make_button("Title screen",func(): menu_requested.emit())
		"success":
			title.text = "THE SHADOW IS BOUND"
			body.text = "The Circle of Light holds.\nYour ember survives the Shrine of Lost Hours.\n\nSHRINE TEST COMPLETE\n\nThe full campaign continues into the Royal Hall. The Hourkeeper waits beyond."
			make_button("Play again from the beginning",func(): start_requested.emit())
			make_button("Title screen",func(): menu_requested.emit())

func hide_screen() -> void:
	overlay.hide()

func notify(words: String) -> void:
	message.text = words
	message_timer = 5.0

func refresh(game: Node, delta: float) -> void:
	message_timer = maxf(0,message_timer-delta)
	if message_timer <= 0.0:
		message.text = "Two flames. Lure within. Still time. Seal the third."
	ui_clock += delta
	if game.flow != game.Flow.PLAYING:
		displayed_flame = game.flame.value
	else:
		displayed_flame = lerpf(displayed_flame,game.flame.value,1.0-exp(-delta*14.0))
	flame_bar.value = displayed_flame
	flame_text.text = "%d / 100" % ceili(game.flame.value)
	var power: Node = game.time_power
	if power.freeze_remaining > 0.0:
		ability.text = "TIME HELD  %.1fs\n[Space]  15 flame / 8s cooldown" % power.freeze_remaining
	elif power.cooldown_remaining > 0.0:
		ability.text = "RECHARGING  %.1fs\n[Space]  15 flame / 8s cooldown" % power.cooldown_remaining
	elif game.flame.value < 15.0:
		ability.text = "NEED 15 FLAME\nReturn to sanctuary [E] / restart [R]"
	else:
		ability.text = "[Space]  BORROWED TIME\nReady / 3 seconds / costs 15 flame"
	var count: int = game.puzzle.lit_count()
	if game.puzzle.solved:
		objective.text = "CIRCLE SEALED  /  3 of 3\nFollow the gold light to the eastern exit."
	elif count < 2:
		objective.text = "CIRCLE OF LIGHT  /  %d of 3\nKindle the two western lamps [E]." % count
	else:
		objective.text = "CIRCLE OF LIGHT  /  2 of 3\nLure inside > Space > east lamp [E]."
	context.text = game.context_hint()
	var zone := "PROTECTED / slower drain" if game.world.is_protected(game.player.global_position) else "EXPOSED / flame fading"
	if game.corruption.contains(game.player.global_position):
		zone = "SHADOW RESIDUE / cosmetic"
	status.text = "SHADOW: %s    |    %s    |    Move: WASD/arrows   E: interact   Esc: pause/audio   R: retry   M: %s" % [game.shadow.state_label().to_upper(),zone,"unmute" if game.audio.muted else "mute"]
	freeze_wash.visible = power.freeze_remaining > 0.0
	freeze_bar.visible = power.freeze_remaining > 0.0
	freeze_bar.value = power.freeze_remaining
	danger_wash.visible = game.flame.value < 25.0 and not game.puzzle.solved
	danger_wash.color.a = 0.025+(0.5+0.5*sin(ui_clock*4))*0.03
	flame_text.modulate = Color("ff9b88") if game.flame.value < 25.0 else Color.WHITE
