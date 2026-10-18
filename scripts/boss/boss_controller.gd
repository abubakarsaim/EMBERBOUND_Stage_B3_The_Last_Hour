extends "res://scripts/game_controller.gd"
const ARRIVAL := [["HOURKEEPER","One last ember. One last hour. Neither shall leave this chamber."],["PRINCESS","The two anchors hold my prison. Break their light when his attacks fall silent."],["KNIGHT","Then your last hour ends here."]]
const RESCUE := [["PRINCESS","You found me..."],["KNIGHT","The Hourkeeper is gone. It's over."],["PRINCESS","Not yet. Listen... Time is still broken. The flame must reach the heart of the clock."],["KNIGHT","Then there is one last thing I must do."]]
const OFFERING := [["PRINCESS","The ember has kept your heart warm through all this darkness. Return it, and the dawn will take your last strength."],["KNIGHT","Then let it be morning. Remember me in the light."]]
var cinematic_mode: String=""
var cinematic_time: float=0
var intro_seen: bool=false
var camera_from:=Vector2.ZERO
var camera_zoom_from: float=1
var read_grace: float=4
var slow_remaining: float=0
var clock_angle: float=0
var elapsed: float=0
var ending_time: float=0
var dawn_amount: float=0
var last_aligned: bool=false
var trail_timer: float=0
var step_timer: float=0
var last_stamp:=Vector2.INF
@onready var boss: Node2D=$World/Hourkeeper
@onready var patterns: Node2D=$World/Patterns
@onready var princess: Node2D=$World/RealPrincess
@onready var dialogue: CanvasLayer=$Dialogue
@onready var intro_camera: Camera2D=$World/CinematicCamera
@onready var sky: CanvasLayer=$DawnSky
func _ready() -> void:
	super._ready()
	var incoming: bool=Journey.arriving_boss
	Journey.arriving_boss=false
	if not incoming:Journey.royal_solved=true # Independent boss testing includes the earned sigil.
	Journey.apply_audio(audio);hud.music_slider.value=audio.music_volume;hud.sfx_slider.value=audio.sfx_volume
	world.controller=self;effects.controller=self
	corruption.walk_bounds=world.BOUNDS;corruption.sacred_test=world.is_protected
	princess.knight=player
	puzzle.anchor_disabled.connect(on_anchor_disabled)
	puzzle.core_struck.connect(on_core_struck)
	puzzle.mission_changed.connect(on_mission_changed)
	puzzle.channel_cancelled.connect(func(reason: String):hud.notify(reason))
	puzzle.anchors_exposed.connect(func():
		audio.play_cue("core_expose");hud.notify("Chrono Anchors exposed for 12 seconds! E channels your flame; stand still to finish.");effects.wave(world.BOSS,Color("87e5e8"),570))
	patterns.released.connect(func(_kind: int):boss.release_remaining=0.32;effects.burst(boss.global_position-Vector2(0,135),Color("9b6fa5"),12))
	patterns.warning.connect(on_attack_warning)
	patterns.flare_requested.connect(on_flare_fired)
	patterns.damage_requested.connect(damage_flame)
	patterns.slow_requested.connect(on_distorted)
	patterns.recovery_started.connect(func():audio.cancel_charge();puzzle.expose_anchors())
	dialogue.advanced.connect(advance_dialogue);dialogue.skipped.connect(skip_scene)
	var camera: Camera2D=player.get_node("Camera2D");camera.limit_right=2560;camera.limit_bottom=2048;camera.offset=Vector2(0,-180)
	restore_run(false)
	if incoming:flame.reset(maxf(60,Journey.carried_flame));player.flame_strength=flame.value
func start_new_game() -> void:
	if Journey.campaign:
		Journey.begin_forest=true;return_to_title();return
	puzzle.reset();intro_seen=false;Journey.completed=false;restore_run(false)
func restore_run(_at_checkpoint: bool) -> void:
	puzzle.clear_temporary()
	get_tree().paused=false;flow=Flow.PLAYING
	projectiles.clear();audio.reset_transients();corruption.clear();effects.clear();dialogue.close()
	cinematic_mode="";cinematic_time=0;read_grace=4;slow_remaining=0;ending_time=0;dawn_amount=0;sky.progress=0
	last_aligned=false;trail_timer=0;last_stamp=Vector2.INF;low_warning_remaining=0;step_timer=0
	flame.reset();time_power.reset();player.flame_strength=100;player.speed=220;player.active=true;player.invulnerable=1.5
	player.offering=0;player.flame_returned=false;player.fallen=false
	player.global_position=puzzle.checkpoint_position();player.velocity=Vector2.ZERO;player.reset_visuals()
	boss.reset_actor();boss.defeated=puzzle.solved;boss.visible=not puzzle.solved
	shadow.active=false;shadow.visible=false
	patterns.reset(not puzzle.solved,1 if puzzle.phase==puzzle.Phase.CORE else 0)
	princess.global_position=world.PRISON;princess.freed=puzzle.freed;princess.release_progress=1 if puzzle.freed else 0
	princess.approaching=puzzle.freed;princess.kneeling=false
	if puzzle.freed:princess.global_position=player.global_position+Vector2(83,-12)
	princess.reset_physics_interpolation()
	world.prison_shape.set_deferred("disabled",puzzle.freed)
	corruption.modulate.a=1
	checkpoint_active=true;checkpoint_solved=puzzle.phase!=puzzle.Phase.ANCHORS
	intro_camera.enabled=false
	var camera: Camera2D=player.get_node("Camera2D");camera.enabled=true;camera.zoom=Vector2.ONE;camera.offset=Vector2(0,-180);camera.make_current();camera.reset_smoothing();camera.force_update_scroll()
	audio.chapter_phase=puzzle.phase;audio.quiet=false;audio.set_flow("playing")
	hud.root.show();hud.cinema.hide();hud.skip_label.hide();hud.hide_screen();presentation.start_fade()
	if not intro_seen and puzzle.phase==puzzle.Phase.ANCHORS:begin_intro()
	else:hud.notify("Checkpoint restored. Disabled anchors, core strikes and rescue progress are remembered. Fire sources are ready.")
func restart_checkpoint() -> void:restore_run(true)
func begin_intro() -> void:
	if flow not in [Flow.PLAYING,Flow.PAUSED] or puzzle.phase!=puzzle.Phase.ANCHORS:return
	get_tree().paused=false;flow=Flow.PLAYING;hud.hide_screen();dialogue.close()
	player.active=false;player.velocity=Vector2.ZERO;projectiles.clear(false);audio.cancel_charge();audio.quiet=true
	cinematic_mode="intro_pan";cinematic_time=0;camera_from=player.global_position+Vector2(0,-180)
	intro_camera.enabled=true;intro_camera.global_position=camera_from;intro_camera.zoom=Vector2.ONE;intro_camera.make_current()
func begin_conversation(lines: Array,kind: String) -> void:
	cinematic_mode=kind;cinematic_time=0;player.active=false;player.velocity=Vector2.ZERO;projectiles.clear(false);audio.cancel_charge();audio.quiet=true
	dialogue.begin(lines,kind);audio.play_cue("dialogue")
func advance_dialogue() -> void:
	if flow!=Flow.PLAYING or not dialogue.active:return
	audio.play_cue("dialogue")
	if dialogue.next():end_dialogue()
func end_dialogue() -> void:
	if cinematic_mode in ["arrival","intro_pan"]:
		cinematic_mode="return";cinematic_time=0;camera_from=intro_camera.global_position;camera_zoom_from=intro_camera.zoom.x
	else:
		cinematic_mode="";player.active=true;audio.quiet=false;read_grace=4
		if puzzle.freed:princess.approaching=true
		hud.notify("The princess is free. Approach the central pedestal. E reads the offering; E again returns the flame.") if puzzle.phase==puzzle.Phase.DAWN else hud.notify("Follow the current mission. The two ancient fires offer +30 flame and safe recovery.")
func skip_scene() -> void:
	if cinematic_mode=="ending":finish_ending();return
	if dialogue.active or cinematic_mode=="intro_pan":dialogue.close();end_dialogue()
func advance_cinematic(delta: float) -> void:
	cinematic_time+=delta
	if cinematic_mode=="intro_pan":
		var t:=clampf(cinematic_time/1.45,0,1);t=t*t*(3-2*t)
		intro_camera.global_position=camera_from.lerp(Vector2(1280,760),t);intro_camera.zoom=Vector2.ONE*lerpf(1,0.68,t)
		if cinematic_time>=1.45:cinematic_mode="arrival";dialogue.begin(ARRIVAL,"arrival");audio.play_cue("dialogue")
	elif cinematic_mode=="return":
		var t:=clampf(cinematic_time/0.6,0,1);t=t*t*(3-2*t)
		intro_camera.global_position=camera_from.lerp(player.global_position+Vector2(0,-180),t);intro_camera.zoom=Vector2.ONE*lerpf(camera_zoom_from,1,t)
		if cinematic_time>=0.6:
			intro_camera.enabled=false;player.get_node("Camera2D").make_current();player.get_node("Camera2D").reset_smoothing()
			cinematic_mode="";intro_seen=true;player.active=true;audio.quiet=false;read_grace=4
			hud.notify("Break the time prison: dodge an attack, then channel each exposed anchor [E]. Fire sources restore +30 flame.")
	elif cinematic_mode=="defeat":
		boss.defeat_progress=clampf(cinematic_time/2.4,0,1);boss.tick(delta)
		if cinematic_time>=2.4:boss.visible=false;cinematic_mode="";player.active=true;hud.notify("His power is broken. The prison's royal lock remains. Approach the princess NORTH and use your sigil [E].")
	elif cinematic_mode=="release":
		princess.release_progress=clampf(cinematic_time/1.4,0,1);princess.tick(delta)
		if cinematic_time>=1.4:
			princess.freed=true;puzzle.mark_freed();world.prison_shape.set_deferred("disabled",true);begin_conversation(RESCUE,"rescue")
	elif cinematic_mode=="ending":advance_ending(delta)
func _physics_process(delta: float) -> void:
	if flow!=Flow.PLAYING:return
	if cinematic_mode!="":advance_cinematic(delta);return
	elapsed+=delta;read_grace=maxf(0,read_grace-delta)
	var frozen_before: bool=time_power.freeze_remaining>0;time_power.tick(delta)
	if frozen_before and time_power.freeze_remaining<=0:audio.play_cue("time_end")
	slow_remaining=maxf(0,slow_remaining-delta);player.speed=220*(0.68 if slow_remaining>0 else 1.0)
	var protected: bool=world.is_protected(player.global_position) or read_grace>0
	if puzzle.phase<puzzle.Phase.RESCUE:flame.tick(delta,protected)
	if flow!=Flow.PLAYING:return
	player.flame_strength=flame.value
	boss.charging=patterns.state==patterns.State.WINDUP;boss.moving=not puzzle.solved;boss.tick(delta);princess.tick(delta)
	puzzle.tick(delta,player,boss,time_power)
	if cinematic_mode!="" or flow!=Flow.PLAYING:return
	if puzzle.phase==puzzle.Phase.CORE and puzzle.aligned and not last_aligned:audio.play_cue("core_expose")
	last_aligned=puzzle.aligned
	patterns.tick(delta,boss,player,projectiles,time_power,protected,puzzle.channel_kind!="" or read_grace>0 or boss.stagger>0)
	projectiles.tick(delta,time_power.freeze_remaining>0,player,protected)
	if flow!=Flow.PLAYING:return
	corruption.tick(delta)
	trail_timer-=delta
	if not puzzle.solved and time_power.freeze_remaining<=0 and trail_timer<=0 and boss.global_position.distance_to(last_stamp)>9:
		corruption.stamp(boss.global_position);last_stamp=boss.global_position;trail_timer=0.16
	if puzzle.phase==puzzle.Phase.ANCHORS:clock_angle-=delta*0.3
	elif puzzle.phase==puzzle.Phase.CORE:clock_angle+=sin(elapsed*2.3)*delta*0.8
	low_warning_remaining=maxf(0,low_warning_remaining-delta)
	if flame.value<25 and puzzle.phase<puzzle.Phase.RESCUE and low_warning_remaining<=0:audio.play_cue("low_flame");low_warning_remaining=8
	step_timer=maxf(0,step_timer-delta)
	if player.velocity.length()>60 and step_timer<=0:audio.play_cue("step");step_timer=0.4
func _process(delta: float) -> void:
	super._process(delta)
	if not is_instance_valid(boss):return
	dialogue.box.visible=dialogue.active and flow==Flow.PLAYING
	audio.chapter_phase=puzzle.phase
	audio.set_context(0.9 if puzzle.phase==puzzle.Phase.CORE else 0.3,1 if world.is_protected(player.global_position) else 0.15,time_power.freeze_remaining>0)
func interact() -> void:
	if cinematic_mode!="" or flow!=Flow.PLAYING:return
	var at: Vector2=player.global_position
	for i in range(2):
		if at.distance_to(world.FONTS[i])<115:
			var before: float=flame.value;hud.notify(puzzle.use_font(i,flame))
			if flame.value>before:audio.play_cue("lamp");effects.wave(world.FONTS[i],Color("ffdb93"),120)
			return
	if at.distance_to(world.PRISON)<120:
		if puzzle.phase==puzzle.Phase.RESCUE:
			if not Journey.royal_solved:hud.notify("The royal sigil is missing. Return to the title and complete the Royal Hall.");return
			cinematic_mode="release";cinematic_time=0;player.active=false;player.velocity=Vector2.ZERO;audio.play_cue("prison_open");effects.wave(world.PRISON,Color("ffe1a0"),200)
		elif puzzle.phase<puzzle.Phase.RESCUE:hud.notify("The prison still draws power from the Hourkeeper. Break both anchors, then shatter his clock core.");audio.play_cue("clock_lock")
		else:hud.notify("She is free, but dawn has not returned. Carry the last flame to the central pedestal.")
		return
	if puzzle.phase==puzzle.Phase.ANCHORS:
		for i in range(2):
			if at.distance_to(world.ANCHORS[i])<115:hud.notify(puzzle.start_anchor(i,at));return
	elif puzzle.phase==puzzle.Phase.CORE:
		if at.distance_to(puzzle.core_point(boss))<200:hud.notify(puzzle.start_core(at,boss,time_power));return
	elif puzzle.phase==puzzle.Phase.DAWN and at.distance_to(world.PEDESTAL)<110:
		if not puzzle.offering_ready:puzzle.offering_ready=true;begin_conversation(OFFERING,"offering")
		else:begin_ending()
		return
	hud.notify(context_hint())
func on_attack_warning(kind: int) -> void:
	if kind==patterns.Kind.FLARE:audio.play_cue("charge");hud.notify("SHADOW FLARE / Red mark locks your position. Sidestep before the flare arrives.")
	elif kind==patterns.Kind.SWEEP:audio.play_cue("clock_sweep");hud.notify("CLOCK-HAND SWEEP / Leave the red warning sector, step close to the hub, or retreat beyond its arc.")
	else:audio.play_cue("time_pulse");hud.notify("TIME DISTORTION / Move outside the cyan circle. A hit slows movement briefly; it never removes control.")
func damage_flame(amount: float) -> void:
	if flow!=Flow.PLAYING or cinematic_mode!="" or read_grace>0 or world.is_protected(player.global_position) or player.invulnerable>0:return
	player.invulnerable=1.15;player.hurt_feedback();puzzle.cancel_channel("Impact interrupted the channel. Recover at a fire source.")
	flame.spend(minf(amount,flame.value));player.flame_strength=flame.value;audio.play_cue("impact")
	effects.burst(player.torch_position(),Color("b34268"),18);effects.announce(player.global_position,"-%d FLAME" % amount,Color("ef95a2"))
func on_flare_hit(amount: float,_at: Vector2) -> void:damage_flame(amount)
func on_shadow_struck() -> void:pass
func on_distorted(duration: float) -> void:
	if world.is_protected(player.global_position) or read_grace>0:return
	slow_remaining=maxf(slow_remaining,duration);effects.wave(player.global_position,Color("85e5ee"),90);hud.notify("TIME DRAG / Movement slowed to 68% for 1.6 seconds. Controls remain active.")
func on_anchor_disabled(index: int) -> void:
	audio.play_cue("anchor_break");effects.burst(world.ANCHORS[index]-Vector2(0,40),Color("ffc987"),35);effects.wave(world.ANCHORS[index],Color("ffe0a1"),180)
	hud.notify("Chrono Anchor %s disabled. Its chain fades; the princess's prison weakens. Progress saved." % ["I","II"][index])
func on_mission_changed() -> void:
	read_grace=4;projectiles.clear(false);puzzle.idle_time=0;checkpoint_solved=true
	if puzzle.phase==puzzle.Phase.CORE:
		flame.restore(25);boss.stagger=1.4;patterns.reset(true,1);audio.play_cue("core_expose")
		hud.notify("BARRIER BROKEN / Checkpoint. Freeze the moving clock hand when it meets the GOLD royal symbol, then E at the exposed core.")
	elif puzzle.phase==puzzle.Phase.DAWN:hud.notify("RESCUE COMPLETE / Return the last flame to the central pedestal. Dawn still waits.")
func on_core_struck(count: int) -> void:
	projectiles.clear(false);audio.cancel_charge();audio.play_cue("core_hit");boss.stagger=1.4;read_grace=4;patterns.recover(3)
	effects.burst(boss.global_position-Vector2(0,140),Color("fff0bd"),50);effects.wave(boss.global_position,Color("85e8ea"),240)
	if count<2:hud.notify("CLOCK CORE / 1 of 2. Progress saved. Recharge Time; freeze another gold alignment for the final strike.")
func on_puzzle_completed() -> void:
	patterns.active=false;projectiles.clear(false);audio.cancel_charge();puzzle.cancel_channel("");corruption.clear();boss.defeated=true
	cinematic_mode="defeat";cinematic_time=0;player.active=false;player.velocity=Vector2.ZERO;slow_remaining=0;player.speed=220;audio.play_cue("boss_fall")
	effects.burst(boss.global_position-Vector2(0,130),Color("ebc7a0"),90);effects.wave(boss.global_position,Color("9be3e8"),650)
func on_time_activated() -> void:
	super.on_time_activated();puzzle.register_freeze(boss)
	if puzzle.phase==puzzle.Phase.CORE:
		hud.notify("CORE EXPOSED / Move into the focus and E. One flame strike per opening." if puzzle.opening else "The barrier is held away from the symbol. Restore flame if needed, then wait for gold alignment.")
func begin_ending() -> void:
	puzzle.phase=puzzle.Phase.ENDING;cinematic_mode="ending";cinematic_time=0;ending_time=0
	player.active=false;player.velocity=Vector2.ZERO;player.offering=0.01;patterns.active=false;projectiles.clear(false);time_power.reset();audio.quiet=false;audio.play_cue("flame_return")
	hud.root.hide();hud.cinema.show();hud.skip_label.show()
	intro_camera.enabled=true;intro_camera.global_position=player.global_position+Vector2(0,-180);intro_camera.zoom=Vector2.ONE;intro_camera.make_current()
func advance_ending(delta: float) -> void:
	ending_time+=delta
	player.offering=clampf(ending_time/1.5,0,1)
	if ending_time>=2 and not player.flame_returned:
		player.flame_returned=true;flame.reset(0);player.flame_strength=0;audio.play_cue("clock_awaken");effects.wave(world.PEDESTAL,Color("ffdf9b"),900)
	if ending_time>=2:clock_angle+=delta*0.65
	dawn_amount=clampf((ending_time-2)/7,0,1);corruption.modulate.a=1-dawn_amount
	if ending_time>=2:princess.approaching=true
	if ending_time>=4.5:player.fallen=true
	princess.tick(delta)
	var t:=clampf((ending_time-6.5)/5,0,1);t=t*t*(3-2*t)
	intro_camera.global_position=(player.global_position+Vector2(0,-180)).lerp(Vector2(1880,540),t)
	intro_camera.zoom=Vector2.ONE*lerpf(1,0.8,t)
	sky.progress=clampf((ending_time-9)/3.5,0,1)
	hud.cinema.text="The last ember returns to the heart of the clock." if ending_time<4.5 else ("With his last breath, the clock found its first morning." if ending_time<9 else "The dawn remembers those who carried its light.")
	if ending_time>=12.5:finish_ending()
func finish_ending() -> void:
	puzzle.phase=puzzle.Phase.COMPLETE;Journey.completed=true;Journey.next_chapter="dawn_restored"
	cinematic_mode="";sky.progress=1;dawn_amount=1;player.flame_returned=true;player.fallen=true;player.offering=1;flame.reset(0);player.flame_strength=0
	princess.freed=true;princess.approaching=false;princess.kneeling=true;princess.global_position=player.global_position+Vector2(83,-12)
	patterns.active=false;projectiles.clear(false);hud.cinema.hide();hud.skip_label.hide();hud.root.show()
	flow=Flow.SUCCESS;audio.chapter_phase=puzzle.phase;audio.set_flow("success");get_tree().paused=true;hud.show_screen("success")
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo:return
	if event.is_action_pressed("skip_scene") and flow==Flow.PLAYING:skip_scene();return
	if event.is_action_pressed("replay_intro"):
		if puzzle.phase==puzzle.Phase.ANCHORS:begin_intro()
		else:hud.notify("This phase checkpoint is saved. R retries it; a new boss run replays the arrival.")
		return
	if flow==Flow.PLAYING and cinematic_mode!="":
		if event.is_action_pressed("interact") or event.is_action_pressed("confirm"):
			if dialogue.active:advance_dialogue()
		elif event.is_action_pressed("pause") or event.is_action_pressed("restart") or event.is_action_pressed("mute"):super._unhandled_input(event)
		return
	if flow==Flow.PLAYING and event.is_action_pressed("borrow_time"):
		if puzzle.phase>=puzzle.Phase.RESCUE:hud.notify("The Hourkeeper is gone. Keep the ember for the clock; no more borrowed hours are needed.")
		else:
			var result: String=time_power.try_activate(flame)
			if not result.begins_with("Time stands"):hud.notify(result)
		return
	super._unhandled_input(event)
func return_to_title() -> void:
	Journey.remember(audio);get_tree().paused=false;get_tree().change_scene_to_file("res://scenes/forest.tscn")
func context_hint() -> String:
	if cinematic_mode!="":return "[E / Enter] Continue   •   [Q] Skip   •   [Esc] Pause / read safely"
	if puzzle.channel_kind!="":return "CHANNELING / Stand still until the gold bar fills. Movement cancels without an extra flame cost."
	var at: Vector2=player.global_position
	for i in range(2):
		if at.distance_to(world.FONTS[i])<115:return "[E] Ancient fire / +30 flame"+(" / Ready" if puzzle.font_cooldowns[i]<=0 else " / Recharges in %.0fs" % ceilf(puzzle.font_cooldowns[i]))
	if puzzle.phase==puzzle.Phase.ANCHORS:
		for i in range(2):
			if at.distance_to(world.ANCHORS[i])<115:
				if puzzle.anchors[i]:return "ANCHOR DISABLED / Its chain is broken. Reach the other anchor."
				return "[E] CHANNEL FLAME INTO THE EXPOSED ANCHOR / Stand still 1.2s" if puzzle.exposed_remaining>0 else "Anchor shielded. Dodge an attack; its recovery opens a 12-second channel opportunity."
		return "Disable both Chrono Anchors to weaken her prison. Gold fire sources provide refuge and recovery."
	if puzzle.phase==puzzle.Phase.CORE:
		if puzzle.opening:return "CORE EXPOSED / Approach its focus, then [E] channel before Time resumes."
		if puzzle.aligned:return "GOLD ALIGNMENT / [Space] freeze the clock barrier, then [E] at its exposed core."
		return "Stand near the royal symbol south of the boss. Freeze when the hand glows GOLD; then E at the core."
	if puzzle.phase==puzzle.Phase.RESCUE:return "[E] Use the royal sigil at the princess's prison / NORTH" if at.distance_to(world.PRISON)<120 else "His attacks are silent. Walk NORTH to the prison and use your royal sigil [E]."
	if puzzle.phase==puzzle.Phase.DAWN:
		if at.distance_to(world.PEDESTAL)<110:return "[E] RETURN THE LAST FLAME / Restore dawn" if puzzle.offering_ready else "[E] Read the final offering / The princess will explain its cost."
		return "The princess is free. Return the last flame to the glowing CENTRAL pedestal to restore dawn."
	return "EMBERBOUND / THE LAST HOUR"

func pause_game() -> void:
	super.pause_game();hud.root.show();hud.cinema.hide();hud.skip_label.hide()
func resume_game() -> void:
	super.resume_game()
	if cinematic_mode=="ending":hud.root.hide();hud.cinema.show();hud.skip_label.show()
