extends GutHookScript
## Hook previo de GUT (.gutconfig.json > pre_run_script): los tests nunca tocan lo guardado de
## verdad. Lo que apunten las partidas que acaben en un test (un nivel entero con el jugador muerto,
## enemigos derrotados) va a otros archivos, que empiezan vacíos.

const TEST_LEADERBOARD := "user://test_leaderboard.cfg"
const TEST_ARCHIVE := "user://test_archive.cfg"


func run() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_LEADERBOARD))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_ARCHIVE))
	Save.leaderboard_path = TEST_LEADERBOARD
	Save.load_leaderboard()
	Save.archive_path = TEST_ARCHIVE
	Save.load_discoveries()
