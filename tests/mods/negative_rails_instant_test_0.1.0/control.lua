remote.add_interface("negative_rails_instant_test", {
  mode = function(mode) storage.mode = mode end
})
script.on_event(defines.events.on_marked_for_deconstruction, function(event)
  if storage.mode == "demolition" and event.entity.valid then event.entity.destroy() end
end)
script.on_event(defines.events.on_cancelled_upgrade, function(event)
  if storage.mode == "cancel" and event.entity.valid then event.entity.destroy() end
end)
