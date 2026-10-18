extends "res://scripts/hud.gd"
var mission_label: Label
var mission_back: ColorRect
var mission_rows: Array[Label] = []
var waypoint: Label
func _ready() -> void:
	super._ready()
	mission_back = panel(Rect2(24,116,370,200),Color(0.035,0.042,0.075,0.92))
	mission_label = label_at(Rect2(41,128,340,24),"",14,Color("c9bfaa"))
	for i in range(4): mission_rows.append(label_at(Rect2(41,154+i*25,340,24),"",15,Color("c9bfaa")))
	waypoint = label_at(Rect2(41,265,340,44),"",14,Color("d6c798"))
	context.add_theme_font_size_override("font_size",16)
	message.add_theme_font_size_override("font_size",14)
func show_screen(kind: String, saved: bool = false) -> void:
	super.show_screen(kind,saved)
	match kind:
		"menu":
			title.text = "THE ROYAL HALL"
			body.text = "CHAPTER III / THE BORROWED FACE\n\nRescue the princess. Investigate her altar.\nRestore the royal mirror. Break the illusion.\n\nFire reveals. Shadow deceives. Time gives you a chance."
			buttons.get_child(0).text = "Enter the Royal Hall"
		"pause":
			body.text = "Your current mission is shown above.\n\nGold/cyan objects: approach and E.\nE / Enter advances dialogue; Q skips.\nR restores the latest mission checkpoint.\nReflector angles and completed steps are saved.\n\nThe font, mirror and clock offer recovery."
		"failure":
			body.text = "The ember failed. Your progress did not.\n\nRetry with 100 flame at the latest mission checkpoint.\nReflectors, restored mirror, ignited seal and royal sigil are remembered.\n\nDodge the red warning mark; Time freezes flares."
		"success":
			title.text = "BEYOND THE LAST HOUR"
			title.add_theme_font_size_override("font_size",26)
			body.text = "The borrowed face is broken.\nYour flame carries the royal sigil.\n\nThe real princess is alive, imprisoned with the Eternal Flame beyond this door.\n\nNEXT: THE HOURKEEPER'S CHAMBER\nROYAL HALL TEST COMPLETE.\nThe full campaign continues to the Hourkeeper."
			buttons.get_child(0).text = "Play again from the beginning"
func refresh(game: Node, delta: float) -> void:
	super.refresh(game,delta)
	if mission_label==null: return
	var p: Node = game.puzzle
	var mission: int = 0 if p.phase<=p.Phase.ALTAR else (1 if p.phase==p.Phase.MIRROR else (2 if not p.solved else 3))
	mission_back.visible = game.flow==game.Flow.PLAYING and game.cinematic_mode==""
	mission_label.visible = mission_back.visible
	waypoint.visible = mission_back.visible
	var compact: bool = p.phase in [p.Phase.ENCOUNTER,p.Phase.REVEALING]
	mission_back.size.y = 88 if compact else 200
	waypoint.position.y = 154 if compact else 265
	mission_label.text = "03  BREAK THE ILLUSION" if compact else "MISSIONS / CHAPTER III"
	var names := ["Rescue the Princess","Reveal the Truth","Break the Illusion","Find the Real Princess"]
	for i in range(4):
		mission_rows[i].visible = mission_back.visible and not compact
		mission_rows[i].text = ("+ " if i<mission else ("> " if i==mission else "· "))+str(i+1)+"  "+names[i]
	var direction: Vector2 = p.goal()-game.player.global_position
	var bearing: String = "Within reach [E]" if direction.length()<110 else ["EAST","SOUTHEAST","SOUTH","SOUTHWEST","WEST","NORTHWEST","NORTH","NORTHEAST"][posmod(roundi(direction.angle()/(PI/4)),8)]
	waypoint.text = "NEXT: "+p.goal_name().split(" / ")[0]+"\n"+bearing+" / "+str(roundi(direction.length()))+" px"
	if game.cinematic_mode!="":
		objective.text = "%02d  %s\nE / Enter continues  •  Q skips" % [mission+1,names[mission].to_upper()]
	elif p.phase==p.Phase.RESCUE:
		objective.text = "01  RESCUE THE PRINCESS\nApproach her beside the throne [E]."
	elif p.phase==p.Phase.ALTAR:
		objective.text = "01  RESCUE THE PRINCESS\nExamine her altar before giving the flame."
	elif p.phase==p.Phase.MIRROR:
		if not p.source_lit: objective.text = "02  REVEAL THE TRUTH\nKindle the light font to restore the mirror."
		elif p.mirror_powered: objective.text = "02  REVEAL THE TRUTH\nLight reaches the mirror. Examine it [E]."
		else: objective.text = "02  REVEAL THE TRUTH\nRotate reflectors; guide light to the mirror."
	elif p.phase==p.Phase.REVEALING:
		objective.text = "03  BREAK THE ILLUSION\nThe stolen royal sigil is breaking free."
	elif not p.solved:
		if not p.seal_armed: objective.text = "03  BREAK THE ILLUSION\nKindle the royal seal [E]. Dodge red marks."
		elif game.princess.global_position.distance_to(game.world.SEAL)>p.RADIUS-24: objective.text = "03  BREAK THE ILLUSION\nDraw her shadow inside the cyan seal."
		elif game.time_power.freeze_remaining>0: objective.text = "03  BREAK THE ILLUSION\n[E] Finish the binding at the royal seal!"
		else: objective.text = "03  BREAK THE ILLUSION\nShadow inside: [Space] hold, then [E]."
	else:
		objective.text = "04  FIND THE REAL PRINCESS\n"+("Cross the opened eastern passage." if p.gate_unlocked else "Use the freed sigil at the eastern door [E].")
	if p.phase==p.Phase.ENCOUNTER:
		status.text = "APPARITION: %s | Gold heart / font / mirror: refuge | WASD/arrows: move  E: interact  Space: Time  Esc: pause  R: retry" % game.encounter.state_label().to_upper()
	elif p.solved: status.text = "ROYAL SIGIL: FREED | Real princess: alive / held by the Hourkeeper | E: passage  Esc: pause  R: retry"
	if message_timer<=0:
		message.text = ["She seems to be the princess. Speak to her and learn how to free her.","A true royal mirror cannot be fooled by a borrowed face. Your fire can restore its sight.","Fire binds her shadow; Time keeps it still long enough for your hand to break the illusion.","Her sigil was sustaining the imitation. Freed, it can open the prison of the real princess."][mission]

		if p.phase==p.Phase.ALTAR: message.text = "She claims the altar can free her. Examine it before risking the Eternal Flame."
