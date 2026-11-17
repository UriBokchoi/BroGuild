class_name GameSettings
extends RefCounted
## Opciones que ha elegido el jugador: volumen de cada bus, pantalla completa, tamaño de la ventana
## y VSync. Se guardan en un [ConfigFile] ([method write_to] y [method read_from]) y se aplican al
## motor ([method apply_audio] y [method apply_display]). El autoload [code]Save[/code] las carga y
## las aplica al arrancar.

const SECTION_AUDIO := "audio"
const SECTION_DISPLAY := "display"

## Volumen de cada bus, de 0 (silencio) a 1.
var volumes: Dictionary[StringName, float] = {}
var fullscreen: bool = false
## Tamaño de la ventana fuera de pantalla completa. [code]Vector2i.ZERO[/code]: sin elegir (se queda
## el que tenga).
var resolution: Vector2i = Vector2i.ZERO
var vsync: bool = false


## Opciones de un juego recién estrenado, según [param data].
static func create(data: SettingsData) -> GameSettings:
	var settings := GameSettings.new()
	for bus: StringName in data.volume_buses:
		settings.volumes[bus] = data.default_volume
	settings.vsync = data.default_vsync
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


## Escribe las opciones en [param config].
func write_to(config: ConfigFile) -> void:
	for bus: StringName in volumes:
		config.set_value(SECTION_AUDIO, String(bus), volumes[bus])
	config.set_value(SECTION_DISPLAY, "fullscreen", fullscreen)
	config.set_value(SECTION_DISPLAY, "resolution", resolution)
	config.set_value(SECTION_DISPLAY, "vsync", vsync)


## Pone el volumen de cada bus (a 0, silenciado). Los buses que no existen se ignoran.
func apply_audio() -> void:
	for bus: StringName in volumes:
		var index := AudioServer.get_bus_index(bus)
		if index < 0:
			continue
		AudioServer.set_bus_mute(index, volumes[bus] <= 0.0)
		AudioServer.set_bus_volume_linear(index, volumes[bus])


## Pone [param window] en pantalla completa o en ventana (con su tamaño, centrada) y el VSync. Sin
## pantalla (headless: tests y validación), no hace nada.
func apply_display(window: Window) -> void:
	if DisplayServer.get_name() == "headless":
		return
	window.mode = Window.MODE_FULLSCREEN if fullscreen else Window.MODE_WINDOWED
	if not fullscreen and resolution != Vector2i.ZERO:
		window.size = resolution
		window.move_to_center()
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED)
