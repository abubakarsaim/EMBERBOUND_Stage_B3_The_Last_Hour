extends CanvasLayer
signal advanced
signal skipped
var box: Panel
var portrait: TextureRect
var speaker: Label
var words: Label
var counter: Label
var continue_button: Button
var lines: Array = []
var index: int = 0
var active: bool = false
var kind: String = ""
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 15
	box = Panel.new()
	box.position = Vector2(80,442)
	box.size = Vector2(1120,150)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("10192b")
	style.border_color = Color("aa8e5f")
	style.set_border_width_all(2)
	box.add_theme_stylebox_override("panel",style)
	add_child(box)
	portrait = TextureRect.new()
	portrait.position = Vector2(22,12)
	portrait.size = Vector2(80,120)
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	box.add_child(portrait)
	speaker = label(Vector2(126,12),Vector2(830,24),18,Color("edd095"))
	words = label(Vector2(126,41),Vector2(940,64),21,Color("e1e6e9"))
	words.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	counter = label(Vector2(126,117),Vector2(720,20),14,Color("8fa8bc"))
	continue_button = Button.new()
	continue_button.position = Vector2(928,110)
	continue_button.size = Vector2(170,30)
	continue_button.text = "Continue [E]"
	continue_button.focus_mode = Control.FOCUS_NONE
	continue_button.pressed.connect(func(): advanced.emit())
	box.add_child(continue_button)
	box.hide()
func label(at: Vector2, dimensions: Vector2, font_size: int, col: Color) -> Label:
	var item := Label.new()
	item.position = at
	item.size = dimensions
	item.add_theme_font_size_override("font_size",font_size)
	item.add_theme_color_override("font_color",col)
	box.add_child(item)
	return item
func begin(script_lines: Array, category: String) -> void:
	lines = script_lines
	kind = category
	index = 0
	active = true
	box.show()
	refresh()
	get_viewport().gui_release_focus()
func refresh() -> void:
	if not active: return
	speaker.text = lines[index][0]
	words.text = lines[index][1]
	counter.text = "%d / %d   •   E / Enter continue   •   Q skip" % [index+1,lines.size()]
	if kind=="arrival": counter.text += "   •   T replay arrival"
	var tex: Texture2D
	var region := Rect2(0,0,40,56)
	if speaker.text=="KNIGHT":
		tex = preload("res://scripts/pixel_art.gd").knight_frame(0,0)
		region = Rect2(0,0,40,48)
	elif speaker.text=="FALSE PRINCESS":
		tex = preload("res://assets/royal/false_princess_idle.png")
		region = Rect2(0,0,64,80)
	else: tex = preload("res://assets/royal/princess_idle.png")
	var atlas := AtlasTexture.new()
	atlas.atlas = tex
	atlas.region = region
	portrait.texture = atlas
func next() -> bool:
	index += 1
	if index>=lines.size():
		close()
		return true
	refresh()
	return false
func close() -> void:
	active = false
	box.hide()
	continue_button.release_focus()
