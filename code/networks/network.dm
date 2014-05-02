/**************************
* High-level network object
*
* Code stolen from older /datum/physical_network/atmos, made generic
*/

/datum/network
	var/list/obj/machinery/networked/members
	var/list/obj/machinery/networked/edges //Used for building networks

	// Physical network
	var/datum/physical_network/network

/datum/network/Del()
	if(network)
		del(network)
	..()

// API Crap
/datum/network/proc/process()
	return

/datum/network/proc/OnPreBuild(var/obj/machinery/networked/base)
	return

/datum/network/proc/OnPostBuild(var/obj/machinery/networked/base)
	return

/datum/network/proc/OnBuildAddedMember(var/obj/machinery/networked/newmember)
	return

/datum/network/proc/build_network(var/obj/machinery/networked/base)
	var/list/possible_expansions = list(base)
	members = list(base)
	edges = list()

	base.network = src
	OnPreBuild(base)

	while(possible_expansions.len>0)
		for(var/obj/machinery/networked/atmos/pipe/borderline in possible_expansions)

			var/list/result = borderline.network_expansion(src)
			var/edge_check = result.len

			if(edge_check>0)
				for(var/obj/machinery/networked/item in result)
					if(!members.Find(item))
						members += item
						possible_expansions += item
						OnBuildAddedMember(item)
					edge_check--

			if(edge_check>0)
				edges += borderline

			possible_expansions -= borderline
	OnPostBuild(base)

/datum/network/proc/network_expand(var/datum/network/new_network, var/obj/machinery/networked/reference)
	if(new_network.line_members.Find(src))
		return 0

	new_network.line_members += src

	network = new_network

	for(var/obj/machinery/networked/edge in edges)
		for(var/obj/machinery/networked/result in edge.network_expansion())
			if(!istype(result) && (result!=reference))
				result.network_expand(new_network, edge)

	return 1

/datum/network/proc/return_network(var/obj/machinery/networked/reference)
	if(!network)
		network = new /datum/network/atmos()
		network.build_network(src, null)
			//technically passing these parameters should not be allowed
			//however pipe_network.build_network(..) and pipeline.network_extend(...)
			//		were setup to properly handle this case

	return network