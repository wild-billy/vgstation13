// /datum/pipeline
/datum/physical_network/atmos
	var/datum/gas_mixture/air
	var/new_volume = 0
	var/alert_pressure = 0

	network_type = /datum/network/atmos

	Del()
		if(air && air.volume)
			temporarily_store_air()
			del(air)
		..()

	process()
		//Check to see if pressure is within acceptable limits
		var/pressure = air.return_pressure()
		if(pressure > alert_pressure)
			for(var/obj/machinery/networked/atmos/pipe/member in members)
				if(!member.check_pressure(pressure))
					break //Only delete 1 pipe per process

		//Allow for reactions
		//air.react() //Should be handled by pipe_network now
	OnPreBuild(var/obj/machinery/networked/atmos/pipe/base)
		air = new
		alert_pressure = base.alert_pressure
		new_volume = base.volume

		if(base.air_temporary)
			air = base.air_temporary
			base.air_temporary = null
		else
			air = new

	OnPostBuild(var/obj/machinery/networked/atmos/pipe/base)
		air.volume = new_volume

	OnNewMember(var/obj/machinery/networked/atmos/pipe/item)
		if(!istype(item)) return 0
		new_volume += item.volume

		alert_pressure = min(alert_pressure, item.alert_pressure)

		if(item.air_temporary)
			air.merge(item.air_temporary)
		return 1


	CanNetworkExpand(var/obj/machinery/networked/result)
		return istype(result,/obj/machinery/networked/atmos/pipe)

	proc/temporarily_store_air()
		//Update individual gas_mixtures by volume ratio

		for(var/obj/machinery/networked/atmos/pipe/member in members)
			member.air_temporary = new
			member.air_temporary.volume = member.volume

			member.air_temporary.oxygen = air.oxygen*member.volume/air.volume
			member.air_temporary.nitrogen = air.nitrogen*member.volume/air.volume
			member.air_temporary.toxins = air.toxins*member.volume/air.volume
			member.air_temporary.carbon_dioxide = air.carbon_dioxide*member.volume/air.volume

			member.air_temporary.temperature = air.temperature

			if(air.trace_gases.len)
				for(var/datum/gas/trace_gas in air.trace_gases)
					var/datum/gas/corresponding = new trace_gas.type()
					member.air_temporary.trace_gases += corresponding

					corresponding.moles = trace_gas.moles*member.volume/air.volume
			member.air_temporary.update_values()

	proc/mingle_with_turf(turf/simulated/target, mingle_volume)
		var/datum/gas_mixture/air_sample = air.remove_ratio(mingle_volume/air.volume)
		air_sample.volume = mingle_volume

		if(istype(target) && target.zone && !iscatwalk(target))
			//Have to consider preservation of group statuses
			var/datum/gas_mixture/turf_copy = new

			turf_copy.copy_from(target.zone.air)
			turf_copy.volume = target.zone.air.volume //Copy a good representation of the turf from parent group

			equalize_gases(list(air_sample, turf_copy))
			air.merge(air_sample)

			turf_copy.subtract(target.zone.air)

			target.zone.air.merge(turf_copy)

		else
			var/datum/gas_mixture/turf_air = target.return_air()

			equalize_gases(list(air_sample, turf_air))
			air.merge(air_sample)
			//turf_air already modified by equalize_gases()

		/*
		if(istype(target) && !target.processing && !iscatwalk(target))
			if(target.air)
				if(target.air.check_tile_graphic())
					target.update_visuals(target.air)
		*/
		if(network)
			network.update = 1

	proc/temperature_interact(turf/target, share_volume, thermal_conductivity)
		var/total_heat_capacity = air.heat_capacity()
		var/partial_heat_capacity = total_heat_capacity*(share_volume/air.volume)

		if(istype(target, /turf/simulated))
			var/turf/simulated/modeled_location = target

			if(modeled_location.blocks_air)

				if((modeled_location.heat_capacity>0) && (partial_heat_capacity>0))
					var/delta_temperature = air.temperature - modeled_location.temperature

					var/heat = thermal_conductivity*delta_temperature* \
						(partial_heat_capacity*modeled_location.heat_capacity/(partial_heat_capacity+modeled_location.heat_capacity))

					air.temperature -= heat/total_heat_capacity
					modeled_location.temperature += heat/modeled_location.heat_capacity

			else
				var/delta_temperature = 0
				var/sharer_heat_capacity = 0

				if(modeled_location.zone)
					delta_temperature = (air.temperature - modeled_location.zone.air.temperature)
					sharer_heat_capacity = modeled_location.zone.air.heat_capacity()
				else
					delta_temperature = (air.temperature - modeled_location.air.temperature)
					sharer_heat_capacity = modeled_location.air.heat_capacity()

				var/self_temperature_delta = 0
				var/sharer_temperature_delta = 0

				if((sharer_heat_capacity>0) && (partial_heat_capacity>0))
					var/heat = thermal_conductivity*delta_temperature* \
						(partial_heat_capacity*sharer_heat_capacity/(partial_heat_capacity+sharer_heat_capacity))

					self_temperature_delta = -heat/total_heat_capacity
					sharer_temperature_delta = heat/sharer_heat_capacity
				else
					return 1

				air.temperature += self_temperature_delta

				if(modeled_location.zone)
					modeled_location.zone.air.temperature += sharer_temperature_delta/modeled_location.zone.air.group_multiplier
				else
					modeled_location.air.temperature += sharer_temperature_delta


		else
			if((target.heat_capacity>0) && (partial_heat_capacity>0))
				var/delta_temperature = air.temperature - target.temperature

				var/heat = thermal_conductivity*delta_temperature* \
					(partial_heat_capacity*target.heat_capacity/(partial_heat_capacity+target.heat_capacity))

				air.temperature -= heat/total_heat_capacity
		if(network)
			network.update = 1