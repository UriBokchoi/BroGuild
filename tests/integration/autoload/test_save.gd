extends GutTest
## Save: con archivos de prueba, récords y Archivo van a otros archivos que empiezan vacíos.

const PREFIX := "test_save_scratch"

var _real_leaderboard: String
var _real_archive: String


func before_each() -> void:
	_real_leaderboard = Save.leaderboard_path
	_real_archive = Save.archive_path


func after_each() -> void:
	for path: String in [Save.leaderboard_path, Save.archive_path]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	Save.leaderboard_path = _real_leaderboard
	Save.archive_path = _real_archive
	Save.load_leaderboard()
	Save.load_discoveries()


func test_scratch_files_start_empty_every_time() -> void:
	Save.use_scratch_files(PREFIX)
	assert_eq(Save.archive_path, "user://%s_archive.cfg" % PREFIX)
	assert_eq(Save.leaderboard_path, "user://%s_leaderboard.cfg" % PREFIX)
	Save.discover(&"enemies", &"swarmer")
	var record := RunRecord.new()
	record.kills = 9
	Save.record_run(record)
	assert_true(FileAccess.file_exists(Save.archive_path), "lo descubierto, guardado")
	Save.use_scratch_files(PREFIX)
	assert_false(Save.discoveries.has(&"enemies", &"swarmer"), "vacío otra vez")
	assert_eq(Save.leaderboard.get_entries().size(), 0)
