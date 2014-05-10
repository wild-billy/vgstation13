var/list/all_wire_dirs = all_netdirs + list(NET_NODE)

/obj/machinery/networked/power
	name = "Powered Machine"
	desc = "A machine that can directly tie into the power network."

	// Replaces node1/2/3 vars
	var/list/obj/machinery/networked/power/nodes=list()
	var/list/datum/network/power/powernets=list()
	var/list/connected_dirs = 0

	var/datum/physical_network/power/physnet
	var/datum/network/power/powernet

	var/obj/machinery/networked/power/terminal/terminal

	network_type = /datum/network/power
	physnet_type = /datum/physical_network/power

	icon = 'icons/obj/power.dmi'

	// Type of connection permitted:
	var/connection_type = POWERCONN_KNOT // Compatible with "old" direct wiring.

	use_power = 0
	idle_power_usage = 0
	active_power_usage = 0

/obj/machinery/networked/power/New()
	..()
	// Resize if needed.
	var/newlen = 0
	if(connection_type & POWERCONN_KNOT)
		newlen += 1
	if(connection_type & POWERCONN_TERMINAL)
		newlen += 1
	if(connection_type & POWERCONN_DIRECTIONAL)
		newlen += 8
	nodes.len = newlen
	powernets.len = newlen

/obj/machinery/networked/power/check_physnet()
	physnet=..()

/obj/machinery/networked/power/getNodeType()
	return NETTYPE_POWER

/obj/machinery/networked/power/proc/connect_to_network()
	var/nid=1
	if(connection_type & POWERCONN_KNOT)
		var/turf/T = get_turf(src)
		var/obj/machinery/networked/power/cable/C = T.get_cable_node()
		if(!C)
			stat |= BROKEN
			return 0
		nodes[nid] = C
		powernet = C.return_network(src)
		powernets[nid] += powernet
		nid++

	if(connection_type & POWERCONN_TERMINAL)
		// Stolen from SMES code.
		dir_loop:
			for(var/d in cardinal)
				var/turf/T = get_step(src, d)
				for(var/obj/machinery/networked/power/terminal/term in T)
					if(term && term.dir == turn(d, 180))
						terminal = term
						break dir_loop
		if(!terminal)
			stat |= BROKEN
			return 0
		nodes[nid] = terminal
		powernets[nid] = terminal.powernet
		terminal.master = src
		nid++

	if(connection_type & POWERCONN_DIRECTIONAL)
		findAllConnections(all_netdirs,nid)
	return 1

/obj/machinery/networked/power/proc/disconnect_from_network()
	nodes = 0
	powernets = 0
	powernet = null
	terminal = null
	return 1

// Direct, pipe-style connections (used by wires)
/obj/machinery/networked/power/findAllConnections(var/connect_dirs, var/startnum=1)
	var/node_id=startnum
	var/byond_dir
	for(var/direction in all_wire_dirs)
		if(connect_dirs & direction)
			byond_dir = dir2netdir(direction)
			var/obj/machinery/networked/power/found
			var/node_type=getNodeType(node_id)
			switch(node_type)
				if(NETTYPE_POWER)
					found = findConnectingWire(direction)
				else
					testing("Unknown getNodeType([node_id]) - [type]: [node_type]")
			if(found)
				if(!nodes[node_id])
					nodes[node_id] = found
				if(!powernets[node_id])
					powernets[node_id] = found
				connected_dirs |= byond_dir
			else
				testing("Could not find node #[node_id]: {[x],[y],[z]}")
			node_id++

// Direct, pipe-style connections (used by wires)
/obj/machinery/networked/power/proc/rebuild_connections()
	disconnect_from_network()
	connect_to_network()

/obj/machinery/networked/power/proc/getAvailable()
	powernet = return_network(src)
	return powernet.avail

// Housekeeping and pipe network stuff below
/obj/machinery/networked/power/network_expand(var/datum/network/power/new_network, var/obj/machinery/networked/power/reference)
	var/idx = nodes.Find(reference)
	if(idx)
		powernets[idx]=new_network

	if(new_network.normal_members.Find(src))
		return 0

	new_network.normal_members += src

	return null

/obj/machinery/networked/power/Destroy()
	disconnect_from_network()
	..()

// common helper procs for all power machines
/obj/machinery/networked/power/proc/add_avail(var/amount)
	if(powernet)
		powernet.newavail += amount

/obj/machinery/networked/power/proc/add_load(var/amount)
	if(powernet)
		powernet.newload += amount

/obj/machinery/networked/power/proc/surplus()
	if(powernet)
		return powernet.avail-powernet.load
	else
		return 0

/obj/machinery/networked/power/proc/avail()
	if(powernet)
		return powernet.avail
	else
		return 0

/obj/machinery/networked/power/initialize()
	//if(nodes.len>0) return

	connect_to_network()

	update_icon()

/obj/machinery/networked/power/build_network()
	if(!powernet && nodes.len>0)
		powernet = new /datum/network/power()
		powernet.normal_members += src
		for(var/i=1;i<=nodes.len;i++)
			powernet.build_network(nodes[i], src)

/obj/machinery/networked/power/return_network(var/obj/machinery/networked/power/reference)
	build_network()

	if(reference in nodes)
		return powernet

	return null

/obj/machinery/networked/power/reassign_network(datum/network/power/old_network, datum/network/power/new_network)
	var/idx = powernets.Find(old_network)
	if(idx)
		powernets[idx]=new_network

	if(powernet == old_network)
		powernet = new_network

	return 1

/obj/machinery/networked/power/disconnect(obj/machinery/networked/power/reference)
	if(reference in nodes)
		del(powernet)
		nodes = null

	return null


// returns true if the area has power on given channel (or doesn't require power).
// defaults to power_channel
/obj/machinery/proc/powered(var/chan = -1)

	if(!src.loc)
		return 0

	if(!use_power)
		return 1

	var/area/A = src.loc.loc		// make sure it's in an area
	if(!A || !isarea(A) || !A.master)
		return 0					// if not, then not powered
	if(chan == -1)
		chan = power_channel
	return A.master.powered(chan)	// return power status of the area

// increment the power usage stats for an area
// defaults to power_channel
/obj/machinery/proc/use_power(var/amount, var/chan = -1)
	var/A = getArea()

	if(!A || !isarea(A))
		return

	var/area/B = A

	if (!B.master)
		return

	if (-1 == chan)
		chan = power_channel

	B.master.use_power(amount, chan)

// called whenever the power settings of the containing area change
// by default, check equipment channel & set flag
// can override if needed
/obj/machinery/proc/power_change()
	if(powered(power_channel))
		stat &= ~NOPOWER
	else
		stat |= NOPOWER
	return