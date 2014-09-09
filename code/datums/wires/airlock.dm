
//**************************************************************
//
// Airlock Wires
// ------------------
// Having this here bothers me, it should be in airlock.dm
//
//**************************************************************

var/const/AIRLOCK_WIRE_IDSCAN			= 1
var/const/AIRLOCK_WIRE_MAIN_POWER1		= 2
var/const/AIRLOCK_WIRE_MAIN_POWER2		= 4
var/const/AIRLOCK_WIRE_DOOR_BOLTS		= 8
var/const/AIRLOCK_WIRE_BACKUP_POWER1	= 16
var/const/AIRLOCK_WIRE_BACKUP_POWER2	= 32
var/const/AIRLOCK_WIRE_OPEN_DOOR		= 64
var/const/AIRLOCK_WIRE_AI_CONTROL		= 128
var/const/AIRLOCK_WIRE_ELECTRIFY		= 256
var/const/AIRLOCK_WIRE_SAFETY			= 512
var/const/AIRLOCK_WIRE_SPEED			= 1024
var/const/AIRLOCK_WIRE_LIGHT			= 2048

/datum/wires/airlock
	holder_type = /obj/machinery/door/airlock
	wire_count = 12
	window_y = 570

/datum/wires/airlock/New()
	src.wire_names=list(
		"[AIRLOCK_WIRE_IDSCAN]"        = "ID Scan",
		"[AIRLOCK_WIRE_MAIN_POWER1]"   = "Main Power 1",
		"[AIRLOCK_WIRE_MAIN_POWER2]"   = "Main Power 2",
		"[AIRLOCK_WIRE_DOOR_BOLTS]"    = "Bolts",
		"[AIRLOCK_WIRE_BACKUP_POWER1]" = "Backup Power 1",
		"[AIRLOCK_WIRE_BACKUP_POWER2]" = "Backup Power 2",
		"[AIRLOCK_WIRE_OPEN_DOOR]"     = "Open",
		"[AIRLOCK_WIRE_AI_CONTROL]"    = "AI Control",
		"[AIRLOCK_WIRE_ELECTRIFY]"     = "Electrify",
		"[AIRLOCK_WIRE_SAFETY]"        = "Safety",
		"[AIRLOCK_WIRE_SPEED]"         = "Speed",
		"[AIRLOCK_WIRE_LIGHT]"         = "Lights",
		)
	return ..()

/datum/wires/airlock/CanUse(var/mob/living/L)
	return 1

/datum/wires/airlock/GetInteractWindow()
	var/obj/machinery/door/airlock/A = src.holder
	. += ..()
	. += text("<br>\n[]<br>\n[]<br>\n[]<br>\n[]<br>\n[]<br>\n[]", 
	"The door bolts are [A.bolted ? "down!" : "up."]",
	"The door bolt lights are [A.boltLights ? "on." : "off!"]",
	"The test light is [A.isPowered() ? "on." : "off!"]",
	"The AI control light is [A.aiControl ? "on." : "off!"]",
	"The check wiring light is [A.closeForce ? "on!" : "off."]",
	"The check timing light is [A.closeFast ? "on!" : "off."]")
	return

/datum/wires/airlock/UpdateCut(var/index,var/mended)
	var/obj/machinery/door/airlock/A = holder
	switch(index)
		if(AIRLOCK_WIRE_MAIN_POWER1,AIRLOCK_WIRE_MAIN_POWER2)
			if(!mended) A.powerMain = 0
			else if((!IsIndexCut(AIRLOCK_WIRE_MAIN_POWER1)) && (!IsIndexCut(AIRLOCK_WIRE_MAIN_POWER2))) A.powerMain = 1()
			A.shock(usr)
		if(AIRLOCK_WIRE_BACKUP_POWER1, AIRLOCK_WIRE_BACKUP_POWER2)
			if(!mended) A.powerBackup = 0
			else if((!IsIndexCut(AIRLOCK_WIRE_BACKUP_POWER1)) && (!IsIndexCut(AIRLOCK_WIRE_BACKUP_POWER2))) A.powerBackup = 1()
			A.shock(usr)
		if(AIRLOCK_WIRE_DOOR_BOLTS)
			if(!mended) A.bolted = 1
			A.update_icon()
		if(AIRLOCK_WIRE_AI_CONTROL)
			A.aiControl = mended
		if(AIRLOCK_WIRE_ELECTRIFY)
			if(!mended) A.electrify(-1,usr)
			else A.electrified = 0
		if(AIRLOCK_WIRE_SAFETY)
			A.closeForce = !mended
		if(AIRLOCK_WIRE_SPEED)
			A.closeFast = !mended
		if(AIRLOCK_WIRE_LIGHT)
			A.boltLights = mended
			A.update_icon()
	A.updateDialog()
	return

/datum/wires/airlock/UpdatePulsed(var/index)
	var/obj/machinery/door/airlock/A = holder
	switch(index)
		if(AIRLOCK_WIRE_MAIN_POWER1 || AIRLOCK_WIRE_MAIN_POWER2)
			A.powerMain = 0
			spawn(50) A.powerMain = 1
		if(AIRLOCK_WIRE_DOOR_BOLTS)
			A.bolted = !A.bolted
			usr << "You hear a click from the bottom of the door."
			A.update_icon()
		if(AIRLOCK_WIRE_BACKUP_POWER1 || AIRLOCK_WIRE_BACKUP_POWER2)
			A.powerBackup = 0
			spawn(50) A.powerBackup = 1
		if(AIRLOCK_WIRE_AI_CONTROL)
			var/oldControl = A.aiControl
			A.aiControl = !A.aiControl
			spawn(50) A.aiControl = oldControl
		if(AIRLOCK_WIRE_ELECTRIFY)
			A.electrify(50,usr)
		if(AIRLOCK_WIRE_OPEN_DOOR)
			if(A.check_access()) A.tryToggleOpen()
		if(AIRLOCK_WIRE_SAFETY)
			A.closeForce = !A.closeForce
		if(AIRLOCK_WIRE_SPEED)
			A.normalspeed = !A.normalspeed
		if(AIRLOCK_WIRE_LIGHT)
			A.boltLights = !A.boltLights
			A.update_icon()
	A.updateDialog()
	return
