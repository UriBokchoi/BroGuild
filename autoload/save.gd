extends Node
## Lo que dura entre partidas, guardado en [code]user://[/code]: las opciones ([GameSettings]), que
## al arrancar carga y aplica, la clasificación de partidas ([Leaderboard]) y lo descubierto para el
## Archivo ([Discoveries]). Los desbloqueos llegarán más adelante.
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
## Archivo de lo descubierto (los tests usan otro).
var archive_path: String = "user://archive.cfg"
## Lo descubierto. Para apuntar algo, [method discover].
var discoveries: Discoveries


func _ready() -> void:
	load_settings()
	settings.apply_locale()
	settings.apply_audio()
	settings.apply_display(get_window())
	load_leaderboard()
	load_discoveries()


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
	return _save(config, settings_path, "las opciones")


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
	_save(config, leaderboard_path, "la clasificación")
	return place


## Carga lo descubierto de [member archive_path] (sin archivo, nada).
func load_discoveries() -> void:
	discoveries = Discoveries.new()
	var config := ConfigFile.new()
	if config.load(archive_path) == OK:
		discoveries.read_from(config)


## Apunta [param id] como descubierto en [param category] y, si es nuevo, lo guarda. Devuelve si
## era nuevo.
func discover(category: StringName, id: StringName) -> bool:
	if discoveries == null:
		load_discoveries()
	if not discoveries.discover(category, id):
		return false
	var config := ConfigFile.new()
	discoveries.write_to(config)
	_save(config, archive_path, "el Archivo")
	return true


func _save(config: ConfigFile, path: String, what: String) -> Error:
	var error := config.save(path)
	if error != OK:
		push_error("Save: no se ha podido guardar %s en %s (%s)." % [what, path, error_string(error)])
	return error
