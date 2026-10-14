local M = {}
M.force_name = "negative-rails-markers"
M.proxy_name = "negative-rail-copy-marker"
M.names = {"negative-straight-rail", "negative-half-diagonal-rail",
  "negative-curved-rail-a", "negative-curved-rail-b"}

local function marker_force(owner)
  local force = game.forces[M.force_name] or game.create_force(M.force_name)
  force.set_friend(owner, true)
  owner.set_friend(force, true)
  force.set_cease_fire(owner, true)
  owner.set_cease_fire(force, true)
  return force
end

function M.keep(ghost, owner)
  local surface, position, direction, name, quality = ghost.surface, ghost.position,
    ghost.direction, ghost.ghost_name, ghost.quality
  local force = marker_force(owner)
  ghost.force = force
  if not ghost.valid then
    ghost = surface.create_entity({name="entity-ghost",inner_name=name,
      position=position,direction=direction,quality=quality,force=force})
  end
  if not ghost then return end
  local proxy = surface.create_entity({name=M.proxy_name,position=position,force=owner})
  if not proxy then ghost.destroy(); return end
  ghost.tags = {negative_rails_proxy=proxy.unit_number,negative_rails_owner=owner.index}
  storage.nr_markers = storage.nr_markers or {}
  storage.nr_objects = storage.nr_objects or {}
  local id = proxy.unit_number
  storage.nr_markers[id] = {ghost=ghost,proxy=proxy}
  storage.nr_objects[script.register_on_object_destroyed(ghost)] = id
  storage.nr_objects[script.register_on_object_destroyed(proxy)] = id
  return ghost
end

function M.remove(id)
  local marker = storage.nr_markers and storage.nr_markers[id]
  if not marker then return end
  storage.nr_markers[id] = nil
  if marker.ghost.valid then marker.ghost.destroy() end
  if marker.proxy.valid then marker.proxy.destroy() end
end

function M.destroyed(event)
  local id = storage.nr_objects and storage.nr_objects[event.registration_number]
  if id then
    storage.nr_objects[event.registration_number] = nil
    M.remove(id)
  end
end

-- Geometry stays encoded as native rails in the resulting blueprint. Rotation
-- and mirroring remain the engine's job, rather than transforming custom tags.
function M.rewrite(blueprint, mapping)
  local entities = blueprint.get_blueprint_entities()
  if not entities then return end
  local changed = false
  local direct = {}
  for _, entry in pairs(entities) do
    if entry.tags and entry.tags.negative_rails_proxy then
      direct[entry.tags.negative_rails_proxy] = true
    end
  end
  local result = {}
  for _, entry in pairs(entities) do
    local include = true
    if entry.name == M.proxy_name then
      local proxy = mapping[entry.entity_number]
      if proxy and proxy.valid then
        if direct[proxy.unit_number] then
          include = false
          changed = true
        else
        for _, ghost in pairs(proxy.surface.find_entities_filtered({name="entity-ghost",
          force=M.force_name,ghost_name=M.names,position=proxy.position,radius=16})) do
          if ghost.tags and ghost.tags.negative_rails_proxy == proxy.unit_number then
            entry.name = ghost.ghost_name
            entry.direction = ghost.direction
            entry.quality = ghost.quality.name
            changed = true
            break
          end
        end
        end
      end
    end
    if entry.tags and entry.tags.negative_rails_proxy then
      entry.tags.negative_rails_proxy = nil
      entry.tags.negative_rails_owner = nil
      if next(entry.tags) == nil then entry.tags = nil end
      changed = true
    end
    if include then result[#result+1] = entry end
  end
  if changed then blueprint.set_blueprint_entities(result) end
end

return M
