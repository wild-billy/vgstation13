/**************************
* Physical Networks
*
* Collections of pipes and machines.
*
* Code stolen from older /datum/pipeline, made generic
*/
// /datum/pipeline
/datum/physical_network

	var/list/obj/machinery/networked/members
	var/list/obj/machinery/networked/edges //Used for building networks

	var/datum/network/network

	var/net_type = /datum/network

	Del()
		if(network)
			del(network)
		..()

	proc/process()
		return

	proc/OnPreBuild(var/obj/machinery/networked/base)

	proc/OnPostBuild(var/obj/machinery/networked/base)

	proc/OnNewMember(var/obj/machinery/networked/item)

	proc/build_physical_network(var/obj/machinery/networked/base)

		var/list/possible_expansions = list(base)
		members = list(base)
		edges = list()

		base.set_physnet(src)

		OnPreBuild(base)

		while(possible_expansions.len>0)
			for(var/obj/machinery/networked/borderline in possible_expansions)
				var/list/result = borderline.physical_expansion()
				var/edge_check = result.len

				if(result.len>0)
					for(var/obj/machinery/networked/item in result)
						if(!members.Find(item))
							members += item
							possible_expansions += item
							item.set_physnet(src)

							OnNewMember(item)

						edge_check--

				if(edge_check>0)
					edges += borderline

				possible_expansions -= borderline

		OnPreBuild(base)

	proc/network_expand(var/datum/network/new_network, var/obj/machinery/networked/reference)

		if(new_network.physical_networks.Find(src))
			return 0

		new_network.physical_networks += src

		network = new_network

		for(var/obj/machinery/networked/edge in edges)
			for(var/obj/machinery/networked/result in edge.physical_expansion())
				if(!istype(result,/obj/machinery/networked) && (result!=reference))
					result.network_expand(new_network, edge)

		return 1

	proc/return_network(var/obj/machinery/atmospherics/reference)
		if(!network)
			network = new net_type()
			network.build_network(src, null)
				//technically passing these parameters should not be allowed
				//however pipe_network.build_network(..) and pipeline.network_extend(...)
				//		were setup to properly handle this case

		return network