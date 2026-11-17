extends GutTest
## Save: sin archivo, opciones de juego recién estrenado; lo guardado se vuelve a cargar igual.

const SaveService := preload("res://autoload/save.gd")
const PATH := "user://test_save_settings.cfg"

## Volumen y silencio de cada bus antes del test (Save los aplica al entrar en el árbol).
var _saved_audio: Dictionary[StringName, Vector2] = {}


func before_each() -> void:
	_remove_file()
	for bus: StringName in SaveService.SETTINGS_DATA.volume_buses:
		var index := AudioServer.get_bus_index(bus)
		_saved_audio[bus] = Vector2(AudioServer.get_bus_volume_linear(index), float(AudioServer.is_bus_mute(index)))


func after_each() -> void:
	_remove_file()
	for bus: StringName in _saved_audio:
		var index := AudioServer.get_bus_index(bus)
		AudioServer.set_bus_volume_linear(index, _saved_audio[bus].x)
		AudioServer.set_bus_mute(index, _saved_audio[bus].y > 0.0)


func test_without_a_file_loads_the_defaults() -> void:
	var save := _make_save()
	assert_eq(save.settings.volumes[&"Master"], SaveService.SETTINGS_DATA.default_volume)


func test_what_is_saved_loads_back() -> void:
	var save := _make_save()
	save.settings.volumes[&"Master"] = 0.35
	save.settings.resolution = Vector2i(1280, 720)
	assert_eq(save.save_settings(), OK)
	var again := _make_save()
	assert_eq(again.settings.volumes[&"Master"], 0.35)
	assert_eq(again.settings.resolution, Vector2i(1280, 720))


func _make_save() -> SaveService:
	var save := SaveService.new()
	save.settings_path = PATH
	add_child_autofree(save)
	return save


func _remove_file() -> void:
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
