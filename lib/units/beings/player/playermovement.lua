require("lib/units/beings/player/states/PlayerMovementState")
require("lib/units/beings/player/states/PlayerEmpty")
require("lib/units/beings/player/states/PlayerStandard")
require("lib/units/beings/player/states/PlayerClean")
require("lib/units/beings/player/states/PlayerCivilian")
require("lib/units/beings/player/states/PlayerMaskOff")
require("lib/units/beings/player/states/PlayerBleedOut")
require("lib/units/beings/player/states/PlayerFatal")
require("lib/units/beings/player/states/PlayerArrested")
require("lib/units/beings/player/states/PlayerTased")
require("lib/units/beings/player/states/PlayerIncapacitated")
require("lib/units/beings/player/states/PlayerCarry")
require("lib/units/beings/player/states/PlayerBipod")
require("lib/units/beings/player/states/PlayerDriving")
require("lib/units/beings/player/states/PlayerFreefall")
require("lib/units/beings/player/states/PlayerParachuting")

PlayerMovement = PlayerMovement or class()
PlayerMovement._STAMINA_INIT = tweak_data.player.movement_state.stamina.STAMINA_INIT or 10
PlayerMovement.OUT_OF_WORLD_Z = -4000

-- Lines: 27 to 88
function PlayerMovement:init(unit)
	self._unit = unit

	unit:set_timer(managers.player:player_timer())
	unit:set_animation_timer(managers.player:player_timer())

	self._machine = self._unit:anim_state_machine()
	self._next_check_out_of_world_t = 1
	self._nav_tracker = nil
	self._pos_rsrv_id = nil

	self:set_driving("script")

	self._m_pos = unit:position()
	self._m_stand_pos = mvector3.copy(self._m_pos)

	mvector3.set_z(self._m_stand_pos, self._m_pos.z + 140)

	self._m_com = math.lerp(self._m_pos, self._m_stand_pos, 0.5)
	self._kill_overlay_t = managers.player:player_timer():time() + 5
	self._state_data = {
		in_air = false,
		ducking = false
	}
	self._synced_suspicion = false
	self._suspicion_ratio = false
	self._SO_access = managers.navigation:convert_access_flag("teamAI1")
	self._regenerate_timer = nil
	self._stamina = self:_max_stamina()
	self._underdog_skill_data = {
		max_dis_sq = 3240000,
		chk_t = 6,
		chk_interval_active = 6,
		nr_enemies = 3,
		max_vert_dis = 1000,
		chk_interval_inactive = 1,
		has_dmg_dampener = managers.player:has_category_upgrade("temporary", "dmg_dampener_outnumbered") or managers.player:has_category_upgrade("temporary", "dmg_dampener_outnumbered_strong"),
		has_dmg_mul = managers.player:has_category_upgrade("temporary", "dmg_multiplier_outnumbered")
	}

	if managers.player:has_category_upgrade("player", "morale_boost") or managers.player:has_category_upgrade("cooldown", "long_dis_revive") then
		local data = managers.player:upgrade_value("cooldown", "long_dis_revive", nil)
		self._rally_skill_data = {
			range_sq = 810000,
			morale_boost_delay_t = managers.player:has_category_upgrade("player", "morale_boost") and 0 or nil,
			long_dis_revive = managers.player:has_category_upgrade("cooldown", "long_dis_revive"),
			revive_chance = data and type(data) ~= "number" and data[1] or 0,
			morale_boost_cooldown_t = tweak_data.upgrades.morale_boost_base_cooldown * managers.player:upgrade_value("player", "morale_boost_cooldown_multiplier", 1)
		}
	end

	self:set_friendly_fire(true)
end

-- Lines: 94 to 111
function PlayerMovement:post_init()
	self._m_head_rot = self._unit:camera()._m_cam_rot
	self._m_head_pos = self._unit:camera()._m_cam_pos

	if managers.navigation:is_data_ready() and (not Global.running_simulation or Global.running_simulation_with_mission) then
		self._nav_tracker = managers.navigation:create_nav_tracker(self._unit:position())
		self._pos_rsrv_id = managers.navigation:get_pos_reservation_id()
	end

	self._unit:inventory():add_listener("PlayerMovement" .. tostring(self._unit:key()), {
		"add",
		"equip",
		"unequip"
	}, callback(self, self, "inventory_clbk_listener"))
	self:_setup_states()

	self._attention_handler = CharacterAttentionObject:new(self._unit, true)
	self._enemy_weapons_hot_listen_id = "PlayerMovement" .. tostring(self._unit:key())

	managers.groupai:state():add_listener(self._enemy_weapons_hot_listen_id, {"enemy_weapons_hot"}, callback(self, self, "clbk_enemy_weapons_hot"))
end

-- Lines: 115 to 116
function PlayerMovement:attention_handler()
	return self._attention_handler
end

-- Lines: 121 to 122
function PlayerMovement:nav_tracker()
	return self._nav_tracker
end

-- Lines: 127 to 128
function PlayerMovement:pos_rsrv_id()
	return self._pos_rsrv_id
end

-- Lines: 134 to 144
function PlayerMovement:warp_to(pos, rot, velocity)
	self._unit:warp_to(rot, pos)

	if velocity then
		self:push(velocity)
	end

	local camera_base = self:current_state()._camera_unit:base()
	camera_base._camera_properties.spin = rot:yaw() + 90
	camera_base._camera_properties.pitch = rot:pitch()
end

-- Lines: 148 to 170
function PlayerMovement:_setup_states()
	local unit = self._unit
	self._states = {
		empty = PlayerEmpty:new(unit),
		standard = PlayerStandard:new(unit),
		mask_off = PlayerMaskOff:new(unit),
		bleed_out = PlayerBleedOut:new(unit),
		fatal = PlayerFatal:new(unit),
		arrested = PlayerArrested:new(unit),
		tased = PlayerTased:new(unit),
		incapacitated = PlayerIncapacitated:new(unit),
		clean = PlayerClean:new(unit),
		civilian = PlayerCivilian:new(unit),
		carry = PlayerCarry:new(unit),
		bipod = PlayerBipod:new(unit),
		driving = PlayerDriving:new(unit),
		jerry2 = PlayerParachuting:new(unit),
		jerry1 = PlayerFreefall:new(unit)
	}
end

-- Lines: 174 to 236
function PlayerMovement:set_character_anim_variables()
	local char_name = managers.criminals:character_name_by_unit(self._unit)
	local mesh_names = nil
	local lvl_tweak_data = Global.level_data and Global.level_data.level_id and tweak_data.levels[Global.level_data.level_id]
	local unit_suit = lvl_tweak_data and lvl_tweak_data.unit_suit or "suit"
	mesh_names = not lvl_tweak_data and {
		spanish = "",
		russian = "",
		german = "",
		american = ""
	} or unit_suit == "cat_suit" and {
		spanish = "_chains",
		russian = "",
		german = "",
		american = ""
	} or managers.player._player_mesh_suffix == "_scrubs" and {
		spanish = "_chains",
		russian = "",
		german = "",
		american = ""
	} or {
		spanish = "_chains",
		russian = "_dallas",
		german = "",
		american = "_hoxton"
	}
	local mesh_name = Idstring("g_fps_hand" .. (mesh_names[char_name] or "") .. managers.player._player_mesh_suffix)
	local mesh_obj = self._unit:camera():camera_unit():get_object(mesh_name)

	if mesh_obj then
		if self._plr_mesh_name then
			local old_mesh_obj = self._unit:camera():camera_unit():get_object(self._plr_mesh_name)

			if old_mesh_obj then
				old_mesh_obj:set_visibility(false)
			end
		end

		self._plr_mesh_name = mesh_name

		mesh_obj:set_visibility(true)
	end

	local camera_unit = self._unit:camera():camera_unit()

	if camera_unit:damage() then
		local sequence = managers.blackmarket:character_sequence_by_character_name(char_name)

		if camera_unit:damage():has_sequence(sequence) then
			camera_unit:damage():run_sequence_simple(sequence)
		end
	end
end

-- Lines: 240 to 242
function PlayerMovement:set_driving(mode)
	self._unit:set_driving(mode)
end

-- Lines: 245 to 262
function PlayerMovement:change_state(name)
	local exit_data = nil

	if self._current_state then
		exit_data = self._current_state:exit(self._state_data, name)
	end

	local new_state = self._states[name]
	self._current_state = new_state
	self._current_state_name = name
	self._state_enter_t = managers.player:player_timer():time()

	new_state:enter(self._state_data, exit_data)
	self._unit:network():send("sync_player_movement_state", self._current_state_name, self._unit:character_damage():down_time(), self._unit:id())
end

-- Lines: 266 to 289
function PlayerMovement:update(unit, t, dt)
	self:_calculate_m_pose()

	if self:_check_out_of_world(t) then
		return
	end

	self:_upd_underdog_skill(t)

	if self._current_state then
		self._current_state:update(t, dt)
	end

	if self._kill_overlay_t and self._kill_overlay_t < t then
		self._kill_overlay_t = nil

		managers.overlay_effect:stop_effect()
	end

	self:update_stamina(t, dt)
end

-- Lines: 291 to 310
function PlayerMovement:update_stamina(t, dt, ignore_running)
	local dt = self._last_stamina_regen_t and t - self._last_stamina_regen_t or dt
	self._last_stamina_regen_t = t

	if not ignore_running and self._is_running then
		self:subtract_stamina(dt * tweak_data.player.movement_state.stamina.STAMINA_DRAIN_RATE)
	elseif self._regenerate_timer then
		self._regenerate_timer = self._regenerate_timer - dt

		if self._regenerate_timer < 0 then
			self:add_stamina(dt * tweak_data.player.movement_state.stamina.STAMINA_REGEN_RATE)

			if self:_max_stamina() <= self._stamina then
				self._regenerate_timer = nil
			end
		end
	elseif self._stamina < self:_max_stamina() then
		self:_restart_stamina_regen_timer()
	end
end

-- Lines: 314 to 317
function PlayerMovement:set_position(pos)
	self._unit:set_position(pos)
end

-- Lines: 321 to 325
function PlayerMovement:set_m_pos(pos)
	mvector3.set(self._m_pos, pos)
	mvector3.set(self._m_stand_pos, pos)
	mvector3.set_z(self._m_stand_pos, pos.z + 140)
end

-- Lines: 329 to 330
function PlayerMovement:m_pos()
	return self._m_pos
end

-- Lines: 335 to 336
function PlayerMovement:m_stand_pos()
	return self._m_stand_pos
end

-- Lines: 341 to 342
function PlayerMovement:m_com()
	return self._m_com
end

-- Lines: 347 to 348
function PlayerMovement:m_head_pos()
	return self._m_head_pos
end

-- Lines: 353 to 354
function PlayerMovement:m_head_rot()
	return self._m_head_rot
end

-- Lines: 359 to 360
function PlayerMovement:m_detect_pos()
	return self._m_head_pos
end

-- Lines: 365 to 366
function PlayerMovement:m_newest_pos()
	return self._m_pos
end

-- Lines: 371 to 372
function PlayerMovement:get_object(object_name)
	return self._unit:get_object(object_name)
end

-- Lines: 382 to 386
function PlayerMovement:downed()
	return self._current_state_name == "bleed_out" or self._current_state_name == "fatal" or self._current_state_name == "arrested" or self._current_state_name == "incapacitated"
end

-- Lines: 392 to 393
function PlayerMovement:current_state()
	return self._current_state
end

-- Lines: 398 to 400
function PlayerMovement:_calculate_m_pose()
	mvector3.lerp(self._m_com, self._m_pos, self._m_head_pos, 0.5)
end

-- Lines: 402 to 410
function PlayerMovement:_check_out_of_world(t)
	if self._next_check_out_of_world_t < t then
		self._next_check_out_of_world_t = t + 1

		if mvector3.z(self._m_pos) < PlayerMovement.OUT_OF_WORLD_Z then
			managers.player:on_out_of_world()

			return true
		end
	end

	return false
end

-- Lines: 415 to 417
function PlayerMovement:play_redirect(redirect_name, at_time)
	local result = self._unit:play_redirect(Idstring(redirect_name), at_time)

	return result ~= Idstring("") and result
end

-- Lines: 422 to 424
function PlayerMovement:play_state(state_name, at_time)
	local result = self._unit:play_state(Idstring(state_name), at_time)

	return result ~= Idstring("") and result
end

-- Lines: 429 to 430
function PlayerMovement:chk_action_forbidden(action_type)
	return self._current_state.chk_action_forbidden and self._current_state:chk_action_forbidden(action_type)
end

-- Lines: 435 to 436
function PlayerMovement:get_melee_damage_result(...)
	return self._current_state.get_melee_damage_result and self._current_state:get_melee_damage_result(...)
end

-- Lines: 441 to 448
function PlayerMovement:linked(state, physical, parent_unit)
	if state then
		self._link_data = {
			physical = physical,
			parent = parent_unit
		}

		parent_unit:base():add_destroy_listener("PlayerMovement" .. tostring(self._unit:key()), callback(self, self, "parent_clbk_unit_destroyed"))
	else
		self._link_data = nil
	end
end

-- Lines: 452 to 455
function PlayerMovement:parent_clbk_unit_destroyed(parent_unit, key)
	self._link_data = nil

	parent_unit:base():remove_destroy_listener("PlayerMovement" .. tostring(self._unit:key()))
end

-- Lines: 459 to 460
function PlayerMovement:is_physically_linked()
	return self._link_data and self._link_data.physical
end

-- Lines: 465 to 475
function PlayerMovement:on_cuffed()
	if self._unit:character_damage()._god_mode then
		return
	end

	if self._current_state_name == "standard" or self._current_state_name == "bipod" or self._current_state_name == "bleed_out" or self._current_state_name == "carry" or self._current_state_name == "mask_off" or self._current_state_name == "clean" or self._current_state_name == "civilian" then
		managers.player:set_player_state("arrested")
	else
		debug_pause("[PlayerMovement:on_cuffed] transition failed", self._current_state_name)
	end
end

-- Lines: 477 to 478
function PlayerMovement:is_cuffed()
	return self._current_state_name == "arrested"
end

-- Lines: 483 to 491
function PlayerMovement:on_uncovered(enemy_unit)
	if self._current_state_name ~= "mask_off" and self._current_state_name ~= "clean" or self._current_state_name == "civilian" then
		return
	end

	self._state_data.uncovered = true

	managers.player:set_player_state("standard")

	self._state_data.uncovered = nil
end

-- Lines: 496 to 517
function PlayerMovement:on_SPOOCed(enemy_unit)
	if managers.player:has_category_upgrade("player", "counter_strike_spooc") and self._current_state.in_melee and self._current_state:in_melee() then
		self._current_state:discharge_melee()

		return "countered"
	end

	if self._unit:character_damage()._god_mode or self._unit:character_damage():get_mission_blocker("invulnerable") then
		return
	end

	if self._current_state_name == "standard" or self._current_state_name == "carry" or self._current_state_name == "bleed_out" or self._current_state_name == "tased" or self._current_state_name == "bipod" then
		local state = "incapacitated"
		state = managers.crime_spree:modify_value("PlayerMovement:OnSpooked", state)

		managers.player:set_player_state(state)
		managers.achievment:award(tweak_data.achievement.finally.award)

		return true
	end
end

-- Lines: 521 to 528
function PlayerMovement:is_SPOOC_attack_allowed()
	if self._unit:character_damage():get_mission_blocker("invulnerable") or self._unit:character_damage().swansong then
		return false
	end

	if self._current_state_name == "driving" then
		return false
	end

	return true
end

-- Lines: 531 to 535
function PlayerMovement:is_taser_attack_allowed()
	if self._unit:character_damage():get_mission_blocker("invulnerable") or self._current_state_name == "driving" or self._unit:base().parachuting then
		return false
	end

	return true
end

-- Lines: 540 to 545
function PlayerMovement:on_non_lethal_electrocution()
	self._state_data.non_lethal_electrocution = true

	if alive(self._unit) then
		self._unit:character_damage():on_tased(true)
	end
end

-- Lines: 549 to 554
function PlayerMovement:on_tase_ended()
	if self._current_state_name == "tased" then
		self._unit:character_damage():erase_tase_data()
		self._current_state:on_tase_ended()
	end
end

-- Lines: 558 to 559
function PlayerMovement:tased()
	return self._current_state_name == "tased"
end

-- Lines: 564 to 565
function PlayerMovement:current_state_name()
	return self._current_state_name
end

-- Lines: 570 to 571
function PlayerMovement:state_enter_time()
	return self._state_enter_t
end

-- Lines: 576 to 594
function PlayerMovement:_create_attention_setting_from_descriptor(setting_desc, setting_name)
	local setting = clone(setting_desc)
	setting.id = setting_name
	setting.filter = managers.groupai:state():get_unit_type_filter(setting.filter)
	setting.reaction = AIAttentionObject[setting.reaction]
	setting.team = self._team

	if setting.notice_clbk then
		if self[setting.notice_clbk] then
			setting.notice_clbk = callback(self, self, setting.notice_clbk)
		else
			debug_pause("[PlayerMovement:_create_attention_setting_from_descriptor] no notice_clbk defined in class", self._unit, setting.notice_clbk)
		end
	end

	if self._apply_attention_setting_modifications then
		self:_apply_attention_setting_modifications(setting)
	end

	return setting
end

-- Lines: 599 to 610
function PlayerMovement:_apply_attention_setting_modifications(setting)
	setting.detection = self._unit:base():detection_settings()

	if managers.player:has_category_upgrade("player", "camouflage_bonus") then
		setting.weight_mul = (setting.weight_mul or 1) * managers.player:upgrade_value("player", "camouflage_bonus", 1)
	end

	if managers.player:has_category_upgrade("player", "camouflage_multiplier") then
		setting.weight_mul = (setting.weight_mul or 1) * managers.player:upgrade_value("player", "camouflage_multiplier", 1)
	end

	if managers.player:has_category_upgrade("player", "uncover_multiplier") then
		setting.weight_mul = (setting.weight_mul or 1) * managers.player:upgrade_value("player", "uncover_multiplier", 1)
	end
end

-- Lines: 617 to 664
function PlayerMovement:set_attention_settings(settings_list)
	local changes = self._attention_handler:chk_settings_diff(settings_list)

	if not changes then
		return
	end

	local all_attentions = nil


	-- Lines: 625 to 637
	local function _add_attentions_to_all(names)
		for _, setting_name in ipairs(names) do
			local setting_desc = tweak_data.attention.settings[setting_name]

			if setting_desc then
				all_attentions = all_attentions or {}
				local setting = self:_create_attention_setting_from_descriptor(setting_desc, setting_name)
				all_attentions[setting_name] = setting
			else
				debug_pause_unit(self._unit, "[PlayerMovement:set_attention_settings] invalid setting", setting_name, self._unit)
			end
		end
	end

	if changes.added then
		_add_attentions_to_all(changes.added)
	end

	if changes.maintained then
		_add_attentions_to_all(changes.maintained)
	end

	self._attention_handler:set_settings_set(all_attentions)

	if Network:is_client() and changes.removed then
		for _, id in ipairs(changes.removed) do
			local index = tweak_data.attention:get_attention_index(id)

			self._unit:network():send_to_host("set_attention_enabled", index, false)
		end
	end
end

-- Lines: 669 to 673
function PlayerMovement:clbk_attention_notice_sneak(observer_unit, status)
	if alive(observer_unit) then
		self:on_suspicion(observer_unit, status)
	end
end

-- Lines: 679 to 717
function PlayerMovement:on_suspicion(observer_unit, status)
	if Network:is_server() then
		self._suspicion_debug = self._suspicion_debug or {}
		self._suspicion_debug[observer_unit:key()] = {
			unit = observer_unit,
			name = observer_unit:name(),
			status = status
		}
		local visible_status = nil
		visible_status = managers.groupai:state():whisper_mode() and status or false
		self._suspicion = self._suspicion or {}

		if visible_status == false or visible_status == true then
			self._suspicion[observer_unit:key()] = nil

			if not next(self._suspicion) then
				self._suspicion = nil
			end

			if visible_status and observer_unit:movement() and not observer_unit:movement():cool() and TimerManager:game():time() - observer_unit:movement():not_cool_t() > 1 then
				self._suspicion_ratio = false

				self:_feed_suspicion_to_hud()

				return
			end
		elseif type(visible_status) == "number" and (not observer_unit:movement() or observer_unit:movement():cool()) then
			self._suspicion[observer_unit:key()] = visible_status
		else
			return
		end

		self:_calc_suspicion_ratio_and_sync(observer_unit, visible_status)
	else
		self._suspicion_ratio = status
	end

	self:_feed_suspicion_to_hud()
end

-- Lines: 721 to 728
function PlayerMovement:_feed_suspicion_to_hud()
	local susp_ratio = self._suspicion_ratio

	if type(susp_ratio) == "number" then
		local offset = self._unit:base():suspicion_settings().hud_offset
		susp_ratio = susp_ratio * (1 - offset) + offset
	end

	managers.hud:set_suspicion(susp_ratio)
end

-- Lines: 733 to 767
function PlayerMovement:_calc_suspicion_ratio_and_sync(observer_unit, status)
	local suspicion_sync = nil

	if self._suspicion and status ~= true then
		local max_suspicion = nil

		for u_key, val in pairs(self._suspicion) do
			if not max_suspicion or max_suspicion < val then
				max_suspicion = val
			end
		end

		if max_suspicion then
			self._suspicion_ratio = max_suspicion
			suspicion_sync = math.ceil(self._suspicion_ratio * 254)
		else
			self._suspicion_ratio = false
			suspicion_sync = false
		end
	elseif type(status) == "boolean" then
		self._suspicion_ratio = status
		suspicion_sync = status and 255 or 0
	else
		self._suspicion_ratio = false
		suspicion_sync = 0
	end

	if suspicion_sync ~= self._synced_suspicion then
		self._synced_suspicion = suspicion_sync
		local peer = managers.network:session():peer_by_unit(self._unit)

		if peer then
			managers.network:session():send_to_peers_synched("suspicion", peer:id(), suspicion_sync)
		end
	end
end

-- Lines: 772 to 785
function PlayerMovement.clbk_msg_overwrite_suspicion(overwrite_data, msg_queue, msg_name, suspect_peer_id, suspicion)
	if msg_queue then
		if overwrite_data.indexes[suspect_peer_id] then
			local index = overwrite_data.indexes[suspect_peer_id]
			local old_msg = msg_queue[index]
			old_msg[3] = suspicion
		else
			table.insert(msg_queue, {
				msg_name,
				suspect_peer_id,
				suspicion
			})

			overwrite_data.indexes[suspect_peer_id] = #msg_queue
		end
	else
		overwrite_data.indexes = {}
	end
end

-- Lines: 789 to 809
function PlayerMovement:clbk_enemy_weapons_hot()
	if self._current_state_name == "mask_off" then
		self:on_uncovered(nil)
	end

	self._suspicion_ratio = false
	self._suspicion = false

	if Network:is_server() and self._synced_suspicion ~= 0 then
		self._synced_suspicion = 0
		local peer = managers.network:session():peer_by_unit(self._unit)

		if peer then
			managers.network:session():send_to_peers_synched("suspicion", peer:id(), 0)
		end
	end

	self:_feed_suspicion_to_hud()
end

-- Lines: 813 to 822
function PlayerMovement:inventory_clbk_listener(unit, event)
	if event == "add" then
		local data = self._unit:inventory():get_latest_addition_hud_data()

		managers.hud:add_weapon(data)
	end

	if self._current_state and self._current_state.inventory_clbk_listener then
		self._current_state:inventory_clbk_listener(unit, event)
	end
end

-- Lines: 826 to 836
function PlayerMovement:chk_play_mask_on_slow_mo(state_data)
	if not state_data.uncovered and managers.enemy:chk_any_unit_in_slotmask_visible(managers.slot:get_mask("enemies"), self._unit:camera():position(), self._nav_trakcer) then
		local effect_id_world = "world_MaskOn_Peer" .. tostring(managers.network:session():local_peer():id())

		managers.time_speed:play_effect(effect_id_world, tweak_data.timespeed.mask_on)

		local effect_id_player = "player_MaskOn_Peer" .. tostring(managers.network:session():local_peer():id())

		managers.time_speed:play_effect(effect_id_player, tweak_data.timespeed.mask_on_player)
	end
end

-- Lines: 840 to 841
function PlayerMovement:SO_access()
	return self._SO_access
end

-- Lines: 846 to 847
function PlayerMovement:rally_skill_data()
	return self._rally_skill_data
end

-- Lines: 853 to 892
function PlayerMovement:_upd_underdog_skill(t)
	local data = self._underdog_skill_data

	if not self._attackers or not data.has_dmg_dampener and not data.has_dmg_mul or t < self._underdog_skill_data.chk_t then
		return
	end

	local my_pos = self._m_pos
	local nr_guys = 0
	local activated = nil

	for u_key, attacker_unit in pairs(self._attackers) do
		if not alive(attacker_unit) then
			self._attackers[u_key] = nil

			return
		end

		local attacker_pos = attacker_unit:movement():m_pos()
		local dis_sq = mvector3.distance_sq(attacker_pos, my_pos)

		if dis_sq < data.max_dis_sq and math.abs(attacker_pos.z - my_pos.z) < data.max_vert_dis then
			nr_guys = nr_guys + 1

			if data.nr_enemies <= nr_guys then
				activated = true

				if data.has_dmg_mul then
					managers.player:activate_temporary_upgrade("temporary", "dmg_multiplier_outnumbered")
				end

				if data.has_dmg_dampener then
					managers.player:activate_temporary_upgrade("temporary", "dmg_dampener_outnumbered")
					managers.player:activate_temporary_upgrade("temporary", "dmg_dampener_outnumbered_strong")
				end

				break
			end
		end
	end

	if nr_guys >= 1 then
		managers.player:activate_temporary_upgrade("temporary", "dmg_dampener_close_contact")
	end

	data.chk_t = t + (activated and data.chk_interval_active or data.chk_interval_inactive)
end

-- Lines: 896 to 906
function PlayerMovement:on_targetted_for_attack(state, attacker_unit)
	if state then
		self._attackers = self._attackers or {}
		self._attackers[attacker_unit:key()] = attacker_unit
	elseif self._attackers then
		self._attackers[attacker_unit:key()] = nil

		if not next(self._attackers) then
			self._attackers = nil
		end
	end
end

-- Lines: 910 to 912
function PlayerMovement:set_carry_restriction(state)
	self._carry_restricted = state
end

-- Lines: 916 to 917
function PlayerMovement:has_carry_restriction()
	return self._carry_restricted
end

-- Lines: 923 to 924
function PlayerMovement:object_interaction_blocked()
	return self._current_state:interaction_blocked()
end

-- Lines: 927 to 929
function PlayerMovement:interupt_interact()
	self._current_state:interupt_interact()
end

-- Lines: 933 to 945
function PlayerMovement:on_morale_boost(benefactor_unit)
	if self._morale_boost then
		managers.enemy:reschedule_delayed_clbk(self._morale_boost.expire_clbk_id, TimerManager:game():time() + tweak_data.upgrades.morale_boost_time)
	else
		self._morale_boost = {
			expire_clbk_id = "PlayerMovement_morale_boost" .. tostring(self._unit:key()),
			move_speed_bonus = tweak_data.upgrades.morale_boost_speed_bonus,
			suppression_resistance = tweak_data.upgrades.morale_boost_suppression_resistance,
			reload_speed_bonus = tweak_data.upgrades.morale_boost_reload_speed_bonus
		}

		managers.enemy:add_delayed_clbk(self._morale_boost.expire_clbk_id, callback(self, self, "clbk_morale_boost_expire"), TimerManager:game():time() + tweak_data.upgrades.morale_boost_time)
	end
end

-- Lines: 949 to 950
function PlayerMovement:morale_boost()
	return self._morale_boost
end

-- Lines: 955 to 957
function PlayerMovement:clbk_morale_boost_expire()
	self._morale_boost = nil
end

-- Lines: 961 to 965
function PlayerMovement:push(vel)
	if self._current_state.push then
		self._current_state:push(vel)
	end
end

-- Lines: 969 to 981
function PlayerMovement:set_team(team_data)
	self._team = team_data

	self._attention_handler:set_team(team_data)

	if Network:is_server() and self._unit:id() ~= -1 then
		local team_index = tweak_data.levels:get_team_index(team_data.id)

		if team_index <= 16 then
			self._unit:network():send("sync_unit_event_id_16", "movement", team_index)
		else
			debug_pause_unit(self._unit, "[PlayerMovement:set_team] team limit reached!", team_data.id)
		end
	end
end

-- Lines: 985 to 986
function PlayerMovement:team()
	return self._team
end

-- Lines: 991 to 995
function PlayerMovement:sync_net_event(event_id, peer)
	local team_id = tweak_data.levels:get_team_names_indexed()[event_id]
	local team_data = managers.groupai:state():team_data(team_id)

	self:set_team(team_data)
end

-- Lines: 999 to 1011
function PlayerMovement:set_friendly_fire(state)
	if state then
		if self._friendly_fire then
			self._friendly_fire = self._friendly_fire + 1
		else
			self._friendly_fire = 1
		end
	elseif self._friendly_fire == 1 then
		self._friendly_fire = nil
	else
		self._friendly_fire = self._friendly_fire - 1
	end
end

-- Lines: 1015 to 1016
function PlayerMovement:friendly_fire(unit)
	return self._friendly_fire and true or false
end

-- Lines: 1021 to 1059
function PlayerMovement:save(data)
	local peer_id = managers.network:session():peer_by_unit(self._unit):id()
	data.movement = {
		state_name = self._current_state_name,
		look_fwd = self._m_head_rot:y(),
		peer_id = peer_id,
		character_name = managers.criminals:character_name_by_unit(self._unit),
		attentions = {},
		outfit = managers.network:session():peer(peer_id):profile("outfit_string"),
		outfit_version = managers.network:session():peer(peer_id):outfit_version()
	}

	if self._current_state_name ~= "clean" and self._current_state_name ~= "civilian" then
		if self._current_state_name == "mask_off" then
			-- Nothing
		elseif self._state_data.in_steelsight then
			data.movement.stance = 3
		else
			data.movement.stance = 2
		end
	end

	data.movement.pose = self._state_data.ducking and 2 or 1

	if Network:is_client() then
		for _, settings in ipairs(self._attention_handler:attention_data()) do
			local index = tweak_data.player:get_attention_index("player", settings.id)

			table.insert(data.movement.attentions, index)
		end
	end

	data.zip_line_unit_id = self:zipline_unit() and self:zipline_unit():editor_id()
	data.down_time = self._unit:character_damage():down_time()

	self._current_state:save(data.movement)

	data.movement.team_id = self._team.id
	data.movement.special_material = managers.network:session():peer(peer_id)._special_material
end

-- Lines: 1064 to 1078
function PlayerMovement:pre_destroy(unit)
	self._attention_handler:set_attention(nil)
	self._current_state:pre_destroy(unit)

	if self._nav_tracker then
		managers.navigation:destroy_nav_tracker(self._nav_tracker)

		self._nav_tracker = nil
	end

	if self._enemy_weapons_hot_listen_id then
		managers.groupai:state():remove_listener(self._enemy_weapons_hot_listen_id)

		self._enemy_weapons_hot_listen_id = nil
	end
end

-- Lines: 1082 to 1090
function PlayerMovement:destroy(unit)
	if self._link_data then
		self._link_data.parent:base():remove_destroy_listener("PlayerMovement" .. tostring(self._unit:key()))
	end

	self._current_state:destroy(unit)
	managers.hud:set_suspicion(false)
	SoundDevice:set_rtpc("suspicion", 0)
	SoundDevice:set_rtpc("stamina", 100)
end

-- Lines: 1100 to 1107
function PlayerMovement:_max_stamina()
	local base_stamina = self._STAMINA_INIT + managers.player:stamina_addend()
	local max_stamina = base_stamina * managers.player:body_armor_value("stamina") * managers.player:stamina_multiplier()

	managers.hud:set_max_stamina(max_stamina)

	return max_stamina
end

-- Lines: 1110 to 1126
function PlayerMovement:_change_stamina(value)
	local max_stamina = self:_max_stamina()
	local stamina_maxed = self._stamina == max_stamina
	self._stamina = math.clamp(self._stamina + value, 0, max_stamina)

	managers.hud:set_stamina_value(self._stamina)

	if stamina_maxed and self._stamina < max_stamina then
		self._unit:sound():play("fatigue_breath")
	elseif not stamina_maxed and max_stamina <= self._stamina then
		self._unit:sound():play("fatigue_breath_stop")
	end

	local stamina_to_threshold = max_stamina - tweak_data.player.movement_state.stamina.MIN_STAMINA_THRESHOLD
	local stamina_breath = math.clamp((self._stamina - tweak_data.player.movement_state.stamina.MIN_STAMINA_THRESHOLD) / stamina_to_threshold, 0, 1) * 100

	SoundDevice:set_rtpc("stamina", stamina_breath)
end

-- Lines: 1133 to 1135
function PlayerMovement:subtract_stamina(value)
	self:_change_stamina(-math.abs(value))
end

-- Lines: 1137 to 1139
function PlayerMovement:add_stamina(value)
	self:_change_stamina(math.abs(value) * managers.player:upgrade_value("player", "stamina_regen_multiplier", 1))
end

-- Lines: 1141 to 1142
function PlayerMovement:is_above_stamina_threshold()
	return tweak_data.player.movement_state.stamina.MIN_STAMINA_THRESHOLD < self._stamina
end

-- Lines: 1145 to 1146
function PlayerMovement:is_stamina_drained()
	return self._stamina <= 0
end

-- Lines: 1149 to 1152
function PlayerMovement:set_running(running)
	self._is_running = running

	self:_restart_stamina_regen_timer()
end

-- Lines: 1154 to 1156
function PlayerMovement:_restart_stamina_regen_timer()
	self._regenerate_timer = (tweak_data.player.movement_state.stamina.REGENERATE_TIME or 5) * managers.player:upgrade_value("player", "stamina_regen_timer_multiplier", 1)
end

-- Lines: 1158 to 1159
function PlayerMovement:running()
	return self._is_running
end

-- Lines: 1162 to 1163
function PlayerMovement:crouching()
	return self._state_data.ducking
end

-- Lines: 1166 to 1167
function PlayerMovement:in_air()
	return self._state_data.in_air
end

-- Lines: 1170 to 1171
function PlayerMovement:on_ladder()
	return self._state_data.on_ladder
end

-- Lines: 1176 to 1178
function PlayerMovement:on_enter_ladder(ladder_unit)
	self._ladder_unit = ladder_unit
end

-- Lines: 1180 to 1182
function PlayerMovement:on_exit_ladder()
	self._ladder_unit = nil
end

-- Lines: 1184 to 1185
function PlayerMovement:ladder_unit()
	return self._ladder_unit
end

-- Lines: 1190 to 1192
function PlayerMovement:on_enter_zipline(zipline_unit)
	self._zipline_unit = zipline_unit
end

-- Lines: 1194 to 1199
function PlayerMovement:on_exit_zipline()
	if alive(self._zipline_unit) then
		self._zipline_unit:zipline():set_user(nil)
	end

	self._zipline_unit = nil
end

-- Lines: 1201 to 1202
function PlayerMovement:zipline_unit()
	return self._zipline_unit
end
