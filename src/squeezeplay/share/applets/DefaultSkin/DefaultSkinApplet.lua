
--[[
=head1 NAME

applets.DefaultSkin.DefaultSkinApplet - The default Jive skin.

=head1 DESCRIPTION

This applet implements the default Jive skin. It can
be used as a model to provide alternate skins for Jive.

=head1 FUNCTIONS

Applet related methods are described in L<jive.Applet>. 
DefaultSkinApplet overrides the following methods:

=cut
--]]


-- stuff we use
local ipairs, pairs, setmetatable, type = ipairs, pairs, setmetatable, type

local oo                     = require("loop.simple")

local Applet                 = require("jive.Applet")
local Audio                  = require("jive.ui.Audio")
local Font                   = require("jive.ui.Font")
local Framework              = require("jive.ui.Framework")
local Icon                   = require("jive.ui.Icon")
local Label                  = require("jive.ui.Label")
local RadioButton            = require("jive.ui.RadioButton")
local RadioGroup             = require("jive.ui.RadioGroup")
local SimpleMenu             = require("jive.ui.SimpleMenu")
local Surface                = require("jive.ui.Surface")
local Textarea               = require("jive.ui.Textarea")
local Tile                   = require("jive.ui.Tile")
local Window                 = require("jive.ui.Window")

local table                  = require("jive.utils.table")
local debug                  = require("jive.utils.debug")
local autotable              = require("jive.utils.autotable")

local log = require("jive.utils.log").logger("ui")

local LAYER_FRAME            = jive.ui.LAYER_FRAME
local LAYER_CONTENT_ON_STAGE = jive.ui.LAYER_CONTENT_ON_STAGE

local LAYOUT_NORTH           = jive.ui.LAYOUT_NORTH
local LAYOUT_EAST            = jive.ui.LAYOUT_EAST
local LAYOUT_SOUTH           = jive.ui.LAYOUT_SOUTH
local LAYOUT_WEST            = jive.ui.LAYOUT_WEST
local LAYOUT_CENTER          = jive.ui.LAYOUT_CENTER
local LAYOUT_NONE            = jive.ui.LAYOUT_NONE

local WH_FILL                = jive.ui.WH_FILL

local appletManager          = appletManager


module(..., Framework.constants)
oo.class(_M, Applet)


-- Define useful variables for this skin
local imgpath = "applets/DefaultSkin/images/"
local fontpath = "fonts/"

-- define a local function to make it easier to create icons.
local function _icon(x, y, img)
	local var = {}
	var.x = x
	var.y = y
	var.img = Surface:loadImage(imgpath .. img)
	var.layer = LAYER_FRAME
	var.position = LAYOUT_SOUTH

	return var
end

-- defines a new style that inherrits from an existing style
local function _uses(parent, value)
	local style = {}
	setmetatable(style, { __index = parent })

	for k,v in pairs(value or {}) do
		if type(v) == "table" and type(parent[k]) == "table" then
			-- recursively inherrit from parent style
			style[k] = _uses(parent[k], v)
		else
			style[k] = v
		end
	end

	return style
end


-- skin
-- The meta arranges for this to be called to skin Jive.
function skin(self, s)
	local screenWidth, screenHeight = Framework:getScreenSize()

	-- Images and Tiles
	local iconBackground = 
		Tile:loadHTiles({
					imgpath .. "border_l.png",
					imgpath .. "border.png",
					imgpath .. "border_r.png",
			       })

	local titleBox =
		Tile:loadTiles({
				       imgpath .. "titlebox.png",
				       imgpath .. "titlebox_tl.png",
				       imgpath .. "titlebox_t.png",
				       imgpath .. "titlebox_tr.png",
				       imgpath .. "titlebox_r.png",
				       imgpath .. "titlebox_br.png",
				       imgpath .. "titlebox_b.png",
				       imgpath .. "titlebox_bl.png",
				       imgpath .. "titlebox_l.png"
			       })

	local selectionBox =
		Tile:loadTiles({
				       imgpath .. "menu_selection_box.png",
				       imgpath .. "menu_selection_box_tl.png",
				       imgpath .. "menu_selection_box_t.png",
				       imgpath .. "menu_selection_box_tr.png",
				       imgpath .. "menu_selection_box_r.png",
				       imgpath .. "menu_selection_box_br.png",
				       imgpath .. "menu_selection_box_b.png",
				       imgpath .. "menu_selection_box_bl.png",
				       imgpath .. "menu_selection_box_l.png"
			       })

	local albumSelectionBox =
		Tile:loadTiles({
				       imgpath .. "menu_album_selection.png",
				       imgpath .. "menu_album_selection_tl.png",
				       imgpath .. "menu_album_selection_t.png",
				       imgpath .. "menu_album_selection_tr.png",
				       imgpath .. "menu_album_selection_r.png",
				       imgpath .. "menu_album_selection_br.png",
				       imgpath .. "menu_album_selection_b.png",
				       imgpath .. "menu_album_selection_bl.png",
				       imgpath .. "menu_album_selection_l.png"
			       })

	local helpBox = 
		Tile:loadTiles({
				       imgpath .. "helpbox.png",
				       imgpath .. "helpbox_tl.png",
				       imgpath .. "helpbox_t.png",
				       imgpath .. "helpbox_tr.png",
				       imgpath .. "helpbox_r.png",
				       nil,
				       nil,
				       nil,
				       imgpath .. "helpbox_l.png",
			       })

	local scrollBackground =
		Tile:loadVTiles({
					imgpath .. "scrollbar_bkgroundtop.png",
					imgpath .. "scrollbar_bkgroundmid.png",
					imgpath .. "scrollbar_bkgroundbottom.png",
				})

	local scrollBar = 
		Tile:loadVTiles({
					imgpath .. "scrollbar_bodytop.png",
					imgpath .. "scrollbar_bodymid.png",
					imgpath .. "scrollbar_bodybottom.png",
			       })

	local sliderBackground = 
		Tile:loadHTiles({
					imgpath .. "slider_bkgrd_l.png",
					imgpath .. "slider_bkgrd.png",
					imgpath .. "slider_bkgrd_r.png",
			       })

	local sliderBar = 
		Tile:loadHTiles({
					imgpath .. "slider_fill_l.png",
					imgpath .. "slider_fill.png",
					imgpath .. "slider_fill_r.png",
			       })

	local volumeBar =
		Tile:loadHTiles({
					imgpath .. "volume_fill_l.png",
					imgpath .. "volume_fill.png",
					imgpath .. "volume_fill_r.png",
				})

	local volumeBackground =
		Tile:loadHTiles({
					imgpath .. "volume_bkgrd_l.png",
					imgpath .. "volume_bkgrd.png",
					imgpath .. "volume_bkgrd_r.png",
			       })

	local popupMask = Tile:fillColor(0x000000e5)

	local popupBox =
		Tile:loadTiles({
				       imgpath .. "popupbox.png",
				       imgpath .. "popupbox_tl.png",
				       imgpath .. "popupbox_t.png",
				       imgpath .. "popupbox_tr.png",
				       imgpath .. "popupbox_r.png",
				       imgpath .. "popupbox_br.png",
				       imgpath .. "popupbox_b.png",
				       imgpath .. "popupbox_bl.png",
				       imgpath .. "popupbox_l.png"
			       })


	local textinputBackground =
		Tile:loadHTiles({
				       imgpath .. "text_entry_bkgrd_l.png",
				       imgpath .. "text_entry_bkgrd.png",
				       imgpath .. "text_entry_bkgrd_r.png",
			       })

	local softButtonBackground =
		Tile:loadTiles({
				       imgpath .. "button.png",
				       imgpath .. "button_tl.png",
				       imgpath .. "button_t.png",
				       imgpath .. "button_tr.png",
				       imgpath .. "button_r.png",
				       imgpath .. "button_br.png",
				       imgpath .. "button_b.png",
				       imgpath .. "button_bl.png",
				       imgpath .. "button_l.png"
				})

	local textinputWheel = Tile:loadImage(imgpath .. "text_entry_select.png")

	local textinputCursor = Tile:loadImage(imgpath .. "text_entry_letter.png")


	local TEXT_COLOR = { 0xE7, 0xE7, 0xE7 }
	local TEXT_SH_COLOR = { 0x37, 0x37, 0x37 }

	local SELECT_COLOR = { 0x00, 0x00, 0x00 }
	local SELECT_SH_COLOR = { }

	local FONT_NAME = "FreeSans"
	local BOLD_PREFIX = "Bold"

	local FONT_13px = Font:load(fontpath .. FONT_NAME .. ".ttf", 14)
	local FONT_15px = Font:load(fontpath .. FONT_NAME .. ".ttf", 16)

	local FONT_BOLD_13px = Font:load(fontpath .. FONT_NAME .. BOLD_PREFIX .. ".ttf", 14)
	local FONT_BOLD_15px = Font:load(fontpath .. FONT_NAME .. BOLD_PREFIX .. ".ttf", 16)
	local FONT_BOLD_18px = Font:load(fontpath .. FONT_NAME .. BOLD_PREFIX .. ".ttf", 20)
	local FONT_BOLD_20px = Font:load(fontpath .. FONT_NAME .. BOLD_PREFIX .. ".ttf", 22)
	local FONT_BOLD_22px = Font:load(fontpath .. FONT_NAME .. BOLD_PREFIX .. ".ttf", 24)
	local FONT_BOLD_200px = Font:load(fontpath .. FONT_NAME .. BOLD_PREFIX .. ".ttf", 200)


	-- Iconbar definitions, each icon needs an image and x,y
	s.iconBackground = {}
	s.iconBackground.x = 0
	s.iconBackground.y = screenHeight - 30
	s.iconBackground.w = screenWidth
	s.iconBackground.h = 30
	s.iconBackground.border = { 4, 0, 4, 0 }
	s.iconBackground.bgImg = iconBackground
	s.iconBackground.layer = LAYER_FRAME
	s.iconBackground.position = LAYOUT_SOUTH

	-- play/stop/pause
	s.iconPlaymodeOFF = _icon(9, screenHeight - 30, "icon_mode_off.png")
	s.iconPlaymodeSTOP = _icon(9, screenHeight - 30, "icon_mode_off.png")
	s.iconPlaymodePLAY = _icon(9, screenHeight - 30, "icon_mode_play.png")
	s.iconPlaymodePAUSE = _icon(9, screenHeight - 30, "icon_mode_pause.png")

	-- repeat off/repeat track/repeat playlist
	s.iconRepeatOFF = _icon(41, screenHeight - 30, "icon_repeat_off.png")
	s.iconRepeat0 = _icon(41, screenHeight - 30, "icon_repeat_off.png")
	s.iconRepeat1 = _icon(41, screenHeight - 30, "icon_repeat_song.png")
	s.iconRepeat2 = _icon(41, screenHeight - 30, "icon_repeat.png")

	-- shuffle off/shuffle album/shuffle playlist
	s.iconShuffleOFF = _icon(75, screenHeight - 30, "icon_shuffle_off.png")
	s.iconShuffle0 = _icon(75, screenHeight - 30, "icon_shuffle_off.png")
	s.iconShuffle1 = _icon(75, screenHeight - 30, "icon_shuffle.png")
	s.iconShuffle2 = _icon(75, screenHeight - 30, "icon_shuffle_album.png")

	-- wireless status
	s.iconWireless1 = _icon(107, screenHeight - 30, "icon_wireless_1.png")
	s.iconWireless2 = _icon(107, screenHeight - 30, "icon_wireless_2.png")
	s.iconWireless3 = _icon(107, screenHeight - 30, "icon_wireless_3.png")
	s.iconWireless4 = _icon(107, screenHeight - 30, "icon_wireless_4.png")
	s.iconWirelessERROR = _icon(107, screenHeight - 30, "icon_wireless_off.png")
	s.iconWirelessSERVERERROR = _icon(107, screenHeight - 30, "icon_wireless_noserver.png")

	-- battery status
	s.iconBatteryAC = _icon(137, screenHeight - 30, "icon_battery_ac.png")

	s.iconBatteryCHARGING = _icon(137, screenHeight - 30, "icon_battery_charging.png")
	s.iconBattery0 = _icon(137, screenHeight - 30, "icon_battery_0.png")
	s.iconBattery1 = _icon(137, screenHeight - 30, "icon_battery_1.png")
	s.iconBattery2 = _icon(137, screenHeight - 30, "icon_battery_2.png")
	s.iconBattery3 = _icon(137, screenHeight - 30, "icon_battery_3.png")
	s.iconBattery4 = _icon(137, screenHeight - 30, "icon_battery_4.png")

	s.iconBatteryCHARGING.frameRate = 1
	s.iconBatteryCHARGING.frameWidth = 37


	-- time
	s.iconTime = {}
	s.iconTime.x = screenWidth - 60
	s.iconTime.y = screenHeight - 34
	s.iconTime.h = 34
	s.iconTime.layer = LAYER_FRAME
	s.iconTime.position = LAYOUT_SOUTH
	s.iconTime.font = Font:load(fontpath .. "FreeSansBold.ttf", 12)
	s.iconTime.fg = TEXT_COLOR


	-- Window title, this is a Label
	-- black text with a background image
	s.title = {}
	s.title.border = 4
	s.title.position = LAYOUT_NORTH
	s.title.bgImg = titleBox
	s.title.text = {}
	s.title.text.padding = { 10, 8, 8, 8 }
	s.title.text.align = "top-left"
	s.title.text.font = FONT_BOLD_18px
	s.title.text.fg = SELECT_COLOR


	-- Menu with three basic styles: normal, selected and locked
	-- First define the dimesions of the menu
	s.menu = {}
	s.menu.padding = { 4, 2, 4, 2 }
	s.menu.itemHeight = 27
	s.menu.fg = {0xbb, 0xbb, 0xbb }
	s.menu.font = FONT_BOLD_200px

	-- menu item
	s.item = {}
	s.item.order = { "text", "icon" }
	s.item.padding = { 9, 6, 6, 6 }
	s.item.text = {}
	s.item.text.w = WH_FILL
	s.item.text.font = FONT_BOLD_15px
	s.item.text.fg = TEXT_COLOR
	s.item.text.sh = TEXT_SH_COLOR

	-- menu item with no right icon
	s.itemNoAction = _uses(s.item)

	-- menu items for using different selection icons
	s.itemplay = {}
	s.itemplay = _uses(s.item)
	s.itemadd  = {}
	s.itemadd = _uses(s.item)

	-- checked menu item
	s.checked =
		_uses(s.item, {
			      order = { "text", "check", "icon" },
			      check = {
				      img = Surface:loadImage(imgpath .. "menu_check.png"),
				      align = "right"

			      }
		      })

	-- checked menu item, with no action
	s.checkedNoAction = _uses(s.checked)

	-- selected menu item
	s.selected = {}
	s.selected.item =
		_uses(s.item, {
			      bgImg = selectionBox,
			      text = {
				      fg = SELECT_COLOR,
				      sh = SELECT_SH_COLOR
			      },
			      icon = {
				      padding = { 4, 0, 0, 0 },
				      align = "right",
				      img = Surface:loadImage(imgpath .. "selection_right.png")
			      }
		      })

	s.selected.itemplay =
		_uses(s.selected.item, {
			      icon = {
				      img = Surface:loadImage(imgpath .. "selection_play.png")
			      }
		      })

	s.selected.itemadd =
		_uses(s.selected.item, {
			      icon = {
				      img = Surface:loadImage(imgpath .. "selection_add.png")
			      }
		      })

	s.selected.checked = _uses(s.selected.item, {
			      		order = { "text", "check", "icon" },
					icon = {
						img = Surface:loadImage(imgpath .. "selection_right.png")
					},
					check = {
						align = "right",
						img = Surface:loadImage(imgpath .. "menu_check_selected.png")
					}
				
				})

	s.selected.itemNoAction =
		_uses(s.itemNoAction, {
			      bgImg = selectionBox,
			      text = {
				      fg = SELECT_COLOR,
				      sh = SELECT_SH_COLOR
			      },
		      })

	s.selected.checkedNoAction =
		_uses(s.checkedNoAction, {
			      bgImg = selectionBox,
			      text = {
				      fg = SELECT_COLOR,
				      sh = SELECT_SH_COLOR
			      },
			      check = {
				      align = "right",
				      img = Surface:loadImage(imgpath .. "menu_check_selected.png")
			      }
		      })


	-- locked menu item (with loading animation)
	s.locked = {}
	s.locked.item = _uses(s.selected.item, {
					icon = {
						img = Surface:loadImage(imgpath .. "selection_wait.png"),
						frameRate = 5,
						frameWidth = 10
					}
			})

	--FIXME, locked menu item for these should show something other than the same icon as selected
	s.locked.itemplay = _uses(s.selected.itemplay)
	s.locked.itemadd = _uses(s.selected.itemadd)

	-- menu item choice
	s.item.choice = {}
	s.item.choice.font = FONT_BOLD_15px
	s.item.choice.fg = TEXT_COLOR
	s.item.choice.sh = TEXT_SH_COLOR
	s.item.choice.padding = { 8, 0, 0, 0 }

	-- selected menu item choice
	s.selected.item.choice = {}
	s.selected.item.choice.font = FONT_BOLD_15px
	s.selected.item.choice.fg = SELECT_COLOR
	s.selected.item.choice.sh = SELECT_SH_COLOR

	-- menu value choice
	s.item.value = {}
	s.item.value.font = FONT_BOLD_15px
	s.item.value.fg = TEXT_COLOR
	s.item.value.sh = TEXT_SH_COLOR

	-- selected menu item choice
	s.selected.item.value = {}
	s.selected.item.value.font = FONT_BOLD_15px
	s.selected.item.value.fg = SELECT_COLOR
	s.selected.item.value.sh = SELECT_SH_COLOR

	-- Text areas
	s.textarea = {}
	s.textarea.w = screenWidth
	s.textarea.padding = { 13, 8, 8, 8 }
	s.textarea.font = FONT_BOLD_15px
	s.textarea.fg = TEXT_COLOR
	s.textarea.sh = TEXT_SH_COLOR
	s.textarea.align = "left"
	

	-- Scrollbar
	s.scrollbar = {}
	s.scrollbar.w = 9
	s.scrollbar.border = { 4, 0, 0, 0 }
	s.scrollbar.horizontal = 0
	s.scrollbar.bgImg = scrollBackground
	s.scrollbar.img = scrollBar
	s.scrollbar.layer = LAYER_CONTENT_ON_STAGE


	-- Checkbox
	s.checkbox = {}
	s.checkbox.imgOn = Surface:loadImage(imgpath .. "checkbox_on.png")
	s.checkbox.imgOff = Surface:loadImage(imgpath .. "checkbox_off.png")
	s.item.checkbox = {}
	s.item.checkbox.padding = { 4, 0, 0, 0 }
	s.item.checkbox.align = "right"


	-- Radio button
	s.radio = {}
	s.radio.imgOn = Surface:loadImage(imgpath .. "radiobutton_on.png")
	s.radio.imgOff = Surface:loadImage(imgpath .. "radiobutton_off.png")
	s.item.radio = {}
	s.item.radio.padding = { 4, 0, 0, 0 }
	s.item.radio.align = "right"


	-- Slider
	s.slider = {}
	s.slider.border = 5
	s.slider.horizontal = 1
	s.slider.bgImg = sliderBackground
	s.slider.img = sliderBar

	s.sliderMin = {}
	s.sliderMin.img = Surface:loadImage(imgpath .. "slider_icon_negative.png")
	s.sliderMin.border = { 5, 0, 5, 0 }
	s.sliderMax = {}
	s.sliderMax.img = Surface:loadImage(imgpath .. "slider_icon_positive.png")
	s.sliderMax.border = { 5, 0, 5, 0 }

	s.sliderGroup = {}
	s.sliderGroup.border = { 7, 5, 25, 10 }

	-- Text input
	s.textinput = {}
	s.textinput.border = { 8, -5, 8, 0 }
	s.textinput.padding = { 6, 0, 6, 0 }
	s.textinput.font = FONT_15px
	s.textinput.cursorFont = FONT_BOLD_22px
	s.textinput.wheelFont = FONT_BOLD_15px
	s.textinput.charHeight = 26
	s.textinput.fg = SELECT_COLOR
	s.textinput.wh = { 0x55, 0x55, 0x55 }
	s.textinput.bgImg = textinputBackground
	s.textinput.wheelImg = textinputWheel
	s.textinput.cursorImg = textinputCursor
	s.textinput.enterImg = Tile:loadImage(imgpath .. "selection_right.png")

	-- Help menu
	s.help = {}
	s.help.w = screenWidth - 6
	s.help.position = LAYOUT_SOUTH
	s.help.padding = 12
	s.help.font = FONT_15px
	s.help.fg = TEXT_COLOR
	s.help.bgImg = helpBox
	s.help.align = "left"
	s.help.scrollbar = {}
	s.help.scrollbar.w = 0

	-- Help with soft buttons
	s.softHelp = {}
	s.softHelp.w = screenWidth - 6
	s.softHelp.position = LAYOUT_SOUTH
	s.softHelp.padding = { 12, 12, 12, 42 }
	s.softHelp.font = FONT_15px
	s.softHelp.fg = TEXT_COLOR
	s.softHelp.bgImg = helpBox
	s.softHelp.align = "left"
	s.softHelp.scrollbar = {}
	s.softHelp.scrollbar.w = 0

	s.softButton1 = {}
	s.softButton1.x = 15
	s.softButton1.y = screenHeight - 33
	s.softButton1.w = (screenWidth / 2) - 20
	s.softButton1.h = 28
	s.softButton1.position = LAYOUT_NONE
	s.softButton1.align = "center"
	s.softButton1.font = FONT_15px
	s.softButton1.fg = SELECT_COLOR
	s.softButton1.bgImg = softButtonBackground

	s.softButton2 = {}
	s.softButton2.x = (screenWidth / 2) + 5
	s.softButton2.y = screenHeight - 33
	s.softButton2.w = (screenWidth / 2) - 20
	s.softButton2.h = 28
	s.softButton2.position = LAYOUT_NONE
	s.softButton2.align = "center"
	s.softButton2.font = FONT_15px
	s.softButton2.fg = SELECT_COLOR
	s.softButton2.bgImg = softButtonBackground

	s.window = {}
	s.window.w = screenWidth
	s.window.h = screenHeight

	s.errorWindow = {}
	s.errorWindow.w = screenWidth
	s.errorWindow.h = screenHeight
	s.errorWindow.maskImg = popupMask

	-- Popup window with Icon, no borders
	s.popupArt = {}
	s.popupArt.border = { 0, 0, 0, 0 }
	s.popupArt.maskImg = popupMask

	-- Popup window with Icon
	s.popupIcon = {}
	s.popupIcon.border = { 13, 0, 13, 0 }
	s.popupIcon.maskImg = popupMask

	s.popupIcon.text = {}
	s.popupIcon.text.border = 15
	s.popupIcon.text.line = {
		{
			font = FONT_BOLD_13px,
			height = 16,
		},
		{
			font = FONT_BOLD_20px,
		},
	}
	s.popupIcon.text.fg = TEXT_COLOR
	s.popupIcon.text.sh = TEXT_SH_COLOR
	s.popupIcon.text.align = "center"
	s.popupIcon.text.position = LAYOUT_SOUTH

	s.iconPower = {}
	s.iconPower.img = Surface:loadImage(imgpath .. "popup_shutdown_icon.png")
	s.iconPower.w = WH_FILL
	s.iconPower.align = 'center'

	s.iconFavorites = {}
	s.iconFavorites.img = Surface:loadImage(imgpath .. "popup_fav_heart_bkgrd.png")
	s.iconFavorites.frameWidth = 161
	s.iconFavorites.align = 'center'

	-- connecting/connected popup icon
	s.iconConnecting = {}
	s.iconConnecting.img = Surface:loadImage(imgpath .. "icon_connecting.png")
	s.iconConnecting.frameRate = 4
	s.iconConnecting.frameWidth = 161
	s.iconConnecting.w = WH_FILL
	s.iconConnecting.align = "center"

	s.iconConnected = {}
	s.iconConnected.img = Surface:loadImage(imgpath .. "icon_connected.png")
	s.iconConnected.w = WH_FILL
	s.iconConnected.align = "center"

	s.iconLocked = {}
	s.iconLocked.img = Surface:loadImage(imgpath .. "popup_locked_icon.png")
	s.iconLocked.w = WH_FILL
	s.iconLocked.align = "center"

	s.iconBatteryLow = {}
	s.iconBatteryLow.img = Surface:loadImage(imgpath .. "popup_battery_low_icon.png")
	s.iconBatteryLow.w = WH_FILL
	s.iconBatteryLow.align = "center"

	s.iconAlarm = {}
	s.iconAlarm.img = Surface:loadImage(imgpath .. "popup_alarm_icon.png")
	s.iconAlarm.w = WH_FILL
	s.iconAlarm.align = "center"


	-- wireless icons for menus
	s.wirelessLevel1 = {}
	s.wirelessLevel1.align = "right"
	s.wirelessLevel1.img = Surface:loadImage(imgpath .. "icon_wireless_1_shadow.png")
	s.wirelessLevel2 = {}
	s.wirelessLevel2.align = "right"
	s.wirelessLevel2.img = Surface:loadImage(imgpath .. "icon_wireless_2_shadow.png")
	s.wirelessLevel3 = {}
	s.wirelessLevel3.align = "right"
	s.wirelessLevel3.img = Surface:loadImage(imgpath .. "icon_wireless_3_shadow.png")
	s.wirelessLevel4 = {}
	s.wirelessLevel4.align = "right"
	s.wirelessLevel4.img = Surface:loadImage(imgpath .. "icon_wireless_4_shadow.png")

	s.navcluster = {}
	s.navcluster.img = Surface:loadImage(imgpath .. "navcluster.png")
	s.navcluster.align = "center"
	s.navcluster.w = WH_FILL


	-- Special styles for specific window types

	-- Jive Home Window

	-- Here we add an icon to the window title. This uses a function
	-- that is called at runtime, so for example the icon could change
	-- based on time of day
--[[
	This example is not relevant any more, but I have left it here as an example
	of how a style value can be set dynamically using a lua function.

	s.home.window.title.icon.img = 
		function(widget)
			return Surface:loadImage(imgpath .. "mini_home.png")
		end
--]]


	-- SlimBrowser applet

	s.volumeMin = {}
	s.volumeMin.img = Surface:loadImage(imgpath .. "volume_speaker_l.png")
	s.volumeMin.border = { 5, 0, 5, 0 }
	s.volumeMax = {}
	s.volumeMax.img = Surface:loadImage(imgpath .. "volume_speaker_r.png")
	s.volumeMax.border = { 5, 0, 5, 0 }

	s.volume = {}
	s.volume.horizontal = 1
	s.volume.img = volumeBar
	s.volume.bgImg = volumeBackground

	s.volumeGroup = {}
	s.volumeGroup.border = { 16, 5, 16, 10 }

	s.volumePopup = {}
	s.volumePopup.x = 0
	s.volumePopup.y = screenHeight - 80
	s.volumePopup.w = screenWidth
	s.volumePopup.h = 80
	s.volumePopup.bgImg = helpBox
	s.volumePopup.title = {}
	s.volumePopup.title.border = 10
	s.volumePopup.title.fg = TEXT_COLOR
	s.volumePopup.title.font = FONT_BOLD_15px
	s.volumePopup.title.align = "center"
	s.volumePopup.title.bgImg = false

	s.scanner = {}
	s.scanner.horizontal = 1
	s.scanner.img = volumeBar
	s.scanner.bgImg = volumeBackground

	s.scannerGroup = {}
	s.scannerGroup.border = { 16, 5, 16, 10 }
	s.scannerGroup.order = { "elapsed", "slider", "remain" }
	s.scannerGroup.text = {}
	s.scannerGroup.text.fg = TEXT_COLOR
	s.scannerGroup.text.font = FONT_13px
	s.scannerGroup.text.w = 55
	-- s.scannerGroup.padding = { 0, 0, 0, 0 }
	s.scannerGroup.text.padding = { 8, 0, 0, 0}

	s.scannerPopup = {}
	s.scannerPopup.x = 0
	s.scannerPopup.y = screenHeight - 80
	s.scannerPopup.w = screenWidth
	s.scannerPopup.h = 80
	s.scannerPopup.bgImg = helpBox
	s.scannerPopup.title = {}
	s.scannerPopup.title.border = 10
	s.scannerPopup.title.fg = TEXT_COLOR
	s.scannerPopup.title.font = FONT_BOLD_15px
	s.scannerPopup.title.align = "center"
	s.scannerPopup.title.bgImg = false

	-- titles with artwork and song info
	s.albumtitle = {}
	s.albumtitle.position = LAYOUT_NORTH
	s.albumtitle.bgImg = titleBox
	s.albumtitle.order = { "icon", "text" }
	s.albumtitle.w = screenWidth
	s.albumtitle.h = 60
	s.albumtitle.border = 4
	s.albumtitle.text = {}
	s.albumtitle.text.padding = { 10, 8, 8, 9 }
	s.albumtitle.text.align = "top-left"
	s.albumtitle.text.font = FONT_13px
	s.albumtitle.text.lineHeight = 16
	s.albumtitle.text.line = {
		{
			font = FONT_BOLD_13px,
			height = 17,
		}
	}
	s.albumtitle.text.fg = SELECT_COLOR
	s.albumtitle.icon = {}
	s.albumtitle.icon.h = WH_FILL
	s.albumtitle.icon.align = "left"
	s.albumtitle.icon.img = Surface:loadImage(imgpath .. "menu_album_noartwork.png")
	s.albumtitle.icon.padding = { 9, 0, 0, 0 }


	-- titles with mini icons
	s.minititle = {}
	setmetatable(s.minititle, { __index = s.title })

	s.minititle.border        = 4
	s.minititle.position      = LAYOUT_NORTH
	s.minititle.bgImg         = titleBox
	s.minititle.text = {}
	s.minititle.text.w        = WH_FILL
	s.minititle.text.padding  = { 8, 7, 0, 9 }
	s.minititle.text.align    = 'top-left'
	s.minititle.text.font     = FONT_BOLD_18px
	s.minititle.text.fg       = SELECT_COLOR
	s.minititle.order         = { "text", "icon" }
	s.minititle.icon = {}
	s.minititle.icon.padding  = { 0, 0, 8, 0 }
	s.minititle.icon.align    = 'right'


	-- Based on s.title, this is for internetradio title style
	s.internetradiotitle =
		_uses(s.minititle, {
			      icon = {
				      img = Surface:loadImage(imgpath .. "mini_internet_radio.png")
			      }
		      })

	-- Based on s.title, this is for favorites title style
	s.favoritestitle = 
		_uses(s.minititle, {
			      icon = {
				      img = Surface:loadImage(imgpath .. "mini_favorites.png")
			      }
		      })

	-- Based on s.title, this is for mymusic title style
	s.mymusictitle =
		_uses(s.minititle, {
			      icon = {
				      img = Surface:loadImage(imgpath .. "mini_music_library.png")
			      }
		      })

	-- Based on s.title, this is for search title style
	s.searchtitle =
		_uses(s.minititle, {
			      icon = {
				      img = Surface:loadImage(imgpath .. "mini_search.png")
			      }
		      })

	-- Based on s.title, this is for settings title style
	s.hometitle =
		_uses(s.minititle, {
			      icon = {
				      img = Surface:loadImage(imgpath .. "mini_home.png")
			      }
		      })

	-- Based on s.title, this is for settings title style
	s.settingstitle =
		_uses(s.minititle, {
			      icon = {
				      img = Surface:loadImage(imgpath .. "mini_settings.png")
			      }
		      })

	-- Based on s.title, this is for newmusic title style
	s.newmusictitle =
		_uses(s.minititle, {
			      icon = {
				      img = Surface:loadImage(imgpath .. "mini_newmusic.png")
			      }
		      })

	-- Based on s.title, this is for infobrowser title style
	s.infobrowsertitle =
		_uses(s.minititle, {
			      icon = {
				      img = Surface:loadImage(imgpath .. "mini_infobrowser.png")
			      }
		      })

	-- Based on s.title, this is for albumlist title style
	-- NOTE: not to be confused with "album", which is a different style
	s.albumlisttitle =
		_uses(s.minititle, {
			      icon = {
				      img = Surface:loadImage(imgpath .. "mini_albums.png")
			      }
		      })


	-- Based on s.title, this is for artists title style
	s.artiststitle =
		_uses(s.minititle, {
			      icon = {
				      img = Surface:loadImage(imgpath .. "mini_artists.png")
			      }
		      })
	-- Based on s.title, this is for random title style
	s.randomtitle =
		_uses(s.minititle, {
			      icon = {
				      img = Surface:loadImage(imgpath .. "mini_random.png")
			      }
		      })

	-- Based on s.title, this is for musicfolder title style
	s.musicfoldertitle =
		_uses(s.minititle, {
			      icon = {
				      img = Surface:loadImage(imgpath .. "mini_musicfolder.png")
			      }
		      })

	-- Based on s.title, this is for genres title style
	s.genrestitle =
		_uses(s.minititle, {
			      icon = {
				      img = Surface:loadImage(imgpath .. "mini_genres.png")
			      }
		      })

	-- Based on s.title, this is for years title style
	s.yearstitle =
		_uses(s.minititle, {
			      icon = {
				      img = Surface:loadImage(imgpath .. "mini_years.png")
			      }
		      })
	-- Based on s.title, this is for playlist title style
	s.playlisttitle =
		_uses(s.minititle, {
			      icon = {
				      img = Surface:loadImage(imgpath .. "mini_playlist.png")
			      }
		      })

	-- Based on s.title, this is for currentplaylist title style
	s.currentplaylisttitle =
		_uses(s.minititle, {
			      icon = {
				      img = Surface:loadImage(imgpath .. "mini_nowplaying.png")
			      }
		      })





	-- menus with artwork and song info
	s.albummenu = {}
	s.albummenu.padding = { 4, 2, 4, 2 }
	s.albummenu.itemHeight = 61
	s.albummenu.fg = {0xbb, 0xbb, 0xbb }
	s.albummenu.font = FONT_BOLD_200px


	-- items with artwork and song info
	--s.albumitem.h = 60
	s.albumitem = {}
	s.albumitem.order = { "icon", "text", "play" }
	s.albumitem.text = {}
	s.albumitem.text.w = WH_FILL
	s.albumitem.text.padding = { 6, 8, 8, 8 }
	s.albumitem.text.align = "top-left"
	s.albumitem.text.font = FONT_13px
	s.albumitem.text.lineHeight = 16
	s.albumitem.text.line = {
		{
			font = FONT_BOLD_13px,
			height = 17
		}
	}
	s.albumitem.text.fg = TEXT_COLOR
	s.albumitem.text.sh = TEXT_SH_COLOR
	s.albumitem.icon = {}
	s.albumitem.icon.w = 56
	s.albumitem.icon.h = WH_FILL
	s.albumitem.icon.align = "center"
	s.albumitem.icon.img = Surface:loadImage(imgpath .. "menu_album_noartwork.png")
	s.albumitem.icon.border = { 8, 0, 0, 0 }

	s.popupToast = _uses(s.albumitem, 
		{
			order = { 'icon', 'text', 'textarea' },
			textarea = { 
				w = WH_FILL, 
				h = WH_FILL, 
				padding = { 12, 20, 12, 12 } 
			},
			text = { 
				padding = { 6, 15, 8, 8 } 
			},
			icon = { 
				align = 'top-left', 
				border = { 12, 12, 0, 0 } 
			}
		}
	)

	s.albumitemNoAction = {}
	s.albumitemNoAction.order = { "text" }
	s.albumitemNoAction.text = {}
	s.albumitemNoAction.text.w = WH_FILL
	s.albumitemNoAction.text.padding = { 6, 8, 8, 8 }
	s.albumitemNoAction.text.align = "top-left"
	s.albumitemNoAction.text.font = FONT_13px
	s.albumitemNoAction.text.lineHeight = 16
	s.albumitemNoAction.text.line = {
		{
			font = FONT_BOLD_13px,
			height = 17
		}
	}
	s.albumitemNoAction.text.fg = TEXT_COLOR
	s.albumitemNoAction.text.sh = TEXT_SH_COLOR


--FIXME: albumitemNoAction can't use _uses because it sticks an icon on the screen
--[[
	s.albumitemNoAction = _uses(s.albumitem, {
					order = { 'text' },
					icon  = nil
				})
--]]
	s.selected.albumitemNoAction = _uses(s.albumitemNoAction)

	-- selected item with artwork and song info
	s.selected.albumitem = {}
	s.selected.albumitem.text = {}
	s.selected.albumitem.text.fg = SELECT_COLOR
	s.selected.albumitem.text.sh = SELECT_SH_COLOR
	s.selected.albumitem.bgImg = albumSelectionBox

	s.selected.albumitem.play = {}
	s.selected.albumitem.play.h = WH_FILL
	s.selected.albumitem.play.align = "center"
	s.selected.albumitem.play.img = Surface:loadImage(imgpath .. "selection_right.png")
	s.selected.albumitem.play.border = { 0, 0, 5, 0 }

	-- locked item with artwork and song info
	s.locked.albumitem = {}
	s.locked.albumitem.text = {}
	s.locked.albumitem.text.fg = SELECT_COLOR
	s.locked.albumitem.text.sh = SELECT_SH_COLOR
	s.locked.albumitem.bgImg = albumSelectionBox

	-- waiting item with spinny
	s.albumitemwaiting = _uses(s.albumitem, {
		icon = {
			img = Surface:loadImage(imgpath .. "icon_connecting_44.png"),
			frameRate = 4,
			frameWidth = 56
		}
	})

	s.selected.albumitemwaiting = _uses(s.albumitemwaiting)

	s.locked.albumitem.play = {}
	s.locked.albumitem.play.h = WH_FILL
	s.locked.albumitem.play.align = "center"
	s.locked.albumitem.play.img = Surface:loadImage(imgpath .. "selection_wait.png")
	s.locked.albumitem.play.border = { 0, 0, 5, 0 }
	s.locked.albumitem.play.frameRate = 4
	s.locked.albumitem.play.frameWidth = 10

	-- titles with artwork and song info
	s.nowplayingtitle = {}
	s.nowplayingtitle.position = LAYOUT_NORTH
	s.nowplayingtitle.bgImg = titleBox
	s.nowplayingtitle.order = { "text", "icon" }
	s.nowplayingtitle.w = screenWidth
	s.nowplayingtitle.h = 70
	s.nowplayingtitle.border = 4
	s.nowplayingtitle.text = {}
	s.nowplayingtitle.text.padding = { 10, 8, 8, 9 }
	s.nowplayingtitle.text.align = "top-left"
	s.nowplayingtitle.text.font = FONT_18px
	s.nowplayingtitle.text.lineHeight = 17
	s.nowplayingtitle.text.line = {
		{
			font = FONT_BOLD_18px,
			height = 20
		}
	}
	s.nowplayingtitle.text.fg = SELECT_COLOR
	s.nowplayingtitle.icon = {}
	s.nowplayingtitle.icon.hide = 1
--	s.nowplayingtitle.icon.align = "center"
--	s.nowplayingtitle.icon.img = Surface:loadImage(imgpath .. "menu_nowplaying_noartwork.png")
--	s.nowplayingtitle.icon.padding = { 6, 0, 0, 0 }


	-- menus with artwork and song info
	s.nowplayingmenu = {}
	s.nowplayingmenu.padding = 2
	s.nowplayingmenu.itemHeight = 61


	-- items with artwork and song info
	--s.nowplayingitem.h = 60
	s.nowplayingitem = {}
	s.nowplayingitem.order = { "icon", "text", "play" }
	s.nowplayingitem.text = {}
	s.nowplayingitem.text.w = WH_FILL
	s.nowplayingitem.text.padding = { 12, 8, 8, 8 }
	s.nowplayingitem.text.align = "top-left"
	s.nowplayingitem.text.font = FONT_13px
	s.nowplayingitem.text.lineHeight = 170
	s.nowplayingitem.text.line = {
		{
			font = FONT_BOLD_13px,
			height = 17
		}
	}
	s.nowplayingitem.text.fg = TEXT_COLOR
	s.nowplayingitem.text.sh = TEXT_SH_COLOR
	s.nowplayingitem.icon = {}
	s.nowplayingitem.icon.w = 156
	s.nowplayingitem.icon.h = 156
	s.nowplayingitem.icon.align = "left"
	s.nowplayingitem.icon.img = Surface:loadImage(imgpath .. "menu_album_noartwork.png")
	s.nowplayingitem.icon.padding = { 5, 0, 0, 0 }


	-- selected item with artwork and song info
	s.selected.nowplayingitem = {}
	s.selected.nowplayingitem.text = {}
	s.selected.nowplayingitem.text.fg = SELECT_COLOR
	s.selected.nowplayingitem.text.sh = SELECT_SH_COLOR
	s.selected.nowplayingitem.bgImg = albumSelectionBox


	-- locked item with artwork and song info
	s.locked.nowplayingitem = {}
	s.locked.nowplayingitem.text = {}
	s.locked.nowplayingitem.text.fg = SELECT_COLOR
	s.locked.nowplayingitem.text.sh = SELECT_SH_COLOR
	s.locked.nowplayingitem.bgImg = albumSelectionBox


	-- now playing menu item
	s.albumcurrent = {}
	s.albumcurrent.order = { "icon", "text", "play" }
	s.albumcurrent.text = {}
	s.albumcurrent.text.w = WH_FILL
	s.albumcurrent.text.padding = { 6, 8, 8, 8 }
	s.albumcurrent.text.align = "top-left"
	s.albumcurrent.text.font = FONT_13px
	s.albumcurrent.text.lineHeight = 16
	s.albumcurrent.text.line = {
		{
			font = FONT_BOLD_13px,
			height = 17
		}
	}
	s.albumcurrent.text.fg = TEXT_COLOR
	s.albumcurrent.text.sh = TEXT_SH_COLOR
	s.albumcurrent.icon = {}
	s.albumcurrent.icon.w = 56
	s.albumcurrent.icon.h = WH_FILL
	s.albumcurrent.icon.align = "center"
	s.albumcurrent.icon.img = Surface:loadImage(imgpath .. "menu_album_noartwork.png")
	s.albumcurrent.icon.border = { 8, 0, 0, 0 }
	s.albumcurrent.play = {}
	s.albumcurrent.play.img = Surface:loadImage(imgpath .. "menu_nowplaying.png")

	-- selected now playing menu item
	s.selected.albumcurrent = {}
	s.selected.albumcurrent.bgImg = albumSelectionBox
	s.selected.albumcurrent.text = {}
	s.selected.albumcurrent.text.fg = SELECT_COLOR
	s.selected.albumcurrent.text.sh = SELECT_SH_COLOR
	s.selected.albumcurrent.play = {}
	s.selected.albumcurrent.play.img = Surface:loadImage(imgpath .. "menu_nowplaying_selected.png")


	-- locked now playing menu item (with loading animation)
	s.locked.albumcurrent = {}
	s.locked.albumcurrent.bgImg = albumSelectionBox
	s.locked.albumcurrent.text = {}
	s.locked.albumcurrent.text.fg = SELECT_COLOR
	s.locked.albumcurrent.text.sh = SELECT_SH_COLOR

	-- Popup window for current song info
	s.currentsong = {}
	s.currentsong.x = 0
	s.currentsong.y = screenHeight - 93
	s.currentsong.w = screenWidth
	s.currentsong.h = 93
	s.currentsong.bgImg = helpBox
	s.currentsong.albumitem = {}
	s.currentsong.albumitem.border = { 4, 10, 4, 0 }
	s.currentsong.albumitem.icon = { }
	s.currentsong.albumitem.icon.align = "top"

	-- Popup window for play/add without artwork
	s.popupplay= {}
	s.popupplay.x = 0
	s.popupplay.y = screenHeight - 96
	s.popupplay.w = screenWidth
	s.popupplay.h = 96

	-- for textarea properties in popupplay
	s.popupplay.padding = { 12, 12, 12, 0 }
	s.popupplay.fg = TEXT_COLOR
	s.popupplay.font = FONT_15px
	s.popupplay.align = "top-left"
	s.popupplay.scrollbar = {}
	s.popupplay.scrollbar.w = 0

	s.lockedHelp = {}
	s.lockedHelp.padding = { 12, 0, 12, 12 }
	s.lockedHelp.fg = TEXT_COLOR
	s.lockedHelp.font = FONT_BOLD_15px
	s.lockedHelp.align = "center"
	s.lockedHelp.position = LAYOUT_NORTH
	s.lockedHelp.w = screenWidth - 20
	s.lockedHelp.x = 20
	s.lockedHelp.y = 0

	s.popupplay.text = {}
	s.popupplay.text.w = screenWidth
	s.popupplay.text.h = 72
	s.popupplay.text.padding = { 20, 20, 20, 20 }
	s.popupplay.text.font = FONT_15px
	s.popupplay.text.lineHeight = 17
	s.popupplay.text.line = {
		nil,
		{
			font = FONT_BOLD_15px,
			height = 17
		}
	}
	s.popupplay.text.fg = TEXT_COLOR
	s.popupplay.text.align = "top-left"

	-- Popup window for information display
	s.popupinfo = {}
	s.popupinfo.x = 0
	s.popupinfo.y = screenHeight - 96
	s.popupinfo.w = screenWidth
	s.popupinfo.h = 96
	s.popupinfo.bgImg = helpBox
	s.popupinfo.text = {}
	s.popupinfo.text.w = screenWidth
	s.popupinfo.text.h = 72
	s.popupinfo.text.padding = { 14, 24, 14, 14 }
	s.popupinfo.text.font = FONT_BOLD_13px
	s.popupinfo.text.lineHeight = 17
	s.popupinfo.text.fg = TEXT_COLOR
	s.popupinfo.text.align = "left"

	-- the NowPlaying skin code is established in two forms,
	-- one for the Screensaver windowStyle (ss), one for the browse windowStyle (browse)
	-- a lot of it can be recycled from one to the other

	-- BEGIN NowPlaying skin code
	local npimgpath = "applets/NowPlaying/"
	local screenWidth, screenHeight = Framework:getScreenSize()

        local titleBox =
                Tile:loadTiles({
                                       imgpath .. "titlebox.png",
                                       imgpath .. "titlebox_tl.png",
                                       imgpath .. "titlebox_t.png",
                                       imgpath .. "titlebox_tr.png",
                                       imgpath .. "titlebox_r.png",
                                       imgpath .. "bghighlight_tr.png",
                                       imgpath .. "titlebox_b.png",
                                       imgpath .. "bghighlight_tl.png",
                                       imgpath .. "titlebox_l.png"
                               })

        local highlightBox =
                Tile:loadTiles({
                                       imgpath .. "bghighlight.png",
                                       nil,
                                       nil,
                                       nil,
                                       imgpath .. "bghighlight_r.png",
                                       imgpath .. "bghighlight_br.png",
                                       imgpath .. "bghighlight_b.png",
                                       imgpath .. "bghighlight_bl.png",
                                       imgpath .. "bghighlight_l.png"
                               })

	-- Title
	s.ssnptitle = {}
	s.ssnptitle.border = { 4, 4, 4, 0 }
	s.ssnptitle.position = LAYOUT_NORTH
	s.ssnptitle.bgImg = titleBox
	s.ssnptitle.order = { "title", "playlist" }
	s.ssnptitle.text = {}
	s.ssnptitle.text.w = WH_FILL
	s.ssnptitle.text.padding = { 10, 7, 10, 9 }
	s.ssnptitle.text.align = "top-left"
	s.ssnptitle.text.font = Font:load(fontpath .. "FreeSansBold.ttf", 20)
	s.ssnptitle.text.fg = { 0x00, 0x00, 0x00 }
	s.ssnptitle.playlist = {}
	s.ssnptitle.playlist.padding = { 10, 7, 10, 9 }
	s.ssnptitle.playlist.font = Font:load(fontpath .. "FreeSans.ttf", 15)
	s.ssnptitle.playlist.fg = { 0x00, 0x00, 0x00 }
	s.ssnptitle.playlist.textAlign = "top-right"


	-- nptitle style is the same for both windowStyles
	s.browsenptitle = _uses(s.ssnptitle, browsenptitle)


	-- Song
	s.ssnptrack = {}
	s.ssnptrack.border = { 4, 0, 4, 0 }
        s.ssnptrack.bgImg = highlightBox
	s.ssnptrack.text = {}
	s.ssnptrack.text.w = WH_FILL
	s.ssnptrack.text.padding = { 10, 10, 8, 4 }
	s.ssnptrack.text.align = "top-left"
        s.ssnptrack.text.font = Font:load(fontpath .. "FreeSans.ttf", 14)
	s.ssnptrack.text.lineHeight = 17
        s.ssnptrack.text.line = {
		{
			font = Font:load(fontpath .. "FreeSansBold.ttf", 14),
			height = 17
		}
	}
	s.ssnptrack.text.fg = { 0x00, 0x00, 0x00 }

	-- nptrack is identical between the two windowStyles
	s.browsenptrack = _uses(s.ssnptrack)

	-- Artwork
	local browseArtWidth = 154
	local ssArtWidth = 186

	s.ssnpartwork = {}
	s.ssnpartwork.w = WH_FILL
	-- 8 pixel padding below artwork in browse mode
	s.ssnpartwork.border = { 0, 10, 0, 8 }
--	s.ssnpartwork.bgImg = Tile:loadImage(imgpath .. "album_shadow_" .. ssArtWidth .. ".png")
	s.ssnpartwork.artwork = {}
	s.ssnpartwork.artwork.padding = 0 
	s.ssnpartwork.artwork.w = WH_FILL
	s.ssnpartwork.artwork.align = "center"
	s.ssnpartwork.artwork.img = Surface:loadImage(imgpath .. "album_noartwork_" .. ssArtWidth .. ".png")

	-- artwork layout is not the same between the two windowStyles
	local browsenpartwork = {
		-- 10 pixel padding below artwork in browse mode
		w = WH_FILL,
		border = { 0, 10, 0, 10 },
		--bgImg = Tile:loadImage(imgpath .. "album_shadow_" .. browseArtWidth .. ".png"),
		artwork = { padding = 0, img = Surface:loadImage(imgpath .. "album_noartwork_" .. browseArtWidth .. ".png") }
	}
	s.browsenpartwork = _uses(s.ssnpartwork, browsenpartwork)

	-- Progress bar
        local progressBackground =
                Tile:loadHTiles({
                                        npimgpath .. "progressbar_bkgrd_l.png",
                                        npimgpath .. "progressbar_bkgrd.png",
                                        npimgpath .. "progressbar_bkgrd_r.png",
                               })

        local progressBar =
                Tile:loadHTiles({
                                        npimgpath .. "progressbar_fill_l.png",
                                        npimgpath .. "progressbar_fill.png",
                                        npimgpath .. "progressbar_fill_r.png",
                               })

	s.ssprogress = {}
	s.ssprogress.position = LAYOUT_SOUTH
	s.ssprogress.order = { "elapsed", "slider", "remain" }
	s.ssprogress.text = {}
	s.ssprogress.text.w = 50
	s.ssprogress.padding = { 8, 0, 8, 5 }
	s.ssprogress.text.padding = { 8, 0, 0, 5 }
	s.ssprogress.text.font = Font:load(fontpath .. "FreeSansBold.ttf", 12)
	s.ssprogress.text.fg = { 0xe7,0xe7, 0xe7 }
	s.ssprogress.text.sh = { 0x37, 0x37, 0x37 }

	-- browse has different positioning than ss windowStyle
	s.browseprogress = _uses(s.ssprogress,
				{ 
					padding = { 8, 0, 8, 25 },
					text = {
						padding = { 8, 0, 0, 25 }
					}
				}
			)

	s.ssprogressB             = {}
        s.ssprogressB.horizontal  = 1
        s.ssprogressB.bgImg       = progressBackground
        s.ssprogressB.img         = progressBar
	s.ssprogressB.position    = LAYOUT_SOUTH
	s.ssprogressB.padding     = { 0, 0, 0, 5 }

	s.browseprogressB = _uses(s.ssprogressB,
					{
					padding = { 0, 0, 0, 25 }
					}
				)

	-- special style for when there shouldn't be a progress bar (e.g., internet radio streams)
	s.ssprogressNB = {}
	s.ssprogressNB.position = LAYOUT_SOUTH
	s.ssprogressNB.order = { "elapsed" }
	s.ssprogressNB.text = {}
	s.ssprogressNB.text.w = WH_FILL
	s.ssprogressNB.text.align = "center"
	s.ssprogressNB.padding = { 0, 0, 0, 5 }
	s.ssprogressNB.text.padding = { 0, 0, 0, 5 }
	s.ssprogressNB.text.font = Font:load(fontpath .. "FreeSansBold.ttf", 12)
	s.ssprogressNB.text.fg = { 0xe7, 0xe7, 0xe7 }
	s.ssprogressNB.text.sh = { 0x37, 0x37, 0x37 }

	s.browseprogressNB = _uses(s.ssprogressNB,
				{ 
					padding = { 0, 0, 0, 25 },
					text = {
						padding = { 0, 0, 0, 25 },
					}
				}
			)

	-- background style should start at x,y = 0,0
        s.iconbg = {}
        s.iconbg.x = 0
        s.iconbg.y = 0
        s.iconbg.h = screenHeight
        s.iconbg.w = screenWidth
	s.iconbg.border = { 0, 0, 0, 0 }
	s.iconbg.position = LAYOUT_NONE

	-- END NowPlaying skin code


end


--[[

=head1 LICENSE

Copyright 2007 Logitech. All Rights Reserved.

This file is subject to the Logitech Public Source License Version 1.0. Please see the LICENCE file for details.

=cut
--]]
