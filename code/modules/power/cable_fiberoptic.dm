/obj/item/weapon/cable_coil/fiberoptic
	name = "fiber-optic coil"
	icon = 'icons/obj/power.dmi'
	icon_state = "coil_fiber"
	cable_type = /obj/structure/cable/fiberoptic
	carries = CARRIES_DATA

/obj/structure/cable/fiberoptic
	icon = 'icons/obj/power_cond_fiber.dmi'
	name = "fiber-optic cable"
	desc = "A cable for carrying data."
	layer = 2.39 //Just below pipes, which are at 2.4
	carries = CARRIES_DATA
	coil_type = /obj/item/weapon/cable_coil/fiberoptic
	_color = "fiber"