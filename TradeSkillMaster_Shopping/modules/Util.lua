-- ------------------------------------------------------------------------------ --
--                            TradeSkillMaster_Shopping                           --
--            http://www.curse.com/addons/wow/tradeskillmaster_shopping           --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

-- load the parent file (TSM) into a local variable and register this file as a module
local TSM = select(2, ...)
local Util = TSM:NewModule("Util", "AceEvent-3.0", "AceHook-3.0")
local private = {}

-- ʕ •ᴥ•ʔ✿ FORGE LEVEL DETECTION ✿ ʕ •ᴥ•ʔ
local FORGE_LEVEL_MAP = {
	BASE = 0,
	TITANFORGED = 1,
	WARFORGED = 2,
	LIGHTFORGED = 3
}

-- ʕ •ᴥ•ʔ✿ TEMPORARY PAGE-LEVEL CACHE FOR FORGE LEVELS ✿ ʕ •ᴥ•ʔ
local pageForgeCache = {}

local function GetForgeLevelFromLink(itemLink)
	if not itemLink then return FORGE_LEVEL_MAP.BASE end
	
	-- ʕ •ᴥ•ʔ✿ PERFORMANCE: Check page cache first ✿ ʕ •ᴥ•ʔ
	if pageForgeCache[itemLink] then
		return pageForgeCache[itemLink]
	end
	
	local forgeValue = FORGE_LEVEL_MAP.BASE
	if _G.GetItemLinkTitanforge then
		forgeValue = GetItemLinkTitanforge(itemLink)
		-- Validate the returned value against known FORGE_LEVEL_MAP values
		local validValue = false
		for _, knownValue in pairs(FORGE_LEVEL_MAP) do
			if forgeValue == knownValue then
				validValue = true
				break
			end
		end
		if not validValue then
			forgeValue = FORGE_LEVEL_MAP.BASE
		end
	end
	
	-- ʕ •ᴥ•ʔ✿ CACHE RESULT FOR THIS PAGE ✿ ʕ •ᴥ•ʔ
	pageForgeCache[itemLink] = forgeValue
	return forgeValue
end

-- ʕ •ᴥ•ʔ✿ CLEAR PAGE CACHE WHEN STARTING NEW SCAN ✿ ʕ •ᴥ•ʔ
local function ClearPageForgeCache()
	wipe(pageForgeCache)
end

-- ʕ •ᴥ•ʔ✿ OPTIMIZED LIVE DATA PROCESSING ✿ ʕ •ᴥ•ʔ
function private:ProcessLiveData()
	if not private.filterList or not private.filterList[1] then
		return
	end
	
	local currentFilter = private.filterList[1]
	local shown = GetNumAuctionItems("list")
	
	-- ʕ •ᴥ•ʔ✿ PERFORMANCE OPTIMIZATION: Early exit if no forge filter ✿ ʕ •ᴥ•ʔ
	local hasForgeFilter = currentFilter.forgeLevel and currentFilter.forgeLevel >= 0
	
	-- ʕ •ᴥ•ʔ✿ BATCH PROCESSING: Process in chunks to avoid UI freezing ✿ ʕ •ᴥ•ʔ
	local batchSize = 10 -- Process 10 items at a time
	local startIndex = private.liveProcessIndex or 1
	local endIndex = min(startIndex + batchSize - 1, shown)
	
	for i = startIndex, endIndex do
		-- ʕ •ᴥ•ʔ✿ PERFORMANCE: Get all data in one call ✿ ʕ •ᴥ•ʔ
		local name, texture, count, _, _, _, minBid, minIncrement, buyout, bid, highBidder, seller = GetAuctionItemInfo("list", i)
		
		-- Process item if it meets all criteria
		if buyout and buyout > 0 then
			local itemLink = GetAuctionItemLink("list", i)
			if itemLink then
				local itemString = TSMAPI:GetItemString(itemLink)
				if itemString then
					local shouldProcess = true
					
					-- ʕ •ᴥ•ʔ✿ OPTIMIZED FORGE CHECK ✿ ʕ •ᴥ•ʔ
					if hasForgeFilter then
						local itemForgeLevel = GetForgeLevelFromLink(itemLink)
						if itemForgeLevel ~= currentFilter.forgeLevel then
							shouldProcess = false
						end
					end
					
					if shouldProcess then
						-- Create unique key and check for duplicates
						local auctionKey = itemString .. ":" .. i
						if not private.auctions[auctionKey] then
							-- ʕ •ᴥ•ʔ✿ STREAMLINED AUCTION CREATION ✿ ʕ •ᴥ•ʔ
							local tempAuctionItem = TSMAPI.AuctionScan:NewAuctionItem()
							tempAuctionItem:SetItemLink(itemLink)
							tempAuctionItem:SetTexture(texture)
							tempAuctionItem.query = currentFilter
							
							local timeLeft = GetAuctionItemTimeLeft("list", i)
							tempAuctionItem:AddAuctionRecord(count, minBid, minIncrement, buyout, bid, highBidder, seller or "?", timeLeft)
							
							private:ProcessItem(itemString, tempAuctionItem)
						end
					end
				end
			end
		end
	end
	
	-- ʕ •ᴥ•ʔ✿ CONTINUE PROCESSING NEXT BATCH ✿ ʕ •ᴥ•ʔ
	if endIndex < shown then
		private.liveProcessIndex = endIndex + 1
		-- Schedule next batch with small delay to prevent UI freezing
		TSMAPI:CreateTimeDelay("liveBatchProcess", 0.05, function()
			private:ProcessLiveData()
		end)
	else
		-- Reset for next page
		private.liveProcessIndex = 1
	end
end

-- locals to speed up function access
local abs = abs
local ceil = ceil
local floor = floor
local format = format
local ipairs = ipairs
local max = max
local min = min
local pairs = pairs
local select = select
local strfind = strfind
local strlower = strlower
local strlenutf8 = strlenutf8
local strsub = strsub
local tinsert = tinsert
local tonumber = tonumber
local tremove = tremove
local tsort = table.sort
local type = type
local wipe = wipe

local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Shopping") -- loads the localization table
private.auctions={}
TSMAPI:RegisterForTracing(private, "TradeSkillMaster_Shopping_private")
Util.shoppingLog = {}


local function ControlCallback(event, ...)
	if event == "OnBuyout" then
		local auction = ...
		tinsert(Util.shoppingLog, {action="Buyout", link=auction.link, buyout=auction.buyout, count=auction.count})
		private:RemoveAuction(auction, event, TSMAPI:GetItemString(auction.link))
	elseif event == "OnCancel" then
		local auction = ...
		tinsert(Util.shoppingLog, {action="Cancel", link=auction.link, buyout=auction.buyout, count=auction.count})
		private:RemoveAuction(auction, event, TSMAPI:GetItemString(auction.link))
	elseif event == "OnPost" then
		local postInfo = ...
		local link = select(2, TSMAPI:GetSafeItemInfo(postInfo.itemString))
		for i=1, postInfo.numAuctions do
			tinsert(Util.shoppingLog, {auction="Post", link=link, buyout=postInfo.buyout, count=postInfo.stackSize})
		end
		private:AddPostedAuction(postInfo)
	end
	if TSM.searchCallback then
		TSM.searchCallback(event, ...)
	end
end

function private:HasInBags(baseItemString)
	for _, _, itemString in TSMAPI:GetBagIterator() do
		if TSMAPI:GetBaseItemString(itemString) == baseItemString then
			return true
		end
	end
end

function private:CreateSearchFrame()
	local function OnShow(self)
		if not self.info then return end
		if self.info.isDestroying then
			self.rtNormal:Hide()
			self.rtDestroying:Show()
			self.rt = private.searchFrame.rtDestroying
		else
			self.rtNormal:Show()
			self.rtDestroying:Hide()
			self.rt = private.searchFrame.rtNormal
		end
		self.rt:SetColHeadText(#self.rt.headCols, self.info.pctColName)
	end

	local frame = CreateFrame("Frame", nil, private.parent.content)
	frame:Hide()
	frame:SetAllPoints()
	frame:SetScript("OnShow", OnShow)
	
	local statusBarFrame = CreateFrame("Frame", nil, frame)
	statusBarFrame:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 165, -2)
	statusBarFrame:SetWidth(250)
	statusBarFrame:SetHeight(30)
	frame.statusBar = TSMAPI.GUI:CreateStatusBar(statusBarFrame, "TSMShoppingStatusBar")
	
	local handlers = {
		OnClick = function(_, data, self, button)
			-- they clicked on a data row
			if button == "LeftButton" then
				-- go to the page for this item
				local record = data.auctionRecord
				TSMAPI.AuctionScan:FindAuction(function() end, {itemString=data.itemString, buyout=record.buyout, count=record.count, seller=record.seller}, true)
				
				if data.auctionRecord:IsPlayer() then
					private.controlButtons.cancel:Enable()
					private.controlButtons.buyout:Disable()
					private.controlButtons.post:Disable()
				elseif data.auctionRecord.buyout == 0 then
					private.controlButtons.buyout:Disable()
					private.controlButtons.cancel:Disable()
					private.controlButtons.post:Disable()
				else
					private.controlButtons.buyout:Enable()
					private.controlButtons.cancel:Disable()
					private.controlButtons.post:Disable()
				end
				if private:HasInBags(TSMAPI:GetBaseItemString(data.itemString)) then
					private.controlButtons.post:Enable()
				end
			end
		end,
	}
	
	local rt = TSMAPI:CreateAuctionResultsTable(frame, handlers, true)
	rt:SetData({})
	rt:SetSort(8, true)
	frame.rtNormal = rt
	
	local rt2 = TSMAPI:CreateAuctionResultsTable(frame, handlers, true, true)
	rt2:SetData({})
	rt2:SetSort(5, true)
	frame.rtDestroying = rt2
	
	return frame
end

function Util:SetParent(parent)
	private.parent = parent
end

function Util:ShowSearchFrame(isDestroying, pctColName, clearRT)
	if private.searchFrame and private.searchFrame:IsVisible() then
		Util:HideSearchFrame()
	end
	private.searchFrame = private.searchFrame or private:CreateSearchFrame()
	private.searchFrame.info = {isDestroying=isDestroying, pctColName=pctColName}
	private.searchFrame:Show()
	if clearRT then
		private.searchFrame.rtNormal:SetData({})
		private.searchFrame.rtDestroying:SetData({})
	end
	private.controlButtons = TSMAPI.AuctionControl:ShowControlButtons(private.parent, private.searchFrame.rt, ControlCallback, "Shopping", TSM.db.global.postBidPercent, TSM.db.global.postUndercut)
	private.controlButtons.buyout:Disable()
	private.controlButtons.cancel:Disable()
	private.controlButtons.post:Disable()
	TSMAPI.AuctionScan:StopScan()
	TSMAPI.AuctionScan:ClearCache()
	private.searchFrame.statusBar:SetStatusText("")
	private.searchFrame.statusBar:UpdateStatus(0, 0)
	private.mode = isDestroying and "destroy" or "normal"
	TSM.Search:SetMode(private.mode)
end

function Util:HideSearchFrame()
	private.searchFrame:Hide()
	TSMAPI.AuctionControl:HideControlButtons()
	TSMAPI.AuctionScan:StopScan()
	TSMAPI.AuctionScan:ClearCache()
end


function Util:StartItemScan(itemList, callback)
	if type(itemList) ~= "table" then return end
	private:PrepareForScan(callback)
	if #itemList == 1 then private.searchItem = itemList[1] end
	TSMAPI:GenerateQueries(itemList, private.ScanCallback)
end

function Util:StartFilterScan(filters, callback)
	if type(filters) ~= "table" then return end
	
	-- ʕ •ᴥ•ʔ✿ CHECK FOR GETALL FORGE SEARCH ✿ ʕ •ᴥ•ʔ
	if #filters == 1 and filters[1].useGetAll and filters[1].forgeLevel and filters[1].forgeLevel >= 0 then
		private:StartGetAllForgeScan(filters[1], callback)
		return
	end
	
	private:PrepareForScan(callback)
	if #filters == 1 then
		for _, _, itemString in TSMAPI:GetBagIterator() do
			local name = TSMAPI:GetSafeItemInfo(itemString)
			if name and filters[1].name and strlower(name) == strlower(filters[1].name) then
				private.searchItem = itemString
				break
			end 
		end
	end
	private.filterList = filters
	private.numFilters = #private.filterList
	private:ScanNextFilter()
end

function Util:StartLastPageScan(callback)
	private:PrepareForScan(callback, true)
	TSMAPI.AuctionScan:ScanLastPage(private.ScanCallback)
end

function Util:StopScan()
	TSMAPI:CancelFrame("shoppingRestartSniper")
	TSMAPI.AuctionScan:StopScan()
	private:ScanComplete()
end

-- ʕ •ᴥ•ʔ✿ GETALL FORGE SCANNING ✿ ʕ •ᴥ•ʔ
function private:StartGetAllForgeScan(filter, callback)
	private:PrepareForScan(callback)
	private.getAllForgeFilter = filter
	private.getAllLoaded = nil
	
	-- Update status message
	local forgeNames = {"", "Titanforged", "Warforged", "Lightforged"}
	local forgeName = forgeNames[filter.forgeLevel + 1] or "Unknown"
	private.searchFrame.statusBar:SetStatusText(format("Starting GetAll scan for %s items...", forgeName))
	
	-- Show informational message
	TSM:Printf("Using GetAll scan to find forge items. This scans the entire auction house once and filters locally - much faster than multiple searches!")
	
	-- Check if GetAll is available
	local canScan, canGetAll = CanSendAuctionQuery()
	if not canGetAll then
		TSM:Print("GetAll scan unavailable. Falling back to standard search...")
		-- Remove the useGetAll flag and do normal filter scan
		filter.useGetAll = nil
		private.filterList = {filter}
		private.numFilters = 1
		private:ScanNextFilter()
		return
	end
	
	if not canScan then
		TSMAPI:CreateTimeDelay("getAllForgeDelay", 0.5, function() private:StartGetAllForgeScan(filter, callback) end)
		return
	end
	
	-- Register event and start GetAll scan
	Util:RegisterEvent("AUCTION_ITEM_LIST_UPDATE", private.GetAllScanEventHandler)
	QueryAuctionItems("", nil, nil, nil, nil, nil, nil, nil, nil, true)
	
	-- Start processing thread
	TSMAPI.Threading:Start(private.ProcessGetAllForgeScan, 1, function()
		private:ScanComplete()
	end)
end

function private.GetAllScanEventHandler()
	Util:UnregisterEvent("AUCTION_ITEM_LIST_UPDATE")
	
	local shown, total = GetNumAuctionItems("list")
	if shown <= 0 then
		TSM:Print("GetAll scan failed due to server issues.")
		private:ScanComplete()
		return
	end
	
	-- Check if GetAll is severely limited (less than 10% of total auctions)
	if total > 0 and shown < (total * 0.1) then
		TSM:Printf(format("GetAll severely limited: only %d of %d auctions received. Falling back to targeted searches...", shown, total))
		-- Fall back to targeted category searches
		private:StartTargetedForgeScan()
		return
	end
	
	-- Cache the amount of auctions we received
	private.getAllLoaded = shown
	
	-- Warn if we didn't get all auctions (like TSM does)
	if total ~= shown then
		TSM:Printf(format("WARNING: Server has %d auctions but only sent %d auctions. GetAll scan may be incomplete.", total, shown))
	else
		TSM:Printf(format("All auctions received from server (%d auctions)...", shown))
	end
end

function private.ProcessGetAllForgeScan(self)
	-- Wait for the GetAll data to be loaded
	local timeStart = time()
	local progressBar = 0
	while true do
		progressBar = min(progressBar + 1, 100)
		self:Sleep(0.2)
		
		if not private.getAllForgeFilter then return end -- Scan stopped
		if private.getAllLoaded then break end -- Data received
		
		local timeElapsed = time() - timeStart
		if timeElapsed >= 30 then
			TSM:Print("GetAll scan timed out. Server may be throttling requests.")
			return
		else
			private.searchFrame.statusBar:SetStatusText("Waiting for GetAll data...")
		end
	end
	
	-- Process the GetAll data
	local filter = private.getAllForgeFilter
	local forgeNames = {"", "Titanforged", "Warforged", "Lightforged"}
	local forgeName = forgeNames[filter.forgeLevel + 1] or "Unknown"
	
	private.searchFrame.statusBar:SetStatusText(format("Processing %d auctions for %s items...", private.getAllLoaded, forgeName))
	
	for auctionIdx = 1, private.getAllLoaded do
		-- Update progress bar periodically
		if (auctionIdx == 1) or (auctionIdx == private.getAllLoaded) or ((auctionIdx % 100) == 0) then
			local progress = min(100 * (auctionIdx / private.getAllLoaded), 100)
			private.searchFrame.statusBar:UpdateStatus(progress, 0)
			private.searchFrame.statusBar:SetStatusText(format("Processing GetAll data: %d / %d", auctionIdx, private.getAllLoaded))
			
			-- Yield CPU every 100 auctions
			self:Yield()
			
			-- Verify we're still looking at the same auction list
			if GetNumAuctionItems("list") ~= private.getAllLoaded then
				TSM:Print("GetAll scan interrupted - auction list changed.")
				return
			end
		end
		
		-- Get auction data
		local name, texture, count, _, _, _, minBid, minIncrement, buyout, bid, highBidder, seller = GetAuctionItemInfo("list", auctionIdx)
		local itemLink = GetAuctionItemLink("list", auctionIdx)
		
		if buyout and buyout > 0 and itemLink then
			local itemString = TSMAPI:GetItemString(itemLink)
			if itemString then
				-- Check forge level
				local itemForgeLevel = GetForgeLevelFromLink(itemLink)
				if itemForgeLevel == filter.forgeLevel then
					-- Check quality filter
					local _, _, quality = TSMAPI:GetSafeItemInfo(itemString)
					if quality and quality >= filter.quality then
						-- Check if it's armor or weapon
						local _, _, _, _, _, class = TSMAPI:GetSafeItemInfo(itemString)
						if class == 2 or class == 4 then -- Weapons or Armor
							-- Create and process auction item
							local tempAuctionItem = TSMAPI.AuctionScan:NewAuctionItem()
							tempAuctionItem:SetItemLink(itemLink)
							tempAuctionItem:SetTexture(texture)
							tempAuctionItem.query = filter
							
							local timeLeft = GetAuctionItemTimeLeft("list", auctionIdx)
							tempAuctionItem:AddAuctionRecord(count, minBid, minIncrement, buyout, bid, highBidder, seller or "?", timeLeft)
							
							private:ProcessItem(itemString, tempAuctionItem)
						end
					end
				end
			end
		end
	end
	
	TSM:Print("GetAll forge scan completed successfully!")
end

-- ʕ •ᴥ•ʔ✿ TARGETED FORGE SCANNING FALLBACK ✿ ʕ •ᴥ•ʔ
function private:StartTargetedForgeScan()
	local filter = private.getAllForgeFilter
	if not filter then return end
	
	-- Create targeted searches for armor and weapons
	local targetedFilters = {}
	
	-- Weapons (class 2)
	local weaponFilter = TSMAPI.Util:CopyTable(filter)
	weaponFilter.name = ""
	weaponFilter.class = 2
	weaponFilter.useGetAll = nil -- Remove GetAll flag
	table.insert(targetedFilters, weaponFilter)
	
	-- Armor (class 4)  
	local armorFilter = TSMAPI.Util:CopyTable(filter)
	armorFilter.name = ""
	armorFilter.class = 4
	armorFilter.useGetAll = nil -- Remove GetAll flag
	table.insert(targetedFilters, armorFilter)
	
	-- Set up the fallback filter list
	private.filterList = targetedFilters
	private.numFilters = #targetedFilters
	private.currentFilter = 0
	
	TSM:Printf("Starting targeted forge scans: %d searches for weapons and armor...", #targetedFilters)
	
	-- Start the first targeted scan
	private:ScanNextFilter()
end





function private:PrepareForScan(callback, isLastPageScan)
	TSMAPI:CancelFrame("shoppingRestartSniper")
	TSMAPI.AuctionScan:StopScan()
	private.searchItem = nil
	private.isLastPageScan = isLastPageScan
	private.callback = callback
	wipe(private.auctions)
	
	if private.isLastPageScan then
		private.searchFrame.statusBar:SetStatusText("Scanning last page...")
	else
		private.searchFrame.statusBar:SetStatusText(L["Preparing filters..."])
	end
	private.searchFrame.rt:SetData({})
	private.searchFrame.rt:SetDisabled(true)
	private.searchFrame.statusBar:UpdateStatus(0, 0)
	TSM.moduleAPICallback = nil
	
	-- ʕ •ᴥ•ʔ✿ LIVE RESULTS INDICATOR ✿ ʕ •ᴥ•ʔ
	private.liveResultsMode = true
end

function private.ScanCallback(event, ...)
	if event == "QUERY_COMPLETE" then
		private.filterList = ...
		private.numFilters = #private.filterList
		private:ScanNextFilter()
	elseif event == "QUERY_UPDATE" then
		local current, total, skipped = ...
		private:UpdateStatus("query", current, total)
	elseif event == "SCAN_PAGE_UPDATE" then
		-- Simply forward the "currently received" and "total" page counts
		-- for the current item we're scanning.
		-- NOTE: Private servers sometimes give totally insane "total page counts"
		-- on the first response, such as "page 1/142", but those server errors
		-- always correct themselves to "page 2/REAL" when the scan has reached
		-- page 2. There's nothing we can do to avoid that rare page-count issue
		-- (which happens on many popular private servers, such as Warmane).
		private:UpdateStatus("page", ...)
		
		-- ʕ •ᴥ•ʔ✿ PERFORMANCE: Clear page cache for new page ✿ ʕ •ᴥ•ʔ
		ClearPageForgeCache()
		
		-- ʕ •ᴥ•ʔ✿ LIVE PROCESSING: Process items as each page is scanned ✿ ʕ •ᴥ•ʔ
		-- Try to process any new auction data that might be available
		TSMAPI:CreateTimeDelay("liveUpdate", 0.1, function()
			-- This gives the scan a moment to populate data, then we check for new items
			private:ProcessLiveData()
		end)
	elseif event == "SCAN_INTERRUPTED" or event == "INTERRUPTED" then
		-- We've been interrupted by the Auction House closing.
		-- NOTE: "SCAN_INTERRUPTED" is from LibAuctionScan-1.0, which isn't used
		-- by TSM anymore, and "INTERRUPTED" is from "TSM/Auction/AuctionScanning.lua",
		-- which is what this scanner uses nowadays.
		private:ScanComplete(true)
	elseif event == "SCAN_TIMEOUT" then
		tremove(private.filterList, 1)
		private:ScanNextFilter()
	elseif event == "SCAN_COMPLETE" then
		if not private.filterList or not private.filterList[1] then return end -- protect against sniper scan starts causing issues
		local data = ...
		
		-- ʕ •ᴥ•ʔ✿ SKIP SCAN_COMPLETE FOR FORGE FILTERS ✿ ʕ •ᴥ•ʔ
		-- If this is a forge filter search, we already processed everything correctly in live processing
		-- The aggregated data in SCAN_COMPLETE mixes forge levels and would contaminate our results
		if private.filterList[1].forgeLevel and private.filterList[1].forgeLevel >= 0 then
			-- For forge filters, skip the normal SCAN_COMPLETE processing
			-- Live processing already handled individual auction filtering correctly
		else
			-- Normal processing for non-forge filters
			if private.filterList[1].items then
				for _, itemString in ipairs(private.filterList[1].items) do
					if data[itemString] then
						if data[itemString].isBaseItem then
							for iString, auctionitem in pairs(data) do
								if iString ~= itemString and TSMAPI:GetBaseItemString(iString) == itemString then
									auctionitem.query = private.filterList[1]
									private:ProcessItem(iString, auctionitem)
								end
							end
						else
							data[itemString].query = private.filterList[1]
							private:ProcessItem(itemString, data[itemString])
						end
					end
				end
			else
				for itemString, auctionData in pairs(data) do
					if not auctionData.isBaseItem then
						auctionData.query = private.filterList[1]
						private:ProcessItem(itemString, auctionData)
					end
				end
			end
		end
		
		-- ʕ •ᴥ•ʔ✿ FINAL UPDATE FOR THIS FILTER ✿ ʕ •ᴥ•ʔ
		-- Only update RT if we haven't already done so in ProcessItem
		-- This prevents double updates and ensures smooth instant results
		if private.searchFrame.rt.disabled then
			private:UpdateRT()
		end
		
		private.searchFrame.rt:ClearSelection()
		tremove(private.filterList, 1)
		private:ScanNextFilter()
	elseif event == "SCAN_LAST_PAGE_COMPLETE" then
		local data = ...
		for itemString, auctionData in pairs(data) do
			if not auctionData.isBaseItem then
				if auctionData and #auctionData.records > 0 then
					if private.auctions[itemString] then
						private.auctions[itemString].shouldCompact = true
						private.auctions[itemString]:PopulateCompactRecords()
						local existingRecords = {}
						for _, record in ipairs(private.auctions[itemString].compactRecords) do
							local key = strjoin("~", record.uniqueID, record.count, record.buyout, record.minBid, record.timeLeft)
							existingRecords[key] = true
						end
						for _, record in ipairs(auctionData.records) do
							local key = strjoin("~", record.uniqueID, record.count, record.buyout, record.minBid, record.timeLeft)
							if not existingRecords[key] then
								private.auctions[itemString]:AddRecord(record)
							else
								for _, record2 in ipairs(private.auctions[itemString].records) do
									local key2 = strjoin("~", record.uniqueID, record.count, record.buyout, record.minBid, record.timeLeft)
									if key2 == key and record2.seller ~= "?" then
										record2.seller = record.seller
										break
									end
								end
							end
						end
					else
						private.auctions[itemString] = auctionData
					end
					private.auctions[itemString] = private.callback("process", itemString, private.auctions[itemString])
				end
			end
		end
		private:UpdateRT()
		private.searchFrame.rt:ClearSelection()
		TSMAPI:CreateTimeDelay("shoppingRestartSniper", 0, function() TSMAPI.AuctionScan:ScanLastPage(private.ScanCallback) end)
	end
end

function private:ScanNextFilter()
	-- We must reset the page counter, otherwise the next scan will keep the
	-- page count of the previous item until we receive "SCAN_PAGE_UPDATE".
	-- NOTE: The "nil" signals that we don't know the item's page count yet.
	-- NOTE: The recipient may want to ignore "page" events that have nil values
	-- and not update their status bars based on those, since we send these empty
	-- page events before we start each new scan!
	private:UpdateStatus("page", nil, nil)

	-- Now update the scan counter.
	-- NOTE: Our scan progress counter below starts counting from 0 as the first item.
	if #private.filterList == 0 then
		private:UpdateStatus("scan", private.numFilters, private.numFilters)
		return private:ScanComplete()
	end
	private:UpdateStatus("scan", private.numFilters-#private.filterList, private.numFilters)
	
	-- ʕ •ᴥ•ʔ✿ FORGE SEARCH STATUS MESSAGE ✿ ʕ •ᴥ•ʔ
	local currentFilter = private.filterList[1]
	if currentFilter and currentFilter.forgeLevel and currentFilter.forgeLevel >= 0 then
		local forgeNames = {"", "Titanforged", "Warforged", "Lightforged"}
		local forgeName = forgeNames[currentFilter.forgeLevel + 1] or "Unknown"
		private.searchFrame.statusBar:SetStatusText(format("Scanning for %s items...", forgeName))
		
		-- ʕ •ᴥ•ʔ✿ SHOW FORGE SEARCH MESSAGE ✿ ʕ •ᴥ•ʔ
		if currentFilter.useGetAll then
			-- GetAll message already shown in StartGetAllForgeScan
		elseif private.numFilters == 2 and currentFilter.quality and currentFilter.quality == 2 then
			TSM:Printf("Searching armor and weapons for forge items. This may take a moment to scan both categories.")
		end
	end
	
	TSMAPI.AuctionScan:RunQuery(private.filterList[1], private.ScanCallback, true, private.callback("filter", private.filterList[1]), true)
end

local scanStatus, pageStatus
function private:UpdateStatus(statusType, ...)
	if statusType == "query" then
		private.searchFrame.statusBar:SetStatusText(format(L["Preparing Filter %d / %d"], ...))
		private.searchFrame.statusBar:UpdateStatus(0, 0)
	else
		if statusType == "scan" then
			scanStatus = {...}
		elseif statusType == "page" then
			pageStatus = {...}
			-- Ignore the empty "reset page count" events that happen before every new
			-- scan. We've reset the page counts, which is the only thing that matters.
			if pageStatus[1] == nil and pageStatus[2] == nil then
				return
			end
		end

		-- NOTE: We don't do +1 for the item-scan or page-status counters below,
		-- since we want our progress bar to show FULLY RECEIVED/FINISHED items
		-- and pages, and not fill up until we've fully received each item/page.
		local progress_bar_items = min(100*(scanStatus[1]/scanStatus[2]), 100)  -- Calculate "total items" progress bar from 0-100%.
		local progress_bar_pages = 0
		-- NOTE: In the status text label, we count the items starting at 1,
		-- to say "Scanning 1 / 2" (instead of "Scanning 0 / 2"). For pages,
		-- we show which page we're waiting for (so if we have received 2/4 pages,
		-- the label will say 3/4, meaning "we're waiting for page 3...").
		if pageStatus[1] ~= nil and pageStatus[2] ~= nil then
			-- We have received the page counter ("current page / total pages") for the current item.
			-- NOTE: We add "+1" to the page counter, to indicate that we've received that page and are working on the next page.
			private.searchFrame.statusBar:SetStatusText(format(L["Scanning %d / %d (Page %d / %d)"], scanStatus[1] + 1, scanStatus[2], min(pageStatus[1] + 1, pageStatus[2]), pageStatus[2]))
			progress_bar_pages = min(100*(pageStatus[1]/pageStatus[2]), 100)  -- Calculate "total pages of current item" progress bar from 0-100%.
		else
			-- We have started a new item scan but haven't received the page count yet.
			-- NOTE: If we don't initialize the page-progress to 0%, we'd get a "jumpy"
			-- progress bar that goes from 100% at page 1/? to "real%" after page 1.
			private.searchFrame.statusBar:SetStatusText(format(L["Scanning %d / %d (Page 1 / ?)"], scanStatus[1] + 1, scanStatus[2]))
			progress_bar_pages = 0  -- Begin at 0% for the gray page-counter bar of the current item.
		end
		private.searchFrame.statusBar:UpdateStatus(progress_bar_items, progress_bar_pages)
	end
end

function private:ScanComplete(interrupted)
	if interrupted then
		-- If our scan has been interrupted by the Auction House closing,
		-- simply act as if the user clicked "Stop".
		Util:StopScan()
	else
		if not private.callback then return end
		private.searchFrame.statusBar:SetStatusText(L["Done Scanning"])
		private.searchFrame.statusBar:UpdateStatus(100, 100)
		private.searchFrame.rt:SetDisabled(false)
		if #private.searchFrame.rt.auctionData == 1 then
			private.searchFrame.rt:SetExpanded(private.searchFrame.rt.auctionData[1]:GetItemString(), true)
			private.searchFrame.rt.rows[1].cols[1]:Click()
		elseif #private.searchFrame.rt.auctionData == 0 and private.searchItem and private:HasInBags(TSMAPI:GetBaseItemString(private.searchItem)) then
			private.controlButtons.post:Enable()
			local postPrice = TSM:GetMaxPrice(TSM.db.global.normalPostPrice, private.searchItem) or 0
			TSMAPI.AuctionControl:SetNoResultItem(private.searchItem, postPrice)
		end
		
		if #private.searchFrame.rt.auctionData == 0 and TSM.moduleAPICallback then
			TSM.moduleAPICallback()
		end
		private.callback("done", private.auctions)
		TSMAPI:FireEvent("SHOPPING:SEARCH:SCANDONE", #private.searchFrame.rt.auctionData)
	end
end

-- processes scan data for a specific item
function private:ProcessItem(itemString, auctionItem)
	-- make sure we haven't already scanned this item (possible with common search terms)
	if private.auctions[itemString] then return end
	if not itemString or not auctionItem then return end
	
	local query = auctionItem.query
	query.minILevel = query.minILevel or 0
	query.maxILevel = query.maxILevel or 0
	query.minLevel = query.minLevel or 0
	query.maxLevel = query.maxLevel or 0
	local name, _, _, ilvl, lvl = TSMAPI:GetSafeItemInfo(itemString)
	
	-- check if this item is outside our level or ilvl filters
	if query.minILevel > 0 and (ilvl < query.minILevel or (query.maxILevel > 0 and ilvl > query.maxILevel)) then
		private.auctions[itemString] = nil
		return
	end
	if query.minLevel > 0 and (lvl < query.minLevel or (query.maxLevel > 0 and lvl > query.maxLevel)) then
		private.auctions[itemString] = nil
		return
	end
	
	-- check for /exact filter
	if query.exactOnly and strlower(name) ~= strlower(query.name) then
		private.auctions[itemString] = nil
		return
	end
	
	-- ʕ •ᴥ•ʔ✿ OPTIMIZED FORGE FILTER CHECK - PER RECORD ✿ ʕ •ᴥ•ʔ
	if query.forgeLevel and query.forgeLevel >= 0 then
		-- Early exit if we don't have the API
		if not _G.GetItemLinkTitanforge then
			-- If API is not available, skip forge filtering
			TSM:Print("Forge filtering requires GetItemLinkTitanforge API. Skipping forge filter.")
			query.forgeLevel = -1
		else
			-- ʕ •ᴥ•ʔ✿ CHECK EACH RECORD'S INDIVIDUAL LINK ✿ ʕ •ᴥ•ʔ
			-- Filter out records that don't match the forge level
			auctionItem:FilterRecords(function(record)
				-- Each record should have access to its original itemLink
				-- For now, we'll use the auctionItem's link, but this needs to be improved
				local itemLink = auctionItem.itemLink
				if not itemLink then
					return true -- Remove records without links
				end
				
				local itemForgeLevel = GetForgeLevelFromLink(itemLink)
				return itemForgeLevel ~= query.forgeLevel -- Return true to remove
			end)
			
			-- If no records left after filtering, skip this item
			if #auctionItem.records == 0 then
				private.auctions[itemString] = nil
				return
			end
		end
	end
	
	-- remove any records that don't have buyouts
	for i=#auctionItem.records, 1, -1 do
		local record = auctionItem.records[i]
		if not record.buyout or record.buyout == 0 then
			auctionItem:RemoveRecord(i)
		end
	end
	
	-- check if this auctionItem has records left
	if #auctionItem.records == 0 then return end
	
	auctionItem = private.callback("process", itemString, auctionItem)
	if not auctionItem or #auctionItem.records == 0 then return end
	
	-- store auctionItem
	auctionItem:PopulateCompactRecords()
	private.auctions[itemString] = auctionItem
	
	-- ʕ •ᴥ•ʔ✿ DEBUG: Item added to results ✿ ʕ •ᴥ•ʔ
	
	-- ʕ •ᴥ•ʔ✿ INSTANT RESULTS UPDATE ✿ ʕ •ᴥ•ʔ
	-- Immediately update the results table when we find a matching item
	private:UpdateRT()
	
	-- Enable the results table if this is the first item found
	if private.searchFrame.rt.disabled then
		private.searchFrame.rt:SetDisabled(false)
	end
	
	-- ʕ •ᴥ•ʔ✿ VISUAL FEEDBACK FOR NEW ITEMS ✿ ʕ •ᴥ•ʔ
	-- Flash the status bar briefly to indicate new items found
	if private.searchFrame.statusBar.Flash then
		private.searchFrame.statusBar:Flash()
	end
	
	-- Update status to show items found
	local itemCount = 0
	for _ in pairs(private.auctions) do
		itemCount = itemCount + 1
	end
	
	-- ʕ •ᴥ•ʔ✿ ENHANCED STATUS WITH PROGRESS ✿ ʕ •ᴥ•ʔ
	local progressText = ""
	if scanStatus and scanStatus[1] and scanStatus[2] then
		progressText = format(" (Filter %d/%d)", scanStatus[1] + 1, scanStatus[2])
	end
	
	if itemCount == 1 then
		private.searchFrame.statusBar:SetStatusText(format("Live Results: Found 1 matching item%s...", progressText))
	else
		private.searchFrame.statusBar:SetStatusText(format("Live Results: Found %d matching items%s...", itemCount, progressText))
	end

end

function private:UpdateRT()
	local rtData = {}
	for _, obj in pairs(private.auctions) do
		tinsert(rtData, obj)
	end
	private.searchFrame.rt:SetData(rtData)
end

function private:RemoveAuction(auction, event, itemString)
	if private.auctions[itemString] then
		-- remove this record from the auctionItem
		for i, record in ipairs(private.auctions[itemString].records) do
			if record.parent.itemLink == auction.link and record.buyout == auction.buyout and record.count == auction.count and record.seller == auction.seller then
				private.auctions[itemString]:RemoveRecord(i)
				if #private.auctions[itemString].records == 0 then
					private.auctions[itemString] = nil
				else
					-- handle max quantities on queries
					local query = private.auctions[itemString].query
					if event == "OnBuyout" and query then
						if private.mode == "normal" and (query.maxQuantity or 0) > 0 then
							query.maxQuantity = query.maxQuantity - auction.count
							if TSM.moduleAPICallback then TSM.moduleAPICallback(max(query.maxQuantity, 0), itemString, auction.count) end
							for item, auctionItem in pairs(private.auctions) do
								if auctionItem.query and auctionItem.query.maxQuantity and auctionItem.query.maxQuantity <= 0 then
									private.auctions[item] = nil
								end
							end
							if not private.auctions[itemString] then
								private.controlButtons.buyout:Disable()
								TSMAPI.AuctionControl:HideConfirmation()
								TSM:Printf(L["Maximum quantity purchased for %s."], auction.link)
							end
						elseif private.mode == "destroy" and (TSM.Destroying.maxQuantity or 0) > 0 then
							TSM.Destroying.maxQuantity = TSM.Destroying.maxQuantity - auction.count / auction.destroyingNum
							if TSM.moduleAPICallback then TSM.moduleAPICallback(max(TSM.Destroying.maxQuantity, 0), itemString, auction.count) end
							if TSM.Destroying.maxQuantity <= 0 then
								private.controlButtons.buyout:Disable()
								TSMAPI.AuctionControl:HideConfirmation()
								TSM:Printf(L["Maximum quantity purchased for destroy search."])
							end
						end
					end
				end
				break
			end
		end
	end
	
	local baseItemString = TSMAPI:GetBaseItemString(itemString)
	if baseItemString ~= itemString then
		return private:RemoveAuction(auction, event, baseItemString)
	end
	
	private:UpdateRT()
	local selected = private.searchFrame.rt:GetSelectedAuction()
	if not TSMAPI.AuctionControl:IsConfirmationVisible() then
		-- select the auction that was previously selected
		if not private.searchFrame.rt:GetSelectedAuction() and selected then
			-- we bought all of this auction, so select the new first occurace of this item
			private.searchFrame.rt:SetSelectedAuction(selected.parent:GetItemString())
		end
	end
end

function private:AddPostedAuction(postInfo)
	local link = select(2, TSMAPI:GetSafeItemInfo(postInfo.itemString))
	local texture = select(10, TSMAPI:GetSafeItemInfo(postInfo.itemString))
	if not private.auctions[postInfo.itemString] then
		private.auctions[postInfo.itemString] = TSMAPI.AuctionScan:NewAuctionItem()
		private.auctions[postInfo.itemString]:SetItemLink(link)
		private.auctions[postInfo.itemString]:SetTexture(texture)
	end
	private.auctions[postInfo.itemString]:AddAuctionRecord(postInfo.stackSize, postInfo.bid, 0, postInfo.buyout, 0, nil, UnitName("player"), postInfo.duration)
	private.auctions[postInfo.itemString]:PopulateCompactRecords()
	private:UpdateRT()
	private.searchFrame.rt:SetSelectedAuction()
end