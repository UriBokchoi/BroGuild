class_name Armory
extends Node3D
## Armería de la zona de práctica: al interactuar abre su panel para equipar, quitar y cambiar de
## nivel cualquier arma del juego (las de [member weapons_dir]). Solo para probar: no es parte de
## una partida.

@export var interactable: Interactable
@export var panel: ArmoryPanel
## Carpeta con los [WeaponData] que ofrece: un arma nueva aparece sola.
@export_dir var weapons_dir: String = ""


func _ready() -> void:
	interactable.interacted.connect(_on_interacted)


func _on_interacted(by: Node3D) -> void:
	var player := by as Player
	if player:
		var catalog: Array[WeaponData] = []
		catalog.assign(ResourceDir.load_all(weapons_dir, WeaponData))
		panel.open(player.weapons, catalog)
