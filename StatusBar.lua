WritCreater = WritCreater or {}

local StatusBar = DolgubonsLazyWritStatus



SLASH_COMMANDS['/dstat'] =function() StatusBar:SetHidden(false) end

local function myLower(str)
	return zo_strformat("<<z:1>>",str)
end

local function toggleStatusWindow(override)
	if override ~= nil then
		StatusBar:SetHidden(override)
		return
	end
	StatusBar:SetHidden(not WritCreater:GetSettings().showStatusBar)
end


local colours={
	notAccepted = "8D8D8D",
	incomplete = "FFFF33",
	deliver = "32CD32",
}

local QUEST_NOT_ACCEPTED = "notAccepted"
local QUEST_INCOMPLETE = "incomplete"
local QUEST_DELIVER = "deliver"

local function isQuestDeliverable(questIndex)
	local conditionsTable =
	{
		["text"] = {},
		["cur"] = {},
		["max"] = {},
		["complete"] = {},
		["pattern"] = {},
		["mats"] = {},
	}
	for condition = 1, GetJournalQuestNumConditions(questIndex,1) do
		conditionsTable["text"][condition], conditionsTable["cur"][condition], conditionsTable["max"][condition],_,conditionsTable["complete"][condition] = GetJournalQuestConditionInfo(questIndex, 1, condition)
		-- Check if the condition is complete or empty or at the deliver step
		if string.find(myLower(conditionsTable["text"][condition]),myLower(WritCreater.writCompleteStrings()["Deliver"])) then
			return QUEST_DELIVER
		else
		end
	end
	return QUEST_INCOMPLETE
end

local function singleQuestStatus(craftingIndex, questIndex)
	if not questIndex then
		return QUEST_NOT_ACCEPTED
	else
		return isQuestDeliverable(questIndex)
	end
end

local function computeQuestStatus ()
	local status = {
		QUEST_NOT_ACCEPTED ,
		QUEST_NOT_ACCEPTED ,
		QUEST_NOT_ACCEPTED ,
		QUEST_NOT_ACCEPTED ,
		QUEST_NOT_ACCEPTED ,
		QUEST_NOT_ACCEPTED ,
		QUEST_NOT_ACCEPTED ,
	}
	local writs = WritCreater.writSearch()
	for i = 1, 7 do
		status[i] = singleQuestStatus(i, writs[i])
	end
	return status
end

local statusOrder =
{
	CRAFTING_TYPE_BLACKSMITHING,
	CRAFTING_TYPE_CLOTHIER,
	CRAFTING_TYPE_WOODWORKING,
	CRAFTING_TYPE_JEWELRYCRAFTING ,
	CRAFTING_TYPE_ALCHEMY,
	CRAFTING_TYPE_ENCHANTING,
	CRAFTING_TYPE_PROVISIONING
}

local writLetters =
{
	"B","C","E","A","P","W","J"
}

local function updateQuestStatus(event)
	local status = computeQuestStatus()
	local workingString = ""
	local anyActive = false
	for i = 1, 7 do
		local nextOrder = statusOrder[i]
		local nextStatus = status[nextOrder]
		local colour = colours[nextStatus]
		workingString = workingString.."|c"..colour..writLetters[nextOrder].."|r"
		if i == 4 then
			workingString = workingString.."  "
		end
		if nextStatus == QUEST_INCOMPLETE or nextStatus == QUEST_DELIVER then
			anyActive = true
		end
	end
	DolgubonsLazyWritStatusBackdropOutput:SetText(workingString)
	if not anyActive then
		toggleStatusWindow(true)
	else
		toggleStatusWindow()
	end
	StatusBar:ClearAnchors()
	StatusBar:SetAnchor(TOPRIGHT, GuiRoot, TOPLEFT, WritCreater:GetSettings().statusBarX, WritCreater:GetSettings().statusBarY)
end

WritCreater.updateQuestStatus = updateQuestStatus
function WritCreater.loadStatusBar()
	--EVENT_QUEST_COMPLETE
	EVENT_MANAGER:RegisterForEvent("WritCrafterStatusBar", EVENT_QUEST_ADDED , updateQuestStatus)
	EVENT_MANAGER:RegisterForEvent("WritCrafterStatusBar", EVENT_QUEST_ADVANCED , updateQuestStatus) -- items delivered
	EVENT_MANAGER:RegisterForEvent("WritCrafterStatusBar", EVENT_QUEST_CONDITION_COUNTER_CHANGED , updateQuestStatus) -- this one
	EVENT_MANAGER:RegisterForEvent("WritCrafterStatusBar", EVENT_OBJECTIVES_UPDATED , updateQuestStatus) -- probably not used
	EVENT_MANAGER:RegisterForEvent("WritCrafterStatusBar", EVENT_OBJECTIVE_COMPLETED , updateQuestStatus) -- probably not used
	EVENT_MANAGER:RegisterForEvent("WritCrafterStatusBar", EVENT_QUEST_REMOVED , updateQuestStatus)
	EVENT_MANAGER:RegisterForEvent("WritCrafterStatusBar", EVENT_PLAYER_ACTIVATED , updateQuestStatus)
	updateQuestStatus()
	StatusBar:ClearAnchors()
	StatusBar:SetAnchor(TOPRIGHT, GuiRoot, TOPLEFT, WritCreater:GetSettings().statusBarX, WritCreater:GetSettings().statusBarY)
end


WritCreater.toggleQuestStatusWindow = toggleStatusWindow
