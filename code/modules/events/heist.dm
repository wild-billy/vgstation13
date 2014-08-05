/*
VOX HEIST ROUNDTYPE
*/

#define MAX_VOX_KILLS 10 //Number of kills during the round before the Inviolate is broken.
						 //Would be nice to use vox-specific kills but is currently not feasible.

var/global/vox_kills = 0 //Used to check the Inviolate.
var/global/vox_sent=0

var/global/list/datum/mind/raiders = list()  //Antags.

/datum/event/heist
	var/list/raid_objectives = list()     //Raid objectives.
	var/list/raiders = list() // Mobs for 'leave nobody behind' objective.

	announceWhen	= 600
	oneShot			= 1

	var/required_candidates = 4
	var/max_candidates = 6
	var/successSpawn = 0	//So we don't make a command report if nothing gets spawned.

/datum/event/heist/setup()
	announceWhen = rand(announceWhen, announceWhen + 50)
	sent_aliens_to_station = 1

/datum/event/heist/announce()
	return


/datum/event/heist/start()

	if(!..())
		return 0

	var/list/candidates = get_candidates(BE_RAIDER)
	var/raider_num = 0

	//Check that we have enough vox.
	if(candidates.len < required_candidates)
		return 0
	else if(candidates.len < max_candidates)
		raider_num = candidates.len
	else
		raider_num = max_candidates

	//Grab candidates randomly until we have enough.
	while(raider_num > 0)
		var/datum/mind/new_raider = pick(candidates)
		raiders += new_raider
		candidates -= new_raider
		raider_num--

	for(var/datum/mind/raider in raiders)
		raider.QuickAssignRole("raider")

	vox_sent=1