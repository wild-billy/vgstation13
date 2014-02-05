/**
* Used in Mixed Mode, also simplifies equipping antags for other gamemodes and
* for the traitor panel.
*
* By N3X15
*/

#define ANTAG_MIXABLE   1 // Can be used in mixed mode
#define ANTAG_NEED_HOST 2 // Antag needs a host/partner
#define ANTAG_ADDITIVE  4 // Antag can be added on top of another antag.
#define ANTAG_GOOD      8 // Role is not actually an antag. (Used for GetAllBadMinds() etc)

/antag_role
	//////////////////////////////
	// "Static" vars
	//////////////////////////////
	// Unique ID of the definition.
	var/id = null

	// Displayed name of the antag type
	var/name = null

	var/plural_name = null

	// Various flags and things.
	var/flags = 0

	// Jobs that cannot be this antag.
	var/list/protected_jobs=list()

	// Antag IDs that cannot be used with this antag type. (cultists can't be wizard, etc)
	var/list/protected_antags=list()

	// Antags protected from becoming host
	var/list/protected_host_antags=list()

	// If set, sets special_role to this
	var/special_role=null

	// If set, assigned role is set to MODE to prevent job assignment.
	var/disallow_job=0

	var/min_players=0
	var/max_players=0

	var/be_flag = BE_TRAITOR

	// List of minds assigned to this role
	var/list/minds=list()

	//////////////////////////////
	// Local
	//////////////////////////////
	// Actual antag
	var/datum/mind/antag=null

	// The host (set if NEED_HOST)
	var/datum/mind/host=null

/antag_role/New(var/datum/mind/M=null, var/antag_role/parent=null)
	if(M)
		if(!(M in parent.minds))
			parent.minds += M
		ticker.mode.add_player_role_association(M,parent.id)
	if(!plural_name)
		plural_name="[name]s"

// Remove
/antag_role/proc/Drop()
	if(!antag) return
	var/antag_role/parent = ticker.antag_types[id]
	parent.minds -= antag
	ticker.mode.remove_player_role_association(antag,id)
	del(src)

// Scaling, should fuck with min/max players.
// Return 1 on success, 0 on failure.
/antag_role/proc/calculateRoleNumbers()
	return 1

// General sanity checks before assigning antag.
// Return 1 on success, 0 on failure.
/antag_role/proc/CanBeAssigned(var/datum/mind/M)
	if(protected_jobs.len>0)
		if(M.assigned_role in protected_jobs)
			return 0

	if(protected_antags.len>0)
		for(var/forbidden_role in protected_antags)
			if(forbidden_role in M.antag_roles)
				return 0
	return 1

// General sanity checks before assigning host.
// Return 1 on success, 0 on failure.
/antag_role/proc/CanBeHost(var/datum/mind/M)
	if(protected_jobs.len>0)
		if(M.assigned_role in protected_jobs)
			return 0

	if(protected_antags.len>0)
		for(var/forbidden_role in protected_host_antags)
			if(forbidden_role in M.antag_roles)
				return 0
	return 1

/antag_role/proc/OnPreSetup()
	if(special_role)
		antag.special_role=special_role
	if(disallow_job)
		antag.assigned_role="MODE"
		ticker.mode.modePlayer += antag
	return 1

/antag_role/proc/process()
	return

// Return 1 on success, 0 on failure.
/antag_role/proc/OnPostSetup()
	for(var/datum/objective/O in ForgeObjectives())
		O.owner=antag
		antag.objectives += O
	return 0

// Return list of objectives.
/antag_role/proc/ForgeObjectives()
	return list()

/antag_role/proc/Greet(var/you_are=1)
	return

/antag_role/proc/PreMindTransfer(var/datum/mind/M)
	return

/antag_role/proc/PostMindTransfer(var/datum/mind/M)
	return

// Dump a table for Check Antags.
/antag_role/proc/CheckAntags()
	// HOW DOES EVERYONE MISS FUCKING COLSPAN
	// AM I THE ONLY ONE WHO REMEMBERS XHTML
	var/dat = "<br><table cellspacing=5><tr><td colspan=\"3\"><B>[plural_name]</B></td></tr>"
	for(var/datum/mind/mind in minds)
		var/mob/M=mind.current
		//var/antag_role/R=mind.antag_roles[id]
		dat += {"<tr><td><a href='?src=\ref[src];adminplayeropts=\ref[M]'>[M.real_name]</a>[M.client ? "" : " <i>(logged out)</i>"][M.stat == 2 ? " <b><font color=red>(DEAD)</font></b>" : ""]</td>
						<td><A href='?src=\ref[usr];priv_msg=\ref[M]'>PM</A></td>
						<td><A HREF='?src=\ref[src];traitor=\ref[M]'>Show Objective</A></td></tr>"}
	dat += "</table>"
	return dat

/antag_role/proc/DeclareAll()

	for(var/datum/mind/mind in minds)
		var/antag_role/R=mind.antag_roles[id]
		R.Declare()

/antag_role/proc/Declare()
	world << "\red <b>[type] didn't make a Declare() override!</b>"