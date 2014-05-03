// the cable coil object, used for laying cable

#define MAXCOIL 30
/obj/item/weapon/cable_coil
	name = "cable coil"
	icon = 'icons/obj/power.dmi'
	icon_state = "coil_red"
	var/amount = MAXCOIL
	var/max_amount = MAXCOIL
	var/cable_type = /obj/structure/cable
	_color = "red"
	desc = "A coil of power cable."
	throwforce = 10
	w_class = 2.0
	throw_speed = 2
	throw_range = 5
	m_amt = CC_PER_SHEET_METAL
	w_type = RECYK_METAL
	flags = TABLEPASS | USEDELAY | FPRINT | CONDUCT
	slot_flags = SLOT_BELT
	item_state = "coil_red"
	attack_verb = list("whipped", "lashed", "disciplined", "flogged")

/obj/item/weapon/cable_coil/suicide_act(var/mob/user)
	viewers(user) << "\red <b>[user] is strangling \himself with the [src.name]! It looks like \he's trying to commit suicide.</b>"
	return(OXYLOSS)

/obj/item/weapon/cable_coil/New(loc, length = MAXCOIL, var/param_color = null)
	..()
	src.amount = length
	if (param_color)
		_color = param_color
	pixel_x = rand(-2,2)
	pixel_y = rand(-2,2)
	updateicon()

/obj/item/weapon/cable_coil/proc/updateicon()
	if (!_color)
		_color = pick("red", "yellow", "blue", "green")
	if(amount == 1)
		icon_state = "coil_[_color]1"
		name = "cable piece"
	else if(amount == 2)
		icon_state = "coil_[_color]2"
		name = "cable piece"
	else
		icon_state = "coil_[_color]"
		name = "cable coil"

/obj/item/weapon/cable_coil/examine()
	set src in view(1)

	if(amount == 1)
		usr << "A short piece of power cable."
	else if(amount == 2)
		usr << "A piece of power cable."
	else
		usr << "A coil of power cable. There are [amount] lengths of cable in the coil."

/obj/item/weapon/cable_coil/verb/make_restraint()
	set name = "Make Cable Restraints"
	set category = "Object"
	var/mob/M = usr

	if(ishuman(M) && !M.restrained() && !M.stat && !M.paralysis && ! M.stunned)
		if(!istype(usr.loc,/turf)) return
		if(src.amount <= 14)
			usr << "\red You need at least 15 lengths to make restraints!"
			return
		var/obj/item/weapon/handcuffs/cable/B = new /obj/item/weapon/handcuffs/cable(usr.loc)
		B.icon_state = "cuff_[_color]"
		usr << "\blue You wind some cable together to make some restraints."
		src.use(15)
	else
		usr << "\blue You cannot do that."
	..()

/obj/item/weapon/cable_coil/attackby(obj/item/weapon/W, mob/user)
	..()
	if( istype(W, /obj/item/weapon/wirecutters) && src.amount > 1)
		src.amount--
		new/obj/item/weapon/cable_coil(user.loc, 1,_color)
		user << "You cut a piece off the cable coil."
		src.updateicon()
		return

	else if( istype(W, /obj/item/weapon/cable_coil) )
		var/obj/item/weapon/cable_coil/C = W
		if(C.amount == max_amount)
			user << "The coil is too long, you cannot add any more cable to it."
			return

		if( (C.amount + src.amount <= max_amount) )
			C.amount += src.amount
			user << "You join the cable coils together."
			C.updateicon()
			del(src)
			return

		else
			user << "You transfer [max_amount - C.amount] length\s of cable from one coil to the other."
			src.amount -= (max_amount-C.amount)
			src.updateicon()
			C.amount = max_amount
			C.updateicon()
			return

/obj/item/weapon/cable_coil/proc/use(var/used)
	if(src.amount < used)
		return 0
	else if (src.amount == used)
		del(src)
	else
		amount -= used
		updateicon()
		return 1

// called when cable_coil is clicked on a turf/simulated/floor

/obj/item/weapon/cable_coil/proc/turf_place(turf/simulated/floor/F, mob/user)

	if(!isturf(user.loc))
		return

	if(get_dist(F,user) > 1)
		user << "You can't lay cable at a place that far away."
		return

	if(F.intact)		// if floor is intact, complain
		user << "You can't lay cable there unless the floor tiles are removed."
		return

	else
		var/dirn

		if(user.loc == F)
			dirn = user.dir			// if laying on the tile we're on, lay in the direction we're facing
		else
			dirn = get_dir(F, user)

		for(var/obj/structure/cable/LC in F)
			// If we carry data and the existing cable carries power, skip over it.
			if((LC.d1 == dirn && LC.d2 == 0 ) || ( LC.d2 == dirn && LC.d1 == 0))
				user << "There's already a cable at that position."
				return

		var/obj/structure/cable/C = new cable_type(F)

		C.d1 = 0
		C.d2 = dirn
		C.add_fingerprint(user)
		C.initialize()


		use(1)
		if (C.cable.shock(user, 50))
			if (prob(50)) //fail
				new C.coil_type(C.loc, 1)
				del(C)

// called when cable_coil is click on an installed obj/cable
/obj/item/weapon/cable_coil/proc/cable_join(var/obj/structure/cable/C, mob/user)

	var/turf/U = user.loc
	if(!isturf(U))
		return

	var/turf/T = C.loc

	if(!isturf(T) || T.intact)		// sanity checks, also stop use interacting with T-scanner revealed cable
		return

	if(get_dist(C, user) > 1)		// make sure it's close enough
		user << "You can't lay cable at a place that far away."
		return

	if(U == T)		// do nothing if we clicked a cable we're standing on
		return		// may change later if can think of something logical to do

	var/dirn = get_dir(C, user)

	if(C.d1 == dirn || C.d2 == dirn)		// one end of the clicked cable is pointing towards us
		if(U.intact)						// can't place a cable if the floor is complete
			user << "You can't lay cable there unless the floor tiles are removed."
			return
		else
			// cable is pointing at us, we're standing on an open tile
			// so create a stub pointing at the clicked cable on our tile

			var/fdirn = turn(dirn, 180)		// the opposite direction

			for(var/obj/structure/cable/LC in U)		// check to make sure there's not a cable there already
				if(LC.d1 == fdirn || LC.d2 == fdirn)
					user << "There's already a cable at that position."
					return

			var/obj/structure/cable/NC = new cable_type(U)
			NC.d1 = 0
			NC.d2 = fdirn
			NC.add_fingerprint()
			NC.initialize()
			use(1)
			if (NC.cable.shock(user, 50))
				if (prob(50)) //fail
					new src.type(NC.loc, 1)
					del(NC)

			return
	else if(C.d1 == 0)		// exisiting cable doesn't point at our position, so see if it's a stub
							// if so, make it a full cable pointing from it's old direction to our dirn
		var/nd1 = C.d2	// these will be the new directions
		var/nd2 = dirn


		if(nd1 > nd2)		// swap directions to match icons/states
			nd1 = dirn
			nd2 = C.d2


		for(var/obj/structure/cable/LC in T)		// check to make sure there's no matching cable
			if(LC == C)			// skip the cable we're interacting with
				continue
			if((LC.d1 == nd1 && LC.d2 == nd2) || (LC.d1 == nd2 && LC.d2 == nd1) )	// make sure no cable matches either direction
				user << "There's already a cable at that position."
				return

		C.d1 = nd1
		C.d2 = nd2

		C.add_fingerprint()
		C.cable.rmLink(C,autoclean=0)
		C.initialize()

		use(1)
		if (C.cable.shock(user, 50))
			if (prob(50)) //fail
				new src.type(C.loc, 2)
				del(C)

		return
/obj/item/weapon/cable_coil/attack(mob/M as mob, mob/user as mob)
	if(hasorgans(M))
		var/datum/organ/external/S = M:get_organ(user.zone_sel.selecting)
		if(!(S.status & ORGAN_ROBOT) || user.a_intent != "help")
			return ..()
		if(S.burn_dam > 0 && use(1))
			S.heal_damage(0,15,0,1)
			if(user != M)
				user.visible_message("\red \The [user] repairs some burn damage on their [S.display_name] with \the [src]",\
				"\red You repair some burn damage on your [S.display_name]",\
				"You hear wires being cut.")
			else
				user.visible_message("\red \The [user] repairs some burn damage on their [S.display_name] with \the [src]",\
				"\red You repair some burn damage on your [S.display_name]",\
				"You hear wires being cut.")
		else
			user << "Nothing to fix!"
	else
		return ..()

/obj/item/weapon/cable_coil/cut
	item_state = "coil_red2"

/obj/item/weapon/cable_coil/cut/New(loc)
	..()
	src.amount = rand(1,2)
	pixel_x = rand(-2,2)
	pixel_y = rand(-2,2)
	updateicon()

/obj/item/weapon/cable_coil/yellow
	_color = "yellow"
	icon_state = "coil_yellow"

/obj/item/weapon/cable_coil/blue
	_color = "blue"
	icon_state = "coil_blue"

/obj/item/weapon/cable_coil/green
	_color = "green"
	icon_state = "coil_green"

/obj/item/weapon/cable_coil/pink
	_color = "pink"
	icon_state = "coil_pink"

/obj/item/weapon/cable_coil/orange
	_color = "orange"
	icon_state = "coil_orange"

/obj/item/weapon/cable_coil/cyan
	_color = "cyan"
	icon_state = "coil_cyan"

/obj/item/weapon/cable_coil/white
	_color = "white"
	icon_state = "coil_white"

/obj/item/weapon/cable_coil/random/New()
	_color = pick("red","yellow","green","blue","pink")
	icon_state = "coil_[_color]"
	..()
