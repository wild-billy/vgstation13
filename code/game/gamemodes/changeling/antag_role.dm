///////////////////////////////////
// Antag Datum
///////////////////////////////////
/antag_role/changeling
	name="Changeling"
	id="changeling"
	flags = ANTAG_MIXABLE | ANTAG_ADDITIVE
	special_role="Changeling"
	protected_jobs = SILICON_JOBS
	protected_antags = list("borer")

	min_players=1
	max_players=4

	// From /antag_role/changeling, which this replaces.
	var/list/absorbed_dna = list()
	var/absorbedcount = 0
	var/chem_charges = 20
	var/chem_recharge_rate = 0.5
	var/chem_storage = 50
	var/sting_range = 1
	var/honorific = "Broken"
	var/changeling_id = "Changeling"
	var/geneticdamage = 0
	var/isabsorbing = 0
	var/geneticpoints = 5
	var/purchasedpowers = list()
	var/mimicing = ""

/antag_role/changeling/New(var/datum/mind/M=null,var/antag_role/changeling/parent=null)
	if(config.protect_roles_from_antagonist)
		protected_jobs |= SECURITY_JOBS

/antag_role/changeling/calculateRoleNumbers()
	min_players=1 + round(ticker.mode.num_players() / 10)
	max_players=min_players+2
	return 1

/antag_role/changeling/OnPostSetup()
	if(!..()) return 0
	antag.current.make_changeling()
	antag.special_role = "Changeling"
	return 1

/antag_role/changeling/Drop()
	..()

	// Remove all the verbs we've added.
	antag.current.verbs += /antag_role/changeling/proc/EvolutionMenu

	for(var/datum/power/changeling/P in purchasedpowers)
		if(P.isVerb)
			antag.current.verbs -= P.verbpath

/antag_role/changeling/PostMindTransfer()
	if(antag.current.gender == FEMALE)
		honorific = "Ms."
	else
		honorific = "Mr."

	// Only set ID once.
	if(!changeling_id)
		if(possible_changeling_IDs.len)
			changeling_id = pick(possible_changeling_IDs)
			possible_changeling_IDs -= changeling_id
		else
			changeling_id = rand(1,999)

/antag_role/changeling/proc/GetChangelingID()
	return "[honorific] [changeling_id]"

/antag_role/changeling/PreMindTransfer(var/datum/mind/M)
	M.current.verbs -= /antag_role/changeling/proc/EvolutionMenu
	M.current.remove_changeling_powers()

/antag_role/changeling/PostMindTransfer(var/datum/mind/M)
	M.current.make_changeling()

/antag_role/changeling/ForgeObjectives()
	var/list/objectives = list()

	//OBJECTIVES - Always absorb 5 genomes, plus random traitor objectives.
	//If they have two objectives as well as absorb, they must survive rather than escape
	//No escape alone because changelings aren't suited for it and it'd probably just lead to rampant robusting
	//If it seems like they'd be able to do it in play, add a 10% chance to have to escape alone

	var/datum/objective/absorb/absorb_objective = new
	absorb_objective.gen_amount_goal(2, 3)
	objectives += absorb_objective

	var/datum/objective/assassinate/kill_objective = new
	kill_objective.find_target()
	objectives += kill_objective

	var/datum/objective/steal/steal_objective = new
	steal_objective.find_target()
	objectives += steal_objective


	switch(rand(1,100))
		if(1 to 80)
			var/datum/objective/escape/escape_objective = new
			objectives += escape_objective
		else
			var/datum/objective/survive/survive_objective = new
			objectives += survive_objective

	return objectives

/antag_role/changeling/Greet(var/you_are=1)
	if(you_are)
		antag.current << "<B>\red You are a changeling!</B>"
	antag.current << "<b>\red Use say \":g message\" to communicate with your fellow changelings. Remember: you get all of their absorbed DNA if you absorb them.</b>"
	antag.current << "<B>You must complete the following tasks:</B>"

	if (antag)
		if (antag.assigned_role == "Clown")
			antag.current << "You have evolved beyond your clownish nature, allowing you to wield weapons without harming yourself."
			antag.current.dna.SetSEState(CLUMSYBLOCK,0)
			antag.current.mutations.Remove(M_CLUMSY)

	var/obj_count = 1
	for(var/datum/objective/objective in antag.objectives)
		antag << "<B>Objective #[obj_count++]</B>: [objective.explanation_text]"

/antag_role/changeling/proc/regenerate()
	chem_charges = min(max(0, chem_charges+chem_recharge_rate), chem_storage)
	geneticdamage = max(0, geneticdamage-1)

/antag_role/changeling/proc/GetDNA(var/dna_owner)
	var/datum/dna/chosen_dna
	for(var/datum/dna/DNA in absorbed_dna)
		if(dna_owner == DNA.real_name)
			chosen_dna = DNA
			break
	return chosen_dna