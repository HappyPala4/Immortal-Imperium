/mob/living/simple_animal/hostile/rippers
	name = "Ripper"
	real_name = "Ripper"
	desc = "Gnawing, gnashing worms!"
	icon = 'icons/mob/human_races/tyranids/tyranids.dmi'
	icon_state = "ripper"
	icon_living = "ripper"
	icon_dead = "ripper_dead"
	maxHealth = 3
	health = 3
	meat_type = null
	universal_speak = 1
	speak_emote = list("harks")
	emote_hear = list("growls")
	response_help  = "barks"
	response_disarm = "shoves"
	response_harm   = "mauls"
	melee_damage_lower = 10
	melee_damage_upper = 10
	attacktext = "mauls and bites with all its might!"
	maxbodytemp = 1000
	see_in_dark = 10
	wander = 1

	speed = -2.5

	min_gas = null
	max_gas = null
	minbodytemp = 0
	stance_step = 0
	armor_penetration = 2

	faction = "Tyranids"

/mob/living/simple_animal/hostile/rippers/Life()
	. =..()
	if(!.)
		return


	switch(stance)

		if(HOSTILE_STANCE_TIRED)
			stop_automated_movement = 1
			stance_step++
			if(stance_step >= 3) //rests for 10 ticks
				if(target_mob && target_mob in ListTargets(10))
					stance = HOSTILE_STANCE_ATTACK //If the mob he was chasing is still nearby, resume the attack, otherwise go idle.
				else
					stance = HOSTILE_STANCE_IDLE

		if(HOSTILE_STANCE_ALERT)
			stop_automated_movement = 1
			var/found_mob = 0
			if(target_mob && target_mob in ListTargets(10))
				if(!(SA_attackable(target_mob)))
					stance_step = max(0, stance_step) //If we have not seen a mob in a while, the stance_step will be negative, we need to reset it to 0 as soon as we see a mob again.
					stance_step++
					found_mob = 1
					src.set_dir(get_dir(src,target_mob))	//Keep staring at the mob

					if(stance_step in list(1,4,7)) //every 3 ticks
						var/action = pick( list( "clacks at [target_mob]", "locks onto [target_mob]", "prepares to attack [target_mob]", "charges [target_mob]" ) )
						if(action)
							custom_emote(1,action)
			if(!found_mob)
				stance_step--

			if(stance_step <= -20) //If we have not found a mob for 20-ish ticks, revert to idle mode
				stance = HOSTILE_STANCE_IDLE
			if(stance_step >= 1)   //If we have been staring at a mob for 7 ticks,
				stance = HOSTILE_STANCE_ATTACK

		if(HOSTILE_STANCE_ATTACKING)
			if(stance_step >= 200)	//attacks for 20 ticks, then it gets tired and needs to rest
				custom_emote(1, "is worn out and needs to rest." )
				stance = HOSTILE_STANCE_TIRED
				stance_step = 0
				walk(src, 0) //This stops the bear's walking
				return



/mob/living/simple_animal/hostile/rippers/attackby(var/obj/item/O as obj, var/mob/user as mob)
	if(stance != HOSTILE_STANCE_ATTACK && stance != HOSTILE_STANCE_ATTACKING)
		stance = HOSTILE_STANCE_ALERT
		stance_step = 6
		target_mob = user
	..()

/mob/living/simple_animal/hostile/rippers/attack_hand(mob/living/carbon/human/M as mob)
	if(stance != HOSTILE_STANCE_ATTACK && stance != HOSTILE_STANCE_ATTACKING)
		stance = HOSTILE_STANCE_ALERT
		stance_step = 6
		target_mob = M
	..()

/mob/living/simple_animal/hostile/rippers/FindTarget()
	. = ..()
	if(.)
		custom_emote(1,"stares alertly at [.]")
		stance = HOSTILE_STANCE_ALERT

/mob/living/simple_animal/hostile/rippers/LoseTarget()
	..(5)
