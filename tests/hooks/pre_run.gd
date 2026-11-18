extends GutHookScript
## Hook previo de GUT (.gutconfig.json > pre_run_script): los tests nunca tocan la clasificación de
## verdad. Las partidas que acaben en un test (un nivel entero con el jugador muerto) van a otro
## archivo, que empieza vacío.

const TEST_LEADERBOARD := "user://test_leaderboard.cfg"


func run() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_LEADERBOARD))
	Save.leaderboard_path = TEST_LEADERBOARD
	Save.load_leaderboard()
