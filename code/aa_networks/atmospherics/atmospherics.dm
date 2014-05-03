/obj/machinery/networked/atmos
	// Pipe painter color setting.
	var/_color

	var/datum/network/atmos/network
	var/datum/physical_network/atmos/physnet

	network_type = /datum/network/atmos
	physnet_type = /datum/physical_network/atmos

/obj/machinery/networked/atmos/check_network()
	network=..()

/obj/machinery/networked/atmos/check_physnet()
	physnet=..()

/obj/machinery/networked/atmos/proc/return_network_air(datum/network/reference)
	// Return a list of gas_mixture(s) in the object
	//		associated with reference pipe_network for use in rebuilding the networks gases list
	// Is permitted to return null
	return

/obj/machinery/networked/atmos/findAllConnections(var/connect_dirs)
	var/node_id=0
	for(var/direction in cardinal)
		if(connect_dirs & direction)
			node_id++
			var/obj/machinery/networked/atmos/found
			var/node_type=getNodeType(node_id)
			switch(node_type)
				if(NETTYPE_ATMOS)
					found = findConnectingPipe(direction)
				if(NETTYPE_ATMOS_HE)
					found = findConnectingPipeHE(direction)
				else
					error("UNKNOWN RESPONSE FROM [src.type]/getNodeType([node_id]): [node_type]")
					return
			if(!found) continue
			var/node_var="node[node_id]"
			if(!(node_var in vars))
				testing("[node_var] not in vars.")
				return
			if(!vars[node_var])
				vars[node_var] = found