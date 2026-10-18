extends Node2D
## Four connected missions. Permanent progress is separate from transient encounter effects.
signal completed
signal lamp_lit
signal mission_changed
signal mirror_restored
signal revelation_started
signal seal_ignited
const Art = preload("res://scripts/pixel_art.gd")
const Glyph = preload("res://scripts/forest/forest_art.gd")
const SEAL := Vector2(1536,1000)
const ALTAR := Vector2(1536,1390)
const MIRROR := Vector2(830,930)
const FONT := Vector2(1536,1740)
const SOURCE := Vector2(1536,1530)
const REFLECTORS := [Vector2(1150,1530),Vector2(1150,930)]
const GATE := Vector2(2680,580)
const RADIUS: float = 175
const DEFAULT_ROTATIONS := [3,2]
enum Phase { RESCUE, ALTAR, MIRROR, ENCOUNTER, REVEALING, SIGIL, SOLVED }
var phase: Phase = Phase.RESCUE
var solved: bool = false
var lamps: Array[Node2D] = []
var rotations: Array[int] = [3,2]
var source_lit: bool = false
var mirror_powered: bool = false
var mirror_lit: bool = false
var seal_armed: bool = false
var sigil_released: bool = false
var gate_unlocked: bool = false
var reveal_remaining: float = 0
var clock: float = 0
var no_progress: float = 0
var selected: String = ""
var beam: Array[Vector2] = []
var energized: Array[bool] = [false,false]
var checkpoint_position := Vector2(1536,2200)
var last_feedback: String = ""
func reset() -> void:
	phase = Phase.RESCUE
	solved = false
	rotations.assign(DEFAULT_ROTATIONS)
	source_lit = false
	mirror_powered = false
	mirror_lit = false
	seal_armed = false
	sigil_released = false
	gate_unlocked = false
	checkpoint_position = Vector2(1536,2200)
	clear_temporary()
	trace_light()
func clear_temporary() -> void:
	reveal_remaining = 0
	no_progress = 0
	if phase==Phase.REVEALING: phase = Phase.ENCOUNTER
func lit_count() -> int:
	return 4 if gate_unlocked else (3 if solved else (2 if mirror_lit else (1 if phase>=Phase.MIRROR else 0)))
func nearest_lamp(_point: Vector2) -> Node2D: return null
func set_phase(next: Phase) -> void:
	phase = next
	no_progress = 0
	mission_changed.emit()
func ask_for_flame() -> void:
	if phase!=Phase.RESCUE: return
	checkpoint_position = ALTAR+Vector2(0,90)
	set_phase(Phase.ALTAR)
func examine_altar() -> void:
	if phase!=Phase.ALTAR: return
	checkpoint_position = SOURCE+Vector2(0,90)
	set_phase(Phase.MIRROR)
func trace_light() -> void:
	beam.clear()
	energized.fill(false)
	mirror_powered = false
	if not source_lit: return
	var at := SOURCE
	var direction := Vector2.LEFT
	beam.append(at)
	var previous: int = -1
	for bounce in range(5):
		var end := at+direction*1000
		# Clip the visible ray to the light court, including incorrect directions.
		for axis in range(2):
			if absf(direction[axis])>0.001:
				var edge: float = ([1740.0,1840.0][axis] if direction[axis]>0 else [680.0,800.0][axis])
				var distance: float = (edge-at[axis])/direction[axis]
				if distance>0 and distance<at.distance_to(end): end = at+direction*distance
		var closest: float = at.distance_to(end)
		var hit: int = -1
		for i in range(3):
			if i==previous: continue
			var target: Vector2 = REFLECTORS[i] if i<2 else MIRROR
			var along: float = (target-at).dot(direction)
			if along>12 and along<=closest and absf((target-at).cross(direction))<25:
				closest = along
				hit = i
		if hit<0:
			beam.append(end)
			break
		at = REFLECTORS[hit] if hit<2 else MIRROR
		beam.append(at)
		if hit==2:
			mirror_powered = true
			break
		energized[hit] = true
		var face := Vector2.from_angle(rotations[hit]*PI/4)
		direction = (2*direction.dot(face)*face-direction).normalized().snapped(Vector2(0.001,0.001))
		previous = hit
	queue_redraw()
func rotate_reflector(index: int) -> String:
	if phase>Phase.MIRROR: return "The mirror is restored. These reflectors are aligned; follow your next mission."
	if phase!=Phase.MIRROR: return "Restore the mirror after examining the royal altar."
	rotations[index] = (rotations[index]+1)%4
	no_progress = 0
	trace_light()
	if mirror_powered: return "The mirror receives the flame! Follow the beam WEST and examine its reflection [E]."
	if not source_lit: return "Reflector rotated. Kindle the golden light font to the EAST first."
	return "Reflector rotated 45 degrees. Follow the gold beam; its next receiver has a cyan rim."
func tick(delta: float, _player: Node2D, _princess: Node2D, power: Node) -> void:
	if power.freeze_remaining<=0: clock += delta
	no_progress += delta
	if phase==Phase.REVEALING:
		reveal_remaining = maxf(0,reveal_remaining-delta)
		if reveal_remaining<=0:
			solved = true
			sigil_released = true
			checkpoint_position = SEAL+Vector2(0,70)
			set_phase(Phase.SIGIL)
			completed.emit()
	queue_redraw()
func update_feedback(at: Vector2, _hunter: Node2D) -> void:
	selected = ""
	for i in range(2):
		if at.distance_to(REFLECTORS[i])<100: selected = "reflector"+str(i)
	if at.distance_to(MIRROR)<110: selected = "mirror"
	if at.distance_to(SEAL)<110: selected = "seal"
func interact(at: Vector2, power: Node, flame: Node, apparition_at: Vector2 = Vector2.INF) -> String:
	for i in range(2):
		if at.distance_to(REFLECTORS[i])<100: return rotate_reflector(i)
	if at.distance_to(SOURCE)<110:
		if phase<Phase.MIRROR: return "The light font is cold. Speak to the princess and examine her altar first."
		if not source_lit:
			source_lit = true
			trace_light()
			lamp_lit.emit()
			return "Your fire awakens the royal lens. Follow its beam WEST to Reflector I."
		flame.reset()
		return "The sacred font rekindles your flame. Its light remembers the path to truth."
	if at.distance_to(MIRROR)<110:
		if phase<Phase.MIRROR: return "The royal mirror is blind. Its inscription reads: 'Only living fire can reveal a borrowed face.'"
		if not mirror_powered: return "No light reaches the mirror. Kindle the font, then turn both silver reflectors to guide its beam here."
		if not mirror_lit:
			mirror_lit = true
			checkpoint_position = MIRROR+Vector2(0,100)
			set_phase(Phase.ENCOUNTER)
			mirror_restored.emit()
			return "The reflection reveals a shadow impostor. The royal seal can bind her. CHECKPOINT SAVED."
		flame.restore(25)
		return "The restored mirror steadies your flame (+25). The apparition cannot enter this refuge."
	if at.distance_to(SEAL)<110:
		if phase<Phase.ENCOUNTER: return "The seal answers only an exposed shadow. Restore the royal mirror first."
		if solved: return "The released royal sigil is bound to your flame. Take it to the EASTERN passage."
		if not seal_armed:
			seal_armed = true
			checkpoint_position = SEAL+Vector2(0,70)
			if flame.value<40: flame.restore(40-flame.value)
			seal_ignited.emit()
			return "The seal draws her inward. Its gold heart is a refuge. Wait for her shadow INSIDE cyan, then Space > E."
		if apparition_at.distance_to(SEAL)>RADIUS-24: return "Her shadow is OUTSIDE the cyan seal. Wait in its gold heart and lure her across the ring before using Time."
		if power.freeze_remaining<=0: return "Her shadow is inside. Press SPACE to hold it, then E here to break the illusion."
		phase = Phase.REVEALING
		reveal_remaining = 2.6
		revelation_started.emit()
		return "FIRE binds. TIME holds. The borrowed face breaks."
	return "No object in reach. Follow the current mission marker; E examines nearby gold/cyan objects."
func unlock_gate() -> bool:
	if not sigil_released or gate_unlocked: return false
	gate_unlocked = true
	checkpoint_position = Vector2(2580,580)
	set_phase(Phase.SOLVED)
	return true
func goal() -> Vector2:
	match phase:
		Phase.RESCUE: return Vector2(1536,860)
		Phase.ALTAR: return ALTAR
		Phase.MIRROR:
			if not source_lit: return SOURCE
			if mirror_powered: return MIRROR+Vector2(0,75)
			return REFLECTORS[1] if energized[1] else REFLECTORS[0]
		Phase.ENCOUNTER,Phase.REVEALING: return SEAL
		_: return Vector2(2820,580) if gate_unlocked else GATE
func goal_name() -> String:
	match phase:
		Phase.RESCUE: return "Princess / NORTH"
		Phase.ALTAR: return "Royal altar / SOUTH"
		Phase.MIRROR:
			if not source_lit: return "Light font / SOUTH"
			if mirror_powered: return "Royal mirror / WEST"
			return "Reflector II / NORTH" if energized[1] else "Reflector I / WEST"
		Phase.ENCOUNTER,Phase.REVEALING: return "Royal seal / EAST"
		_: return "Hourkeeper passage / EAST"
func _draw() -> void:
	# The altar is deliberately separate from the binding seal.
	for i in range(4,0,-1):draw_circle(ALTAR,i*24,Color(0.8,0.36,0.17,0.018))
	draw_rect(Rect2(ALTAR-Vector2(64,22),Vector2(128,44)),Color("151c30"))
	draw_rect(Rect2(ALTAR-Vector2(58,55),Vector2(116,38)),Color("695542"))
	draw_rect(Rect2(ALTAR-Vector2(60,58),Vector2(120,6)),Color("d5ad64"))
	Glyph.glyph(self,ALTAR-Vector2(0,34),2,Color("dfc287"),0.8)
	text(ALTAR+Vector2(-65,44),"ROYAL ALTAR",Color("d5b77b"))
	if phase>=Phase.ALTAR:
		for i in range(12):
			var angle := i*TAU/12
			var end := ALTAR+Vector2.from_angle(angle)*(75+sin(clock*2+i)*13)
			draw_line(end,ALTAR+Vector2.from_angle(angle)*25,Color("351025"),4,false)
			var mote := end.lerp(ALTAR,fmod(clock*0.45+i*0.083,1.0))
			draw_rect(Rect2(mote.snapped(Vector2(2,2)),Vector2(5,5)),Color("79233f"))
	# Physical redirection: visible rays reflect from the rotated faces, no hidden order.
	for i in range(beam.size()-1):
		draw_line(beam[i],beam[i+1],Color(0.98,0.63,0.2,0.13),12,false)
		draw_line(beam[i],beam[i+1],Color("e7b86c"),4,false)
		var packet: Vector2 = beam[i].lerp(beam[i+1],fmod(clock*0.32,1))
		draw_rect(Rect2(packet.snapped(Vector2(2,2))-Vector2(3,3),Vector2(6,6)),Color("ffecb9"))
	for i in range(2):
		var at: Vector2 = REFLECTORS[i]
		var col := Color("e2bd78") if energized[i] else Color("69a9bf")
		Art.ring(self,at,47,col,2)
		draw_rect(Rect2(at-Vector2(30,22),Vector2(60,44)),Color("101c30"))
		var face := Vector2.from_angle(rotations[i]*PI/4)*33
		draw_line(at-face,at+face,Color("789caf"),10,false)
		draw_line(at-face,at+face,Color("d0e5e6"),4,false)
		for a in [0,PI/2,PI,PI*1.5]:draw_rect(Rect2(at+Vector2.from_angle(a)*42-Vector2(2,2),Vector2(4,4)),Color("d4ab6b"))
		text(at+Vector2(-63,78),"REFLECTOR "+["I","II"][i],col)
		if selected=="reflector"+str(i): text(at+Vector2(-65,-64),"[E] ROTATE 45°",Color("ffe2a5"))
	Art.ring(self,SOURCE,42,Color("bba06a"),3)
	Glyph.glyph(self,SOURCE,2,Color("eecb8b"),0.8)
	if source_lit:
		for i in range(5,0,-1):draw_circle(SOURCE-Vector2(0,18),i*12,Color(1,0.6,0.16,0.025))
		draw_rect(Rect2(SOURCE-Vector2(7,38),Vector2(14,27)),Color("ffd487"))
	text(SOURCE+Vector2(-68,63),"[E] LIGHT FONT",Color("e6c488"))
	var col := Color("82e1e7") if seal_armed else Color("7f7f99")
	Art.ring(self,SEAL,RADIUS,col,3)
	Art.ring(self,SEAL,80,Color("d7b96a") if seal_armed else Color("5d5365"),3)
	if seal_armed:
		for i in range(5,0,-1):draw_circle(SEAL,i*17,Color(1,0.72,0.24,0.022))
	Glyph.glyph(self,SEAL,2,col,1.7)
	text(SEAL+Vector2(-75,205),"[E] ROYAL SEAL",col)
	# Gilded, chipped mirror. The activated reflection is an actual animated sprite view.
	draw_rect(Rect2(MIRROR+Vector2(-75,-15),Vector2(150,24)),Color("171d30"))
	draw_rect(Rect2(MIRROR+Vector2(-70,-150),Vector2(140,145)),Color("86673f"))
	draw_rect(Rect2(MIRROR+Vector2(-63,-143),Vector2(126,132)),Color("d8ba7e"))
	draw_rect(Rect2(MIRROR+Vector2(-57,-137),Vector2(114,122)),Color("1b2b45"))
	if mirror_powered or mirror_lit:
		for i in range(4,0,-1):draw_circle(MIRROR-Vector2(0,70),i*26,Color(0.3,0.67,0.82,0.02))
		var source: Texture2D = preload("res://assets/royal/false_princess_idle.png")
		draw_texture_rect_region(source,Rect2(MIRROR+Vector2(-45,-131),Vector2(90,112)),Rect2((int(clock*2)%4)*64,0,64,80),Color(0.62,0.8,0.95,0.92))
	else:
		for i in range(4):draw_line(MIRROR+Vector2(-40+i*24,-130),MIRROR+Vector2(-70+i*24,-28),Color(0.4,0.6,0.77,0.25),3,false)
	draw_line(MIRROR+Vector2(6,-137),MIRROR+Vector2(-8,-88),Color("8891a7"),2,false)
	text(MIRROR+Vector2(-76,46),"THE ROYAL REFLECTION",Color("b6c9db"))
	if selected=="mirror":text(MIRROR+Vector2(-55,-176),"[E] EXAMINE",Color("ffe2a5"))
func text(at: Vector2, words: String, col: Color) -> void:
	draw_string(ThemeDB.fallback_font,at,words,HORIZONTAL_ALIGNMENT_LEFT,-1,17,col)
