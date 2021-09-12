local hirelingMailSubjects = WritCreater.hirelingMailSubjects

local hirelingMails = 
{}

local currentWorkingMail
local function lootMails()
	if #hirelingMails == 0 then
		-- CloseMailbox()
		d("Writ Crafter: Mail Looting complete")
		return
	else
		local mailId = hirelingMails[1]
		-- d(mailId)
		currentWorkingMail = mailId
		requestResult = RequestReadMail(mailId)
		if requestResult <= REQUEST_READ_MAIL_RESULT_SUCCESS_SERVER_REQUESTED then
		end
		zo_callLater(function()

				if currentWorkingMail == mailId and not IsReadMailInfoReady(mailId) then
					RequestReadMail(mailId)
				end 
			end, 100)
	end
end

local function  findLootableMails()
	if not WritCreater:GetSettings().mail.loot then
		return
	end
	hirelingMails = {}
	local nextMail = GetNextMailId(nil)
	if not nextMail then
	 	-- CloseMailbox()
	 	-- d("No mails found")
	 	EVENT_MANAGER:UnregisterForEvent(WritCreater.name.."mailbox", EVENT_MAIL_READABLE)
	 	return
	end
	
	while nextMail do
		local  _,_,subject, _,_,system,customer, _, numAtt, money = GetMailItemInfo (nextMail)
		if not customer and money == 0 and system and hirelingMailSubjects[subject] then
			if WritCreater:GetSettings().mail.delete or numAtt > 0 then
			-- if #hirelingMails < 3 then
				-- hirelingMails[nextMail] = true
				table.insert(hirelingMails,  nextMail)
			end
			-- end
			-- DeleteMail(mailId, true)
		end
		nextMail = GetNextMailId(nextMail)
	end

	if #hirelingMails > 0 then
		d("Writ Crafter: "..#hirelingMails.. " hireling mails found")
		zo_callLater(lootMails, 10)
	else
		EVENT_MANAGER:UnregisterForEvent(WritCreater.name.."mailbox", EVENT_MAIL_READABLE)
		-- d("No hireling mails found")
	end
end
local lootReadMail
local function deleteLootedMail(mailId)
	local  _,_,subject, _,_,system,customer, _, numAtt, money = GetMailItemInfo(mailId)
	if numAtt > 0 then
		-- d("Tried deleting but still attachments")
		lootReadMail(1, mailId)
		return
	end
	if WritCreater:GetSettings().mail.delete then
		DeleteMail(mailId, true)
	end
	if hirelingMails[1] == mailId then
		table.remove(hirelingMails, 1)
		zo_callLater(lootMails, 40)
	end
	-- table.remove(hirelingMails, mailId)
	shouldBeRemoved = mailId
	-- zo_callLater(lootMails, 40)
end


function lootReadMail(event, mailId)
	if not IsReadMailInfoReady(mailId) then
		-- d("Stop")
		zo_callLater(function() lootMails() end , 10 )
		return
	end
	local  _,_,subject, _,_,system,customer, _, numAtt, money = GetMailItemInfo(mailId)
	if not customer and money == 0 and system and hirelingMailSubjects[subject] then
		if numAtt > 0 then
			-- d("Writ Crafter: Looting "..subject)
			TakeMailAttachedItems(mailId)
			zo_callLater(function() deleteLootedMail(mailId) end, 40)
			return
		else
			-- d("Mail empty. Delete it")
			deleteLootedMail(mailId)
			return
		end
	end
end


function WritCreater.lootHireling(event)
	-- d("BEGIN the bugs!")
	EVENT_MANAGER:RegisterForEvent(WritCreater.name.."mailbox",EVENT_MAIL_REMOVED, function(event, mailId)if hirelingMails[1] == mailId then
		table.remove(hirelingMails, 1)
		if #hirelingMails == 0 then
			-- d("COMPLETETIONS")
		else
			lootMails()
		end
	end
	end)
	EVENT_MANAGER:RegisterForEvent(WritCreater.name.."mailbox",EVENT_MAIL_TAKE_ATTACHED_ITEM_SUCCESS, function(event, mailId) 
		local toremove
		for k, v in pairs(hirelingMails) do 
			if v == mailId then 
				local _,_,sub = GetMailItemInfo(mailId) d("Writ Crafter: "..sub.." looted")
				if not WritCreater:GetSettings().mail.delete then
					toremove = k
				end
			end 
		end 
		if toremove then
			table.remove(hirelingMails, k)
		end
	end )
	-- EVENT_MANAGER:RegisterForEvent(WritCreater.name.."mailbox", EVENT_MAIL_OPEN_MAILBOX, 
	-- 	function ()
	-- 	EVENT_MANAGER:UnregisterForEvent(WritCreater.name.."mailbox", EVENT_MAIL_OPEN_MAILBOX)
	-- 		zo_callLater(function ()
	-- 			findLootableMails()
	-- 		end, 10)
	-- 	end)
	if WritCreater:GetSettings().mail.loot then
		findLootableMails()
		EVENT_MANAGER:RegisterForEvent(WritCreater.name.."mailbox", EVENT_MAIL_READABLE, lootReadMail)
	end
end
EVENT_MANAGER:RegisterForEvent(WritCreater.name.."mailbox",EVENT_MAIL_OPEN_MAILBOX , function() WritCreater.lootHireling() end)

function WritCreater.triggerMailLooting()
	CloseMailbox()
	RequestOpenMailbox()
end

SLASH_COMMANDS['/testmail'] = WritCreater.triggerMailLooting
--EVENT_MAIL_INBOX_UPDATE


-- EVENT_MANAGER:RegisterForEvent(_addon.name, EVENT_MAIL_OPEN_MAILBOX, function ()
-- 			EVENT_MANAGER:UnregisterForEvent(_addon.name, EVENT_MAIL_OPEN_MAILBOX)
-- 			zo_callLater(function () 
-- 					if mailAction~=MAIL_ACTION_LOOT then return end
-- 					--todo: get out of the action if we get stuck

-- 					local mailId = GetNextMailId(nil)
					
-- 					if not mailId then
-- 						DCS_closeMailbox()
-- 						_out("Extract from Mail: |cFF8080mailbox empty or not ready yet|r")
-- 						return
-- 					end	
					
-- 					while mailId do
-- 						local _,_,subject,_,_,fromSystem,fromCustSrv,returned,numAtt,attMoney,codAmount = GetMailItemInfo(mailId)
-- 						local lootf = false
-- 						if not fromCustSrv and not returned and attMoney==0 and codAmount==0 then
-- 							if subjtext and subjtext~="" then
-- 								lootf = string.find(subject,subjtext)
-- 							else
-- 								lootf = FindFromList(string.lower(subject),langStrings["material"])
-- 							end 
-- 						end	
-- 						if lootf then
-- 							if numAtt==0 then
-- 								lootedMail[#lootedMail+1] = mailId
-- 							else	
-- 								mailToLoot[#mailToLoot+1] = mailId
-- 							end	
-- 						end
-- 						mailId = GetNextMailId(mailId)
-- 					end

-- 					EVENT_MANAGER:RegisterForEvent(_addon.name, EVENT_MAIL_READABLE, DCS_lootSingleMail)
-- 					EVENT_MANAGER:RegisterForEvent(_addon.name, EVENT_MAIL_TAKE_ATTACHED_ITEM_SUCCESS, DCS_takeMailAttSuccess)
-- 					EVENT_MANAGER:RegisterForEvent(_addon.name, EVENT_INVENTORY_IS_FULL, DCS_takeMailAttFail)
-- 					DCS_regUnexpectedCloseEvent()		
-- 					DCS_tryLootNextMail()
-- 				end, MAIL_NEXTOP_DELAY)	
-- 		end)

-- 	_out("Extract from Mail: please wait...")
-- 	DCS_tryOpenMailbox() 

-- 	local function DCS_tryOpenMailbox()
-- 	if mailAction==MAIL_ACTION_NONE then return end
-- 	if SCENE_MANAGER:GetCurrentScene().name == "mailInbox" then
-- 		SCENE_MANAGER:HideCurrentScene()
-- 	end	
	
-- 	CloseMailbox()	
	
-- 	local cMailAction = mailAction
-- 	local cMailActionId = mailActionId

-- 	--if inbox is not open within 5s, abort all
-- 	zo_callLater(function () 
-- 			if mailAction==cMailAction then
-- 				if mailActionId==cMailActionId then
-- 					if curMailIndex==0 then
-- 						EVENT_MANAGER:UnregisterForEvent(_addon.name, EVENT_MAIL_OPEN_MAILBOX)
-- 						mailAction = MAIL_ACTION_NONE
-- 						mailActionId = 0
-- 						_out("Failed to open mailbox, |cFF8080operation aborted")
-- 					end
-- 				end	
-- 			end 
-- 		end, 5000)  
		
-- 	RequestOpenMailbox() 
-- end
