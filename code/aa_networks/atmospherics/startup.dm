// Hook into the events we desire.
/hook_handler/atmos_handler
	// Set up player on login
	proc/OnInitNetworks(var/list/args)
		var/count=0
		for(var/obj/machinery/networked/atmos/M in machines)
			M.build_network()
			count++
		world << "\red [count] atmos devices activated."