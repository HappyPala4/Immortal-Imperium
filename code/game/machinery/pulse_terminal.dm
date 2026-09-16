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
	desc = "РџСЂРѕСЃС‚РѕР№ РѕР±С‰РµСЃС‚РІРµРЅРЅС‹Р№ РєРѕРіРёС‚Р°С‚РѕСЂ. Р“РѕСЂРѕР¶Р°РЅРµ РјРѕРіСѓС‚ С‡РёС‚Р°С‚СЊ РЅРѕРІРѕСЃС‚Рё РёР»Рё РїРµСЂРµРїРёСЃС‹РІР°С‚СЃСЏ РІ РІРµС‚РєР°С… РЅР° С„РѕСЂРѕРјРµ РџСѓР»СЊСЃ. Р’С‹СЃРѕРєРѕРїРѕСЃС‚Р°РІР»РµРЅРЅС‹Рµ С‡РёРЅС‹ РјРѕРіСѓС‚ РїРёСЃР°С‚СЊ РЅРѕРІРѕСЃС‚Рё С‡РµСЂРµР· СЌС‚РѕС‚ С‚РµСЂРјРёРЅР°Р»."
	icon = 'icons/obj/machines/ludkamachines.dmi'
	icon_state = "baseterminal_off"
	anchored = 1
	density = 1
	use_power = 0
	layer = ABOVE_WINDOW_LAYER
	var/logged_name = ""	//Nickname used when posting
	var/icon_off_state = "baseterminal_off"
	var/screen = 0			//0 main, 1 news, 2 threads, 3 thread view, 4 account, 7 exchange, 8 position, 9 mfo, 10 treasury
	var/datum/feed_channel/viewing_channel = null
	var/datum/market_position/viewing_position = null
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
				dat += "<BR><BR><B>Finance:</B><BR>"
				dat += "<A href='?src=\ref[src];ex_main=1'>Birja</A> - exchange and futures<BR>"
				dat += "<A href='?src=\ref[src];mfo=1'>MFO</A> - loans and transfers<BR>"
				if(is_treasury_access(C))
					dat += "<A href='?src=\ref[src];treasury=1'>Kazna</A> - treasury<BR>"
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
			if(7)
				var/datum/market/M = get_market()
				var/ck = ckey(C.registered_name)
				var/dep = M.player_deposits[ck] || 0
				dat += "<B>Geliak Exchange</B> - exchange<HR>"
				dat += "Card: <FONT COLOR='green'>[C.money]</FONT> | Deposit: <FONT COLOR='green'>[dep]</FONT> thrones<BR>"
				dat += "<A href='?src=\ref[src];ex_dep=1'>Deposit</A> | "
				dat += "<A href='?src=\ref[src];ex_wd=1'>Withdraw</A><HR>"
				dat += "<B>Positions:</B><BR>"
				for(var/datum/market_position/P in M.positions)
					dat += "<A href='?src=\ref[src];ex_pos=\ref[P]'><B>[P.ticker]</B> [P.name]</A> - [P.current_price()] thrones<BR>"
				dat += "<HR><B>My Trades:</B><BR>"
				var/has_trades = FALSE
				for(var/datum/market_trade/T in M.trades)
					if(T.ckey == ck)
						has_trades = TRUE
						var/profit = round(T.quantity * (T.position.current_price() - T.entry_price))
						var/pcol = profit >= 0 ? "green" : "red"
						dat += "[T.position.ticker] | Entry:[T.entry_price] | Now:[T.position.current_price()] | [T.leverage]x | <font color='[pcol]'>[profit >= 0 ? "+" : ""][profit]</font>"
						dat += " <A href='?src=\ref[src];ex_close=\ref[T]'>Close</A><BR>"
				if(!has_trades)
					dat += "<I>None.</I><BR>"
				dat += "<HR><A href='?src=\ref[src];setScreen=[0]'>Back</A>"
			if(8)
				if(viewing_position)
					var/datum/market_position/P = viewing_position
					var/datum/market/M = get_market()
					var/ck = ckey(C.registered_name)
					var/dep = M.player_deposits[ck] || 0
					dat += "<B>[P.name] ([P.ticker])</B><HR>"
					var/pcol = P.trend_color()
					dat += "Price: <FONT COLOR='[pcol]'>[P.current_price()]</FONT> thrones/future<BR>"
					dat += "Points: [P.current_points] / Initial: [P.initial_points]<BR>"
					var/tdir = "Flat"
					var/tcol = "#888888"
					if(P.trend > 0)
						tdir = "Up"
						tcol = "#00cc00"
					else if(P.trend < 0)
						tdir = "Down"
						tcol = "#cc0000"
					dat += "Trend: <FONT COLOR='[tcol]'>[tdir]</FONT> | Momentum: [P.instability + 15]% move chance<BR>"
					dat += P.chart_html()
					dat += "<HR><B>Buy Futures (deposit: [dep] thrones):</B><BR>"
					dat += "<A href='?src=\ref[src];ex_buy=\ref[P]'>Open Position</A><BR>"
					dat += "<HR><A href='?src=\ref[src];setScreen=[7]'>Back</A>"
				else
					screen = 7
			if(9)
				var/datum/market/M = get_market()
				var/ck = ckey(C.registered_name)
				var/debt = 0
				for(var/datum/market_loan/LL in M.loans)
					if(LL.ckey == ck && !LL.repaid)
						debt += LL.total_owed
				var/blocked = (ck in M.blocked_accounts)
				dat += "<B>MFO</B> - microfinance<HR>"
				if(blocked)
					dat += "<FONT COLOR='red'><B>ACCOUNT BLOCKED.</B></FONT> Repay your overdue loan to unlock.<BR><HR>"
				dat += "<B>Take a Loan:</B><BR>"
				dat += "<A href='?src=\ref[src];loan_term=5'>5 min (5%)</A> | "
				dat += "<A href='?src=\ref[src];loan_term=10'>10 min (7%)</A> | "
				dat += "<A href='?src=\ref[src];loan_term=20'>20 min (12%)</A><BR>"
				dat += "Total debt: <FONT COLOR='red'>[debt]</FONT> / 500 thrones<BR><HR>"
				dat += "<B>My Loans:</B><BR>"
				var/has_loans = FALSE
				for(var/datum/market_loan/L in M.loans)
					if(L.ckey == ck && !L.repaid)
						has_loans = TRUE
						if(L.expired)
							var/blk_status = (ck in M.blocked_accounts) ? "<font color='maroon'><B>BLOCKED</B></font>" : "<font color='red'>BLOCKING SOON</font>"
							dat += "[L.amount] thrones | [L.interest_rate*100]% | [blk_status]"
						else
							var/mins_left = round((L.borrowed_time + L.term_minutes MINUTES - world.time) / 600)
							dat += "[L.amount] thrones | [L.interest_rate*100]% | [max(mins_left, 0)] min left"
						dat += " <A href='?src=\ref[src];repay_loan=\ref[L]'>Repay [L.total_owed]</A><BR>"
				if(!has_loans)
					dat += "<I>No active loans.</I><BR>"
				dat += "<HR><B>Transfer to Player:</B><BR>"
				dat += "<A href='?src=\ref[src];transfer=1'>Send thrones to another player</A><BR>"
				dat += "<HR><A href='?src=\ref[src];setScreen=[0]'>Back</A>"
			if(10)
				if(is_treasury_access(C))
					var/datum/market/M = get_market()
					dat += "<B>Kazna</B> - treasury<HR>"
					dat += "Balance: <FONT COLOR='green'>[M.treasury]</FONT> thrones<BR><HR>"
					dat += "<B>Recent Income:</B><BR>"
					if(!M.treasury_log.len)
						dat += "<I>No transactions.</I><BR>"
					else
						var/start = max(1, M.treasury_log.len - 19)
						for(var/i = start to M.treasury_log.len)
							dat += "[M.treasury_log[i]]<BR>"
					dat += "<HR><A href='?src=\ref[src];treasury_wd=1'>Withdraw to Card</A><BR>"
					dat += "<A href='?src=\ref[src];setScreen=[0]'>Back</A>"
				else
					dat += "<I>Access denied. Governor or Heir ID required.</I><BR>"
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
		icon_state = icon_off_state
		close_browser(usr, "window=pulse_terminal")
		return
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
	else if(href_list["ex_main"])
		screen = 7
	else if(href_list["mfo"])
		screen = 9
	else if(href_list["treasury"])
		screen = 10
	else if(href_list["ex_dep"])
		if(C)
			var/datum/market/M = get_market()
			var/ck = ckey(C.registered_name)
			if(ck in M.blocked_accounts)
				to_chat(usr, "<span class='warning'>Your account is blocked. Repay your overdue loan first.</span>")
				return
			var/dep = round(input(usr, "How many thrones to deposit to the exchange?", "Birja", "") as null|num)
			if(dep && dep > 0 && dep <= C.money)
				C.money -= dep
				M.player_deposits[ck] = (M.player_deposits[ck] || 0) + dep
				to_chat(usr, "<span class='notice'>[dep] thrones deposited to the exchange.</span>")
			else
				to_chat(usr, "<span class='warning'>Invalid deposit amount.</span>")
	else if(href_list["ex_wd"])
		if(C)
			var/datum/market/M = get_market()
			var/ck = ckey(C.registered_name)
			if(ck in M.blocked_accounts)
				to_chat(usr, "<span class='warning'>Your account is blocked. Repay your overdue loan first.</span>")
				return
			var/avail = M.player_deposits[ck] || 0
			var/wd = round(input(usr, "How many thrones to withdraw? (available: [avail])", "Birja", "") as null|num)
			if(wd && wd > 0 && wd <= avail)
				M.player_deposits[ck] -= wd
				var/wtax = round(wd * M.withdraw_tax)
				C.money += wd - wtax
				if(wtax > 0)
					M.treasury += wtax
					M.treasury_log += "[logged_name]: Birja withdraw tax [wtax]"
				to_chat(usr, "<span class='notice'>[wd - wtax] thrones withdrawn from the exchange ([wtax] tax to the treasury).</span>")
			else
				to_chat(usr, "<span class='warning'>Invalid withdrawal amount.</span>")
	else if(href_list["ex_pos"])
		var/datum/market_position/P = locate(href_list["ex_pos"])
		if(istype(P))
			viewing_position = P
			screen = 8
	else if(href_list["ex_buy"])
		var/datum/market_position/P = locate(href_list["ex_buy"])
		if(istype(P) && C)
			var/datum/market/M = get_market()
			var/ck = ckey(C.registered_name)
			if(ck in M.blocked_accounts)
				to_chat(usr, "<span class='warning'>Your account is blocked. Repay your overdue loan first.</span>")
				return
			var/avail = M.player_deposits[ck] || 0
			var/dep = round(input(usr, "Deposit (max [avail] thrones):", "Buy Futures", "") as null|num)
			if(!dep || dep <= 0 || dep > avail)
				to_chat(usr, "<span class='warning'>Invalid deposit amount.</span>")
				return
			var/lev = round(input(usr, "Leverage (1-10):", "Buy Futures", "") as null|num)
			if(!lev || lev < 1)
				lev = 1
			if(lev > 10)
				lev = 10
			var/notional = dep * lev
			var/price = P.current_price()
			var/qty = notional / price
			M.player_deposits[ck] -= dep
			var/datum/market_trade/T = new()
			T.trader_name = logged_name
			T.ckey = ck
			T.position = P
			T.deposit = dep
			T.leverage = lev
			T.entry_price = price
			T.quantity = qty
			M.trades += T
			P.buys_this_period++
			P.buy_volume_this_period += notional
			to_chat(usr, "<span class='notice'>Opened [P.name] position: [round(qty, 0.01)] futures at [price] thrones with [lev]x leverage.</span>")
	else if(href_list["ex_close"])
		var/datum/market_trade/T = locate(href_list["ex_close"])
		if(istype(T) && C)
			var/datum/market/M = get_market()
			var/datum/market_position/P = T.position
			var/current = P.current_price()
			var/notional = T.deposit * T.leverage
			var/value = T.quantity * current
			var/equity = T.deposit + (value - notional)
			var/commission = 0
			var/payout = 0
			if(equity > 0)
				var/gain = value - notional
				if(gain > 0)
					commission = round(gain * 0.04)
					if(commission > equity)
						commission = equity
				payout = max(0, round(equity - commission))
			M.player_deposits[T.ckey] = (M.player_deposits[T.ckey] || 0) + payout
			if(commission > 0)
				M.treasury += commission
				M.treasury_log += "[logged_name]: [P.ticker] deal commission [commission]"
			P.sells_this_period++
			P.sell_volume_this_period += value
			M.trades -= T
			qdel(T)
			to_chat(usr, "<span class='notice'>Position closed. Payout: [payout] thrones. Commission: [commission].</span>")
	else if(href_list["loan_term"])
		if(C)
			var/term = text2num(href_list["loan_term"])
			var/rate = 0
			if(term == 5)
				rate = 0.05
			else if(term == 10)
				rate = 0.07
			else if(term == 20)
				rate = 0.12
			var/amt = round(input(usr, "Loan amount:", "MFO", "") as null|num)
			if(amt && amt > 0)
				var/datum/market/M = get_market()
				var/ck = ckey(C.registered_name)
				if(ck in M.blocked_accounts)
					to_chat(usr, "<span class='warning'>Your account is blocked. Repay your overdue loan first.</span>")
					return
				var/debt = 0
				for(var/datum/market_loan/EX in M.loans)
					if(EX.ckey == ck && !EX.repaid)
						debt += EX.total_owed
				if(debt + amt > 500)
					to_chat(usr, "<span class='warning'>Loan limit exceeded. Max total debt is 500 thrones (current: [debt]).</span>")
					return
				var/datum/market_loan/L = new()
				L.borrower_name = logged_name
				L.ckey = ck
				L.amount = amt
				L.interest_rate = rate
				L.term_minutes = term
				L.borrowed_time = world.time
				L.total_owed = round(amt * (1 + rate))
				M.loans += L
				C.money += amt
				to_chat(usr, "<span class='notice'>Loan of [amt] thrones received. Repay [L.total_owed] within [term] minutes.</span>")
			else
				to_chat(usr, "<span class='warning'>Invalid loan amount.</span>")
	else if(href_list["repay_loan"])
		var/datum/market_loan/L = locate(href_list["repay_loan"])
		if(istype(L) && C)
			if(L.ckey != ckey(C.registered_name))
				to_chat(usr, "<span class='warning'>Not your loan.</span>")
				return
			if(C.money >= L.total_owed)
				C.money -= L.total_owed
				var/datum/market/M = get_market()
				var/interest = L.total_owed - L.amount
				M.treasury += interest
				M.treasury_log += "[logged_name]: loan interest [interest] ([L.interest_rate*100]%)"
				L.repaid = TRUE
				var/still_owes = FALSE
				for(var/datum/market_loan/OL in M.loans)
					if(OL.ckey == L.ckey && !OL.repaid)
						still_owes = TRUE
						break
				if(!still_owes)
					M.blocked_accounts -= L.ckey
				to_chat(usr, "<span class='notice'>Loan repaid. [interest] thrones of interest went to the treasury.</span>")
			else
				to_chat(usr, "<span class='warning'>Insufficient funds. Need [L.total_owed] thrones.</span>")
	else if(href_list["transfer"])
		if(C)
			var/target_name = input(usr, "Recipient's ID name (as shown on their card):", "Transfer", "") as null|text
			if(!target_name)
				return
			var/amt = round(input(usr, "Amount (available: [C.money]):", "Transfer", "") as null|num)
			if(!amt || amt <= 0 || amt > C.money)
				to_chat(usr, "<span class='warning'>Invalid transfer amount.</span>")
				return
			var/mob/living/carbon/human/target = null
			for(var/mob/living/carbon/human/H in world)
				var/obj/item/card/id/ID = H.get_active_hand()
				if(istype(ID) && ID.registered_name == target_name)
					target = H
					break
				if(H.wear_id)
					var/obj/item/card/id/worn = H.wear_id.GetIdCard()
					if(istype(worn) && worn.registered_name == target_name)
						target = H
						break
			if(target)
				var/obj/item/card/id/target_id = target.get_active_hand()
				if(!istype(target_id) && target.wear_id)
					target_id = target.wear_id.GetIdCard()
				if(istype(target_id))
					C.money -= amt
					target_id.money += amt
					to_chat(usr, "<span class='notice'>Sent [amt] thrones to [target_name].</span>")
					to_chat(target, "<span class='notice'>You received [amt] thrones via the terminal network.</span>")
				else
					to_chat(usr, "<span class='warning'>Recipient has no ID card.</span>")
			else
				to_chat(usr, "<span class='warning'>Nobody found with that ID name.</span>")
	else if(href_list["treasury_wd"])
		if(C && is_treasury_access(C))
			var/datum/market/M = get_market()
			var/wd = round(input(usr, "Withdraw from treasury (available: [M.treasury]):", "Kazna", "") as null|num)
			if(wd && wd > 0 && wd <= M.treasury)
				M.treasury -= wd
				C.money += wd
				M.treasury_log += "[logged_name]: withdrew [wd] thrones"
				to_chat(usr, "<span class='notice'>Withdrew [wd] thrones from the treasury.</span>")
			else
				to_chat(usr, "<span class='warning'>Invalid withdrawal amount.</span>")
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

/obj/machinery/pulse_terminal/proc/is_treasury_access(var/obj/item/card/id/C)
	if(!istype(C))
		return 0
	var/a = lowertext(C.assignment)
	if(findtext(a, "governor") || findtext(a, "heir"))
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
//############ EXCHANGE / MARKET ###############
//### Futures exchange on the terminal. Charts###
//### update every 5 min, price reacts to     ###
//### buy/sell pressure and instability.      ###
//### 4% of each deal profit goes to treasury.###
//##############################################

/var/global/datum/market/exchange = null

/proc/get_market()
	if(!exchange)
		exchange = new /datum/market()
	return exchange

/datum/market
	var/list/positions = list()
	var/list/trades = list()
	var/list/loans = list()
	var/list/player_deposits = list()
	var/list/blocked_accounts = list()	// ckeys blocked for overdue loans
	var/withdraw_tax = 0.05			// tax on exchange deposit withdrawals
	var/treasury = 0
	var/list/treasury_log = list()

/datum/market/New()
	initialize_positions()
	addtimer(CALLBACK(src, .proc/tick), 1 MINUTES)

/datum/market/proc/initialize_positions()
	var/datum/market_position/P
	P = new()
	P.name = "Promethium Gas"
	P.ticker = "PG"
	P.validity = 40
	P.initial_points = 100
	P.current_points = P.initial_points + rand(-15, 15)
	P.instability = 85
	P.vol_min = 5
	P.vol_max = 55
	positions += P

	P = new()
	P.name = "Promethium Raw"
	P.ticker = "PR"
	P.validity = 25
	P.initial_points = 80
	P.current_points = P.initial_points + rand(-10, 10)
	P.instability = 30
	P.vol_min = 2
	P.vol_max = 32
	positions += P

	P = new()
	P.name = "Gold"
	P.ticker = "Au"
	P.validity = 60
	P.initial_points = 120
	P.current_points = P.initial_points + rand(-20, 20)
	P.instability = 50
	P.vol_min = 3
	P.vol_max = 30
	positions += P

/datum/market/proc/tick()
	for(var/datum/market_position/P in positions)
		P.tick()
	for(var/datum/market_trade/T in trades)
		if(!T.position)
			trades -= T
			qdel(T)
			continue
		var/datum/market_position/pos = T.position
		var/ratio = pos.current_price() / T.entry_price
		if(ratio <= 1 - 1/T.leverage)
			trades -= T
			qdel(T)
			for(var/mob/M in world)
				if(M.ckey == T.ckey)
					to_chat(M, "<span class='danger'>Your [pos.ticker] trade was burned! Your deposit is lost.</span>")
					break
	for(var/datum/market_loan/L in loans)
		if(!L.repaid)
			if(!L.expired && world.time >= L.borrowed_time + (L.term_minutes MINUTES))
				L.expired = TRUE
			if(L.expired && !(L.ckey in blocked_accounts) && world.time >= L.borrowed_time + ((L.term_minutes + 5) MINUTES))
				blocked_accounts += L.ckey
				for(var/mob/M in world)
					if(M.ckey == L.ckey)
						to_chat(M, "<span class='danger'>Your account has been BLOCKED until you repay your overdue loan.</span>")
						break
	addtimer(CALLBACK(src, .proc/tick), 1 MINUTES)

/datum/market_position
	var/name = ""
	var/ticker = ""
	var/validity = 0
	var/initial_points = 0
	var/current_points = 0
	var/instability = 0
	var/vol_min = 0
	var/vol_max = 0
	var/list/candles = list()	// list of list(open, close, high, low)
	var/buys_this_period = 0
	var/sells_this_period = 0
	var/buy_volume_this_period = 0	// thrones of positions opened this period
	var/sell_volume_this_period = 0	// thrones of positions closed this period
	var/vol_base = 100				// reference volume for movement scaling
	var/trend = 0			// 1 = rising, -1 = falling, 0 = flat (momentum)

/datum/market_position/proc/current_price()
	return max(1, round(validity * current_points / initial_points))

/datum/market_position/proc/trend_color()
	if(candles.len >= 2)
		var/list/last = candles[candles.len]
		var/list/prev = candles[candles.len - 1]
		if(last[2] > prev[2])
			return "#00cc00"
		if(last[2] < prev[2])
			return "#cc0000"
	if(candles.len == 1)
		var/list/last = candles[1]
		if(last[2] > last[1])
			return "#00cc00"
		if(last[2] < last[1])
			return "#cc0000"
	return "#888888"

/datum/market_position/proc/tick()
	var/open = current_points
	var/net = buy_volume_this_period - sell_volume_this_period
	var/direction = 0
	if(net > 0)
		trend = 1
		direction = 1
	else if(net < 0)
		trend = -1
		direction = -1
	else if(trend != 0)
		direction = trend
	var/move_chance = instability
	if(trend != 0)
		move_chance += 15
	if(direction != 0 && prob(move_chance))
		var/delta = rand(vol_min, vol_max)
		var/net_abs = abs(net)
		if(net_abs > 0)
			var/scale = clamp(net_abs / vol_base, 0.25, 3)
			delta = max(1, round(delta * scale))
		current_points = clamp(current_points + direction * delta, max(1, round(initial_points / 5)), initial_points * 5)
	candles += list(list(open, current_points, max(open, current_points), min(open, current_points)))
	while(candles.len > 30)
		candles.Cut(1, 2)
	buys_this_period = 0
	sells_this_period = 0
	buy_volume_this_period = 0
	sell_volume_this_period = 0

/datum/market_position/proc/chart_html()
	if(!candles.len)
		return "<I>No data yet. Charts update every 1 minute.</I>"
	var/chart_h = 150
	var/candle_w = 12
	var/wick_w = 2
	var/body_w = 8
	var/p_min = 1e10
	var/p_max = -1e10
	for(var/list/c in candles)
		p_min = min(p_min, c[4])
		p_max = max(p_max, c[3])
	var/range = p_max - p_min
	if(range <= 0)
		range = 1
	var/max_y = chart_h - 4
	var/dat = "<table cellpadding='0' cellspacing='1' style='background:#1a1a1a; border:1px solid #444;'><tr>"
	for(var/list/c in candles)
		var/o = c[1]
		var/cl = c[2]
		var/h = c[3]
		var/l = c[4]
		var/h_y = clamp(round((1 - (h - p_min) / range) * max_y), 0, max_y)
		var/l_y = clamp(round((1 - (l - p_min) / range) * max_y), 0, max_y)
		var/o_y = clamp(round((1 - (o - p_min) / range) * max_y), 0, max_y)
		var/cl_y = clamp(round((1 - (cl - p_min) / range) * max_y), 0, max_y)
		var/btop = min(o_y, cl_y)
		var/bh = max(abs(o_y - cl_y), 2)
		var/wt = h_y
		var/wh = max(l_y - h_y, 1)
		var/col = "#888888"
		if(cl > o)
			col = "#00cc00"
		else if(cl < o)
			col = "#cc0000"
		var/wx = round((candle_w - wick_w) / 2)
		var/bx = round((candle_w - body_w) / 2)
		var/pct = (cl - o) / max(o, 1) * 100
		var/psign = pct > 0 ? "+" : ""
		var/tt = "[psign][round(pct, 1)]% ([o] -> [cl] pts)"
		dat += "<td style='width:[candle_w]px; height:[chart_h]px; position:relative; background:#111;' title='Change: [tt]'>"
		dat += "<div style='position:absolute; left:[wx]px; top:[wt]px; width:[wick_w]px; height:[wh]px; background:[col];'></div>"
		dat += "<div style='position:absolute; left:[bx]px; top:[btop]px; width:[body_w]px; height:[bh]px; background:[col];'></div>"
		dat += "</td>"
	dat += "</tr></table>"
	var/tcol = trend_color()
	dat += "<font size=1>Range: [p_min] - [p_max] | Current: <font color='[tcol]'>[current_points] pts</font> | Price: <font color='[tcol]'>[current_price()] thrones</font></font>"
	return dat

/datum/market_trade
	var/trader_name = ""
	var/ckey = ""
	var/datum/market_position/position
	var/deposit = 0
	var/leverage = 1
	var/entry_price = 0
	var/quantity = 0

/datum/market_loan
	var/borrower_name = ""
	var/ckey = ""
	var/amount = 0
	var/interest_rate = 0
	var/term_minutes = 0
	var/borrowed_time = 0
	var/total_owed = 0
	var/repaid = FALSE
	var/expired = FALSE

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
	icon_off_state = "ludkaterminal_off"
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
