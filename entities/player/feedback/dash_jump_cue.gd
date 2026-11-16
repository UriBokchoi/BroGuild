class_name DashJumpCue
extends Node
## Aviso visual del dash-jump: muestra [member visual] (un aro en los pies) mientras la ventana
## para hacerlo está abierta. Solo lee el contexto del jugador; no cambia nada del movimiento.

@export var player: Player
## Lo que se enseña mientras la ventana está abierta.
@export var visual: Node3D


func _ready() -> void:
	visual.visible = false


func _physics_process(_delta: float) -> void:
	visual.visible = player.context != null and player.context.is_dash_jump_open()
