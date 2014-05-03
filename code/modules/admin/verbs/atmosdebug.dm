/client/proc/atmosscan()
	set category = "Mapping"
	set name = "Check Plumbing"
	if(!src.holder)
		src << "Only administrators may use this command."
		return
	feedback_add_details("admin_verb","CP") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

	//all plumbing - yes, some things might get stated twice, doesn't matter.
	for (var/obj/machinery/networked/atmos/plumbing in world)
		if (plumbing.nodealert)
			usr << "Unconnected [plumbing.name] located at [formatJumpTo(plumbing.loc)]"

	//Manifolds
	for (var/obj/machinery/networked/atmos/pipe/manifold/pipe in world)
		if (!pipe.node1 || !pipe.node2 || !pipe.node3)
			usr << "Unconnected [pipe.name] located at [formatJumpTo(pipe.loc)]"

	//4-way Manifolds
	for (var/obj/machinery/networked/atmos/pipe/manifold4w/pipe in world)
		if (!pipe.node1 || !pipe.node2 || !pipe.node3 || !pipe.node4)
			usr << "Unconnected [pipe.name] located at [formatJumpTo(pipe.loc)]"

	//Pipes
	for (var/obj/machinery/networked/atmos/pipe/simple/pipe in world)
		if (!pipe.node1 || !pipe.node2)
			usr << "Unconnected [pipe.name] located at [formatJumpTo(pipe.loc)]"