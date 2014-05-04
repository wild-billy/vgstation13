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

	var/network_type = /datum/network

	Del()
		if(network)
			del(network)
		..()

	proc/process()
		return

	proc/OnPreBuild(var/obj/machinery/networked/base)

	proc/OnPostBuild(var/obj/machinery/networked/base)

	proc/OnNewMember(var/obj/machinery/networked/item)
		return 0

	proc/build_physical_network(var/obj/machinery/networked/base)

		var/list/possible_expansions = list(base)
		members = list(base)
		edges = list()

		base.set_physnet(src)

		OnPreBuild(base)

		while(possible_expansions.len>0)
			for(var/obj/machinery/networked/borderline in possible_expansions)
				if(CanNetworkExpand(borderline))
					var/list/result = borderline.physical_expansion()
					var/edge_check = result.len

					if(result.len>0)
						for(var/obj/machinery/networked/item in result)
							if(!members.Find(item))
								if(OnNewMember(item))
									members += item
									possible_expansions += item
									item.set_physnet(src)
							edge_check--
					if(edge_check>0)
						edges += borderline
				possible_expansions -= borderline

		OnPreBuild(base)

	proc/CanNetworkExpand(var/obj/machinery/networked/result)
		return 0

	proc/network_expand(var/datum/network/new_network, var/obj/machinery/networked/reference)

		if(new_network.physical_networks.Find(src))
			return 0

		new_network.physical_networks += src

		network = new_network

		for(var/obj/machinery/networked/edge in edges)
			for(var/obj/machinery/networked/result in edge.physical_expansion())
				if(!CanNetworkExpand(result) && (result!=reference))
					result.network_expand(new_network, edge)

		return 1

	proc/return_network(var/obj/machinery/atmospherics/reference)
		if(!network)
#ifdef DEBUG
			if(network_type == /datum/network)
				warning("[type] has specified its network_type as [network_type].")
#endif
			network = new network_type()
			network.build_network(src, null)
				//technically passing these parameters should not be allowed
				//however pipe_network.build_network(..) and pipeline.network_extend(...)
				//		were setup to properly handle this case

		return network