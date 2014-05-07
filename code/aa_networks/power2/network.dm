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

/datum/network/power/process()
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
					error("[S.name] (\ref[S]) had a [S.powernet ? "different (\ref[S.powernet])" : "null"] network to our network (\ref[src]).")
					normal_members.Remove(S)

/datum/network/power/build_network(var/obj/machinery/networked/power/start_normal, var/obj/machinery/networked/power/reference)
	if(..(start_normal,reference))
		power_networks += src

/datum/network/power/merge(var/datum/network/giver)
	if(!..()) return 0
	//update_network_gases()
	return 1

/datum/network/power/proc/get_electrocute_damage()
	switch(avail)/*
		if (1300000 to INFINITY)
			return min(rand(70,150),rand(70,150))
		if (750000 to 1300000)
			return min(rand(50,115),rand(50,115))
		if (100000 to 750000-1)
			return min(rand(35,101),rand(35,101))
		if (75000 to 100000-1)
			return min(rand(30,95),rand(30,95))
		if (50000 to 75000-1)
			return min(rand(25,80),rand(25,80))
		if (25000 to 50000-1)
			return min(rand(20,70),rand(20,70))
		if (10000 to 25000-1)
			return min(rand(20,65),rand(20,65))
		if (1000 to 10000-1)
			return min(rand(10,20),rand(10,20))*/
		if (5000000 to INFINITY)
			return min(rand(100,180),rand(100,180))
		if (4500000 to 5000000)
			return min(rand(80,160),rand(80,160))
		if (1000000 to 4500000)
			return min(rand(50,140),rand(50,140))
		if (200000 to 1000000)
			return min(rand(25,80),rand(25,80))
		if (100000 to 200000)//Ave powernet
			return min(rand(20,60),rand(20,60))
		if (50000 to 100000)
			return min(rand(15,40),rand(15,40))
		if (1000 to 50000)
			return min(rand(10,20),rand(10,20))
		else
			return 0