/client/verb/ooc(message as text)
	set name = "OOC"
	set category = "OOC"

	sanitize_and_communicate(/decl/communication_channel/ooc, src, message)

/client/verb/looc(message as text)
	set name = "LOOC"
	set desc = "Local OOC, seen only by those in view. Remember: Just because you see someone that doesn't mean they see you."
	set category = "OOC"

	sanitize_and_communicate(/decl/communication_channel/ooc/looc, src, message)

/client/verb/fix_chat()
	set name = "Fix chat"
	set category = "OOC"

	to_chat(src, "<span class='danger'>Reloading chat, please wait...</span>")
	log_game("GOONCHAT: [key_name(src)] used Fix chat")

	if(!chatOutput || !istype(chatOutput))
		chatOutput = new /datum/chatOutput(src)

	chatOutput.broken = FALSE
	chatOutput.loaded = FALSE
	chatOutput.loadAttempts = 0
	if(!chatOutput.messageQueue)
		chatOutput.messageQueue = list()
	chatOutput.showLegacyChat()
	chatOutput.start()

	spawn(5 SECONDS)
		if(QDELETED(src) || QDELETED(chatOutput))
			return
		if(chatOutput.loaded && !chatOutput.broken)
			to_chat(src, "<span class='notice'>Fancy chat reloaded.</span>")
			return
		var/action = alert(src, "Chat is still not loading. Keep waiting, or switch to the old chat window?", "Fix chat", "Wait", "Switch to old chat")
		if(QDELETED(src) || QDELETED(chatOutput))
			return
		if(action == "Switch to old chat")
			chatOutput.failChat()
		else if(!chatOutput.loaded)
			chatOutput.load()

/mob/living/verb/toggleMusic()
	set name = "Toggle Music"
	set desc = "Allows you to toggle ambient music."
	set category = "OOC"

	if(src.music_on == 1)
		src.music_on = 0
		to_chat(src, "Ambient music disabled.")
		src.change_current_ambience(null)
	else
		src.music_on = 1
		to_chat(src, "Ambient music enabled.")


/client/verb/playedTime()
	set name = "View Played Time"
	set desc = "See how long you've played!"
	set category = "OOC"

	establish_db_connection()
	if(!dbcon.IsConnected())
		to_chat(src, "DB connection failed! Tell an admeme!")
		return

	var/DBQuery/query = dbcon.NewQuery("SELECT time_living FROM playtime_history WHERE ckey='[src.ckey]'")
	query.Execute()
	while(query.NextRow())
		var/playedTime = query.item[1]
		playedTime = text2num(playedTime)
		playedTime = playedTime/60
		to_chat(src, "[playedTime] hours played")
		break