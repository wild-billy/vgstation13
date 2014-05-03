
// Regular pipe colors
//                         #RRGGBB
#define PIPE_COLOR_BLUE   "#0000FF"
#define PIPE_COLOR_CYAN   "#00FFFF"
#define PIPE_COLOR_GREEN  "#00FF00"
#define PIPE_COLOR_GREY   "#FFFFFF" // White
#define PIPE_COLOR_PURPLE "#800080"
#define PIPE_COLOR_RED    "#FF0000"
#define PIPE_COLOR_YELLOW "#FFA800" // Orange, actually. Yellow looked awful.

// Insulated pipes
#define IPIPE_COLOR_RED   PIPE_COLOR_RED
#define IPIPE_COLOR_BLUE  "#4285F4"

/obj/machinery/networked/atmos/pipe
	var/datum/gas_mixture/air_temporary //used when reconstructing a pipeline that broke
	var/volume = 0
	force = 20
	layer = 2.4 //under wires with their 2.44
	use_power = 0
	var/alert_pressure = 80*ONE_ATMOSPHERE
	var/baseicon=""
	var/list/available_colors = list(
		"grey"=PIPE_COLOR_GREY,
		"red"=PIPE_COLOR_RED,
		"blue"=PIPE_COLOR_BLUE,
		"cyan"=PIPE_COLOR_CYAN,
		"green"=PIPE_COLOR_GREEN,
		"yellow"=PIPE_COLOR_YELLOW,
		"purple"=PIPE_COLOR_PURPLE
	)

/obj/machinery/networked/atmos/pipe/proc/check_pressure(pressure)
	//Return 1 if network should continue checking other pipes
	//Return null if network should stop checking other pipes. Recall: del(src) will by default return null
	return 1


/obj/machinery/networked/atmos/pipe/return_air()
	check_physnet()
	return physnet.air


/obj/machinery/networked/atmos/pipe/build_network()
	check_physnet()
	return physnet.return_network()


/obj/machinery/networked/atmos/pipe/network_expand(var/datum/physical_network/atmos/new_network, var/obj/machinery/networked/atmos/pipe/reference)
	check_physnet()
	return physnet.network_expand(new_network, reference)

/obj/machinery/networked/atmos/pipe/return_network(var/obj/machinery/networked/atmos/pipe/reference)
	check_physnet()
	return physnet.return_network(reference)


/obj/machinery/networked/atmos/pipe/Destroy()
	if(air_temporary)
		loc.assume_air(air_temporary)
	..()

/obj/machinery/networked/atmos/pipe/simple
	icon = 'icons/obj/pipes.dmi'
	icon_state = "intact"
	name = "pipe"
	desc = "A one meter section of regular pipe"
	volume = 70
	dir = SOUTH
	initialize_directions = SOUTH|NORTH
	var/obj/machinery/networked/atmos/node1
	var/obj/machinery/networked/atmos/node2
	var/minimum_temperature_difference = 300
	var/thermal_conductivity = 0 //WALL_HEAT_TRANSFER_COEFFICIENT No
	var/maximum_pressure = 70*ONE_ATMOSPHERE
	var/fatigue_pressure = 55*ONE_ATMOSPHERE
	alert_pressure = 55*ONE_ATMOSPHERE
	level = 1

/obj/machinery/networked/atmos/pipe/simple/New()
	..()
	switch(dir)
		if(SOUTH || NORTH)
			initialize_directions = SOUTH|NORTH
		if(EAST || WEST)
			initialize_directions = EAST|WEST
		if(NORTHEAST)
			initialize_directions = NORTH|EAST
		if(NORTHWEST)
			initialize_directions = NORTH|WEST
		if(SOUTHEAST)
			initialize_directions = SOUTH|EAST
		if(SOUTHWEST)
			initialize_directions = SOUTH|WEST


/obj/machinery/networked/atmos/pipe/simple/buildFrom(var/mob/usr,var/obj/item/pipe/pipe)
	dir = pipe.dir
	initialize_directions = pipe.get_pipe_dir()
	var/turf/T = loc
	level = T.intact ? 2 : 1
	initialize(1)
	if(!node1&&!node2)
		usr << "\red There's nothing to connect this pipe section to! (with how the pipe code works, at least one end needs to be connected to something, otherwise the game deletes the segment)"
		return 0
	update_icon()
	build_network()
	if (node1)
		node1.initialize()
		node1.build_network()
	if (node2)
		node2.initialize()
		node2.build_network()
	return 1


/obj/machinery/networked/atmos/pipe/simple/hide(var/i)
	if(level == 1 && istype(loc, /turf/simulated))
		invisibility = i ? 101 : 0
	update_icon()


/obj/machinery/networked/atmos/pipe/simple/process()
	if(!physnet) //This should cut back on the overhead calling build_network thousands of times per cycle
		..()
	else
		. = PROCESS_KILL

	/*if(!node1)
		physnet.mingle_with_turf(loc, volume)
		if(!nodealert)
			//world << "Missing node from [src] at [src.x],[src.y],[src.z]"
			nodealert = 1

	else if(!node2)
		physnet.mingle_with_turf(loc, volume)
		if(!nodealert)
			//world << "Missing node from [src] at [src.x],[src.y],[src.z]"
			nodealert = 1
	else if (nodealert)
		nodealert = 0


	else if(physnet)
		var/environment_temperature = 0

		if(istype(loc, /turf/simulated/))
			if(loc:blocks_air)
				environment_temperature = loc:temperature
			else
				var/datum/gas_mixture/environment = loc.return_air()
				environment_temperature = environment.temperature

		else
			environment_temperature = loc:temperature

		var/datum/gas_mixture/pipe_air = return_air()

		if(abs(environment_temperature-pipe_air.temperature) > minimum_temperature_difference)
			physnet.temperature_interact(loc, volume, thermal_conductivity)
	*/


/obj/machinery/networked/atmos/pipe/simple/check_pressure(pressure)
	var/datum/gas_mixture/environment = loc.return_air()

	var/pressure_difference = pressure - environment.return_pressure()

	if(pressure_difference > maximum_pressure)
		burst()

	else if(pressure_difference > fatigue_pressure)

		if(prob(5))
			burst()

	else return 1


/obj/machinery/networked/atmos/pipe/simple/proc/burst()
	src.visible_message("\red \bold [src] bursts!");
	playsound(get_turf(src), 'sound/effects/bang.ogg', 25, 1)
	var/datum/effect/effect/system/smoke_spread/smoke = new
	smoke.set_up(1,0, src.loc, 0)
	smoke.start()
	qdel(src)


/obj/machinery/networked/atmos/pipe/simple/proc/normalize_dir()
	if(dir==3)
		dir = 1
	else if(dir==12)
		dir = 4


/obj/machinery/networked/atmos/pipe/simple/Destroy()
	if(node1)
		node1.disconnect(src)
	if(node2)
		node2.disconnect(src)

	..()


/obj/machinery/networked/atmos/pipe/simple/physical_expansion()
	return list(node1, node2)


/obj/machinery/networked/atmos/pipe/simple/update_icon()
	alpha = invisibility ? 128 : 255
	color = available_colors[_color]
	if(node1&&node2)
		icon_state = "intact"

	else
		if(!node1&&!node2)
			qdel(src) //TODO: silent deleting looks weird
		var/have_node1 = node1?1:0
		var/have_node2 = node2?1:0
		icon_state = "exposed[have_node1][have_node2]"


/obj/machinery/networked/atmos/pipe/simple/initialize(var/suppress_icon_check=0)
	normalize_dir()

	findAllConnections(initialize_directions)

	var/turf/T = src.loc			// hide if turf is not intact
	hide(T.intact)
	if(!suppress_icon_check)
		update_icon()


/obj/machinery/networked/atmos/pipe/simple/disconnect(obj/machinery/networked/atmos/reference)
	if(reference == node1)
		if(istype(node1, /obj/machinery/networked/atmos/pipe))
			del(physnet)
		node1 = null

	if(reference == node2)
		if(istype(node2, /obj/machinery/networked/atmos/pipe))
			del(physnet)
		node2 = null

	update_icon()
	return null

/obj/machinery/networked/atmos/pipe/simple/scrubbers
	name = "Scrubbers pipe"
	_color = "red"
	color=PIPE_COLOR_RED
/obj/machinery/networked/atmos/pipe/simple/supply
	name = "Air supply pipe"
	_color = "blue"
	color=PIPE_COLOR_BLUE
/obj/machinery/networked/atmos/pipe/simple/supplymain
	name = "Main air supply pipe"
	_color = "purple"
	color=PIPE_COLOR_PURPLE
/obj/machinery/networked/atmos/pipe/simple/general
	name = "Pipe"
	_color = "grey"
	color=PIPE_COLOR_GREY
/obj/machinery/networked/atmos/pipe/simple/yellow
	name = "Pipe"
	_color="yellow"
	color=PIPE_COLOR_YELLOW
/obj/machinery/networked/atmos/pipe/simple/cyan
	name = "Pipe"
	_color="cyan"
	color=PIPE_COLOR_CYAN
/obj/machinery/networked/atmos/pipe/simple/filtering
	name = "Pipe"
	_color = "green"
	color=PIPE_COLOR_GREEN

/obj/machinery/networked/atmos/pipe/simple/scrubbers/visible
	level = 2
/obj/machinery/networked/atmos/pipe/simple/scrubbers/hidden
	level = 1
	alpha=128
/obj/machinery/networked/atmos/pipe/simple/supply/visible
	level = 2
/obj/machinery/networked/atmos/pipe/simple/supply/hidden
	level = 1
	alpha=128
/obj/machinery/networked/atmos/pipe/simple/supplymain/visible
	level = 2
/obj/machinery/networked/atmos/pipe/simple/supplymain/hidden
	level = 1
	alpha=128
/obj/machinery/networked/atmos/pipe/simple/general/visible
	level = 2
/obj/machinery/networked/atmos/pipe/simple/general/hidden
	level = 1
	alpha=128
/obj/machinery/networked/atmos/pipe/simple/yellow/visible
	level = 2
/obj/machinery/networked/atmos/pipe/simple/yellow/hidden
	level = 1
	alpha=128
/obj/machinery/networked/atmos/pipe/simple/cyan/visible
	level = 2
/obj/machinery/networked/atmos/pipe/simple/cyan/hidden
	level = 1
	alpha=128
/obj/machinery/networked/atmos/pipe/simple/filtering/visible
	level = 2
/obj/machinery/networked/atmos/pipe/simple/filtering/hidden
	level = 1
	alpha=128
/obj/machinery/networked/atmos/pipe/simple/insulated
	name = "Insulated pipe"
	//icon = 'icons/obj/atmospherics/red_pipe.dmi'
	icon = 'icons/obj/atmospherics/insulated.dmi'
	minimum_temperature_difference = 10000
	thermal_conductivity = 0
	maximum_pressure = 1000*ONE_ATMOSPHERE
	fatigue_pressure = 900*ONE_ATMOSPHERE
	alert_pressure = 900*ONE_ATMOSPHERE
	available_colors = list(
		"red"=IPIPE_COLOR_RED,
		"blue"=IPIPE_COLOR_BLUE
	)
	_color = "red"
/obj/machinery/networked/atmos/pipe/simple/insulated/visible
	icon_state = "intact"
	level = 2
	color=IPIPE_COLOR_RED
/obj/machinery/networked/atmos/pipe/simple/insulated/visible/blue
	color=IPIPE_COLOR_BLUE
	_color = "blue"
/obj/machinery/networked/atmos/pipe/simple/insulated/hidden
	icon_state = "intact"
	alpha=128
	level = 1
	color=IPIPE_COLOR_RED
/obj/machinery/networked/atmos/pipe/simple/insulated/hidden/blue
	color=IPIPE_COLOR_BLUE
	_color = "blue"
/obj/machinery/networked/atmos/pipe/tank
	icon = 'icons/obj/atmospherics/pipe_tank.dmi'
	icon_state = "intact"
	name = "Pressure Tank"
	desc = "A large vessel containing pressurized gas."
	volume = 2000 //in liters, 1 meters by 1 meters by 2 meters
	dir = SOUTH
	initialize_directions = SOUTH
	density = 1
	var/obj/machinery/networked/atmos/node1

/obj/machinery/networked/atmos/pipe/tank/New()
	initialize_directions = dir
	..()


/obj/machinery/networked/atmos/pipe/tank/process()
	if(!physnet)
		..()
	else
		. = PROCESS_KILL
	/*			if(!node1)
		physnet.mingle_with_turf(loc, 200)
		if(!nodealert)
			//world << "Missing node from [src] at [src.x],[src.y],[src.z]"
			nodealert = 1
	else if (nodealert)
		nodealert = 0
	*/

/obj/machinery/networked/atmos/pipe/tank/carbon_dioxide
	name = "Pressure Tank (Carbon Dioxide)"

/obj/machinery/networked/atmos/pipe/tank/carbon_dioxide/New()
	air_temporary = new
	air_temporary.volume = volume
	air_temporary.temperature = T20C

	air_temporary.carbon_dioxide = (25*ONE_ATMOSPHERE)*(air_temporary.volume)/(R_IDEAL_GAS_EQUATION*air_temporary.temperature)

	..()

/obj/machinery/networked/atmos/pipe/tank/toxins
	icon = 'icons/obj/atmospherics/orange_pipe_tank.dmi'
	name = "Pressure Tank (Plasma)"

/obj/machinery/networked/atmos/pipe/tank/toxins/New()
	air_temporary = new
	air_temporary.volume = volume
	air_temporary.temperature = T20C

	air_temporary.toxins = (25*ONE_ATMOSPHERE)*(air_temporary.volume)/(R_IDEAL_GAS_EQUATION*air_temporary.temperature)

	..()

/obj/machinery/networked/atmos/pipe/tank/oxygen_agent_b
	icon = 'icons/obj/atmospherics/red_orange_pipe_tank.dmi'
	name = "Pressure Tank (Oxygen + Plasma)"

/obj/machinery/networked/atmos/pipe/tank/oxygen_agent_b/New()
	air_temporary = new
	air_temporary.volume = volume
	air_temporary.temperature = T0C

	var/datum/gas/oxygen_agent_b/trace_gas = new
	trace_gas.moles = (25*ONE_ATMOSPHERE)*(air_temporary.volume)/(R_IDEAL_GAS_EQUATION*air_temporary.temperature)

	air_temporary.trace_gases += trace_gas

	..()

/obj/machinery/networked/atmos/pipe/tank/oxygen
	icon = 'icons/obj/atmospherics/blue_pipe_tank.dmi'
	name = "Pressure Tank (Oxygen)"

/obj/machinery/networked/atmos/pipe/tank/oxygen/New()
	air_temporary = new
	air_temporary.volume = volume
	air_temporary.temperature = T20C

	air_temporary.oxygen = (25*ONE_ATMOSPHERE)*(air_temporary.volume)/(R_IDEAL_GAS_EQUATION*air_temporary.temperature)

	..()

/obj/machinery/networked/atmos/pipe/tank/nitrogen
	icon = 'icons/obj/atmospherics/red_pipe_tank.dmi'
	name = "Pressure Tank (Nitrogen)"

/obj/machinery/networked/atmos/pipe/tank/nitrogen/New()
	air_temporary = new
	air_temporary.volume = volume
	air_temporary.temperature = T20C

	air_temporary.nitrogen = (25*ONE_ATMOSPHERE)*(air_temporary.volume)/(R_IDEAL_GAS_EQUATION*air_temporary.temperature)

	..()

/obj/machinery/networked/atmos/pipe/tank/air
	icon = 'icons/obj/atmospherics/red_pipe_tank.dmi'
	name = "Pressure Tank (Air)"

/obj/machinery/networked/atmos/pipe/tank/air/New()
	air_temporary = new
	air_temporary.volume = volume
	air_temporary.temperature = T20C

	air_temporary.oxygen = (25*ONE_ATMOSPHERE*O2STANDARD)*(air_temporary.volume)/(R_IDEAL_GAS_EQUATION*air_temporary.temperature)
	air_temporary.nitrogen = (25*ONE_ATMOSPHERE*N2STANDARD)*(air_temporary.volume)/(R_IDEAL_GAS_EQUATION*air_temporary.temperature)

	..()


/obj/machinery/networked/atmos/pipe/tank/Destroy()
	if(node1)
		node1.disconnect(src)

	..()

/obj/machinery/networked/atmos/pipe/tank/physical_expansion()
	return list(node1)


/obj/machinery/networked/atmos/pipe/tank/update_icon()
	if(node1)
		icon_state = "intact"
		dir = get_dir(src, node1)
	else
		icon_state = "exposed"


/obj/machinery/networked/atmos/pipe/tank/initialize()

	var/connect_direction = dir

	node1=findConnectingPipe(connect_direction)

	update_icon()


/obj/machinery/networked/atmos/pipe/tank/disconnect(obj/machinery/networked/atmos/reference)
	if(reference == node1)
		if(istype(node1, /obj/machinery/networked/atmos/pipe))
			del(physnet)
		node1 = null

	update_icon()

	return null


/obj/machinery/networked/atmos/pipe/tank/attackby(var/obj/item/weapon/W as obj, var/mob/user as mob)
	if(istype(W, /obj/item/weapon/pipe_dispenser) || istype(W, /obj/item/device/pipe_painter))
		return // Coloring pipes.
	if (istype(W, /obj/item/device/analyzer) && get_dist(user, src) <= 1)
		for (var/mob/O in viewers(user, null))
			O << "\red [user] has used the analyzer on \icon[icon]"

		var/pressure = physnet.air.return_pressure()
		var/total_moles = physnet.air.total_moles()

		user << "\blue Results of analysis of \icon[icon]"
		if (total_moles>0)
			var/o2_concentration = physnet.air.oxygen/total_moles
			var/n2_concentration = physnet.air.nitrogen/total_moles
			var/co2_concentration = physnet.air.carbon_dioxide/total_moles
			var/plasma_concentration = physnet.air.toxins/total_moles

			var/unknown_concentration =  1-(o2_concentration+n2_concentration+co2_concentration+plasma_concentration)

			user << "\blue Pressure: [round(pressure,0.1)] kPa"
			user << "\blue Nitrogen: [round(n2_concentration*100)]%"
			user << "\blue Oxygen: [round(o2_concentration*100)]%"
			user << "\blue CO2: [round(co2_concentration*100)]%"
			user << "\blue Plasma: [round(plasma_concentration*100)]%"
			if(unknown_concentration>0.01)
				user << "\red Unknown: [round(unknown_concentration*100)]%"
			user << "\blue Temperature: [round(physnet.air.temperature-T0C)]&deg;C"
		else
			user << "\blue Tank is empty!"

/obj/machinery/networked/atmos/pipe/vent
	icon = 'icons/obj/atmospherics/pipe_vent.dmi'
	icon_state = "intact"
	name = "Vent"
	desc = "A large air vent"
	level = 1
	volume = 250
	dir = SOUTH
	initialize_directions = SOUTH
	var/build_killswitch = 1
	var/obj/machinery/networked/atmos/node1

/obj/machinery/networked/atmos/pipe/vent/New()
	initialize_directions = dir
	..()

/obj/machinery/networked/atmos/pipe/vent/high_volume
	name = "Larger vent"
	volume = 1000

/obj/machinery/networked/atmos/pipe/vent/process()
	if(!physnet)
		if(build_killswitch <= 0)
			. = PROCESS_KILL
		else
			build_killswitch--
		..()
		return
	else
		physnet.mingle_with_turf(loc, volume)
	/*
	if(!node1)
		if(!nodealert)
			//world << "Missing node from [src] at [src.x],[src.y],[src.z]"
			nodealert = 1
	else if (nodealert)
		nodealert = 0
	*/


/obj/machinery/networked/atmos/pipe/vent/Destroy()
	if(node1)
		node1.disconnect(src)

	..()


/obj/machinery/networked/atmos/pipe/vent/physical_expansion()
	return list(node1)


/obj/machinery/networked/atmos/pipe/vent/update_icon()
	if(node1)
		icon_state = "intact"

		dir = get_dir(src, node1)

	else
		icon_state = "exposed"


/obj/machinery/networked/atmos/pipe/vent/initialize()
	var/connect_direction = dir

	node1=findConnectingPipe(connect_direction)

	update_icon()


/obj/machinery/networked/atmos/pipe/vent/disconnect(obj/machinery/networked/atmos/reference)
	if(reference == node1)
		if(istype(node1, /obj/machinery/networked/atmos/pipe))
			del(physnet)
		node1 = null

	update_icon()

	return null


/obj/machinery/networked/atmos/pipe/vent/hide(var/i)
	if(node1)
		icon_state = "[i == 1 && istype(loc, /turf/simulated) ? "h" : "" ]intact"
		dir = get_dir(src, node1)
	else
		icon_state = "exposed"

/obj/machinery/networked/atmos/pipe/manifold
	icon = 'icons/obj/atmospherics/pipe_manifold.dmi'
	icon_state = "manifold"
	baseicon = "manifold"
	name = "pipe manifold"
	desc = "A manifold composed of regular pipes"
	volume = 105
	dir = SOUTH
	initialize_directions = EAST|NORTH|WEST
	var/obj/machinery/networked/atmos/node1
	var/obj/machinery/networked/atmos/node2
	var/obj/machinery/networked/atmos/node3
	level = 1
	layer = 2.4 //under wires with their 2.44

/obj/machinery/networked/atmos/pipe/manifold/buildFrom(var/mob/usr,var/obj/item/pipe/pipe)
	dir = pipe.dir
	initialize_directions = pipe.get_pipe_dir()
	var/turf/T = loc
	level = T.intact ? 2 : 1
	initialize(1)
	if(!node1&&!node2&&!node3)
		usr << "\red There's nothing to connect this manifold to! (with how the pipe code works, at least one end needs to be connected to something, otherwise the game deletes the segment)"
		return 0
	update_icon() // Skipped in initialize()!
	build_network()
	if (node1)
		node1.initialize()
		node1.build_network()
	if (node2)
		node2.initialize()
		node2.build_network()
	if (node3)
		node3.initialize()
		node3.build_network()
	return 1


/obj/machinery/networked/atmos/pipe/manifold/New()
	switch(dir)
		if(NORTH)
			initialize_directions = EAST|SOUTH|WEST
		if(SOUTH)
			initialize_directions = WEST|NORTH|EAST
		if(EAST)
			initialize_directions = SOUTH|WEST|NORTH
		if(WEST)
			initialize_directions = NORTH|EAST|SOUTH

	..()


/obj/machinery/networked/atmos/pipe/manifold/hide(var/i)
	if(level == 1 && istype(loc, /turf/simulated))
		invisibility = i ? 101 : 0
	update_icon()


/obj/machinery/networked/atmos/pipe/manifold/physical_expansion()
	return list(node1, node2, node3)


/obj/machinery/networked/atmos/pipe/manifold/process()
	if(!physnet)
		..()
	else
		. = PROCESS_KILL
	/*
	if(!node1)
		physnet.mingle_with_turf(loc, 70)
		if(!nodealert)
			//world << "Missing node from [src] at [src.x],[src.y],[src.z]"
			nodealert = 1
	else if(!node2)
		physnet.mingle_with_turf(loc, 70)
		if(!nodealert)
			//world << "Missing node from [src] at [src.x],[src.y],[src.z]"
			nodealert = 1
	else if(!node3)
		physnet.mingle_with_turf(loc, 70)
		if(!nodealert)
			//world << "Missing node from [src] at [src.x],[src.y],[src.z]"
			nodealert = 1
	else if (nodealert)
		nodealert = 0
	*/


/obj/machinery/networked/atmos/pipe/manifold/Destroy()
	if(node1)
		node1.disconnect(src)
	if(node2)
		node2.disconnect(src)
	if(node3)
		node3.disconnect(src)

	..()


/obj/machinery/networked/atmos/pipe/manifold/disconnect(obj/machinery/networked/atmos/reference)
	if(reference == node1)
		if(istype(node1, /obj/machinery/networked/atmos/pipe))
			del(physnet)
		node1 = null

	if(reference == node2)
		if(istype(node2, /obj/machinery/networked/atmos/pipe))
			del(physnet)
		node2 = null

	if(reference == node3)
		if(istype(node3, /obj/machinery/networked/atmos/pipe))
			del(physnet)
		node3 = null

	update_icon()

	..()


/obj/machinery/networked/atmos/pipe/manifold/update_icon()
	alpha = invisibility ? 128 : 255
	color = available_colors[_color]
	overlays = 0
	if(node1&&node2&&node3)
		icon_state="manifold"
	else
		icon_state = "[baseicon]_ex"
		var/icon/con = new/icon(icon,"[baseicon]_con") //Since 4-ways are supposed to be directionless, they need an overlay instead it seems.

		if(node1)
			overlays += new/image(con,dir=get_dir(src, node1))
		if(node2)
			overlays += new/image(con,dir=get_dir(src, node2))
		if(node3)
			overlays += new/image(con,dir=get_dir(src, node3))

		if(!node1 && !node2 && !node3)
			qdel(src)

	return


/obj/machinery/networked/atmos/pipe/manifold/initialize(var/skip_icon_update=0)
	var/connect_directions = (NORTH|SOUTH|EAST|WEST)&(~dir)

	findAllConnections(connect_directions)

	var/turf/T = src.loc			// hide if turf is not intact
	hide(T.intact)
	if(!skip_icon_update)
		update_icon()

/obj/machinery/networked/atmos/pipe/manifold/scrubbers
	name = "Scrubbers pipe"
	_color = "red"
	color=PIPE_COLOR_RED
/obj/machinery/networked/atmos/pipe/manifold/supply
	name = "Air supply pipe"
	_color = "blue"
	color=PIPE_COLOR_BLUE
/obj/machinery/networked/atmos/pipe/manifold/supplymain
	name = "Main air supply pipe"
	_color = "purple"
	color=PIPE_COLOR_PURPLE
/obj/machinery/networked/atmos/pipe/manifold/general
	name = "Gas pipe"
	_color = "gray"
	color=PIPE_COLOR_GREY
/obj/machinery/networked/atmos/pipe/manifold/yellow
	name = "Air supply pipe"
	_color = "yellow"
	color=PIPE_COLOR_YELLOW
/obj/machinery/networked/atmos/pipe/manifold/cyan
	name = "Air supply pipe"
	_color = "cyan"
	color=PIPE_COLOR_CYAN
/obj/machinery/networked/atmos/pipe/manifold/filtering
	name = "Air filtering pipe"
	_color = "green"
	color=PIPE_COLOR_GREEN
/obj/machinery/networked/atmos/pipe/manifold/insulated
	name = "Insulated pipe"
	//icon = 'icons/obj/atmospherics/red_pipe.dmi'
	icon = 'icons/obj/atmospherics/insulated.dmi'
	icon_state = "manifold"
	alert_pressure = 900*ONE_ATMOSPHERE
	level = 2
	available_colors = list(
		"red"=IPIPE_COLOR_RED,
		"blue"=IPIPE_COLOR_BLUE
	)
/obj/machinery/networked/atmos/pipe/manifold/scrubbers/visible
	level = 2
/obj/machinery/networked/atmos/pipe/manifold/scrubbers/hidden
	level = 1
	alpha=128
/obj/machinery/networked/atmos/pipe/manifold/supply/visible
	level = 2
/obj/machinery/networked/atmos/pipe/manifold/supply/hidden
	level = 1
	alpha=128
/obj/machinery/networked/atmos/pipe/manifold/supplymain/visible
	level = 2
/obj/machinery/networked/atmos/pipe/manifold/supplymain/hidden
	level = 1
	alpha=128
/obj/machinery/networked/atmos/pipe/manifold/general/visible
	level = 2
/obj/machinery/networked/atmos/pipe/manifold/general/hidden
	level = 1
	alpha=128
/obj/machinery/networked/atmos/pipe/manifold/insulated/visible
	level = 2
	color=IPIPE_COLOR_RED
	_color = "red"
/obj/machinery/networked/atmos/pipe/manifold/insulated/visible/blue
	color=IPIPE_COLOR_BLUE
	_color = "blue"
/obj/machinery/networked/atmos/pipe/manifold/insulated/hidden
	level = 1
	color=IPIPE_COLOR_RED
	alpha=128
	_color = "red"
/obj/machinery/networked/atmos/pipe/manifold/insulated/hidden/blue
	color=IPIPE_COLOR_BLUE
	_color = "blue"
/obj/machinery/networked/atmos/pipe/manifold/yellow/visible
	level = 2
/obj/machinery/networked/atmos/pipe/manifold/yellow/hidden
	level = 1
	alpha=128
/obj/machinery/networked/atmos/pipe/manifold/cyan/visible
	level = 2
/obj/machinery/networked/atmos/pipe/manifold/cyan/hidden
	level = 1
	alpha=128
/obj/machinery/networked/atmos/pipe/manifold/filtering/visible
	level = 2
/obj/machinery/networked/atmos/pipe/manifold/filtering/hidden
	level = 1
	alpha=128

/obj/machinery/networked/atmos/pipe/manifold4w
	icon = 'icons/obj/atmospherics/pipe_manifold.dmi'
	icon_state = "manifold4w"
	name = "4-way pipe manifold"
	desc = "A manifold composed of regular pipes"
	volume = 140
	dir = SOUTH
	initialize_directions = NORTH|SOUTH|EAST|WEST
	var/obj/machinery/networked/atmos/node1
	var/obj/machinery/networked/atmos/node2
	var/obj/machinery/networked/atmos/node3
	var/obj/machinery/networked/atmos/node4
	level = 1
	layer = 2.4 //under wires with their 2.44
	baseicon="manifold4w"

/obj/machinery/networked/atmos/pipe/manifold4w/buildFrom(var/mob/usr,var/obj/item/pipe/pipe)
	dir = pipe.dir
	initialize_directions = pipe.get_pipe_dir()
	var/turf/T = loc
	level = T.intact ? 2 : 1
	initialize(1)
	if(!node1 && !node2 && !node3 && !node4)
		usr << "\red There's nothing to connect this manifold to! (with how the pipe code works, at least one end needs to be connected to something, otherwise the game deletes the segment)"
		return 0
	update_icon()
	build_network()
	if (node1)
		node1.initialize()
		node1.build_network()
	if (node2)
		node2.initialize()
		node2.build_network()
	if (node3)
		node3.initialize()
		node3.build_network()
	if (node4)
		node4.initialize()
		node4.build_network()
	return 1


/obj/machinery/networked/atmos/pipe/manifold4w/hide(var/i)
	if(level == 1 && istype(loc, /turf/simulated))
		invisibility = i ? 101 : 0
	update_icon()


/obj/machinery/networked/atmos/pipe/manifold4w/physical_expansion()
	return list(node1, node2, node3, node4)


/obj/machinery/networked/atmos/pipe/manifold4w/process()
	if(!physnet)
		..()
	else
		. = PROCESS_KILL
	/*
	if(!node1)
		network.mingle_with_turf(loc, 70)
		if(!nodealert)
			//world << "Missing node from [src] at [src.x],[src.y],[src.z]"
			nodealert = 1
	else if(!node2)
		network.mingle_with_turf(loc, 70)
		if(!nodealert)
			//world << "Missing node from [src] at [src.x],[src.y],[src.z]"
			nodealert = 1
	else if(!node3)
		network.mingle_with_turf(loc, 70)
		if(!nodealert)
			//world << "Missing node from [src] at [src.x],[src.y],[src.z]"
			nodealert = 1
	else if (nodealert)
		nodealert = 0
	*/


/obj/machinery/networked/atmos/pipe/manifold4w/Destroy()
	if(node1)
		node1.disconnect(src)
	if(node2)
		node2.disconnect(src)
	if(node3)
		node3.disconnect(src)
	if(node4)
		node4.disconnect(src)

	..()


/obj/machinery/networked/atmos/pipe/manifold4w/disconnect(obj/machinery/networked/atmos/reference)
	if(reference == node1)
		if(istype(node1, /obj/machinery/networked/atmos/pipe))
			del(physnet)
		node1 = null

	if(reference == node2)
		if(istype(node2, /obj/machinery/networked/atmos/pipe))
			del(physnet)
		node2 = null

	if(reference == node3)
		if(istype(node3, /obj/machinery/networked/atmos/pipe))
			del(physnet)
		node3 = null

	if(reference == node4)
		if(istype(node4, /obj/machinery/networked/atmos/pipe))
			del(network)
		node4 = null

	update_icon()

	..()


/obj/machinery/networked/atmos/pipe/manifold4w/update_icon()
	overlays=0
	alpha = invisibility ? 128 : 255
	color = available_colors[_color]
	if(node1&&node2&&node3&&node4)
		icon_state = "[baseicon]"
	else
		icon_state = "[baseicon]_ex"
		var/icon/con = new/icon(icon,"[baseicon]_con") //Since 4-ways are supposed to be directionless, they need an overlay instead it seems.

		if(node1)
			overlays += new/image(con,dir=1)
		if(node2)
			overlays += new/image(con,dir=2)
		if(node3)
			overlays += new/image(con,dir=4)
		if(node4)
			overlays += new/image(con,dir=8)

		if(!node1 && !node2 && !node3 && !node4)
			qdel(src)
	return


/obj/machinery/networked/atmos/pipe/manifold4w/initialize(var/skip_update_icon=0)

	findAllConnections(initialize_directions)

	var/turf/T = src.loc			// hide if turf is not intact
	hide(T.intact)
	if(!skip_update_icon)
		update_icon()

/obj/machinery/networked/atmos/pipe/manifold4w/scrubbers
	name = "Scrubbers pipe"
	_color = "red"
	color=PIPE_COLOR_RED
/obj/machinery/networked/atmos/pipe/manifold4w/supply
	name = "Air supply pipe"
	_color = "blue"
	color=PIPE_COLOR_BLUE
/obj/machinery/networked/atmos/pipe/manifold4w/supplymain
	name = "Main air supply pipe"
	_color = "purple"
	color=PIPE_COLOR_PURPLE
/obj/machinery/networked/atmos/pipe/manifold4w/general
	name = "Air supply pipe"
	_color = "gray"
	color=PIPE_COLOR_GREY
/obj/machinery/networked/atmos/pipe/manifold4w/yellow
	name = "Air supply pipe"
	_color = "yellow"
	color=PIPE_COLOR_YELLOW
/obj/machinery/networked/atmos/pipe/manifold4w/filtering
	name = "Air filtering pipe"
	_color = "green"
	color=PIPE_COLOR_GREEN
/obj/machinery/networked/atmos/pipe/manifold4w/insulated
	icon = 'icons/obj/atmospherics/insulated.dmi'
	name = "Insulated pipe"
	_color = "red"
	alert_pressure = 900*ONE_ATMOSPHERE
	color=IPIPE_COLOR_RED
	level = 2
	available_colors = list(
		"red"=IPIPE_COLOR_RED,
		"blue"=IPIPE_COLOR_BLUE
	)
/obj/machinery/networked/atmos/pipe/manifold4w/scrubbers/visible
	level = 2
/obj/machinery/networked/atmos/pipe/manifold4w/scrubbers/hidden
	level = 1
	alpha=128
/obj/machinery/networked/atmos/pipe/manifold4w/supply/visible
	level = 2
/obj/machinery/networked/atmos/pipe/manifold4w/supply/hidden
	level = 1
	alpha=128
/obj/machinery/networked/atmos/pipe/manifold4w/supplymain/visible
	level = 2
/obj/machinery/networked/atmos/pipe/manifold4w/supplymain/hidden
	level = 1
	alpha=128
/obj/machinery/networked/atmos/pipe/manifold4w/general/visible
	level = 2
/obj/machinery/networked/atmos/pipe/manifold4w/general/hidden
	level = 1
	alpha=128
/obj/machinery/networked/atmos/pipe/manifold4w/filtering/visible
	level = 2
/obj/machinery/networked/atmos/pipe/manifold4w/filtering/hidden
	level = 1
	alpha=128
/obj/machinery/networked/atmos/pipe/manifold4w/yellow/visible
	level = 2
/obj/machinery/networked/atmos/pipe/manifold4w/yellow/hidden
	level = 1
	alpha=128
/obj/machinery/networked/atmos/pipe/manifold4w/insulated/hidden
	level = 1
	alpha=128
/obj/machinery/networked/atmos/pipe/manifold4w/insulated/visible
	level = 2
/obj/machinery/networked/atmos/pipe/manifold4w/insulated/hidden/blue
	color=IPIPE_COLOR_BLUE
	_color = "blue"
/obj/machinery/networked/atmos/pipe/manifold4w/insulated/visible/blue
	color=IPIPE_COLOR_BLUE
	_color = "blue"

/obj/machinery/networked/atmos/pipe/cap
	name = "pipe endcap"
	desc = "An endcap for pipes"
	icon = 'icons/obj/pipes.dmi'
	icon_state = "cap"
	level = 2
	layer = 2.4 //under wires with their 2.44
	volume = 35
	dir = SOUTH
	initialize_directions = NORTH
	var/obj/machinery/networked/atmos/node

/obj/machinery/networked/atmos/pipe/cap/New()
	..()
	switch(dir)
		if(SOUTH)
			initialize_directions = NORTH
		if(NORTH)
			initialize_directions = SOUTH
		if(WEST)
			initialize_directions = EAST
		if(EAST)
			initialize_directions = WEST


/obj/machinery/networked/atmos/pipe/cap/buildFrom(var/mob/usr,var/obj/item/pipe/pipe)
	dir = pipe.dir
	initialize_directions = pipe.get_pipe_dir()
	initialize()
	build_network()
	if(node)
		node.initialize()
		node.build_network()
	return 1


/obj/machinery/networked/atmos/pipe/cap/hide(var/i)
	if(level == 1 && istype(loc, /turf/simulated))
		invisibility = i ? 101 : 0
	update_icon()


/obj/machinery/networked/atmos/pipe/cap/physical_expansion()
	return list(node)


/obj/machinery/networked/atmos/pipe/cap/process()
	if(!physnet)
		..()
	else
		. = PROCESS_KILL


/obj/machinery/networked/atmos/pipe/cap/Destroy()
	if(node)
		node.disconnect(src)

	..()


/obj/machinery/networked/atmos/pipe/cap/disconnect(obj/machinery/networked/atmos/reference)
	if(reference == node)
		if(istype(node, /obj/machinery/networked/atmos/pipe))
			del(physnet)
		node = null

	update_icon()

	..()


/obj/machinery/networked/atmos/pipe/cap/update_icon()
	overlays = 0
	alpha = invisibility ? 128 : 255
	color = available_colors[_color]
	icon_state = "cap"
	return


/obj/machinery/networked/atmos/pipe/cap/initialize(var/skip_update_icon=0)
	node = findConnectingPipe(initialize_directions)

	var/turf/T = src.loc			// hide if turf is not intact
	hide(T.intact)
	if(!skip_update_icon)
		update_icon()

/obj/machinery/networked/atmos/pipe/cap/visible
	level = 2
	icon_state = "cap"
/obj/machinery/networked/atmos/pipe/cap/hidden
	level = 1
	alpha=128

/obj/machinery/networked/atmos/pipe/attackby(var/obj/item/weapon/W as obj, var/mob/user as mob)
	if(istype(W, /obj/item/weapon/pipe_dispenser) || istype(W, /obj/item/device/pipe_painter))
		return // Coloring pipes.
	if (istype(src, /obj/machinery/networked/atmos/pipe/tank))
		return ..()
	if (istype(src, /obj/machinery/networked/atmos/pipe/vent))
		return ..()

	if(istype(W, /obj/item/weapon/reagent_containers/glass/paint/red))
		src._color = "red"
		src.color = PIPE_COLOR_RED
		user << "\red You paint the pipe red."
		update_icon()
		return 1
	if(istype(W, /obj/item/weapon/reagent_containers/glass/paint/blue))
		src._color = "blue"
		src.color = PIPE_COLOR_BLUE
		user << "\red You paint the pipe blue."
		update_icon()
		return 1
	if(istype(W, /obj/item/weapon/reagent_containers/glass/paint/green))
		src._color = "green"
		src.color = PIPE_COLOR_GREEN
		user << "\red You paint the pipe green."
		update_icon()
		return 1
	if(istype(W, /obj/item/weapon/reagent_containers/glass/paint/yellow))
		src._color = "yellow"
		src.color = PIPE_COLOR_YELLOW
		user << "\red You paint the pipe yellow."
		update_icon()
		return 1

	if (!istype(W, /obj/item/weapon/wrench))
		return ..()
	var/turf/T = src.loc
	if (level==1 && isturf(T) && T.intact)
		user << "\red You must remove the plating first."
		return 1
	var/datum/gas_mixture/int_air = return_air()
	var/datum/gas_mixture/env_air = loc.return_air()
	if ((int_air.return_pressure()-env_air.return_pressure()) > 2*ONE_ATMOSPHERE)
		user << "\red You cannot unwrench this [src], it too exerted due to internal pressure."
		add_fingerprint(user)
		return 1
	playsound(get_turf(src), 'sound/items/Ratchet.ogg', 50, 1)
	user << "\blue You begin to unfasten \the [src]..."
	if (do_after(user, 40))
		user.visible_message( \
			"[user] unfastens \the [src].", \
			"\blue You have unfastened \the [src].", \
			"You hear ratchet.")
		new /obj/item/pipe(loc, make_from=src)
		for (var/obj/machinery/meter/meter in T)
			if (meter.target == src)
				new /obj/item/pipe_meter(T)
				del(meter)
		qdel(src)
