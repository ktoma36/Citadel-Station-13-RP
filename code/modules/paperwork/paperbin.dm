/obj/item/paper_bin
	name = "paper bin"
	desc = "Contains all the paper you'll never need."
	icon = 'icons/obj/bureaucracy.dmi'
	icon_state = "paper_bin1"
	item_icons = list(
			SLOT_ID_LEFT_HAND = 'icons/mob/items/lefthand_material.dmi',
			SLOT_ID_RIGHT_HAND = 'icons/mob/items/righthand_material.dmi',
			)
	item_state = "sheet-metal"
	throw_force = 1
	w_class = WEIGHT_CLASS_NORMAL
	throw_speed = 3
	throw_range = 7
	pressure_resistance = 10
	layer = OBJ_LAYER - 0.1
	var/amount = 30					//How much paper is in the bin.
	var/list/papers = new/list()	//List of papers put in the bin for reference.
	drop_sound = 'sound/items/drop/cardboardbox.ogg'
	pickup_sound = 'sound/items/pickup/cardboardbox.ogg'

/obj/item/paper_bin/Destroy()
	QDEL_LIST(papers)
	return ..()

/obj/item/paper_bin/OnMouseDropLegacy(mob/user as mob)
	if((user == usr && (!( usr.restrained() ) && (!( usr.stat ) && (usr.contents.Find(src) || in_range(src, usr))))))
		if(!user.put_in_hands(src))
			return
		to_chat(user, "<span class='notice'>You pick up the [src].</span>")

/obj/item/paper_bin/attack_hand(mob/user, datum/event_args/actor/clickchain/e_args)
	if(!user.standard_hand_usability_check(src, e_args.hand_index, HAND_MANIPULATION_GENERAL))
		return

	var/response = ""
	if(!papers.len)
		response = alert(user, "Do you take regular paper, or Carbon copy paper?", "Paper type request", "Regular", "Carbon-Copy", "Cancel")
		if(!user.Adjacent(src))
			return
		if (response != "Regular" && response != "Carbon-Copy")
			add_fingerprint(user)
			return
	if(amount >= 1)
		amount--
		if(!amount)
			update_icon()

		var/obj/item/paper/P
		if(papers.len)	//If there's any custom paper on the stack, use that instead of creating a new paper.
			P = papers[papers.len]
			papers.Remove(P)
		else
			if(response == "Regular")
				P = new /obj/item/paper
				if(Holiday == "April Fool's Day")
					if(prob(30))
						P.info = "<font face=\"[P.crayonfont]\" color=\"red\"><b>HONK HONK HONK HONK HONK HONK HONK<br>HOOOOOOOOOOOOOOOOOOOOOONK<br>APRIL FOOLS</b></font>"
						P.rigged = 1
						P.updateinfolinks()
			else if (response == "Carbon-Copy")
				P = new /obj/item/paper/carbon
		user.put_in_hands_or_drop(P)
		to_chat(user, "<span class='notice'>You take [P] out of the [src].</span>")
	else
		to_chat(user, "<span class='notice'>[src] is empty!</span>")

	add_fingerprint(user)
	return


/obj/item/paper_bin/attackby(obj/item/I, mob/living/user, params, clickchain_flags, damage_multiplier)
	if(!istype(I, /obj/item/paper))
		return ..()

	if(!user.attempt_insert_item_for_installation(I, src))
		return

	to_chat(user, "<span class='notice'>You put [I] in [src].</span>")
	papers.Add(I)
	update_icon()
	amount++


/obj/item/paper_bin/examine(mob/user, dist)
	. = ..()
	if(get_dist(src, user) <= 1)
		if(amount)
			. += "<span class='notice'>There " + (amount > 1 ? "are [amount] papers" : "is one paper") + " in the bin.</span>"
		else
			. += "<span class='notice'>There are no papers in the bin.</span>"

/obj/item/paper_bin/update_icon()
	if(amount < 1)
		icon_state = "paper_bin0"
	else
		icon_state = "paper_bin1"

/obj/item/paper_bin/bundlenatural
	name = "natural paper bundle"
	desc = "A bundle of paper created using traditional methods."
	icon_state = "paper_bundle"
	papers = /obj/item/paper/natural

/obj/item/paper_bin/bundlenatural/attack_hand(mob/user, datum/event_args/actor/clickchain/e_args)
	if(amount < 1)
		qdel(src)
	return ..()
