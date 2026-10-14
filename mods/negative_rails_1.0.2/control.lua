local negative = {
  ["negative-straight-rail"] = "straight-rail",
  ["negative-half-diagonal-rail"] = "half-diagonal-rail",
  ["negative-curved-rail-a"] = "curved-rail-a",
  ["negative-curved-rail-b"] = "curved-rail-b"
}
local markers = require("scripts.markers")

local function give_rail(player_index)
  local player = game.get_player(player_index)
  if player and player.clear_cursor() then
    -- A real item allows instant fast-replacement and consumes the old rail.
    -- Ghost planning keeps the original entity until robots actually mine it.
    player.cursor_ghost = "negative-rail"
  end
end

script.on_event("give-negative-rail", function(event) give_rail(event.player_index) end)
script.on_event(defines.events.on_lua_shortcut, function(event)
  if event.prototype_name == "give-negative-rail" then give_rail(event.player_index) end
end)

script.on_event(defines.events.on_player_pipette, function(event)
  if event.item.name == "negative-rail" then give_rail(event.player_index) end
end)

script.on_configuration_changed(function()
  -- Saved cursors from earlier versions can still contain a real item.
  for _, player in pairs(game.players) do
    if player.cursor_stack and player.cursor_stack.valid_for_read
      and player.cursor_stack.name == "negative-rail" then give_rail(player.index) end
  end
  -- Upgrade old physical template rails without changing ordinary rail pieces.
  for _, surface in pairs(game.surfaces) do
    for _, entity in pairs(surface.find_entities_filtered({name=markers.names})) do
      local name, position, direction, force, quality = entity.name, entity.position,
        entity.direction, entity.force, entity.quality
      entity.destroy()
      local ghost = surface.create_entity({name="entity-ghost",inner_name=name,
        position=position,direction=direction,force=force,quality=quality})
      if ghost then markers.keep(ghost, force) end
    end
  end
end)

script.on_event(defines.events.on_object_destroyed, markers.destroyed)
script.on_event(defines.events.on_marked_for_deconstruction, function(event)
  if event.entity.valid and event.entity.name == markers.proxy_name then
    markers.remove(event.entity.unit_number)
  end
end)
script.on_event(defines.events.on_pre_ghost_deconstructed, function(event)
  local entity = event.ghost
  if entity and entity.valid and entity.tags and entity.tags.negative_rails_proxy then
    markers.remove(entity.tags.negative_rails_proxy)
  end
end)
script.on_event(defines.events.on_player_setup_blueprint, function(event)
  local blueprint = event.stack
  if not blueprint or not blueprint.is_blueprint or not blueprint.is_blueprint_setup() then
    blueprint = event.record
  end
  if blueprint and blueprint.is_blueprint_setup() then
    markers.rewrite(blueprint, event.mapping.get())
  end
end)

script.on_event(defines.events.on_marked_for_upgrade, function(event)
  if not negative[event.target.name] then return end
  local entity = event.entity
  local player = event.player_index and game.get_player(event.player_index)
  if entity.valid and not negative[entity.name] then
    -- Both calls raise events immediately. Sandbox/instant construction mods
    -- can destroy the entity inside those events, before this callback resumes.
    local force = entity.force
    local position = entity.position
    entity.cancel_upgrade(force, player)
    if not entity.valid then return end
    if entity.order_deconstruction(force, player) then
      log("Negative Rails: converted upgrade to demolition at " .. serpent.line(position))
    end
  end
end)

script.on_event({defines.events.on_built_entity, defines.events.on_robot_built_entity, defines.events.script_raised_built,
  defines.events.script_raised_revive}, function(event)
  local entity = event.entity
  if not entity.valid then return end
  local name = entity.type == "entity-ghost" and entity.ghost_name or entity.name
  local shape = negative[name]
  if not shape then return end
  local player = event.player_index and game.get_player(event.player_index)
  -- Real negative rails are never allowed to become a usable railway.
  if entity.type ~= "entity-ghost" then
    local surface, position, direction, force, quality = entity.surface,
      entity.position, entity.direction, entity.force, entity.quality
    entity.destroy()
    local owner = player and player.force or force
    if owner.name == markers.force_name then
      owner = event.tags and event.tags.negative_rails_owner
        and game.forces[event.tags.negative_rails_owner] or game.forces.player
    end
    local ghost = surface.create_entity({name="entity-ghost",inner_name=name,
      position=position,direction=direction,force=force,quality=quality})
    if ghost then markers.keep(ghost, owner) end
    return
  end
  if entity.force.name == markers.force_name and entity.tags
    and entity.tags.negative_rails_proxy then return end
  local surface, position, direction, force = entity.surface, entity.position, entity.direction, entity.force
  local owner = player and player.force or force
  local matched = false
  for _, rail in pairs(surface.find_entities_filtered({
    -- Curved rail collision boxes need not include their entity origin.
    -- Search broadly, then compare native rail geometry exactly.
    position = position, radius = 16, type = shape, force = owner
  })) do
    if rail.valid and not negative[rail.name] and rail.direction == direction
      and math.abs(rail.position.x-position.x) < 0.01
      and math.abs(rail.position.y-position.y) < 0.01 then
      matched = true
      rail.order_deconstruction(owner, player)
    end
  end
  -- Rail path planning can omit on_pre_build entirely. Classify by the cursor,
  -- not by a cached build-mode event: a path may contain both demolition and
  -- new template pieces. Blueprint placement keeps its one-shot behavior.
  if entity.valid and not matched and player and not player.is_cursor_blueprint() then
    markers.keep(entity, owner)
    return
  end
  if entity.valid then entity.destroy() end
end)
