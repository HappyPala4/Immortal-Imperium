#define NIGHT_TIME /datum/daytime/night
#define DAY_TIME /datum/daytime/day
#define DUSK_TIME /datum/daytime/dusk
#define DAWN_TIME /datum/daytime/dawn
#define BATCH_SIZE 600

#define TRANSITION_TIME 1 MINUTES
SUBSYSTEM_DEF(daynight)
	name = "Day night"
	wait = 0.5 SECONDS
	var/list/dayparts = list(new NIGHT_TIME, new DUSK_TIME, new DAY_TIME, new DAWN_TIME)
	var/datum/daytime/current
	var/cycle_length
	var/cycle_time
	var/list/lightning_areas = list(/area/cadiaoutpost/oa/theforest, /area/latewave, /area/latewave/variant_1, /area/latewave/variant_2, /area/latewave/variant_3, /area/latewave/variant_4, /area/latewave/variant_5)
	var/light_update_index = 1
	var/need_update = TRUE
	priority = SS_PRIORITY_DAYNIGHT

	var/list/light_dummies = list()

/datum/controller/subsystem/daynight/Initialize()
	cycle_length = get_cycle_time()
	place_light()
	update_cycle_time(wait)
	current = get_current_daytime()
	while(need_update)
		update_light()

/datum/controller/subsystem/daynight/fire(resumed)
	update_cycle_time(wait)
	current = get_current_daytime(current)
	if(need_update)
		update_light()

/datum/controller/subsystem/daynight/proc/update_cycle_time(delta_time)
	cycle_time += delta_time

	if(cycle_time >= cycle_length)
		cycle_time %= cycle_length
		current = get_current_daytime()
		light_update_index = 1
		need_update = TRUE

/datum/controller/subsystem/daynight/proc/place_light()
	var/list/turfs_to_add = filter_valid_turfs(get_areas_turfs())
	for(var/turf/T in turfs_to_add)
		var/obj/effect/lighting_dummy/daylight/D = new(T)
		light_dummies += D

/datum/controller/subsystem/daynight/proc/get_areas_turfs()
	var/list/return_list = list()
	for(var/area_type in lightning_areas)
		return_list += get_area_turfs(area_type)
	return return_list

/datum/controller/subsystem/daynight/proc/filter_valid_turfs(list/turfs)
	for(var/turf/T in turfs)
		if(iswall(T))
			turfs -= T
	return turfs
//На всякий случай если проверку надо будет

/datum/controller/subsystem/daynight/proc/get_current_daytime(datum/daytime/previous_daytime)
	var/elapsed = 0

	for(var/datum/daytime/part in dayparts)
		if(cycle_time < elapsed + part.duration)
			if(previous_daytime != part)
				need_update = TRUE
			return part

		elapsed += part.duration

	return dayparts[1]

/datum/controller/subsystem/daynight/proc/get_cycle_time()
	var/cycle_length = 0
	for(var/datum/daytime/part in dayparts)
		cycle_length += part.duration
	return cycle_length

/datum/controller/subsystem/daynight/proc/update_light(roundstart = FALSE)
	if(!light_dummies.len)
		return

	var/light_batch_size = BATCH_SIZE
	var/end_index = min(
		light_update_index + light_batch_size - 1,
		light_dummies.len
	)
	if(roundstart)
		end_index = light_dummies.len

	var/list/parameters = get_light_parameters()

	for(var/i = light_update_index, i <= end_index, i++)
		var/obj/effect/lighting_dummy/daylight/D = light_dummies[i]

		set_dummy_light(D, parameters)

	light_update_index = end_index + 1

	if(light_update_index > light_dummies.len)
		light_update_index = 1
		need_update = FALSE

/datum/controller/subsystem/daynight/proc/set_dummy_light(obj/effect/lighting_dummy/daylight/D, list/parameters)
	D.set_light(
		1,
		parameters["brightness"],
		parameters["color"]
	)

/datum/controller/subsystem/daynight/proc/get_light_parameters()
	var/elapsed = 0
	var/datum/daytime/previous = dayparts[dayparts.len]

	for(var/datum/daytime/part in dayparts)
		if(cycle_time < elapsed + part.duration)
			var/time_in_part = cycle_time - elapsed
			var/progress = CLAMP01(min(time_in_part, TRANSITION_TIME) / TRANSITION_TIME)

			var/brightness = current.light_brightness
			var/color = current.color

			if(progress < 1)
				brightness = previous.light_brightness + \
					(current.light_brightness - previous.light_brightness) * progress

				color = lerp_color(
					previous.color,
					current.color,
					progress
				)

			return list(
				"brightness" = brightness,
				"color" = color
			)

		previous = part
		elapsed += part.duration

	return list(
		"brightness" = current.light_brightness,
		"color" = current.color
	)

/datum/controller/subsystem/daynight/proc/lerp_color(color1, color2, progress)
	var/r1 = hex2num(copytext(color1, 2, 4))
	var/g1 = hex2num(copytext(color1, 4, 6))
	var/b1 = hex2num(copytext(color1, 6, 8))

	var/r2 = hex2num(copytext(color2, 2, 4))
	var/g2 = hex2num(copytext(color2, 4, 6))
	var/b2 = hex2num(copytext(color2, 6, 8))

	return rgb(
		round(r1 + (r2 - r1) * progress),
		round(g1 + (g2 - g1) * progress),
		round(b1 + (b2 - b1) * progress)
	)

/datum/controller/subsystem/daynight/proc/get_dayparts()
	var/list/return_list = list()
	for(var/datum/daytime/D in dayparts)
		return_list += list(D.name = D)
	return return_list
/datum/controller/subsystem/daynight/proc/change_daytime(datum/daytime/D)
	light_update_index = 1
	need_update = TRUE

	var/current_time = 0
	for(var/datum/daytime/daytime in dayparts)
		if(daytime == D)
			cycle_time = current_time
			current = D
			return

		current_time += daytime.duration

/datum/daytime
	var/name
	var/duration
	var/color
	var/light_brightness

/datum/daytime/night
	name = "Night"
	duration = 10 MINUTES
	color = "#0e1426"
	light_brightness = 0

/datum/daytime/day
	name = "Day"
	duration = 10 MINUTES
	color = "#bcc9f4"
	light_brightness = 0.6

/datum/daytime/dusk
	name = "Dusk"
	duration = 5 MINUTES
	color = "#313c58"
	light_brightness = 0.2

/datum/daytime/dawn
	name = "Dawn"
	duration = 5 MINUTES
	color = "#807962"
	light_brightness = 0.2
