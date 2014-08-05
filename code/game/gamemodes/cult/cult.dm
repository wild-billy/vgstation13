//This file was auto-corrected by findeclaration.exe on 25.5.2012 20:42:31

/proc/iscultist(mob/living/M as mob)
	return istype(M) && M.GetRole("cultist")

/proc/is_convertable_to_cult(datum/mind/mind)
	if(!istype(mind))	return 0
	if(istype(mind.current, /mob/living/carbon/human) && (mind.assigned_role in list("Captain", "Chaplain")))	return 0
	for(var/obj/item/weapon/implant/loyalty/L in mind.current)
		if(L && (L.imp_in == mind.current))//Checks to see if the person contains an implant, then checks that the implant is actually inside of them
			return 0
	return 1

/datum/game_mode/cult
	name = "cult"
	config_tag = "cult"
	restricted_jobs = list("Chaplain","AI", "Cyborg", "Security Officer", "Warden", "Detective", "Head of Security", "Captain", "Internal Affairs Agent", "Mobile MMI")
	protected_jobs = list()
	required_players = 5
	required_players_secret = 15
	required_enemies = 3
	recommended_enemies = 4

	uplink_welcome = "Nar-Sie Uplink Console:"
	uplink_uses = 10

	var/finished = 0

	startwords = list("blood","join","self","hell")
	allwords = list("travel","self","see","hell","blood","join","tech","destroy", "other", "hide")

	// for the survive objective
	var/const/min_acolytes_needed = 5
	var/const/max_acolytes_needed = 7

	// "Difficulty"
	var/const/min_cultists_to_start = 3
	var/const/max_cultists_to_start = 4

	// Future gamemodes can swap this out to be silly.
	var/summon_objective = /datum/group_objective/cult/summon
	var/summons_left=0

	available_roles=list("cultist")

	var/list/objectives = list()

/datum/game_mode/cult/announce()
	world << "<B>The current game mode is - Cult!</B>"
	world << "<B>Some crewmembers are attempting to start a cult!<BR>\nCultists - complete your objectives. Convert crewmembers to your cause by using the convert rune. Remember - there is no you, there is only the cult.<BR>\nPersonnel - Do not let the cult succeed in its mission. Brainwashing them with the chaplain's bible reverts them to whatever CentCom-allowed faith they had.</B>"

/datum/game_mode/cult/post_setup()
	var/antag_role/cultist/cult = ticker.antag_types["cultist"]

	modePlayer += cult.minds

	//if(!mixed)
	spawn (rand(waittime_l, waittime_h))
		send_intercept()

	..()


/datum/game_mode/proc/add_cultist(datum/mind/cult_mind) //BASE
	if (!istype(cult_mind))
		return 0
	if(!cult_mind.GetRole("cultist") && is_convertable_to_cult(cult_mind))
		cult_mind.assignRole("cultist")
		update_cult_icons_added(cult_mind)

/datum/game_mode/cult/add_cultist(datum/mind/cult_mind) //INHERIT
	if (!..(cult_mind))
		return
	var/antag_role/cultist/cultist = cult_mind.GetRole("cultist")
	cultist.MemorizeCultObjectives()

/datum/game_mode/proc/remove_cultist(datum/mind/cult_mind, show_message = 1)
	if(cult_mind.GetRole("cultist"))
		cult_mind.unassignRole("cultist")
		if(show_message)
			for(var/mob/M in viewers(cult_mind.current))
				M << "<FONT size = 3>[cult_mind.current] looks like they just reverted to their old faith!</FONT>"

/proc/update_all_cult_icons()
	spawn(0)
		var/list/cult=ticker.GetPlayersWithRole("cultist")
		for(var/datum/mind/cultist in cult)
			if(cultist.current)
				if(cultist.current.client)
					for(var/image/I in cultist.current.client.images)
						if(I.icon_state == "cult")
							cultist.current.client.images -= I

		for(var/datum/mind/cultist in cult)
			if(cultist.current)
				if(cultist.current.client)
					for(var/datum/mind/cultist_1 in cult)
						if(cultist_1.current)
							var/I = image('icons/mob/mob.dmi', loc = cultist_1.current, icon_state = "cult")
							cultist.current.client.images += I


/proc/update_cult_icons_added(datum/mind/cult_mind)
	spawn(0)
		for(var/datum/mind/cultist in ticker.GetPlayersWithRole("cultist"))
			if(cultist.current)
				if(cultist.current.client)
					var/I = image('icons/mob/mob.dmi', loc = cult_mind.current, icon_state = "cult")
					cultist.current.client.images += I
			if(cult_mind.current)
				if(cult_mind.current.client)
					var/image/J = image('icons/mob/mob.dmi', loc = cultist.current, icon_state = "cult")
					cult_mind.current.client.images += J


/proc/update_cult_icons_removed(datum/mind/cult_mind)
	spawn(0)
		for(var/datum/mind/cultist in ticker.GetPlayersWithRole("cultist"))
			if(cultist.current)
				if(cultist.current.client)
					for(var/image/I in cultist.current.client.images)
						if(I.icon_state == "cult" && I.loc == cult_mind.current)
							cultist.current.client.images -= I

		if(cult_mind.current)
			if(cult_mind.current.client)
				for(var/image/I in cult_mind.current.client.images)
					if(I.icon_state == "cult")
						cult_mind.current.client.images -= I


/datum/game_mode/cult/proc/get_unconvertables()
	var/list/ucs = list()
	for(var/mob/living/carbon/human/player in mob_list)
		if(!is_convertable_to_cult(player.mind))
			ucs += player.mind
	return ucs

/datum/game_mode/cult/proc/check_cult_victory()
	var/antag_role/cultist/cult = ticker.antag_types["cultist"]
	var/success=1
	for(var/datum/group_objective/O in cult.objectives)
		if(!O.completed) success=0
	return success
/datum/game_mode/cult/declare_completion()

	if(check_cult_victory())
		feedback_set_details("round_end_result","win - cult win")
		//feedback_set("round_end_result",acolytes_survived)
		world << "\red <FONT size = 3><B> The cult wins! It has succeeded in serving its dark masters!</B></FONT>"
	else
		feedback_set_details("round_end_result","loss - staff stopped the cult")
		//feedback_set("round_end_result",acolytes_survived)
		world << "\red <FONT size = 3><B> The staff managed to stop the cult!</B></FONT>"

	var/antag_role/cultist/cult = ticker.antag_types["cultist"]

	world << cult.DeclareAll()
	..()
	return 1
