extends GutTest
## PhysicsLayers y los nombres de capa de Project Settings deben coincidir.

const SETTING_FORMAT: String = "layer_names/3d_physics/layer_%d"
const LAYER_COUNT: int = 32


func test_names_match_project_settings() -> void:
	for layer: int in PhysicsLayers.NAMES:
		var setting: String = ProjectSettings.get_setting(SETTING_FORMAT % layer, "")
		assert_eq(setting, PhysicsLayers.NAMES[layer], "Capa %d" % layer)


func test_every_named_layer_is_listed() -> void:
	for layer: int in range(1, LAYER_COUNT + 1):
		var setting: String = ProjectSettings.get_setting(SETTING_FORMAT % layer, "")
		if not setting.is_empty():
			assert_has(PhysicsLayers.NAMES, layer, "La capa %d («%s») no está en PhysicsLayers" % [layer, setting])


func test_mask_sets_one_bit_per_layer() -> void:
	var expected: int = (1 << (PhysicsLayers.WORLD - 1)) | (1 << (PhysicsLayers.ENEMY - 1))
	assert_eq(PhysicsLayers.mask(PhysicsLayers.WORLD, PhysicsLayers.ENEMY), expected)


func test_mask_without_layers_is_empty() -> void:
	assert_eq(PhysicsLayers.mask(), 0)
