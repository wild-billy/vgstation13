// the power monitoring computer
// for the moment, just report the status of all APCs in the same powernet
/obj/machinery/networked/power/monitor
	name = "power monitoring computer"
	desc = "It monitors power levels across the station."
	icon = 'icons/obj/computer.dmi'
	icon_state = "power"
	density = 1
	anchored = 1
	use_power = 2
	idle_power_usage = 20
	active_power_usage = 80

// There was a New() here.  It's gone now - N3X

/obj/machinery/networked/power/monitor/attack_ai(mob/user)
	src.add_hiddenprint(user)
	add_fingerprint(user)

	if(stat & (BROKEN|NOPOWER))
		return
	interact(user)

/obj/machinery/networked/power/monitor/attack_hand(mob/user)
	add_fingerprint(user)

	if(stat & (BROKEN|NOPOWER))
		return
	interact(user)

/obj/machinery/networked/power/monitor/attackby(I as obj, user as mob)
	if(istype(I, /obj/item/weapon/screwdriver))
		playsound(get_turf(src), 'sound/items/Screwdriver.ogg', 50, 1)
		if(do_after(user, 20))
			if (src.stat & BROKEN)
				user << "\blue The broken glass falls out."
				var/obj/structure/computerframe/A = new /obj/structure/computerframe( src.loc )
				getFromPool(/obj/item/weapon/shard, loc)
				var/obj/item/weapon/circuitboard/powermonitor/M = new /obj/item/weapon/circuitboard/powermonitor( A )
				for (var/obj/C in src)
					C.loc = src.loc
				A.circuit = M
				A.state = 3
				A.icon_state = "3"
				A.anchored = 1
				del(src)
			else
				user << "\blue You disconnect the monitor."
				var/obj/structure/computerframe/A = new /obj/structure/computerframe( src.loc )
				var/obj/item/weapon/circuitboard/powermonitor/M = new /obj/item/weapon/circuitboard/powermonitor( A )
				for (var/obj/C in src)
					C.loc = src.loc
				A.circuit = M
				A.state = 4
				A.icon_state = "4"
				A.anchored = 1
				del(src)
	else
		src.attack_hand(user)
	return

/obj/machinery/networked/power/monitor/interact(mob/user)

	if ( (get_dist(src, user) > 1 ) || (stat & (BROKEN|NOPOWER)) )
		if (!istype(user, /mob/living/silicon))
			user.unset_machine()
			user << browse(null, "window=powcomp")
			return


	user.set_machine(src)
	var/t = "<TT><B>Power Monitoring</B><HR>"


	// AUTOFIXED BY fix_string_idiocy.py
	// C:\Users\Rob\Documents\Projects\vgstation13\code\game\machinery\computer\power.dm:84: t += "<BR><HR><A href='?src=\ref[src];update=1'>Refresh</A>"
	t += {"<BR><HR><A href='?src=\ref[src];update=1'>Refresh</A>
		<BR><HR><A href='?src=\ref[src];close=1'>Close</A>"}
	// END AUTOFIX
	if(!powernet)
		t += "\red No connection"
	else

		var/list/L = list()
		for(var/obj/machinery/networked/power/terminal/term in powernet.normal_members)
			if(istype(term.master, /obj/machinery/networked/power/apc))
				var/obj/machinery/networked/power/apc/A = term.master
				L += A


		// AUTOFIXED BY fix_string_idiocy.py
		// C:\Users\Rob\Documents\Projects\vgstation13\code\game\machinery\computer\power.dm:97: t += "<PRE>Total power: [powernet.avail] W<BR>Total load:  [num2text(powernet.viewload,10)] W<BR>"
		t += {"<div style="font-family:monospace;">
			Total power: [powernet.avail] W
			Total load:  [num2text(powernet.viewload,10)] W
			<table border="0" style="font-size:-1">
				<tr>
					<th>Area</th>
					<th title="Equipment">Eq</th>
					<th title="Lighting">Li</th>
					<th title="Environment">En</th>
					<th>Load</th>
					<th>Cell</th>
				</tr>"}
		// END AUTOFIX
		if(L.len > 0)
			var/list/S = list("Off","AOff","On", "AOn")
			var/list/chg = list("N","C","F")

			for(var/obj/machinery/networked/power/apc/A in L)
				var/areaname = copytext("\The [A.area]", 1, 30)
				var/cellstatus = "N/C"
				if(A.cell)
					cellstatus = "[round(A.cell.percent())]% [chg[A.charging+1]]"
				t += {"
				<tr>
					<td>[areaname]</td>
					<td>[S[A.equipment+1]]</td>
					<td>[S[A.lighting+1]]</td>
					<td>[S[A.environ+1]]</td>
					<td>[A.lastused_total]</td>
					<td>[cellstatus]</td>
				</tr>"}

		t += "</table></div>"

	user << browse(t, "window=powcomp;size=420x900")
	onclose(user, "powcomp")


/obj/machinery/networked/power/monitor/Topic(href, href_list)
	..()
	if( href_list["close"] )
		usr << browse(null, "window=powcomp")
		usr.unset_machine()
		return
	if( href_list["update"] )
		src.updateDialog()
		return


/obj/machinery/networked/power/monitor/power_change()

	if(stat & BROKEN)
		icon_state = "broken"
	else
		if( powered() )
			icon_state = initial(icon_state)
			stat &= ~NOPOWER
		else
			spawn(rand(0, 15))
				src.icon_state = "c_unpowered"
				stat |= NOPOWER
