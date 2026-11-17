class_name SignPost
extends StaticBody3D
## Cartel de madera con un texto traducible (cada instancia pone el suyo).

## Clave de traducción del texto.
@export var text_key: StringName = &""
@export var label: Label3D


func _ready() -> void:
	if not text_key.is_empty():
		# Es una clave: el Label3D la traduce solo.
		label.text = String(text_key)
