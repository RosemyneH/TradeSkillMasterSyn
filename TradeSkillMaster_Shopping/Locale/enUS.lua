-- ------------------------------------------------------------------------------ --
--                            TradeSkillMaster_Shopping                           --
--            http://www.curse.com/addons/wow/tradeskillmaster_shopping           --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

-- TradeSkillMaster_Shopping Locale - enUS
-- Please use the localization app on CurseForge to update this
-- http://wow.curseforge.com/addons/TradeSkill-Master/localization/

local L = LibStub("AceLocale-3.0"):NewLocale("TradeSkillMaster_Shopping", "enUS", true)
if not L then return end

L["% DE Value"] = true
L["% Market Value"] = true
L["% Mat Price"] = true
L["% Max Price"] = true
L["% Target Value"] = true
L["% Vendor Price"] = true
L["'%s' has a Shopping operation of '%s' which no longer exists. Shopping will ignore this group until this is fixed."] = true
L["Action"] = true
L["Added '%s' to your favorite searches."] = true
L["Below Custom Price ('0c' to disable)"] = true
L["Below Max Price"] = true
L["Below Vendor Sell Price"] = true
L["Bid Percent"] = true
L["Buyout"] = true
L["Click to search for an item.\nShift-Click to post at market value."] = true
L["Custom Filter"] = true
L["Default Post Undercut Amount"] = true
L["Destroy Mode"] = true
L["Disenchant Search Profit: %s"] = true
L["Done Scanning"] = true
L["Enter what you want to search for in this box. You can also use the following options for more complicated searches."] = true
L["Error creating operation. Operation with name '%s' already exists."] = true
L["Even (5/10/15/20) Stacks Only"] = true
L["Favorite Searches"] = true
L["Forge Level"] = true
L["General Operation Options"] = true
L["General Options"] = true
L["General Settings"] = true
L["General"] = true
L["Give the new operation a name. A descriptive name will help you find this operation later."] = true
L["Hide Grouped Items"] = true
L["If checked, auctions above the max price will be shown."] = true
L["If checked, only auctions posted in even quantities will be considered for purchasing."] = true
L["If checked, the maximum shopping price will be shown in the tooltip for the item."] = true
L["If set, only items which are usable by your character will be included in the results."] = true
L["If set, only items which exactly match the search filter you have set will be included in the results."] = true
L["Import Favorite Search"] = true
L["Import"] = true
L["Inline Filters:|r You can easily add common search filters to your search such as rarity, level, and item type. For example '%sarmor/leather/epic/80/i200/i285|r' will search for all leather armor of epic quality that requires level 80 and has an ilvl between 200 and 285 inclusive. Also, '%sinferno ruby/exact|r' will display only raw inferno rubys (none of the cuts)."] = true
L["Invalid Even Only Filter"] = true
L["Invalid Exact Only Filter"] = true
L["Invalid Filter"] = true
L["Invalid Forge Level"] = true

L["Invalid Item Level"] = true
L["Invalid Item Rarity"] = true
L["Invalid Item SubType"] = true
L["Invalid Item Type"] = true
L["Invalid Max Quantity"] = true
L["Invalid Min Level"] = true
L["Invalid Usable Only Filter"] = true
L["Invalid custom price source for %s. %s"] = true
L["Invalid destroy search: '%s'"] = true
L["Invalid destroy target: '%s'"] = true
L["Invalid target item for destroy search: '%s'"] = true
L["Item Class"] = true
L["Item Level Range:"] = true
L["Item SubClass"] = true
L["Item"] = true
L["Items which are below their maximum price (per their group / Shopping operation) will be displayed in Sniper searches."] = true
L["Items which are below their vendor sell price will be displayed in Sniper searches."] = true
L["Items which are below this custom price will be displayed in Sniper searches."] = true
L["Left-Click to run this search."] = true
L["Left-Click to run this search."] = true
L["Log"] = true
L["Management"] = true
L["Market Value Price Source"] = true
L["Max Disenchant Level"] = true
L["Max Disenchant Search Percent"] = true
L["Max Shopping Price:"] = true
L["Maximum Auction Price (per item)"] = true
L["Maximum Quantity to Buy:"] = true
L["Maximum quantity purchased for %s."] = true
L["Maximum quantity purchased for destroy search."] = true
L["Min Disenchant Level"] = true
L["Minimum Rarity"] = true
L["Multiple Search Terms:|r You can search for multiple things at once by simply separated them with a ';'. For example '%scopper ore; gold ore|r' will search for both copper and gold ore."] = true
L["New Operation"] = true
L["NOTE: The scan must be stopped before you can buy anything."] = true
L["No recent AuctionDB scan data found."] = true
L["Normal Mode"] = true
L["Normal Post Price"] = true
L["Num"] = true
L["Operation Name"] = true
L["Operations"] = true
L["Options"] = true
L["Paste the search you'd like to import into the box below."] = true
L["Paste the search you'd like to import into the box below."] = true
L["Posted a %s with a buyout of %s."] = true
L["Preparing Filter %d / %d"] = true
L["Preparing filters..."] = true
L["Press Ctrl-C to copy this saved search."] = true
L["Price"] = true
L["Quick Posting Duration"] = true
L["Quick Posting Price"] = true
L["Quick Posting"] = true
L["Recent Searches"] = true
L["Relationships"] = true
L["Removed '%s' from your favorite searches."] = true
L["Removed '%s' from your recent searches."] = true
L["Required Level Range:"] = true
L["Reset Filters"] = true
L["Right-Click to favorite this recent search."] = true
L["Right-Click to remove from favorite searches."] = true
L["Saved Searches"] = true
L["Scanning %d / %d (Page 1 / ?)"] = true
L["Scanning %d / %d (Page %d / %d)"] = true
L["Search Filter:"] = true
L["Select the groups which you would like to include in the search."] = true
L["Shift-Left-Click to export this search."] = true
L["Shift-Left-Click to export this search."] = true
L["Shift-Right-Click to remove this recent search."] = true
L["Shopping for auctions including those above the max price."] = true
L["Shopping for auctions with a max price set."] = true
L["Shopping for even stacks including those above the max price"] = true
L["Shopping for even stacks with a max price set."] = true
L["Shopping operations contain settings items which you regularly buy from the auction house."] = true
L["Show Auctions Above Max Price"] = true
L["Show Shopping Max Price in Tooltip"] = true
L["Sidebar Pages:"] = true
L["Skipped the following search term because it's invalid."] = true
L["Skipped the following search term because it's too long. Blizzard does not allow search terms over 63 characters."] = true
L["Sniper Options"] = true
L["Start Disenchant Search"] = true
L["Start Search"] = true
L["Start Sniper"] = true
L["Start Vendor Search"] = true
L["Stop"] = true
L["Stop Sniper"] = true
L["TSM Groups"] = true
L["The Sniper feature will look in real-time for items that have recently been posted to the AH which are worth snatching! You can configure the parameters of Sniper in the Shopping options."] = true
L["The disenchant search looks for items on the AH below their disenchant value. You can set the maximum percentage of disenchant value to search for in the Shopping General options"] = true
L["The duration at which items will be posted via the 'Quick Posting' frame."] = true
L["The highest price per item you will pay for items in affected by this operation."] = true
L["The vendor search looks for items on the AH below their vendor sell price."] = true
L["This is how Shopping calculates the '% Market Value' column in the search results."] = true
L["This is the default price Shopping will suggest to post items at when there's no others posted."] = true
L["This is the maximum item level that the Other > Disenchant search will display results for."] = true
L["This is the maximum percentage of disenchant value that the Other > Disenchant search will display results for."] = true
L["This is the minimum item level that the Other > Disenchant search will display results for."] = true
L["This is the percentage of your buyout price that your bid will be set to when posting auctions with Shopping."] = true
L["This price is used to determine what items will be posted at through the 'Quick Posting' frame."] = true
L["Unknown Filter"] = true
L["Unknown milling search target: '%s'"] = true
L["Vendor Search Profit: %s"] = true
L["Warning: The max disenchant level must be higher than the min disenchant level."] = true
L["Warning: The min disenchant level must be lower than the max disenchant level."] = true
L["What to set the default undercut to when posting items with Shopping."] = true
L["When in destroy mode, you simply enter a target item (ink/pigment, enchanting mat, gem, etc) into the search box to search for everything you can destroy to get that item."] = true
L["When in normal mode, you may run simple and filtered searches of the auction house."] = true