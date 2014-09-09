
//**************************************************************
//
// Doors
// -----------
//
//**************************************************************

// Defines /////////////////////////////////////////////////////

#define DOOR_SHOCK_CHANCE 50
#define DOOR_CRUSH_DAMAGE 10

// Base ////////////////////////////////////////////////////////

/obj/machinery/door
	name = "door"
	desc = "It opens and closes."
	icon = 'icons/obj/doors/door.dmi'
	icon_state = "door_closed"
	anchored = 1
	opacity = 1
	density = 1
	layer = 2.7

	var/busy = 0
	var/clear = 0
	var/bolted = 0
	var/welded = 0
	var/jammed = 0
	var/shocked = 0
	var/aiControl = 0
	var/closeFast = 0
	var/closeForce = 0
	
	var/sfx = 'sound/effects/stonedoor_openclose.ogg'
	
	//TODO: This is crappy
	var/icon_state_prefix = ""
	var/icon_state_open = "door_open"
	var/icon_state_opening = "door_opening"
	var/icon_state_closed = "door_closed"
	var/icon_state_closing = "door_closing"
	var/icon_state_deny = "door_deny"
	var/icon_state_spark = "door_spark"
	
// Setup/Cleanup ///////////////////////////////////////////////
	
/obj/machinery/door/proc/New()
	if(src.clear) src.opacity = 1
	spawn() src.updateNearbyTiles()
	return ..()
	
/obj/machinery/door/proc/Destroy()
	spawn() src.updateNearbyTiles()
	return ..()

// Utilities ///////////////////////////////////////////////////

/obj/machinery/door/proc/isPowered()
	return

// Opening/Closing /////////////////////////////////////////////
	
/obj/machinery/door/proc/open()
	flick(src.icon_state_opening,src)
	src.icon_state = src.icon_state_prefix + src.icon_state_open
	src.opacity = 0
	src.density = 0
	playsound(get_turf(src),src.sfx,100,1)
	if(src.isPowered())
		if(src.closeFast) . = 5
		else . = 20
		spawn(.) src.tryToggleOpen(closeOnly=1)
	spawn() src.updateNearbyTiles()
	return

/obj/machinery/door/proc/close(var/force)
	if(!src.checkObstacles(force)) return
	flick(src.icon_state_closing,src)
	src.icon_state = src.icon_state_prefix + src.icon_state_closed
	if(!src.clear) src.opacity = 1
	src.density = 1
	playsound(get_turf(src),src.sfx,100,1)
	spawn() src.updateNearbyTiles()
	return
	
/obj/machinery/door/proc/tryToggleOpen(mob/user,var/force,var/closeOnly)
	src.busy = 1
	if(src.jammed) . = "It looks damaged."
	else if(src.welded) . = "It's welded shut."
	else if(!force)
		if(src.bolted) . = "It's bolted in this position."
		else if(user && src.isPowered() && (!src.allowed(user)))
			. = "Access Denied."
			flick(src.icon_state_deny,src)
	if(!.)
		if(src.density)
			if(!closeOnly) src.open()
		else src.close(force)
	else if(user) user << "<span class='warning'>[.]</span>"
	src.busy = 0
	return
	
/obj/machinery/door/proc/checkObstacles(var/force)
	if(force || src.closeForce)
		for(var/mob/living/Victim in src.loc)
			Victim.adjustBruteLoss(DOOR_CRUSH_DAMAGE)
			if(istype(Victim,mob/living/carbon)
				Victim.SetStunned(5)
				Victim.SetWeakened(5)
				Victim.emote("scream")
				if(istype(src.loc,/turf/simulated))
					src.loc.add_blood(Victim)
		for(var/obj/structure/window/Window in src.loc)
			Window.Destroy()
	else 
		for(var/atom/A in src.loc)
			if(A.density) return		
		if(locate(/mob/living) in src.loc) return
	return 1
	
// Interaction /////////////////////////////////////////////////

/obj/machinery/door/proc/touchAnalog(mob/user,obj/item/I)
	src.add_fingerprint(user)
	if(src.electrified) src.shock(user)
	src.tryToggleOpen(user)
	return
	
/obj/machinery/door/proc/touchDigital(mob/user,obj/item/I)
	if(src.aiControl) src.tryToggleOpen(user)
	return
	
/obj/machinery/door/attackby(obj/item/I,mob/user)
	src.busy ? return : src.busy = 1
	if(I && istype(I,/obj/item/device/detective_scanner)) return
	if(istype(user,/mob/living))
		if(istype(user,/mob/living/silicon) && (get_dist(user,src)>1))
			src.touchDigital(user,I)
		else src.touchAnalog(user,I)
	src.busy = 0
	return

/obj/machinery/door/attack_ai(mob/user)
	return src.touchDigital(user)

/obj/machinery/door/attack_paw(mob/user)
	return src.attackby(null,user)
	
/obj/machinery/door/attack_hand(mob/user)
	return src.attackby(null,user)
	
/obj/machinery/door/Bumped(atom/movable/AM)
	if(istype(AM,/obj/machinery/bot))
		if((!src.digital) || src.check_access(AM:botcard)) src.tryToggleOpen() 
	else if(istype(AM,/obj/mecha) && AM.density && AM:occupant)
		src.attackby(null,AM.occupant)
	else if(istype(AM,/mob)) src.attackby(user.get_active_hand(),user)
	return

// Atmos Shit //////////////////////////////////////////////////

/obj/machinery/door/proc/updateNearbyTiles()
	if(!air_master) return 0
	for(var/turf/simulated/T in locs)
		air_master.mark_for_update(T)
		if(istype(T))
			if(src.density && (src.opacity || src.heat_proof))
				T.thermal_conductivity = DOOR_HEAT_TRANSFER_COEFFICIENT
			else
				T.thermal_conductivity = initial(T.thermal_conductivity)
	update_freelok_sight()
	return 1

// Miscellaneous ///////////////////////////////////////////////
	
/obj/machinery/door/CanPass(atom/movable/mover,turf/target,height=1.5,air_group = 0)
	if(air_group) return 0
	if(istype(mover) && mover.checkpass(PASSGLASS)) return !opacity
	return !density
	
/obj/machinery/door/emp_act(severity)
	return
	
/obj/machinery/door/ex_act(severity)
	switch(severity)
		if(1.0) qdel(src)
		if(2.0)
			if(prob(25)) qdel(src)
	return

// Shocking ////////////////////////////////////////////////////

/obj/machinery/door/proc/electrify(var/ticks,mob/user)
	src.shocked = 1
	if(src.electrify > 0)
		spawn(ticks) src.shocked = 0
	if(user) spawn()
		src.shockedby += text("\[[time_stamp()]\][usr](ckey:[usr.ckey])")
		user.attack_log += text("\[[time_stamp()]\] <font color='red'>Electrified [src] at [x] [y] [z]</font>")
	return

/obj/machinery/door/proc/shock(mob/user)
	if(istype(user,/mob/living/carbon) && src.isPowered() && prob(DOOR_SHOCK_CHANCE))
		electrocute_mob(user,get_area(src),src))
		var/datum/effect/effect/system/spark_spread/sparks = new
		sparks.set_up(5,1,src)
		sparks.start()
		if(src.shocked == -1) src.shocked = 0
	return

//**************************************************************
// Subtypes ////////////////////////////////////////////////////
//**************************************************************

/obj/machinery/door/morgue
	icon = 'icons/obj/doors/morgue.dmi'

// Undefines ///////////////////////////////////////////////////

#undef DOOR_SHOCK_CHANCE
#undef DOOR_CRUSH_DAMAGE
