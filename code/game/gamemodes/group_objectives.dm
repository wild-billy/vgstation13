/**
 * GROUP OBJECTIVES
 *
 * Primarily to clean up Cult's awful fucking objectives.
 */

/datum/group_objective
	var/explanation_text = "Nothing"	//What that group is supposed to do.
	var/completed = 0					//currently only used for custom objectives.

	New(var/text)
		if(text)
			explanation_text = text

	proc/check_completion()
		return completed

/datum/group_objective/targetted
	var/datum/mind/target = null		//If they are focused on a particular person.

	proc/find_target()
		var/list/possible_targets = list()
		for(var/datum/mind/possible_target in ticker.minds)
			if(possible_target != owner && ishuman(possible_target.current) && (possible_target.current.stat != 2))
				possible_targets += possible_target
		if(possible_targets.len > 0)
			target = pick(possible_targets)


	proc/find_target_by_role(role, role_type=0, invert=0)//Option sets either to check assigned role or special role. Default to assigned.
		for(var/datum/mind/possible_target in ticker.minds)
			if((possible_target != owner) && ishuman(possible_target.current) && ((role_type ? possible_target.special_role : possible_target.assigned_role) == role) )
				if(!invert)
					target = possible_target
					break
			else
				if(invert)
					target = possible_target
					break

	/*
	.. function:: find_target_by_antag_role(role_id=null, invert=0)
		:param string role_id:
			The ID of the antag_role to locate, or null to find minds with ANY antag_role set.
		:param int invert:
			Instead of finding those with the given role_id, we find those WITHOUT the role_id.
	*/
	proc/find_target_by_antag_role(role_id=null, invert=0)
		for(var/datum/mind/possible_target in ticker.minds)
			if(possible_target != owner && ishuman(possible_target.current) && possible_target.antag_roles.len>0 && (role_id == null || role_id in possible_target.antag_roles))
				if(!invert)
					target = possible_target
					break
			else
				if(invert)
					target = possible_target
					break
