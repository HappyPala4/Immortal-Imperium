
/datum/map/geliak
	name = "Geliak"
	full_name = "Geliak"
	path = "geliak"
	station_name  = "Geliak"
	station_short = "Geliak"
	dock_name     = "Geliak"
	boss_name     = "Command"
	boss_short    = "SC"
	company_name  = "Imperium of Man"
	company_short = "Imperium"
	system_name = "Helican Subsector"

	lobby_icon = 'maps/delta/fullscreen.dmi'
	lobby_screens = list("lobby1","lobby2","lobby3","lobby4")

	station_levels = list(1,2,3)
	contact_levels = list(1,2,3)
	player_levels = list(1,2,3)

	allowed_spawns = list("Arrivals Shuttle")
	base_turf_by_z = list("1" = /turf/simulated/floor/dirty, "2" = /turf/simulated/floor/dirty, "3" = /turf/simulated/floor/dirty)
	shuttle_docked_message = "The slipstream has been opened."
	shuttle_leaving_dock = "The slipstream is closing."
	shuttle_called_message = "A requested slipstream is being opened."
	shuttle_recall_message = "The slipstream opening has been aborted"
	emergency_shuttle_docked_message = "The emergency escape shuttle has docked."
	emergency_shuttle_leaving_dock = "The emergency escape shuttle has departed from %dock_name%."
	emergency_shuttle_called_message = "An emergency escape shuttle has been sent."
	emergency_shuttle_recall_message = "The emergency shuttle has been recalled"
	map_lore = "Welcome to Geliak."



//Overriding event containers to remove random events.
/datum/event_container/mundane
	available_events = list(
		new /datum/event_meta(EVENT_LEVEL_MUNDANE, "Mortars",/datum/event/mortar,5),
		new /datum/event_meta(EVENT_LEVEL_MUNDANE, "Carp",/datum/event/carp_migration,5),
		new /datum/event_meta(EVENT_LEVEL_MUNDANE, "None",/datum/event/no_event,25),
		new /datum/event_meta(EVENT_LEVEL_MUNDANE, "None2",/datum/event/no_event,25),
		new /datum/event_meta(EVENT_LEVEL_MUNDANE, "None3",/datum/event/no_event,25),
		new /datum/event_meta(EVENT_LEVEL_MUNDANE, "None4",/datum/event/no_event,25),
		new /datum/event_meta(EVENT_LEVEL_MUNDANE, "None5",/datum/event/no_event,25),
		new /datum/event_meta(EVENT_LEVEL_MUNDANE, "None6",/datum/event/no_event,25),
		new /datum/event_meta(EVENT_LEVEL_MUNDANE, "None7",/datum/event/no_event,25)
	)

//Turbolift
/obj/machinery/door/airlock/lift/imperium
	name = "Lift Doorway"
	desc = "A solemn archway of gothic stone and copper mechanisms. The ancient platform beyond rumbles as it moves."
	icon = 'icons/obj/doors/imperiumdoor.dmi'
	glass = 0
	opacity = 1

/area/turbolift/geliak/lower
	name = "\improper Geliak-IV Lift"
	lift_floor_label = "\improper Lift - Lower"
	lift_floor_name = "lower-hive level"

/area/turbolift/geliak/middle
	name = "\improper Geliak-IV Lift"
	lift_floor_label = "\improper Lift - Middle"
	lift_floor_name = "middle-hive level"

/area/turbolift/geliak/upper
	name = "\improper Geliak-IV Lift"
	lift_floor_label = "\improper Lift - Upper"
	lift_floor_name = "upper-hive level"

/datum/event_container/moderate
	available_events = list(
		new /datum/event_meta(EVENT_LEVEL_MUNDANE, "Mortars",/datum/event/mortar,10),
		new /datum/event_meta(EVENT_LEVEL_MUNDANE, "None",/datum/event/no_event,25),
		new /datum/event_meta(EVENT_LEVEL_MUNDANE, "None2",/datum/event/no_event,25),
		new /datum/event_meta(EVENT_LEVEL_MUNDANE, "None3",/datum/event/no_event,25),
		new /datum/event_meta(EVENT_LEVEL_MUNDANE, "None3",/datum/event/no_event,25),
		new /datum/event_meta(EVENT_LEVEL_MUNDANE, "None4",/datum/event/no_event,25),
		new /datum/event_meta(EVENT_LEVEL_MUNDANE, "None5",/datum/event/no_event,25),
		new /datum/event_meta(EVENT_LEVEL_MUNDANE, "None6",/datum/event/no_event,25),
		new /datum/event_meta(EVENT_LEVEL_MUNDANE, "None7",/datum/event/no_event,25),
		new /datum/event_meta(EVENT_LEVEL_MUNDANE, "Gravity",/datum/event/gravity,10)
	)

/datum/event_container/major
	available_events = list(
		new /datum/event_meta(EVENT_LEVEL_MUNDANE, "Mortars",/datum/event/mortar,25),
		new /datum/event_meta(EVENT_LEVEL_MAJOR, "Carp",/datum/event/carp_migration,25),
		new /datum/event_meta(EVENT_LEVEL_MUNDANE, "None",/datum/event/no_event,25),
		new /datum/event_meta(EVENT_LEVEL_MUNDANE, "None2",/datum/event/no_event,25),
		new /datum/event_meta(EVENT_LEVEL_MUNDANE, "None3",/datum/event/no_event,25),
		new /datum/event_meta(EVENT_LEVEL_MUNDANE, "None3",/datum/event/no_event,25),
		new /datum/event_meta(EVENT_LEVEL_MUNDANE, "None4",/datum/event/no_event,25),
		new /datum/event_meta(EVENT_LEVEL_MUNDANE, "None5",/datum/event/no_event,25),
		new /datum/event_meta(EVENT_LEVEL_MUNDANE, "None6",/datum/event/no_event,25),
		new /datum/event_meta(EVENT_LEVEL_MUNDANE, "None7",/datum/event/no_event,25)
	)
