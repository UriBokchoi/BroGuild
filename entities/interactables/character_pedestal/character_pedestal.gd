class_name CharacterPedestal
extends Node3D
## Pedestal de la zona de práctica con una figura de un personaje: al interactuar, el jugador pasa a
## ser ese personaje en el momento ([method Player.set_character]). Hasta que exista la selección de
## personaje del Hito 3, es la forma de probarlos. Su cartel muestra el nombre y su figura toma el
## color del personaje.

@export var interactable: Interactable
## Personaje que ofrece.
@export var character: CharacterData
## Cartel con el nombre.
@export var label: Label3D
## Figura que toma el color del personaje.
@export var figure: GeometryInstance3D


func _ready() -> void:
	interactable.interacted.connect(_on_interacted)
	if character == null:
		return
	if label:
		# Es una clave: el Label3D la traduce solo.
		label.text = String(character.name_key)
		label.modulate = character.color.lightened(0.3)
	if figure:
		var skin := StandardMaterial3D.new()
		skin.albedo_color = character.color
		skin.roughness = 0.6
		figure.material_override = skin


func _on_interacted(by: Node3D) -> void:
	var player := by as Player
	if player and character:
		player.set_character(character)
