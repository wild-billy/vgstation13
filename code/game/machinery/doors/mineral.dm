
//**************************************************************
//
// Mineral Doors
// --------------------
// Now with inheritance!
//
//**************************************************************

/obj/machinery/door/mineral
	var/mineralName = "metal"
	var/mineralPath = /obj/item/stack/sheet/metal
	var/mineralAmount = 7
	
/obj/machinery/door/mineral/New()
	src.name = "[src.mineralName] door"
	src.icon_state = src.mineralName
	src.icon_state_open = "[src.mineralName]open"
	src.icon_state_opening = "[src.mineralName]opening"
	src.icon_state_closed = src.mineralName
	src.icon_state_closing = "[src.mineralName]closing"
	src.icon_state_deny = src.mineralName
	return ..()

/obj/machinery/door/mineral/Destroy()
	if(src.mineralPath)
		for(var/i=1,i<=src.mineralAmount,i++)
			new src.mineralPath(src.loc)
	return ..()
	
/obj/machinery/door/mineral/attackby(obj/item/weapon/W,mob/user)
	if(istype(W,/obj/item/weapon/pickaxe))
		user << "You start demolishing the [src.name]."
		if(do_after(user,digTool:digspeed*hardness) && src) qdel(src)
	else . = ..()
	return

//**************************************************************
// Subtypes ////////////////////////////////////////////////////
//**************************************************************

/obj/machinery/door/mineral/iron
	mineralName = "metal"
	mineralPath = /obj/item/stack/sheet/mineral/iron

/obj/machinery/door/mineral/silver
	mineralName = "silver"
	mineralPath = /obj/item/stack/sheet/mineral/silver

/obj/machinery/door/mineral/gold
	mineralName = "gold"
	mineralPath = /obj/item/stack/sheet/mineral/gold

/obj/machinery/door/mineral/uranium
	mineralName = "uranium"
	mineralPath = /obj/item/stack/sheet/mineral/uranium

/obj/machinery/door/mineral/sandstone
	mineralName = "sandstone"
	mineralPath = /obj/item/stack/sheet/mineral/sandstone

/obj/machinery/door/mineral/plasma
	mineralName = "plasma"
	mineralPath = /obj/item/stack/sheet/mineral/plasma
	clear = 1
	
/obj/machinery/door/mineral/transparent/diamond
	mineralName = "diamond"
	mineralPath = /obj/item/stack/sheet/mineral/iron
	clear = 1

/obj/machinery/door/mineral/wood
	mineralName = "wood"
	mineralPath = /obj/item/stack/sheet/wood
	sfx = 'sound/effects/doorcreaky.ogg'
	
/obj/machinery/door/mineral/resin
	mineralName = "resin"
	mineralPath = null
	sfx = 'sound/effects/attackblob.ogg'
