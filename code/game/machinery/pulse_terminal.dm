//##############################################
//########### PULSE / NEWS TERMINAL ############
//###-Sits in the village, forum + news board.##
//###-Uses the global news_network for storage:
//### Pulse threads = non-admin feed channels
//### authored by "Pulse"; the News feed is an
//### admin channel authored by "Pulse".
//##############################################

/obj/machinery/pulse_terminal
	name = "City terminal"
	desc = "Простой общественный когитатор. Горожане могут читать новости или переписыватся в ветках на фороме Пульс. Высокопоставленные чины могут писать новости через этот терминал."
	icon = 'icons/obj/machines/ludkamachines.dmi'
	icon_state = "baseterminal_off"
	anchored = 1
	density = 1
	use_power = 0
	layer = ABOVE_WINDOW_LAYER
	var/logged_name = ""	//Nickname used when posting
	var/screen = 0			//0 main menu, 1 news, 2 thread list, 3 thread view
	var/datum/feed_channel/viewing_channel = null
	var/const/PULSE_TAG = "Pulse"
	var/const/NEWS_NAME = "News"

/obj/machinery/pulse_terminal/update_icon()
	if(stat & BROKEN)
		icon_state = "baseterminal_off"
		return
	icon_state = "baseterminal"

/obj/machinery/pulse_terminal/attack_ai(var/mob/user as mob)
	return src.attack_hand(user)

/obj/machinery/pulse_terminal/attack_hand(var/mob/user as mob)
	if(stat & BROKEN)
		return
	if(!user.IsAdvancedToolUser())
		return 0
	if(istype(user, /mob/living/carbon/human) || istype(user, /mob/living/silicon))
		var/mob/living/human_or_robot_user = user
		update_icon()
		var/dat = "<HEAD><TITLE>Pulse/News</TITLE></HEAD><H3>Pulse/News Terminal</H3>"
		var/obj/item/card/id/C = get_user_id(human_or_robot_user)
		if(!C)
			dat += "<I>No identification detected.</I><BR>"
			dat += "Hold an ID card in your active hand, or wear it, and approach the terminal again.<HR>"
			dat += "<A href='?src=\ref[src];refresh=1'>Re-scan</A><BR><BR>"
			show_browser(human_or_robot_user, dat, "window=pulse_terminal;size=450x600")
			onclose(human_or_robot_user, "pulse_terminal")
			return
		human_or_robot_user.set_machine(src)
		if(!logged_name)
			logged_name = C.registered_name
		var/priv = is_privileged(C)
		var/ass = C.assignment ? C.assignment : "Unassigned"
		dat += "Authorised: <FONT COLOR='green'>[logged_name]</FONT> (Card: [C.name], Department: [ass])"
		if(priv)
			dat += " <FONT COLOR='maroon'>NEWS posting access granted</FONT>"
		dat += "<HR>"
		switch(screen)
			if(0)
				dat += "<B>Pulse</B> - community board of the alignment.<BR>"
				dat += "<A href='?src=\ref[src];show_threads=1'>Browse threads</A><BR>"
				dat += "<A href='?src=\ref[src];new_thread=1'>Start a new thread</A><BR>"
				dat += "<BR><B>News</B> - official bulletins.<BR>"
				dat += "<A href='?src=\ref[src];show_news=1'>Read the News</A>"
				if(priv)
					dat += "<BR><A href='?src=\ref[src];new_news=1'>Post a News bulletin</A>"
				dat += "<BR><BR><A href='?src=\ref[src];account=1'>Account</A> - <FONT COLOR='green'>[C.money]</FONT> thrones"
				dat += "<BR><A href='?src=\ref[src];rename=1'>Change nickname</A> (currently: [logged_name])"
				dat += "<BR><A href='?src=\ref[src];logout=1'>Log out</A>"
				dat += get_extra_menu_links()
			if(1)
				dat += "<B>News</B> - official bulletins.<HR>"
				var/datum/feed_channel/NC = get_news_channel()
				if(NC)
					if(isemptylist(NC.messages))
						dat += "<I>No bulletins have been posted yet.</I><BR>"
					else
						for(var/datum/feed_message/M in NC.messages)
							dat += "- [M.body]<BR><FONT SIZE=1>[M.author] - [M.time_stamp]</FONT><BR><BR>"
				dat += "<HR><A href='?src=\ref[src];refresh=1'>Refresh</A> / <A href='?src=\ref[src];setScreen=[0]'>Back</A>"
			if(2)
				dat += "<B>Pulse</B> - active threads.<HR>"
				var/list/threads = get_pulse_channels()
				if(isemptylist(threads))
					dat += "<I>No threads yet. Start the first one!</I><BR>"
				else
					for(var/datum/feed_channel/FC in threads)
						dat += "<A href='?src=\ref[src];view_thread=\ref[FC]'>[FC.channel_name]</A> ([FC.messages.len] posts)<BR>"
				dat += "<HR><A href='?src=\ref[src];new_thread=1'>Start a new thread</A>"
				dat += "<BR><A href='?src=\ref[src];refresh=1'>Refresh</A> / <A href='?src=\ref[src];setScreen=[0]'>Back</A>"
			if(3)
				if(viewing_channel)
					dat += "<B>[viewing_channel.channel_name]</B> <FONT SIZE=1>\[opened by [viewing_channel.author]\]</FONT><HR>"
					if(isemptylist(viewing_channel.messages))
						dat += "<I>No posts yet.</I><BR>"
					else
						for(var/datum/feed_message/M in viewing_channel.messages)
							dat += "- [M.body]<BR><FONT SIZE=1>[M.author] - [M.time_stamp]</FONT><BR><BR>"
					dat += "<HR><A href='?src=\ref[src];reply=1'>Reply</A><BR>"
				dat += "<A href='?src=\ref[src];refresh=1'>Refresh</A> / <A href='?src=\ref[src];setScreen=[2]'>Back</A>"
			if(4)
				dat += "<B>Account</B><HR>"
				dat += "Holder: <FONT COLOR='green'>[logged_name]</FONT><BR>"
				dat += "Balance: <FONT COLOR='green'>[C.money]</FONT> thrones<BR><BR>"
				dat += "Insert throne coins into the terminal to deposit them onto this card.<BR><BR>"
				dat += "<A href='?src=\ref[src];withdraw=1'>Withdraw thrones</A><BR>"
				dat += "<A href='?src=\ref[src];setScreen=[0]'>Back</A>"
			else
				dat += get_extra_screen()
		dat += "<BR><BR><A href='?src=\ref[human_or_robot_user];mach_close=pulse_terminal'>Close</A>"
		show_browser(human_or_robot_user, dat, "window=pulse_terminal;size=450x600")
		onclose(human_or_robot_user, "pulse_terminal")
	return

/obj/machinery/pulse_terminal/Topic(href, href_list)
	if(..())
		return
	if(!((usr.contents.Find(src)) || ((get_dist(src, usr) <= 1) && istype(src.loc, /turf))))
		return
	usr.set_machine(src)
	var/obj/item/card/id/C = get_user_id(usr)
	handle_extra_topic(C, href_list)
	if(href_list["setScreen"])
		screen = text2num(href_list["setScreen"])
	else if(href_list["account"])
		screen = 4
	else if(href_list["withdraw"])
		if(C)
			var/wd = round(input(usr, "How many thrones would you like to withdraw?", "Account", "") as null|num)
			if(wd && wd > 0 && wd <= C.money)
				C.money -= wd
				spawn_coins(usr, wd)
			else
				to_chat(usr, "<span class='warning'>Invalid withdrawal amount.</span>")
	else if(href_list["refresh"])
		//just redraws the current screen
	else if(href_list["logout"])
		logged_name = ""
		screen = 0
	else if(href_list["rename"])
		if(C)
			var/new_name = sanitizeSafe(input(usr, "Enter your nickname:", "Pulse/News", logged_name), MAX_LNAME_LEN)
			if(new_name)
				logged_name = new_name
	else if(href_list["show_news"])
		screen = 1
	else if(href_list["show_threads"])
		screen = 2
	else if(href_list["view_thread"])
		var/datum/feed_channel/FC = locate(href_list["view_thread"])
		if(FC && FC in news_network.network_channels)
			viewing_channel = FC
			screen = 3
	else if(href_list["new_thread"])
		if(C)
			var/tname = sanitizeSafe(input(usr, "Name your thread:", "Pulse/News", ""), MAX_LNAME_LEN)
			if(tname)
				create_pulse_thread(tname)
				screen = 2
	else if(href_list["reply"])
		if(C && viewing_channel)
			var/body = sanitizeSafe(input(usr, "Your message:", "Pulse/News", ""), MAX_MESSAGE_LEN)
			if(body != "")
				news_network.SubmitArticle(body, get_author(C), viewing_channel.channel_name, null, 0, "Post")
	else if(href_list["new_news"])
		if(C && is_privileged(C))
			var/body = sanitizeSafe(input(usr, "News bulletin text:", "Pulse/News", ""), MAX_MESSAGE_LEN)
			if(body != "")
				var/datum/feed_channel/NC = get_news_channel()
				news_network.SubmitArticle(body, "[C.assignment ? C.assignment : "Pulse"] [logged_name]", NC.channel_name, null, 1, "News")
				screen = 1
	update_icon()
	src.attack_hand(usr)
	return

/obj/machinery/pulse_terminal/proc/get_user_id(var/mob/user)
	var/obj/item/card/id/C = user.get_active_hand()
	if(istype(C))
		return C
	if(istype(user, /mob/living/carbon/human))
		var/mob/living/carbon/human/H = user
		if(istype(H.wear_id))
			return H.wear_id
	return null

/obj/machinery/pulse_terminal/proc/is_privileged(var/obj/item/card/id/C)
	if(!istype(C))
		return 0
	var/a = lowertext(C.assignment)
	if(findtext(a, "governor") || findtext(a, "commissar") || findtext(a, "deacon"))
		return 1
	return 0

/obj/machinery/pulse_terminal/proc/get_author(var/obj/item/card/id/C)
	var/name = logged_name ? logged_name : (C ? C.registered_name : "Unknown")
	var/ass = C ? C.assignment : ""
	if(ass)
		return "[name] ([ass])"
	return name

/obj/machinery/pulse_terminal/proc/get_pulse_channels()
	var/list/res = list()
	for(var/datum/feed_channel/FC in news_network.network_channels)
		if(FC.author == PULSE_TAG && !FC.is_admin_channel)
			res += FC
	return res

/obj/machinery/pulse_terminal/proc/get_news_channel()
	for(var/datum/feed_channel/FC in news_network.network_channels)
		if(FC.channel_name == NEWS_NAME && FC.is_admin_channel)
			return FC
	news_network.CreateFeedChannel(NEWS_NAME, PULSE_TAG, 1, 1, "New official bulletin posted.")
	for(var/datum/feed_channel/FC in news_network.network_channels)
		if(FC.channel_name == NEWS_NAME && FC.is_admin_channel)
			return FC
	return null

/obj/machinery/pulse_terminal/proc/create_pulse_thread(var/tname)
	for(var/datum/feed_channel/FC in news_network.network_channels)
		if(FC.channel_name == tname)
			return
	news_network.CreateFeedChannel(tname, PULSE_TAG, 0, 0, "A new thread has been opened in the Pulse forum.")

/obj/machinery/pulse_terminal/attackby(var/obj/item/O, var/mob/user)
	var/obj/item/card/id/C = get_user_id(user)
	if(!C)
		to_chat(user, "<span class='warning'>Swipe or hold an ID card to deposit money.</span>")
		return 1
	var/value = 0
	if(istype(O, /obj/item/stack/thrones))
		value = 10
	else if(istype(O, /obj/item/stack/thrones2))
		value = 5
	else if(istype(O, /obj/item/stack/thrones3))
		value = 1
	if(!value)
		return ..()
	user.setClickCooldown(DEFAULT_ATTACK_COOLDOWN)
	var/obj/item/stack/S = O
	S.amount -= 1
	var/deposited = value - round(value * GLOB.tax_rate, 1)
	var/tax = round(value * GLOB.tax_rate, 1)
	C.money += deposited
	GLOB.thrones += tax
	playsound(src, 'sound/effects/coin_ins.ogg', 50, 0, -1)
	visible_message("[user] inserts a coin into [src]. [deposited] thrones added ([tax] in taxes).")
	if(S.amount <= 0)
		qdel(S)
	else
		S.update_icon()
	src.attack_hand(user)
	return 1

/obj/machinery/pulse_terminal/proc/spawn_coins(var/mob/user, var/wd)
	while(wd > 0)
		if(wd >= 10)
			var/obj/item/stack/thrones/money = new(get_turf(user))
			money.amount = round(wd / 10)
			wd -= (money.amount * 10)
		if(wd >= 5 && wd < 10)
			var/obj/item/stack/thrones2/money = new(get_turf(user))
			money.amount = round(wd / 5)
			wd -= (money.amount * 5)
		if(wd >= 1 && wd < 5)
			var/obj/item/stack/thrones3/money = new(get_turf(user))
			money.amount = wd
			wd -= money.amount

/obj/machinery/pulse_terminal/proc/get_extra_menu_links()
	return ""

/obj/machinery/pulse_terminal/proc/get_extra_screen()
	screen = 0
	return ""

/obj/machinery/pulse_terminal/proc/handle_extra_topic(var/obj/item/card/id/C, var/list/href_list)
	return

//##############################################
//############# TRADE TERMINAL ##################
//###-Same Pulse/News mechanics as the city###
//###-terminal, plus a civilian shop. Orders###
//###-drop on the tradezone cargo pads. Money###
//###-is stored on the ID card.#################
//##############################################

/datum/shop_entry
	var/name
	var/cost = 0
	var/item_path
	var/category

/datum/shop_entry/proc/purchase(var/obj/machinery/pulse_terminal/ludka/terminal, var/mob/user, var/obj/item/card/id/C)
	if(terminal.busy)
		terminal.visible_message("<b>[terminal]</b> flashes an <span style='color:red'>error</span>, \"Busy.\"")
		return FALSE
	if(!terminal.drop_pads || !terminal.drop_pads.len)
		terminal.update_drop_pads()
		if(!terminal.drop_pads.len)
			terminal.visible_message("<b>[terminal]</b> flashes an <span style='color:red'>error</span>, \"Drop pads not found.\"")
			return FALSE
	var/total = cost + round(cost * GLOB.tax_rate, 1)
	if(C.money < total)
		terminal.visible_message("<b>[terminal]</b> flashes a <span style='color:red'>warning</span>, \"Your balance is too low.\"")
		return FALSE
	C.money -= total
	terminal.visible_message("<b>[terminal]</b> flashes a <span style='color:blue'>notice</span>, \"Your order has been confirmed. ETA: 5 seconds.\"")
	terminal.busy = TRUE
	playsound(terminal, 'sound/effects/beam.ogg', 50, 0, -1)
	addtimer(CALLBACK(src, .proc/drop_purchase, terminal), 5 SECONDS)
	return TRUE

/datum/shop_entry/proc/drop_purchase(var/obj/machinery/pulse_terminal/ludka/terminal)
	var/obj/effect/landmark/cargospawn/T = pick(terminal.drop_pads)
	var/atom/dropping = new item_path(T.loc)
	dropping.visible_message("[dropping] falls onto the drop pad.")
	terminal.busy = FALSE

/obj/machinery/pulse_terminal/ludka
	name = "Trade terminal"
	desc = "A bustling trade terminal. Order civilian goods and keep an eye on the news."
	icon = 'icons/obj/machines/ludkamachines.dmi'
	icon_state = "ludkaterminal_off"
	var/busy = FALSE
	var/list/obj/effect/landmark/cargospawn/drop_pads = list()
	var/list/shop_entries = list()
	var/list/shop_categories = list()
	var/current_shop_category = ""

/obj/machinery/pulse_terminal/ludka/update_icon()
	if(stat & BROKEN)
		icon_state = "ludkaterminal_off"
		return
	icon_state = "ludkaterminal"

/obj/machinery/pulse_terminal/ludka/proc/update_drop_pads()
	drop_pads = list()
	for(var/pad in world)
		if(istype(pad, /obj/effect/landmark/cargospawn))
			drop_pads += pad

/obj/machinery/pulse_terminal/ludka/Initialize()
	update_drop_pads()
	addtimer(CALLBACK(src, .proc/update_drop_pads), 1 SECONDS)
	add_shop_entry("Barbed Wire", 10, /obj/item/stack/barbwire, "Supplies")
	add_shop_entry("50 Glass Sheets", 15, /obj/item/stack/material/glass/fifty, "Supplies")
	add_shop_entry("50 Cloth", 20, /obj/item/stack/material/cloth/fifty, "Supplies")
	add_shop_entry("50 Metal Sheets", 25, /obj/item/stack/material/steel/fifty, "Supplies")
	add_shop_entry("10 Plasteel", 50, /obj/item/stack/material/plasteel/ten, "Supplies")
	add_shop_entry("10 Gold", 200, /obj/item/stack/material/gold/ten, "Supplies")
	add_shop_entry("10 Diamonds", 400, /obj/item/stack/material/diamond/ten, "Supplies")
	add_shop_entry("Ifak Kit", 10, /obj/item/storage/box/ifak, "Medical")
	add_shop_entry("Advanced First-Aid Kit", 19, /obj/item/storage/firstaid/adv, "Medical")
	add_shop_entry("Surgery Kit", 25, /obj/item/storage/firstaid/surgery, "Medical")
	add_shop_entry("Medical Belt", 30, /obj/item/storage/belt/medical/full, "Medical")
	add_shop_entry("Egg Box", 25, /obj/item/storage/fancy/egg_box, "Food")
	add_shop_entry("Cheap Amasec", 3, /obj/item/reagent_containers/food/drinks/bottle/amasecpoor, "Food")
	add_shop_entry("Expensive Amasec", 8, /obj/item/reagent_containers/food/drinks/bottle/amasecexpensive, "Food")
	add_shop_entry("Gas Mask", 12, /obj/item/clothing/mask/gas/security, "Clothing")
	add_shop_entry("Webbing", 12, /obj/item/clothing/accessory/storage/webbing, "Clothing")
	add_shop_entry("Holster", 12, /obj/item/clothing/accessory/holster/waist, "Clothing")
	add_shop_entry("Satchel", 12, /obj/item/storage/backpack/satchel/warfare, "Clothing")
	add_shop_entry("Zippo Lighter", 3, /obj/item/flame/lighter/zippo, "Misc")
	add_shop_entry("Shovel", 5, /obj/item/shovel, "Misc")
	add_shop_entry("Cigarette Crate", 10, /obj/item/storage/fancy/cigarettes/dromedaryco, "Misc")
	add_shop_entry("Mining Crate", 10, /obj/structure/closet/crate/miningcrate, "Misc")

/obj/machinery/pulse_terminal/ludka/proc/add_shop_entry(var/ename, var/ecost, var/item_path, var/ecategory)
	var/datum/shop_entry/E = new()
	E.name = ename
	E.cost = ecost
	E.item_path = item_path
	E.category = ecategory
	shop_entries += E
	if(!(ecategory in shop_categories))
		shop_categories += ecategory

/obj/machinery/pulse_terminal/ludka/get_extra_menu_links()
	return "<BR><A href='?src=\ref[src];shop=1'>Shop</A> - order civilian goods"

/obj/machinery/pulse_terminal/ludka/get_extra_screen()
	var/dat = ""
	switch(screen)
		if(5)
			dat += "<B>Shop</B> - civilian goods.<HR>"
			dat += "<I>Orders are delivered to the tradezone drop pads.</I><BR><BR>"
			for(var/cat in shop_categories)
				dat += "<A href='?src=\ref[src];cat=[url_encode(cat)]'>[cat]</A><BR>"
			dat += "<HR><A href='?src=\ref[src];setScreen=[0]'>Back</A>"
		if(6)
			if(current_shop_category)
				dat += "<B>Shop</B> - [current_shop_category]<HR>"
				for(var/datum/shop_entry/E in shop_entries)
					if(E.category == current_shop_category)
						var/etotal = E.cost + round(E.cost * GLOB.tax_rate, 1)
						dat += "<A href='?src=\ref[src];buy=\ref[E]'>[E.name] - [etotal] thrones</A><BR>"
				dat += "<HR><A href='?src=\ref[src];shop=1'>Categories</A> / <A href='?src=\ref[src];setScreen=[0]'>Back</A>"
			else
				screen = 5
		else
			screen = 0
	return dat

/obj/machinery/pulse_terminal/ludka/handle_extra_topic(var/obj/item/card/id/C, var/list/href_list)
	if(href_list["shop"])
		screen = 5
		current_shop_category = ""
	else if(href_list["cat"])
		var/catname = href_list["cat"]
		if(catname in shop_categories)
			current_shop_category = catname
			screen = 6
	else if(href_list["buy"])
		if(C && current_shop_category)
			var/datum/shop_entry/E = locate(href_list["buy"])
			if(istype(E) && (E in shop_entries))
				E.purchase(src, usr, C)