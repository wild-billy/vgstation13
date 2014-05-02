/*
Quick overview:

Pipes combine to form pipelines
Pipelines and other atmospheric objects combine to form pipe_networks
	Note: A single pipe_network represents a completely open space

Pipes -> Pipelines
Pipelines + Other Objects -> Pipe network

*/


/obj/machinery/networked
	anchored = 1
	idle_power_usage = 0
	active_power_usage = 0
	power_channel = ENVIRON
	var/nodealert = 0

	// Which directions can we connect with?
	var/initialize_directions = 0

	var/datum/physical_network/network

// Find a connecting /obj/machinery/networked/power in specified direction.
/obj/machinery/proc/findConnectingWire(var/direction)
	if(direction == DOWN)
		for(var/obj/machinery/networked/power/target in get_turf(src))
			if(target.initialize_directions == UP)
				return target
	else
		for(var/obj/machinery/networked/power/target in get_step(src,direction))
			if(target.initialize_directions & get_dir(target,src))
				return target

/*
// Find a connecting /obj/machinery/networked/fiber in specified direction.
/obj/machinery/proc/findConnectingFiber(var/direction)
	if(direction == DOWN)
		for(var/obj/machinery/networked/fiber/target in get_turf(src))
			if(target.initialize_directions == UP)
				return target
	else
		for(var/obj/machinery/networked/fiber/target in get_step(src,direction))
			if(target.initialize_directions & get_dir(target,src))
				return target
*/

// Find a connecting /obj/machinery/networked/atmos/pipe in specified direction.
/obj/machinery/proc/findConnectingPipe(var/direction)
	for(var/obj/machinery/networked/atmos/target in get_step(src,direction))
		if(target.initialize_directions & get_dir(target,src))
			return target

// Ditto, but for heat-exchanging pipes.
/obj/machinery/proc/findConnectingPipeHE(var/direction)
	for(var/obj/machinery/networked/atmos/pipe/simple/heat_exchanging/target in get_step(src,direction))
		if(target.initialize_directions_he & get_dir(target,src))
			return target

/obj/machinery/networked/proc/getNodeType(var/node_id)
	return NETTYPE_ATMOS

// A bit more flexible.
// @param connect_dirs integer Directions at which we should check for connections.
/obj/machinery/networked/proc/findAllConnections(var/connect_dirs)
	return

// Wait..  What the fuck?
// I asked /tg/ and bay and they have no idea why this is here, so into the trash it goes. - N3X
// Re-enabled for debugging.
/obj/machinery/networked/process()
	build_network()

/obj/machinery/networked/proc/network_expand(var/datum/physical_network/atmos/new_network, var/obj/machinery/atmospherics/pipe/reference)
	// Check to see if should be added to network. Add self if so and adjust variables appropriately.
	// Note don't forget to have neighbors look as well!

	return null

/obj/machinery/networked/proc/build_network()
	return null

/obj/machinery/networked/proc/return_network(obj/machinery/atmospherics/reference)
	// Returns pipe_network associated with connection to reference
	// Notes: should create network if necessary
	// Should never return null

	return null

/obj/machinery/networked/proc/reassign_network(datum/physical_network/atmos/old_network, datum/physical_network/atmos/new_network)
	// Used when two pipe_networks are combining

/obj/machinery/networked/proc/check_network()
	//if(!network)
	//	network = new /datum/network/power()
	//	network.build_network(src)

/obj/machinery/networked/proc/disconnect(var/obj/machinery/networked/reference)

/obj/machinery/networked/update_icon()
	return null

/obj/machinery/networked/proc/buildFrom(var/mob/usr,var/obj/item/pipe/pipe)
	error("[src] does not define a buildFrom!")
	return FALSE


/obj/machinery/networked/build_network()
	// Called to build a network from this node
	check_network()
	return network.return_network()


/obj/machinery/networked/network_expand(var/datum/physical_network/new_network, var/obj/machinery/networked/reference)
	check_network()
	return network.network_expand(new_network, reference)

/obj/machinery/networked/Destroy()
	del(network)
	..()

/obj/machinery/networked/proc/network_expansion()
	return null