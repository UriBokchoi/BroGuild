class_name Herald
extends Node3D
## El heraldo del Gremio: espera donde aparece y, si le hablas («interactuar»), ofrece sus pactos
## ([signal EventBus.pact_offered]; los enseña el [PactPanel]). Luego se va. Lo trae el
## [HeraldSpawner].

## Qué pactos ofrece.
@export var data: HeraldData
@export var interactable: Interactable

## Azar de lo que ofrece. Si no se asigna antes de entrar en el árbol, el flujo de apuestas de Rng.
var rng: RandomNumberGenerator


func _ready() -> void:
	if rng == null:
		rng = Rng.stream(Rng.Stream.GAMBLE)
	interactable.interacted.connect(_on_interacted)


## Ofrece sus pactos y se va. Devuelve los que ofreció.
func offer() -> Array[PactData]:
	var pacts := data.roll(rng)
	interactable.enabled = false
	EventBus.pact_offered.emit(pacts)
	queue_free()
	return pacts


func _on_interacted(by: Node3D) -> void:
	if by is Player:
		offer()
