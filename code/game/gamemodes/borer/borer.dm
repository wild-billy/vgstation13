// New modular gamemode system.
// No more snowflake code.

/datum/game_mode/borer
	name = "Cortical Borers"
	config_tag = "borer"
	required_players = 3
	required_players_secret = 10
	restricted_jobs = SILICON_JOBS
	recommended_enemies = 2 // need at least a borer and a host
	votable = 0 // temporarily disable this mode for voting

/datum/game_mode/borer/announce()
	world << "<B>The current game mode is - Cortical Borer!</B>"
	world << "<B>An unknown creature has infested the mind of a crew member. Find and destroy it by any means necessary.</B>"

/datum/game_mode/borer/can_start()
	if(!..())
		return 0

	// for every 10 players, get 1 borer, and for each borer, get a host
	// also make sure that there's at least one borer and one host
	recommended_enemies = max(src.num_players() / 20 * 2, 2)

	var/list/datum/mind/possible_borers = get_players_for_role(BE_ALIEN)

	if(possible_borers.len < 2)
		log_admin("MODE FAILURE: BORER. NOT ENOUGH BORER CANDIDATES.")
		return 0 // not enough candidates for borer

	for(var/obj/machinery/atmospherics/unary/vent_pump/v in world)
		if(!v.welded && v.z == STATION_Z && v.canSpawnMice==1) // No more spawning in atmos.  Assuming the mappers did their jobs, anyway.
			found_vents.Add(v)

	if(found_vents.len < 2)
		log_admin("MODE FAILURE: BORER. NOT ENOUGH VENTS.")
		return 0 // not enough candidates for borer

	// for each 2 possible borers, add one borer and one host
	while(possible_borers.len >= 2)
		var/datum/mind/borer = pick(possible_borers)
		possible_borers.Remove(borer)

		var/datum/mind/first_host = pick(possible_borers)
		possible_borers.Remove(first_host)

		modePlayer += borer
		modePlayer += first_host
		borers += borer
		first_hosts += first_host

		// so that we can later know which host belongs to which borer
		assigned_hosts[borer.key] = first_host

		borer.assigned_role = "MODE" //So they aren't chosen for other jobs.
		borer.special_role = "Borer"

	return 1

/datum/game_mode/borer/pre_setup()
	return 1


/datum/game_mode/borer/post_setup()
	// create a borer and enter it
	for(var/datum/mind/borer in borers)
		// Pick a backup location to spawn at if we can't infest.
		var/spawn_loc
		if(found_vents.len)
			var/vent = pick(found_vents)
			found_vents.Remove(vent)
			spawn_loc=get_turf(vent)
		else
			spawn_loc=pick(xeno_spawn)

		var/mob/living/simple_animal/borer/M = new(spawn_loc,1) // loc, by_gamemode=0
		var/mob/original = borer.current
		borer.transfer_to(M)
		//M.clearHUD()

		// get the host for this borer
		var/datum/mind/first_host = assigned_hosts[borer.key]

		// this is a redundant check, but I don't think the above works..
		// if picking hosts works with this method, remove the method above
		if(!first_host)
			first_host = pick(first_hosts)
			first_hosts.Remove(first_host)

		M.perform_infestation(first_host.current)
		forge_borer_objectives(borer, first_host)

		del(original)

	log_admin("Created [borers.len] borers.")

	spawn (rand(waittime_l, waittime_h))
		send_intercept()
	..()
	return

/datum/game_mode/borer/check_finished()
	var/borers_alive = 0
	for(var/datum/mind/borer in ticker.GetPlayersWithRole("borer"))
		if(!istype(borer.current,/mob/living))
			continue
		if(borer.current.stat==2)
			continue
		borers_alive++

	if (borers_alive)
		return ..()
	else
		return 1
