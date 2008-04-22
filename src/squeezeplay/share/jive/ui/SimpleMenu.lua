--[[
=head1 NAME

jive.ui.SimpleMenu - A simple menu widget.

=head1 DESCRIPTION

A simple menu widget, extends L<jive.ui.Menu>.

=head1 SYNOPSIS

 -- Create a new menu
 local menu = jive.ui.Menu("menu",
		   {
			   {
				   id = 'uniqueString',
				   text = "Item 1",
				   sound = "WINDOWSHOW",
				   icon = widget1,
				   callback = function1
			   ),
			   {
				   id = 'anotherUniqueString',
				   text = "Item 2",
				   sound = "WINDOWSHOW",
				   icon = widget2,
				   callback = function2
			   ),
		   })

 -- Sort the menu alphabetically
 menu:setComparator(SimpleMenu.itemComparatorAlpha)

=head1 STYLE

The Label includes the following style parameters in addition to the widgets basic parameters.

=over

B<itemHeight> : the height of each menu item.

=head1 METHODS

=cut
--]]


-- stuff we use
local _assert, ipairs, string, tostring, type = _assert, ipairs, string, tostring, type


local oo              = require("loop.simple")
local debug           = require("jive.utils.debug")

local Group           = require("jive.ui.Group")
local Label           = require("jive.ui.Label")
local Icon            = require("jive.ui.Icon")
local Menu            = require("jive.ui.Menu")
local Widget          = require("jive.ui.Widget")

local table           = require("jive.utils.table")
local log             = require("jive.utils.log").logger("ui")

local EVENT_ACTION    = jive.ui.EVENT_ACTION
local EVENT_FOCUS_GAINED = jive.ui.EVENT_FOCUS_GAINED
local EVENT_FOCUS_LOST   = jive.ui.EVENT_FOCUS_LOST

local EVENT_CONSUME   = jive.ui.EVENT_CONSUME
local EVENT_UNUSED    = jive.ui.EVENT_UNUSED


-- our class
module(...)
oo.class(_M, Menu)

-- _coerce
-- returns value coerced between 1 and max
local function _coerce(value, max)
	if value < 1 then 
		return 1
	elseif value > max then
		return max
	end
	return value
end


-- _safeIndex
-- returns array[index] if index is in array bounds, nil otherwise
local function _safeIndex(array, index)
	if index and index>0 and index<=#array then
		return array[index]
	end
--	log:warn("_safeIndex failed - ", debug.traceback())
	return nil
end


-- _itemRenderer
-- updates the widgetList ready for the menu to be rendered
local function _itemRenderer(menu, list, widgetList, indexList, size)
	for i = 1,size do
		if indexList[i] ~= nil then
			local item = list[indexList[i]]

			local icon = item.icon or menu.icons[i]
			if icon == nil then
				icon = Icon("icon")
				menu.icons[i] = icon
			end


			if widgetList[i] == nil then
				widgetList[i] = Group(item.style or "item", {
					text = Label("text", item.text),
					check = Icon("check"),
					icon = icon,
				})
			else
				widgetList[i]:setStyle(item.style or "item")
				widgetList[i]:setWidgetValue("text", item.text)
				widgetList[i]:setWidget("icon", icon)
			end
		end
	end
end


-- _itemListener
-- called for menu item events
local function _itemListener(menu, list, menuItem, index, event)
	local item = list[index]

	if( item == nil) then
		return EVENT_UNUSED
	end

	if event:getType() == EVENT_ACTION and item.callback then
		if item.sound then
			menuItem:playSound(item.sound)
		end
		return item.callback(event, item) or EVENT_CONSUME
	
	elseif event:getType() == EVENT_FOCUS_GAINED and item.focusGained then
		return item.focusGained(event, item) or EVENT_CONSUME

	elseif event:getType() == EVENT_FOCUS_LOST and item.focusLost then
		return item.focusLost(event, item) or EVENT_CONSUME

	end

	return EVENT_UNUSED
end


function __init(self, style, items)
	_assert(type(style) == "string")

	local obj = oo.rawnew(self, Menu(style, _itemRenderer, _itemListener))
	obj.items = items or {}
	obj.icons = {}

	obj:setItems(obj.items, #obj.items)

	return obj
end


--[[

=head2 jive.ui.Menu:setComparator(comp)

Sets the menu comparator to I<comp> used to sort the menu items. By default
the menu is not sorted and elements will be displayed in the order they are
added.

--]]
function setComparator(self, comp)
	self.comparator = comp

	if comp ~= nil then
		table.sort(self.items, comp)
	end
end


--[[

=head2 jive.ui.Menu.itemComparatorAlpha

Item comparator to sort items alphabetically (i.e. using item.text).

--]]
function itemComparatorAlpha(a, b)
	return tostring(a.text) < tostring(b.text)
end


--[[

=head2 jive.ui.Menu.itemComparatorWeightAlpha

Item comparator to sort items using item.weight as a primary key, and
item.text as a secondary key.

--]]
function itemComparatorWeightAlpha(a, b)
	local w = a.weight - b.weight

	if w == 0 then
		return tostring(a.text) < tostring(b.text)
	end
	return (w < 0)
end


--[[

=head2 jive.ui.Menu:numItems()

Returns the top number of items in the menu.

=cut
--]]
function numItems(self)
	return #self.items
end


--[[

=head2 jive.ui.Menu:getItem(index)

Returns the item at the index I<index>.

=cut
--]]
function getItem(self, index)
	_assert(type(index) == "number")

	return _safeIndex(self.items, index)
end


--[[

=head2 jive.ui.Menu:iterator()

Returns an interator over all items in the menu.

=cut
--]]
function iterator(self)
	return ipairs(self.items)
end


--[[

=head2 jive.ui.Menu:getIndex(item)

Returns the index of item I<item>, or nil if it is not in this menu.

=cut
--]]
function getIndex(self, item)
	for k,v in ipairs(self.items) do
		if item == v then
			return k
		end
	end

	return nil
end

--[[

=head2 jive.ui.Menu:getIdIndex(id)

Returns the index of item given by I<id>, or nil if it is not in this menu.

=cut
--]]
function getIdIndex(self, id)
	for k,v in ipairs(self.items) do
		if id == v.id then
			return k
		end
	end

	return nil
end


--[[

=head2 jive.ui.Menu:getTextIndex(item)

Returns the index of item given by I<text>, or nil if it is not in this menu.

=cut
--]]
function getTextIndex(self, text)
	for k,v in ipairs(self.items) do
		if text == v.text then
			return k
		end
	end

	return nil
end


--[[

=head2 jive.ui.Menu:setItems(items)

Efficiently replaces the current menu items, with I<items>.

=cut
--]]
function setItems(self, items)
	self.items = items

	Menu.setItems(self, self.items, #self.items)
end



--[[

=head2 jive.ui.Menu:addItem(item)

Add I<item> to the end of the menu. Returns the index of the item added.

I<item> is a table with the following keys: 
- id (optional), a unique key for this menu item
- text,
- icon (optional), 
- weight (optional), see jive.ui.Menu.itemComparatorWeightAlpha,
- callback (optional), a function performing whatever the menu is supposed to do, having prototype:
   function(event, item) returning nil/jive.ui.EVENT_CONSUME/QUIT/UNUSED

For convenience, EVENT_CONSUME is assumed if the function returns nothing
=cut
--]]
function addItem(self, item)
	if self.comparator then
		for i=1,#self.items do
			local x = self.items[i]

			if self.comparator(item, x) then
				return self:insertItem(item, i)
			end
		end
	end

	return self:insertItem(item, nil)
end


--[[

=head2 jive.ui.Menu:insertItem(item, index)

Insert I<item> into the menu at I<index>. Returns the index of the item added.
See addItem for the definition of I<item>.

=cut
--]]
function insertItem(self, item, index)
	_assert(index == nil or type(index) == "number")

	-- replace existing item if the id matches
	if item.id then
		for i,v in ipairs(self.items) do
			if item.id == v.id then
				self.items[i] = item
				self:reLayout()
				return i
			end
		end
	end

	if index == nil then
		table.insert(self.items, item)
		index = #self.items
	else
		table.insert(self.items, _coerce(index, #self.items), item)
	end

	Menu.setItems(self, self.items, #self.items, index, index)

	if self.selected and index <= self.selected then
		self.selected = self.selected + 1
	end

	return index
end


--[[

=head2 jive.ui.Menu:replaceIndex(item, index)

Replace the item at I<index> with I<item>.

=cut
--]]
function replaceIndex(self, item, index)
	_assert(index and type(index) == "number")

	if _safeIndex(self.items, index) then
		self.items[index] = item
		Menu.setItems(self, self.items, #self.items, index, index)
	end
end


--[[

=head2 jive.ui.Menu:removeIndex(index)

Remove the item at I<index> from the menu. Returns the item removed from
the menu.

=cut
--]]
function removeIndex(self, index)
	_assert(type(index) == "number")

	if _safeIndex(self.items, index) then
		local item = table.remove(self.items, index)
		if item ~= nil then
			if self.selected and index < self.selected then
				if #self.items == 0 then
					self.selected = nil
				else
					self.selected = self.selected - 1
				end
			end

			Menu.setItems(self, self.items, #self.items, index, #self.items)
		end

		return item
	end
	return nil
end


--[[

=head2 jive.ui.Menu:removeItem(item)

Remove I<item> from the menu. Returns the item removed from the menu.

=cut
--]]
function removeItem(self, item)
	local index = self:getIndex(item)
	if index ~= nil then
		return self:removeIndex(index)
	else
		return nil
	end
end


--[[

=head2 jive.ui.Menu:removeItemById(id)

Remove I<item> given by I<id> from the menu. Returns the item removed from the menu.

=cut
--]]
function removeItemById(self, id)
	local index = self:getIdIndex(id)
	if index ~= nil then
		return self:removeIndex(index)
	else
		return nil
	end
end


--[[

=head2 jive.ui.Menu:updatedIndex(index)

Notifies the menu with the items at I<index> has changed. If neccessary this will cause the menu to be redrawn.

=cut
--]]
function updatedIndex(self, index)
	_assert(type(index) == "number")

	Menu.setItems(self, self.items, #self.items, index, index)
end


--[[

=head2 jive.ui.Menu:updatedItem(item)

Notifies the menu with the item I<item> has changed. If neccessary this will cause the menu to be redrawn.

=cut
--]]
function updatedItem(self, item)
	local index = self:getIndex(item)
	if index ~= nil then
		self:updatedIndex(index)
	end
end


function setSelectedItem(self, item)
	local index = self:getIndex(item)
	if index ~= nil then
		self:setSelectedIndex(index)
	end
end

function _skin(self)
	-- re-sort in case the locale has changed
	if self.comparator ~= nil then
		table.sort(self.items, self.comparator)
	end

	Menu._skin(self)
end


function __tostring(self)
	return "SimpleMenu()"
end


--[[

=head1 LICENSE

Copyright 2007 Logitech. All Rights Reserved.

This file is subject to the Logitech Public Source License Version 1.0. Please see the LICENCE file for details.

=cut
--]]

