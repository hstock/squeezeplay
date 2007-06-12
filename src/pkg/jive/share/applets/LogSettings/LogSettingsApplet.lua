
--[[
=head1 NAME

applets.LogSettings.LogSettingsApplet - An applet to control Jive log verbosity.

=head1 DESCRIPTION

This applets collects the log categories defined in the running Jive program
and displays each along with their respective verbosity level. Changing the
level is taken into account immediately.

=head1 FUNCTIONS

Applet related methods are described in L<jive.Applet>. 
LogSettingsApplet overrides the following methods:

=cut
--]]


-- stuff we use
local pairs = pairs

local table           = require("table")

local oo              = require("loop.simple")
local logging         = require("logging")

local Applet          = require("jive.Applet")
local Choice          = require("jive.ui.Choice")
local SimpleMenu      = require("jive.ui.SimpleMenu")
local Window          = require("jive.ui.Window")
local jul             = require("jive.utils.log")

local log             = jul.logger("browser")


module(...)
oo.class(_M, Applet)


--[[

=head2 applets.LogSettings.LogSettingsApplet:displayName()

Overridden to return the string "Log Settings"

=cut
--]]
function displayName(self)
	return "Log Settings"
end


-- _gatherLogCategories
-- workhouse that discovers the log categories and for each, creates a suitable
-- table entry to please SimpleMenu
local function _gatherLogCategories()
	
	local res = {}
	
	-- for all items in the (sub)-table
	for k,v in pairs(jul.getCategories()) do
	
		-- create a Choice
		local choice = Choice(
			"choice", 
			{ "Debug", "Info", "Warn", "Error", "Fatal" }, 
			function(obj, selectedIndex)
				log:info("Setting log category ", k, " to ", logging.LEVEL_A[selectedIndex])
				v:setLevel(logging.LEVEL_A[selectedIndex])
			end,
			logging.LEVEL_H[v:getLevel()]
		)
		
		-- insert suitable entry for Choice menu
		table.insert(res, 
			{
				k,
				choice,
			}
		)
	end
	
	return res
end


-- logSettings
-- returns a window with Choices to set the level of each log category
-- the log category are discovered
function logSettings(self, menuItem)

	local logCategories = _gatherLogCategories()
	table.sort(logCategories, function(a,b) return a[1]<b[1] end)

	local window = Window(self:displayName(), menuItem[1])
	window:addWidget(SimpleMenu("menu", logCategories))

	return window
end


--[[

=head1 LICENSE

Copyright 2007 Logitech. All Rights Reserved.

This file is subject to the Logitech Public Source License Version 1.0. Please see the LICENCE file for details.

=cut
--]]

