/*
	Modified DynamicAreaLighting for TGstation - Coded by Carnwennan

	This is TG's 'new' lighting system. It's basically a heavily modified combination of Forum_Account's and
	ShadowDarke's respective lighting libraries. Credits, where due, to them.

	Like sd_DAL (what we used to use), it changes the shading overlays of areas by splitting each type of area into sub-areas
	by using the var/tag variable and moving turfs into the contents list of the correct sub-area.

	Unlike sd_DAL however it uses a queueing system. Everytime we  call a change to opacity or luminosity
	(through SetOpacity() or SetLuminosity()) we are  simply updating variables and scheduling certain lights/turfs for an
	update. Actual updates are handled periodically by the lighting_controller. This carries additional overheads, however it
	means that each thing is changed only once per lighting_controller.processing_interval ticks. Allowing for greater control
	over how much priority we'd like lighting updates to have. It also makes it possible for us to simply delay updates by
	setting lighting_controller.processing = 0 at say, the start of a large explosion, waiting for it to finish, and then
	turning it back on with lighting_controller.processing = 1.

	Unlike our old system there is a hardcoded maximum luminosity. This is to discourage coders using large luminosity values
	for dynamic lighting, as the cost of lighting grows rapidly at large luminosity levels (especially when changing opacity
	at runtime)

	Also, in order for the queueing system to work, each light remembers the effect it casts on each turf. This is going to
	have larger memory requirements than our previous system but hopefully it's worth the hassle for the greater control we
	gain. Besides, there are far far worse uses of needless lists in the game, it'd be worth pruning some of them to offset
	costs.

	Known Issues/TODO:
		admin-spawned turfs will have broken lumcounts. Not willing to fix it at this moment
		mob luminosity will be lower than expected when one of multiple light sources is dropped after exceeding the maximum luminosity
		Shuttles still do not have support for dynamic lighting (I hope to fix this at some point)
		No directional lighting support. Fairly easy to add this and the code is ready.
*/

// Resolution.  Higher values = shittier light.  Lower values = more memory usage.
#define LUMC_Q_RES 32
// Quantizing lumchannel resolution so we don't get shitloads of areas.
#define LUMC_Q(x) Clamp(round(x*LUMC_Q_RES)/LUMC_Q_RES,0,1)
#define LUMINOSITY_PER_LUMA 12 // Distance light is cast when on max luma.

#define MAX_LUMA_MOB  0.7	    // Counterpart to below.

#define MAX_LUMINOSITY 12	    //Hard maximum luminosity to prevet lag which could be caused by coders making mini-suns
#define MAX_LUMINOSITY_MOB 7	//Mobs get their own max because 60-odd human suns running around would be pretty silly
#define LIGHTING_LAYER 10			//Drawing layer for lighting overlays
#define LIGHTING_ICON 'icons/effects/ss13_dark_alpha7.dmi'	//Icon used for lighting shading effects

/***********
COLORED LIGHTING

Light comes in three types:  Red, green, blue.

Therefore, instead of applying just one color
(white), we apply THREE lumcounts.
************/
                    //    R , G , B
#define LIGHT_WHITE list(1.0,1.0,1.0) // white light, aka normal
#define LIGHT_GREEN list(0.0,1.0,0.0) // lime green light

#define LUMA_DEFAULT 0.25 // Default luma level. Dark and moody.

/datum/light_source
	var/atom/owner
	var/changed = 1
	var/mobile = 1
	var/list/effect = list()

	var/__x = 0		//x coordinate at last update
	var/__y = 0		//y coordinate at last update

	var/list/light_color = LIGHT_WHITE
	var/luma = 1.0

	New(atom/A)
		if(!istype(A))
			CRASH("The first argument to the light object's constructor must be the atom that is the light source. Expected atom, received '[A]' instead.")

		..()
		owner = A
		light_color = owner.lighting_color
		if(istype(owner, /atom/movable))	mobile = 1		//apparantly this is faster than type-checking
		else								mobile = 0		//Perhaps removing support for luminous turfs would be a good idea.

		__x = owner.x
		__y = owner.y

		// the lighting object maintains a list of all light sources
		lighting_controller.lights += src


	//Check a light to see if its effect needs reprocessing. If it does, remove any old effect and create a new one
	proc/check()
		if(!owner)
			remove_effect()
			return 1	//causes it to be removed from our list of lights. The garbage collector will then destroy it.

		if(mobile)
			// check to see if we've moved since last update
			if(owner.x != __x || owner.y != __y)
				__x = owner.x
				__y = owner.y
				changed = 1

		if(changed)
			changed = 0
			remove_effect()
			return add_effect()
		return 0


	proc/remove_effect()
		// before we apply the effect we remove the light's current effect.
		if(effect.len)
			for(var/turf in effect)	// negate the effect of this light source
				var/turf/T = turf
				T.update_lighting(-effect[T][4],effect[T])
			effect.Cut()					// clear the effect list

	proc/add_effect()
		// only do this if the light is turned on and is on the map
		if(owner.loc && owner.luminosity > 0)
			effect = new_effect()						// identify the effects of this light source
			for(var/turf in effect)
				var/turf/T = turf
				T.update_lumcount(effect[T][4],effect[T])			// apply the effect
			return 0
		else
			owner.light = null
			return 1	//cause the light to be removed from the lights list and garbage collected once it's no
						//longer referenced by the queue

	proc/new_effect()
		. = list()
		for(var/turf/T in view(owner.luminosity, owner))
//			var/area/A = T.loc
//			if(!A) continue
			var/delta_y = lum(T)
			var/list/delta_c = list(
				band_lum(T,1),
				band_lum(T,2),
				band_lum(T,3)
			)
			if(delta_y > 0)
				.[T] = delta_c + list(delta_y)

		return .


	proc/band_lum(var/turf/A,var/cband)
		var/val = owner.lighting_color[cband] - max(abs(A.x-__x),abs(A.y-__y))
		if(val < 0)
			world << "[src] had a band #[cband] luminosity lower than 0: [val]"
		return val
//		var/dist = cheap_hypotenuse(A.x,A.y,__x,__y) //fetches the pythagorean distance between A and the light
//		if(owner.luminosity < dist)	//if the turf is outside the radius the light doesn't illuminate it
//			return 0
//		return round(owner.luminosity - (dist/2),0.1)

	proc/lum(turf/A)
		var/val = owner.lighting_luma - max(abs(A.x-__x),abs(A.y-__y))
		if(val < 0 || val > 1)
			world << "[src] had a lighting_luma of [val]"
		return val

/atom
	var/datum/light_source/light
	// Lighting color. (R,G,B), [0-1] each channel
	var/list/lighting_color   = LIGHT_WHITE

	// Lighting brightness.  0-1.
	var/lighting_luma    = 1.0

//Turfs with opacity when they are constructed will trigger nearby lights to update
//Turfs atoms with luminosity when they are constructed will create a light_source automatically
//TODO: lag reduction
/turf/New()
	..()
	if(opacity)
		UpdateAffectingLights()
	if(luminosity)
		world.log << "[type] has luminosity at New()"
		if(light)	world.log << "## WARNING: [type] - Don't set lights up manually during New(), We do it automatically."
		light = new(src)

//Movable atoms with opacity when they are constructed will trigger nearby lights to update
//Movable atoms with luminosity when they are constructed will create a light_source automatically
//TODO: lag reduction
/atom/movable/New()
	..()
	if(opacity)
		UpdateAffectingLights()
	if(luminosity)
		if(light)	world.log << "## WARNING: [type] - Don't set lights up manually during New(), We do it automatically."
		light = new(src)

//Turfs with opacity will trigger nearby lights to update at next lighting process.
//TODO: is this really necessary? Removing it could help reduce lag during singulo-mayhem somewhat
/turf/Destroy()
	if(opacity)
		UpdateAffectingLights()
	..()

//Objects with opacity will trigger nearby lights to update at next lighting process.
/atom/movable/Destroy()
	if(opacity)
		UpdateAffectingLights()
	..()

//Sets our luminosity. Enforces a hardcoded maximum luminosity by default. This maximum can be overridden but it is extremely
//unwise to do so.
//If we have no light it will create one.
//If we are setting luminosity to 0 the light will be cleaned up and delted once all its queues are complete
//if we have a light already it is merely updated
/obj/item/weapon/glowstick
	lighting_color = LIGHT_GREEN //yes
	lighting_luma = 0.16 // 666666666...
	icon = 'icons/obj/weapons.dmi'
	icon_state = "glowstick-green"
	w_class = 2

	red
		color = "#FF0000"
		lighting_color = list(1.0, 0.0, 0.0)

/atom/proc/SetLuminosity(new_luminosity, max_luminosity = MAX_LUMINOSITY)
	SetLuma(new_luminosity/MAX_LUMINOSITY)

/atom/proc/SetLuma(new_luma, max_luma = 1.0)
	lighting_luma = Clamp(new_luma,0.0,1.0) // Simple.

	var/new_luminosity = lighting_luma * MAX_LUMINOSITY
	if(isturf(loc))
		if(light)
			if(luminosity != new_luminosity)	//TODO: remove lights from the light list when they're not luminous? DONE in add_effect
				light.changed = 1
		else
			if(new_luminosity)
				light = new(src)

	luminosity = new_luminosity

//Snowflake code to prevent mobs becoming suns (lag-prevention)
mob/SetLuminosity(new_luminosity)
	..(new_luminosity,MAX_LUMINOSITY_MOB)

//change our opacity (defaults to toggle), and then update all lights that affect us.
atom/proc/SetOpacity(var/new_opacity)
	if(new_opacity == null)			new_opacity = !opacity
	else if(opacity == new_opacity)	return
	opacity = new_opacity

	UpdateAffectingLights()

//set the changed status of all lights which could have possibly lit this atom.
//We don't need to worry about lights which lit us but moved away, since they will have change status set already
atom/proc/UpdateAffectingLights()
	var/turf/T = src
	if(!isturf(T))
		T = loc
		if(!isturf(T))	return
	for(var/atom in range(MAX_LUMINOSITY,T))	//TODO: this will probably not work very well :(
		var/atom/A = atom
		if(A.light && A.luminosity)
			A.light.changed = 1			//force it to update at next process()

/turf
	// Don't mess with this.
	var/_lighting_changed = 0

turf/space
	lighting_luma = 0.3 // Old lumcount was 4. 4/12 = 0.3.

// Luma: [0-1] Multiplier used on color.
/turf/proc/update_lighting(var/new_luma=-1,var/list/new_color=null)
	if(new_luma!=-1)
		lighting_luma = new_luma
	if(new_color!=null)
		lighting_color = new_color
	if(!_lighting_changed)
		lighting_controller.changed_turfs += src
		_lighting_changed = 1

// Compatibility.
// Luma is a multiplier: (luma/MAX_LUMA) * (r,g,b)
/turf/proc/update_lumcount(var/luma, var/list/_lcolor=null)
	update_lighting(luma/12,_lcolor)

/proc/mkHexColor(var/list/color)
	return "#" \
		+ add_zero2(num2hex(color[1]*255,1), 2) \
		+ add_zero2(num2hex(color[2]*255,1), 2) \
		+ add_zero2(num2hex(color[3]*255,1), 2)

turf/proc/shift_to_subarea()
	_lighting_changed = 0
	var/area/Area = loc

	if(!istype(Area) || !Area.lighting_use_dynamic /*|| !accepts_lighting*/) return

	// change the turf's area depending on its brightness
	// restrict light to valid levels
	var/light = LUMC_Q(lighting_luma)

	// Same with colored light.
	var/list/color_light = list(
		LUMC_Q(lighting_color[1]),
		LUMC_Q(lighting_color[2]),
		LUMC_Q(lighting_color[3])
	)
	var/ser_color = mkHexColor(color_light)
	var/find = findtextEx(Area.tag, "sd_L")
	var/new_tag = copytext(Area.tag, 1, find)
	new_tag += "sd_L[light][ser_color]" // sd_L0#RRGGBB
	if(Area.tag!=new_tag)	//skip if already in this area
		var/area/A = locate(new_tag)	// find an appropriate area
		if(!A)

			A = new Area.type()    // create area if it wasn't found
			// replicate vars
			for(var/V in Area.vars)
				switch(V)
					if("contents","lighting_overlay", "color_overlay","overlays")	continue
					else
						if(issaved(Area.vars[V])) A.vars[V] = Area.vars[V]

			A.tag = new_tag        // Tell lighting system we're already subdivided
			A.lighting_subarea = 1 // In less uncertain terms.
			A.SetLightLevel(color_light)
			Area.related += A
		A.contents += src	// move the turf into the area

/area
	var/lighting_use_dynamic = 1	//Turn this flag off to prevent sd_DynamicAreaLighting from affecting this area
	var/image/lighting_overlay		//tracks the darkness image of the area for easy removal
	var/lighting_subarea = 0		//tracks whether we're a lighting sub-area

	proc/SetLightLevel(var/luma,var/list/color_light)
		if(!src) return

		// FUCK ALL YOUR COMPATIBILITY
		overlays = 0

		/**
		This is going to be a fucking mess, so bear with me.

		The old lighting system basically flopped a black mask over
		the area and dicked around with the alpha.  Well, it didn't
		have alpha back then, so it swapped between different
		predefined levels, but you get the idea.

		What we're going to do is make a white mask, and color it.

		Then we get into the hairy part: darkening the color mask
		from our luma so shit gets darker when luma goes down,
		rather than brighter.

		Then we simply add our overlay and change the alpha
		according to luma.
		**/

		// Let's get this show on the road.

		// Quantize and sanitize input.
		var/L = LUMC_Q(luma)

		// No luma?  Fuck the rest of this.
		if(L <= 0)
			L = 0
			luminosity = 0
			if(lighting_overlay)
				lighting_overlay = null
				return
		else
			luminosity = 1

		// Build our icon
		if(!lighting_overlay)
			lighting_overlay = image(LIGHTING_ICON,,"white",LIGHTING_LAYER)


		// Quantize colors, too.
		var/R = LUMC_Q(color_light[1])
		var/G = LUMC_Q(color_light[2])
		var/B = LUMC_Q(color_light[3])

		// If we're black, we're going to be black.
		if(R==0&&G==0&&B==0)
			lighting_overlay.color = "#000000"
		else
			////////////////////////////////
			// MAGIC STARTS HERE
			////////////////////////////////

			// Convert to RGB list with [0..255] gamma.
			var/list/RGB = list(round(R*0xFF),round(G*0xFF),round(B*0xFF))

			// Convert to HSV (Hue, Saturation, Value)
			var/list/HSV = ListRGBtoHSV(RGB)

			// Set value to luma, otherwise we get brighter rather than darker.
			HSV[3] = L

			// Convert back to RGB.
			RGB = ListHSVtoRGB(HSV)

			// Apply color to overlay
			lighting_overlay.color = mkHexColor(list(R/255,G/255,B/255)) // This is redundant as hell but I stopped caring a long time ago.

			///////////////////////////////
			// END MAGIC
			///////////////////////////////

		// Set alpha to luma
		lighting_overlay.alpha = L

		// And add our overlay.
		overlays += lighting_overlay

	proc/InitializeLighting()	//TODO: could probably improve this bit ~Carn
		if(!tag) tag = "[type]"
		if(!lighting_use_dynamic)
			if(!lighting_subarea)	// see if this is a lighting subarea already
				//show the dark overlay so areas, not yet in a lighting subarea, won't be bright as day and look silly.
				SetLightLevel(0.3,LIGHT_WHITE)


#undef LIGHTING_MAX_LUMINOSITY
#undef LIGHTING_MAX_LUMINOSITY_MOB
//#undef LIGHTING_LAYER
//#undef LIGHTING_ICON