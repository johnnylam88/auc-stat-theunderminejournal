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

 AucStatTheUndermineJournalLocalizations = {
	enUS = {
		-- Section: Help
		['TUJ_Help_UndermineJournal'] = "What is The Undermine Journal?",
		['TUJ_Help_UndermineJournalAnswer'] = "The Undermine Journal is a website that reads most of a realm's Auction House data about once every hour and packages that market data into an addon. Data is collected for every item on the auction house, except for randomly-enchanted weapons and armor. The data includes the most recent market price, the average price from the past 14 days, and the latest seen quantity available in the Auction House.",

		-- Section: HelpTooltip
		["TUJ_HelpTooltip_EnableUndermineJournal"] = "Allow Auctioneer to use market data from The Undermine Journal.",
		["TUJ_HelpTooltip_MultiplyStack"] = "Toggle display of prices by item or by current stack size.",
		["TUJ_HelpTooltip_Show"] = "Toggle display of stats from The Undermine Journal module on or off.",
		["TUJ_HelpTooltip_ToggleMean"] = "Toggle display of the market average price from the past 14 days.",
		["TUJ_HelpTooltip_ToggleReagents"] = "Toggle display of the total market price of the reagents used to craft the item.",
		["TUJ_HelpTooltip_ToggleStdDev"] = "Toggle display of the market price standard deviation from the past 14 days.",

		-- Section: Interface
		["TUJ_Interface_EnableUndermineJournal"] = "Enable The Undermine Journal Stats",
		["TUJ_Interface_MultiplyStack"] = "Multiply by stack size",
		["TUJ_Interface_Show"] = "Show The Undermine Journal stats in the tooltip",
		["TUJ_Interface_ToggleMean"]	= "Display Mean",
		["TUJ_Interface_ToggleReagents"] = "Display Reagents Price",
		["TUJ_Interface_ToggleStdDev"]	= "Display Standard Deviation",
		["TUJ_Interface_UndermineJournalOptions"] = "The Undermine Journal Options",

		-- Section: Tooltip
		['TUJ_Tooltip_MarketLatest'] = "Market Latest x%d",
		['TUJ_Tooltip_MarketMean'] = "Market Mean x%d",
		['TUJ_Tooltip_MarketStdDev'] = "Market Std Dev x%d",
		['TUJ_Tooltip_ReagentsLatest'] = "Reagents Latest x%d",
	},
}