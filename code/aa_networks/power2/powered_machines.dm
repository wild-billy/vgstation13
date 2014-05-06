var/list/all_wire_dirs = all_netdirs + list(PWR_UP)

/obj/machinery/networked/power
	name = "Powered Machine"
	desc = "A machine that can directly tie into the power network."

	// Replaces node1/2/3 vars
	var/list/obj/machinery/networked/power/nodes=list()
	var/list/connected_dirs = 0

	var/datum/physical_network/power/physnet
	var/datum/network/power/network

	network_type = /datum/network/power
	physnet_type = /datum/physical_network/power

/obj/machinery/networked/power/check_network()
	..()

/obj/machinery/networked/power/check_physnet()
	physnet=..()

/obj/machinery/networked/power/findAllConnections(var/connect_dirs)
	var/node_id=0
	var/byond_dir
	for(var/direction in all_wire_dirs)
		if(connect_dirs & direction)
			byond_dir = dir2pwrdir(direction)
			node_id++
			var/obj/machinery/networked/power/found
			var/node_type=getNodeType(node_id)
			switch(node_type)
				if(NETTYPE_POWER)
					found = findConnectingWire(byond_dir)
			if(!found) continue
			if(!nodes[node_id])
				nodes[node_id] = found
			connected_dirs |= byond_dir

/obj/machinery/networked/power/proc/rebuild_connections()
	findAllConnections(all_netdirs)
	update_icon()
	build_network()
	for(var/obj/machinery/networked/power/node in nodes)
		if(!node) continue
		node.initialize()
		node.build_network()

/obj/machinery/networked/power/proc/getAvailable()
	network = return_network(src)
	return network.avail

// Housekeeping and pipe network stuff below
/obj/machinery/networked/power/network_expand(var/datum/network/power/new_network, var/obj/machinery/networked/power/cable/reference)
	if(reference in nodes)
		network = new_network

	if(new_network.normal_members.Find(src))
		return 0

	new_network.normal_members += src

	return null

/obj/machinery/networked/power/Destroy()
	loc = null

	for(var/obj/machinery/networked/power/node in nodes)
		if(node)
			node.disconnect(src)
			del(network)

	nodes = 0

	..()

/obj/machinery/networked/power/initialize()
	if(nodes.len>0) return

	for(var/obj/machinery/networked/power/cable/target in get_turf(src))
		if(target.initialize_directions & PWR_UP)
			nodes += target
			break

	update_icon()

/obj/machinery/networked/power/build_network()
	if(!network && nodes.len>0)
		network = new /datum/network/power()
		network.normal_members += src
		for(var/i=1;i<=nodes.len;i++)
			network.build_network(nodes[i], src)


/obj/machinery/networked/power/return_network(var/obj/machinery/networked/power/reference)
	build_network()

	if(reference in nodes)
		return network

	return null

/obj/machinery/networked/power/reassign_network(datum/network/power/old_network, datum/network/power/new_network)
	if(network == old_network)
		network = new_network

	return 1

/obj/machinery/networked/power/disconnect(obj/machinery/networked/power/reference)
	if(reference in nodes)
		del(network)
		nodes = null

	return null