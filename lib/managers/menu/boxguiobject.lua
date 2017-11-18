BoxGuiObject = BoxGuiObject or class()
local mvector_tl = Vector3()
local mvector_tr = Vector3()
local mvector_bl = Vector3()
local mvector_br = Vector3()

-- Lines: 8 to 10
function BoxGuiObject:init(panel, config)
	self:create_sides(panel, config)
end

-- Lines: 12 to 35
function BoxGuiObject:create_sides(panel, config)
	if not alive(panel) then
		Application:error("[BoxGuiObject:create_sides] Failed creating BoxGui. Parent panel not alive!")
		Application:stack_dump()

		return
	end

	if alive(self._panel) then
		self._panel:parent():remove(self._panel)

		self._panel = nil
	end

	self._panel = panel:panel({
		layer = 1,
		halign = "scale",
		valign = "scale",
		name = config.name,
		w = config.w,
		h = config.h
	})
	self._color = config.color or self._color or Color.white
	local left_side = config.sides and config.sides[1] or config.left or 0
	local right_side = config.sides and config.sides[2] or config.right or 0
	local top_side = config.sides and config.sides[3] or config.top or 0
	local bottom_side = config.sides and config.sides[4] or config.bottom or 0

	self:_create_side(self._panel, "left", left_side, config.texture)
	self:_create_side(self._panel, "right", right_side, config.texture)
	self:_create_side(self._panel, "top", top_side, config.texture)
	self:_create_side(self._panel, "bottom", bottom_side, config.texture)
end

-- Lines: 37 to 166
function BoxGuiObject:_create_side(panel, side, type, texture)
	local ids_side = Idstring(side)
	local ids_left = Idstring("left")
	local ids_right = Idstring("right")
	local ids_top = Idstring("top")
	local ids_bottom = Idstring("bottom")
	local left_or_right = false
	local w, h = nil

	if ids_side == ids_left or ids_side == ids_right then
		left_or_right = true
		w = 2
		h = panel:h()
	else
		w = panel:w()
		h = 2
	end

	local side_panel = panel:panel({
		name = side,
		w = w,
		h = h,
		halign = left_or_right and side or "scale",
		valign = left_or_right and "scale" or side
	})

	if type == 0 then
		return
	elseif type == 1 or type == 3 or type == 4 then
		local one = side_panel:bitmap({texture = texture or "guis/textures/pd2/shared_lines"})
		local two = side_panel:bitmap({texture = texture or "guis/textures/pd2/shared_lines"})
		local x = math.random(1, 255)
		local y = math.random(0, one:texture_height() / 2 - 1) * 2
		local tw = math.min(10, w)
		local th = math.min(10, h)

		if left_or_right then
			one:set_halign(side)
			two:set_halign(side)
			one:set_valign("scale")
			two:set_valign("scale")
			mvector3.set_static(mvector_tl, x, y + tw, 0)
			mvector3.set_static(mvector_tr, x, y, 0)
			mvector3.set_static(mvector_bl, x + th, y + tw, 0)
			mvector3.set_static(mvector_br, x + th, y, 0)
			one:set_texture_coordinates(mvector_tl, mvector_tr, mvector_bl, mvector_br)

			x = math.random(1, 255)
			y = math.random(0, math.round(one:texture_height() / 2 - 1)) * 2

			mvector3.set_static(mvector_tl, x, y + tw, 0)
			mvector3.set_static(mvector_tr, x, y, 0)
			mvector3.set_static(mvector_bl, x + th, y + tw, 0)
			mvector3.set_static(mvector_br, x + th, y, 0)
			two:set_texture_coordinates(mvector_tl, mvector_tr, mvector_bl, mvector_br)
			one:set_size(2, th)
			two:set_size(2, th)
			two:set_bottom(h)
		else
			one:set_halign("scale")
			two:set_halign("scale")
			one:set_valign(side)
			two:set_valign(side)
			mvector3.set_static(mvector_tl, x, y, 0)
			mvector3.set_static(mvector_tr, x + tw, y, 0)
			mvector3.set_static(mvector_bl, x, y + th, 0)
			mvector3.set_static(mvector_br, x + tw, y + th, 0)
			one:set_texture_coordinates(mvector_tl, mvector_tr, mvector_bl, mvector_br)

			x = math.random(1, 255)
			y = math.random(0, math.round(one:texture_height() / 2 - 1)) * 2

			mvector3.set_static(mvector_tl, x, y, 0)
			mvector3.set_static(mvector_tr, x + tw, y, 0)
			mvector3.set_static(mvector_bl, x, y + th, 0)
			mvector3.set_static(mvector_br, x + tw, y + th, 0)
			two:set_texture_coordinates(mvector_tl, mvector_tr, mvector_bl, mvector_br)
			one:set_size(tw, 2)
			two:set_size(tw, 2)
			two:set_right(w)
		end

		one:set_visible(type == 1 or type == 3)
		two:set_visible(type == 1 or type == 4)
	elseif type == 2 then
		local full = side_panel:bitmap({
			texture = texture or "guis/textures/pd2/shared_lines",
			w = side_panel:w(),
			h = side_panel:h()
		})
		local x = math.random(1, 255)
		local y = math.random(0, math.round(full:texture_height() / 2 - 1)) * 2

		if left_or_right then
			full:set_halign(side)
			full:set_valign("scale")
			mvector3.set_static(mvector_tl, x, y + w, 0)
			mvector3.set_static(mvector_tr, x, y, 0)
			mvector3.set_static(mvector_bl, x + h, y + w, 0)
			mvector3.set_static(mvector_br, x + h, y, 0)
			full:set_texture_coordinates(mvector_tl, mvector_tr, mvector_bl, mvector_br)
		else
			full:set_halign("scale")
			full:set_valign(side)
			mvector3.set_static(mvector_tl, x, y, 0)
			mvector3.set_static(mvector_tr, x + w, y, 0)
			mvector3.set_static(mvector_bl, x, y + h, 0)
			mvector3.set_static(mvector_br, x + w, y + h, 0)
			full:set_texture_coordinates(mvector_tl, mvector_tr, mvector_bl, mvector_br)
		end
	else
		Application:error("[BoxGuiObject] Type", type, "is not supported")
		Application:stack_dump()

		return
	end

	side_panel:set_position(0, 0)

	if ids_side == ids_right then
		side_panel:set_right(panel:w())
	elseif ids_side == ids_bottom then
		side_panel:set_bottom(panel:h())
	end

	return side_panel
end

-- Lines: 169 to 172
function BoxGuiObject:hide()
	self._panel:hide()
end

-- Lines: 174 to 177
function BoxGuiObject:show()
	self._panel:show()
end

-- Lines: 179 to 182
function BoxGuiObject:set_visible(visible)
	self._panel:set_visible(visible)
end

-- Lines: 184 to 185
function BoxGuiObject:visible()
	return self._panel:visible()
end

-- Lines: 188 to 190
function BoxGuiObject:set_layer(layer)
	self._panel:set_layer(layer)
end

-- Lines: 192 to 193
function BoxGuiObject:size()
	return self._panel:size()
end

-- Lines: 196 to 197
function BoxGuiObject:alive()
	return alive(self._panel)
end

-- Lines: 200 to 210
function BoxGuiObject:inside(x, y, side)
	if not self:alive() then
		return false
	end

	if side then
		return self._panel:child(side) and self._panel:child(side):inside(x, y)
	else
		return self._panel:inside(x, y)
	end
end

-- Lines: 212 to 217
function BoxGuiObject:set_aligns(halign, valign)
	for i, d in pairs(self._panel:children()) do
		d:set_valign(valign)
		d:set_halign(halign)
	end
end

-- Lines: 219 to 227
function BoxGuiObject:set_clipping(clip, rec_panel)
	for i, d in pairs(rec_panel and rec_panel:children() or self._panel:children()) do
		if d.set_rotation then
			d:set_rotation(clip and 0 or 360)
		else
			self:set_clipping(clip, d)
		end
	end
end

-- Lines: 229 to 230
function BoxGuiObject:color()
	return self._color
end

-- Lines: 233 to 242
function BoxGuiObject:set_color(color, rec_panel)
	self._color = color

	for i, d in pairs(rec_panel and rec_panel:children() or self._panel:children()) do
		if d.set_color then
			d:set_color(color)
		else
			self:set_color(color, d)
		end
	end
end

-- Lines: 244 to 245
function BoxGuiObject:blend_mode()
	return self._blend_mode
end

-- Lines: 248 to 257
function BoxGuiObject:set_blend_mode(blend_mode, rec_panel)
	self._blend_mode = blend_mode

	for i, d in pairs(rec_panel and rec_panel:children() or self._panel:children()) do
		if d.set_blend_mode then
			d:set_blend_mode(blend_mode)
		else
			self:set_blend_mode(blend_mode, d)
		end
	end
end

-- Lines: 259 to 263
function BoxGuiObject:close()
	if alive(self._panel) and alive(self._panel:parent()) then
		self._panel:parent():remove(self._panel)
	end
end

