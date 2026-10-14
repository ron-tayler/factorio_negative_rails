local tint = { r = 1, g = 0.15, b = 0.65, a = 1 }
local shapes = { "straight-rail", "half-diagonal-rail", "curved-rail-a", "curved-rail-b" }
local counts = { 1, 2, 3, 3 }
local rails = {}

local function tint_sprites(value)
  if type(value) ~= "table" then return end
  if value.filename or value.filenames then value.tint = tint end
  for key, child in pairs(value) do
    if key ~= "tint" then tint_sprites(child) end
  end
end

for i, shape in ipairs(shapes) do
  local original = data.raw[shape][shape]
  local rail = table.deepcopy(original)
  rail.name = "negative-" .. shape
  rail.localised_name = { "entity-name.negative-rail" }
  rail.localised_description = { "entity-description.negative-rail" }
  rail.icons = {{ icon = "__base__/graphics/icons/rail.png", icon_size = 64, tint = tint }}
  rail.icon = nil
  rail.placeable_by = { item = "negative-rail", count = counts[i] }
  rail.minable = { mining_time = 0.1 }
  rail.next_upgrade = nil
  -- Keep each shape in its own replacement group. Do not set vanilla next_upgrade:
  -- the default upgrade planner must never turn ordinary rails into demolition.
  original.fast_replaceable_group = original.fast_replaceable_group or shape
  rail.fast_replaceable_group = original.fast_replaceable_group
  rail.deconstruction_alternative = "negative-straight-rail"
  rail.map_color = tint
  tint_sprites(rail.pictures)
  rails[#rails + 1] = rail.name
  data:extend({ rail })
end

local item = table.deepcopy(data.raw["rail-planner"].rail)
item.name = "negative-rail"
item.localised_name = { "item-name.negative-rail" }
item.localised_description = { "entity-description.negative-rail" }
item.icons = {{ icon = "__base__/graphics/icons/rail.png", icon_size = 64, tint = tint }}
item.icon = nil
item.place_result = "negative-straight-rail"
item.rails = rails
item.flags = { "only-in-cursor" }
item.stack_size = 100
item.auto_recycle = false
data:extend({
  {
    type = "simple-entity-with-owner", name = "negative-rail-copy-marker",
    localised_name = {"entity-name.negative-rail"},
    localised_description = {"entity-description.negative-rail"},
    hidden = true,
    flags = {"placeable-off-grid", "player-creation", "not-on-map", "not-flammable"},
    collision_mask = {layers = {}},
    collision_box = {{-0.1,-0.1},{0.1,0.1}},
    selection_box = {{-0.5,-0.5},{0.5,0.5}},
    selection_priority = 1,
    icons = {{icon="__base__/graphics/icons/rail.png",icon_size=64,tint=tint}},
    picture = {filename="__core__/graphics/empty.png",width=1,height=1},
    minable = {mining_time=0.1},
    placeable_by = {item="negative-rail-copy-marker",count=1}
  },
  {
    type="item",name="negative-rail-copy-marker",hidden=true,stack_size=1,
    flags={"only-in-cursor"},place_result="negative-rail-copy-marker",
    icon="__base__/graphics/icons/rail.png",icon_size=64,auto_recycle=false
  },
  item,
  {
    type = "custom-input", name = "give-negative-rail",
    key_sequence = "CONTROL + SHIFT + R", action = "lua"
  },
  {
    type = "shortcut", name = "give-negative-rail", action = "lua",
    associated_control_input = "give-negative-rail",
    icons = {{ icon = "__base__/graphics/icons/rail.png", icon_size = 64, tint = tint }},
    small_icons = {{ icon = "__base__/graphics/icons/rail.png", icon_size = 64, tint = tint }}
  }
})
