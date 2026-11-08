class_name PlayerInput
extends Node
## Convierte las pulsaciones del InputMap en acciones de la máquina de movimiento. Solo escucha
## las acciones que activan algún estado, así que un estado nuevo con su acción funciona sin
## tocar este script.

@export var machine: StateMachine


func _unhandled_input(event: InputEvent) -> void:
	for action: StringName in machine.get_trigger_actions():
		if event.is_action_pressed(action):
			machine.request(action)
