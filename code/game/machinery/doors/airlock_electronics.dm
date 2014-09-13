
//**************************************************************
// Airlock Electronics Board
//**************************************************************

/obj/item/weapon/circuitboard/airlock
	name = "airlock electronics"
	icon = 'icons/obj/doors/door_assembly.dmi'
	icon_state = "door_electronics"
	w_class = 2.0 //It should be tiny! -Agouri
	m_amt = 50
	g_amt = 50
	w_type = RECYK_ELECTRONIC
	req_access = list(access_engine)

	var/locked = 1
	var/oneAccess = 0
	var/lastUser
	var/list/confAccess

//To allow robutts to build airlocks
/obj/item/weapon/circuitboard/airlock/attack_robot(mob/user)
	if(isMoMMI(user)) . = ..()
	else src.attack_self(user)
	return 1
	
/obj/item/weapon/circuitboard/airlock/attack_self(mob/user)
	if(istype(user,/mob/dead) && !isAdminGhost(user))
		user << "<span class='danger'>Nope.</span>"
	else src.interact(user)
	return

// HTML ////////////////////////////////////////////////////////

/obj/item/weapon/circuitboard/airlock/proc/interact(mob/user)
	var/t1 = text("<B>Access control</B><br>\n")
	if(src.lastUser) t1 += "Last Operator: [src.lastUser]<br>"
	src.lastUser = user.name
	if(src.locked)
		if(isrobot(user)) t1 += "<a href='?src=\ref[src];login=1'>Log In</a><hr>"
		else t1 += "<a href='?src=\ref[src];login=1'>Swipe ID</a><hr>"
	else
		t1 += "<a href='?src=\ref[src];logout=1'>Block</a><hr>"
		t1 += "Access requirement is set to "
		t1 += src.oneAccess ? "<a style='color: green' href='?src=\ref[src];oneAccess=1'>ONE</a><hr>" : "<a style='color: red' href='?src=\ref[src];oneAccess=1'>ALL</a><hr>"
		t1 += src.confAccess ? "<a href='?src=\ref[src];access=all'>All</a><br>": "<font color=red>All</font><br>" 
		t1 += "<br>"
		var/AccessName
		for(var/Access in get_all_accesses()) AccessName = get_access_desc(Access)
			if(!src.confAccess || !src.confAccess.len || !(Access in src.confAccess)) t1 += "<a href='?src=\ref[src];access=[Access]'>[AccessName]</a><br>"
			else if(src.oneAccess) t1 += "<a style='color: green' href='?src=\ref[src];access=[Access]'>[AccessName]</a><br>"
			else t1 += "<a style='color: red' href='?src=\ref[src];access=[Access]'>[AccessName]</a><br>"
	t1 += text("<p><a href='?src=\ref[];close=1'>Close</a></p>\n",src)
	user << browse(t1,"window=airlock_electronics")
	onclose(user,"airlock")
	return

/obj/item/weapon/circuitboard/airlock/Topic(href,href_list)
	. = ..()
	if(href_list["close"]) usr << browse(null,"window=airlock")
	else if(href_list["login"])
		if(ishuman(usr))
			var/mob/living/carbon/human/Human = usr
			var/obj/item/Item = Human.get_active_hand()
			var/obj/item/ID
			if(Item && (istype(Item,/obj/item/weapon/card) || istype(Item,/obj/item/device/pda))) ID = Item
			else if(Human.wear_id)
				Item = Human.wear_id
				if(istype(Item,/obj/item/weapon/card)) ID = Item
				else if(istype(Item,/obj/item/device/pda) && Item:id) ID = Item:id
			if(ID && src.check_access(ID))
				src.locked = 0
				src.lastUser = ID:registered_name
		else if(isrobot(usr))
			src.locked = 0
			src.lastUser = usr.name
	else if(!src.locked)
		if(href_list["logout"]) src.locked = 1
		else if(href_list["oneAccess"]) src.oneAccess = !src.oneAccess
		else if(href_list["access"]) src.toggleAccess(href_list["access"])
	return src.attack_self(usr) //TODO: This is not the right way to update a dialog.

/obj/item/weapon/circuitboard/airlock/proc/toggleAccess(var/Access)
	if(Access == "all") src.confAccess = null
	else
		var/Required = text2num(Access)
		if(!src.confAccess) confAccess = list()
		src.confAccess ^= Required
		if(!src.confAccess.len) src.confAccess = null
	return
