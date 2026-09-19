
/obj/machinery/gibber
	name = "meat grinder"
	desc = "The name isn't descriptive enough?"
	icon = 'icons/obj/kitchen.dmi'
	icon_state = "grinder"
	density = 1
	anchored = 1
	req_access = list(access_kitchen,access_village)

	var/operating = 0        //Is it on?
	var/dirty = 0            // Does it need cleaning?
	var/mob/living/occupant  // Mob who has been put inside
	var/obj/item/processing_item
	var/obj/machinery/mineral/input/input
	var/obj/machinery/mineral/output/output
	var/material_amount = 0
	var/batch_poisoned = 0
	var/gib_time = 40        // Time from starting until meat appears
	var/gib_throw_dir = WEST // Direction to spit meat and gibs in.

	use_power = 1
	idle_power_usage = 2
	active_power_usage = 500

// Automatically processes eligible material delivered to its input plate.
/obj/machinery/gibber/autogibber


/obj/machinery/gibber/Initialize()
	. = ..()
	for(var/i in GLOB.cardinal)
		if(!input)
			input = locate(/obj/machinery/mineral/input, get_step(src.loc, i))
		if(!output)
			output = locate(/obj/machinery/mineral/output, get_step(src.loc, i))
	update_icon()

/obj/machinery/gibber/Process()
	if(!input || !output || operating || occupant || processing_item)
		return
	produce_output()
	if(get_output_count() >= 3)
		return

	for(var/mob/living/M in input.loc)
		if(istype(M, /mob/living/carbon) || istype(M, /mob/living/simple_animal))
			M.forceMove(src)
			occupant = M
			startgibbing()
			return

	for(var/obj/item/reagent_containers/food/snacks/meat/meat in input.loc)
		processing_item = meat
		meat.forceMove(src)
		startgibbing()
		return

/obj/machinery/gibber/proc/get_output_count()
	if(!output)
		return 3
	var/count = 0
	for(var/obj/item/reagent_containers/food/snacks/corpsestarch/bar in output.loc)
		count++
	return count

/obj/machinery/gibber/proc/can_accept_material()
	return output && get_output_count() < 3

/obj/machinery/gibber/proc/produce_output()
	if(!output)
		return
	var/available = 3 - get_output_count()
	while(material_amount >= 1 && available > 0)
		var/obj/item/reagent_containers/food/snacks/corpsestarch/bar = new(output.loc)
		if(batch_poisoned)
			bar.reagents.add_reagent(/datum/reagent/toxin, 10)
		material_amount -= 1
		available--
	if(material_amount < 0.01)
		material_amount = 0
	if(!material_amount)
		batch_poisoned = 0

/obj/machinery/gibber/update_icon()
	overlays.Cut()
	if (dirty)
		src.overlays += image('icons/obj/kitchen.dmi', "grbloody")
	if(stat & (NOPOWER|BROKEN))
		return
	if (!occupant && !processing_item)
		src.overlays += image('icons/obj/kitchen.dmi', "grjam")
	else if (operating)
		src.overlays += image('icons/obj/kitchen.dmi', "gruse")
	else
		src.overlays += image('icons/obj/kitchen.dmi', "gridle")

/obj/machinery/gibber/relaymove(mob/user as mob)
	src.go_out()
	return

/obj/machinery/gibber/attack_hand(mob/user as mob)
	if(stat & (NOPOWER|BROKEN))
		return
	if(operating)
		to_chat(user, "<span class='danger'>\The [src] is locked and running, wait for it to finish.</span>")
		return
	else
		src.startgibbing(user)

/obj/machinery/gibber/examine()
	. = ..()
	to_chat(usr, "The safety guard is disabled.")

/obj/machinery/gibber/attackby(var/obj/item/W, var/mob/user)
	if(istype(W, /obj/item/grab))
		var/obj/item/grab/G = W
		if(!G.force_danger())
			to_chat(user, "<span class='danger'>You need a better grip to do that!</span>")
			return
		move_into_gibber(user,G.affecting)
		user.drop_from_inventory(G)
	else if(istype(W, /obj/item/organ))
		return ..()
	else
		return ..()

/obj/machinery/gibber/MouseDrop_T(mob/target, mob/user)
	if(user.stat || user.restrained())
		return
	move_into_gibber(user,target)

/obj/machinery/gibber/proc/move_into_gibber(var/mob/user,var/mob/living/victim)

	if(!can_accept_material())
		to_chat(user, "<span class='danger'>\The [src] cannot accept more material until its output is cleared.</span>")
		return

	if(src.occupant)
		to_chat(user, "<span class='danger'>\The [src] is full, empty it first!</span>")
		return

	if(operating)
		to_chat(user, "<span class='danger'>\The [src] is locked and running, wait for it to finish.</span>")
		return

	if(!(istype(victim, /mob/living/carbon)) && !(istype(victim, /mob/living/simple_animal)) )
		to_chat(user, "<span class='danger'>This is not suitable for \the [src]!</span>")
		return

	if(victim.abiotic(1))
		to_chat(user, "<span class='danger'>\The [victim] may not have any abiotic items on.</span>")
		return

	user.visible_message("<span class='danger'>\The [user] starts to put \the [victim] into \the [src]!</span>")
	src.add_fingerprint(user)
	if(do_after(user, 30, src) && victim.Adjacent(src) && user.Adjacent(src) && victim.Adjacent(user) && !occupant)
		user.visible_message("<span class='danger'>\The [user] stuffs \the [victim] into \the [src]!</span>")
		if(victim.client)
			victim.client.perspective = EYE_PERSPECTIVE
			victim.client.eye = src
		victim.forceMove(src)
		src.occupant = victim
		update_icon()

/obj/machinery/gibber/proc/eject()
	set category = "Object"
	set name = "Empty Gibber"

	if (usr.stat != 0)
		return
	src.go_out()
	add_fingerprint(usr)
	return

/obj/machinery/gibber/RightClick(mob/user)
	if(CanPhysicallyInteract(user))
		eject()

/obj/machinery/gibber/proc/go_out()
	if(operating || !src.occupant)
		return
	for(var/obj/O in src)
		O.dropInto(loc)
	if (src.occupant.client)
		src.occupant.client.eye = src.occupant.client.mob
		src.occupant.client.perspective = MOB_PERSPECTIVE
	src.occupant.dropInto(loc)
	src.occupant = null
	update_icon()
	return

/obj/machinery/gibber/proc/startgibbing(mob/user as mob)
	if(src.operating)
		return
	if(!src.occupant && !processing_item)
		visible_message("<span class='danger'>You hear a loud metallic grinding sound.</span>")
		return
	if(!can_accept_material())
		return

	use_power(1000)
	visible_message("<span class='danger'>You hear a loud [occupant && occupant.isSynthetic() ? "metallic" : "squelchy"] grinding sound.</span>")
	src.operating = 1
	update_icon()

	var/material_yield = 0
	if(occupant)
		material_yield = istype(occupant, /mob/living/simple_animal) ? 0.75 : 2
		if(istype(occupant, /mob/living/carbon/human))
			var/mob/living/carbon/human/H = occupant
			if(H.decaylevel >= 3 && prob(50))
				batch_poisoned = 1
	else
		material_yield = 0.25
	material_amount += material_yield

	if(user && occupant)
		admin_attack_log(user, occupant, "Gibbed the victim", "Was gibbed", "gibbed")
	if(occupant)
		occupant.ghostize()

	spawn(gib_time)

		if(occupant)
			for(var/atom/movable/content in occupant.contents)
				qdel(content)
			qdel(occupant)
			occupant = null
		if(processing_item)
			qdel(processing_item)
			processing_item = null

		playsound(src.loc, 'sound/effects/splat.ogg', 50, 1)
		produce_output()
		operating = 0
		update_icon()


