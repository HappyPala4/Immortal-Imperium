/client/proc/change_daytime()
	set category = "Debug"
	set name = "Change current daytime"
	set desc = ""
	var/dayparts = SSdaynight.get_dayparts()
	var/input = input(usr, "Change daytime", "Daytime change", null) in dayparts
	if(!input)
		return
	SSdaynight.change_daytime(dayparts[input])