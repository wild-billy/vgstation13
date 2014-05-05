var/global/list/datum/network/atmos/power_networks = list()
/datum/network/power
	var/newload = 0
	var/load = 0
	var/newavail = 0
	var/avail = 0
	var/viewload = 0
	var/number = 0
	var/perapc = 0			// per-apc avilability
	var/netexcess = 0

	process()
		//if(update)
		//	update = 0
		load = newload
		newload = 0
		avail = newavail
		newavail = 0


		viewload = 0.8*viewload + 0.2*load

		viewload = round(viewload)

		var/numapc = 0

		if(normal_members && normal_members.len) // Added to fix a bad list bug -- TLE
			for(var/obj/machinery/networked/power/terminal/term in normal_members)
				if( istype( term.master, /obj/machinery/networked/power/apc ) )
					numapc++

		if(numapc)
			perapc = avail/numapc

		netexcess = avail - load

		if( netexcess > 100)		// if there was excess power last cycle
			if(normal_members && normal_members.len)
				for(var/obj/machinery/networked/power/smes/S in normal_members)	// find the SMESes in the network
					if(S.powernet == src)
						S.restore()				// and restore some of the power that was used
					else
						error("[S.name] (\ref[S]) had a [S.network ? "different (\ref[S.powernet])" : "null"] network to our network (\ref[src]).")
						normal_members.Remove(S)

	build_network(var/obj/machinery/networked/power/start_normal, var/obj/machinery/networked/power/reference)
		if(..(start_normal,reference))
			power_networks += src

	merge(var/datum/network/giver)
		if(!..()) return 0
		//update_network_gases()
		return 1

