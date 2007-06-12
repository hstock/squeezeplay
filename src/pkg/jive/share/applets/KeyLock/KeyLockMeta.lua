
--[[
=head1 NAME

applets.KeyLock.KeyLockMeta - KeyLock meta-info

=head1 DESCRIPTION

See L<applets.KeyLock.KeyLockApplet>.

=head1 FUNCTIONS

See L<jive.AppletMeta> for a description of standard applet meta functions.

=cut
--]]


local oo            = require("loop.simple")

local AppletMeta    = require("jive.AppletMeta")

local appletManager = appletManager
local jiveMain      = jiveMain


module(...)
oo.class(_M, AppletMeta)


function jiveVersion(self)
	return 0.1, 0.1
end


function registerApplet(self)

	-- KeyLock is a resident Applet
	appletManager:load("KeyLock")
end


--[[

=head1 LICENSE

Copyright 2007 Logitech. All Rights Reserved.

This file is subject to the Logitech Public Source License Version 1.0. Please see the LICENCE file for details.

=cut
--]]

