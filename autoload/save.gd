extends Node
## Lo que dura entre partidas, guardado en [code]user://[/code]. De momento, las opciones
## ([GameSettings]): al arrancar las carga y las aplica. Los desbloqueos llegarán en el Hito 3.
## Sin lógica de gameplay.

const SETTINGS_DATA := preload("res://data/settings/settings.tres")

## Archivo de las opciones (los tests usan otro).
var settings_path: String = "user://settings.cfg"
## Opciones actuales. Quien las cambie las aplica y, al terminar, llama a [method save_settings].
var settings: GameSettings


func _ready() -> void:
	load_settings()
	settings.apply_audio()
	settings.apply_display(get_window())


## Carga las opciones de [member settings_path]; sin archivo, las de un juego recién estrenado.
func load_settings() -> void:
	settings = GameSettings.create(SETTINGS_DATA)
	var config := ConfigFile.new()
	if config.load(settings_path) == OK:
		settings.read_from(config)


## Guarda las opciones en [member settings_path].
func save_settings() -> Error:
	var config := ConfigFile.new()
	settings.write_to(config)
	var error := config.save(settings_path)
	if error != OK:
		push_error("Save: no se han podido guardar las opciones en %s (%s)." % [settings_path, error_string(error)])
	return error
