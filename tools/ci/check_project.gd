extends SceneTree
## Carga sin caché todos los scripts, escenas, recursos y shaders del proyecto
## (salvo addons/, carpetas ocultas y carpetas con .gdignore). Así se analiza
## cada .gd aunque nadie lo use, y aparecen escenas o .tres rotos que la escena
## principal no carga. Sustituye a --check-only, que da falsos errores con los
## autoloads.
## Lanzar con -d --ignore-error-breaks: solo así los warnings salen por stderr.
## Sale con código 1 si algo no carga; los errores impresos los recoge validate.sh.

const SKIP_DIRS: PackedStringArray = ["res://addons"]
const SCRIPT_EXTENSION: String = "gd"
const RESOURCE_EXTENSIONS: PackedStringArray = ["tscn", "tres", "gdshader"]


func _initialize() -> void:
	var self_path: String = (get_script() as Script).resource_path
	var paths: PackedStringArray = _collect_files("res://")
	var failed: PackedStringArray = []
	for path: String in paths:
		# Recargarse a sí mismo mientras se ejecuta tumba Godot 4.7.2 (signal 11).
		if path != self_path and not _loads(path):
			failed.append(path)
	print("check_project: %d archivos, %d fallidos" % [paths.size(), failed.size()])
	for path: String in failed:
		printerr("ERROR: check_project: no carga ", path)
	quit(1 if failed.size() > 0 else 0)


func _loads(path: String) -> bool:
	var resource: Resource = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	if resource == null:
		return false
	# Un shader no se compila al cargarlo, sino al pedir sus parámetros. Si falla,
	# imprime SHADER ERROR (lo recoge validate.sh), pero no hay forma de saberlo aquí.
	var shader: Shader = resource as Shader
	if shader != null:
		shader.get_shader_uniform_list()
	# En builds de editor load() devuelve el script aunque no compile:
	# can_instantiate() es false solo si es inválido (abstract y tool dan true).
	var script: Script = resource as Script
	return script == null or script.can_instantiate()


func _collect_files(dir_path: String) -> PackedStringArray:
	var result: PackedStringArray = []
	for file: String in DirAccess.get_files_at(dir_path):
		var extension: String = file.get_extension()
		if extension == SCRIPT_EXTENSION or extension in RESOURCE_EXTENSIONS:
			result.append(dir_path.path_join(file))
	for sub: String in DirAccess.get_directories_at(dir_path):
		var sub_path: String = dir_path.path_join(sub)
		if sub.begins_with(".") or sub_path in SKIP_DIRS:
			continue
		if FileAccess.file_exists(sub_path.path_join(".gdignore")):
			continue
		result.append_array(_collect_files(sub_path))
	return result
