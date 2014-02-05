///////////////////////////////////
// Antag Datum
///////////////////////////////////
/antag_role/blob
	name="Blob"
	id="blob"
	flags = 0
	protected_jobs = SILICON_JOBS
	special_role="Blob"
	be_flag = BE_ALIEN

	var/const/cores_to_spawn = 1
	var/const/players_per_core = 30
	var/const/blob_point_rate = 3

/antag_role/blob/calculateRoleNumbers()
	min_players = max(round(ticker.mode.num_players()/players_per_core, 1), 1)
	max_players = min_players

/antag_role/blob/OnPostSetup()
	log_game("[antag.key] (ckey) has been selected as a Blob")
	return 1

/antag_role/blob/ForgeObjectives()
	var/list/objectives = list()

	objectives += new /datum/objective/survive

	return objectives

/antag_role/blob/Greet(you_are=1)
	antag.current << {"<B>\red You are infected by the Blob!</B>
<b>Your body is ready to give spawn to a new blob core which will eat this station.</b>
<b>Find a good location to spawn the core and then take control and overwhelm the station!</b>
<b>When you have found a location, wait until you spawn; this will happen automatically and you cannot speed up the process.</b>
<b>If you go outside of the station level, or in space, then you will die; make sure your location has lots of ground to cover.</b>"}


/antag_role/blob/DeclareAll()
	world << "<FONT size = 2><B>The blob[(minds.len > 1 ? "s were" : " was")]:</B></FONT>"
	for(var/datum/mind/mind in minds)
		var/antag_role/R=mind.antag_roles[id]
		R.Declare()

/antag_role/blob/Declare()
	var/win = 1
	if(antag.current)
		world << "<br /><B>[antag.current.key] was [antag.current.name].</B>"

		var/count = 1
		for(var/datum/objective/objective in antag.objectives)
			if(objective.check_completion())
				world << "<B>Objective #[count]</B>: [objective.explanation_text] \green <B>Success</B>"
				feedback_add_details("borer_objective","[objective.type]|SUCCESS")
			else
				world << "<B>Objective #[count]</B>: [objective.explanation_text] \red Failed"
				feedback_add_details("borer_objective","[objective.type]|FAIL")
				win = 0
			count++

	else
		win = 0

	if(win)
		world << "<B>The blob was successful!<B>"
		feedback_add_details("blob_success","SUCCESS")
	else
		world << "<B>The blob has failed!<B>"
		feedback_add_details("blob_success","FAIL")