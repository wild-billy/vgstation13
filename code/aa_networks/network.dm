var/global/list/datum/network/all_networks = list()
// /datum/pipe_network
/datum/network
	var/list/obj/machinery/networked/normal_members = list()
	var/list/datum/physical_network/physical_networks = list() //membership roster to go through for updates and what not
	var/update = 1
	proc/process()
		if(!update) return 0
		return 1

	proc/build_network(var/obj/machinery/networked/start_normal, var/obj/machinery/networked/reference)
		//Purpose: Generate membership roster
		//Notes: Assuming that members will add themselves to appropriate roster in network_expand()
		// Returns 0 if deleted.

		if(!start_normal)
			del(src)
			return 0

		start_normal.network_expand(src, reference)

		if((normal_members.len>0)||(physical_networks.len>0))
			all_networks += src
		else
			del(src)
			return 0
		return 1

	proc/merge(var/datum/network/giver)
		if(giver==src) return 0

		normal_members |= giver.normal_members

		physical_networks |= giver.physical_networks

		for(var/obj/machinery/networked/normal_member in giver.normal_members)
			normal_member.reassign_network(giver, src)

		for(var/datum/physical_network/physnet in giver.physical_networks)
			physnet.network = src

		del(giver)
		return 1