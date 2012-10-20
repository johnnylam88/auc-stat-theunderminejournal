--[[--------------------------------------------------------------------
	Auc-Stat-TheUndermineJournal - The Undermine Journal price statistics module
	Copyright (c) 2011, 2012 Johnny C. Lam
	All rights reserved.

	Redistribution and use in source and binary forms, with or without
	modification, are permitted provided that the following conditions
	are met:

	1. Redistributions of source code must retain the above copyright
	   notice, this list of conditions and the following disclaimer.
	2. Redistributions in binary form must reproduce the above copyright
	   notice, this list of conditions and the following disclaimer in the
	   documentation and/or other materials provided with the distribution.

	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
	"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
	TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
	PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS
	BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
	CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
	SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
	INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
	CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
	ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
	POSSIBILITY OF SUCH DAMAGE.
--]]--------------------------------------------------------------------

if not AucAdvanced then return end

local libType, libName = "Stat", "The Undermine Journal"
local lib, parent, private = AucAdvanced.NewModule(libType, libName)
if not lib then return end

local aucPrint, decode, _, _, replicate, empty, get, set, default, debugPrint, fill, _TRANS = AucAdvanced.GetModuleLocals()
local GetFaction = AucAdvanced.GetFaction
local wipe = wipe

-- TUJ data table for market data from most-recently requested item.
local tujData = { }

lib.Processors = {
	config = function(callbackType, ...)
			private.SetupConfigGui(...)
		end,
	load = function(callbackType, addon)
			if private.OnLoad then
				private.OnLoad(addon)
			end
		end,
	tooltip = function(callbackType, ...)
			private.ProcessTooltip(...)
		end,
}

-- lib.GetPrice()
--     (optional) Returns estimated price for item link.
function lib.GetPrice(hyperlink, serverKey)
	if not get("stat.underminejournal.enable") then return end
	if not private.GetInfo(hyperlink, serverKey) then return end
	return tujData.market, tujData.reagentprice, tujData.marketaverage, tujData.marketstddev, tujData.quantity,
		tujData.gemarketmedian, tujData.gemarketmean, tujData.gemarketstddev
end

-- lib.GetPriceColumns()
--     (optional) Returns the column names for GetPrice.
function lib.GetPriceColumns()
	return "Market Latest", "Reagents Latest", "Market Mean", "Market Std Dev", "Qty Available",
		"Global Market Median", "Global Market Mean", "Global Market Std Dev"
end

-- lib.GetPriceArray()
--     Returns pricing and other statistical info in an array.
local priceArray = {}
function lib.GetPriceArray(hyperlink, serverKey)
	if not get("stat.underminejournal.enable") then return end
	if not private.GetInfo(hyperlink, serverKey) then return end

	wipe(priceArray)

	-- Required entries for GetMarketPrice().
	priceArray.price = tujData.marketaverage
	-- (Poorly) approximate "seen" with the current AH quantity.
	priceArray.seen = tujData.quantity

	priceArray.market = tujData.market
	priceArray.quantity = tujData.quantity
	priceArray.reagentprice = tujData.reagentprice
	priceArray.marketaverage = tujData.marketaverage
	priceArray.marketstddev = tujData.marketstddev
	priceArray.gemarketmedian = tujData.gemarketmedian
	priceArray.gemarketaverage = tujData.gemarketaverage
	priceArray.gemarketstddev = tujData.gemarketstddev

	return priceArray
end

-- lib.GetItemPDF()
--     Returns Probability Density Function for item link.
local bellCurve = AucAdvanced.API.GenerateBellCurve()
function lib.GetItemPDF(hyperlink, serverKey)
	if not get("stat.underminejournal.enable") then return end
	if not private.GetInfo(hyperlink, serverKey) then return end

	local mean, stddev = tujData.marketaverage, tujData.marketstddev
	if not mean or not stddev or stddev == 0 then
		-- No available data.
		return
	end

	-- Calculate the lower and upper bounds as +/- 3 standard deviations.
	local lower, upper = (mean - 3 * stddev), (mean + 3 * stddev)

	bellCurve:SetParameters(mean, stddev)
	return bellCurve, lower, upper
end

function private.OnLoad(addon)
	if addon ~= "auc-stat-theunderminejournal" then return end

	default("stat.underminejournal.enable", false)
	default("stat.underminejournal.tooltip", false)
	default("stat.underminejournal.reagents", true)
	default("stat.underminejournal.mean", true)
	default("stat.underminejournal.stddev", true)
	default("stat.underminejournal.gemedian", true)
	default("stat.underminejournal.gemean", true)
	default("stat.underminejournal.gestddev", true)
	default("stat.underminejournal.quantmul", true)

	-- Only run this function once.
	private.OnLoad = nil
end

-- private.GetInfo(hyperlink, serverKey)
--     Returns the market info for the requested item in the tujData table.
function private.GetInfo(hyperlink, serverKey)
	local linkType, itemId, suffix, factor = decode(hyperlink)
	if linkType ~= "item" then return nil end

	wipe(tujData)
	if TUJMarketInfo then
		TUJMarketInfo(itemId, tujData)
	end
	if not tujData.itemid then
		return nil
	end
	tujData.quantity = tujData.quantity or 0

	-- If there are zero quantity and market data is missing, then fallback to using the GE (all realms) data.
	if tujData.quantity == 0 and not tujData.marketaverage then
		tujData.marketaverage = tujData.gemarketaverage
		tujData.marketstddev = tujData.gemarketstddev
	end

	return itemId
end

function private.SetupConfigGui(gui)
	local id = gui:AddTab(lib.libName, lib.libType.." Modules")

	gui:AddHelp(id, "what undermine journal",
		_TRANS('TUJ_Help_UndermineJournal'),
		_TRANS('TUJ_Help_UndermineJournalAnswer')
	)

	-- All options in here will be duplicated in the tooltip frame
	function private.addTooltipControls(id)
		gui:AddControl(id, "Header",     0,    _TRANS('TUJ_Interface_UndermineJournalOptions'))
		gui:AddControl(id, "Note",       0, 1, nil, nil, " ")
		gui:AddControl(id, "Checkbox",   0, 1, "stat.underminejournal.enable", _TRANS('TUJ_Interface_EnableUndermineJournal'))
		gui:AddTip(id, _TRANS('TUJ_HelpTooltip_EnableUndermineJournal'))
		gui:AddControl(id, "Note",       0, 1, nil, nil, " ")

		gui:AddControl(id, "Checkbox",   0, 4, "stat.underminejournal.tooltip", _TRANS('TUJ_Interface_Show'))
		gui:AddTip(id, _TRANS('TUJ_HelpTooltip_Show'))
		gui:AddControl(id, "Checkbox",   0, 6, "stat.underminejournal.reagents", _TRANS('TUJ_Interface_ToggleReagentsLatest'))
		gui:AddTip(id, _TRANS('TUJ_HelpTooltip_ToggleReagentsLatest'))
		gui:AddControl(id, "Checkbox",   0, 6, "stat.underminejournal.mean", _TRANS('TUJ_Interface_ToggleMarketMean'))
		gui:AddTip(id, _TRANS('TUJ_HelpTooltip_ToggleMarketMean'))
		gui:AddControl(id, "Checkbox",   0, 6, "stat.underminejournal.stddev", _TRANS('TUJ_Interface_ToggleMarketStdDev'))
		gui:AddTip(id, _TRANS('TUJ_HelpTooltip_ToggleMarketStdDev'))
		gui:AddControl(id, "Checkbox",   0, 6, "stat.underminejournal.gemedian", _TRANS('TUJ_Interface_ToggleGlobalMarketMedian'))
		gui:AddTip(id, _TRANS('TUJ_HelpTooltip_ToggleGlobalMarketMedian'))
		gui:AddControl(id, "Checkbox",   0, 6, "stat.underminejournal.gemean", _TRANS('TUJ_Interface_ToggleGlobalMarketMean'))
		gui:AddTip(id, _TRANS('TUJ_HelpTooltip_ToggleGlobalMarketMean'))
		gui:AddControl(id, "Checkbox",   0, 6, "stat.underminejournal.gestddev", _TRANS('TUJ_Interface_ToggleGlobalMarketStdDev'))
		gui:AddTip(id, _TRANS('TUJ_HelpTooltip_ToggleGlobalMarketStdDev'))

		gui:AddControl(id, "Checkbox",   0, 4, "stat.underminejournal.quantmul", _TRANS('TUJ_Interface_MultiplyStack'))
		gui:AddTip(id, _TRANS('TUJ_HelpTooltip_MultiplyStack'))
		gui:AddControl(id, "Note",       0, 1, nil, nil, " ")
	end

	local tooltipID = AucAdvanced.Settings.Gui.tooltipID

	private.addTooltipControls(id)
	if tooltipID then private.addTooltipControls(tooltipID) end
end

function private.ProcessTooltip(tooltip, name, hyperlink, quality, quantity, cost, ...)
	-- If the Auctioneer TUJ tooltip is enabled, then disable TUJ's tooltip, and vice versa.
	if not get("stat.underminejournal.tooltip") then
		if TUJTooltip then TUJTooltip(true) end
		return
	else
		if TUJTooltip then TUJTooltip(false) end
	end
	local serverKey = GetFaction()
	if not private.GetInfo(hyperlink, serverKey) then return end

	if not quantity or quantity < 1 then quantity = 1 end
	if not get("stat.underminejournal.quantmul") then quantity = 1 end

	if tujData.market or tujData.reagentprice or tujData.marketaverage or tujData.marketstddev then
		tooltip:AddLine("The Undermine Journal:")
	end
	if tujData.market and tujData.quantity then
		tooltip:AddLine("  " .. _TRANS('TUJ_Tooltip_MarketLatestSeen'):format(tujData.quantity), tujData.market)
	end
	if tujData.market then
		tooltip:AddLine("  " .. _TRANS('TUJ_Tooltip_MarketLatest'):format(quantity), tujData.market * quantity)
	end
	if tujData.reagentprice and get("stat.underminejournal.reagents") then
		tooltip:AddLine("  " .. _TRANS('TUJ_Tooltip_ReagentsLatest'):format(quantity), tujData.reagentprice * quantity)
	end
	if tujData.marketaverage and get("stat.underminejournal.mean") then
		tooltip:AddLine("  " .. _TRANS('TUJ_Tooltip_MarketMean'):format(quantity), tujData.marketaverage * quantity)
	end
	if tujData.marketstddev and get("stat.underminejournal.stddev") then
		tooltip:AddLine("  " .. _TRANS('TUJ_Tooltip_MarketStdDev'):format(quantity), tujData.marketstddev * quantity)
	end
	if tujData.gemarketmedian and get("stat.underminejournal.gemedian") then
		tooltip:AddLine("  " .. _TRANS('TUJ_Tooltip_GlobalMarketMedian'):format(quantity), tujData.gemarketmedian * quantity)
	end
	if tujData.gemarketmean and get("stat.underminejournal.gemean") then
		tooltip:AddLine("  " .. _TRANS('TUJ_Tooltip_GlobalMarketMean'):format(quantity), tujData.gemarketmean * quantity)
	end
	if tujData.gemarketstddev and get("stat.underminejournal.gestddev") then
		tooltip:AddLine("  " .. _TRANS('TUJ_Tooltip_GlobalMarketStdDev'):format(quantity), tujData.gemarketstddev * quantity)
	end
end
