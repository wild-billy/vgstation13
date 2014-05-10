// /datum/pipeline
/datum/physical_network/power
	network_type = /datum/network/power

	Del()
		..()

	OnPreBuild(var/obj/machinery/networked/power/cable/base)
		return

	OnPostBuild(var/obj/machinery/networked/power/cable/base)
		return

	OnNewMember(var/obj/machinery/networked/power/cable/item)
		return istype(item)

	CanNetworkExpand(var/obj/machinery/networked/result)
		return istype(result,/obj/machinery/networked/power/cable)
