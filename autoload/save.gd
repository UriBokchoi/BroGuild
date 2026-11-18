extends Node
## Lo que dura entre partidas, guardado en [code]user://[/code]: las opciones ([GameSettings]), que
## al arrancar carga y aplica, y la clasificación de partidas ([Leaderboard]). Los desbloqueos
## llegarán más adelante.
## Sin lógica de gameplay.

const SETTINGS_DATA := preload("res://data/settings/settings.tres")

## Archivo de las opciones (los tests usan otro).
var settings_path: String = "user://settings.cfg"
## Opciones actuales. Quien las cambie las aplica y, al terminar, llama a [method save_settings].
var settings: GameSettings
## Archivo de la clasificación (los tests usan otro).
var leaderboard_path: String = "user://leaderboard.cfg"
## Las mejores partidas. Para añadir una, [method record_run].
var leaderboard: Leaderboard


func _ready() -> void:
	load_settings()
	settings.apply_locale()
	settings.apply_audio()
	settings.apply_display(get_window())
	load_leaderboard()


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


## Carga la clasificación de [member leaderboard_path] (sin archivo, vacía).
func load_leaderboard() -> void:
	leaderboard = Leaderboard.new(SETTINGS_DATA.leaderboard_size)
	var config := ConfigFile.new()
	if config.load(leaderboard_path) == OK:
		leaderboard.read_from(config)


## Apunta [param record] en la clasificación y la guarda. Devuelve su puesto (desde 0) o −1 si no
## entra entre las mejores.
func record_run(record: RunRecord) -> int:
	if leaderboard == null:
		load_leaderboard()
	var place := leaderboard.add(record)
	var config := ConfigFile.new()
	leaderboard.write_to(config)
	var error := config.save(leaderboard_path)
	if error != OK:
		push_error("Save: no se ha podido guardar la clasificación en %s (%s)." % [leaderboard_path, error_string(error)])
	return place
