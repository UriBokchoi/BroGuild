extends GutTest
## Panel de opciones: un deslizador por bus que cambia el volumen al momento; las opciones de
## pantalla esperan a «Aplicar», que las aplica y las guarda, y «Volver» descarta las que no se
## aplicaron; la pantalla completa desactiva la resolución; al cerrar (Volver o Esc) se guarda.
## Trabaja sobre Save.settings, que aquí es una copia de prueba.

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


func test_display_options_wait_for_apply() -> void:
	var apply := _panel.get_node(^"%Apply") as Button
	assert_true(apply.disabled, "sin cambios, no hay nada que aplicar")
	var resolution := _panel.get_node(^"%Resolution") as OptionButton
	var last := _panel.get_resolutions().size() - 1
	resolution.select(last)
	resolution.item_selected.emit(last)
	(_panel.get_node(^"%VSync") as CheckButton).button_pressed = not DATA.default_vsync
	assert_eq(Save.settings.resolution, Vector2i.ZERO, "aún sin aplicar")
	assert_eq(Save.settings.vsync, DATA.default_vsync)
	assert_false(apply.disabled)
	apply.pressed.emit()
	assert_eq(Save.settings.resolution, _panel.get_resolutions()[last])
	assert_eq(Save.settings.vsync, not DATA.default_vsync)
	assert_true(apply.disabled, "ya aplicado")
	assert_true(FileAccess.file_exists(PATH), "y guardado")


func test_offers_the_fps_limits_and_applies_the_chosen_one() -> void:
	var limits := _panel.get_node(^"%FpsLimit") as OptionButton
	assert_eq(limits.item_count, DATA.fps_limits.size())
	assert_eq(limits.selected, DATA.fps_limits.find(DATA.default_fps_limit), "el de serie, marcado")
	var unlimited := DATA.fps_limits.find(0)
	assert_eq(limits.get_item_text(unlimited), tr(&"OPTIONS_FPS_UNLIMITED"))
	limits.select(unlimited)
	limits.item_selected.emit(unlimited)
	assert_eq(Save.settings.fps_limit, DATA.default_fps_limit, "aún sin aplicar")
	(_panel.get_node(^"%Apply") as Button).pressed.emit()
	assert_eq(Save.settings.fps_limit, 0)


func test_back_drops_what_was_not_applied() -> void:
	(_panel.get_node(^"%Fullscreen") as CheckButton).button_pressed = true
	(_panel.get_node(^"%Back") as Button).pressed.emit()
	assert_false(Save.settings.fullscreen)
	_panel.open()
	assert_false((_panel.get_node(^"%Fullscreen") as CheckButton).button_pressed, "al volver a abrir")


func test_fullscreen_disables_the_resolution() -> void:
	var fullscreen := _panel.get_node(^"%Fullscreen") as CheckButton
	var resolution := _panel.get_node(^"%Resolution") as OptionButton
	fullscreen.button_pressed = true
	assert_true(resolution.disabled)
	var screen := DisplayServer.screen_get_size(get_window().current_screen)
	assert_eq(_panel.shown_resolution(), screen, "en pantalla completa, la de la pantalla")
	assert_eq(resolution.get_item_text(resolution.selected), tr(&"OPTIONS_RESOLUTION_VALUE") % [screen.x, screen.y])
	fullscreen.button_pressed = false
	assert_false(resolution.disabled)


func test_no_window_note_outside_the_editor() -> void:
	assert_false((_panel.get_node(^"%WindowNote") as Label).visible)
	assert_false((_panel.get_node(^"%Fullscreen") as CheckButton).disabled)


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


func test_the_shake_slider_changes_the_setting_at_once() -> void:
	var slider := _panel.get_node(^"%ScreenShake") as HSlider
	assert_eq(slider.value, Save.settings.screen_shake, "muestra el actual")
	slider.value = 0.25
	assert_almost_eq(Save.settings.screen_shake, 0.25, 0.0001)
	assert_eq((_panel.get_node(^"%ScreenShakeValue") as Label).text, tr(&"OPTIONS_VOLUME_VALUE") % 25)
