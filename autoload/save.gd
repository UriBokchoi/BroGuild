extends Node
## Lo que se guarda entre partidas (en user://): las opciones, los récords, lo descubierto para el
## Archivo y los tiers superados de cada nivel. Al arrancar carga las opciones y las aplica.
##
## Con «-- --no-save» (lo usa tools/validate.sh) los récords y el Archivo van a archivos de prueba:
## probar el juego no ensucia lo de verdad. Esos archivos se borran al cerrar.

const SETTINGS_DATA := preload("res://data/settings/settings.tres")
## Argumento de línea de órdenes (tras [code]--[/code]) para no tocar récords ni Archivo.
const NO_SAVE_ARG := "--no-save"

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
## Archivo de los tiers superados (los tests usan otro).
var progress_path: String = "user://progress.cfg"
## Tiers superados de cada nivel. Para apuntar uno, [method complete_tier].
var progress: LevelProgress
## Si se usan archivos de prueba (se borran al cerrar).
var _scratch: bool = false


func _ready() -> void:
	load_settings()
	settings.apply_locale()
	settings.apply_audio()
	settings.apply_display(get_window())
	if OS.get_cmdline_user_args().has(NO_SAVE_ARG):
		use_scratch_files("validate")
	else:
		load_leaderboard()
		load_discoveries()
		load_progress()


func _exit_tree() -> void:
	if _scratch:
		_remove_scratch_files()


## Lleva récords, Archivo y tiers a [code]user://<prefix>_leaderboard.cfg[/code],
## [code]user://<prefix>_archive.cfg[/code] y [code]user://<prefix>_progress.cfg[/code], que empiezan
## vacíos (los tests y la validación).
func use_scratch_files(prefix: String) -> void:
	leaderboard_path = "user://%s_leaderboard.cfg" % prefix
	archive_path = "user://%s_archive.cfg" % prefix
	progress_path = "user://%s_progress.cfg" % prefix
	_scratch = true
	_remove_scratch_files()
	load_leaderboard()
	load_discoveries()
	load_progress()


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


## Carga los tiers superados de [member progress_path] (sin archivo, ninguno).
func load_progress() -> void:
	progress = LevelProgress.new()
	var config := ConfigFile.new()
	if config.load(progress_path) == OK:
		progress.read_from(config)


## ¿Se puede jugar el tier [param tier] del nivel [param level_id]?
func is_tier_unlocked(level_id: StringName, tier: int) -> bool:
	if progress == null:
		load_progress()
	return progress.is_unlocked(level_id, tier)


## Apunta que se superó el tier [param tier] de [param level_id] y, si es nuevo, lo guarda. Devuelve
## si era nuevo (abre el siguiente).
func complete_tier(level_id: StringName, tier: int) -> bool:
	if progress == null:
		load_progress()
	if not progress.complete(level_id, tier):
		return false
	var config := ConfigFile.new()
	progress.write_to(config)
	_save(config, progress_path, "los tiers superados")
	return true


func _remove_scratch_files() -> void:
	for path: String in [leaderboard_path, archive_path, progress_path]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _save(config: ConfigFile, path: String, what: String) -> Error:
	var error := config.save(path)
	if error != OK:
		push_error("Save: no se ha podido guardar %s en %s (%s)." % [what, path, error_string(error)])
	return error
