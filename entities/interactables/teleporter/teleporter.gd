class_name Teleporter
extends Area3D
## Zona que lleva al jugador a [member destination] en cuanto entra: una plataforma de
## teletransporte o, sin nada que se vea, un recogedor de caídas bajo el mapa. El destino tiene
## que quedar fuera de cualquier otra zona así, o volvería a saltar. Su máscara de física es
## [code]player[/code].

## El jugador acaba de llegar a [member destination].
signal teleported(player: Player)

## Punto de llegada (los pies del jugador).
@export var destination: Node3D
## Cartel que lleva encima (opcional).
@export var label: Label3D
## Clave de traducción del cartel.
@export var label_key: StringName = &"":
	set(value):
		label_key = value
		if label:
			label.text = value


func _ready() -> void:
	if label:
		label.text = label_key
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	var player := body as Player
	if player and destination:
		# En plena consulta de física no se puede mover un cuerpo: al acabar el tick.
		_send.call_deferred(player)


func _send(player: Player) -> void:
	player.teleport_to(destination.global_position)
	teleported.emit(player)
