require("lib/managers/HUDManager")
require("lib/managers/HUDManagerVR")


-- Lines: 5 to 9
local function make_fine_text(text)
	local x, y, w, h = text:text_rect()

	text:set_size(w, h)
	text:set_position(math.round(text:x()), math.round(text:y()))
end

local PADDING = 30
VRGuiObject = VRGuiObject or class()

-- Lines: 17 to 29
function VRGuiObject:init(panel, id, params)
	self._id = id
	self._panel = panel:panel({
		w = params.w,
		h = params.h,
		x = params.x,
		y = params.y
	})
	self._parent_menu = params.parent_menu
	self._enabled = true
end

-- Lines: 31 to 32
function VRGuiObject:id()
	return self._id
end

-- Lines: 35 to 36
function VRGuiObject:parent_menu()
	return self._parent_menu
end

-- Lines: 39 to 42
function VRGuiObject:set_enabled(enabled)
	self._enabled = enabled

	self._panel:set_visible(enabled)
end

-- Lines: 44 to 45
function VRGuiObject:enabled()
	return self._enabled
end

-- Lines: 49 to 60
function VRGuiObject:set_selected(selected)
	if self._selected == selected then
		return
	end

	self._selected = selected

	if selected then
		managers.menu:post_event("highlight")
	end

	return true
end

-- Lines: 63 to 64
function VRGuiObject:moved(x, y)
end

-- Lines: 66 to 67
function VRGuiObject:pressed(x, y)
end

-- Lines: 69 to 70
function VRGuiObject:released(x, y)
end
local overrides = {
	"inside",
	"x",
	"y",
	"w",
	"h",
	"left",
	"right",
	"top",
	"bottom",
	"set_x",
	"set_y",
	"set_w",
	"set_h",
	"set_left",
	"set_right",
	"set_top",
	"set_bottom",
	"set_visible"
}

for _, func in ipairs(overrides) do

	-- Lines: 73 to 74
	VRGuiObject[func] = function (self, ...)
		return self._panel[func](self._panel, ...)
	end
end

local unselected_color = Color.black:with_alpha(0.5)
local selected_color = Color.black:with_alpha(0.7)
VRButton = VRButton or class(VRGuiObject)

-- Lines: 84 to 103
function VRButton:init(panel, id, params)
	params.w = params.w or 200
	params.h = params.h or 75

	VRButton.super.init(self, panel, id, params)

	self._bg = self._panel:rect({
		name = "bg",
		color = unselected_color
	})
	self._text = self._panel:text({
		font_size = 50,
		text = not params.skip_localization and managers.localization:to_upper_text(params.text_id) or params.text_id,
		font = tweak_data.menu.pd2_massive_font
	})

	make_fine_text(self._text)
	self._text:set_center(self._panel:w() / 2, self._panel:h() / 2)
	BoxGuiObject:new(self._panel, {sides = {
		1,
		1,
		1,
		1
	}})
end

-- Lines: 105 to 109
function VRButton:set_selected(selected)
	if VRButton.super.set_selected(self, selected) then
		self._bg:set_color(selected and selected_color or unselected_color)
	end
end

-- Lines: 111 to 115
function VRButton:set_text(text_id, skip_localization)
	self._text:set_text(not skip_localization and managers.localization:to_upper_text(text_id) or text_id)
	make_fine_text(self._text)
	self._text:set_center_x(self._panel:w() / 2)
end
VRSlider = VRSlider or class(VRGuiObject)

-- Lines: 120 to 161
function VRSlider:init(panel, id, params)
	params.w = params.w or 400
	params.h = params.h or 75

	VRSlider.super.init(self, panel, id, params)

	self._value = params.value or 0
	self._max = params.max or 1
	self._min = params.min or 0
	self._snap = params.snap or 1
	self._value_clbk = params.value_clbk
	self._line = self._panel:rect({
		h = 4,
		name = "line"
	})

	self._line:set_center_y(self._panel:h() / 2)

	self._mid_piece = self._panel:panel({
		w = 100,
		name = "mid_piece",
		layer = 1
	})

	self._mid_piece:set_center_x(self._panel:w() / 2)

	self._bg = self._mid_piece:rect({
		name = "bg",
		color = unselected_color
	})
	self._text = self._mid_piece:text({
		font_size = 50,
		text = tostring(math.floor(self._value)),
		font = tweak_data.menu.pd2_massive_font
	})

	make_fine_text(self._text)
	self._text:set_center(self._mid_piece:w() / 2, self._mid_piece:h() / 2)
	BoxGuiObject:new(self._mid_piece, {sides = {
		1,
		1,
		1,
		1
	}})
	self:_update_position()
end

-- Lines: 163 to 164
function VRSlider:value()
	return self._value
end

-- Lines: 167 to 168
function VRSlider:value_ratio()
	return (self._value - self._min) / (self._max - self._min)
end

-- Lines: 171 to 172
function VRSlider:value_from_ratio(ratio)
	return math.clamp((self._max - self._min) * ratio + self._min, self._min, self._max)
end

-- Lines: 175 to 179
function VRSlider:set_value(value)
	self._value = math.clamp(value, self._min, self._max)

	self:set_text(math.floor(self._value))
	self:_update_position()
end

-- Lines: 181 to 185
function VRSlider:_update_position()
	local value_ratio = self:value_ratio()
	local w = self._panel:w() - self._mid_piece:w()

	self._mid_piece:set_center_x(value_ratio * w + self._mid_piece:w() / 2)
end

-- Lines: 187 to 191
function VRSlider:set_selected(selected)
	if VRButton.super.set_selected(self, selected) then
		self._bg:set_color(selected and selected_color or unselected_color)
	end
end

-- Lines: 193 to 197
function VRSlider:set_text(text)
	self._text:set_text(tostring(text))
	make_fine_text(self._text)
	self._text:set_center_x(self._mid_piece:w() / 2)
end

-- Lines: 199 to 207
function VRSlider:pressed(x, y)
	if not self._selected then
		return
	end

	self._start_x = x
	self._start_ratio = self:value_ratio()
	self._pressed = true
end

-- Lines: 209 to 215
function VRSlider:released(x, y)
	if self._pressed and self._value_clbk then
		self._value_clbk(self._value)
	end

	self._pressed = nil
end

-- Lines: 217 to 228
function VRSlider:moved(x, y)
	if self._pressed then
		local diff = x - self._start_x
		local diff_ratio = diff / (self._panel:w() - self._mid_piece:w())

		if self._snap <= math.abs(diff_ratio) * self._max then
			self:set_value(math.floor(self:value_from_ratio(diff_ratio + self._start_ratio) / self._snap) * self._snap)

			self._start_ratio = self:value_ratio()
			self._start_x = self._panel:world_x() + self._mid_piece:w() / 2 + (self._panel:w() - self._mid_piece:w()) * self._start_ratio
		end
	end
end
VRSettingButton = VRSettingButton or class(VRButton)

-- Lines: 234 to 243
function VRSettingButton:init(panel, id, params)
	if not params.setting then
		Application:error("Tried to add a setting button without a setting!")
	end

	params.text_id, params.skip_localization = self:_get_setting_text(managers.vr:get_setting(params.setting))

	VRSettingButton.super.init(self, panel, id, params)

	self._setting = params.setting
end

-- Lines: 245 to 253
function VRSettingButton:_get_setting_text(value)
	if type(value) == "boolean" then
		return value and "menu_vr_on" or "menu_vr_off"
	elseif type(value) == "number" then
		return tostring(value), true
	else
		return "menu_vr_" .. tostring(value)
	end
end

-- Lines: 255 to 258
function VRSettingButton:setting_changed()
	local new_value = managers.vr:get_setting(self._setting)

	self:set_text(self:_get_setting_text(new_value))
end
VRSettingSlider = VRSettingSlider or class(VRSlider)

-- Lines: 263 to 279
function VRSettingSlider:init(panel, id, params)
	if not params.setting then
		Application:error("Tried to add a setting slider without a setting!")
	end

	params.value = managers.vr:get_setting(params.setting)
	params.value_clbk = params.value_clbk or function (value)
		managers.vr:set_setting(params.setting, value)
	end
	params.min, params.max = managers.vr:setting_limits(params.setting)

	if not params.max then
		Application:error("Tried to add a setting slider without limits: " .. params.setting)
	end

	VRSettingSlider.super.init(self, panel, id, params)

	self._setting = params.setting
end

-- Lines: 281 to 284
function VRSettingSlider:setting_changed()
	local new_value = managers.vr:get_setting(self._setting)

	self:set_value(new_value)
end
VRSettingTrigger = VRSettingTrigger or class(VRButton)

-- Lines: 288 to 293
function VRSettingTrigger:init(panel, id, params)
	VRSettingTrigger.super.init(self, panel, id, params)

	self._setting = params.setting
	self._change_clbk = params.change_clbk
end

-- Lines: 295 to 299
function VRSettingTrigger:setting_changed()
	if self._change_clbk then
		self:_change_clbk(managers.vr:get_setting(self._setting))
	end
end
VRMenu = VRMenu or class()

-- Lines: 305 to 309
function VRMenu:init()
	self._buttons = {}
	self._sub_menus = {}
	self._objects = {}
end

-- Lines: 311 to 318
function VRMenu:set_selected(index)
	if self._selected and self._selected ~= index then
		self._buttons[self._selected].button:set_selected(false)
	end

	if index then
		self._buttons[index].button:set_selected(true)
	end

	self._selected = index
end

-- Lines: 320 to 321
function VRMenu:selected()
	return self._selected and self._buttons[self._selected]
end

-- Lines: 324 to 339
function VRMenu:mouse_moved(o, x, y)
	local selected = nil

	for i, button in ipairs(self._buttons) do
		if button.button:inside(x, y) and button.button:enabled() then
			selected = i
		end

		button.button:moved(x, y)
	end

	self:set_selected(selected)

	if self._open_menu then
		self._open_menu:mouse_moved(o, x, y)
	end
end

-- Lines: 341 to 353
function VRMenu:mouse_pressed(o, button, x, y)
	if button ~= Idstring("0") then
		return
	end

	for _, button in ipairs(self._buttons) do
		button.button:pressed(x, y)
	end

	if self._open_menu then
		self._open_menu:mouse_pressed(o, button, x, y)
	end
end

-- Lines: 355 to 367
function VRMenu:mouse_released(o, button, x, y)
	if button ~= Idstring("0") then
		return
	end

	for _, button in ipairs(self._buttons) do
		button.button:released(x, y)
	end

	if self._open_menu then
		self._open_menu:mouse_released(o, button, x, y)
	end
end

-- Lines: 369 to 378
function VRMenu:mouse_clicked(o, button, x, y)
	if self:selected() and self:selected().clbk then
		self:selected().clbk(self:selected().button)
		managers.menu:post_event("menu_enter")
	end

	if self._open_menu then
		self._open_menu:mouse_clicked(o, button, x, y)
	end
end

-- Lines: 380 to 382
function VRMenu:add_object(id, obj)
	self._objects[id] = obj
end

-- Lines: 384 to 389
function VRMenu:remove_object(id)
	if self._objects[id].destroy then
		self._objects[id]:destroy()
	end

	self._objects[id] = nil
end

-- Lines: 391 to 392
function VRMenu:object(id)
	return self._objects[id]
end

-- Lines: 395 to 399
function VRMenu:clear_objects()
	for id in pairs(self._objects) do
		self:remove_object(id)
	end
end

-- Lines: 401 to 405
function VRMenu:update(t, dt)
	for id, obj in pairs(self._objects) do
		obj:update(t, dt)
	end
end
VRSubMenu = VRSubMenu or class(VRMenu)

-- Lines: 411 to 416
function VRSubMenu:init(panel, id)
	VRSubMenu.super.init(self)

	self._id = id
	self._enabled = false
	self._panel = panel:panel({
		visible = false,
		w = panel:w() * 0.8 - PADDING * 2,
		h = panel:h() - PADDING * 2,
		x = panel:w() * 0.2 + PADDING,
		y = PADDING
	})
end

-- Lines: 418 to 427
function VRSubMenu:add_desc(desc)
	self._desc = self._panel:text({
		word_wrap = true,
		wrap = true,
		text = managers.localization:text(desc),
		font = tweak_data.menu.pd2_large_font,
		font_size = tweak_data.menu.pd2_large_font_size
	})

	make_fine_text(self._desc)
end

-- Lines: 429 to 430
function VRSubMenu:setting(id)
	return self._settings and self._settings[id]
end

-- Lines: 433 to 504
function VRSubMenu:add_setting(type, text_id, setting, params)
	local y_offset = 0

	if self._desc then
		y_offset = self._desc:h()
	end

	self._settings = self._settings or {}
	local num_settings = table.size(self._settings)
	params = params or {}
	local setting_text = self._panel:text({
		word_wrap = true,
		wrap = true,
		text = managers.localization:text(text_id),
		font = tweak_data.menu.pd2_large_font,
		font_size = tweak_data.menu.pd2_large_font_size,
		y = num_settings * 100 + y_offset
	})
	local setting_item, clbk = nil

	if type == "button" then
		setting_item = VRSettingButton:new(self._panel, setting, table.map_append({
			setting = setting,
			parent_menu = self
		}, params))


		-- Lines: 455 to 463
		function clbk(btn)
			local new_value = not managers.vr:get_setting(setting)

			managers.vr:set_setting(setting, new_value)
			btn:setting_changed()

			if params.clbk then
				params.clbk(new_value)
			end
		end
	elseif type == "slider" then

		-- Lines: 464 to 465
		local function clbk(value)
			managers.vr:set_setting(setting, value)
		end

		setting_item = VRSettingSlider:new(self._panel, setting, table.map_append({
			setting = setting,
			parent_menu = self
		}, params))
	elseif type == "multi_button" then
		if not params.options then
			Application:error("Tried to add a multi_button setting without options: " .. setting)

			params.options = {"error"}
		end

		local option_count = #params.options
		setting_item = VRSettingButton:new(self._panel, setting, table.map_append({
			setting = setting,
			parent_menu = self
		}, params))


		-- Lines: 477 to 487
		function clbk(btn)
			local current_index = table.index_of(params.options, managers.vr:get_setting(setting))
			local new_index = current_index % option_count + 1
			local new_value = params.options[new_index]

			managers.vr:set_setting(setting, new_value)
			btn:setting_changed()

			if params.clbk then
				params.clbk(new_value)
			end
		end
	elseif type == "trigger" then
		params.text_id = params.trigger_text_id
		setting_item = VRSettingTrigger:new(self._panel, setting, table.map_append({
			setting = setting,
			parent_menu = self
		}, params))


		-- Lines: 491 to 494
		function clbk(btn)
			local value = params.value_clbk(btn)

			managers.vr:set_setting(setting, value)
		end
	end

	setting_item:set_y(num_settings * 100 + y_offset)
	setting_item:set_right(self._panel:w() - PADDING)
	setting_text:set_w((self._panel:w() - setting_item:w()) - PADDING * 2)
	make_fine_text(setting_text)
	table.insert(self._buttons, {
		button = setting_item,
		clbk = clbk,
		custom_params = {
			x = setting_item:x(),
			y = setting_item:y()
		}
	})

	self._settings[setting] = {
		text = setting_text,
		button = setting_item
	}
end

-- Lines: 506 to 513
function VRSubMenu:set_setting_enabled(setting, enabled)
	local item = self:setting(setting)

	if item then
		item.text:set_visible(enabled)
		item.button:set_visible(enabled)
		item.button:set_enabled(enabled)
	end
end

-- Lines: 515 to 521
function VRSubMenu:add_button(id, text, clbk, custom_params)
	custom_params = custom_params or {}
	local button = VRButton:new(self._panel, id, {
		text_id = text,
		parent_menu = self
	})

	button:set_x(custom_params.x or ((self._buttons[#self._buttons] and self._buttons[#self._buttons].button:left() or self._panel:w()) - button:w()) - PADDING)
	button:set_y(custom_params.y or (self._panel:h() - button:h()) - PADDING)
	table.insert(self._buttons, {
		button = button,
		clbk = clbk,
		custom_params = custom_params
	})

	return button
end

-- Lines: 524 to 531
function VRSubMenu:set_button_enabled(id, enabled)
	for _, button in ipairs(self._buttons) do
		if button.button:id() == id then
			button.button:set_enabled(enabled)
		end
	end

	self:layout_buttons()
end

-- Lines: 533 to 541
function VRSubMenu:layout_buttons()
	local last_x = self._panel:w()

	for _, button in ipairs(self._buttons) do
		if button.button:enabled() and not button.custom_params.x then
			button.button:set_x((last_x - button.button:w()) - PADDING)

			last_x = button.button:x()
		end
	end
end

-- Lines: 543 to 570
function VRSubMenu:add_image(params)
	if not params or not params.texture then
		Application:error("[VRSubMenu:add_image] tried to add missing image!")

		return
	end

	local image = self._panel:bitmap({
		texture = params.texture,
		x = params.x,
		y = params.y,
		w = params.w,
		h = params.h
	})

	if params.fit then
		if params.fit == "height" then
			local h = self._panel:h()
			local dh = h / image:texture_height()

			image:set_size(image:texture_width() * dh, h)
		elseif params.fit == "width" then
			local w = self._panel:w()
			local dw = w / image:texture_width()

			image:set_size(w, image:texture_height() * dw)
		else
			image:set_size(self._panel:w(), self._panel:h())
		end
	end
end

-- Lines: 572 to 585
function VRSubMenu:set_temp_text(text_id, color)
	self:clear_temp_text()

	self._temp_text = self._panel:text({
		word_wrap = true,
		wrap = true,
		text = managers.localization:text(text_id),
		font = tweak_data.menu.pd2_large_font,
		font_size = tweak_data.menu.pd2_large_font_size,
		color = color or Color.white,
		y = self._desc:bottom() + PADDING
	})

	make_fine_text(self._temp_text)
end

-- Lines: 587 to 592
function VRSubMenu:clear_temp_text()
	if alive(self._temp_text) then
		self._panel:remove(self._temp_text)

		self._temp_text = nil
	end
end

-- Lines: 594 to 595
function VRSubMenu:id()
	return self._id
end

-- Lines: 598 to 600
function VRSubMenu:set_enabled_clbk(clbk)
	self._enabled_clbk = clbk
end

-- Lines: 602 to 609
function VRSubMenu:set_enabled(enabled)
	if self._enabled_clbk then
		self:_enabled_clbk(enabled)
	end

	self._enabled = enabled

	self._panel:set_visible(enabled)
end

-- Lines: 611 to 612
function VRSubMenu:enabled()
	return self._enabled
end
VRCustomizationGui = VRCustomizationGui or class(VRMenu)

-- Lines: 619 to 636
function VRCustomizationGui:init(is_start_menu)
	VRCustomizationGui.super.init(self)

	self._is_start_menu = is_start_menu
	self._ws = managers.gui_data:create_fullscreen_workspace("left")

	managers.menu:player():register_workspace({
		ws = self._ws,
		activate = callback(self, self, "activate"),
		deactivate = callback(self, self, "deactivate")
	})

	self._id = "vr_customization"

	if not is_start_menu then
		self:initialize()
	else
		self._ws:hide()
	end
end

-- Lines: 638 to 654
function VRCustomizationGui:initialize()
	if not self._initialized then
		self:_setup_gui()
		managers.vr:show_savefile_dialog()

		if not managers.vr:has_set_height() then
			managers.menu:show_vr_settings_dialog()
			self:open_sub_menu("height")
		end

		self._ws:show()

		self._initialized = true
	end
end

-- Lines: 656 to 698
function VRCustomizationGui:_setup_gui()
	if alive(self._panel) then
		self._panel:clear()
	end

	self._panel = self._ws:panel():panel({})
	self._buttons = {}
	self._bg = self._panel:bitmap({
		texture = "guis/dlcs/vr/textures/pd2/bg",
		name = "bg",
		layer = -2
	})
	local h = self._panel:h()
	local dh = h / self._bg:texture_height()

	self._bg:set_size(self._bg:texture_width() * dh, h)
	self:_setup_sub_menus()
	self:add_back_button()

	local controls_image_paths = {
		touch_dash_walk = "guis/dlcs/vr/textures/pd2/menu_controls_touch_dash_walk",
		vive_dash_walk = "guis/dlcs/vr/textures/pd2/menu_controls_vive_dash_walk",
		touch_dash = "guis/dlcs/vr/textures/pd2/menu_controls_touch_dash",
		vive_dash = "guis/dlcs/vr/textures/pd2/menu_controls_vive_dash"
	}
	self._controls_images = {}

	for key, path in pairs(controls_image_paths) do
		local controls_image = self._panel:bitmap({
			texture = path,
			x = self._panel:w() * 0.2 + PADDING,
			y = PADDING
		})
		local h = self._panel:h() - PADDING * 2
		local dh = h / controls_image:texture_height()

		controls_image:set_size(controls_image:texture_width() * dh, h)
		controls_image:set_visible(false)

		self._controls_images[key] = controls_image
	end

	self:_check_controls()
end

-- Lines: 700 to 704
function VRCustomizationGui:_hide_controls()
	for _, image in pairs(self._controls_images) do
		image:set_visible(false)
	end
end

-- Lines: 706 to 718
function VRCustomizationGui:_check_controls()
	local image_key = nil
	local movement_type = managers.vr:get_setting("movement_type") or "warp"

	if managers.vr:is_oculus() then
		image_key = movement_type == "warp_walk" and "touch_dash_walk" or "touch_dash"
	else
		image_key = movement_type == "warp_walk" and "vive_dash_walk" or "vive_dash"
	end

	for key, image in pairs(self._controls_images) do
		image:set_visible(image_key == key)
	end
end

-- Lines: 720 to 779
function VRCustomizationGui:_setup_sub_menus()
	self._sub_menus = {}
	self._open_menu = nil
	local is_start_menu = self._is_start_menu

	self:add_sub_menu("height", "menu_vr_height_desc", {
		{
			text = "menu_vr_calibrate",
			id = "calibrate",
			clbk = function (btn)
				local hmd_pos = VRManager:hmd_position()

				managers.vr:set_setting("height", hmd_pos.z)
				managers.system_menu:close("vr_settings")
				btn:parent_menu():set_temp_text("menu_vr_height_success", Color.green)
			end
		},
		{
			text = "menu_vr_reset",
			id = "reset",
			clbk = function (btn)
				managers.vr:reset_setting("height")
			end
		}
	})
	self:add_settings_menu("belt", {{
		setting = "belt_snap",
		type = "slider",
		text_id = "menu_vr_belt_snap",
		params = {snap = 15}
	}}, function (menu, enabled)
		if enabled then
			if not menu:object("belt") then
				menu:add_object("belt", VRBeltCustomization:new(is_start_menu))
			end
		elseif menu:object("belt") then
			menu:remove_object("belt")
		end
	end)
	self:add_settings_menu("gameplay", {
		{
			setting = "auto_reload",
			type = "button",
			text_id = "menu_vr_auto_reload_text"
		},
		{
			setting = "default_weapon_hand",
			type = "multi_button",
			text_id = "menu_vr_default_weapon_hand",
			params = {
				options = {
					"right",
					"left"
				},
				clbk = function (value)
					managers.menu:set_primary_hand(value)
				end
			}
		},
		{
			setting = "default_tablet_hand",
			type = "multi_button",
			text_id = "menu_vr_default_tablet_hand",
			params = {options = {
				"left",
				"right"
			}}
		},
		{
			setting = "weapon_assist_toggle",
			type = "button",
			text_id = "menu_vr_weapon_assist_toggle"
		},
		{
			type = "multi_button",
			setting = "rotate_player_angle",
			text_id = "menu_vr_rotate_player_angle",
			params = {options = {
				45,
				90
			}},
			visible = function ()
				return managers.vr:is_oculus()
			end
		}
	})
	self:add_settings_menu("controls", {
		{
			setting = "movement_type",
			type = "multi_button",
			text_id = "menu_vr_movement_type",
			params = {
				w = 260,
				options = {
					"warp",
					"warp_walk"
				}
			}
		},
		{
			type = "slider",
			setting = "warp_zone_size",
			text_id = "menu_vr_warp_zone_size",
			params = {snap = 5},
			visible = function ()
				return managers.vr:is_default_hmd()
			end
		},
		{
			setting = "dead_zone_size",
			type = "slider",
			text_id = "menu_vr_dead_zone_size",
			params = {snap = 5}
		},
		{
			setting = "enable_dead_zone_warp",
			type = "button",
			text_id = "menu_vr_enable_dead_zone_warp"
		},
		{
			setting = "weapon_switch_button",
			type = "button",
			text_id = "menu_vr_weapon_switch_button"
		}
	})
	self:add_settings_menu("advanced", {
		{
			setting = "autowarp_length",
			type = "multi_button",
			text_id = "menu_vr_autowarp_length",
			params = {options = {
				"off",
				"long",
				"short"
			}}
		},
		{
			setting = "zipline_screen",
			type = "button",
			text_id = "menu_vr_zipline_screen"
		}
	})
end

-- Lines: 781 to 782
function VRCustomizationGui:sub_menu(id)
	return self._sub_menus[id]
end

-- Lines: 785 to 799
function VRCustomizationGui:add_sub_menu(id, desc, buttons, clbk)
	local menu = VRSubMenu:new(self._panel, id)

	menu:add_desc(desc)
	menu:set_enabled_clbk(clbk)

	for _, button in ipairs(buttons) do
		local btn = menu:add_button(button.id, button.text, button.clbk)

		if button.enabled ~= nil then
			btn:set_enabled(button.enabled)
		end
	end

	menu:layout_buttons()

	self._sub_menus[id] = menu

	self:add_menu_button(id)
end

-- Lines: 801 to 831
function VRCustomizationGui:add_settings_menu(id, settings, clbk)
	local menu = VRSubMenu:new(self._panel, id)

	menu:set_enabled_clbk(clbk)
	menu:add_button("reset_" .. id, "menu_vr_reset", function ()
		for setting, item in pairs(menu._settings) do
			managers.vr:reset_setting(setting)
			item.button:setting_changed()
		end

		for _, object in pairs(menu._objects) do
			if object.reset then
				object:reset()
			end
		end
	end)

	for _, setting in ipairs(settings) do
		local visible = setting.visible == nil
		visible = visible or type(setting.visible) == "function" and setting.visible() or not not setting.visible

		if visible then
			menu:add_setting(setting.type, setting.text_id, setting.setting, setting.params)
		end
	end

	self._sub_menus[id] = menu

	self:add_menu_button(id)
end

-- Lines: 833 to 839
function VRCustomizationGui:add_image_menu(id, params, clbk)
	local menu = VRSubMenu:new(self._panel, id)

	menu:set_enabled_clbk(clbk)
	menu:add_image(params)

	self._sub_menus[id] = menu

	self:add_menu_button(id)
end

-- Lines: 841 to 848
function VRCustomizationGui:open_sub_menu(id)
	self:close_sub_menu()
	self:_hide_controls()

	self._open_menu = self._sub_menus[id]

	self._open_menu:set_enabled(true)
end

-- Lines: 850 to 857
function VRCustomizationGui:close_sub_menu()
	if self._open_menu then
		self._open_menu:set_enabled(false)

		self._open_menu = nil

		self:_check_controls()
	end
end

-- Lines: 859 to 864
function VRCustomizationGui:add_menu_button(id)
	local x = PADDING
	local y = PADDING + (self._buttons[#self._buttons] and self._buttons[#self._buttons].button:bottom() or 0)
	local button = VRButton:new(self._panel, id, {
		text_id = "menu_vr_open_" .. id,
		x = x,
		y = y
	})

	table.insert(self._buttons, {
		button = button,
		clbk = callback(self, self, "open_sub_menu", id)
	})
end

-- Lines: 866 to 871
function VRCustomizationGui:add_back_button()
	local x = PADDING
	local y = (self._panel:h() - 75) - PADDING
	local button = VRButton:new(self._panel, "back", {
		text_id = "menu_vr_back",
		x = x,
		y = y
	})

	table.insert(self._buttons, {
		button = button,
		clbk = callback(self, self, "close_sub_menu")
	})
end

-- Lines: 873 to 877
function VRCustomizationGui:update(t, dt)
	if self._open_menu then
		self._open_menu:update(t, dt)
	end
end

-- Lines: 879 to 889
function VRCustomizationGui:activate()
	local clbks = {
		mouse_move = callback(self, self, "mouse_moved"),
		mouse_click = callback(self, self, "mouse_clicked"),
		mouse_press = callback(self, self, "mouse_pressed"),
		mouse_release = callback(self, self, "mouse_released"),
		id = self._id
	}

	managers.mouse_pointer:use_mouse(clbks)

	self._active = true
end

-- Lines: 891 to 894
function VRCustomizationGui:deactivate()
	managers.mouse_pointer:remove_mouse(self._id)

	self._active = false
end

-- Lines: 896 to 906
function VRCustomizationGui:exit_menu()
	for _, menu in pairs(self._sub_menus) do
		menu:clear_objects()
	end

	if self._active then
		self:deactivate()
	end

	self:_setup_gui()
end
VRBeltAdjuster = VRBeltAdjuster or class()

-- Lines: 912 to 970
function VRBeltAdjuster:init(scene, belt, params)
	local offset = params.offset or Vector3()
	local up = params.up or math.Z
	self._obj = belt:orientation_object()
	offset = offset:rotate_with(self._obj:rotation())

	if params.horizontal then
		self._ws = scene:gui():create_linked_workspace(512, 128, self._obj, belt:position() + offset, math.X * 40, -up * 10)
	else
		self._ws = scene:gui():create_linked_workspace(256, 300, self._obj, belt:position() + offset, math.X * 20, -up * 24.5)
	end

	local panel = self._ws:panel()
	self._up_arrow = panel:bitmap({
		texture = "guis/dlcs/vr/textures/pd2/icon_belt_arrow",
		name = "up_arrow",
		texture_rect = {
			128,
			0,
			128,
			128
		}
	})

	if params.horizontal then
		self._up_arrow:set_right(panel:w())
		self._up_arrow:set_rotation(90)
	else
		self._up_arrow:set_center_x(panel:w() / 2)
	end

	self._down_arrow = panel:bitmap({
		texture = "guis/dlcs/vr/textures/pd2/icon_belt_arrow",
		name = "down_arrow",
		rotation = 180,
		texture_rect = {
			128,
			0,
			128,
			128
		}
	})

	if params.horizontal then
		self._down_arrow:set_rotation(-90)
	else
		self._down_arrow:set_center_x(panel:w() / 2)
		self._down_arrow:set_bottom(panel:h())
	end

	self._text_id = params.text_id
	self._text = panel:text({
		name = "text",
		text = managers.localization:to_upper_text(self._text_id),
		font = tweak_data.hud.medium_font_noshadow,
		font_size = tweak_data.hud.default_font_size
	})

	make_fine_text(self._text)
	self._text:set_center(panel:w() / 2, panel:h() / 2)

	self._offset = offset

	if params.horizontal then
		self._center = (self._offset + Vector3(20, 0, 0)) - up * 5
	else
		self._center = (self._offset + Vector3(10, 0, 0)) - up * 12.25
	end

	self:set_help_state("inactive")

	self._stationary = params.stationary
	self._update_func = params.update_func
	self._save_func = params.save_func
end

-- Lines: 972 to 974
function VRBeltAdjuster:destroy()
	self._ws:gui():destroy_workspace(self._ws)
end

-- Lines: 976 to 977
function VRBeltAdjuster:center()
	return self._obj:position() + self._center:rotate_with(self._obj:rotation())
end

-- Lines: 980 to 981
function VRBeltAdjuster:stationary()
	return self._stationary
end

-- Lines: 984 to 988
function VRBeltAdjuster:update(pos)
	if self._update_func then
		self._update_func(pos)
	end
end

-- Lines: 990 to 994
function VRBeltAdjuster:save()
	if self._save_func then
		self._save_func()
	end
end

-- Lines: 996 to 1016
function VRBeltAdjuster:set_help_state(state)
	if state == self._state then
		return
	end

	self._state = state
	local grip = state == "grip"
	local inactive = state == "inactive"
	local x = grip and 0 or 128

	self._up_arrow:set_texture_rect(x, 0, 128, 128)
	self._up_arrow:set_alpha(inactive and 0.2 or 1)
	self._down_arrow:set_texture_rect(x, 0, 128, 128)
	self._down_arrow:set_alpha(inactive and 0.2 or 1)
	self._text:set_alpha(inactive and 0.5 or 1)
	self._text:set_text(managers.localization:to_upper_text(grip and "menu_vr_belt_release" or self._text_id))
	make_fine_text(self._text)
	self._text:set_center_x(self._ws:panel():w() / 2)
end
VRBeltCustomization = VRBeltCustomization or class()

-- Lines: 1021 to 1104
function VRBeltCustomization:init(is_start_menu)
	local scene = is_start_menu and World or MenuRoom
	local player = managers.menu:player()
	self._belt_unit = World:spawn_unit(Idstring("units/pd2_dlc_vr/player/vr_hud_belt"), Vector3(0, 0, 0), Rotation())

	self._belt_unit:set_visible(false)

	self._ws = scene:gui():create_world_workspace(1280, 680, Vector3(), math.X, math.Y)
	self._belt = HUDBelt:new(self._ws)

	HUDManagerVR.link_belt(self._ws, self._belt_unit)

	self._height = managers.vr:get_setting("height") * managers.vr:get_setting("belt_height_ratio")
	self._distance = managers.vr:get_setting("belt_distance")

	self._belt_unit:set_position(player:position():with_z(self._height) - Vector3(20, 0, 0))
	self._belt_unit:set_rotation(Rotation((VRManager:hmd_rotation() * player:base_rotation()):yaw()))
	self._belt:set_alpha(0.4)
	player._hand_state_machine:enter_hand_state(player:primary_hand_index(), "customization")
	player._hand_state_machine:enter_hand_state(3 - player:primary_hand_index(), "customization_empty")

	self._adjusters = {
		VRBeltAdjuster:new(scene, self._belt_unit, {
			text_id = "menu_vr_belt_grip_height",
			offset = Vector3(-10, 10, 24.5),
			up = math.Z,
			update_func = function (pos)
				local height = managers.vr:get_setting("height")
				local min, max = managers.vr:setting_limits("belt_height_ratio")
				local z = pos.z

				if min and max then
					z = math.clamp(z, height * min, height * max)
				end

				self._height = z
			end,
			save_func = function ()
				managers.vr:set_setting("belt_height_ratio", self._height / managers.vr:get_setting("height"))
			end
		}),
		VRBeltAdjuster:new(scene, self._belt_unit, {
			text_id = "menu_vr_belt_grip_distance",
			offset = Vector3(-10, 10, 0),
			up = math.Y,
			update_func = function (pos)
				local min, max = managers.vr:setting_limits("belt_distance")
				local relative_pos = (pos - managers.menu:player():position()):rotate_with(self._belt_unit:rotation():inverse())
				local y = relative_pos.y

				if min and max then
					y = math.clamp(y, min, max)
				end

				self._distance = y
			end,
			save_func = function ()
				managers.vr:set_setting("belt_distance", self._distance)
			end
		}),
		VRBeltAdjuster:new(scene, self._belt_unit, {
			horizontal = true,
			text_id = "menu_vr_belt_grip_radius",
			stationary = true,
			offset = Vector3(-20, -12, 0),
			up = math.Y,
			update_func = function (pos)
				local size = managers.vr:get_setting("belt_size")
				local min, max = managers.vr:setting_limits("belt_size")
				local x = (pos - self._grip_pos):rotate_with(self._belt_unit:rotation():inverse()).x
				size = size + x

				if min and max then
					size = math.clamp(size, min, max)
				end

				self._size = size

				HUDManagerVR.link_belt(self._ws, self._belt_unit, size)
			end,
			save_func = function ()
				managers.vr:set_setting("belt_size", self._size)
			end
		})
	}

	managers.menu:active_menu().input:focus(false)
	managers.menu:active_menu().input:focus(true)
end

-- Lines: 1106 to 1115
function VRBeltCustomization:reset()
	managers.vr:reset_setting("belt_height_ratio")
	managers.vr:reset_setting("belt_distance")
	managers.vr:reset_setting("belt_size")

	self._height = managers.vr:get_setting("belt_height_ratio") * managers.vr:get_setting("height")
	self._distance = managers.vr:get_setting("belt_distance")
	self._size = managers.vr:get_setting("belt_size")

	HUDManagerVR.link_belt(self._ws, self._belt_unit)
end

-- Lines: 1117 to 1136
function VRBeltCustomization:destroy()
	self._ws:gui():destroy_workspace(self._ws)

	for _, adjuster in ipairs(self._adjusters) do
		adjuster:destroy()
	end

	local player = managers.menu:player()

	player._hand_state_machine:enter_hand_state(player:primary_hand_index(), "laser")
	player._hand_state_machine:enter_hand_state(3 - player:primary_hand_index(), "empty")

	if managers.menu:active_menu() then
		managers.menu:active_menu().input:focus(false)
		managers.menu:active_menu().input:focus(true)
	end

	self._belt:destroy()
	World:delete_unit(self._belt_unit)
end

-- Lines: 1138 to 1210
function VRBeltCustomization:update(t, dt)
	local player = managers.menu:player()
	local hands = {
		player:hand(1),
		player:hand(2)
	}
	local adjusters = self._adjusters

	for i, hand in ipairs(hands) do
		if not self._active_hand_id or i == self._active_hand_id then
			local interact_btn = "interact_" .. (i == 1 and "right" or "left")
			local held = managers.menu:get_controller():get_input_bool(interact_btn)

			if self._active_adjuster then
				local adjuster = self._active_adjuster

				if mvector3.distance_sq(hand:position(), adjuster:center()) > 225 and (not adjuster:stationary() or not held) then
					adjuster:set_help_state("inactive")

					self._active_adjuster = nil
				else
					if managers.menu:get_controller():get_input_pressed(interact_btn) then
						self._grip_offset = hand:position() - self._belt_unit:position()
						self._grip_pos = hand:position() - self._grip_offset
					end

					if held and self._grip_offset then
						local new_pos = hand:position() - self._grip_offset

						adjuster:update(new_pos)
						adjuster:set_help_state("grip")

						break
					else
						adjuster:set_help_state("active")
					end
				end

				if managers.menu:get_controller():get_input_released(interact_btn) then
					adjuster:save()

					self._active_adjuster = nil
				end
			end

			if not held then
				local closest, new_adjuster = nil

				for _, adjuster in ipairs(adjusters) do
					local dis = mvector3.distance_sq(hand:position(), adjuster:center())

					if dis < 225 and (not closest or dis < closest) then
						closest = dis
						new_adjuster = adjuster
					end
				end

				if self._active_adjuster and self._active_adjuster ~= new_adjuster then
					self._active_adjuster:set_help_state("inactive")
				end

				self._active_adjuster = new_adjuster

				if not self._active_adjuster then
					self._active_hand_id = nil
				else
					self._active_hand_id = i
				end
			end
		end
	end

	self._belt_unit:set_position(player:position():with_z(self._height) + math.Y:rotate_with(self._belt_unit:rotation()) * self._distance)

	local hmd_rot = VRManager:hmd_rotation() * player:base_rotation()
	local snap_angle = managers.vr:get_setting("belt_snap")
	local yaw_rot = Rotation(hmd_rot:yaw())
	local angle = Rotation:rotation_difference(Rotation(self._belt_unit:rotation():yaw()), yaw_rot):yaw()
	angle = math.abs(angle)

	if snap_angle < angle then
		self._belt_unit:set_rotation(yaw_rot)
	end
end

