/* Mining sorting and payout machines. */

/datum/mining_machine_account
	var/obj/item/card/id/card
	var/balance = 0

/datum/mining_machine_account/New(var/obj/item/card/id/new_card)
	card = new_card

/datum/mining_machine_payout
	var/item_type
	var/item_name
	var/icon_data
	var/required_amount = 0
	var/price = 0
	var/paid_amount = 0

/datum/mining_machine_payout/New(var/new_item_type, var/obj/item/source_item, var/new_required_amount, var/new_price)
	item_type = new_item_type
	item_name = source_item.name
	var/icon/item_icon = icon(source_item.icon, source_item.icon_state)
	icon_data = icon2base64(item_icon, "mining_vendor_[new_item_type]")
	required_amount = new_required_amount
	price = new_price

/obj/machinery/mining_machine/filter
	name = "ore sorting filter"
	desc = "Sorts individual ore and ingot pieces on a conveyor."
	icon = 'icons/obj/machines/mining_machines.dmi'
	icon_state = "stacker"
	opacity = TRUE
	density = TRUE
	anchored = 1
	req_access = list(access_mechanicus)

	var/obj/machinery/mineral/input/input_area
	var/obj/machinery/mineral/output/accepted_output
	var/obj/machinery/mineral/output/rejected_output
	var/vendor_id = ""
	var/reader_id = ""
	var/obj/machinery/mining_machine/vendor/linked_vendor
	var/obj/machinery/mining_machine/card_reader/linked_reader

/obj/machinery/mining_machine/filter/Initialize()
	. = ..()
	spawn(5)
		resolve_links()

/obj/machinery/mining_machine/filter/proc/resolve_links()
	for(var/dir in GLOB.cardinal)
		var/obj/machinery/mineral/input/input_candidate = locate(/obj/machinery/mineral/input, get_step(src, dir))
		if(input_candidate)
			input_area = input_candidate
			break
	for(var/dir in GLOB.cardinal)
		for(var/obj/machinery/mineral/output/output_candidate in get_step(src, dir))
			if(istype(output_candidate, /obj/machinery/mineral/output/rejected))
				rejected_output = output_candidate
			else
				accepted_output = output_candidate

	if(vendor_id)
		for(var/obj/machinery/mining_machine/vendor/V in world)
			if(V.machine_id == vendor_id)
				linked_vendor = V
				break
	if(reader_id)
		for(var/obj/machinery/mining_machine/card_reader/R in world)
			if(R.machine_id == reader_id)
				linked_reader = R
				R.linked_filter = src
				break

/obj/machinery/mining_machine/filter/proc/register_card(var/obj/item/card/id/card)
	if(linked_vendor && card)
		linked_vendor.register_card(card)

/obj/machinery/mining_machine/filter/Process()
	if(!input_area || (!accepted_output && !rejected_output))
		return
	var/turf/input_turf = input_area.loc

	for(var/atom/movable/A in input_turf.contents)
		if(A == src)
			continue
		if(ismob(A))
			if(rejected_output)
				A.forceMove(get_turf(rejected_output))
			continue
		if(!istype(A, /obj/item))
			continue
		var/obj/item/I = A

		var/is_valid = linked_vendor && linked_vendor.can_accept_item(I.type)
		var/obj/machinery/mineral/output/target = is_valid ? accepted_output : rejected_output
		if(!target)
			continue

		if(is_valid)
			var/obj/item/card/id/card = linked_reader ? linked_reader.registered_card : null
			if(card)
				linked_vendor.credit_item(card, I.type)
			I.forceMove(get_turf(target))
		else
			I.forceMove(get_turf(target))

/obj/machinery/mining_machine/filter/attack_hand(mob/user)
	if(!allowed(user))
		to_chat(user, "Access denied.")
		return

	var/choice = input(user, "Ore sorting filter", "Mining machine") as null|anything in list("Set payout vendor", "Set card reader", "Clear links")
	if(!choice)
		return
	if(choice == "Clear links")
		linked_vendor = null
		linked_reader = null
		vendor_id = ""
		reader_id = ""
		return
	if(choice == "Set payout vendor")
		var/list/vendors = list()
		for(var/obj/machinery/mining_machine/vendor/V in world)
			vendors[V.name] = V
		var/obj/machinery/mining_machine/vendor/selected_vendor = input(user, "Choose payout vendor", "Mining machine") as null|anything in vendors
		if(selected_vendor)
			linked_vendor = selected_vendor
			vendor_id = selected_vendor.machine_id
		return
	if(choice == "Set card reader")
		var/list/readers = list()
		for(var/obj/machinery/mining_machine/card_reader/R in world)
			readers[R.name] = R
		var/obj/machinery/mining_machine/card_reader/selected_reader = input(user, "Choose card reader", "Mining machine") as null|anything in readers
		if(selected_reader)
			linked_reader = selected_reader
			selected_reader.linked_filter = src
			reader_id = selected_reader.machine_id
		return

/obj/machinery/mining_machine/card_reader
	name = "mining card reader"
	desc = "Registers the miner who will receive payments."
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "id_swap"
	density = 1
	anchored = 1
	req_access = list(access_mechanicus)
	var/machine_id = ""
	var/obj/item/card/id/registered_card
	var/obj/machinery/mining_machine/filter/linked_filter

/obj/machinery/mining_machine/card_reader/attackby(obj/item/W, mob/user)
	var/obj/item/card/id/card = W.GetIdCard()
	if(card)
		registered_card = card
		if(linked_filter)
			linked_filter.register_card(card)
		to_chat(user, "The card reader registers [card].")
		return
	..()

/obj/machinery/mining_machine/vendor
	name = "mining payout vendor"
	desc = "Stores mining funds and pays registered miners."
	icon = 'icons/obj/vending.dmi'
	icon_state = "generic"
	density = 1
	anchored = 1
	opacity = 1
	req_access = list(access_mechanicus)
	var/machine_id = ""
	var/internal_funds = 50
	var/list/payouts = list()
	var/list/registered_accounts = list()

/obj/machinery/mining_machine/vendor/New()
	. = ..()
	for(var/item_type in list(
		/obj/item/newore/ironore,
		/obj/item/newore/silverore,
		/obj/item/newore/goldore,
		/obj/item/newore/adamantiumore,
		/obj/item/newore/copperore,
		/obj/item/newore/coalore,
		/obj/item/newore/uraniumore,
		/obj/item/newore/phoronore,
		/obj/item/newore/coboltore,
		/obj/item/newore/kultriniumore,
		/obj/item/newore/diamantineore,
		/obj/item/ingots/ironingot,
		/obj/item/ingots/silveringot,
		/obj/item/ingots/goldingot,
		/obj/item/ingots/adamantiumingot,
		/obj/item/ingots/copperingot,
		/obj/item/ingots/steelingot,
		/obj/item/ingots/coboltingot,
		/obj/item/ingots/kultriniumingot))
		var/obj/item/item = new item_type(src)
		payouts[item_type] = new/datum/mining_machine_payout(item_type, item, 0, 0)
		qdel(item)

/obj/machinery/mining_machine/vendor/proc/get_account(var/obj/item/card/id/card, var/create = FALSE)
	if(!card)
		return null
	var/datum/mining_machine_account/account = registered_accounts[card]
	if(!account && create)
		account = new(card)
		registered_accounts[card] = account
	return account

/obj/machinery/mining_machine/vendor/proc/register_card(var/obj/item/card/id/card)
	get_account(card, TRUE)

/obj/machinery/mining_machine/vendor/proc/get_payout(var/item_type)
	return payouts[item_type]

/obj/machinery/mining_machine/vendor/proc/can_accept_item(var/item_type)
	var/datum/mining_machine_payout/payout = get_payout(item_type)
	if(!payout || payout.required_amount <= 0)
		return FALSE
	if(payout.paid_amount >= payout.required_amount)
		return FALSE
	return internal_funds >= payout.price

/obj/machinery/mining_machine/vendor/proc/credit_item(var/obj/item/card/id/card, var/item_type)
	var/datum/mining_machine_payout/payout = get_payout(item_type)
	var/datum/mining_machine_account/account = get_account(card, TRUE)
	if(!payout || !account)
		return FALSE
	if(!can_accept_item(item_type))
		return FALSE
	internal_funds -= payout.price
	account.balance += payout.price
	payout.paid_amount++
	return TRUE

/obj/machinery/mining_machine/vendor/proc/withdraw_funds(var/mob/user, var/amount)
	if(!allowed(user))
		return
	amount = max(0, min(round(amount), internal_funds))
	if(!amount)
		return
	internal_funds -= amount
	dispense_funds(user, amount)
	SSnanoui.update_uis(src)

/obj/machinery/mining_machine/vendor/proc/dispense_funds(var/mob/user, var/amount)
	while(amount >= 10)
		var/obj/item/stack/thrones/throne_coins = new(get_turf(user))
		throne_coins.amount = min(20, round(amount / 10))
		throne_coins.update_icon()
		amount -= throne_coins.amount * 10
	while(amount >= 5)
		var/obj/item/stack/thrones2/silver_reales = new(get_turf(user))
		silver_reales.amount = min(20, round(amount / 5))
		silver_reales.update_icon()
		amount -= silver_reales.amount * 5
	if(amount)
		var/obj/item/stack/thrones3/copper_reales = new(get_turf(user))
		copper_reales.amount = amount
		copper_reales.update_icon()

/obj/machinery/mining_machine/vendor/attackby(obj/item/W, mob/user)
	var/obj/item/card/id/card = W.GetIdCard()
	if(card)
		var/datum/mining_machine_account/account = get_account(card)
		if(account && account.balance > 0)
			var/amount = min(account.balance, internal_funds)
			if(amount)
				account.balance -= amount
				internal_funds -= amount
				dispense_funds(user, amount)
		SSnanoui.update_uis(src)
		return
	if(istype(W, /obj/item/stack/thrones) || istype(W, /obj/item/stack/thrones2) || istype(W, /obj/item/stack/thrones3))
		var/obj/item/stack/thrones/cash = W
		var/amount = cash.amount * 10
		if(istype(W, /obj/item/stack/thrones2))
			amount = cash.amount * 5
		else if(istype(W, /obj/item/stack/thrones3))
			amount = cash.amount
		internal_funds += amount
		user.drop_from_inventory(cash)
		qdel(cash)
		to_chat(user, "You load [amount] Thrones into the vendor.")
		SSnanoui.update_uis(src)
		return
	if(allowed(user) && istype(W, /obj/item))
		if(!get_payout(W.type))
			payouts[W.type] = new/datum/mining_machine_payout(W.type, W, 0, 0)
		SSnanoui.update_uis(src)
		return
	..()

/obj/machinery/mining_machine/vendor/attack_hand(mob/user)
	ui_interact(user)

/obj/machinery/mining_machine/vendor/ui_interact(mob/user, ui_key = "main", var/datum/nanoui/ui = null, var/force_open = 1)
	user.set_machine(src)
	var/list/data = list()
	var/obj/item/card/id/card = user.GetIdCard()
	var/datum/mining_machine_account/account = get_account(card)
	data["vendor_funds"] = internal_funds
	data["personal_balance"] = account ? account.balance : 0
	data["can_configure"] = allowed(user)
	var/list/items = list()
	for(var/item_type in payouts)
		var/datum/mining_machine_payout/payout = payouts[item_type]
		if(!data["can_configure"] && payout.price <= 0)
			continue
		items += list(list(
			"name" = payout.item_name,
			"icon" = payout.icon_data,
			"price" = payout.price,
			"remaining" = max(0, payout.required_amount - payout.paid_amount),
			"unlimited" = FALSE,
			"paid" = payout.paid_amount,
			"quota" = payout.required_amount,
			"item_key" = "[item_type]"))
	data["items"] = items
	ui = SSnanoui.try_update_ui(user, src, ui_key, ui, data, force_open)
	if(!ui)
		ui = new(user, src, ui_key, "mining_payout_vendor.tmpl", src.name, 820, 600)
		ui.set_initial_data(data)
		ui.open()

/obj/machinery/mining_machine/vendor/Topic(href, href_list)
	if(..())
		return
	if(!allowed(usr))
		return
	if(href_list["withdraw"])
		withdraw_funds(usr, input(usr, "Amount of Thrones to withdraw", "Mining machine", internal_funds) as num)
		SSnanoui.update_uis(src)
		return
	var/item_type = text2path(href_list["item"])
	var/datum/mining_machine_payout/payout = get_payout(item_type)
	if(!payout)
		return
	if(href_list["remove_item"])
		payouts -= item_type
	else if(href_list["set_quota"])
		payout.required_amount = max(0, round(input(usr, "Required amount for [payout.item_name] (0 disables payment)", "Mining machine", payout.required_amount) as num))
	else if(href_list["quota_up"])
		payout.required_amount++
	else if(href_list["quota_down"])
		payout.required_amount = max(0, payout.required_amount - 1)
	else if(href_list["set_price"])
		payout.price = max(0, round(input(usr, "Payment per [payout.item_name]", "Mining machine", payout.price) as num))
	SSnanoui.update_uis(src)