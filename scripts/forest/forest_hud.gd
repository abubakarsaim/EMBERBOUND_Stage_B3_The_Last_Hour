extends "res://scripts/hud.gd"
signal shrine_test_requested
signal hall_test_requested
signal boss_test_requested
var journal: Label
var story: Label
var journal_back: ColorRect
var journal_line: ColorRect
func _ready() -> void:
	super._ready()
	journal_back = panel(Rect2(24,116,370,120),Color(0.025,0.045,0.085,0.9))
	journal_line = panel(Rect2(24,116,3,120),Color("5babbc"))
	journal = label_at(Rect2(42,123,343,108),"",16,Color("9dcbd7"))
	story = label_at(Rect2(426,126,790,82),"",20,Color("d2cbb8"))
	story.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
func show_screen(kind: String, saved: bool = false) -> void:
	super.show_screen(kind,saved)
	buttons.position.y=410 if kind=="menu" else 438
	body.size.y=180 if kind=="menu" else 205
	if kind=="menu":
		body.text = "THE LAST HOUR / CHAPTER I\n\nA kingdom without sunlight. One last ember.\nCross the Cursed Forest. Reach the princess.\n\nWASD / arrows  Move     E  Read / kindle\nSpace  Borrowed Time (15 flame)"
		buttons.get_child(0).text = "Begin the Cursed Forest"
		make_button("Development: test shrine only",func(): shrine_test_requested.emit())
		make_button("Development: Royal Hall",func(): hall_test_requested.emit())
		make_button("Development: Hourkeeper / finale",func(): boss_test_requested.emit())
	elif kind=="pause":
		body.text = "The forest waits.\n\nFollow the ruined paths to three inscriptions.\nYour fire reveals their ordered symbols.\nRead the journal: FIRST > SECOND > LAST.\n\nWatchfires grant temporary refuge.\nR restores flame and remembers puzzle progress."
	elif kind=="failure":
		body.text = "The forest swallows the light.\n\nYour journal and kindled braziers are remembered.\nRetry at the watchfire, or at the unlocked gate.\n\nRestart restores 100 flame.\nBorrowed Time freezes flares as well as the hunter."
func refresh(game: Node, delta: float) -> void:
	super.refresh(game,delta)
	if journal==null: return
	journal.text = "INSCRIPTIONS / FIRE REVEALS THE WAY\n"
	for i in range(3):
		journal.text += ["FIRST  ","SECOND  ","LAST  "][i]+(["ROOT / Memorial","BELL / Fallen tower","CROWN / Royal tomb"][i] if game.puzzle.discovered[i] else "? / Find the hidden stone")+"\n"
	journal.visible = game.flow==game.Flow.PLAYING
	journal_back.visible = journal.visible
	journal_line.visible = journal.visible
	story.visible = journal.visible
	story.text = game.story_line
	if message_timer<=0: message.text = "FIRST the roots. SECOND the bell. LAST the crown. Your light reveals what darkness hides."
	if game.puzzle.solved:
		objective.text = "THE FORGOTTEN FLAMES / 3 of 3\nGate open > EAST to the shrine"
	elif game.puzzle.found_count()<3:
		objective.text = "FOREST INSCRIPTIONS / %d of 3\nExplore the ruins; firelight reveals clues." % game.puzzle.found_count()
	else:
		objective.text = "THE FORGOTTEN FLAMES / %d of 3\nLight braziers: FIRST > SECOND > LAST" % game.puzzle.progress
	if game.corruption.contains(game.player.global_position):
		status.text = status.text.replace("SHADOW RESIDUE / cosmetic","CORRUPTION / the hunter passed here")
