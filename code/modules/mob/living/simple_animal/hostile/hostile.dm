/proc/emit_noise(atom/source, loudness)
	if(!source)
		return
	for(var/mob/living/simple_animal/hostile/H in range(loudness, source))
		if(!H.client && !H.stat)
			H.HearNoise(source, loudness)


/mob/living/simple_animal/hostile
	faction = "Demon"
	var/stance = HOSTILE_STANCE_IDLE
	var/mob/living/target_mob
	var/attack_same = FALSE
	var/ranged = FALSE
	var/rapid = FALSE
	var/projectiletype
	var/projectilesound
	var/casingtype
	var/move_to_delay = 3
	var/attack_delay = DEFAULT_QUICK_COOLDOWN
	var/fire_delay = DEFAULT_ATTACK_COOLDOWN
	var/list/friends = list()
	var/break_stuff_probability = 10
	stop_automated_movement_when_pulled = FALSE
	var/destroy_surroundings = TRUE
	a_intent = I_HURT
	var/armor_penetration = 0
	var/stance_step = 0
	var/tmp/stance_update_lock = FALSE

	var/shuttletarget = null
	var/enroute = FALSE
	environment_smash = 1

	var/damtype = BRUTE
	var/defense = "melee"

	var/vision_range = 10
	var/react_time = 8
	var/reacting_until = 0
	var/search_time = 10 SECONDS
	var/searching_until = 0
	var/atom/last_seen_loc = null
	var/fire_range = 5
	var/can_open_doors = TRUE
	var/can_break_doors = TRUE
	var/open_doors_idle = FALSE
	var/next_door_try = 0
	var/stuck_ticks = 0
	var/last_goal_dist = -1
	var/list/access_levels = list()
	var/alert_icon = 'icons/mob/alerts.dmi'
	var/image/current_alert = null
	var/atom/home_turf
	var/leash_radius = 0


/mob/living/simple_animal/hostile/New()
	..()
	home_turf = get_turf(src)

/mob/living/simple_animal/hostile/proc/get_access()
	return access_levels

/mob/living/simple_animal/hostile/death(gibbed, deathmessage, show_dead_message)
	..(gibbed, deathmessage, show_dead_message)
	walk(src, 0)
	target_mob = null
	searching_until = 0
	reacting_until = 0
	stuck_ticks = 0
	last_goal_dist = -1
	stance = HOSTILE_STANCE_IDLE // LEGACY
	stance_step = 0
	ClearAlert()

/mob/living/simple_animal/hostile/Life()
	. = ..()
	if(!.)
		walk(src, 0)
		return FALSE
	if(client)
		walk(src, 0)
		ClearAlert()
		return FALSE

	UpdateStance()

	switch(stance)
		if(HOSTILE_STANCE_IDLE)
			handle_idle()
		if(HOSTILE_STANCE_ATTACK)
			MoveToTarget()
		if(HOSTILE_STANCE_ATTACKING)
			stance_step++
			AttackTarget()

/mob/living/simple_animal/hostile/proc/IsLegacyStance()
	return (stance == HOSTILE_STANCE_ALERT || stance == HOSTILE_STANCE_TIRED)

/mob/living/simple_animal/hostile/proc/UpdateStance()
	if(IsLegacyStance())
		return

	if(leash_radius && home_turf && get_dist(src, home_turf) > leash_radius + 5)
		if(stance != HOSTILE_STANCE_IDLE)
			GoIdle()
		return

	if(target_mob && TargetInvalid(target_mob))
		LoseTarget()

	if(!target_mob || !CanSeeTarget(target_mob))
		ScanForTargets()
		if(IsLegacyStance())
			return

	if(!target_mob)
		if(searching_until > world.time)
			stance = HOSTILE_STANCE_ATTACK
		else if(stance != HOSTILE_STANCE_IDLE)
			GoIdle()
		return

	if(!CanSeeTarget(target_mob))
		if(!searching_until)
			searching_until = world.time + search_time
		if(world.time >= searching_until)
			GoIdle()
		else
			stance = HOSTILE_STANCE_ATTACK
		return

	last_seen_loc = get_turf(target_mob)
	searching_until = 0

	if(InAttackRange(target_mob))
		stance = HOSTILE_STANCE_ATTACKING
	else
		stance = HOSTILE_STANCE_ATTACK

/mob/living/simple_animal/hostile/proc/IsAggro()
	return (stance == HOSTILE_STANCE_ATTACK || stance == HOSTILE_STANCE_ATTACKING)

/mob/living/simple_animal/hostile/proc/handle_idle()
	stop_automated_movement = FALSE
	if(!is_far_from_home())
		return
	stop_automated_movement = TRUE
	if(get_dist(src, home_turf) > 1)
		walk_to(src, home_turf, 1, move_to_delay)
	else
		walk(src, 0)

/mob/living/simple_animal/hostile/proc/is_far_from_home()
	if(leash_radius && home_turf && get_dist(src, home_turf) > leash_radius)
		return TRUE
	return FALSE

/mob/living/simple_animal/hostile/Bump(atom/obstacle)
	. = ..()
	if(!can_open_doors || !istype(obstacle, /obj/machinery/door))
		return
	if(stance == HOSTILE_STANCE_IDLE && !open_doors_idle)
		return
	TryOpenDoor(obstacle, target_mob != null)

/mob/living/simple_animal/hostile/attackby(obj/item/O, mob/user)
	var/oldhealth = health
	. = ..()
	if(health < oldhealth)
		Retaliate(user)

/mob/living/simple_animal/hostile/attack_hand(mob/living/carbon/human/M)
	var/oldhealth = health
	. = ..()
	if(health < oldhealth)
		Retaliate(M)

/mob/living/simple_animal/hostile/bullet_act(obj/item/projectile/Proj)
	. = ..()
	if(Proj && Proj.firer)
		Retaliate(Proj.firer)

/mob/living/simple_animal/hostile/proc/Retaliate(mob/M)
	if(client || stat || incapacitated(INCAPACITATION_KNOCKOUT))
		return
	if(!IsValidTarget(M))
		return
	if(target_mob && !TargetInvalid(target_mob) && get_dist(src, target_mob) < get_dist(src, M))
		return
	SetTarget(M, TRUE)

/mob/living/simple_animal/hostile/proc/ShowAlert(alert_state, duration = 30)
	ClearAlert()
	var/image/I = image(alert_icon, src, alert_state)
	I.pixel_y = 28
	I.layer = FLY_LAYER
	current_alert = I
	overlays += I
	spawn(duration)
		if(QDELETED(src))
			return
		if(current_alert == I)
			ClearAlert()

/mob/living/simple_animal/hostile/proc/ClearAlert()
	if(current_alert)
		overlays -= current_alert
		current_alert = null

/mob/living/simple_animal/hostile/proc/ListTargets(dist)
	var/list/L = viewers(src, dist)
	for(var/obj/mecha/M in mechas_list)
		if(M.z == src.z && get_dist(src, M) <= dist)
			L += M
	return L

/mob/living/simple_animal/hostile/proc/CanSeeTarget(atom/target)
	if(!target || QDELETED(target))
		return FALSE
	if(ishuman(target))
		var/mob/living/carbon/human/H = target
		if(H.is_cloaked())
			return FALSE
	return can_see(src, target)

/mob/living/simple_animal/hostile/proc/IsValidTarget(atom/A)
	if(!A || A == src)
		return FALSE
	if(isliving(A))
		var/mob/living/L = A
		if(L.stat)
			return FALSE
		if(L.faction == faction && !attack_same)
			return FALSE
		if(friends && friends.len && (weakref(L) in friends))
			return FALSE
		if(ishuman(L))
			var/mob/living/carbon/human/H = L
			if(H.is_cloaked())
				return FALSE
		return TRUE
	if(istype(A, /obj/mecha))
		var/obj/mecha/M = A
		return M.occupant ? TRUE : FALSE
	return FALSE

/mob/living/simple_animal/hostile/proc/GetVisibleTarget()
	if(!faction)
		return null
	var/list/pool = list()
	for(var/atom/A in ListTargets(vision_range))
		if(IsValidTarget(A))
			pool += A

	while(pool.len)
		var/atom/nearest = null
		var/nearest_dist = INFINITY
		for(var/atom/A in pool)
			var/d = get_dist(src, A)
			if(d < nearest_dist)
				nearest = A
				nearest_dist = d
		pool -= nearest
		if(CanSeeTarget(nearest))
			return nearest
	return null

/mob/living/simple_animal/hostile/proc/FindTarget()
	return GetVisibleTarget()

/mob/living/simple_animal/hostile/proc/TargetInvalid(atom/T)
	if(!T || QDELETED(T))
		return TRUE
	if(istype(T, /obj/mecha))
		var/obj/mecha/M = T
		return !M.occupant
	return SA_attackable(T)

/mob/living/simple_animal/hostile/proc/ScanForTargets()
	var/atom/seen = FindTarget()
	if(seen)
		SetTarget(seen)

/mob/living/simple_animal/hostile/proc/HearNoise(atom/source, loudness)
	if(client || stat || !source || !faction)
		return
	if(target_mob || world.time < reacting_until)
		return
	if(get_dist(src, source) > loudness)
		return

	if(isliving(source) || istype(source, /obj/mecha))
		SetTarget(source, TRUE)
		return

	last_seen_loc = get_turf(source)
	searching_until = world.time + search_time
	ShowAlert("question", 20)
	walk_to(src, last_seen_loc, 1, move_to_delay)

/mob/living/simple_animal/hostile/proc/SetTarget(atom/new_target, instant = FALSE)
	if(!IsValidTarget(new_target))
		return FALSE

	var/retarget = (new_target != target_mob)
	target_mob = new_target
	last_seen_loc = get_turf(new_target)
	searching_until = 0

	if(retarget)
		GoAggro(instant)
	return TRUE

/mob/living/simple_animal/hostile/proc/GoAggro(instant = TRUE, silent = FALSE)
	if(stance == HOSTILE_STANCE_TIRED)
		return FALSE
	if(stance == HOSTILE_STANCE_ALERT)
		return FALSE

	var/from_idle = !IsAggro()
	stance = HOSTILE_STANCE_ATTACK
	reacting_until = 0
	walk(src, 0)
	if(!from_idle)
		return
	if(!silent)
		ShowAlert("exclamation", 25)
		AlertPack()
	if(!instant)
		reacting_until = world.time + react_time
		next_move = max(next_move, reacting_until)
	return TRUE

/mob/living/simple_animal/hostile/proc/GoIdle()
	stance = HOSTILE_STANCE_IDLE
	target_mob = null
	searching_until = 0
	reacting_until = 0
	last_seen_loc = null
	stuck_ticks = 0
	last_goal_dist = -1
	stance_step = 0
	walk(src, 0)
	stop_automated_movement = FALSE

/mob/living/simple_animal/hostile/proc/LoseTarget(var/legacy_chase_time = 0)
	if(!searching_until)
		searching_until = world.time + search_time
	target_mob = null

/mob/living/simple_animal/hostile/proc/AlertPack()
	if(!target_mob)
		return
	for(var/mob/living/simple_animal/hostile/H in range(vision_range, src))
		if(H == src || H.client || H.stat)
			continue
		if(H.faction != src.faction)
			continue
		if(H.IsAggro())
			continue
		if(!H.IsValidTarget(target_mob))
			continue
		H.target_mob = target_mob
		H.last_seen_loc = get_turf(target_mob)
		H.searching_until = 0
		H.GoAggro(TRUE, TRUE)

/mob/living/simple_animal/hostile/proc/HasDoorAccess(obj/machinery/door/D)
	if(istype(D, /obj/machinery/door/airlock))
		var/obj/machinery/door/airlock/A = D
		if(A.wires && !A.requiresID())
			return TRUE
	if(D.req_access && D.req_access.len)
		for(var/a in D.req_access)
			if(!(a in access_levels))
				return FALSE
	if(D.req_one_access && D.req_one_access.len)
		var/found = FALSE
		for(var/a in D.req_one_access)
			if(a in access_levels)
				found = TRUE
				break
		if(!found)
			return FALSE
	return TRUE

/mob/living/simple_animal/hostile/proc/TryOpenDoor(obj/machinery/door/D, allow_smash = TRUE)
	if(!istype(D) || !D.density || D.operating)
		return FALSE
	if(world.time < next_door_try)
		return FALSE
	next_door_try = world.time + 1 SECONDS

	if(HasDoorAccess(D))
		if(D.open(1))
			return TRUE

	if(allow_smash && can_break_doors && environment_smash && next_move <= world.time)
		next_move = world.time + attack_delay
		D.attack_generic(src, rand(melee_damage_lower, melee_damage_upper), attacktext)
		return TRUE
	return FALSE

/mob/living/simple_animal/hostile/proc/HandleDoorObstacles(atom/target, allow_smash = TRUE)
	if(!target || !can_open_doors)
		return FALSE
	var/dir_to = get_dir(src, target)
	if(!dir_to)
		return FALSE
	for(var/d in list(dir_to & (NORTH|SOUTH), dir_to & (EAST|WEST)))
		if(!d)
			continue
		var/turf/T = get_step(src, d)
		for(var/obj/machinery/door/D in T)
			if(TryOpenDoor(D, allow_smash))
				return TRUE
	return FALSE

/mob/living/simple_animal/hostile/proc/Found()
	return

/mob/living/simple_animal/hostile/proc/MoveToTarget()
	stop_automated_movement = TRUE

	if(world.time < reacting_until)
		walk(src, 0)
		return FALSE

	var/atom/goal = last_seen_loc
	if(target_mob && CanSeeTarget(target_mob))
		goal = target_mob
		last_seen_loc = get_turf(target_mob)

	if(!goal)
		walk(src, 0)
		return FALSE

	var/on_hunt = (target_mob != null)

	if(!on_hunt && get_dist(src, goal) <= 1)
		walk(src, 0)
		stuck_ticks = 0
		last_goal_dist = -1
		return FALSE

	walk_to(src, goal, 1, move_to_delay)
	HandleDoorObstacles(goal, on_hunt)
	if(on_hunt && destroy_surroundings)
		DestroySurroundings()
	HandleStuck(goal)
	return TRUE

/mob/living/simple_animal/hostile/proc/HandleStuck(atom/goal)
	if(!goal)
		return FALSE
	var/d = get_dist(src, goal)
	if(d < last_goal_dist)
		stuck_ticks = 0
	else
		stuck_ticks++
	last_goal_dist = d

	if(stuck_ticks < 5 || d <= 1)
		return FALSE

	stuck_ticks = 0
	last_goal_dist = -1
	var/goal_dir = get_dir(src, goal)
	if(!step(src, turn(goal_dir, 90)) && !step(src, turn(goal_dir, -90)))
		step(src, pick(GLOB.cardinal))
	return TRUE

/mob/living/simple_animal/hostile/proc/AttackTarget()
	stop_automated_movement = TRUE

	if(!target_mob)
		return FALSE

	if(world.time < reacting_until)
		walk(src, 0)
		return FALSE

	if(!InAttackRange(target_mob))
		walk_to(src, target_mob, 1, move_to_delay)
		HandleDoorObstacles(target_mob, TRUE)
		return FALSE

	walk(src, 0)

	if(destroy_surroundings)
		DestroySurroundings()

	if(next_move > world.time)
		return FALSE

	last_seen_loc = get_turf(target_mob)

	if(get_dist(src, target_mob) == 1 && melee_damage_upper > 0)
		AttackingTarget()
		next_move = world.time + attack_delay
		return TRUE

	if(ranged)
		OpenFire(target_mob)
		return TRUE

	return FALSE

/mob/living/simple_animal/hostile/proc/InAttackRange(atom/T)
	if(!T || QDELETED(T))
		return FALSE
	if(ranged)
		if(get_dist(src, T) > fire_range)
			return FALSE
		return HasLineOfFire(T)
	return get_dist(src, T) <= 1

/mob/living/simple_animal/hostile/proc/AttackingTarget()
	if(!Adjacent(target_mob))
		return FALSE

	var/damage = rand(melee_damage_lower, melee_damage_upper)
	var/atom/A = target_mob

	if(isliving(A))
		var/mob/living/L = A
		var/def_zone = pick(BP_HEAD, BP_CHEST, BP_L_HAND, BP_R_HAND, BP_L_LEG, BP_R_LEG)
		L.resolve_generic_attack(src, damage, damtype, def_zone, defense, armor_penetration, attacktext, attack_sound)
		return L

	if(istype(A, /obj/mecha))
		var/obj/mecha/M = A
		M.attack_generic(src, damage, attacktext)
		return M

	return FALSE

/mob/living/simple_animal/hostile/proc/OpenFire(atom/target_atom)
	if(!target_atom || QDELETED(target_atom) || stat || client)
		return FALSE

	next_move = world.time + fire_delay
	emit_noise(src, 10)

	if(rapid)
		spawn(1)
			TryShoot(target_atom)
		spawn(4)
			TryShoot(target_atom)
		spawn(6)
			TryShoot(target_atom)
	else
		TryShoot(target_atom)
	return TRUE

/mob/living/simple_animal/hostile/proc/TryShoot(atom/target_atom)
	if(QDELETED(src) || QDELETED(target_atom) || !target_atom || stat || client)
		return FALSE
	if(!HasLineOfFire(target_atom))
		return FALSE
	Shoot(target_atom, src.loc, src)
	if(casingtype)
		new casingtype(get_turf(src))
	return TRUE

/mob/living/simple_animal/hostile/proc/Shoot(target, start, user, bullet = 0)
	if(!target || target == start || !projectiletype)
		return

	var/obj/item/projectile/A = new projectiletype(get_turf(start))
	if(!A)
		return
	if(projectilesound)
		playsound(user, projectilesound, 100, TRUE)
	A.launch_projectile(target, get_exposed_defense_zone(target))

/mob/living/simple_animal/hostile/proc/DestroySurroundings()
	if(!prob(break_stuff_probability))
		return
	for(var/dir in shuffle(GLOB.cardinal))
		var/turf/T = get_step(src, dir)
		if(!T)
			continue
		var/obj/effect/shield/S = locate(/obj/effect/shield, T)
		if(S && S.gen && S.gen.check_flag(MODEFLAG_NONHUMANS))
			S.attack_generic(src, rand(melee_damage_lower, melee_damage_upper), attacktext)
			return
		for(var/obj/structure/window/obstacle in T)
			if(obstacle.dir == GLOB.reverse_dir[dir])
				obstacle.attack_generic(src, rand(melee_damage_lower, melee_damage_upper), attacktext)
				return
		var/obj/structure/found = null
		for(var/obj/structure/O in T)
			if(istype(O, /obj/structure/window) || istype(O, /obj/structure/closet) || istype(O, /obj/structure/table) || istype(O, /obj/structure/grille))
				found = O
				break
		if(found)
			found.attack_generic(src, rand(melee_damage_lower, melee_damage_upper), attacktext)
			return

/mob/living/simple_animal/hostile/proc/TurfBlocksShot(turf/T)
	if(!T)
		return TRUE
	if(T.density || T.opacity)
		return TRUE
	for(var/obj/O in T)
		if((O.opacity || O.density) && istype(O, /obj/structure))
			return TRUE
	return FALSE

/mob/living/simple_animal/hostile/proc/HasLineOfFire(atom/target)
	var/turf/start = get_turf(src)
	var/turf/goal = get_turf(target)
	if(!start || !goal || start.z != goal.z)
		return FALSE
	if(start == goal)
		return TRUE

	var/dx = goal.x - start.x
	var/dy = goal.y - start.y
	var/steps = max(abs(dx), abs(dy)) * 4
	var/last = start
	for(var/i = 1 to steps)
		var/turf/T = locate(start.x + round(dx * i / steps), start.y + round(dy * i / steps), start.z)
		if(!T)
			return FALSE
		if(T == goal)
			return TRUE
		if(T == last)
			continue
		if(TurfBlocksShot(T))
			return FALSE
		last = T
	return TRUE