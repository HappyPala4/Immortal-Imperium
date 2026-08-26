/obj/machinery/door/airlock/multi_tile
	width = 2
	appearance_flags = 0

/obj/machinery/door/airlock/multi_tile/New()
	..()
	SetBounds()

/obj/machinery/door/airlock/multi_tile/Initialize()
	. = ..()
	SetBounds()
	if(!glass)
		create_fillers()

/obj/machinery/door/airlock/multi_tile/Destroy()
	QDEL_NULL(f5)
	QDEL_NULL(f6)
	return ..()

/obj/machinery/door/airlock/multi_tile/Move()
	. = ..()
	SetBounds()

/obj/machinery/door/airlock/multi_tile/proc/SetBounds()
	if(dir in list(EAST, WEST))
		bound_width = width * world.icon_size
		bound_height = world.icon_size
	else
		bound_width = world.icon_size
		bound_height = width * world.icon_size

/obj/machinery/door/airlock/multi_tile/proc/create_fillers()
	var/turf/extra
	if(dir in list(EAST, WEST))
		extra = get_step(src, EAST)
	else
		extra = get_step(src, NORTH)
	f5 = new /obj/machinery/filler_object(loc)
	if(extra)
		f6 = new /obj/machinery/filler_object(extra)
	update_filler_opacity()

/obj/machinery/door/airlock/multi_tile/proc/update_filler_opacity()
	if(f5)
		f5.set_opacity(opacity)
	if(f6)
		f6.set_opacity(opacity)

/obj/machinery/door/airlock/multi_tile/set_opacity(new_opacity)
	. = ..()
	update_filler_opacity()

/obj/machinery/filler_object
	name = ""
	icon = 'icons/obj/doors/rapid_pdoor.dmi'
	icon_state = ""
	density = FALSE
	anchored = TRUE
	invisibility = 101

/obj/machinery/door/airlock/multi_tile/glass
	name = "Glass Airlock"
	icon = 'icons/obj/doors/Door2x1glass.dmi'
	opacity = 0
	glass = 1
	assembly_type = /obj/structure/door_assembly/multi_tile

/obj/machinery/door/airlock/multi_tile/metal
	name = "Airlock"
	opacity = 1
	glass = 0

/obj/machinery/door/airlock/multi_tile/metal/maintenance
	name = "Airlock"
	icon = 'icons/obj/doors/Door2x1maint.dmi'
	assembly_type = /obj/structure/door_assembly/multi_tile/maintenance

/obj/machinery/door/airlock/multi_tile/metal/imperium
	name = "Airlock"
	icon = 'icons/obj/doors/Door2x1imperium.dmi'
	assembly_type = /obj/structure/door_assembly/multi_tile/imperium
