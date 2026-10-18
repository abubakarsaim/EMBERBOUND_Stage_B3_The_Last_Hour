extends "res://scripts/hud.gd"
var progress_label: Label
var detail_label: Label
var way_label: Label
var mission_back: ColorRect
var channel_bar: Control
var cinema: Label
var skip_label: Label
func _ready() -> void:
	super._ready()
	mission_back=panel(Rect2(24,116,370,121),Color(0.025,0.04,0.08,0.92))
	progress_label=label_at(Rect2(40,126,340,28),"",17,Color("edcf95"))
	detail_label=label_at(Rect2(40,158,340,24),"",14,Color("a6c9d5"))
	way_label=label_at(Rect2(40,192,340,38),"",14,Color("c2c2b2"))
	channel_bar=Meter.new();channel_bar.position=Vector2(720,98);channel_bar.size=Vector2(505,5);channel_bar.max_value=1;channel_bar.show_percentage=false
	channel_bar.add_theme_stylebox_override("background",style(Color("28233c")));channel_bar.add_theme_stylebox_override("fill",style(Color("f5ce83")));root.add_child(channel_bar)
	context.add_theme_font_size_override("font_size",16);message.add_theme_font_size_override("font_size",14)
	cinema=Label.new();cinema.position=Vector2(130,616);cinema.size=Vector2(1020,76);cinema.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;cinema.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	cinema.add_theme_font_size_override("font_size",22);cinema.add_theme_color_override("font_color",Color("fff0ce"));cinema.add_theme_color_override("font_shadow_color",Color("121a2c"));cinema.add_theme_constant_override("shadow_offset_x",2);cinema.add_theme_constant_override("shadow_offset_y",2);add_child(cinema);cinema.hide()
	skip_label=Label.new();skip_label.position=Vector2(1070,24);skip_label.text="Q skip / Esc pause";skip_label.add_theme_font_size_override("font_size",14);add_child(skip_label);skip_label.hide()
func show_screen(kind: String,saved: bool=false) -> void:
	super.show_screen(kind,saved)
	match kind:
		"menu":title.text="THE LAST HOUR";body.text="THE HOURKEEPER'S CHAMBER\n\nBreak the two anchors. Expose his clock core.\nRescue the princess. Restore the dawn.\n\nWASD/arrows: move   E: channel\nSpace: Borrowed Time   Q: skip dialogue"
		"pause":body.text="Time and the ember wait.\n\nAnchors open after an attack's recovery.\nE starts a short channel; movement interrupts.\nFreeze the clock barrier at GOLD alignment.\nOne core strike per Time opening.\n\nTwo fire sources: +30 flame / 16s recharge.\nR retries your latest mission checkpoint."
		"failure":body.text="The last hour has taken this attempt.\nYour completed anchors and core strikes remain.\n\nRetry restores 100 flame, ready fire sources, and the correct boss phase.\n\nDodge the warning, then act during recovery."
		"success":
			title.text="EMBERBOUND";title.add_theme_font_size_override("font_size",42)
			body.add_theme_font_size_override("font_size",16)
			body.text="THE LAST HOUR\n\nThe dawn remembers those who carried its light.\n\nEMBERBOUND team · Built with Godot\nOriginal prototype art / music / sound\nAI-assisted development · Thank you for playing."
			buttons.get_child(0).text="Carry the light again"
func refresh(game: Node,delta: float) -> void:
	super.refresh(game,delta)
	if progress_label==null:return
	var p: Node=game.puzzle
	mission_back.visible=game.flow==game.Flow.PLAYING and game.cinematic_mode==""
	for item in [progress_label,detail_label,way_label]:item.visible=mission_back.visible
	channel_bar.visible=p.channel_kind!="" and mission_back.visible
	channel_bar.value=p.channel_time/maxf(0.01,p.channel_duration)
	var goal:=Vector2.ZERO
	if p.phase==p.Phase.ANCHORS:
		objective.text="01  BREAK THE TIME PRISON\nDisable both anchors to weaken her prison."
		progress_label.text="CHRONO ANCHORS / %d of 2" % p.lit_count()
		detail_label.text="EXPOSED / %.0fs / E channels flame" % ceilf(p.exposed_remaining) if p.exposed_remaining>0 else "Shielded / Dodge an attack; then channel"
		goal=game.world.ANCHORS[1] if p.anchors[0] else game.world.ANCHORS[0]
	elif p.phase==p.Phase.CORE:
		objective.text="02  DEFEAT THE HOURKEEPER\nFreeze at GOLD alignment; channel the core."
		progress_label.text="CLOCK CORE / %d of 2 STRIKES" % p.strikes
		detail_label.text="CORE EXPOSED / E channels flame" if p.opening else ("GOLD ALIGNMENT / Use Space" if p.aligned else "Wait for hand + royal symbol to align")
		goal=p.core_point(game.boss)
	elif p.phase==p.Phase.RESCUE:
		objective.text="03  RESCUE THE PRINCESS\nUse the royal sigil at her prison [E].";progress_label.text="THE HOURKEEPER IS DEFEATED";detail_label.text="The prison's royal lock remains.";goal=game.world.PRISON+Vector2(0,85)
	else:
		objective.text="04  RESTORE THE DAWN\nReturn the last flame to the Eternal Clock."
		progress_label.text="THE REAL PRINCESS IS FREE";detail_label.text="The clock waits for the last ember.";goal=game.world.PEDESTAL
	var offset: Vector2=goal-game.player.global_position
	var bearing: String="Within reach [E]" if offset.length()<120 else ["EAST","SOUTHEAST","SOUTH","SOUTHWEST","WEST","NORTHWEST","NORTH","NORTHEAST"][posmod(roundi(offset.angle()/(PI/4)),8)]
	way_label.text=bearing+" / "+str(roundi(offset.length()))+" px\nFire sources: WEST and EAST / gold markers"
	if game.cinematic_mode!="":objective.text=objective.text.split("\n")[0]+"\nE / Enter continues · Q skips"
	if p.phase>=p.Phase.RESCUE:ability.text="THE FLAME ENDURES\nNo more borrowed hours are needed."
	status.text="HOURKEEPER: %s | WASD/arrows: move  E: channel  Space: Time  Esc: pause  R: retry  M: mute" % game.patterns.state_label().to_upper()
	if game.slow_remaining>0:status.text="TIME DRAG / %.1fs / Movement 68%% · Controls remain active" % game.slow_remaining
	if message_timer<=0:
		message.text="Your flame weakens the prison's chains. Attacks expose the anchors; their light shields a channel." if p.phase==p.Phase.ANCHORS else ("The chest core is protected by the rotating hand. Freeze GOLD alignment, approach, then E." if p.phase==p.Phase.CORE else "Her royal sigil is the key. The last ember is the dawn.")
