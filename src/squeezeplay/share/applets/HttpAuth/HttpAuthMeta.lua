
--[[
=head1 NAME

applets.HttpAuth.HttpAuthMeta - HttpAuth meta-info

=head1 DESCRIPTION

See L<applets.HttpAuth.HttpAuthMeta>.

=head1 FUNCTIONS

See L<jive.AppletMeta> for a description of standard applet meta functions.

=cut
--]]

local pairs = pairs

local oo            = require("loop.simple")

local AppletMeta    = require("jive.AppletMeta")
local Framework     = require("jive.ui.Framework")

local SlimServer    = require("jive.slim.SlimServer")

local appletManager = appletManager
local jiveMain      = jiveMain

module(...)
oo.class(_M, AppletMeta)

function jiveVersion(meta)
	return 1, 1
end

function defaultSettings(meta)
        return { }
end

function registerApplet(meta)
	local settings = meta:getSettings()

	for servername, cred in pairs(settings) do
		SlimServer:setCredentials(cred, servername)
	end
end

--[[

=head1 LICENSE

Copyright 2007 Logitech. All Rights Reserved.

This file is subject to the Logitech Public Source License Version 1.0. Please see the LICENCE file for details.

=cut
--]]