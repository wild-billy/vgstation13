///////////////////////////////////
// Antag Datum
///////////////////////////////////
/antag_role/borer
	name="Cortical Borer"
	id="borer"
	flags = ANTAG_MIXABLE | ANTAG_NEED_HOST
	protected_jobs = SILICON_JOBS
	special_role="Borer"

	var/list/found_vents[0]

/antag_role/borer/New(var/datum/mind/M=null,var/antag_role/borer/parent=null)
	if(M)
		if(ticker.mode.config_tag=="borer")
			if(!(M in ticker.mode:borers))
				ticker.mode:borers += M

	// Transfer "static" data from parent.
	if(parent)
		found_vents=parent.found_vents
	else
		for(var/obj/machinery/atmospherics/unary/vent_pump/v in world)
			if(!v.welded && v.z == STATION_Z && v.canSpawnMice==1) // No more spawning in atmos.  Assuming the mappers did their jobs, anyway.
				found_vents.Add(v)

/antag_role/borer/CanBeAssigned(var/datum/mind/M)
	return ..()

/antag_role/borer/OnPostSetup()
	if(!host) return 0

	// Pick a backup location to spawn at if we can't infest.
	var/spawn_loc

	if(found_vents.len)
		var/vent = pick(found_vents)
		found_vents.Remove(vent)
		spawn_loc=get_turf(vent)
	else
		spawn_loc=pick(xeno_spawn)

	var/mob/living/simple_animal/borer/M = new(spawn_loc,1) // loc, by_gamemode=0
	var/mob/original = antag.current
	antag.transfer_to(M)
	//M.clearHUD()

	M.perform_infestation(host.current)

	del(original)

	return 1

/antag_role/borer/ForgeObjectives()
	var/list/objectives = list()

	objectives += new /datum/objective/survive

	return objectives

/antag_role/borer/Greet()
	antag << "<B>\red You are a Cortical Borer!</B>"

	var/i=0
	for(var/datum/objective/objective in antag.objectives)
		antag << "<B>Objective #[i++]</B>: [objective.explanation_text]"