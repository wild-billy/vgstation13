///////////////////////////////////
// Antag Datum
///////////////////////////////////
/antag_role/cultist
	name="Cultist"
	id="cultist"
	flags = 0
	protected_jobs = list("Chaplain","AI", "Cyborg", "Security Officer", "Warden", "Detective", "Head of Security", "Captain", "Internal Affairs Agent", "Mobile MMI")
	special_role="Cultist"
	be_flag = BE_CULTIST

	min_players = 4 // 3
	max_players = 4

	// Minds sacrificed.
	var/list/sacrificed=list()

/antag_role/cultist/calculateRoleNumbers()
	return

/antag_role/cultist/OnPostSetup()
	Equip()
	GrantRune()
	update_cult_icons_added(antag)
	return 1

/antag_role/cultist/proc/GrantRune()
	ticker.mode.grant_runeword(antag.current)

/antag_role/cultist/Drop()
	..()
	antag.current << "\red <FONT size = 3><B>An unfamiliar white light flashes through your mind, cleansing the taint of the dark-one and the memories of your time as his servant with it.</B></FONT>"
	antag.memory = ""
	update_cult_icons_removed(antag)
	log_admin("[antag.current] ([ckey(antag.current.key)] has been deconverted from the cult")

/antag_role/cultist/ForgeGroupObjectives()
	if(ticker.mode.config_tag == "cult" && prob(50))
		objectives += new ticker.mode:summon_objective(src)
	else
		objectives += new /datum/group_objective/cult/survive(src,5,7)
	objectives += new /datum/group_objective/targetted/sacrifice(src)

/antag_role/cultist/proc/MemorizeCultObjectives()
	var/text=""
	if(ticker.mode.config_tag=="cult")
		for(var/obj_count = 1,obj_count <= objectives.len,obj_count++)
			var/datum/group_objective/O = objectives[obj_count]
			text +=  "<B>Objective #[obj_count]</B>: [O.explanation_text]"
	text += "The convert rune is join blood self."
	antag.current << text
	antag.memory += "[text]<BR>"


/antag_role/cultist/proc/Equip()
	if (antag)
		if (antag.assigned_role == "Clown")
			antag.current << "Your training has allowed you to overcome your clownish nature, allowing you to wield weapons without harming yourself."
			antag.current.mutations.Remove(M_CLUMSY)
			antag.current.dna.SetSEState(CLUMSYBLOCK,0)

	var/obj/item/weapon/paper/talisman/supply/T = new(antag.current)
	var/list/slots = list (
		"backpack" = slot_in_backpack,
		"left pocket" = slot_l_store,
		"right pocket" = slot_r_store,
		"left hand" = slot_l_hand,
		"right hand" = slot_r_hand,
	)
	var/where = antag.current:equip_in_one_of_slots(T, slots, EQUIP_FAILACTION_DROP)
	if (!where)
		antag.current << "Unfortunately, you weren't able to get a talisman. This is very bad and you should adminhelp immediately."
	else
		antag.current << "You have a talisman in your [where], one that will help you start the cult on this station. Use it well and remember - there are others."
		antag.current.update_icons()
		return 1

/antag_role/cultist/Greet(you_are=1)
	antag.current << "<font color=\"purple\"><b><i>You catch a glimpse of the Realm of Nar-Sie, The Geometer of Blood. You now see how flimsy the world is, you see that it should be open to the knowledge of Nar-Sie.</b></i></font>"
	antag.current << "<font color=\"purple\"><b><i>Assist your new compatriots in their dark dealings. Their goal is yours, and yours is theirs. You serve the Dark One above all else. Bring It back.</b></i></font>"

	MemorizeCultObjectives()


/antag_role/cultist/DeclareAll()
	var/text = ""
	if(objectives.len)
		text += "<br /><b>The cultists' objectives were:</b>"
		for(var/obj_count=1, obj_count <= objectives.len, obj_count++)
			var/datum/group_objective/objective = objectives[obj_count]
			text += "<br /><b>Objective #[obj_count]:</b> [objective.declare()]"

	text += "<br /><FONT size = 2><B>The cultists were:</B></FONT>"
	for(var/datum/mind/mind in minds)
		var/antag_role/R=mind.antag_roles[id]
		R.Declare()

/antag_role/cultist/Declare()
	var/text= "<br>[antag.key] was [antag.name] ("
	if(antag.current)
		if(antag.current.stat == DEAD)
			text += "died"
		else
			text += "survived"
		if(antag.current.real_name != antag.name)
			text += " as [antag.current.real_name]"
	else
		text += "body destroyed"
	text += ")"

	world << text

/antag_role/cultist/EditMemory(var/datum/mind/M)
	var/text="[name]"
	if (ticker.mode.config_tag=="cult")
		text = uppertext(text)
	text = "<i><b>[text]</b></i>: "
	if (M.assigned_role in command_positions)
		text += "<b>HEAD</b>|officer|employee|cultist"
	else if (M.assigned_role in list("Security Officer", "Detective", "Warden"))
		text += "head|<b>OFFICER</b>|employee|cultist"
	else if (M.GetRole("cultist"))
		text += {"head|officer|<a href='?src=\ref[src];remove_role=cultist'>employee</a>|<b>CULTIST</b>
<ul>
	<li>Give <a href='?src=\ref[src];mind=\ref[M];give=tome'>tome</a></li>
	<li>Give <a href='?src=\ref[src];mind=\ref[M];give=amulet'>amulet</a></li>
</ul>"}
	else
		text += "head|officer|<b>EMPLOYEE</b>|<a href='?src=\ref[src];assign_role=cultist'>cultist</a>"

/antag_role/cultist/RoleTopic(href, href_list, var/datum/mind/M)
	if("give" in href_list)
		switch(href_list["give"])
			if("tome")
				var/mob/living/carbon/human/H = M.current
				if (istype(H))
					var/obj/item/weapon/tome/T = new(H)

					var/list/slots = list (
						"backpack" = slot_in_backpack,
						"left pocket" = slot_l_store,
						"right pocket" = slot_r_store,
						"left hand" = slot_l_hand,
						"right hand" = slot_r_hand,
					)
					var/where = H.equip_in_one_of_slots(T, slots)
					if (!where)
						usr << "\red Spawning tome failed!"
					else
						H << "A tome, a message from your new master, appears in your [where]."

			if("amulet")
				var/antag_role/cultist/cultist = M.GetRole("cultist")
				if (!cultist.Equip())
					usr << "\red Spawning amulet failed!"