extends GutTest
## Panel de opciones: un deslizador por bus que cambia el volumen al momento; la pantalla completa
## desactiva la resolución; elegir una resolución la guarda en las opciones; al cerrar (Volver o
## Esc) se guarda en el archivo. Trabaja sobre Save.settings, que aquí es una copia de prueba.

const PanelScene := preload("res://ui/menus/options/options_panel.tscn")
const DATA := preload("res://data/settings/settings.tres")
const PATH := "user://test_options_settings.cfg"

var _panel: OptionsPanel
var _real_settings: GameSettings
var _real_path: String


func before_each() -> void:
	_real_settings = Save.settings
	_real_path = Save.settings_path
	Save.settings = GameSettings.create(DATA)
	Save.settings_path = PATH
	_panel = PanelScene.instantiate() as OptionsPanel
	add_child_autofree(_panel)
	_panel.open()


func after_each() -> void:
	Save.settings = _real_settings
	Save.settings_path = _real_path
	Save.settings.apply_audio()
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))


func test_has_a_slider_per_bus_showing_its_volume() -> void:
	for bus: StringName in DATA.volume_buses:
		var slider := _panel.get_volume_slider(bus)
		assert_not_null(slider, "falta el volumen de %s" % bus)
		if slider:
			assert_eq(slider.value, DATA.default_volume)


func test_moving_a_slider_changes_the_volume_now() -> void:
	_panel.get_volume_slider(&"Effects").value = 0.3
	assert_almost_eq(Save.settings.volumes[&"Effects"], 0.3, 0.001)
	assert_almost_eq(AudioServer.get_bus_volume_linear(AudioServer.get_bus_index(&"Effects")), 0.3, 0.001)


func test_fullscreen_disables_the_resolution() -> void:
	var fullscreen := _panel.get_node(^"%Fullscreen") as CheckButton
	var resolution := _panel.get_node(^"%Resolution") as OptionButton
	fullscreen.button_pressed = true
	assert_true(Save.settings.fullscreen)
	assert_true(resolution.disabled)
	fullscreen.button_pressed = false
	assert_false(resolution.disabled)


func test_choosing_a_resolution_keeps_it() -> void:
	var resolution := _panel.get_node(^"%Resolution") as OptionButton
	var last := _panel.get_resolutions().size() - 1
	resolution.select(last)
	resolution.item_selected.emit(last)
	assert_eq(Save.settings.resolution, _panel.get_resolutions()[last])


func test_offers_the_data_resolutions_and_the_current_window() -> void:
	var offered := _panel.get_resolutions()
	assert_has(offered, get_window().size, "el tamaño de ahora")
	for option: Vector2i in DATA.resolutions:
		assert_has(offered, option)


func test_back_saves_and_closes() -> void:
	watch_signals(_panel)
	_panel.get_volume_slider(&"Master").value = 0.4
	(_panel.get_node(^"%Back") as Button).pressed.emit()
	assert_false(_panel.visible)
	assert_signal_emitted(_panel, "closed")
	var config := ConfigFile.new()
	assert_eq(config.load(PATH), OK, "guardado en su archivo")
	var saved: float = config.get_value(GameSettings.SECTION_AUDIO, "Master")
	assert_almost_eq(saved, 0.4, 0.001)


func test_escape_closes() -> void:
	var event := InputEventAction.new()
	event.action = InputActions.PAUSE
	event.pressed = true
	_panel._unhandled_input(event)
	assert_false(_panel.visible)
