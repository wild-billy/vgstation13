/*
VOX HEIST ROUNDTYPE
*/

#define MAX_VOX_KILLS 10 //Number of kills during the round before the Inviolate is broken.
						 //Would be nice to use vox-specific kills but is currently not feasible.
						 // FIXED, HONK HONK - N3X

/datum/game_mode/heist
	name = "heist"
	config_tag = "heist"
	required_players = 15
	required_players_secret = 25
	required_enemies = 4
	recommended_enemies = 6

	// Objectives and cortical stacks are now handled by the antag_role.

	available_roles=list("raider")

/datum/game_mode/heist/announce()
	world << {"
		<B>The current game mode is - Heist!</B>
		<B>An unidentified bluespace signature has slipped past the Icarus and is approaching [station_name()]!</B>
		Whoever they are, they're likely up to no good. Protect the crew and station resources against this dastardly threat!
		<B>Raiders:</B> Loot [station_name()] for anything and everything you need.
		<B>Personnel:</B> Repel the raiders and their low, low prices and/or crossbows."}

/datum/game_mode/heist/pre_setup()
	return 1

/datum/game_mode/heist/declare_completion()

	var/win_type = "Major"
	var/win_group = "Crew"
	var/win_msg = ""

	var/antag_role/group/vox_raider/group = ticker.antag_types["raider"]

	var/success = group.objectives.len

	//Decrease success for failed objectives.
	for(var/datum/group_objective/O in group.objectives)
		if(!(O.check_completion()))
			success--

	//Set result by objectives.
	if(success == group.objectives.len)
		win_type = "Major"
		win_group = "Vox"
	else if(success > 2)
		win_type = "Minor"
		win_group = "Vox"
	else
		win_type = "Minor"
		win_group = "Crew"

	//Now we modify that result by the state of the vox crew.
	if(!group.GetNumAlive())

		win_type = "Major"
		win_group = "Crew"
		win_msg += "<B>The Vox Raiders have been wiped out!</B>"

	else if(group.GetNumLeftBehind())
		if(win_group == "Crew" && win_type == "Minor")
			win_type = "Major"
		win_group = "Crew"
		win_msg += "<B>The Vox Raiders have left someone behind!</B>"
	else
		if(win_group == "Vox")
			if(win_type == "Minor")
				win_type = "Major"
			win_msg += "<B>The Vox Raiders escaped the station!</B>"
		else
			win_msg += "<B>The Vox Raiders were repelled!</B>"

	world << {"\red <FONT size = 3><B>[win_type] [win_group] victory!</B></FONT>
		[win_msg]"}
	feedback_set_details("round_end_result","heist - [win_type] [win_group]")
	world << group.DeclareAll()
	return 1

	..()

datum/game_mode/proc/auto_declare_completion_heist()
	if(ticker.GetPlayersWithRole("raiders"))
		var/check_return = 0
		if(ticker && istype(ticker.mode,/datum/game_mode/heist))
			check_return = 1
		var/text = "<FONT size = 2><B>The vox raiders were:</B></FONT>"

		for(var/datum/mind/vox in ticker.GetPlayersWithRole("raider"))
			text += "<br>[vox.key] was [vox.name] ("
			var/antag_role/group/vox_raider/raider=vox.GetRole("raider")
			if(check_return)
				if(get_area(raider.cortical_stack) != locate(/area/shuttle/vox/station))
					text += "left behind)"
					continue
			if(vox.current)
				if(vox.current.stat == DEAD)
					text += "died"
				else
					text += "survived"
				if(vox.current.real_name != vox.name)
					text += " as [vox.current.real_name]"
			else
				text += "body destroyed"
			text += ")"

		world << text
	return 1

/datum/game_mode/heist/check_finished()
	var/num_alive=0
	var/check_return = 0
	if(ticker && istype(ticker.mode,/datum/game_mode/heist))
		check_return = 1
	for(var/datum/mind/vox in ticker.GetPlayersWithRole("raider"))
		var/antag_role/group/vox_raider/raider=vox.GetRole("raider")
		if(!vox.current)
			continue
		if(vox.current.stat == DEAD)
			continue
		if(check_return)
			if(get_area(raider.cortical_stack) != locate(/area/shuttle/vox/station))
				continue
		num_alive++
	if (num_alive==0 || (vox_shuttle_location && (vox_shuttle_location == "start")))
		return 1
	return ..()
