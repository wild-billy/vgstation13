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

/datum/game_mode/borer/post_setup()
	if(!..()) return 0

	log_admin("Created [ticker.GetPlayersWithRole("borer")] borers.")

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