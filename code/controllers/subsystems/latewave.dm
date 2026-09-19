#define LATEWAVE_SPAWN_INTERVAL (25 MINUTES)

SUBSYSTEM_DEF(latewaves)
	name = "latewaves"
	flags = SS_NO_TICK_CHECK | SS_NO_FIRE

	var/list/waves = list()
	var/next_wave_id = 0


/datum/controller/subsystem/latewaves/Initialize(start_timeofday)
	addtimer(
		CALLBACK(src, PROC_REF(try_spawn_wave)),
		LATEWAVE_SPAWN_INTERVAL
	)

	. = ..()


/datum/controller/subsystem/latewaves/proc/try_spawn_wave(wave_type)
	if(!wave_type)
		wave_type = pickweight(GLOB.latewave_available)

	add_new_wave(wave_type)
	addtimer(
		CALLBACK(src, PROC_REF(try_spawn_wave)),
		LATEWAVE_SPAWN_INTERVAL
		)


/datum/controller/subsystem/latewaves/proc/add_new_wave(wave_type)
	if(!ispath(wave_type, /datum/latewave))
		return null

	var/datum/latewave/wave = new wave_type

	wave.wave_id = ++next_wave_id

	waves += wave

	update_waves()

	return wave


/datum/controller/subsystem/latewaves/proc/get_wave(wave_id)
	for(var/datum/latewave/wave as anything in waves)
		if(wave.wave_id == wave_id)
			return wave

	return null


/datum/controller/subsystem/latewaves/proc/join_wave(mob/new_player/user, wave_id, role_id)
	var/datum/latewave/wave = get_wave(wave_id)

	if(!wave)
		return FALSE

	wave.handle_spawn(user, role_id)

/datum/controller/subsystem/latewaves/proc/get_lobby_data()
	var/list/result = list()

	for(var/datum/latewave/wave as anything in waves)
		if(!wave.has_available_slots())
			continue

		result += list(
			wave.get_ui_data()
		)

	return result


/datum/controller/subsystem/latewaves/proc/update_waves()
	SEND_GLOBAL_SIGNAL(COMSIG_LATEWAVES_UPDATED, src)

	return