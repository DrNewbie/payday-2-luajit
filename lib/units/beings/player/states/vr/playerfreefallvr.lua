PlayerFreefallVR = PlayerFreefall or Application:error("PlayerFreefallVR needs PlayerFreefall!")
local __enter = PlayerFreefall.enter

-- Lines: 5 to 10
function PlayerFreefallVR:enter(...)
	__enter(self, ...)
	self._camera_unit:base():set_hmd_tracking(false)
	managers.menu:open_menu("zipline")
end
local __exit = PlayerFreefall.exit

-- Lines: 13 to 18
function PlayerFreefallVR:exit(...)
	__exit(self, ...)
	managers.menu:close_menu("zipline")
	self._camera_unit:base():set_hmd_tracking(true)
end

-- Lines: 20 to 22
function PlayerFreefallVR:_update_variables(t, dt)
	self._current_height = self._ext_movement:hmd_position().z
end
local __update_movement = PlayerFreefall._update_movement

-- Lines: 25 to 29
function PlayerFreefallVR:_update_movement(t, dt)
	__update_movement(self, t, dt)
	self._unit:movement():set_ghost_position(self._unit:position())
end

