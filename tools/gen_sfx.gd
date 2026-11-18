extends SceneTree
## Genera los efectos de sonido: sintetiza ([SfxSynth]) cada receta ([SfxRecipe]) de
## [code]data/audio/sfx/[/code] y la guarda como [code]assets/audio/sfx/<nombre>.wav[/code].
## Después hay que importar. Con el editor cerrado:
##   "$G" --headless --path . -s res://tools/gen_sfx.gd
##   "$G" --headless --path . --import

const RECIPES_DIR := "res://data/audio/sfx"
const OUT_DIR := "res://assets/audio/sfx"


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var failed := false
	for resource: Resource in ResourceDir.load_all(RECIPES_DIR, SfxRecipe):
		var recipe := resource as SfxRecipe
		var file := "%s/%s.wav" % [OUT_DIR, recipe.resource_path.get_file().get_basename()]
		var error := SfxSynth.render_stream(recipe).save_to_wav(ProjectSettings.globalize_path(file))
		if error == OK:
			print("gen_sfx: %s (%.2f s)" % [file, recipe.duration()])
		else:
			failed = true
			printerr("gen_sfx: no se ha podido guardar %s (%s)" % [file, error_string(error)])
	quit(1 if failed else 0)
