extends RefCounted
## Complete actual-input route. No boss phase, angle, health or position is assigned here.
func run(d: SceneTree) -> void:
	var game: Node=d.game
	game.skip_scene()
	await d.frames(45)
	d.check(game.player.active and game.puzzle.phase==game.puzzle.Phase.ANCHORS,"Boss chapter gives immediate control after its skippable arrival")
	d.check(game.princess.visible and not game.princess.freed and d.root.get_node("Journey").royal_solved,"Real princess is visibly imprisoned and the earned sigil reaches B3")
	d.check(game.hud.objective.text.contains("BREAK THE TIME PRISON"),"First boss objective explains the two prison anchors")
	d.check(await d.road([Vector2(760,1650),Vector2(760,1030)]),"Input traversal reaches the west Chrono Anchor through actual arena collisions")
	for i in range(1200):
		if game.puzzle.exposed_remaining>2:break
		await d.frames(1)
	d.check(game.puzzle.exposed_remaining>0,"A real telegraphed attack and recovery expose the anchors")
	d.action("interact")
	d.check(game.puzzle.channel_kind=="anchor" and not game.puzzle.anchors[0],"E begins a timed flame channel rather than instantly disabling an anchor")
	await d.frames(80)
	d.check(game.puzzle.anchors[0] and game.puzzle.lit_count()==1,"Stationary channel disables the first prison chain")
	d.check(await d.go_to(Vector2(1800,1030)),"Player can cross the clock court to the second anchor")
	for i in range(1200):
		if game.puzzle.exposed_remaining>2:break
		await d.frames(1)
	d.action("interact")
	await d.frames(80)
	d.check(game.puzzle.lit_count()==2 and game.puzzle.phase==game.puzzle.Phase.CORE,"Both anchors weaken the prison and start the clock-core phase")
	await d.frames(8)
	d.check(game.hud.objective.text.contains("DEFEAT THE HOURKEEPER"),"HUD automatically advances to the Time barrier objective")
	d.check(await d.go_to(Vector2(1280,1145)),"Core focus remains reachable during the live encounter")
	for strike in range(2):
		for i in range(1800):
			if game.puzzle.aligned and game.time_power.cooldown_remaining<=0:break
			await d.frames(1)
		d.check(game.puzzle.aligned and game.time_power.cooldown_remaining<=0,"Gold hand alignment and Time recovery provide a reachable core opportunity %d" % (strike+1))
		var before: float=game.flame.value
		d.action("borrow_time")
		d.check(game.puzzle.opening and absf(before-game.flame.value-15)<0.01,"Standard fifteen-flame Borrowed Time exposes the correctly aligned clock barrier")
		d.action("interact")
		await d.frames(58)
		d.check(game.puzzle.strikes==strike+1,"Short channel registers core strike %d" % (strike+1))
		if strike==0:
			d.action("interact")
			d.check(game.puzzle.strikes==1,"A single Time opening cannot be used for both core strikes")
	for i in range(220):
		if game.cinematic_mode=="":break
		await d.frames(1)
	d.check(game.puzzle.solved and game.puzzle.phase==game.puzzle.Phase.RESCUE and game.flow==game.Flow.PLAYING,"Boss defeat leaves a playable rescue mission instead of ending the game")
	d.check(not game.patterns.active and game.projectiles.active.is_empty(),"Boss defeat permanently stops hostile attacks and clears lingering flares")
	d.check(await d.go_to(Vector2(1280,740)),"Actual input reaches the prison's royal lock after victory")
	d.action("interact")
	d.check(game.cinematic_mode=="release" and not game.puzzle.freed,"Royal sigil interaction deliberately starts the princess release animation")
	await d.frames(95)
	d.check(game.puzzle.freed and game.dialogue.kind=="rescue" and game.puzzle.phase==game.puzzle.Phase.DAWN,"Release animation frees the real princess and explains the final dawn mission")
	game.skip_scene()
	d.check(await d.go_to(Vector2(1280,1230)),"Knight remains controllable and reaches the revealed Eternal Flame pedestal")
	var flame_before: float=game.flame.value
	d.action("interact")
	d.check(game.dialogue.kind=="offering" and game.puzzle.phase==game.puzzle.Phase.DAWN and game.flame.value==flame_before,"First offering interaction explains its cost without accidentally consuming the flame")
	game.skip_scene()
	d.action("interact")
	d.check(game.cinematic_mode=="ending" and game.puzzle.phase==game.puzzle.Phase.ENDING,"Second deliberate interaction earns the final cinematic")
	await d.frames(800)
	d.check(game.flow==game.Flow.SUCCESS and game.puzzle.phase==game.puzzle.Phase.COMPLETE and d.root.get_node("Journey").completed,"Complete playable mission sequence reaches dawn and ending credits")
	d.check(game.flame.value==0 and game.player.flame_returned and game.player.fallen and game.princess.kneeling,"Bittersweet ending returns the ember, lays the knight to rest and brings the princess to him")
	d.check(game.sky.progress==1 and game.dawn_amount==1 and game.hud.title.text=="EMBERBOUND","Sunrise and final EMBERBOUND title render as the earned conclusion")
	d.check(game.hud.body.text.contains("Godot") and game.hud.body.text.contains("Thank you"),"Ending screen includes actual development credits")
	print("KNOWN_BOSS_ROUTE_SECONDS ",game.elapsed," (known strategy; excludes manual dialogue/cinematic)")
