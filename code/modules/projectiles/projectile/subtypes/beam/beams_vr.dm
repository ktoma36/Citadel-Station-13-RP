/obj/projectile/beam/disable
    name = "disabler beam"
    icon_state = "omnilaser"
    nodamage = 1
    taser_effect = 1
    agony = 100 //One shot stuns for the time being until adjustments are fully made.
    damage_type = DAMAGE_TYPE_HALLOSS
    light_color = "#00CECE"

    muzzle_type = /obj/effect/projectile/muzzle/laser_omni
    tracer_type = /obj/effect/projectile/tracer/laser_omni
    impact_type = /obj/effect/projectile/impact/laser_omni

/obj/projectile/beam/stun
	agony = 35

/obj/projectile/beam/energy_net
	name = "energy net projection"
	icon_state = "xray"
	nodamage = 1
	agony = 5
	damage_type = DAMAGE_TYPE_HALLOSS
	light_color = "#00CC33"

	muzzle_type = /obj/effect/projectile/muzzle/xray
	tracer_type = /obj/effect/projectile/tracer/xray
	impact_type = /obj/effect/projectile/impact/xray

/obj/projectile/beam/energy_net/on_impact(atom/target, impact_flags, def_zone, efficiency)
	. = ..()
	if(. & PROJECTILE_IMPACT_FLAGS_UNCONDITIONAL_ABORT)
		return
	if(!ismob(target))
		return
	do_net(target)

/obj/projectile/beam/energy_net/proc/do_net(var/mob/M)
	var/obj/item/energy_net/net = new (get_turf(M))
	net.throw_impact(M)

/obj/projectile/beam/stun/blue
	icon_state = "bluelaser"
	light_color = "#0066FF"

	muzzle_type = /obj/effect/projectile/muzzle/laser_blue
	tracer_type = /obj/effect/projectile/tracer/laser_blue
	impact_type = /obj/effect/projectile/impact/laser_blue

/obj/projectile/beam/medigun
	name = "healing beam"
	icon_state = "healbeam"
	damage_force = 0 //stops it damaging walls
	nodamage = TRUE
	damage_type = DAMAGE_TYPE_BURN
	damage_flag = ARMOR_LASER
	light_color = "#80F5FF"

	combustion = FALSE

	muzzle_type = /obj/effect/projectile/muzzle/medigun
	tracer_type = /obj/effect/projectile/tracer/medigun
	impact_type = /obj/effect/projectile/impact/medigun

/obj/projectile/beam/medigun/on_impact(atom/target, impact_flags, def_zone, efficiency)
	. = ..()
	if(. & PROJECTILE_IMPACT_FLAGS_UNCONDITIONAL_ABORT)
		return

	if(istype(target, /mob/living/carbon/human))
		var/mob/living/carbon/human/M = target
		if(M.health < M.maxHealth)
			var/obj/effect/overlay/pulse = new /obj/effect/overlay(get_turf(M))
			pulse.icon = 'icons/effects/effects.dmi'
			pulse.icon_state = "heal"
			pulse.name = "heal"
			pulse.anchored = 1
			spawn(20)
				qdel(pulse)
			to_chat(target, "<span class='notice'>As the beam strikes you, your injuries close up!</span>")
			M.adjustBruteLoss(-15)
			M.adjustFireLoss(-15)
			M.adjustToxLoss(-5)
			M.adjustOxyLoss(-5)
