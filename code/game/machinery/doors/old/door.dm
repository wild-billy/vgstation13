//This file was auto-corrected by findeclaration.exe on 25.5.2012 20:42:31

#define BLOB_PROBABILITY 40
#define HEADBUTT_PROBABILITY 40
#define BRAINLOSS_FOR_HEADBUTT 60

/obj/machinery/door
	name = "door"
	desc = "It opens and closes."
	icon = 'icons/obj/doors/door.dmi'
	icon_state = "door_closed"
	anchored = 1
	opacity = 1
	density = 1
	layer = 2.7

	var/secondsElectrified = 0
	var/visible = 1
	var/p_open = 0
	var/operating = 0
	var/autoclose = 0
	var/glass = 0
	var/normalspeed = 1

	// for glass airlocks/opacity firedoors
	var/heat_proof = 0

	var/air_properties_vary_with_direction = 0

	// multi-tile doors
	dir = EAST
	var/width = 1

	// from old /vg/
	// the object that's jammed us open/closed
	var/obj/jammed = null

	// if the door has certain variation, like rapid (r_)
	var/prefix = null

	// TODO: refactor to best :(
	var/animation_delay = 12
	var/animation_delay_2 = null



	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	


/obj/machinery/door/New()
	. = ..()

	if(density)
		// above most items if closed
		layer = 3.1

		explosion_resistance = initial(explosion_resistance)
	else
		// under all objects if opened. 2.7 due to tables being at 2.6
		layer = 2.7

		explosion_resistance = 0

	if(width > 1)
		if(dir in list(EAST, WEST))
			bound_width = width * world.icon_size
			bound_height = world.icon_size
		else
			bound_width = world.icon_size
			bound_height = width * world.icon_size

	update_nearby_tiles()

/obj/machinery/door/Destroy()
	update_nearby_tiles()
	..()






/obj/machinery/door/ex_act(severity)
	switch(severity)
		if(1.0)
			qdel(src)
		if(2.0)
			if(prob(25))
				qdel(src)
		if(3.0)
			if(prob(80))
				var/datum/effect/effect/system/spark_spread/s = new /datum/effect/effect/system/spark_spread
				s.set_up(2, 1, src)
				s.start()
	return

/obj/machinery/door/proc/requiresID()
	return 1

/obj/machinery/door/proc/update_nearby_tiles()
	if(!air_master)
		return 0

	for(var/turf in locs)
		update_heat_protection(turf)
		air_master.mark_for_update(turf)

	update_freelok_sight()
	return 1

/obj/machinery/door/proc/update_heat_protection(var/turf/simulated/source)
	if(istype(source))
		if(src.density && (src.opacity || src.heat_proof))
			source.thermal_conductivity = DOOR_HEAT_TRANSFER_COEFFICIENT
		else
			source.thermal_conductivity = initial(source.thermal_conductivity)

/obj/machinery/door/Move(new_loc, new_dir)
	update_nearby_tiles()
	. = ..()
	if(width > 1)
		if(dir in list(EAST, WEST))
			bound_width = width * world.icon_size
			bound_height = world.icon_size
		else
			bound_width = world.icon_size
			bound_height = width * world.icon_size

	update_nearby_tiles()

/obj/machinery/door/morgue
	icon = 'icons/obj/doors/morgue.dmi'
	animation_delay = 15