UGCItem = UGCItem or class()
UGCItem.CONFIG_NAME = "item.xml"
UGCItem.INFO_NAME = "info.xml"
UGCItem.PREVIEW_FILE = "preview.png"
UGCItem.TMP_FILE = "tmp"
UGCItem.DEFAULT_TAGS = {}
UGCItem.DEFAULT_VISIBILITY = "hidden"
local UGC = Steam:ugc_handler()


-- Lines: 13 to 15
local function time_stamp()
	local t = os.date("*t")

	return string.format("%04u%03u%02u%02u%02u", t.year, t.yday, t.hour, t.min, t.sec)
end


-- Lines: 22 to 23
function UGCItem.SortByTimestamp(lhs, rhs)
	return rhs._config.timestamp < lhs._config.timestamp
end

-- Lines: 27 to 43
function UGCItem:init(item_path)
	self._item_path = item_path
	self._staging_path = item_path
	self._config_path = item_path .. UGCItem.CONFIG_NAME
	self._info_path = item_path .. UGCItem.INFO_NAME
	self._preview_path = self._staging_path .. UGCItem.PREVIEW_FILE
	self._config = {timestamp = time_stamp()}
	self._info = {
		visibility = UGCItem.DEFAULT_VISIBILITY,
		tags = UGCItem.DEFAULT_TAGS
	}
end

-- Lines: 46 to 47
function UGCItem:path()
	return self._item_path
end

-- Lines: 51 to 52
function UGCItem:staging_path()
	return self._staging_path
end

-- Lines: 56 to 57
function UGCItem:config()
	return self._config
end

-- Lines: 63 to 72
function UGCItem:load()
	if not self:_load_config() then
		return false
	end

	self:_load_info()
	print("[UGCItem:load] Loaded item configuration")

	return true
end

-- Lines: 78 to 84
function UGCItem:save()
	self:_save_config()
	self:_save_info()
	print("[UGCItem:save] Saved item configuration")

	return true
end

-- Lines: 97 to 114
function UGCItem:submit(changenotes, callback)
	local valid, err = self:_valid_for_submission()

	if not valid then
		if callback then
			callback(err, self)
		end

		return false
	end

	if not self._ugc_item then
		print("[UGCItem:submit] No item exists")

		if callback then
			callback("error", self)
		end
	end

	return self:_submit_item(changenotes, callback)
end

-- Lines: 123 to 147
function UGCItem:prepare_for_submit(callback)
	local valid, err = self:_valid_for_submission()

	if not valid then
		if callback then
			callback(err, self)
		end

		return false
	end

	if not self._ugc_item then
		print("[UGCItem:submit] Creating item")


		-- Lines: 135 to 144
		local function on_create_callback(result, item)
			if result == "success" then
				self._ugc_item = item

				self:_save_info()
			end

			if callback then
				callback(result, self)
			end
		end

		return UGC:create_item("curated", on_create_callback)
	end
end

-- Lines: 149 to 150
function UGCItem:item_exists()
	return self._ugc_item and true or false
end

-- Lines: 153 to 156
function UGCItem:set_staging_path(path)
	self._staging_path = path
	self._preview_path = self._staging_path .. UGCItem.PREVIEW_FILE
end

-- Lines: 161 to 163
function UGCItem:set_visibility(visibility)
	self._info.visibility = visibility
end

-- Lines: 165 to 166
function UGCItem:visibility()
	return self._info.visibility
end

-- Lines: 169 to 171
function UGCItem:set_title(title)
	self._info.title = title
end

-- Lines: 173 to 174
function UGCItem:title()
	return self._info.title
end

-- Lines: 177 to 179
function UGCItem:set_description(description)
	self._info.description = description
end

-- Lines: 181 to 182
function UGCItem:description()
	return self._info.description
end

-- Lines: 185 to 187
function UGCItem:add_tag(tag)
	self._info.tags[tag] = true
end

-- Lines: 189 to 191
function UGCItem:clear_tags()
	self._info.tags = {}
end

-- Lines: 193 to 194
function UGCItem:tags()
	return self._info.tags
end

-- Lines: 197 to 199
function UGCItem:set_metadata(metadata)
	self._info.metadata = metadata
end

-- Lines: 201 to 202
function UGCItem:metadata()
	return self._info.metadata
end

-- Lines: 205 to 206
function UGCItem:id()
	return self._ugc_item and self._ugc_item:get_id() or nil
end

-- Lines: 214 to 215
function UGCItem:is_valid()
	return self:_valid_for_submission()
end

-- Lines: 219 to 220
function UGCItem:is_submitted()
	return self._ugc_item ~= nil
end

-- Lines: 224 to 225
function UGCItem:is_submitting()
	return self._ugc_item and self._ugc_item:is_submitting()
end

-- Lines: 229 to 233
function UGCItem:get_update_progress()
	if not self._ugc_item then
		return 0, "error"
	end

	return self._ugc_item:get_update_progress()
end

-- Lines: 238 to 269
function UGCItem:_submit_item(changenotes, callback)
	if not self._ugc_item then
		print("[UGCItem:submit] Error no UGC item created!")

		return false
	end

	local item = self._ugc_item

	if item:is_submitting() then
		print("[UGCItem:submit] item already submitting!")

		return false
	end


	-- Lines: 251 to 257
	local function on_submit_item(result, item)
		print("[UGCItem:_submit_item] Result ", result)

		if callback then
			callback(result, self)
		end
	end

	self:_save_info()

	if not item:start_update() then
		print("[UGCItem:submit] start update failed!")

		return false
	end

	self:_prepare_item_info(item)

	return item:submit_update(changenotes, on_submit_item)
end

-- Lines: 272 to 289
function UGCItem:_valid_for_submission()
	if not SystemFS:exists(self._preview_path) then
		print("[UGCItem:_validate_submission] Preview image does not exists!", self._preview_path)

		return false, "error_preview"
	end

	local info = self._info

	if not info.title or string.len(info.title) < 1 then
		print("[UGCItem:_validate_submission] Not a valid item title")

		return false, "error_title"
	end

	if not info.description or string.len(info.description) < 1 then
		print("[UGCItem:_validate_submission] Not a valid item description")

		return false, "error_description"
	end

	return true
end

-- Lines: 292 to 326
function UGCItem:_prepare_item_info(item)
	item:set_content(self._staging_path)
	item:set_preview(self._preview_path)

	local info = self._info

	if info and info.tags then
		local tags = {}
		local i = 1

		for tag, enabled in pairs(info.tags) do
			if enabled then
				tags[i] = tag
				i = i + 1
			end
		end

		item:set_tags(tags)
	end
end

-- Lines: 330 to 375
function UGCItem:_load_xml(path, load_node_func, root_node, param_preprocessor)
	if not SystemFS:exists(path) then
		return false
	end

	local node = SystemFS:parse_xml(path)

	if load_node_func and not load_node_func(node) then
		return false
	end

	local to_process = {}
	local cur_table = root_node

	for child in node:children() do
		table.insert(to_process, {
			node = child,
			parent = root_node
		})
	end

	while table.getn(to_process) >= 1 do
		local element = table.remove(to_process)
		local node = element.node
		local parent = element.parent
		cur_table = parent

		if node:name() == "node" then
			local name = node:parameter("name")
			cur_table[name] = {}

			for child in node:children() do
				table.insert(to_process, {
					node = child,
					parent = cur_table[name]
				})
			end
		elseif node:name() == "param" then
			local key = node:parameter("key")
			local value = node:parameter("value")

			if key ~= nil and value ~= nil then
				if param_preprocessor then
					value = param_preprocessor(key, value)
				end

				cur_table[key] = value
			end
		end
	end

	return true
end


-- Lines: 378 to 383
local function indent_string(str, indent)
	local s = ""

	for i = 1, indent, 1 do
		s = s .. "\t"
	end

	return s .. str
end


-- Lines: 386 to 456
function UGCItem:_save_xml(path, node_name, attributes, params, param_preprocessor)
	local tmp_path = path .. ".tmp"
	local file = SystemFS:open(tmp_path, "w")

	if file ~= nil then
		attributes = attributes and " " .. attributes or ""

		file:puts("<" .. node_name .. attributes .. ">")

		local to_process = {}

		for k, v in pairs(params) do
			table.insert(to_process, {
				level = 1,
				first = k,
				second = v
			})
		end

		while table.getn(to_process) >= 1 do
			local element = table.remove(to_process)
			local k = element.first
			local v = element.second
			local t = element.type
			local level = element.level

			if param_preprocessor then
				v = param_preprocessor(k, v)
			end

			if type(v) == "table" then
				table.insert(to_process, {
					type = "end_node",
					first = k,
					level = level
				})

				for k, v in pairs(v) do
					table.insert(to_process, {
						first = k,
						second = v,
						level = level + 1
					})
				end

				table.insert(to_process, {
					type = "start_node",
					first = k,
					level = level
				})
			elseif t == "start_node" then
				file:puts(indent_string("<node name=\"" .. k .. "\">", level))
			elseif t == "end_node" then
				file:puts(indent_string("</node>", level))
			else
				file:puts(indent_string("<param key=\"" .. k .. "\"" .. " value=\"" .. tostring(v) .. "\"/>", level))
			end
		end

		file:puts("</" .. node_name .. ">")
		SystemFS:close(file)
		SystemFS:copy_file(tmp_path, path)
		SystemFS:delete_file(tmp_path)

		return true
	end

	return false
end

-- Lines: 466 to 481
function UGCItem:_load_config()

	-- Lines: 460 to 466
	local function parse_vector(key, value)
		if string.find(value, "Vector3") then
			local x, y, z = string.match(value, "Vector3%(([-+]?[0-9]*.?[0-9]*), ([-+]?[0-9]*.?[0-9]*), ([-+]?[0-9]*.?[0-9]*)%)")
			value = Vector3(x, y, z)
		end

		return value
	end

	local config = {}

	if self:_load_xml(self._config_path, function (node)
		return node:name() == "ugcitem"
	end, config, parse_vector) then
		self._config = config

		return true
	end

	return false
end

-- Lines: 485 to 492
function UGCItem:_save_config()
	self._config.timestamp = time_stamp()

	if not self:_save_xml(self._config_path, "ugcitem", nil, self._config) then
		print("[UGCItem:_save_config] Failed to save item configuration!")

		return
	end
end


-- Lines: 495 to 504
local function tags_to_string(tags)
	local tag_string = nil

	for tag, enabled in pairs(tags) do
		tag_string = tag_string ~= nil and tag_string .. ":" .. tag or tag
	end

	return tag_string
end


-- Lines: 508 to 516
local function string_to_tags(tags_string)
	local tags = {}

	for tag in string.gmatch(tags_string, "([^:]+)") do
		if tag and string.len(tag) > 0 then
			tag = tag:gsub("^%s*(.-)%s*$", "%1")
			tags[tag] = true
		end
	end

	return tags
end


-- Lines: 519 to 542
function UGCItem:_load_info()
	local info = {}

	if self:_load_xml(self._info_path, function (node)
		if node:name() ~= "ugcinfo" then
			return false
		end

		local id = node:parameter("id")
		self._ugc_item = UGC:get_item(id)

		return true
	end, info, function (key, value)
		if key == "tags" then
			return string_to_tags(value)
		end

		return value
	end) then
		self._info = info

		return true
	end

	return false
end

-- Lines: 545 to 565
function UGCItem:_save_info()
	if not self._ugc_item then
		return
	end


	-- Lines: 551 to 555
	local function param_preprocessor(key, value)
		if key == "tags" then
			return tags_to_string(value)
		end

		return value
	end

	self._info.timestamp = time_stamp()
	local id = self._ugc_item:get_id()

	if id and self._info and not self:_save_xml(self._info_path, "ugcinfo", "id=\"" .. id .. "\"", self._info, param_preprocessor) then
		print("[UGCItem:_save_info] Failed to save item info!")

		return
	end
end
