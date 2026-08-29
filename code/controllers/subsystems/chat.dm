SUBSYSTEM_DEF(chat)
	name = "Chat"
	flags = SS_TICKER | SS_NO_INIT
	wait = 1
	priority = SS_PRIORITY_CHAT
	init_order = INIT_ORDER_CHAT

	var/list/payload = list()


/datum/controller/subsystem/chat/fire()
	for(var/i in payload)
		var/client/C = i
		var/list/messages = payload[C]
		payload -= C
		if(istype(messages))
			for(var/message in messages)
				C << output(message, "browseroutput:output")
		else if(messages)
			C << output(messages, "browseroutput:output")

		if(MC_TICK_CHECK)
			return


/datum/controller/subsystem/chat/proc/queue(target, message, handle_whitespace = TRUE)
	if(!target || !message)
		return

	if(!istext(message))
		crash_with("to_chat called with invalid input type")
		return

	if(target == world)
		target = GLOB.clients

	//Some macros remain in the string even after parsing and fuck up the eventual output
	message = replacetext(message, "\improper", "")
	message = replacetext(message, "\proper", "")
	if(handle_whitespace)
		message = replacetext(message, "\n", "<br>")
		message = replacetext(message, "\t", "[FOURSPACES][FOURSPACES]")
	message += "<br>"


	//url_encode it TWICE, this way any UTF-8 characters are able to be decoded by the Javascript.
	//Do the double-encoding here to save nanoseconds
	var/twiceEncoded = url_encode(url_encode(message))

	if(islist(target))
		for(var/I in target)
			queue_client(CLIENT_FROM_VAR(I), message, twiceEncoded)

	else
		queue_client(CLIENT_FROM_VAR(target), message, twiceEncoded)

/datum/controller/subsystem/chat/proc/queue_client(client/C, message, twiceEncoded)
	if(!C)
		return

	// Always write to the legacy output so a goonchat failure still shows text.
	C << message

	if(!C.chatOutput || C.chatOutput.broken)
		return

	if(!C.chatOutput.loaded)
		if(C.chatOutput.messageQueue)
			C.chatOutput.messageQueue += message
		return

	LAZYINITLIST(payload[C])
	payload[C] += twiceEncoded