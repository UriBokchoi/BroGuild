extends GutTest
## GameSettings: empieza con los valores de SettingsData, se guarda y se lee de un ConfigFile sin
## perder nada, ignora lo que no vale (y limita el volumen entre 0 y 1), pone el volumen de cada bus
## en el AudioServer (a 0, silenciado) y se copia y compara sus opciones de pantalla.

const DATA := preload("res://data/settings/settings.tres")

var _settings: GameSettings
## Volumen y silencio de cada bus antes del test, para dejarlos como estaban.
var _saved_audio: Dictionary[StringName, Vector2] = {}


func before_each() -> void:
	_settings = GameSettings.create(DATA)
	for bus: StringName in DATA.volume_buses:
		var index := AudioServer.get_bus_index(bus)
		_saved_audio[bus] = Vector2(AudioServer.get_bus_volume_linear(index), float(AudioServer.is_bus_mute(index)))


func after_each() -> void:
	for bus: StringName in _saved_audio:
		var index := AudioServer.get_bus_index(bus)
		AudioServer.set_bus_volume_linear(index, _saved_audio[bus].x)
		AudioServer.set_bus_mute(index, _saved_audio[bus].y > 0.0)


func test_starts_with_the_data_defaults() -> void:
	for bus: StringName in DATA.volume_buses:
		assert_eq(_settings.volumes[bus], DATA.default_volume)
	assert_eq(_settings.vsync, DATA.default_vsync)
	assert_false(_settings.fullscreen)
	assert_eq(_settings.resolution, Vector2i.ZERO, "sin tamaño elegido")


func test_round_trips_through_a_config_file() -> void:
	_settings.volumes[&"Music"] = 0.25
	_settings.fullscreen = true
	_settings.resolution = Vector2i(1600, 900)
	_settings.vsync = false
	var config := ConfigFile.new()
	_settings.write_to(config)
	var loaded := GameSettings.create(DATA)
	loaded.read_from(config)
	assert_eq(loaded.volumes[&"Music"], 0.25)
	assert_true(loaded.fullscreen)
	assert_eq(loaded.resolution, Vector2i(1600, 900))
	assert_false(loaded.vsync)


func test_ignores_bad_values_and_clamps_the_volume() -> void:
	var config := ConfigFile.new()
	config.set_value(GameSettings.SECTION_AUDIO, "Master", 3.0)
	config.set_value(GameSettings.SECTION_AUDIO, "Music", "alto")
	config.set_value(GameSettings.SECTION_DISPLAY, "resolution", "grande")
	config.set_value(GameSettings.SECTION_DISPLAY, "fullscreen", 7)
	_settings.read_from(config)
	assert_eq(_settings.volumes[&"Master"], 1.0, "limitado a 1")
	assert_eq(_settings.volumes[&"Music"], DATA.default_volume, "un texto no vale")
	assert_eq(_settings.resolution, Vector2i.ZERO)
	assert_false(_settings.fullscreen)


func test_applies_the_volume_to_each_bus() -> void:
	_settings.volumes[&"Effects"] = 0.5
	_settings.volumes[&"Music"] = 0.0
	_settings.apply_audio()
	var effects := AudioServer.get_bus_index(&"Effects")
	var music := AudioServer.get_bus_index(&"Music")
	assert_almost_eq(AudioServer.get_bus_volume_linear(effects), 0.5, 0.001)
	assert_false(AudioServer.is_bus_mute(effects))
	assert_true(AudioServer.is_bus_mute(music), "a 0, silenciado")


func test_a_copy_is_independent() -> void:
	var copy := _settings.copy()
	copy.volumes[&"Master"] = 0.1
	copy.fullscreen = true
	assert_eq(_settings.volumes[&"Master"], DATA.default_volume)
	assert_false(_settings.fullscreen)


func test_compares_and_takes_the_display_options() -> void:
	var other := _settings.copy()
	assert_false(other.display_differs(_settings))
	other.resolution = Vector2i(1600, 900)
	other.volumes[&"Music"] = 0.2
	assert_true(other.display_differs(_settings))
	_settings.take_display(other)
	assert_eq(_settings.resolution, Vector2i(1600, 900))
	assert_eq(_settings.volumes[&"Music"], DATA.default_volume, "el volumen no es de pantalla")
	assert_false(other.display_differs(_settings))
