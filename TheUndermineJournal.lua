--[[
	Auc-Stat-TheUndermineJournal - The Undermine Journal price statistics module

	This is an Auctioneer statistics module that returns price data from 
	The Undermine Journal addon.  You must have either The Undermine Journal
	or The Undermine Journal GE addon installed for this module to have any
	effect.

	Copyright (c) 2011, Johnny C. Lam
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
 --]]
if not AucAdvanced then return end

local libType, libName = "Stat", "The Undermine Journal"
local lib, parent, private = AucAdvanced.NewModule(libType, libName)
if not lib then return end
local print, decode, _, _, replicate, empty, get, set, default, debugPrint, fill, _TRANS = AucAdvanced.GetModuleLocals()
local GetFaction = AucAdvanced.GetFaction

function lib.Processor(callbackType, ...)
	if (callbackType == "config") then
		private.SetupConfigGui(...)
	elseif (callbackType == "load") then
		lib.OnLoad(...)
	elseif (callbackType == "tooltip") then
		lib.ProcessTooltip(...)
	end
end

lib.Processors = {}
lib.Processors.tooltip = lib.Processor
lib.Processors.config = lib.Processor

function lib.GetPrice(hyperlink, serverKey)
	if not get("stat.underminejournal.enable") then return end
	if not private.IsTheUndermineJournalLoaded() then return end
	serverKey = serverKey or GetFaction()

	local linkType, itemId, suffix, factor = decode(hyperlink)
	if (linkType ~= "item") then return end

	local dta = {}
	TUJMarketInfo(itemId, dta)
	return dta.market, dta.reagentprice, dta.marketaverage, dta.marketstddev, dta.quantity
end

function lib.GetPriceColumns()
	if not private.IsTheUndermineJournalLoaded() then return end
	return "Market Latest", "Reagents Latest", "Market Mean", "Market Std Dev", "Qty Available"
end

local array = {}
function lib.GetPriceArray(hyperlink, serverKey)
	if not get("stat.underminejournal.enable") then return end
	if not private.IsTheUndermineJournalLoaded() then return end

	local price, reagents, mean, stddev, qty = lib.GetPrice(hyperlink, serverKey)

	wipe(array)
	array.price = price
	array.seen = qty and qty or 0	-- (poorly) approximate "seen" with the current AH quantity.

	array.reagents = reagents
	array.mean = mean
	array.stddev = stddev
	array.qty = qty

	return array
end

local bellCurve = AucAdvanced.API.GenerateBellCurve()
function lib.GetItemPDF(hyperlink, serverKey)
	if not get("stat.underminejournal.enable") then return end

	local _, _, mean, stddev, _ = lib.GetPrice(hyperlink, serverKey)
	if not mean or not stddev or mean == 0 or stddev == 0 then
		return	-- no available data
	end

	-- Calculate the lower and upper bounds as +/- 3 standard deviations
	local lower, upper = (mean - 3 * stddev), (mean + 3 * stddev)

	bellCurve:SetParameters(mean, stddev)
	return bellCurve, lower, upper
end

function lib.IsValidAlgorithm()
	if not get("stat.underminejournal.enable") then return false end
	if not private.IsTheUndermineJournalLoaded() then return false end
	return true
end

function lib.OnLoad(addon)
	default("stat.underminejournal.tooltip", false)
	default("stat.underminejournal.reagents", true)
	default("stat.underminejournal.mean", true)
	default("stat.underminejournal.stddev", true)
	default("stat.underminejournal.quantmul", true)
	default("stat.underminejournal.enable", false)
end

-- Localization via Auctioneer's Babylonian; from Auc-Advanced/CoreUtil.lua
local Babylonian = LibStub("Babylonian")
assert(Babylonian, "Babylonian is not installed")
local babylonian = Babylonian(AucStatTheUndermineJournalLocalizations)
_TRANS = function (stringKey)
	local locale = get("SelectedLocale")	-- locales are user choose-able
	-- translated key or english Key or Raw Key
	return babylonian(locale, stringKey) or babylonian[stringKey] or stringKey
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
		gui:AddControl(id, "Checkbox",   0, 6, "stat.underminejournal.reagents", _TRANS('TUJ_Interface_ToggleReagents'))
		gui:AddTip(id, _TRANS('TUJ_HelpTooltip_ToggleReagents'))
		gui:AddControl(id, "Checkbox",   0, 6, "stat.underminejournal.mean", _TRANS('TUJ_Interface_ToggleMean'))
		gui:AddTip(id, _TRANS('TUJ_HelpTooltip_ToggleMean'))
		gui:AddControl(id, "Checkbox",   0, 6, "stat.underminejournal.stddev", _TRANS('TUJ_Interface_ToggleStdDev'))
		gui:AddTip(id, _TRANS('TUJ_HelpTooltip_ToggleStdDev'))

		gui:AddControl(id, "Checkbox",   0, 4, "stat.underminejournal.quantmul", _TRANS('TUJ_Interface_MultiplyStack'))
		gui:AddTip(id, _TRANS('TUJ_HelpTooltip_MultiplyStack'))
		gui:AddControl(id, "Note",       0, 1, nil, nil, " ")
	end

	local tooltipID = AucAdvanced.Settings.Gui.tooltipID

	private.addTooltipControls(id)
	if tooltipID then private.addTooltipControls(tooltipID) end
end

function lib.ProcessTooltip(tooltip, name, hyperlink, quality, quantity, cost, ...)
	if not get("stat.underminejournal.enable") then return end
	if not get("stat.underminejournal.tooltip") then return end
	local serverKey = GetFaction()
	local price, reagents, mean, stddev, qty = lib.GetPrice(hyperlink, serverKey)
	if not price then return end

	if not quantity or quantity < 1 then quantity = 1 end
	if not get("stat.underminejournal.quantmul") then quantity = 1 end

	tooltip:AddLine("The Undermine Journal Prices:")
	tooltip:AddLine("  " .. _TRANS('TUJ_Tooltip_MarketLatest'):format(quantity), price * quantity)
	if reagents and get("stat.underminejournal.reagents") then
		tooltip:AddLine("  " .. _TRANS('TUJ_Tooltip_ReagentsLatest'):format(quantity), reagents * quantity)
	end
	if mean and get("stat.underminejournal.mean") then
		tooltip:AddLine("  " .. _TRANS('TUJ_Tooltip_MarketMean'):format(quantity), mean * quantity)
	end
	if stddev and get("stat.underminejournal.stddev") then
		tooltip:AddLine("  " .. _TRANS('TUJ_Tooltip_MarketStdDev'):format(quantity), stddev * quantity)
	end
end

function private.IsTheUndermineJournalLoaded()
	if TUJMarketInfo then
		return TUJMarketInfo(0)		-- true if TUJ market data is available; false otherwise
	else
		return false
	end
end