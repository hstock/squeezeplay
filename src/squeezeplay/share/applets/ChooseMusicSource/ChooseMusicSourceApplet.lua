
--[[
=head1 NAME

applets.SlimServers.SlimServersApplet - Menus to edit the Slimserver address

=head1 DESCRIPTION

This applet allows users to define IP addresses for their slimserver.  This is useful if
the automatic discovery process does not work - normally because the server and jive are on different subnets meaning
that UDP broadcasts probing for servers do not get through.

Users may add one or more slimserver IP addresses, these will be probed by the server discovery mechanism
implemented in SlimDiscover.  Removing all explicit server IP addresses returns to broadcast discovery.

=head1 FUNCTIONS


=cut
--]]


-- stuff we use
local pairs, setmetatable, tostring, tonumber  = pairs, setmetatable, tostring, tonumber

local oo            = require("loop.simple")
local string        = require("string")
local table         = require("jive.utils.table")

local Applet        = require("jive.Applet")

local Framework     = require("jive.ui.Framework")
local Event         = require("jive.ui.Event")
local Checkbox      = require("jive.ui.Checkbox")
local Label         = require("jive.ui.Label")
local Button        = require("jive.ui.Button")
local Group         = require("jive.ui.Group")
local SimpleMenu    = require("jive.ui.SimpleMenu")
local Window        = require("jive.ui.Window")
local Textarea      = require("jive.ui.Textarea")
local Textinput     = require("jive.ui.Textinput")
local Keyboard      = require("jive.ui.Keyboard")
local Popup         = require("jive.ui.Popup")
local Icon          = require("jive.ui.Icon")

local debug         = require("jive.utils.debug")
local log           = require("jive.utils.log").logger("applets.setup")

local jnt           = jnt
local jiveMain      = jiveMain
local appletManager = appletManager


module(..., Framework.constants)
oo.class(_M, Applet)


local CONNECT_TIMEOUT = 30


-- service to select server for a player
function selectMusicSource(self, setupNext, titleStyle)
	if setupNext then
		self.setupNext = setupNext
	end
	if titleStyle then
		self.titleStyle = titleStyle
	end
	self:settingsShow()
end


-- main setting menu
function settingsShow(self)

	local window = Window("text_list", self:string("SLIMSERVER_SERVERS"), self.titleStyle)
	local menu = SimpleMenu("menu", items)
	menu:setComparator(SimpleMenu.itemComparatorWeightAlpha)
	window:addWidget(menu)
	window:setAllowScreensaver(false)

	local current = appletManager:callService("getCurrentPlayer")

	self.serverMenu = menu
	self.serverList = {}

	-- subscribe to the jnt so that we get notifications of servers added/removed
	jnt:subscribe(self)


	-- Discover players in this window
	appletManager:callService("discoverPlayers")
	window:addTimer(1000, function() appletManager:callService("discoverPlayers") end)


	-- squeezecenter on the poll list
	log:debug("Polled Servers:")
	local poll = appletManager:callService("getPollList")
	for address,_ in pairs(poll) do
		log:debug("\t", address)
		if address ~= "255.255.255.255" then
			self:_addServerItem(nil, address)
		end
	end


	-- discovered squeezecenters
	log:debug("Discovered Servers:")
	for _,server in appletManager:callService("iterateSqueezeCenters") do
		log:debug("\t", server)
		self:_addServerItem(server, _)
	end

	local item = {
		text = self:string("SLIMSERVER_ADD_SERVER"), 
		sound = "WINDOWSHOW",
		callback = function(event, menuItem)
				   self:_addServer(menuItem)
			   end,
		weight = 2
	}
	menu:addItem(item)

	-- Store the applet settings when the window is closed
	window:addListener(EVENT_WINDOW_POP,
			   function()
				self:storeSettings()
		   	end
	)

	self:tieAndShowWindow(window)
	appletManager:callService("hideConnectingToPlayer")

end


function free(self)
	jnt:unsubscribe(self)
end


function _addServerItem(self, server, address)
	log:debug("\t_addServerItem ", server, " " , address)

	local id
	if server then
		id = server:getIpPort()
	else
		id = address
	end

	log:debug("\tid for this server set to: ", id)

	local currentPlayer    = appletManager:callService("getCurrentPlayer")

	-- Bug 9900
	-- squeezeplay cannot connect to production SN
	if server and server:getIpPort() == "www.squeezenetwork.com" and 
		currentPlayer and currentPlayer:getModel() == "squeezeplay" then
			return
	end

	-- remove existing entry
	if self.serverList[id] then
		self.serverMenu:removeItem(self.serverList[id])
	end

	if server then
		if self.serverList[server:getIpPort()] then
			self.serverMenu:removeItem(self.serverList[server:getIpPort()])
		end

		-- new entry
		local item = {
			text = server:getName(),
			sound = "WINDOWSHOW",
			callback = function()
				self:selectServer(server)
                	end,
			weight = 1,
		}

		self.serverMenu:addItem(item)
		self.serverList[id] = item

		if currentPlayer and currentPlayer:getSlimServer() == server then
			item.style = 'item_checked'
			self.serverMenu:setSelectedItem(item)
		end
	end
end


function _delServerItem(self, server, address)
	-- remove entry
	local id = server or address
	if self.serverList[id] then
		self.serverMenu:removeItem(self.serverList[id])
		self.serverList[id] = nil
	end

	-- new entry if server is on poll list
	if server then
		local poll = appletManager:callService("getPollList")
		local address = server:getIpPort()
		if poll[address] then
			self:_addServerItem(nil, address)
		end
	end
end


function notify_serverNew(self, server)
	self:_addServerItem(server)
end


function notify_serverDelete(self, server)
	self:_delServerItem(server)
end


function _updateServerList(self, player)
	local server = player and player:getSlimServer() and player:getSlimServer():getIpPort()

	for id, item in pairs(self.serverList) do
		if server == id then
			item.style = 'item_checked'
		else
			item.style = nil
		end
		self.serverMenu:updatedItem(item)
	end
end


function notify_playerNew(self, player)
	local currentPlayer = appletManager:callService("getCurrentPlayer")
	if player ~= currentPlayer then
		return
	end

	_updateServerList(self, player)
end


function notify_playerDelete(self, player)
	local currentPlayer = appletManager:callService("getCurrentPlayer")
	if player ~= currentPlayer then
		return
	end

	_updateServerList(self, player)
end


function notify_playerCurrent(self, player)
	_updateServerList(self, player)
end


function notify_playerLoaded(self, player)
	if self.waitForConnect then
		log:info("waiting for ", player, " on ", self.waitForConnect.server)
	end

	if self.waitForConnect and self.waitForConnect.player == player
		and self.waitForConnect.server == player:getSlimServer() then

		self.waitForConnect = nil
		jiveMain:openNodeById('_myMusic')
	end
end


-- server selected in menu
function selectServer(self, server, passwordEntered)
	-- ask for password if the server uses http auth
	if not passwordEntered and server:isPasswordProtected() then
		appletManager:callService("squeezeCenterPassword", server,
			function()
				self:selectServer(server, true)		
			end, self.titleStyle)
		return
	end

	if not server:isCompatible() then
		_serverVersionError(self, server)
		return
	end


	local currentPlayer = appletManager:callService("getCurrentPlayer")

	-- is the player already connected to the server?
	if currentPlayer and currentPlayer:getSlimServer() == server then
		jiveMain:openNodeById('_myMusic')
		return		
	end

	-- connect player to server first
       	self:connectPlayerToServer(currentPlayer, server)
end


-- connect player to server
function connectPlayerToServer(self, player, server)
	log:warn('connectPlayerToServer()')
	-- if connecting to SqueezeNetwork, first check jive is linked
	if server:getPin() then
		appletManager:callService("enterPin", server, nil,
			       function()
				       self:connectPlayerToServer(player, server)
			       end)
		return
	end


	-- stoppage popup
	local window = Popup("waiting_popup")
	window:addWidget(Icon("icon_connecting"))

	local statusLabel = Label("text", self:string("SLIMSERVER_CONNECTING_TO", server:getName()))
	window:addWidget(statusLabel)

	-- disable input, but still allow disconnect_player
	window:ignoreAllInputExcept({"disconnect_player"})


	local timeout = 1
	window:addTimer(1000,
			function()
				-- scan all servers waiting for the player
				appletManager:callService("discoverPlayers")

				-- we detect when the connect to the new server
				-- with notify_playerNew

				timeout = timeout + 1
				if timeout == CONNECT_TIMEOUT then
					self:_connectPlayerFailed(player, server)
				end
			end)

	self:tieAndShowWindow(window)


	-- we are now ready to connect to SqueezeCenter
	if not server:isSqueezeNetwork() then
		self:_doConnectPlayer(player, server)
		return
	end

	-- make sure the player is linked on SqueezeNetwork, this may return an
	-- error if the player can't be linked, for example it is linked to another
	-- account already.
	local cmd = { 'playerRegister', player:getUuid(), player:getId(), player:getName() }

	local playerRegisterSink = function(chunk, err)
		if chunk.error then
			self:_playerRegisterFailed(chunk.error)
		else
			self:_doConnectPlayer(player, server)
		end
	end

	server:userRequest(playerRegisterSink, nil, cmd)
end


function _doConnectPlayer(self, player, server)
	-- tell the player to move servers
	self.waitForConnect = {
		player = player,
		server = server
	}
	player:connectToServer(server)
end


function _playerRegisterFailed(self, error)
	local window = Window("error", self:string("SQUEEZEBOX_PROBLEM"), setupsqueezeboxTitleStyle)
	window:setAllowScreensaver(false)

	local textarea = Textarea("text", error)

	local menu = SimpleMenu("menu",
				{
					{
						text = self:string("SQUEEZEBOX_GO_BACK"),
						sound = "WINDOWHIDE",
						callback = function()
								   window:hide()
							   end

					},
				})


	window:addWidget(textarea)
	window:addWidget(menu)

	self:tieAndShowWindow(window)
end


-- failed to connect player to server
function _connectPlayerFailed(self, player, server)
	local window = Window("error", self:string("SQUEEZEBOX_PROBLEM"), setupsqueezeboxTitleStyle)
	window:setAllowScreensaver(false)

	local menu = SimpleMenu("menu",
				{
					{
						text = self:string("SQUEEZEBOX_GO_BACK"),
						sound = "WINDOWHIDE",
						callback = function()
								   window:hide()
							   end
					},
					{
						text = self:string("SQUEEZEBOX_TRY_AGAIN"),
						sound = "WINDOWSHOW",
						callback = function()
								   self:connectPlayerToServer(player, server)
								   window:hide()
							   end
					},
				})


	local help = Textarea("help_text", self:string("SQUEEZEBOX_PROBLEM_HELP", player:getName(), server:getName()))

	window:addWidget(help)
	window:addWidget(menu)

	self:tieAndShowWindow(window)
end


-- failed to connect player to server
function _serverVersionError(self, server)
	local window = Window("error", self:string("SQUEEZECENTER_VERSION"), setupsqueezeboxTitleStyle)
	window:setAllowScreensaver(false)

	local menu = SimpleMenu("menu", {
		{
			text = self:string("CHOOSE_DIFFERENT_SERVER"),
			sound = "WINDOWHIDE",
			callback = function()
				window:hide()
			end
		},
	})

	local help = Textarea("help_text", self:string("SQUEEZECENTER_VERSION_HELP", server:getName(), server:getVersion()))

	window:addWidget(help)
	window:addWidget(menu)

	-- timer to check if server has been upgraded
	window:addTimer(1000, function()
		if server:isCompatible() then
			self:selectServer(server)
			window:hide(Window.transitionPushLeft)
		end
	end)

	self:tieAndShowWindow(window)
end


function _getOtherServer(self)
	local list = appletManager:callService("getPollList")
	for i,v in pairs(list) do
		if i ~= "255.255.255.255" then
			return i
		end
	end

	return nil
end


-- remove broadcast address & add new address
function _add(self, address)
	log:debug("SlimServerApplet:_add: ", address)

	-- only keep other server and the broadcast address
	local oldAddress = self:_getOtherServer()
	self:_delServerItem(nil, oldAddress)

	local list = {
		["255.255.255.255"] = "255.255.255.255",
		[address] = address
	}

	appletManager:callService("setPollList", list)
	self:getSettings().poll = list
end


-- ip address input window
function _addServer(self, menuItem)
	local window = Window("text_list", menuItem.text)

	local v = Textinput.ipAddressValue(self:_getOtherServer() or "0.0.0.0")
	local input = Textinput("textinput", v,
				function(_, value)
					self:_add(value:getValue())
					self:_addServerItem(nil, value:getValue())

					window:playSound("WINDOWSHOW")
					window:hide(Window.transitionPushLeft)
					return true
				end
	)

	local keyboard = Keyboard("keyboard", "ip")
	local backspace = Button(
		Icon('button_keyboard_back'),
			function()
				local e = Event:new(EVENT_CHAR_PRESS, string.byte("\b"))
				Framework:playSound("SELECT")
				Framework:dispatchEvent(nil, e)
				return EVENT_CONSUME
			end
		)
        local group = Group('keyboard_textinput', { textinput = input, backspace = backspace } )

        window:addWidget(group)
	window:addWidget(keyboard)
	window:focusWidget(group)

	self:tieAndShowWindow(window)
	return window
end


--[[

=head1 LICENSE

Copyright 2007 Logitech. All Rights Reserved.

This file is subject to the Logitech Public Source License Version 1.0. Please see the LICENCE file for details.

=cut
--]]

