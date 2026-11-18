extends GutHookScript
## Hook previo de GUT (.gutconfig.json > pre_run_script): los tests nunca tocan lo guardado de
## verdad. Lo que apunten las partidas que acaben en un test (un nivel entero con el jugador muerto,
## enemigos derrotados) va a archivos de prueba que empiezan vacíos
## ([code]Save.use_scratch_files[/code]).


func run() -> void:
	Save.use_scratch_files("test")
