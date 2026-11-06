extends SceneTree
## Carga sin caché todos los .gd del proyecto (salvo addons/, carpetas ocultas
## y carpetas con .gdignore) para forzar el análisis estático de cada uno.
## Lanzar con -d --ignore-error-breaks: solo así los warnings salen por stderr.
## Sustituye a --check-only, que da falsos errores con los autoloads.
## Sale con código 1 si algún script no compila.

const SKIP_DIRS: PackedStringArray = ["res://addons"]


func _initialize() -> void:
	var self_path: String = (get_script() as Script).resource_path
	var paths: PackedStringArray = _collect_scripts("res://")
	var failed: PackedStringArray = []
	for path: String in paths:
		# Recargarse a sí mismo mientras se ejecuta tumba Godot 4.7.2 (signal 11).
		if path == self_path:
			continue
		var script: Script = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as Script
		# En builds de editor load() devuelve el script aunque no compile:
		# can_instantiate() es false solo si es inválido (abstract y tool dan true).
		if script == null or not script.can_instantiate():
			failed.append(path)
	print("check_scripts: %d scripts, %d failed" % [paths.size(), failed.size()])
	for path: String in failed:
		printerr("ERROR: check_scripts: no compila ", path)
	quit(1 if failed.size() > 0 else 0)


func _collect_scripts(dir_path: String) -> PackedStringArray:
	var result: PackedStringArray = []
	for file: String in DirAccess.get_files_at(dir_path):
		if file.get_extension() == "gd":
			result.append(dir_path.path_join(file))
	for sub: String in DirAccess.get_directories_at(dir_path):
		var sub_path: String = dir_path.path_join(sub)
		if sub.begins_with(".") or sub_path in SKIP_DIRS:
			continue
		if FileAccess.file_exists(sub_path.path_join(".gdignore")):
			continue
		result.append_array(_collect_scripts(sub_path))
	return result
