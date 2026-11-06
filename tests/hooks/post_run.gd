extends GutHookScript
## Hook posterior de GUT (.gutconfig.json > post_run_script). GUT 9.7.1 solo
## falla un test por errores ocurridos DENTRO de su cuerpo: los de before_all,
## before_each, after_each y after_all quedan sin test y no fallan nada, y un
## push_warning() nunca falla. Este hook hace fallar la ejecución en ambos casos.
## Los errores esperados (assert_push_error y similares) vienen marcados como
## handled y no cuentan.

const FAILURE_EXIT_CODE: int = 1


func run() -> void:
	var main: GutMain = gut
	var tracker: GutErrorTracker = main.error_tracker
	# GUT no tipa este registro; se lee por nombre de propiedad.
	var errors_by_test: Dictionary = (tracker.errors as Object).get("items")
	var problems: PackedStringArray = []
	for test_id: Variant in errors_by_test:
		for error: GutTrackedError in errors_by_test[test_id]:
			if _is_problem(error, str(test_id)):
				problems.append("%s (%s:%d) en %s" % [error.code, error.file, error.line, test_id])
	for problem: String in problems:
		printerr("[GUT ERROR]: no gestionado: ", problem)
	if not problems.is_empty():
		set_exit_code(FAILURE_EXIT_CODE)


func _is_problem(error: GutTrackedError, test_id: String) -> bool:
	if error.handled:
		return false
	return test_id == GutUtils.NO_TEST or error.is_push_warning()
