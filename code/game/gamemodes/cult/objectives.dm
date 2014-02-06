// Sacrifice some dude.
/datum/group_objective/targetted/sacrifice
	find_target()
		find_target_by_antag_role("cultist",1)
		explanation_text="Sacrifice [sacrifice_target.name], the [sacrifice_target.assigned_role]."

