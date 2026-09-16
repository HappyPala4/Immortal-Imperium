//##############################################################################
//###### MARKET RANDOM ENCOUNTERS / EVENTS #####################################
//### Three event types can strike the market:                                ##
//###  1) A burst promethium gas pipe (PG gas futures)                        ##
//###  2) A burning promethium pump (PR raw futures)                          ##
//###  3) An ambushed gold convoy (Au futures)                                ##
//### One event may be active at a time. Every 5 minutes the market rolls a   ##
//### 5% chance (+5% per miss, reset on success). If the event is not         ##
//### resolved in time, the affected commodity gets a forced negative trend.  ##
//##############################################################################

// --- LANDMARKS (place one of each on the map) ---

/obj/effect/landmark/market_event
	name = "Market event point"
	desc = "A spawn point for random market events."
	var/event_slot = ""		// "pipe", "pump", "convoy" or "governor"

/obj/effect/landmark/market_event/pipe
	name = "Event point: burst gas pipe"
	event_slot = "pipe"

/obj/effect/landmark/market_event/pump
	name = "Event point: burning pump"
	event_slot = "pump"

/obj/effect/landmark/market_event/convoy
	name = "Event point: ambushed convoy"
	event_slot = "convoy"

/obj/effect/landmark/market_event/governor
	name = "Governor delivery point"
	event_slot = "governor"

// --- BASE EVENT DATUM ---

/datum/market_event
	var/name = "Unknown event"
	var/ticker_tag = ""				// commodity affected if the event fails
	var/resolve_minutes = 0			// time limit to resolve the event
	var/neg_minutes_min = 0			// forced negative trend duration (min)
	var/neg_minutes_max = 0
	var/spawned_time = 0
	var/resolved = FALSE
	var/datum/market/market = null
	var/list/event_mobs = list()	// hostile mobs cleaned up at the end

/datum/market_event/proc/start_event(var/turf/T)
	spawned_time = world.time
	return T

/datum/market_event/proc/announce_start(var/turf/T)
	var/area/A = get_area(T)
	var/areastr = A && A.name ? A.name : "unknown area"
	for(var/mob/M in world)
		if(M.client)
			to_chat(M, "<span class='danger'>Market event: <B>[name]</B> in [areastr]. Resolve it before the market suffers!</span>")

/datum/market_event/proc/fail()
	if(resolved)
		return
	resolved = TRUE
	var/datum/market_position/P = market ? market.get_position_by_ticker(ticker_tag) : null
	if(P)
		var/duration = rand(neg_minutes_min, neg_minutes_max)
		P.force_trend(-1, duration)
		for(var/mob/M in world)
			if(M.client)
				to_chat(M, "<span class='danger'>Market: [name] failed! [P.name] will be pushed down for [duration] minutes.</span>")
	else
		for(var/mob/M in world)
			if(M.client)
				to_chat(M, "<span class='danger'>Market: [name] failed!</span>")
	finish_event()

/datum/market_event/proc/succeed()
	if(resolved)
		return
	resolved = TRUE
	for(var/mob/M in world)
		if(M.client)
			to_chat(M, "<span class='notice'>Market: [name] resolved. No market impact.</span>")
	finish_event()

/datum/market_event/proc/finish_event()
	for(var/mob/living/L in event_mobs)
		if(L && L.stat != DEAD)
			qdel(L)
	event_mobs.Cut()
	if(market && market.active_event == src)
		market.active_event = null

/datum/market_event/proc/spawn_guards_at(var/turf/T, var/n, var/guard_type)
	for(var/i = 1, i <= n, i++)
		var/turf/ST = get_step(T, pick(GLOB.alldirs))
		if(!ST || ST.density)
			ST = T
		var/mob/G = new guard_type(ST)
		if(G)
			event_mobs += G

// --- EVENT 1: BURST PROMETHIUM GAS PIPE ---

/datum/market_event/broken_pipe
	name = "Burst promethium pipe"
	ticker_tag = "PG"
	resolve_minutes = 6
	neg_minutes_min = 5
	neg_minutes_max = 10

/datum/market_event/broken_pipe/start_event(var/turf/T)
	..()
	var/obj/structure/market_pipe/P = new /obj/structure/market_pipe(T)
	P.my_event = src
	P.gas_loop()
	return T

/obj/structure/market_pipe
	name = "Burst promethium pipe"
	desc = "A ruptured pipe leaking promethium gas. Use a WRENCH to shut the valve, wait for the gas to dissipate, then WELD the crack shut. Welding it while it still leaks will ignite the gas!"
	icon = 'icons/atmos/pipes.dmi'
	icon_state = "pipe-s"
	anchored = 1
	density = 0
	layer = ABOVE_OBJ_LAYER
	var/datum/market_event/broken_pipe/my_event = null
	var/shut_off = FALSE
	var/safe_to_weld = FALSE

/obj/structure/market_pipe/proc/gas_loop()
	if(QDELETED(src))
		return
	if(!my_event || my_event.resolved || safe_to_weld)
		return
	if(!shut_off)
		var/datum/effect/effect/system/smoke_spread/S = new /datum/effect/effect/system/smoke_spread()
		S.set_up(6, 1, src.loc)
		S.start()
		for(var/mob/living/M in range(3, src))
			if(M.stat != DEAD)
				if(ishuman(M))
					var/mob/living/carbon/human/H = M
					if(H.wear_mask && (H.wear_mask.item_flags & ITEM_FLAG_AIRTIGHT))
						continue
					if(H.head && (H.head.item_flags & ITEM_FLAG_AIRTIGHT))
						continue
				M.apply_damage(3, TOX)
				to_chat(M, "<span class='warning'>The promethium gas burns your lungs!</span>")
	addtimer(CALLBACK(src, .proc/gas_loop), 4 SECONDS)

/obj/structure/market_pipe/proc/dissipate()
	if(QDELETED(src) || !shut_off)
		return
	safe_to_weld = TRUE
	visible_message("<span class='notice'>The remaining promethium gas dissipates. The crack can now be welded shut.</span>")

/obj/structure/market_pipe/attackby(var/obj/item/W, var/mob/user)
	if(isWrench(W))
		if(shut_off)
			to_chat(user, "<span class='warning'>The valve is already closed.</span>")
			return 1
		shut_off = TRUE
		playsound(src, 'sound/items/Ratchet.ogg', 50, 1)
		visible_message("<span class='notice'>[user] shuts off the gas valve with the wrench. The gas will dissipate soon.</span>")
		addtimer(CALLBACK(src, .proc/dissipate), 3 MINUTES)
		return 1
	if(isWelder(W))
		if(!shut_off)
			visible_message("<span class='danger'>[user] welds the leaking pipe! The promethium gas ignites in a massive explosion!</span>")
			explosion(get_turf(src), 0, 1, 2, 3)
			if(my_event)
				my_event.fail()
			qdel(src)
			return 1
		if(!safe_to_weld)
			to_chat(user, "<span class='warning'>The gas has not dissipated yet. Wait until it is safe to weld.</span>")
			return 1
		visible_message("<span class='notice'>[user] seals the crack with the welder. The leak is repaired.</span>")
		if(my_event)
			my_event.succeed()
		qdel(src)
		return 1
	return ..()

// --- EVENT 2: BURNING PROMETHIUM PUMP ---

/datum/market_event/burning_pump
	name = "Burning promethium pump"
	ticker_tag = "PR"
	resolve_minutes = 5
	neg_minutes_min = 7
	neg_minutes_max = 11

/datum/market_event/burning_pump/start_event(var/turf/T)
	..()
	var/obj/structure/market_pump/P = new /obj/structure/market_pump(T)
	P.my_event = src
	P.fire_loop()
	P.spawn_visual()
	spawn_guards_at(T, 3, /mob/living/simple_animal/hostile/syndicate/ranged)
	return T

/datum/market_event/burning_pump/proc/check_guards()
	if(resolved)
		return
	for(var/mob/living/L in event_mobs)
		if(L && L.stat != DEAD)
			return
	succeed()

/obj/structure/market_pump
	name = "Burning promethium pump"
	desc = "A promethium pump engulfed in flames. Put the fire out with a fire EXTINGUISHER, then deal with the attackers."
	icon = 'icons/atmos/pump.dmi'
	icon_state = "map_on"
	anchored = 1
	density = 0
	layer = ABOVE_OBJ_LAYER
	var/datum/market_event/burning_pump/my_event = null
	var/extinguished = FALSE
	var/obj/effect/market_fire/fire_visual = null

/obj/structure/market_pump/proc/fire_loop()
	if(QDELETED(src))
		return
	if(!my_event || my_event.resolved || extinguished)
		return
	for(var/mob/living/M in range(2, src))
		if(M.stat != DEAD)
			M.apply_damage(4, BURN)
			to_chat(M, "<span class='warning'>The pump fire burns you!</span>")
	addtimer(CALLBACK(src, .proc/fire_loop), 3 SECONDS)

/obj/structure/market_pump/proc/spawn_visual()
	if(QDELETED(src) || !my_event || my_event.resolved || extinguished)
		return
	fire_visual = new /obj/effect/market_fire(src.loc)

/obj/structure/market_pump/proc/update_visuals()
	if(extinguished)
		if(fire_visual)
			qdel(fire_visual)
			fire_visual = null
		icon_state = "map_off"

/obj/structure/market_pump/attackby(var/obj/item/W, var/mob/user)
	if(istype(W, /obj/item/extinguisher))
		if(extinguished)
			to_chat(user, "<span class='warning'>The fire is already out.</span>")
			return 1
		extinguished = TRUE
		playsound(src, 'sound/effects/spray.ogg', 50, 1)
		visible_message("<span class='notice'>[user] douses the pump fire with the extinguisher.</span>")
		update_visuals()
		if(my_event && !my_event.resolved)
			my_event.check_guards()
		return 1
	return ..()

/obj/structure/market_pump/examine(var/mob/user)
	..()
	if(extinguished)
		to_chat(user, "<span class='notice'>The fire is out, but the attackers are still around!</span>")
	else
		to_chat(user, "<span class='warning'>It is on fire! Use a fire extinguisher on it, then kill the attackers.</span>")

/obj/effect/market_fire
	name = "Fire"
	desc = "Intense flames."
	icon = 'icons/effects/fire.dmi'
	icon_state = "3"
	anchored = 1
	density = 0
	layer = FIRE_LAYER
	mouse_opacity = 0
	light_color = "#ed9200"

/obj/effect/market_fire/New()
	..()
	set_light(4, 2, "#ed9200")

// --- EVENT 3: AMBUSHED GOLD CONVOY ---

/datum/market_event/ambushed_convoy
	name = "Ambushed gold convoy"
	ticker_tag = "Au"
	resolve_minutes = 10
	neg_minutes_min = 10
	neg_minutes_max = 15

/datum/market_event/ambushed_convoy/start_event(var/turf/T)
	..()
	new /obj/structure/closet/crate/market_convoy_wreck(T)
	new /obj/item/stack/material/gold/fifty(get_step(T, pick(GLOB.alldirs)))
	new /obj/item/stack/material/gold/fifty(get_step(T, pick(GLOB.alldirs)))
	spawn_guards_at(T, 2, /mob/living/simple_animal/hostile/syndicate/ranged)
	spawn_guards_at(T, 2, /mob/living/simple_animal/hostile/syndicate/ranged/space)
	if(!locate(/obj/structure/closet/crate/market_gold_delivery) in world)
		var/turf/GT = null
		if(market)
			var/obj/effect/landmark/market_event/G = market.find_event_landmark("governor")
			if(G)
				GT = get_turf(G)
		if(!GT)
			GT = get_step(T, pick(GLOB.alldirs))
			if(!GT)
				GT = T
		new /obj/structure/closet/crate/market_gold_delivery(GT)
	return T

/obj/structure/closet/crate/market_convoy_wreck
	name = "Shot-up cargo truck"
	desc = "A bullet-riddled cargo truck from the ambushed convoy. The gold shipment is scattered nearby."

/obj/structure/closet/crate/market_gold_delivery
	name = "Governor gold delivery crate"
	desc = "A reinforced delivery crate for the planetary governor. Deposit the salvaged convoy gold here."
	var/gold_required = 100
	var/gold_stored = 0

/obj/structure/closet/crate/market_gold_delivery/attackby(var/obj/item/O, var/mob/user)
	if(istype(O, /obj/item/stack/material/gold))
		var/obj/item/stack/material/gold/G = O
		var/need = max(0, gold_required - gold_stored)
		var/placing = min(G.amount, need)
		gold_stored += placing
		G.amount -= placing
		to_chat(user, "<span class='notice'>You deposit [placing] gold. Delivery: [gold_stored]/[gold_required].</span>")
		if(G.amount <= 0)
			qdel(G)
		else
			G.update_icon()
		if(gold_stored >= gold_required)
			var/datum/market/M = get_market()
			if(istype(M.active_event, /datum/market_event/ambushed_convoy))
				var/datum/market_event/ambushed_convoy/E = M.active_event
				E.succeed()
		return 1
	return ..()

/obj/structure/closet/crate/market_gold_delivery/examine(var/mob/user)
	..()
	to_chat(user, "<span class='notice'>Gold stored: [gold_stored] / [gold_required].</span>")