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

	var/list/raid_objectives = list()     //Raid objectives.

/datum/game_mode/heist/announce()
	world << {"
		<B>The current game mode is - Heist!</B>
		<B>An unidentified bluespace signature has slipped past the Icarus and is approaching [station_name()]!</B>
		Whoever they are, they're likely up to no good. Protect the crew and station resources against this dastardly threat!
		<B>Raiders:</B> Loot [station_name()] for anything and everything you need.
		<B>Personnel:</B> Repel the raiders and their low, low prices and/or crossbows."}

/datum/game_mode/heist/pre_setup()
	return 1

/datum/game_mode/heist/post_setup()

	//Build a list of spawn points.
	var/list/turf/raider_spawn = list()

	for(var/obj/effect/landmark/L in landmarks_list)
		if(L.name == "voxstart")
			raider_spawn += get_turf(L)
			del(L)
			continue

	//Generate objectives for the group.
	raid_objectives = forge_vox_objectives()

	var/index = 1

	//Spawn the vox!
	for(var/datum/mind/raider in raiders)

		if(index > raider_spawn.len)
			index = 1

		raider.current.loc = raider_spawn[index]
		index++


		var/mob/living/carbon/human/vox = raider.current
		raider.name = vox.name
		vox.age = rand(12,20)
		vox.dna.mutantrace = "vox"
		vox.set_species("Vox")
		vox.generate_name()
		vox.languages = list() // Removing language from chargen.
		vox.flavor_text = ""
		vox.add_language("Vox-pidgin")
		vox.h_style = "Short Vox Quills"
		vox.f_style = "Shaved"
		for(var/datum/organ/external/limb in vox.organs)
			limb.status &= ~(ORGAN_DESTROYED | ORGAN_ROBOT)
		vox.equip_vox_raider()
		vox.regenerate_icons()

		raider.objectives = raid_objectives
		greet_vox(raider)

	spawn (rand(waittime_l, waittime_h))
		send_intercept()

/datum/game_mode/heist/proc/is_raider_crew_safe()

	if(raiders.len == 0)
		return 0

	for(var/datum/mind/M in raiders)
		if(!M || !M.current) continue
		if (get_area(M.current) != locate(/area/shuttle/vox/station))
			return 0
	return 1

/datum/game_mode/heist/proc/is_raider_crew_alive()
	if(raiders.len == 0)
		return 0
	for(var/datum/mind/raider in raiders)
		if(!raider) continue
		if(raider.current)
			if(istype(raider.current,/mob/living/carbon/human) && raider.current.stat != 2)
				return 1
	return 0

/datum/game_mode/heist/proc/forge_vox_objectives()


	//Commented out for testing.
	/* var/i = 1
	var/max_objectives = pick(2,2,2,3,3)
	var/list/objs = list()
	while(i<= max_objectives)
		var/list/goals = list("kidnap","loot","salvage")
		var/goal = pick(goals)
		var/datum/objective/heist/O

		if(goal == "kidnap")
			goals -= "kidnap"
			O = new /datum/objective/heist/kidnap()
		else if(goal == "loot")
			O = new /datum/objective/heist/loot()
		else
			O = new /datum/objective/heist/salvage()
		O.choose_target()
		objs += O

		i++

	//-All- vox raids have these two objectives. Failing them loses the game.
	objs += new /datum/objective/heist/inviolate_crew
	objs += new /datum/objective/heist/inviolate_death */

	if(prob(25))
		raid_objectives += new /datum/objective/heist/kidnap
	raid_objectives += new /datum/objective/steal/heist
	raid_objectives += new /datum/objective/steal/salvage
	raid_objectives += new /datum/objective/heist/inviolate_crew
	raid_objectives += new /datum/objective/heist/inviolate_death

	for(var/datum/objective/heist/O in raid_objectives)
		O.choose_target()

	for(var/datum/objective/steal/O in raid_objectives)
		O.find_target()

	return raid_objectives

/datum/game_mode/heist/proc/greet_vox(var/datum/mind/raider)
	raider.current << {"\blue <B>You are a Vox Raider, fresh from the Shoal!</b>
The Vox are a race of cunning, sharp-eyed nomadic raiders and traders endemic to Tau Ceti and much of the unexplored galaxy. You and the crew have come to the Exodus for plunder, trade or both.
Vox are cowardly and will flee from larger groups, but corner one or find them en masse and they are vicious.
Use :V to voxtalk, :H to talk on your encrypted channel, and <b>don't forget to turn on your nitrogen internals!"}
	var/obj_count = 1
	for(var/datum/objective/objective in raider.objectives)
		raider.current << "<B>Objective #[obj_count]</B>: [objective.explanation_text]"
		obj_count++


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
			var/antag_role/group/vox_raider/raider=vox.antag_roles["raider"]
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
		var/antag_role/group/vox_raider/raider=vox.antag_roles["raider"]
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
