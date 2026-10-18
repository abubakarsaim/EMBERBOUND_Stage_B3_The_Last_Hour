extends "res://tests/test_forest.gd"
## Route uses real input. Fixtures below deliberately assign state to isolate edge cases.
func fixture() -> void:
	paused=false;game.set_physics_process(true);game.puzzle.reset();game.intro_seen=true;game.restore_run(false)
	await frames(3)
	game.set_physics_process(false);game.read_grace=0;game.player.invulnerable=0
func run() -> void:
	game=load("res://scenes/hourkeeper.tscn").instantiate();root.add_child(game);current_scene=game
	await frames(4)
	await preload("res://tests/boss_route.gd").new().run(self)
	await fixture()
	var p: Node=game.puzzle
	var a: Node=game.patterns
	var b: Node=game.boss
	var k: Node=game.player
	var t: Node=game.time_power
	var f: Node=game.flame
	k.global_position=p.ANCHORS[0]+Vector2(0,70)
	check(p.start_anchor(0,k.global_position).contains("shielded") and p.channel_kind=="","Shielded anchor rejects E with the attack/recovery explanation")
	p.expose_anchors();p.start_anchor(0,k.global_position)
	Input.action_press("move_right");p.tick(0.1,k,b,t);release_movement()
	check(p.channel_kind=="" and not p.anchors[0],"Movement interrupts anchor channel without false progress")
	p.start_anchor(0,k.global_position);p.exposed_remaining=0.02;p.tick(1.21,k,b,t)
	check(p.anchors[0],"A channel begun inside exposure can finish without an unfair expiry")
	f.set_value(0);check(game.flow==game.Flow.FAILURE,"Combat flame exhaustion enters the ordinary failure screen")
	game.restart_checkpoint()
	check(p.anchors[0] and not p.anchors[1] and p.phase==p.Phase.ANCHORS and f.value==100,"Partial-anchor checkpoint restores progress and full flame")
	await fixture()
	k.global_position=Vector2(1280,1400);k.velocity=Vector2.ZERO
	a.next_kind=0;a.begin_attack(b,k)
	var locked: Vector2=a.aim
	check(is_equal_approx(a.remaining,1.1) and game.projectiles.active.is_empty(),"Shadow Flare provides 1.1 seconds of warning before any projectile")
	k.global_position+=Vector2(100,0);a.tick(0.4,b,k,game.projectiles,t,false,false)
	check(a.aim==locked,"Flare locks its warning position rather than following the dodge")
	a.tick(0.8,b,k,game.projectiles,t,false,false)
	check(game.projectiles.active.size()==1 and a.total_attacks[0]==1 and b.release_remaining>0,"One flare releases with a distinct boss release pose")
	game.projectiles.clear();k.global_position=Vector2(1280,1400);k.invulnerable=0
	f.reset(80);game.projectiles.launch(k.global_position-Vector2(75,0),k.global_position)
	game.projectiles.tick(0.3,false,k,false)
	check(is_equal_approx(f.value,75) and k.light_impact>0 and k.hurt_flash>0,"Real swept flare collision removes five flame and starts torch-impact feedback")
	game.damage_flame(5)
	check(f.value==75,"Post-hit immunity prevents immediate repeated flame damage")
	await frames(45)
	check(k.light_impact==0,"Torch-impact radius penalty expires instead of permanently stacking")
	game.projectiles.clear();game.projectiles.launch(Vector2(1200,1380),Vector2(1500,1380))
	var shot: Node=game.projectiles.active[0]
	var shot_at: Vector2=shot.global_position
	game.projectiles.tick(1,true,k,false)
	check(shot.global_position==shot_at and shot.age==0,"Time freezes active projectile travel and lifetime")
	game.projectiles.tick(0.1,false,k,false)
	check(shot.global_position!=shot_at,"Projectile resumes smooth travel when Time ends")
	game.projectiles.clear()
	k.invulnerable=0;k.global_position=b.global_position+Vector2(300,0);f.reset(80)
	a.next_kind=1;a.begin_attack(b,k)
	check(is_equal_approx(a.remaining,1.55),"Clock sweep warns its exact sector for 1.55 seconds")
	a.tick(1.56,b,k,game.projectiles,t,false,false)
	for i in range(80):a.tick(1.0/60,b,k,game.projectiles,t,false,false)
	check(f.value==72 and a.state==a.State.RECOVERING,"Sweeping hand inflicts eight flame once, then recovers")
	k.invulnerable=0;f.reset(80);a.next_kind=1;a.begin_attack(b,k);k.global_position=b.global_position+Vector2(-300,0)
	a.tick(1.56,b,k,game.projectiles,t,false,false)
	for i in range(80):a.tick(1.0/60,b,k,game.projectiles,t,false,false)
	check(f.value==80,"Leaving the warned sweep sector reliably avoids damage")
	k.global_position=b.global_position+Vector2(280,0);a.next_kind=2;a.begin_attack(b,k)
	check(is_equal_approx(a.remaining,1.65),"Time distortion gives 1.65 seconds of distinct cyan warning")
	a.tick(1.66,b,k,game.projectiles,t,false,false)
	for i in range(60):a.tick(1.0/60,b,k,game.projectiles,t,false,false)
	check(game.slow_remaining==1.6 and f.value==80 and a.remaining>2.5,"Distortion only slows, never drains flame; its recovery prevents overlapping attacks")
	game.patterns.active=false;game.set_physics_process(true);Input.action_press("move_right");await frames(20);release_movement();game.set_physics_process(false)
	check(is_equal_approx(k.speed,149.6) and k.velocity.length()>100,"Time drag retains responsive player control at 68 percent speed")
	game.set_physics_process(true);await frames(100);game.set_physics_process(false)
	check(game.slow_remaining==0 and k.speed==220,"Time drag reliably recovers normal movement")
	await fixture();p.phase=p.Phase.CORE;p.anchors.fill(true);k.global_position=p.core_point(b);k.velocity=Vector2.ZERO
	p.barrier_angle=0;t.reset();f.reset(90);t.try_activate(f)
	check(not p.opening and p.start_core(k.global_position,b,t).contains("away"),"Freezing away from the royal symbol gives a meaningful failed-interaction hint")
	t.reset();p.barrier_angle=PI/2;t.try_activate(f)
	var angle: float=p.barrier_angle
	var clock: float=b.clock
	a.begin_attack(b,k);var warning_time: float=a.remaining
	p.tick(0.5,k,b,t);a.tick(0.5,b,k,game.projectiles,t,false,false);b.tick(0.5)
	check(p.opening and p.barrier_angle==angle and a.remaining==warning_time and b.clock>clock,"Borrowed Time holds barrier and attack timing while boss idle continues")
	p.start_core(k.global_position,b,t);Input.action_press("move_left");p.tick(0.2,k,b,t);release_movement()
	check(p.strikes==0 and p.channel_kind=="","Interrupted core channel cannot award a strike")
	k.velocity=Vector2.ZERO;p.start_core(k.global_position,b,t);p.tick(0.86,k,b,t)
	check(p.strikes==1 and p.start_core(k.global_position,b,t).contains("One strike"),"One freeze opening permits precisely one successful core strike")
	game.projectiles.launch(k.global_position+Vector2(180,0),k.global_position);game.slow_remaining=1;t.freeze_remaining=1
	game.restart_checkpoint()
	check(p.phase==p.Phase.CORE and p.strikes==1 and p.lit_count()==2 and f.value==100,"Phase-two checkpoint retains both anchors and the first successful strike")
	check(game.projectiles.active.is_empty() and t.freeze_remaining==0 and game.slow_remaining==0 and p.channel_kind=="","Checkpoint clears projectiles, freeze, slow and interrupted channel state")
	await fixture();f.reset(12);t.reset();t.try_activate(f)
	check(t.freeze_remaining==0 and f.value==12,"Insufficient flame cannot purchase a boss Time opening")
	check(p.use_font(0,f).contains("+30") and f.value==42,"Visible ancient fire restores enough flame to escape ability starvation")
	p.use_font(0,f);check(f.value==42 and p.font_cooldowns[0]==16,"Fire cooldown prevents refill spam without consuming its permanent refuge")
	p.tick(16,k,b,t);p.use_font(0,f)
	check(f.value==72,"Renewable fire becomes usable after its sixteen-second cooldown")
	p.phase=p.Phase.DAWN;p.solved=true;p.freed=true;game.set_physics_process(true);game.restore_run(true)
	await frames(3)
	check(p.phase==p.Phase.DAWN and game.princess.freed and game.world.prison_shape.disabled,"Rescue checkpoint restores the freed princess and removes prison collision")
	game.begin_ending();await frames(8);game.pause_game();var ending: float=game.ending_time;await frames(25)
	check(game.ending_time==ending and game.hud.root.visible,"Ending can be paused with a visible pause menu")
	game.resume_game();await frames(8);check(game.ending_time>ending,"Ending resumes after pause")
	game.restart_checkpoint();await frames(3)
	check(p.phase==p.Phase.DAWN and game.cinematic_mode=="" and game.sky.progress==0 and k.active and not k.fallen,"Restart during the ending returns to a clean deliberate-offering checkpoint")
	game.begin_ending();game.skip_scene();check(game.flow==game.Flow.SUCCESS and p.phase==p.Phase.COMPLETE,"Q skips the ending into completed credits")
	game.restart_checkpoint();await frames(3)
	check(p.phase==p.Phase.DAWN and f.value==100 and not k.flame_returned,"Restart after credits cannot leave a zero-flame or frozen-camera softlock")
	paused=false;game.queue_free();await frames(25)
	var deadline:=Time.get_ticks_msec()+350
	while Time.get_ticks_msec()<deadline:await process_frame
	print("%d passed / %d failed" % [passed,failed]);quit(0 if failed==0 else 1)
