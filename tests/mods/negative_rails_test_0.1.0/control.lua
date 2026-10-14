local markers = require("__negative_rails__/scripts/markers")
local function run_tests()
  local surface = game.surfaces[1]
  surface.request_to_generate_chunks({0, 0}, 2)
  surface.force_generate_chunk_requests()
  for _, entity in pairs(surface.find_entities()) do entity.destroy() end
  local tiles = {}
  for x = -64, 64 do for y = -64, 64 do
    tiles[#tiles + 1] = { name = "grass-1", position = {x, y} }
  end end
  surface.set_tiles(tiles)
  local force = game.forces.player
  force.research_all_technologies()
  local inventory = game.create_inventory(1)
  local blueprint = inventory[1]
  blueprint.set_stack({name = "blueprint"})

  local function rail(name, position, direction)
    return assert(surface.create_entity({name = name, position = position,
      direction = direction or defines.direction.north, force = force}))
  end
  local function stamp(entities, position, direction)
    blueprint.set_blueprint_entities(entities)
    blueprint.build_blueprint({surface = surface, force = force, position = position,
      direction = direction or defines.direction.north,
      build_mode = defines.build_mode.superforced, raise_built = true})
  end

  local old = rail("straight-rail", {0, 0})
  stamp({{entity_number = 1, name = "negative-straight-rail", position = {0, 0}}}, {0, 0})
  log("NEGATIVE_TEST overlap: demolition=" .. tostring(old.to_be_deconstructed()) ..
    " upgrade=" .. tostring(old.to_be_upgraded()))
  assert(old.to_be_deconstructed(), "Blueprint overlap did not mark the old rail")
  assert(not old.to_be_upgraded(), "Upgrade order left behind")
  assert(surface.count_entities_filtered({name = "entity-ghost", ghost_name = "negative-straight-rail"}) == 0,
    "Negative ghost left behind")

  stamp({{entity_number = 1, name = "negative-straight-rail", position = {0, 0}}}, {20, 0})
  assert(surface.count_entities_filtered({name = "entity-ghost", ghost_name = "negative-straight-rail"}) == 0,
    "Empty-area negative ghost left behind")

  local upgrade = rail("straight-rail", {30, 0})
  assert(upgrade.order_upgrade({target = "negative-straight-rail", force = force}))
  assert(upgrade.to_be_deconstructed() and not upgrade.to_be_upgraded(), "Upgrade conversion failed")
  log("NEGATIVE_TEST upgrade conversion PASS")

  local shapes = {"straight-rail", "half-diagonal-rail", "curved-rail-a", "curved-rail-b"}
  for i, shape in ipairs(shapes) do
    for rotation = 0, 3 do
      local position = {x = -48 + (i - 1) * 24, y = -48 + rotation * 24}
      local target = rail(shape, position, rotation * 4)
      stamp({{entity_number = 1, name = "negative-" .. shape, position = {0, 0}, direction = 0}},
        position, rotation * 4)
      assert(target.to_be_deconstructed(), "Missing demolition: " .. shape .. " rotation " .. rotation)
      assert(not target.to_be_upgraded(), "Upgrade remained: " .. shape)
    end
  end
  log("NEGATIVE_TEST four shapes x four rotations PASS")

  local target = rail("straight-rail", {0, 48})
  local crossing = rail("straight-rail", {0, 48}, defines.direction.east)
  local nearby = rail("straight-rail", {6, 48})
  stamp({
    {entity_number = 1, name = "negative-straight-rail", position = {0, 0}},
    {entity_number = 2, name = "straight-rail", position = {12, 0}}
  }, {6, 48})
  assert(target.to_be_deconstructed(), "Mixed blueprint did not demolish the target")
  assert(not crossing.to_be_deconstructed(), "Crossing rail was demolished")
  assert(not nearby.to_be_deconstructed(), "Nearby rail was demolished")
  assert(surface.count_entities_filtered({name = "entity-ghost", ghost_name = "straight-rail"}) > 0,
    "New ordinary rail was not scheduled for construction")
  assert(surface.count_entities_filtered({type = "entity-ghost", ghost_name = {
    "negative-straight-rail", "negative-half-diagonal-rail", "negative-curved-rail-a", "negative-curved-rail-b"
  }}) == 0, "Negative ghosts remained after the shape tests")
  log("NEGATIVE_TEST mixed blueprint and crossing preservation PASS")

  remote.call("negative_rails_instant_test", "mode", "demolition")
  local instant = rail("straight-rail", {40, 48})
  instant.order_upgrade({target = "negative-straight-rail", force = force})
  assert(not instant.valid, "Instant demolition regression was not exercised")
  remote.call("negative_rails_instant_test", "mode", "cancel")
  local cancelled = rail("straight-rail", {56, 48})
  cancelled.order_upgrade({target = "negative-straight-rail", force = force})
  assert(not cancelled.valid, "Upgrade cancellation regression was not exercised")
  remote.call("negative_rails_instant_test", "mode", nil)
  log("NEGATIVE_TEST synchronous entity deletion PASS")

  local player = game.get_player(1)
  if player then
    player.force = force
    player.set_controller({type = defines.controllers.god})
    player.teleport({-48, 48}, surface)
    player.clear_cursor()
    -- build_from_cursor does not accept cursor_ghost in Factorio 2.0.
    -- Establish a real player placement context, then simulate the native UI's
    -- ghost-built notification using script_raised_built with player_index.
    player.cursor_stack.set_stack({name = "negative-rail", count = 100})
    player.build_from_cursor({position = {-60, 48}})
    player.clear_cursor()
    player.cursor_ghost = "negative-rail"
    local planned = assert(surface.create_entity({name = "entity-ghost",
      inner_name = "negative-straight-rail", position = {-48,48}, force = force}))
    script.raise_event(defines.events.script_raised_built, {entity = planned, player_index = player.index})
    local template = surface.find_entities_filtered({name = "entity-ghost",
      ghost_name="negative-straight-rail",force="negative-rails-markers",
      area = {{-50, 46}, {-46, 50}}})
    assert(#template == 1, "Manual ghost planning did not preserve a template ghost")
    assert(template[1].force ~= force and template[1].force.get_friend(force),
      "Template ghost was not isolated from player construction robots")
    assert(surface.count_entities_filtered({name="negative-straight-rail",
      area={{-50,46},{-46,50}}}) == 0, "Template created a free real rail")
    local copy = game.create_inventory(1)
    copy[1].set_stack({name="blueprint"})
    local mapping = copy[1].create_blueprint({surface=surface,force=force,
      area={{-50,46},{-46,50}},include_entities=true})
    markers.rewrite(copy[1], mapping)
    local copied = copy[1].get_blueprint_entities()
    assert(copied and #copied == 1 and copied[1].name == "negative-straight-rail",
      "Protected ghost did not become a native negative rail in the blueprint")
    log("NEGATIVE_TEST protected ghost blueprint capture PASS")

    -- Native rail planning may emit built events without any pre-build event.
    -- Exercise a path with new curves, a matching old curve, and a straight
    -- track crossing a curve that must remain in the template.
    for _, shape in ipairs({"curved-rail-a","curved-rail-b"}) do
      local position = shape == "curved-rail-a" and {48,40} or {48,56}
      local curve = assert(surface.create_entity({name="entity-ghost",
        inner_name="negative-"..shape,position=position,direction=0,force=force}))
      script.raise_event(defines.events.script_raised_built,{entity=curve,player_index=player.index})
      assert(curve.valid and curve.force.name==markers.force_name,
        "Path-planned curve disappeared on empty space: "..shape)
      assert(curve.tags.negative_rails_proxy, "New curve was not protected")
      local curve_copy = game.create_inventory(1)
      curve_copy[1].set_stack({name="blueprint"})
      local curve_mapping = curve_copy[1].create_blueprint({surface=surface,force=force,
        area={{curve.position.x-1,curve.position.y-1},{curve.position.x+1,curve.position.y+1}},include_entities=true})
      markers.rewrite(curve_copy[1],curve_mapping)
      local curve_entries = curve_copy[1].get_blueprint_entities()
      local captured = false
      for _, entry in pairs(curve_entries or {}) do
        if entry.name == "negative-"..shape and (entry.direction or 0) == curve.direction then captured = true end
      end
      assert(captured,"Path-planned curve was not copied to the blueprint: "..shape)
      curve_copy.destroy()
    end
    local old_curve = rail("curved-rail-a", {40,-60})
    -- At an exact overlap the engine emits an upgrade instead of creating a ghost.
    old_curve.order_upgrade({target="negative-curved-rail-a",force=force,player=player})
    assert(old_curve.valid and old_curve.to_be_deconstructed(), "Matching curve was not marked for demolition")
    local straight = rail("straight-rail", {56,-24})
    local turning = assert(surface.create_entity({name="entity-ghost",
      inner_name="negative-curved-rail-a",position=straight.position,direction=0,force=force}))
    script.raise_event(defines.events.script_raised_built,{entity=turning,player_index=player.index})
    assert(straight.valid and not straight.to_be_deconstructed(), "New curve demolished a different rail shape")
    assert(turning.valid and turning.force.name==markers.force_name, "New curve over a different shape was lost")
    log("NEGATIVE_TEST mixed path: empty curves, matching curve, different shape PASS")
    local roboport = surface.create_entity({name="roboport",position={-48,40},force=force})
    assert(roboport)
    roboport.energy = 100000000
    roboport.insert({name="construction-robot",count=5})
    storage.nr_protected_test = {ghost=template[1],player=player.index,finish=game.tick+1800}
    copy.destroy()

    local manual = rail("straight-rail", {-36, 48})
    local crossing = rail("straight-rail", {-36, 48}, defines.direction.east)
    player.teleport({-36, 48}, surface)
    player.build_from_cursor({position = {-36, 48}})
    assert(manual.valid and manual.name == "straight-rail", "Normal click fast-replaced the old rail")
    -- Use an explicit blueprint instruction to exercise the same engine upgrade
    -- path; native ghost rail planning still needs a UI smoke test.
    player.clear_cursor()
    player.cursor_stack.set_stack({name = "blueprint"})
    player.cursor_stack.set_blueprint_entities({{entity_number = 1,
      name = "negative-straight-rail", position = {0,0}}})
    player.build_from_cursor({position = {-36, 48}, build_mode = defines.build_mode.superforced})
    assert(manual.valid and manual.to_be_deconstructed(), "Manual superforced planning did not mark the old rail")
    assert(crossing.valid and not crossing.to_be_deconstructed(), "Manual planning demolished the crossing rail")
    local buffer = game.create_inventory(4)
    assert(manual.mine({inventory = buffer}), "Marked manual rail could not be mined")
    assert(buffer.get_item_count("rail") == 1, "Manual demolition did not recover the rail item")
    buffer.destroy()
    log("NEGATIVE_TEST protected manual ghost and resource recovery PASS (native UI planning not automated)")
  else
    log("NEGATIVE_TEST manual cursor planning SKIP (no player in headless new map)")
  end
  inventory.destroy()
  log("NEGATIVE_TEST ALL PASS")
end
script.on_init(run_tests)
script.on_configuration_changed(run_tests)
script.on_event(defines.events.on_tick, function()
  local test = storage.nr_protected_test
  if not test or game.tick < test.finish then return end
  local ghost = test.ghost
  assert(ghost.valid and ghost.type == "entity-ghost", "Robots built the protected template")
  assert(ghost.surface.count_entities_filtered({name="negative-straight-rail",
    area={{-50,46},{-46,50}}}) == 0, "A usable negative rail appeared")
  local alerts = game.get_player(test.player).get_alerts({entity=ghost})
  for _, types in pairs(alerts) do
    for _, list in pairs(types) do assert(#list == 0, "Protected marker generated a player alert") end
  end
  local proxies = ghost.surface.find_entities_filtered({name=markers.proxy_name,
    position=ghost.position,radius=1})
  assert(#proxies == 1, "Template proxy missing or duplicated")
  proxies[1].order_deconstruction(game.forces.player)
  assert(not ghost.valid and not proxies[1].valid, "Deleting the template left its paired entity behind")
  storage.nr_protected_test = nil
  log("NEGATIVE_TEST robot isolation, alerts and paired cleanup PASS")
end)
