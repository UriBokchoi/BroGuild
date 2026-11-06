extends GutTest
## InputActions y el InputMap de Project Settings deben coincidir en ambos sentidos.

const PROJECT_ACTION_PREFIX: String = "input/"
const BUILTIN_ACTION_PREFIX: String = "input/ui_"


func test_every_action_exists_in_input_map() -> void:
	for action: StringName in InputActions.ALL:
		assert_true(InputMap.has_action(action), "Falta «%s» en el InputMap" % action)


func test_every_action_has_at_least_one_event() -> void:
	for action: StringName in InputActions.ALL:
		assert_gt(InputMap.action_get_events(action).size(), 0, "«%s» no tiene tecla" % action)


func test_every_project_action_is_listed() -> void:
	for property: Dictionary in ProjectSettings.get_property_list():
		var setting: String = property["name"]
		if setting.begins_with(PROJECT_ACTION_PREFIX) and not setting.begins_with(BUILTIN_ACTION_PREFIX):
			var action := StringName(setting.trim_prefix(PROJECT_ACTION_PREFIX))
			assert_has(InputActions.ALL, action, "«%s» no está en InputActions.ALL" % action)
