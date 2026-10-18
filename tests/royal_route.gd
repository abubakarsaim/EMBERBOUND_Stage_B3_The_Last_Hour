extends RefCounted
## Shared real-Input route, used independently and after forest/shrine traversal.
func run(d: SceneTree) -> void:
	var game: Node = d.game
	game.skip_scene()
	await d.frames(45)
	d.check(game.hud.objective.text.contains("RESCUE THE PRINCESS"),"HUD prominently states the first rescue mission")
	d.check(game.player.active and game.puzzle.phase==game.puzzle.Phase.RESCUE,"Hall gives control with Rescue the Princess as the first mission")
	d.check(await d.road([Vector2(1450,1500),Vector2(1450,850)]),"Input route approaches the princess at the throne")
	d.action("interact")
	d.check(game.dialogue.active and game.puzzle.phase==game.puzzle.Phase.ALTAR and game.dialogue.lines[0][1].contains("Surrender"),"Princess requests the flame at the altar; mission updates with a concrete reason")
	var before: float = game.flame.value
	await d.frames(75)
	d.check(game.flame.value==before and game.projectiles.active.is_empty(),"Essential mission dialogue stops flame, AI and projectiles")
	game.skip_scene()
	d.check(await d.go_to(Vector2(1536,1460)),"Input route reaches the requested royal altar")
	d.action("interact")
	d.check(game.puzzle.phase==game.puzzle.Phase.MIRROR and game.dialogue.kind=="warning" and not game.puzzle.source_lit,"Altar warns of darkness and gives a reason to restore the mirror instead of surrendering fire")
	game.skip_scene()
	await d.frames(3)
	d.check(game.hud.objective.text.contains("REVEAL THE TRUTH"),"Altar warning automatically changes the prominent objective to restoring truth")
	d.check(await d.go_to(Vector2(1536,1600)),"Input route reaches the living-fire font")
	d.action("interact")
	d.check(game.puzzle.source_lit and game.puzzle.beam.size()>1 and not game.puzzle.mirror_powered,"Fire ignites a visible, initially misdirected light path")
	d.check(await d.go_to(Vector2(1150,1600)),"First reflector is physically reachable")
	for i in range(2):
		d.action("interact")
		await d.frames(4)
	d.check(game.puzzle.rotations[0]==1 and game.puzzle.energized[1] and not game.puzzle.mirror_powered,"Rotating the first face redirects actual beam geometry north into the second reflector")
	d.check(await d.go_to(Vector2(1150,1000)),"Input route follows the beam to the second reflector")
	for i in range(3):
		d.action("interact")
		await d.frames(4)
	d.check(game.puzzle.mirror_powered and game.puzzle.beam.back()==game.world.MIRROR and game.puzzle.beam.size()==4,"Second reflector completes source > I > II > mirror without a hidden item/order condition")
	d.check(await d.go_to(Vector2(830,1000)),"The illuminated royal mirror can be reached from the reflectors")
	d.action("interact")
	d.check(game.puzzle.mirror_lit and game.princess.revealed and game.encounter.active and game.dialogue.kind=="exposure","Examining the restored reflection exposes the imitation and begins the apparition mission")
	d.check(not game.shadow.active and not game.shadow.visible,"A single apparition replaces the hunter during the encounter, preventing double attacks")
	game.skip_scene()
	await d.frames(3)
	d.check(game.hud.objective.text.contains("BREAK THE ILLUSION"),"Mirror exposure automatically advances the HUD to the binding mission")
	d.check(await d.road([Vector2(1300,1100),Vector2(1536,1070)]),"Player can reach the binding seal while the apparition is active")
	d.action("interact")
	d.check(game.puzzle.seal_armed and game.world.is_protected(game.player.global_position),"Fire ignites the royal seal and creates its gold-heart recovery refuge")
	for i in range(360):
		if game.princess.global_position.distance_to(game.world.SEAL)<=game.puzzle.RADIUS-24: break
		await d.frames(1)
	d.check(game.princess.global_position.distance_to(game.world.SEAL)<=game.puzzle.RADIUS-24,"The apparition can be lured fully inside the active light seal")
	before = game.flame.value
	d.action("borrow_time")
	await d.frames(4)
	d.check(game.time_power.freeze_remaining>0 and absf(before-game.flame.value-15)<0.1 and game.encounter.state==game.encounter.State.FROZEN,"Existing Borrowed Time spends fifteen flame and immobilizes the apparition")
	d.action("interact")
	d.check(game.puzzle.phase==game.puzzle.Phase.REVEALING,"Final interaction only succeeds after Fire, shadow inside, and Time hold")
	await d.frames(165)
	d.check(game.puzzle.solved and game.puzzle.sigil_released and game.dialogue.kind=="truth" and not game.princess.visible,"Breaking the illusion releases a royal sigil and the short true-princess story")
	d.check(not game.world.gate_open,"The sigil has a concrete next use: the chamber remains sealed until the player brings it")
	game.skip_scene()
	await d.frames(3)
	d.check(game.hud.objective.text.contains("FIND THE REAL PRINCESS"),"Released sigil automatically gives the real-princess rescue objective")
	d.check(await d.road([Vector2(2300,1070),Vector2(2300,580),Vector2(2680,580)]),"Input route carries the released sigil to the eastern passage")
	d.action("interact")
	await d.frames(4)
	d.check(game.puzzle.gate_unlocked and game.world.gate_open,"Royal sigil interaction unlocks the Hourkeeper passage and commits the final checkpoint")
	var hall_time: float=game.hall_elapsed
	Input.action_press("move_right")
	await d.frames(100)
	d.release_movement()
	if d.root.get_node("Journey").campaign:
		for i in range(180):
			if d.current_scene!=game:break
			await d.frames(1)
		d.game=d.current_scene
		await d.frames(4)
		d.check(d.game.scene_file_path=="res://scenes/hourkeeper.tscn" and d.root.get_node("Journey").royal_solved,"Campaign royal sigil exit loads the playable Hourkeeper chapter")
	else:
		d.check(game.flow==game.Flow.SUCCESS and d.root.get_node("Journey").next_chapter=="hourkeeper_chamber","Independent hall test retains its completion screen; campaign continues to the boss")
	print("KNOWN_MISSION_ROUTE_SECONDS ",hall_time," (automated known solution, not human first-time pacing)")
