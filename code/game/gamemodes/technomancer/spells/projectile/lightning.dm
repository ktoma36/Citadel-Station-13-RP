/datum/technomancer/spell/lightning
	name = "Lightning Strike"
	desc = "This uses a hidden electrolaser, which creates a laser beam to ionize the enviroment, allowing for ideal conditions \
	for a directed lightning strike to occur.  The lightning is very strong, however it requires a few seconds to prepare a \
	strike.  Lightning functions cannot miss due to distance."
	cost = 150
	obj_path = /obj/item/spell/projectile/lightning
	category = OFFENSIVE_SPELLS

/obj/item/spell/projectile/lightning
	name = "lightning strike"
	icon_state = "lightning_strike"
	desc = "Now you can feel like Zeus."
	cast_methods = CAST_RANGED
	aspect = ASPECT_SHOCK
	spell_projectile = /obj/projectile/beam/lightning
	energy_cost_per_shot = 2500
	instability_per_shot = 10
	cooldown = 20
	pre_shot_delay = 10
	fire_sound = 'sound/weapons/gauss_shoot.ogg'

/obj/projectile/beam/lightning
	name = "lightning"
	icon_state = "lightning"
	nodamage = 1
	damage_type = DAMAGE_TYPE_HALLOSS

	muzzle_type = /obj/effect/projectile/muzzle/lightning
	tracer_type = /obj/effect/projectile/tracer/lightning
	impact_type = /obj/effect/projectile/impact/lightning

	var/power = 60				//How hard it will hit for with electrocute_act().

/obj/projectile/beam/lightning/on_impact(atom/target, impact_flags, def_zone, efficiency)
	. = ..()
	if(. & (PROJECTILE_IMPACT_FLAGS_UNCONDITIONAL_ABORT | PROJECTILE_IMPACT_BLOCKED))
		return
	var/mob/living/target_mob = target
	if(!isliving(target_mob))
		return
	if(ishuman(target_mob))
		var/mob/living/carbon/human/H = target_mob
		var/obj/item/organ/external/affected = H.get_organ(check_zone(BP_TORSO))
		H.electrocute_act(power, src, H.get_siemens_coefficient_organ(affected), affected, 0)
	else
		target_mob.electrocute_act(power, src, 0.75, BP_TORSO)
	return 1
