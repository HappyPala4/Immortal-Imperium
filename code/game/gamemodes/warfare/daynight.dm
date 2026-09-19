GLOBAL_DATUM(daynight_controller, /datum/daynight_controller)

/hook/roundstart/proc/start_daynight()
	. = 1
	if(!GLOB.daynight_controller)
		GLOB.daynight_controller = new()
	GLOB.daynight_controller.start()
	return .

/datum/daynight_controller
	var/cycle_length = 45 MINUTES
	var/update_interval = 2 SECONDS
	var/list/target_areas = list(/area/cadiaoutpost/oa/theforest)
	var/list/dummies = list()
	var/list/last_levels = list()
	var/running = FALSE
	var/y_min = INFINITY
	var/y_max = -INFINITY
	var/dawn_frac = 0.25
	var/day_frac = 0.25
	var/dusk_frac = 0.25
	var/band_width = 0.12
	var/day_range = 3
	var/day_power = 4
	var/day_color = "#bcc9f4"
	var/night_range = 1
	var/night_power = 0.5
	var/night_color = "#0e1426"

/datum/daynight_controller/proc/start()
	if(running)
		return
	running = TRUE
	build_dummies()
	loop()

/datum/daynight_controller/proc/loop()
	update()
	addtimer(CALLBACK(src, .proc/loop), update_interval)

/datum/daynight_controller/proc/build_dummies()
	dummies.Cut()
	last_levels.Cut()
	y_min = INFINITY
	y_max = -INFINITY
	for(var/area_type in target_areas)
		for(var/turf/simulated/floor/T in get_area_turfs(area_type))
			if(!(locate(/obj/effect/lighting_dummy/daylight) in T))
				new /obj/effect/lighting_dummy/daylight(T)
			var/obj/effect/lighting_dummy/daylight/D = locate(/obj/effect/lighting_dummy/daylight) in T
			if(D)
				dummies += D
				y_min = min(y_min, T.y)
				y_max = max(y_max, T.y)

/datum/daynight_controller/proc/update()
	if(!dummies.len || aspect_chosen(/datum/aspect/nightfare))
		return
	var/p = (world.time % cycle_length) / cycle_length
	for(var/obj/effect/lighting_dummy/daylight/D in dummies)
		apply_light(D, brightness_for(D.y, p))

/datum/daynight_controller/proc/brightness_for(y, p)
	var/yn = y_min < y_max ? (y - y_min) / (y_max - y_min) : 0
	var/day_end = dawn_frac + day_frac
	var/dusk_end = day_end + dusk_frac
	if(p < dawn_frac)
		return front_wave(p / dawn_frac, yn)
	else if(p < day_end)
		return 1
	else if(p < dusk_end)
		return 1 - front_wave((p - day_end) / dusk_frac, yn)
	return 0

/datum/daynight_controller/proc/front_wave(f, yn)
	var/d = CLAMP01(((f - yn) / band_width) + 0.5)
	return d * d * (3 - 2 * d)

/datum/daynight_controller/proc/apply_light(var/obj/effect/lighting_dummy/daylight/D, b)
	var/q = round(b * 20) * 0.05
	var/last = last_levels[D]
	if(last != null && abs(last - q) < 0.001)
		return
	last_levels[D] = q
	D.set_light(
		night_range + (day_range - night_range) * q,
		night_power + (day_power - night_power) * q,
		lerp_color(night_color, day_color, q))

/datum/daynight_controller/proc/lerp_color(c1, c2, f)
	var/r1 = hex2num(copytext(c1, 2, 4))
	var/g1 = hex2num(copytext(c1, 4, 6))
	var/b1 = hex2num(copytext(c1, 6, 8))
	var/r2 = hex2num(copytext(c2, 2, 4))
	var/g2 = hex2num(copytext(c2, 4, 6))
	var/b2 = hex2num(copytext(c2, 6, 8))
	return rgb(
		round(r1 + (r2 - r1) * f),
		round(g1 + (g2 - g1) * f),
		round(b1 + (b2 - b1) * f))