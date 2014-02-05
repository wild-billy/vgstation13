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
	var/const/waittime_l = 600 //lower bound on time before intercept arrives (in tenths of seconds)
	var/const/waittime_h = 1800 //upper bound on time before intercept arrives (in tenths of seconds)

/datum/game_mode/borer/announce()
	world << "<B>The current game mode is - Cortical Borer!</B>"
	world << "<B>An unknown creature has infested the mind of a crew member. Find and destroy it by any means necessary.</B>"

/datum/game_mode/borer/can_start()
	if(!..())
		return 0

	// for every 10 players, get 1 borer, and for each borer, get a host
	// also make sure that there's at least one borer and one host
	recommended_enemies = max(src.num_players() / 20 * 2, 2)

	return 1

/datum/game_mode/borer/post_setup()
	if(!..()) return 0

	log_admin("Created [ticker.GetPlayersWithRole("borer")] borers.")

	spawn (rand(waittime_l, waittime_h))
		send_intercept()
	..()
	return

/datum/game_mode/proc/greet_borer(var/datum/mind/borer, var/you_are=1)
	if (you_are)
		borer.current << "<B>\red You are a Cortical Borer!</B>"

	var/obj_count = 1
	for(var/datum/objective/objective in borer.objectives)
		borer.current << "<B>Objective #[obj_count]</B>: [objective.explanation_text]"
		obj_count++
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