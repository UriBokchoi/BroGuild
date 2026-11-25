class_name GameSettings
extends RefCounted
## Las opciones del jugador: idioma, volumen, pantalla completa, tamaño de ventana, VSync, límite de
## FPS, temblor de pantalla, sensibilidad del ratón e invertir el eje vertical. Se guardan en un
## ConfigFile y se aplican al motor (los controles los lee la cámara); Save las carga al arrancar.

const SECTION_AUDIO := "audio"
const SECTION_DISPLAY := "display"
const SECTION_GENERAL := "general"
const SECTION_CONTROLS := "controls"
## Límites de la sensibilidad del ratón (los mismos que el deslizador de las opciones).
const MIN_SENSITIVITY := 0.2
const MAX_SENSITIVITY := 3.0

## Idioma (código de [TranslationServer]). Vacío: el del sistema.
var locale: String = ""
## Volumen de cada bus, de 0 (silencio) a 1.
var volumes: Dictionary[StringName, float] = {}
var fullscreen: bool = false
## Tamaño de la ventana fuera de pantalla completa. [code]Vector2i.ZERO[/code]: sin elegir (se queda
## el que tenga).
var resolution: Vector2i = Vector2i.ZERO
var vsync: bool = false
## Fotogramas por segundo como mucho ([member Engine.max_fps]; 0 = sin límite).
var fps_limit: int = 0
## Cuánto tiembla la pantalla al recibir golpes, de 0 (nada) a 1 (lo normal).
var screen_shake: float = 1.0
## Sensibilidad del ratón: multiplica la de la cámara (1 = la de serie).
var mouse_sensitivity: float = 1.0
## Si mover el ratón hacia arriba baja la cámara.
var invert_y: bool = false


## Opciones de un juego recién estrenado, según [param data].
static func create(data: SettingsData) -> GameSettings:
	var settings := GameSettings.new()
	for bus: StringName in data.volume_buses:
		settings.volumes[bus] = data.default_volume
	settings.vsync = data.default_vsync
	settings.fps_limit = data.default_fps_limit
	settings.locale = data.default_locale
	settings.screen_shake = data.default_screen_shake
	settings.mouse_sensitivity = data.default_mouse_sensitivity
	return settings


## Lee de [param config] lo que haya guardado; lo que falte o no valga se queda como está.
func read_from(config: ConfigFile) -> void:
	for bus: StringName in volumes.keys():
		var volume: Variant = config.get_value(SECTION_AUDIO, String(bus), volumes[bus])
		if volume is float or volume is int:
			var number: float = volume
			volumes[bus] = clampf(number, 0.0, 1.0)
	var saved_fullscreen: Variant = config.get_value(SECTION_DISPLAY, "fullscreen", fullscreen)
	if saved_fullscreen is bool:
		fullscreen = saved_fullscreen
	var saved_resolution: Variant = config.get_value(SECTION_DISPLAY, "resolution", resolution)
	if saved_resolution is Vector2i:
		resolution = saved_resolution
	var saved_vsync: Variant = config.get_value(SECTION_DISPLAY, "vsync", vsync)
	if saved_vsync is bool:
		vsync = saved_vsync
	var saved_fps: Variant = config.get_value(SECTION_DISPLAY, "fps_limit", fps_limit)
	if saved_fps is int:
		fps_limit = maxi(saved_fps as int, 0)
	var saved_shake: Variant = config.get_value(SECTION_DISPLAY, "screen_shake", screen_shake)
	if saved_shake is float or saved_shake is int:
		var shake: float = saved_shake
		screen_shake = clampf(shake, 0.0, 1.0)
	var saved_sensitivity: Variant = config.get_value(SECTION_CONTROLS, "mouse_sensitivity", mouse_sensitivity)
	if saved_sensitivity is float or saved_sensitivity is int:
		var sensitivity: float = saved_sensitivity
		mouse_sensitivity = clampf(sensitivity, MIN_SENSITIVITY, MAX_SENSITIVITY)
	var saved_invert: Variant = config.get_value(SECTION_CONTROLS, "invert_y", invert_y)
	if saved_invert is bool:
		invert_y = saved_invert
	var saved_locale: Variant = config.get_value(SECTION_GENERAL, "locale", locale)
	if saved_locale is String and not (saved_locale as String).is_empty():
		locale = saved_locale


## Escribe las opciones en [param config].
func write_to(config: ConfigFile) -> void:
	for bus: StringName in volumes:
		config.set_value(SECTION_AUDIO, String(bus), volumes[bus])
	config.set_value(SECTION_DISPLAY, "fullscreen", fullscreen)
	config.set_value(SECTION_DISPLAY, "resolution", resolution)
	config.set_value(SECTION_DISPLAY, "vsync", vsync)
	config.set_value(SECTION_DISPLAY, "fps_limit", fps_limit)
	config.set_value(SECTION_DISPLAY, "screen_shake", screen_shake)
	config.set_value(SECTION_CONTROLS, "mouse_sensitivity", mouse_sensitivity)
	config.set_value(SECTION_CONTROLS, "invert_y", invert_y)
	config.set_value(SECTION_GENERAL, "locale", locale)


## Pone el idioma (vacío: deja el del sistema).
func apply_locale() -> void:
	if not locale.is_empty():
		TranslationServer.set_locale(locale)


## Pone el volumen de cada bus (a 0, silenciado). Los buses que no existen se ignoran.
func apply_audio() -> void:
	for bus: StringName in volumes:
		var index := AudioServer.get_bus_index(bus)
		if index < 0:
			continue
		AudioServer.set_bus_mute(index, volumes[bus] <= 0.0)
		AudioServer.set_bus_volume_linear(index, volumes[bus])


## Pone el VSync, el límite de FPS y [param window] en pantalla completa o en ventana (con su tamaño,
## centrada). Sin pantalla (headless: tests y validación), no hace nada; incrustado en el editor,
## solo el VSync y el límite (ver [method can_change_window]).
func apply_display(window: Window) -> void:
	if DisplayServer.get_name() == "headless":
		return
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = fps_limit
	if not can_change_window():
		return
	window.mode = Window.MODE_FULLSCREEN if fullscreen else Window.MODE_WINDOWED
	if not fullscreen and resolution != Vector2i.ZERO:
		window.size = resolution
		window.move_to_center()


## Copia independiente (para editarla sin tocar estas).
func copy() -> GameSettings:
	var other := GameSettings.new()
	other.volumes = volumes.duplicate()
	other.fullscreen = fullscreen
	other.resolution = resolution
	other.vsync = vsync
	other.fps_limit = fps_limit
	other.locale = locale
	other.screen_shake = screen_shake
	other.mouse_sensitivity = mouse_sensitivity
	other.invert_y = invert_y
	return other


## Si las opciones de pantalla (pantalla completa, tamaño, VSync y límite de FPS) de [param other] son
## otras.
func display_differs(other: GameSettings) -> bool:
	return (
		fullscreen != other.fullscreen
		or resolution != other.resolution
		or vsync != other.vsync
		or fps_limit != other.fps_limit
	)


## Toma de [param other] las opciones de pantalla.
func take_display(other: GameSettings) -> void:
	fullscreen = other.fullscreen
	resolution = other.resolution
	vsync = other.vsync
	fps_limit = other.fps_limit


## Si el juego puede cambiar su ventana. Ejecutado dentro del editor (pestaña «Juego»), la ventana
## es del editor: ni pantalla completa ni otro tamaño.
static func can_change_window() -> bool:
	return not Engine.is_embedded_in_editor()
