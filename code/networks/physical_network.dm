/*******************
* Physical networks.
*
* Was /datum/network/atmos.
*/
var/global/list/datum/physical_network/physnets = list()

/datum/physical_network
	var/list/obj/machinery/networked/normal_members = list()
	var/list/datum/network/line_members = list() //membership roster to go through for updates and what not

	var/update = 1

/datum/physical_network/proc/process()
	if(!update) return 0
	update = 0
	return 1

/datum/physical_network/proc/build_network(var/obj/machinery/networked/start_normal, var/obj/machinery/networked/reference)
	// Purpose: Generate membership roster
	// Notes: Assuming that members will add themselves to appropriate roster in network_expand()
	// Returns 0 if it deleted itself.

	if(!start_normal)
		qdel(src)
		return 0

	start_normal.network_expand(src, reference)

	if((normal_members.len>0)||(line_members.len>0))
		pipe_networks += src
	else
		qdel(src)
		return 0
	return 1

/datum/physical_network/proc/merge(var/datum/physical_network/giver)
	if(giver==src) return 0

	normal_members |= giver.normal_members

	line_members |= giver.line_members

	for(var/obj/machinery/networked/normal_member in giver.normal_members)
		normal_member.reassign_network(giver, src)

	for(var/datum/physical_network/line_member in giver.line_members)
		line_member.network = src

	del(giver)

	//update_network_gases()
	return 1