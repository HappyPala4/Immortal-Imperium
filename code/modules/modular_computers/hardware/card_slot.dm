/obj/item/computer_hardware/card_slot
	name = "RFID card slot"
	desc = "Slot that allows this computer to write data on RFID cards. Necessary for some programs to run properly."
	power_usage = 10 //W
	critical = 0
	icon_state = "cardreader"
	hardware_size = 1
	origin_tech = list(TECH_DATA = 2)

	var/obj/item/card/id/stored_card = null

// Second reader used by ID modification consoles. Holds the authorized ID, not the card being written.
/obj/item/computer_hardware/card_slot/authorized
	name = "RFID authorization slot"
	desc = "Slot that reads an authorized identification card. Used together with a card writer to modify other IDs."

/obj/item/computer_hardware/card_slot/Destroy()
	if(holder2)
		if(holder2.card_slot == src)
			holder2.card_slot = null
		if(holder2.card_slot2 == src)
			holder2.card_slot2 = null
	if(stored_card)
		stored_card.forceMove(get_turf(holder2))
	holder2 = null
	return ..()