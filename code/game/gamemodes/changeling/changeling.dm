// New modular gamemode system.
// No more snowflake code.
var/list/possible_changeling_IDs = list("Alpha","Beta","Gamma","Delta","Epsilon","Zeta","Eta","Theta","Iota","Kappa","Lambda","Mu","Nu","Xi","Omicron","Pi","Rho","Sigma","Tau","Upsilon","Phi","Chi","Psi","Omega")

/datum/game_mode/changeling
	name = "changeling"
	config_tag = "changeling"
	restricted_jobs = list("AI", "Cyborg", "Mobile MMI")
	protected_jobs = list("Security Officer", "Warden", "Detective", "Head of Security", "Captain")
	required_players = 1
	required_players_secret = 10
	required_enemies = 1
	recommended_enemies = 4

	uplink_welcome = "Syndicate Uplink Console:"
	uplink_uses = 10

	var/const/waittime_l = 600 //lower bound on time before intercept arrives (in tenths of seconds)
	var/const/waittime_h = 1800 //upper bound on time before intercept arrives (in tenths of seconds)

	var/list/changelings[0]

/datum/game_mode/changeling/announce()
	world << "<B>The current game mode is - Changeling!</B>"
	world << "<B>There are alien changelings on the station. Do not let the changelings succeed!</B>"

/datum/game_mode/proc/auto_declare_completion_changeling()
	if(ticker.RoleCount("changeling"))
		var/text = "<FONT size = 2><B>The changelings were:</B></FONT>"
		for(var/datum/mind/changeling in ticker.GetPlayersWithRole("changeling"))
			var/antag_role/changeling/changeling_info=changeling.antag_roles["changeling"]
			var/changelingwin = 1

			text += "<br><br>[changeling.key] was [changeling.name] ("
			if(changeling.current)
				if(changeling.current.stat == DEAD)
					text += "died"
				else
					text += "survived"
				if(changeling.current.real_name != changeling.name)
					text += " as [changeling.current.real_name]"
			else
				text += "body destroyed"
				changelingwin = 0
			text += ")"

			//Removed sanity if(changeling) because we -want- a runtime to inform us that the changelings list is incorrect and needs to be fixed.

			// AUTOFIXED BY fix_string_idiocy.py
			// C:\Users\Rob\Documents\Projects\vgstation13\code\game\gamemodes\changeling\changeling.dm:182: text += "<br><b>Changeling ID:</b> [changeling.changeling.changelingID]."
			text += {"<br><b>Changeling ID:</b> [changeling_info.GetChangelingID()].
<b>Genomes Absorbed:</b> [changeling_info.absorbedcount]"}
			// END AUTOFIX
			if(changeling.objectives.len)
				var/count = 1
				for(var/datum/objective/objective in changeling.objectives)
					if(objective.check_completion())
						text += "<br><B>Objective #[count]</B>: [objective.explanation_text] <font color='green'><B>Success!</B></font>"
						feedback_add_details("changeling_objective","[objective.type]|SUCCESS")
					else
						text += "<br><B>Objective #[count]</B>: [objective.explanation_text] <font color='red'>Fail.</font>"
						feedback_add_details("changeling_objective","[objective.type]|FAIL")
						changelingwin = 0
					count++

			if(changelingwin)
				text += "<br><font color='green'><B>The changeling was successful!</B></font>"
				feedback_add_details("changeling_success","SUCCESS")
			else
				text += "<br><font color='red'><B>The changeling has failed.</B></font>"
				feedback_add_details("changeling_success","FAIL")

		world << text

	return 1