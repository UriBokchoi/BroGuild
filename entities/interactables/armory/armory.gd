class_name Armory
extends Node3D
## Armería de la zona de práctica: al interactuar abre su panel para equipar, quitar y cambiar de
## nivel cualquier arma o runa del juego (las de [member weapons_dir] y [member runes_dir]). Solo
## para probar: no es parte de una partida.

@export var interactable: Interactable
@export var panel: ArmoryPanel
## Carpeta con los [WeaponData] que ofrece: un arma nueva aparece sola.
@export_dir var weapons_dir: String = ""
## Carpeta con los [RuneData] que ofrece: una runa nueva aparece sola.
@export_dir var runes_dir: String = ""


func _ready() -> void:
	interactable.interacted.connect(_on_interacted)


func _on_interacted(by: Node3D) -> void:
	var player := by as Player
	if player == null:
		return
	var weapons: Array[WeaponData] = []
	weapons.assign(ResourceDir.load_all(weapons_dir, WeaponData))
	var runes: Array[RuneData] = []
	runes.assign(ResourceDir.load_all(runes_dir, RuneData))
	panel.open(player, weapons, runes)
