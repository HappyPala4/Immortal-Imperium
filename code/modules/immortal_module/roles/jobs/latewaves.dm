GLOBAL_LIST_INIT(latewave_available, list(
	/datum/latewave/ork = 10,
	/datum/latewave/tau = 10,
	/datum/latewave/kroot = 10,
	/datum/latewave/chaos = 10,
	/datum/latewave/genestealer = 10
))

/datum/latewave
	var/wave_id = 0

	var/name = "Default"

	var/list/roles = list()

	var/need_anounce = FALSE
	var/announce_message = ""
	var/afterspawn_message = ""
	var/description = ""
	var/crate_type = /obj/structure/closet/crate
	var/list/equipment = list()

	var/area/latewave/assigned_area



/datum/latewave/New()
	. = ..()

	select_spawn_area()
	spawn_equipment()

	if(need_anounce)
		threat_announcement.Announce(announce_message, "Important announcement")

	update_roles()
	generate_roles()

/datum/latewave/Destroy()
	if(assigned_area)
		assigned_area.occupied = FALSE
		assigned_area = null
	. = ..()

/datum/latewave/proc/update_roles()
	return

/datum/latewave/proc/select_spawn_area()
    var/list/area/latewave/all_latewave_areas = list()
    var/list/area/latewave/free_areas = list()

    for(var/area/latewave/A in world)
        // Игнорируем базовый родительский тип, если он случайно размещен на карте
        if(A.type == /area/latewave)
            continue

        all_latewave_areas += A
        if(!A.occupied)
            free_areas += A

    if(free_areas.len)
        assigned_area = pick(free_areas)
    else if(all_latewave_areas.len)
        assigned_area = pick(all_latewave_areas)

    if(assigned_area)
        assigned_area.occupied = TRUE

/datum/latewave/proc/spawn_equipment()
	if(!assigned_area || !equipment.len)
		return

	var/list/obj/effect/landmark/latewave_equipment/eq_landmarks = list()

	for(var/obj/effect/landmark/latewave_equipment/L in world)
		if(get_area(L) == assigned_area)
			eq_landmarks += L

	if(!eq_landmarks.len)
		return

	var/obj/effect/landmark/latewave_equipment/chosen_landmark = pick(eq_landmarks)
	var/turf/spawn_turf = get_turf(chosen_landmark)

	if(!spawn_turf)
		return

	var/obj/structure/closet/crate/C = new crate_type(spawn_turf)

	for(var/item_path in equipment)
		var/amount = equipment[item_path] || 1
		for(var/i in 1 to amount)
			new item_path(C)

/datum/latewave/proc/get_spawn_turfs()
	var/list/return_list = list()

	if(assigned_area)
		for(var/obj/effect/landmark/start/latewaves/L in world)
			if(get_area(L) == assigned_area)
				return_list += get_turf(L)

	// Если в зоне нету спавна поиск по миру
	if(!return_list.len)
		for(var/obj/effect/landmark/start/latewaves/L in world)
			return_list += get_turf(L)

	if(!return_list.len)
		return null

	return pick(return_list)

/datum/latewave/proc/generate_roles()
	var/list/new_roles = list()

	for(var/role_type in roles)
		var/datum/latewave_role/R = new role_type(roles[role_type]) // Указываем количество ролей в latewave
		new_roles += list(R)

	roles.Cut()
	roles = new_roles

// ==================== External use ====================

/// Returns a role by its unique ID.
/datum/latewave/proc/get_role(role_id)
	if(!role_id)
		return null

	for(var/datum/latewave_role/role in roles)
		if(role.id == role_id)
			return role

	return null


/// Returns TRUE if at least one role still has available slots.
/datum/latewave/proc/has_available_slots()
	for(var/datum/latewave_role/role in roles)
		if(role.has_slots())
			return TRUE

	return FALSE


/// Returns a list of roles that can still be joined.
/datum/latewave/proc/get_available_roles()
	var/list/available_roles = list()

	for(var/datum/latewave_role/role as anything in roles)
		if(role.has_slots())
			available_roles += role

	return available_roles


/// Returns serialized wave data for UI.
/datum/latewave/proc/get_ui_data()
	var/list/role_data = list()

	for(var/datum/latewave_role/role as anything in roles)
		role_data += list(role.get_ui_data())

	return list(
		"id" = wave_id,
		"name" = name,
		"announce" = need_anounce,
		"announce_message" = announce_message,
		"description" = description,
		"available" = has_available_slots(),
		"roles" = role_data
	)


/// Attempts to spawn a player into the selected role.
/datum/latewave/proc/handle_spawn(mob/new_player/user, role_id)
	if(!user || !user.key)
		return FALSE

	var/datum/latewave_role/role = get_role(role_id)

	if(!role || !role.has_slots())
		return FALSE

	var/turf/spawn_turf = get_spawn_turfs()

	if(!spawn_turf)
		return FALSE

	var/mob/living/carbon/human/H = new role.mob_type(spawn_turf)

	if(!H)
		return FALSE

	if(!role.take_slot())
		qdel(H)
		return FALSE

	if(afterspawn_message)
		to_chat(H, afterspawn_message)

	user.close_spawn_windows()

	H.key = user.key

	qdel(user)

	if(!has_available_slots())
		qdel(src)
	else
		SSlatewaves.update_waves()

	return TRUE

/datum/latewave/ork
	name = "Orkz warband"
	need_anounce = TRUE
	announce_message = "Сообщение от гарнизона. Недалеко от улья упали осколки булыги, ожидайте вторжение орков"
	roles = list(
		/datum/latewave_role/ork = 5
	)


/datum/latewave/tau
	name = "Tau"
	need_anounce = TRUE
	announce_message = "Сообщение от гарнизона СПО. Воздушное пространство вблизи города улья нарушило неизвестное космическое судно. \
	Предположительно вторжение противника"
	roles = list(
		/datum/latewave_role/tau = 5
	)


/datum/latewave/kroot
	name = "Kroots"
	need_anounce = TRUE
	announce_message = "Сообщение от гарнизона СПО. Воздушное пространство вблизи города улья нарушило неизвестное космическое судно малого размера. \
	Предположительно вторжение противника"
	roles = list(
		/datum/latewave_role/kroot = 5
	)


/datum/latewave/chaos
	name = "Chaos followers"
	need_anounce = TRUE
	announce_message = "Недалеко от улья силами гарнизона был замечен БТР неизвестного происхождения. Возможно нападение."
	roles = list(
		/datum/latewave_role/chaos = 5
	)
	equipment = list(
		/obj/item/gun/energy/las/lasgun = 3,
		/obj/item/cell/lasgun = 6,
		/obj/item/gun/projectile/automatic/agripinaaii = 2,
		/obj/item/ammo_magazine/c556 = 4,
		/obj/item/clothing/head/helmet/guardhelmet/enforcer/arbitrator/bloodpact2 = 5,
		/obj/item/clothing/suit/armor/guardsman/bloodpact = 5,
		/obj/item/storage/belt/medical/full = 2,
		/obj/item/storage/toolbox/mechanical = 1,
		/obj/item/plastique = 2,
		/obj/item/shovel = 2,
		/obj/item/mortar_launcher/chaos = 1,
		/obj/item/mortar_shell/gas = 3,
		/obj/item/mortar_shell/frag = 5,
		/obj/item/mortar_shell/smoke = 2,
		/obj/item/device/binoculars = 1
	)


/datum/latewave/genestealer
	name = "Genestealers"
	need_anounce = FALSE
	roles = list(
		/datum/latewave_role/genestealer = 3
	)

// ==================== ROLE DATUM ====================

/datum/latewave_role
	var/id = "unknown"
	var/name = "Unknown"
	var/description = ""
	var/mob_type
	var/max_slots = 0
	var/remaining_slots = 0


/datum/latewave_role/New(slots)
	. = ..()
	if(slots)
		max_slots = slots
	remaining_slots = max_slots


/datum/latewave_role/proc/has_slots()
	return remaining_slots > 0


/datum/latewave_role/proc/take_slot()
	if(remaining_slots <= 0)
		return FALSE

	remaining_slots--
	return TRUE


// ==================== External use ====================

/// Returns serialized role data for UI.
/datum/latewave_role/proc/get_ui_data()
	return list(
		"id" = id,
		"name" = name,
		"description" = description,
		"max_slots" = max_slots,
		"remaining_slots" = remaining_slots,
		"available" = has_slots()
	)


// ==================== READY ROLES ====================

/datum/latewave_role/ork
	id = "ork"
	name = "Ork"
	description = "Join the Orkz warband."
	mob_type = /mob/living/carbon/human/ork
	max_slots = 5


/datum/latewave_role/tau
	id = "tau"
	name = "Tau"
	description = "Join the Tau forces."
	mob_type = /mob/living/carbon/human/tau
	max_slots = 5


/datum/latewave_role/kroot
	id = "kroot"
	name = "Kroot"
	description = "Join the Kroot warband."
	mob_type = /mob/living/carbon/human/kroot
	max_slots = 5


/datum/latewave_role/chaos
	id = "chaos"
	name = "Chaos follower"
	description = "Join the forces of Chaos."
	mob_type = /mob/living/carbon/human/Bloodpact
	max_slots = 5


/datum/latewave_role/genestealer
	id = "genestealer"
	name = "Genestealer"
	description = "Join the Genestealer infestation."
	mob_type = /mob/living/carbon/human/genestealer
	max_slots = 3

/obj/effect/landmark/start/latewaves
	name = "latewave"

/obj/effect/landmark/latewave_equipment
	name = "equipment"

/area/latewave
	name = "latewave"
	var/occupied = FALSE

/area/latewave/variant_1

/area/latewave/variant_2

/area/latewave/variant_3

/area/latewave/variant_4

/area/latewave/variant_5