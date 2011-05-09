/obj/machinery/bot/dogbot
	name = "Rover 0.1b"
	desc = "A mechanical dog. Looks like a weiner."
	icon = 'food.dmi'
	icon_state = "hotdog"

	//wtf do these vars do?
	layer = 5.0
	density = 1
	anchored = 0

	req_access = list(access_robotics, access_medical)
	var/on = 1
	var/locked = 1
	//Dogbot's master
	var/mob/living/carbon/master
	//Dogbot's enemy
	var/mob/living/carbon/target
	var/oldtarget_name
	var/anger = 0
	var/emagged = 0 //Emagged dogbots have seisures and follow a new master... They also bite their old master
	var/health = 20

	var/mode = 0
#define DOGBOT_IDLE				0	// idle
#define DOGBOT_FINDFOOD			1	// find food and eat it
#define DOGBOT_EAT				2	// eat the food
#define DOGBOT_FIND_MASTER		3	// Locate master and follow
#define DOGBOT_HEAL_MASTER		4
#define DOGBOT_FOLLOW			5	// Follow master
#define DOGBOT_PROTECT_MASTER	6	// Attack people who attack master
#define DOGBOT_PROTECT_SELF		7	// Attack person who attacks dogbot

	var/obj/machinery/camera/cam //Dogbot has a camera


/obj/machinery/bot/dogbot
	New()
		..()
		src.icon_state = "hotdog"
		spawn(3)
			src.botcard = new /obj/item/weapon/card/id(src)
			src.botcard.access = get_access("Captain")
			src.cam = new /obj/machinery/camera(src)
			src.cam.c_tag = src.name
			src.cam.network = "SS13"

	examine()
		set src in view()
		..()

		if (src.health < 20)
			if (src.health > 10)
				usr << text("\red [src] looks like it needs a vet!")
			else
				usr << text("\red [src] looks kind of droopy.")
			return

	attack_hand(user as mob)
		var/dat

		if (master == null) //We should be able to set the bot's master from the assembly, but if its admin created, this should fix it.
			master = user // lol hack -- replace this with new master has to feed it some poo or a dogbiscuit.

		dat += text({"
<TT><B>Dogbot Version 0.1b</B></TT><BR><BR>
Status: []"}, "<A href='?src=\ref[src];power=1'>[src.on ? "On" : "Off"]</A>" )

		user << browse("<HEAD><TITLE>Dogbot v0.1b controls</TITLE></HEAD>[dat]", "window=autosec")
		onclose(user, "autosec")
		return

	Topic(href, href_list)
		usr.machine = src
		src.add_fingerprint(usr)
		if ((href_list["power"]) && (src.allowed(usr)))
			src.on = !src.on
			src.mode = DOGBOT_IDLE
			src.icon_state = "hotdog"
			src.updateUsrDialog()

	attack_ai(mob/user as mob)
		src.on = !src.on
		src.mode = DOGBOT_IDLE
		src.icon_state = "hotdog"

	attackby(obj/item/weapon/W as obj, mob/user as mob)
		if ((istype(W, /obj/item/weapon/card/emag)) && (!src.emagged))
			user << "\red You short out [src]'s friendly pet circuits. It's sad whine almost makes you tear up. You heartless bastard."
			spawn(0)
				for(var/mob/O in hearers(src, null))
					O.show_message("\red <B>[src] whines and begins twitching.</B>", 1)
			src.emagged = 1
			src.on = 1
			src.icon_state = "hotdog"
			mode = DOGBOT_IDLE
		else if (istype(W, /obj/item/weapon/card/id))
			if (src.allowed(user))
				src.locked = !src.locked
				user << "Controls are now [src.locked ? "locked." : "unlocked."] [src] wags its tail happily."
			else
				user << "\red [src] growls."

		else if (istype(W, /obj/item/weapon/screwdriver))
			if (src.health < 20)
				src.health = 20
				for(var/mob/O in viewers(src, null))
					O << "\red [user] repairs [src]!"
		else
			switch(W.damtype)
				if("fire")
					src.health -= W.force * 0.75
				if("brute")
					src.health -= W.force * 0.5
				else
			if(src.health <= 0)
				src.explode()
			//todo else if attacked but not dead, set attacker as target and get angry

	process()
		set background = 1

		if (!src.on)
			return
			#define DEBUG
		//check on master
		for (var/mob/living/carbon/C in view(7,src))
			if(C == master)	
				assess_master(C)
			
		switch(mode)
			//if(DOGBOT_IDLE)		//idle
				//look for enemy

			//if(DOGBOT_FINDFOOD)
				//look for food

			//if(DOGBOT_EAT)
				//found food, now eat it.

			//if(DOGBOT_FIND_MASTER)
			//Find a path to master and follow it. If the master's position changes, recalculate

			//if(DOGBOT_HEAL_MASTER)
			//If master is hurt, heal master!
			
			//if(DOGBOT_FOLLOW)
			//Found master, now follow. If master gets more than 10 tile distance away, find master

			//if(DOGBOT_PROTECT_MASTER)
			//If dogbot witnesses an attack on its master, it should get pissed.

			//if(DOGBOT_PROTECT_SELF)

		return

	proc/assess_master(mob/living/carbon/C as mob)
		if(C.stat == 2)
			master = null
			doggymote("howls sadly and nudges [C]'s corpse with its little wet nose. How tragic!")
			mode = DOGBOT_IDLE
			return 	//Master's dead, time to find a new master.
			
		if(C.suiciding)
			master = null
			return
			
		if(C.bruteloss >= 15 || C.fireloss >= 15)
			mode = DOGBOT_HEAL_MASTER // PAPAS INJURED LICK HIS PRIVATES!
			return
			
	proc/doggymote(var/message)
		if((!src.on) || (!message))
			return
		for(var/mob/O in hearers(src, null))
			O.show_message("\red [src] [message]",2)
		return
	
	proc/findmaster()
		//find a path to master
		src.explode()
		return

	meteorhit()
		src.explode()
		return

	blob_act()
		if(prob(25))
			src.explode()
		return

	proc/explode()
		src.on = 0
		for(var/mob/O in hearers(src, null))
			O.show_message("\red <B>[src] blows apart!</B>", 1)
		var/turf/Tsec = get_turf(src)

		//TODO: make robogibs

		var/datum/effects/system/spark_spread/s = new /datum/effects/system/spark_spread
		s.set_up(3, 1, src)
		s.start()
		del(src)
		return