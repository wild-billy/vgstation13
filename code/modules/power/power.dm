/obj/machinery/networked/power


/obj/machinery/networked/power/proc/connect_to_network()
	var/turf/T = src.loc
	var/obj/machinery/networked/power/cable/C = T.get_cable_node()
	if(!C)	return 0
	powernet = C.return_network(src)
	return 1

/obj/machinery/networked/power/proc/disconnect_from_network()
	if(!powernet)
		//world << " no powernet"
		return 0
	powernet = null
	return 1