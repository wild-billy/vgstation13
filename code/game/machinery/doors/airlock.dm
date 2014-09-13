
//**************************************************************
//
// Airlocks
// -----------
// The wire code is in code/datums/wires/airlock.dm
//
//**************************************************************

// Base ////////////////////////////////////////////////////////

/obj/machinery/door/airlock
	name = "airlock"
	icon = 'icons/obj/doors/Doorint.dmi'
	power_channel = ENVIRON
	
	var/powerMain = 1
	var/powerBackup = 1
	var/panelOpen = 0
	var/boltLights = 1
	var/idScan //Unused
	
	var/datum/wires/airlock/wires = null
	var/assemblyType = /obj/structure/door_assembly
	var/obj/item/weapon/circuitboard/airlock/electronics = null
	
	var/icon_state_bolted = "door_locked"
	var/overlay_panel = "panel_open"
	var/overlay_welded = "welded"

/obj/machinery/door/airlock/Destroy()
	if(src.wires)
		src.wires.Destroy()
		src.wires = null
	return ..()

/obj/machinery/door/airlock/proc/deconstruct()
	src.busy = 1
	var/obj/structure/door_assembly/Assembly = new src.assembly_type(src.loc)
	Assembly.anchored = 1
	Assembly.clear = src.clear
	Assembly.state = 1
	Assembly.created_name = name
	Assembly.update_state()
	Assembly.fingerprints += src.fingerprints
	Assembly.fingerprintshidden += src.fingerprintshidden
	var/obj/item/weapon/circuitboard/airlock/Electronics = src.electronics
	if(!Electronics)
		Electronics = new/obj/item/weapon/circuitboard/airlock(loc)
		if(src.req_access && src.req_access.len)
			Electronics.conf_access = src.req_access
		else if(src.req_one_access && src.req_one_access.len)
			Electronics.conf_access = req_one_access
			Electronics.one_access = 1
	Electronics.loc = src.loc
	qdel(src)
	return
	
// Utilities ///////////////////////////////////////////////////

/obj/machinery/door/airlock/isPowered()
	if(!(stat & (NOPOWER|BROKEN)))
		if(src.powerMain || src.powerBackup) . = 1
	return
	
/obj/machinery/door/airlock/update_icon()
	if(src.density && src.bolted && src.boltLights)
		src.icon_state = src.icon_state_bolted
	src.overlays.Cut()
	if(src.panelOpen) src.overlays += src.overlay_panel
	if(src.welded) src.overlays += src.overlay_panel
	return
	
/obj/machinery/door/closeAuto()
	if(src.isPowered()) ..()
	return
	
// Interactions ////////////////////////////////////////////////

/obj/machinery/door/airlock/attackby(obj/item/I,mob/user)
	src.busy ? return : src.busy = 1
	if(I)
		if(istype(I,/obj/item/weapon/screwdriver))
			src.panelOpen = !panelOpen
			src.update_icon()
			user << "<span class='notice'>You open the maintenance panel on [src].</span>
		else if(istype(I,/obj/item/weapon/crowbar) || istype(I,/obj/item/weapon/twohanded/fireaxe))
				if(src.isPowered()) user << "<span class='warning'>The door's motors resist your efforts to force it.</span>"
				else if(src.panelOpen || src.jammed) src.deconstruct()
				else src.tryToggleOpen(user,1)
		else if(istype(I,/obj/item/weapon/weldingtool) && src.density)
			if(WT.remove_fuel(0,user))
				src.welded = !src.welded
				src.update_icon()
			user << "<span class='notice'>You remove the electronics from [src].</span>
		else if((istype(I,/obj/item/device/multitool) || istype(I,obj/item/weapon/wirecutters)) && src.panelOpen)
			if(!src.wires) src.wires = new
			src.wires.Interact(user)
		else if(istype(I,/obj/item/weapon/pai_cable))
			PC:plugin(src,user)
		else if(istype(I,/obj/item/weapon/card/emag) || istype(I,/obj/item/weapon/melee/energy/blade))
			src.tryToggleOpen(user,1)
			src.jammed = 1
		else . = ..()
	else . = ..()
	src.busy = 0
	return

/obj/machinery/door/airlock/proc/aiHack(mob/user)
	user << "Airlock AI control has been blocked."
	user << "Attempting to hack into airlock. This may take some time."
	spawn(600)
		if(src && user)
			user << "<span class='notice'>Transfer complete. Airlock digital control restored.</span>"
			src.aiControl = 1
			src.touchDigital(user)
	return

// HTML ////////////////////////////////////////////////////////

/obj/machinery/door/airlock/touchDigital(mob/user)
	if(!src.wires) src.wires = new
	src.add_hiddenprint(user)
	if(aiControl)
		user.set_machine(src)
		var/t1 = text("<B>Airlock Control</B><br>\n")
		t1 += text("Main power is [src.powerMain ? "on" : "off"]line.<br>\n")
		t1 += text("Backup power is [src.powerBackup ? "on" : "off"]line.<br>\n")
		if(src.isWireCut(AIRLOCK_WIRE_IDSCAN)) t1 += text("IdScan wire is cut.<br>\n")
		if(src.isWireCut(AIRLOCK_WIRE_MAIN_POWER1)) t1 += text("Main Power Input wire is cut.<br>\n")
		if(src.isWireCut(AIRLOCK_WIRE_MAIN_POWER2)) t1 += text("Main Power Output wire is cut.<br>\n")
		if(src.powerMain) t1 += text("<A href='?src=\ref[];aiDisable=2'>Temporarily disrupt main power?</a>.<br>\n", src)
		if(src.powerBackup) t1 += text("<A href='?src=\ref[];aiDisable=3'>Temporarily disrupt backup power?</a>.<br>\n", src)
		if(src.isWireCut(AIRLOCK_WIRE_BACKUP_POWER1)) t1 += text("Backup Power Input wire is cut.<br>\n")
		if(src.isWireCut(AIRLOCK_WIRE_BACKUP_POWER2)) t1 += text("Backup Power Output wire is cut.<br>\n")
		if(src.isWireCut(AIRLOCK_WIRE_DOOR_BOLTS)) t1 += text("Door bolt drop wire is cut.<br>\n")
		else if(src.bolted) 
			t1 += text("Door bolts are down.")
			if(src.isPowered()) t1 += text(" <A href='?src=\ref[];aiEnable=4'>Raise?</a><br>\n", src)
			else t1 += text(" Cannot raise door bolts due to power failure.<br>\n")
		else t1 += text("Door bolts are up. <A href='?src=\ref[];aiDisable=4'>Drop them?</a><br>\n", src)
		if(src.isWireCut(AIRLOCK_WIRE_LIGHT)) t1 += text("Door bolt lights wire is cut.<br>\n")
		else if(!src.lights) t1 += text("Door lights are off. <A href='?src=\ref[];aiEnable=10'>Enable?</a><br>\n", src)
		else t1 += text("Door lights are on. <A href='?src=\ref[];aiDisable=10'>Disable?</a><br>\n", src)
		if(src.isWireCut(AIRLOCK_WIRE_ELECTRIFY)) t1 += text("Electrification wire is cut.<br>\n")
		if(src.shocked) t1 += text("Door is electrified [(src.shocked == -1) ? "indefinitely" : "temporarily"]. <A href='?src=\ref[];aiDisable=5'>Un-electrify it?</a><br>\n", src)
		else t1 += text("Door is not electrified. <A href='?src=\ref[];aiEnable=5'>Electrify it for 30 seconds?</a> Or, <A href='?src=\ref[];aiEnable=6'>Electrify it indefinitely until someone cancels the electrification?</a><br>\n", src, src)
		if(src.isWireCut(AIRLOCK_WIRE_SAFETY)) t1 += text("Door force sensors not responding.</a><br>\n")
		else if(src.closeForce) t1 += text("Danger.  Door safeties disabled.  <A href='?src=\ref[];aiEnable=8'> Restore?</a><br>\n",src)
		else t1 += text("Door safeties operating normally.  <A href='?src=\ref[];aiDisable=8'> Override?</a><br>\n",src)
		if(src.isWireCut(AIRLOCK_WIRE_SPEED)) t1 += text("Door timing circuitry not responding.</a><br>\n")
		else if(src.closeFast) t1 += text("Warning.  Door timing circuitry operating abnormally.  <A href='?src=\ref[];aiEnable=9'> Restore?</a><br>\n",src)
		else t1 += text("Door timing circuitry operating normally.  <A href='?src=\ref[];aiDisable=9'> Override?</a><br>\n",src)
		if(src.welded) t1 += text("Door appears to have been welded shut.<br>\n")
		else if(!src.bolted)
			if(src.density) t1 += text("<A href='?src=\ref[];aiEnable=7'>Open door</a><br>\n", src)
			else t1 += text("<A href='?src=\ref[];aiDisable=7'>Close door</a><br>\n", src)
		t1 += text("<p><a href='?src=\ref[];close=1'>Close</a></p>\n", src)
		user << browse(t1, "window=airlock")
		onclose(user, "airlock")
	else if(alert(user,"Digital interface locked down. Hack in?",,"Yes","No")=="Yes") src.aiHack(user)
	return

/obj/machinery/door/airlock/Topic(href,href_list,var/nowindow=0)
	if(!nowindow) ..()
	if(isAdminGhost(usr) || (istype(usr,/mob/living/silicon) && src.aiControl))
		if(href_list["aiDisable"])
			switch(text2num(href_list["aiDisable"]))
				if(1) src.idScan = 0
				if(2) src.powerMain = 0
				if(3) src.powerBackup = 0
				if(4) src.bolted = 1
				if(5) src.shocked = 0
				if(8) src.closeForce = 1
				if(9) src.closeFast = 1
				if(7) src.tryToggleOpen()
				if(10) src.boltLights = 0
		else if(href_list["aiEnable"])
			switch (text2num(href_list["aiEnable"]))
				if(1) src.idScan = 1
				if(4) src.bolted = 0
				if(5) src.electrify(30,usr)
				if(6) src.electrify(-1,usr)
				if(8) src.closeForce = 0
				if(9) src.closeFast = 0
				if(7) src.tryToggleOpen()
				if(10) src.boltLights = 1
		else if(href_list["close"])
			usr << browse(null,"window=airlock")
			if(usr.machine == src) usr.unset_machine()
	src.update_icon()
	src.updateDialog()
	if(!nowindow) src.updateUsrDialog()
	return
	
// Miscellaneous ///////////////////////////////////////////////

/obj/machinery/door/emp_act(severity)
	if(prob(50)) src.tryToggleOpen()
	else src.electrify(300)
	if(prob(5)) src.jammed = 1
	return

//**************************************************************
// Subtypes ////////////////////////////////////////////////////
//**************************************************************

/obj/machinery/door/airlock/command
	name = "Airlock"
	icon = 'icons/obj/doors/Doorcom.dmi'
	assembly_type = /obj/structure/door_assembly/door_assembly_com

/obj/machinery/door/airlock/security
	name = "Airlock"
	icon = 'icons/obj/doors/Doorsec.dmi'
	assembly_type = /obj/structure/door_assembly/door_assembly_sec

/obj/machinery/door/airlock/engineering
	name = "Airlock"
	icon = 'icons/obj/doors/Dooreng.dmi'
	assembly_type = /obj/structure/door_assembly/door_assembly_eng

/obj/machinery/door/airlock/medical
	name = "Airlock"
	icon = 'icons/obj/doors/doormed.dmi'
	assembly_type = /obj/structure/door_assembly/door_assembly_med

/obj/machinery/door/airlock/maintenance
	name = "Maintenance Access"
	icon = 'icons/obj/doors/Doormaint.dmi'
	assembly_type = /obj/structure/door_assembly/door_assembly_mai

/obj/machinery/door/airlock/external
	name = "External Airlock"
	icon = 'icons/obj/doors/Doorext.dmi'
	assembly_type = /obj/structure/door_assembly/door_assembly_ext
	
/obj/machinery/door/airlock/centcom
	name = "Airlock"
	icon = 'icons/obj/doors/Doorele.dmi'

/obj/machinery/door/airlock/vault
	name = "Vault"
	icon = 'icons/obj/doors/vault.dmi'
	assembly_type = /obj/structure/door_assembly/door_assembly_highsecurity

/obj/machinery/door/airlock/freezer
	name = "Freezer Airlock"
	icon = 'icons/obj/doors/Doorfreezer.dmi'
	assembly_type = /obj/structure/door_assembly/door_assembly_fre

/obj/machinery/door/airlock/hatch
	name = "Airtight Hatch"
	icon = 'icons/obj/doors/Doorhatchele.dmi'
	assembly_type = /obj/structure/door_assembly/door_assembly_hatch

/obj/machinery/door/airlock/maintenance_hatch
	name = "Maintenance Hatch"
	icon = 'icons/obj/doors/Doorhatchmaint2.dmi'
	assembly_type = /obj/structure/door_assembly/door_assembly_mhatch

/obj/machinery/door/airlock/mining
	name = "Mining Airlock"
	icon = 'icons/obj/doors/Doormining.dmi'
	assembly_type = /obj/structure/door_assembly/door_assembly_min

/obj/machinery/door/airlock/atmos
	name = "Atmospherics Airlock"
	icon = 'icons/obj/doors/Dooratmo.dmi'
	assembly_type = /obj/structure/door_assembly/door_assembly_atmo

/obj/machinery/door/airlock/research
	name = "Airlock"
	icon = 'icons/obj/doors/doorresearch.dmi'
	assembly_type = /obj/structure/door_assembly/door_assembly_research

/obj/machinery/door/airlock/gold
	name = "Gold Airlock"
	icon = 'icons/obj/doors/Doorgold.dmi'
	mineral = "gold"

/obj/machinery/door/airlock/silver
	name = "Silver Airlock"
	icon = 'icons/obj/doors/Doorsilver.dmi'
	mineral = "silver"

/obj/machinery/door/airlock/diamond
	name = "Diamond Airlock"
	icon = 'icons/obj/doors/Doordiamond.dmi'
	mineral = "diamond"

/obj/machinery/door/airlock/uranium
	name = "Uranium Airlock"
	desc = "And they said I was crazy."
	icon = 'icons/obj/doors/Dooruranium.dmi'
	mineral = "uranium"

/obj/machinery/door/airlock/plasma
	name = "Plasma Airlock"
	desc = "No way this can end badly."
	icon = 'icons/obj/doors/Doorplasma.dmi'
	mineral = "plasma"

/obj/machinery/door/airlock/clown
	name = "Bananium Airlock"
	icon = 'icons/obj/doors/Doorbananium.dmi'
	sfx = 'sound/items/bikehorn.ogg'
	mineral = "clown"

/obj/machinery/door/airlock/sandstone
	name = "Sandstone Airlock"
	icon = 'icons/obj/doors/Doorsand.dmi'
	mineral = "sandstone"

/obj/machinery/door/airlock/science
	name = "Airlock"
	icon = 'icons/obj/doors/Doorsci.dmi'
	assembly_type = /obj/structure/door_assembly/door_assembly_science

/obj/machinery/door/airlock/highsecurity
	name = "High Tech Security Airlock"
	icon = 'icons/obj/doors/hightechsecurity.dmi'
	assembly_type = /obj/structure/door_assembly/door_assembly_highsecurity

// Glass ///////////////////////////////////////////////////////	

/obj/machinery/door/airlock/glass
	name = "Glass Airlock"
	icon = 'icons/obj/doors/Doorglass.dmi'
	sfx = 'sound/machines/windowdoor.ogg'
	clear = 1

/obj/machinery/door/airlock/glass/command
	icon = 'icons/obj/doors/Doorcomglass.dmi'
	assembly_type = /obj/structure/door_assembly/door_assembly_com

/obj/machinery/door/airlock/glass/engineering
	icon = 'icons/obj/doors/Doorengglass.dmi'
	assembly_type = /obj/structure/door_assembly/door_assembly_eng

/obj/machinery/door/airlock/glass/security
	icon = 'icons/obj/doors/Doorsecglass.dmi'
	assembly_type = /obj/structure/door_assembly/door_assembly_sec

/obj/machinery/door/airlock/glass/medical
	icon = 'icons/obj/doors/doormedglass.dmi'
	assembly_type = /obj/structure/door_assembly/door_assembly_med
	
/obj/machinery/door/airlock/glass/science
	icon = 'icons/obj/doors/Doorsciglass.dmi'
	assembly_type = /obj/structure/door_assembly/door_assembly_science

/obj/machinery/door/airlock/glass/research
	icon = 'icons/obj/doors/doorresearchglass.dmi'
	assembly_type = /obj/structure/door_assembly/door_assembly_research

/obj/machinery/door/airlock/glass/mining
	icon = 'icons/obj/doors/Doorminingglass.dmi'
	assembly_type = /obj/structure/door_assembly/door_assembly_min

/obj/machinery/door/airlock/glass/atmos
	icon = 'icons/obj/doors/Dooratmoglass.dmi'
	assembly_type = /obj/structure/door_assembly/door_assembly_atmo
	
// Alarmlock ///////////////////////////////////////////////////
	
/obj/machinery/door/airlock/glass/alarmlock
	closeAuto = 0
	var/datum/radio_frequency/airConnection
	var/airFrequency = 1437
	
/obj/machinery/door/airlock/glass/alarmlock/New()
	src.airConnection = new
	radio_controller.remove_object(src,airFrequency)
	src.airConnection = radio_controller.add_object(src,airFrequency,RADIO_TO_AIRALARM)
	src.open()
	return ..()

/obj/machinery/door/airlock/glass/alarmlock/receive_signal(datum/signal/signal)
	. = ..()
	if(src.isPowered())
		var/area/Area = get_area(src)
		if(Area.master) Area = Area.master
		if(signal.data["zone"] == Area.name)
			switch(signal.data["alert"])
				if("severe")
					src.closeAuto = 1
					src.tryToggleOpen(closeOnly=1)
				if("minor","clear")
					src.closeAuto = 0
					src.tryToggleOpen(openOnly=1)
	return
