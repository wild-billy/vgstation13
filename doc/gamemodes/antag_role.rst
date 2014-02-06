:a:`/antag_role` -- Antag Roles
=============================

:a:`/antag_role` is intended to replace the mess of code that a :a:`/datum/game_mode` would have to execute
just to assign antagonists and set up objectives.  With this new system, thousands of lines of redundant
code has been removed and the gamemode system is far cleaner as a result.

.. atom:: /antag_role(mind=null, parent=null)

	:param /datum/mind mind:
		The mind this role is attaching to. (null for global roles)
	:param /antag_role parent:
		The global role.  Null for global roles.
		
	.. proc:: Drop()
	
		Remove the :a:`/antag_role` from the mind, and execute any defined post-removal actions.
		
	.. proc:: calculateRoleNumbers()
		
		Used primarily for scaling.  This should adjust :v:`min_players` and :v:`max_players`.
		
		.. warning:: This proc is used from a global context.
		
		.. returns boolean 1 on success, 0 on failure
		
	.. proc:: CanBeAssigned(mind)
		
		General sanity checks before assigning the role.
		
		.. warning:: This proc is used from a global context.
		
		.. :param /datum/mind mind:
			The mind to check.
		.. :returns boolean: 1 on success, 0 on failure
		
	.. proc:: CanBeHost(mind)
		
		General sanity checks before assigning host.
		
		.. warning:: This proc is used from a global context.
		
		.. :param /datum/mind mind:
			The mind to check.
		.. :returns boolean: 1 on success, 0 on failure
		
	.. proc:: OnPreSetup()
		
		Do things during the game pre_setup stage.
		
		.. :returns boolean: 1 on success, 0 on failure
		
	.. proc:: process()
	
	.. proc:: OnPostSetup()
		
		.. :returns boolean: 1 on success, 0 on failure
		
	.. proc:: ForgeObjectives()
	
		.. :returns list: List of assigned objectives.
		
	.. proc:: Greet(you_are=1)
		
		Greet the player with role-specific messages.
		
		.. :param boolean you_are:
			Send the "You are an X!" message
			
	.. proc:: PreMindTransfer()
	
	.. proc:: PostMindTransfer()
	
	.. proc:: CheckAntags()
	
		Dump a table for Check Antags.
		
		.. warning:: This proc is used from a global context.
	
	.. proc:: DeclareAll()
		
		Call :proc:Declare() in all assigned minds' roles.
		
		.. warning:: This proc is used from a global context.
		
	.. proc:: Declare()
		
		Declare antagonist objectives.
		
	.. proc:: EditMemory(mind)
		
		Edit the role-specific memory of a given mind.
		
		.. warning:: This proc is used from a global context.
		
		.. :param /datum/mind mind:
			The mind to edit
		.. :returns string: HTML output with editing links.
		
	.. proc:: RoleTopic(href, href_list, mind)
	
		``Topic()`` calls with associated *mind*s.
		
		.. :param string href:
			Entire GET request, as received from Topic()
		.. :param list href_list:
			Parsed GET request.
		.. :param /datum/mind mind:
			The mind to edit