// attach a wire to a power machine - leads from the turf you are standing on

/obj/machinery/power/attackby(obj/item/weapon/W, mob/user)
	if(istype(W, /obj/item/weapon/cable_coil))

		var/obj/item/weapon/cable_coil/coil = W

		var/turf/T = user.loc

		if(T.intact || !istype(T, /turf/simulated/floor))
			return

		if(get_dist(src, user) > 1)
			return

		if(!directwired)		// only for attaching to directwired machines
			return

		coil.turf_place(T, user)
		return
	else
		..()
	return

// the power cable object
/obj/structure/cable/New()
	..()
	// ensure d1 & d2 reflect the icon_state for entering and exiting cable

	var/dash = findtext(icon_state, "-")

	d1 = text2num( copytext( icon_state, 1, dash ) )

	d2 = text2num( copytext( icon_state, dash+1 ) )

	var/turf/T = src.loc			// hide if turf is not intact

	if(level==1) hide(T.intact)
	cable_list += src


/obj/structure/cable/Destroy()						// called when a cable is deleted
	if(!defer_powernet_rebuild)					// set if network will be rebuilt manually
		if(powernet)
			powernet.cut_cable(src)				// update the powernets
	cable_list -= src
	if(istype(attached))
		attached.SetLuminosity(0)
		attached.icon_state = "powersink0"
		attached.mode = 0
		processing_objects.Remove(attached)
		attached.anchored = 0
		attached.attached = null
	attached = null
	..()													// then go ahead and delete the cable

/obj/structure/cable/hide(var/i)

	if(level == 1 && istype(loc, /turf))
		invisibility = i ? 101 : 0
	updateicon()

/obj/structure/cable/proc/updateicon()
	icon_state = "[d1]-[d2]"
	alpha = invisibility ? 128 : 255


// returns the powernet this cable belongs to
/obj/structure/cable/proc/get_powernet()			//TODO: remove this as it is obsolete
	return powernet

/obj/structure/cable/attack_tk(mob/user)
	return

/obj/structure/cable/attackby(obj/item/W, mob/user)

	var/turf/T = src.loc
	if(T.intact)
		return

	if(istype(W, /obj/item/weapon/wirecutters))

//		if(power_switch)
//			user << "\red This piece of cable is tied to a power switch. Flip the switch to remove it."
//			return

		if (carries == CARRIES_POWER && shock(user, 50))
			return

		if(src.d1)	// 0-X cables are 1 unit, X-X cables are 2 units long
			new coil_type(T, 2, _color)
		else
			new coil_type(T, 1, _color)

		for(var/mob/O in viewers(src, null))
			O.show_message("\red [user] cuts the [src].", 1)

		var/message = "\A [src] has been cut "
		var/atom/A = user
		if(A)
			var/turf/Z = get_turf(A)
			var/area/my_area = get_area(Z)

			// AUTOFIXED BY fix_string_idiocy.py
			// C:\Users\Rob\Documents\Projects\vgstation13\code\modules\power\cable.dm:104: message += " in [my_area.name]. (<A HREF='?_src_=holder;adminplayerobservecoodjump=1;X=[T.x];Y=[T.y];Z=[T.z]'>JMP</A>)"
			message += {"in [my_area.name]. (<A HREF='?_src_=holder;adminplayerobservecoodjump=1;X=[T.x];Y=[T.y];Z=[T.z]'>JMP</A>) (<A HREF='?_src_=vars;Vars=\ref[A]'>VV</A>)"}
			// END AUTOFIX
			var/mob/M = get(A, /mob)
			if(M)
				message += " - Cut By: [M.real_name] ([M.key]) (<A HREF='?_src_=holder;adminplayeropts=\ref[M]'>PP</A>) (<A HREF='?_src_=holder;adminmoreinfo=\ref[M]'>?</A>)"
				log_game("[M.real_name] ([M.key]) cut a wire in [my_area.name] ([T.x],[T.y],[T.z])")
		message_admins(message, 0, 1)
		del(src)

		return	// not needed, but for clarity


	else if(istype(W, /obj/item/weapon/cable_coil))
		var/obj/item/weapon/cable_coil/coil = W
		coil.cable_join(src, user)

	else if(istype(W, /obj/item/device/multitool))
		var/datum/powernet/PN = get_powernet()		// find the powernet
		if(PN && (PN.avail > 0))		// is it powered?
			user << "\red [PN.avail]W in power network."
		else
			user << "\red The [src] is not powered."

		shock(user, 5, 0.2)

	else
		if (W.flags & CONDUCT && carries == CARRIES_POWER)
			shock(user, 50, 0.7)

	src.add_fingerprint(user)

// shock the user with probability prb

/obj/structure/cable/proc/shock(mob/user, prb, var/siemens_coeff = 1.0)
	if(!prob(prb))
		return 0
	if (electrocute_mob(user, powernet, src, siemens_coeff))
		var/datum/effect/effect/system/spark_spread/s = new /datum/effect/effect/system/spark_spread
		s.set_up(5, 1, src)
		s.start()
		return 1
	else
		return 0

/obj/structure/cable/ex_act(severity)
	switch(severity)
		if(1.0)
			qdel(src)
		if(2.0)
			if (prob(50))
				new coil_type(src.loc, src.d1 ? 2 : 1, _color)
				qdel(src)

		if(3.0)
			if (prob(25))
				new coil_type(src.loc, src.d1 ? 2 : 1, _color)
				qdel(src)
	return

/obj/structure/cable/proc/mergeConnectedNetworks(var/direction)
	var/turf/TB
	if(!(d1 == direction || d2 == direction))
		return
	TB = get_step(src, direction)

	for(var/obj/structure/cable/TC in TB)

		if(!TC)
			continue

		// If we carry data and the existing cable carries power, skip over it. - N3X
		if(TC.carries != carries)
			continue

		if(src == TC) // How ...?
			continue

		var/fdir = (!direction)? 0 : turn(direction, 180)

		if(TC.d1 == fdir || TC.d2 == fdir)

			if(!TC.powernet)
				TC.powernet = new()
				powernets += TC.powernet
				TC.powernet.cables += TC

			if(powernet)
				merge_powernets(powernet,TC.powernet)
			else
				powernet = TC.powernet
				powernet.cables += src


/obj/structure/cable/proc/mergeConnectedNetworksOnTurf()
	if(!powernet)
		powernet = new()
		powernets += powernet
		powernet.cables += src

	for(var/AM in loc)
		if(istype(AM,/obj/structure/cable))
			var/obj/structure/cable/C = AM
			// If we carry data and the existing cable carries power, skip over it. - N3X
			if(C.carries != carries)
				continue
			if(C.powernet == powernet)	continue
			if(C.powernet)
				merge_powernets(powernet, C.powernet)
			else
				C.powernet = powernet
				powernet.cables += C

		// Why...?  Below has /obj/machinery/power. - N3X
		else if(istype(AM,/obj/machinery/power/apc))
			var/obj/machinery/power/apc/N = AM
			if(!N.terminal)	continue
			if(N.terminal.powernet)
				merge_powernets(powernet, N.terminal.powernet)
			else
				N.terminal.powernet = powernet
				powernet.nodes[N.terminal] = N.terminal

		else if(istype(AM,/obj/machinery/power))
			var/obj/machinery/power/M = AM
			if(M.powernet == powernet)	continue
			if(M.powernet)
				merge_powernets(powernet, M.powernet)
			else
				M.powernet = powernet
				powernet.nodes[M] = M

		else if(istype(AM,/obj/machinery/networked))
			var/obj/machinery/power/M = AM
			if(M.network == powernet)	continue
			if(M.network)
				merge_powernets(powernet, M.network)
			else
				M.network = powernet
				powernet.nodes[M] = M


obj/structure/cable/proc/cableColor(var/colorC)
	var/color_n = "red"
	if(colorC)
		color_n = colorC
	_color = color_n
	switch(colorC)
		if("red")
			icon = 'icons/obj/power_cond_red.dmi'
		if("yellow")
			icon = 'icons/obj/power_cond_yellow.dmi'
		if("green")
			icon = 'icons/obj/power_cond_green.dmi'
		if("blue")
			icon = 'icons/obj/power_cond_blue.dmi'
		if("pink")
			icon = 'icons/obj/power_cond_pink.dmi'
		if("orange")
			icon = 'icons/obj/power_cond_orange.dmi'
		if("cyan")
			icon = 'icons/obj/power_cond_cyan.dmi'
		if("white")
			icon = 'icons/obj/power_cond_white.dmi'

