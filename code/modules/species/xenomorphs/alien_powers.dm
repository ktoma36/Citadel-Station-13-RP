/proc/alien_queen_exists(var/ignore_self,var/mob/living/carbon/human/self)
	for(var/mob/living/carbon/human/Q in living_mob_list)
		if(self && ignore_self && self == Q)
			continue
		if(Q.species.get_species_id() != SPECIES_ID_XENOMORPH_QUEEN)
			continue
		if(!Q.key || !Q.client || Q.stat)
			continue
		return 1
	return 0

/mob/living/carbon/human/proc/gain_plasma(var/amount)

	var/obj/item/organ/internal/xenos/plasmavessel/I = internal_organs_by_name[O_PLASMA]
	if(!istype(I)) return

	if(amount)
		I.stored_plasma += amount
	I.stored_plasma = max(0,min(I.stored_plasma,I.max_plasma))

/mob/living/carbon/human/proc/check_alien_ability(var/cost,var/needs_foundation,var/needs_organ)	//Returns 1 if the ability is clear for usage.

	var/obj/item/organ/internal/xenos/plasmavessel/P = internal_organs_by_name[O_PLASMA]
	if(!istype(P))
		to_chat(src, "<span class='danger'>Your plasma vessel has been removed!</span>")
		return

	if(needs_organ)
		var/obj/item/organ/internal/I = internal_organs_by_name[needs_organ]
		if(!I)
			to_chat(src, "<span class='danger'>Your [needs_organ] has been removed!</span>")
			return
		else if((I.status & ORGAN_CUT_AWAY) || I.is_broken())
			to_chat(src, "<span class='danger'>Your [needs_organ] is too damaged to function!</span>")
			return

	if(P.stored_plasma < cost)
		to_chat(src, "<span class='danger'>You don't have enough phoron stored to do that.</span>")
		return 0

	if(needs_foundation)
		var/turf/T = get_turf(src)
		var/has_foundation
		if(T)
			//TODO: Work out the actual conditions this needs.
			if(!(istype(T,/turf/space)))
				has_foundation = 1
		if(!has_foundation)
			to_chat(src, "<span class='danger'>You need a solid foundation to do that on.</span>")
			return 0

	P.stored_plasma -= cost
	return 1

// Free abilities.
/mob/living/carbon/human/proc/transfer_plasma(mob/living/carbon/human/M as mob in oview())
	set name = "Transfer Plasma"
	set desc = "Transfer Plasma to another alien"
	set category = "Abilities"

	if (get_dist(src,M) > 1)
		to_chat(src, "<span class='green'>You need to be closer.</span>")
		return

	var/obj/item/organ/internal/xenos/plasmavessel/I = M.internal_organs_by_name[O_PLASMA]
	if(!istype(I))
		to_chat(src, "<span class='green'>Their plasma vessel is missing.</span>")
		return

	var/amount = input("Amount:", "Transfer Plasma to [M]") as num
	if (amount)
		amount = abs(round(amount))
		if(check_alien_ability(amount,0,O_PLASMA))
			M.gain_plasma(amount)
			to_chat(M, "<span class='green'>[src] has transfered [amount] plasma to you.</span>")
			to_chat(src, "<span class='green'>You have transferred [amount] plasma to [M].</span>")
	return

// Queen verbs.
/mob/living/carbon/human/proc/lay_egg()

	set name = "Lay Egg (75)"
	set desc = "Lay an egg to produce huggers to impregnate prey with."
	set category = "Abilities"

	if(!config_legacy.aliens_allowed)
		to_chat(src, "You begin to lay an egg, but hesitate. You suspect it isn't allowed.")
		remove_verb(src, /mob/living/carbon/human/proc/lay_egg)
		return

	if(locate(/obj/structure/alien/egg) in get_turf(src))
		to_chat(src, "There's already an egg here.")
		return

	if(check_alien_ability(75,1,O_EGG))
		visible_message("<span class='green'><B>[src] has laid an egg!</B></span>")
		new /obj/structure/alien/egg(loc)

	return

// Drone verbs.
/mob/living/carbon/human/proc/evolve()
	set name = "Evolve (500)"
	set desc = "Produce an interal egg sac capable of spawning children. Only one queen can exist at a time."
	set category = "Abilities"

	if(alien_queen_exists())
		to_chat(src, "<span class='notice'>We already have an active queen.</span>")
		return

	if(check_alien_ability(500))
		visible_message("<span class='green'><B>[src] begins to twist and contort!</B></span>", "<span class='green'>You begin to evolve!</span>")
		src.set_species(/datum/species/xenos/queen)

	return

/mob/living/carbon/human/proc/plant()
	set name = "Plant Weeds (50)"
	set desc = "Plants some alien weeds"
	set category = "Abilities"

	if(check_alien_ability(50,1,O_RESIN))
		visible_message("<span class='green'><B>[src] has planted some alien weeds!</B></span>")
		var/obj/O = new /obj/structure/alien/weeds/node(loc)
		if(O)
			O.color = "#321D37"
	return

/mob/living/carbon/human/proc/Spit(var/atom/A)
	if((last_spit + 1 SECONDS) > world.time) //To prevent YATATATATATAT spitting.
		to_chat(src, "<span class='warning'>You have not yet prepared your chemical glands. You must wait before spitting again.</span>")
		return
	else
		last_spit = world.time

	if(spitting && incapacitated(INCAPACITATION_DISABLED))
		to_chat(src, "You cannot spit in your current state.")
		spitting = FALSE
		return
	else if(spitting)
		if(!check_alien_ability(20,0,O_ACID))
			spitting = FALSE
			return
		visible_message("<span class='warning'>[src] spits [spit_name] at \the [A]!</span>", "<span class='green'>You spit [spit_name] at \the [A].</span>")
		var/obj/projectile/P = new spit_projectile(get_turf(src))
		P.firer = src
		P.old_style_target(A)
		P.fire()
		playsound(loc, 'sound/weapons/pierce.ogg', 25, 0)

/mob/living/carbon/human/proc/corrosive_acid(O as obj|turf in oview(1)) //If they right click to corrode, an error will flash if its an invalid target./N
	set name = "Corrosive Acid (200)"
	set desc = "Drench an object in acid, destroying it over time."
	set category = "Abilities"

	if(!(O in oview(1)))
		to_chat(src, "<span class='green'>[O] is too far away.</span>")
		return

	// OBJ CHECK
	var/cannot_melt
	if(isobj(O))
		var/obj/I = O
		if(I.integrity_flags & INTEGRITY_ACIDPROOF)
			cannot_melt = 1
	else
		if(istype(O, /turf/simulated/wall))
			var/turf/simulated/wall/W = O
			if(W.material_outer.material_flags & MATERIAL_FLAG_UNMELTABLE)
				cannot_melt = 1
		else if(istype(O, /turf/simulated/floor))
/*			var/turf/simulated/floor/F = O							//Turfs are qdel'd to space (Even asteroid tiles), will need to be touched by someone smarter than myself. -Mech
			if(F.flooring && (F.flooring.flags & TURF_ACID_IMMUNE))
*/
			cannot_melt = 1

	if(cannot_melt)
		to_chat(src, "<span class='green'>You cannot dissolve this object.</span>")
		return

	if(check_alien_ability(200,0,O_ACID))
		new /obj/structure/alien/acid(get_turf(O), O)
		visible_message("<span class='green'><B>[src] vomits globs of vile stuff all over [O]. It begins to sizzle and melt under the bubbling mess of acid!</B></span>")

	return

/mob/living/carbon/human/proc/neurotoxin()
	set name = "Toggle Neurotoxic Spit (40)"
	set desc = "Readies a neurotoxic spit, which paralyzes the target for a short time if they are not wearing protective gear."
	set category = "Abilities"

	if(spitting)
		to_chat(src, "<span class='green'>You stop preparing to spit.</span>")
		spitting = FALSE
		return

	if(!check_alien_ability(40,0,O_ACID))
		spitting = FALSE
		return

	else
		last_spit = world.time
		spitting = TRUE
		spit_projectile = /obj/projectile/energy/neurotoxin
		spit_name = "neurotoxin"
		to_chat(src, "<span class='green'>You prepare to spit neurotoxin.</span>")

/mob/living/carbon/human/proc/acidspit()
	set name = "Toggle Acid Spit (50)"
	set desc = "Readies an acidic spit, which burns the target if they are not wearing protective gear."
	set category = "Abilities"

	if(spitting)
		to_chat(src, "<span class='green'>You stop preparing to spit.</span>")
		spitting = FALSE
		return

	if(!check_alien_ability(50,0,O_ACID))
		spitting = FALSE
		return

	else
		last_spit = world.time
		spitting = TRUE
		spit_projectile = /obj/projectile/energy/acid
		spit_name = "acid"
		to_chat(src, "<span class='green'>You prepare to spit acid.</span>")

/mob/living/carbon/human/proc/resin()
	set name = "Secrete Resin (75)"
	set desc = "Secrete tough malleable resin."
	set category = "Abilities"

	var/choice = input("Choose what you wish to shape.","Resin building") as null|anything in list("resin door","resin wall","resin membrane","resin nest","resin blob") //would do it through typesof but then the player choice would have the type path and we don't want the internal workings to be exposed ICly - Urist
	if(!choice)
		return

	if(!check_alien_ability(75,1,O_RESIN))
		return

	visible_message("<span class='warning'><B>[src] vomits up a thick purple substance and begins to shape it!</B></span>", "<span class='green'>You shape a [choice].</span>")

	var/obj/O

	switch(choice)
		if("resin door")
			O = new /obj/structure/simple_door/resin(loc)
		if("resin wall")
			O = new /obj/structure/alien/resin/wall(loc)
		if("resin membrane")
			O = new /obj/structure/alien/resin/membrane(loc)
		if("resin nest")
			O = new /obj/structure/bed/nest(loc)
		if("resin blob")
			O = new /obj/item/stack/material/resin(loc)

	if(O)
		O.color = "#321D37"

	return

/mob/living/carbon/human/proc/leap()
	set category = "Abilities"
	set name = "Leap"
	set desc = "Leap at a target and grab them aggressively."

	if(last_special > world.time)
		return

	if(stat || !CHECK_MOBILITY(src, MOBILITY_CAN_USE) || lying || restrained() || buckled)
		to_chat(src, "You cannot leap in your current state.")
		return

	var/list/choices = list()
	for(var/mob/living/M in view(6,src))
		if(!istype(M,/mob/living/silicon))
			choices += M
	choices -= src

	var/mob/living/T = input(src,"Who do you wish to leap at?") as null|anything in choices

	if(!T || !src || src.stat) return

	if(get_dist(get_turf(T), get_turf(src)) > 4) return

	if(last_special > world.time)
		return

	if(stat || !CHECK_MOBILITY(src, MOBILITY_CAN_USE) || lying || restrained() || buckled)
		to_chat(src, "You cannot leap in your current state.")
		return

	last_special = world.time + 75
	status_flags |= STATUS_LEAPING

	src.visible_message("<span class='danger'>\The [src] leaps at [T]!</span>")
	src.throw_at_old(get_step(get_turf(T),get_turf(src)), 4, 1, src)
	playsound(src.loc, 'sound/voice/hiss5.ogg', 50, 1)

	sleep(5)

	if(status_flags & STATUS_LEAPING) status_flags &= ~STATUS_LEAPING

	if(!src.Adjacent(T))
		to_chat(src, "<span class='warning'>You miss!</span>")
		return

	T.afflict_paralyze(20 * 3)

	if(are_usable_hands_full())
		to_chat(src, "<span class='danger'>You need to have one hand free to grab someone.</span>")
		return

	src.visible_message("<span class='warning'><b>\The [src]</b> seizes [T] aggressively!</span>")

	var/obj/item/grab/G = new(src, T)
	if(!put_in_hands_or_del(G))
		return

	G.state = GRAB_PASSIVE
	G.icon_state = "grabbed1"

/mob/living/carbon/human/proc/gut()
	set category = "Abilities"
	set name = "Gut"
	set desc = "While grabbing someone aggressively, rip their guts out or tear them apart."

	if(last_special > world.time)
		return

	if(stat || !CHECK_MOBILITY(src, MOBILITY_CAN_USE) || lying)
		to_chat(src, "<span class='danger'>You cannot do that in your current state.</span>")
		return

	var/obj/item/grab/G = locate() in src
	if(!G || !istype(G))
		to_chat(src, "<span class='danger'>You are not grabbing anyone.</span>")
		return

	if(G.state < GRAB_AGGRESSIVE)
		to_chat(src, "<span class='danger'>You must have an aggressive grab to gut your prey!</span>")
		return

	last_special = world.time + 50

	visible_message("<span class='warning'><b>\The [src]</b> rips viciously at \the [G.affecting]'s body with its claws!</span>")

	if(istype(G.affecting,/mob/living/carbon/human))
		var/mob/living/carbon/human/H = G.affecting
		H.apply_damage(50,DAMAGE_TYPE_BRUTE)
		if(H.stat == 2)
			H.gib()

	else
		var/mob/living/M = G.affecting
		if(!istype(M)) return //wut
		M.apply_damage(50,DAMAGE_TYPE_BRUTE)
		if(M.stat == 2)
			M.gib()
