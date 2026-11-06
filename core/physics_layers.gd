class_name PhysicsLayers
## Capas de física 3D: mismos números y nombres que Project Settings >
## Layer Names > 3D Physics (un test lo comprueba).
## hitbox = la zona que HACE daño; hurtbox = la zona que lo RECIBE.
## Con un número de capa: set_collision_layer_value() / set_collision_mask_value().
## Para asignar collision_layer o collision_mask enteros: mask().

## Geometría estática: suelo, paredes, rampas, plataformas.
const WORLD: int = 1
## Cuerpo del jugador.
const PLAYER: int = 2
## Cuerpos de los enemigos.
const ENEMY: int = 3
## Zona en la que el jugador recibe daño.
const PLAYER_HURTBOX: int = 4
## Zona en la que un enemigo recibe daño.
const ENEMY_HURTBOX: int = 5
## Ataques y proyectiles del jugador.
const PLAYER_HITBOX: int = 6
## Ataques de contacto y proyectiles de los enemigos.
const ENEMY_HITBOX: int = 7
## Recogibles (experiencia, monedas…).
const PICKUP: int = 8
## Objetos con los que se interactúa (cofres, tragaperras…).
const INTERACTABLE: int = 9

## Nombre de cada capa en Project Settings.
const NAMES: Dictionary[int, String] = {
	WORLD: "world",
	PLAYER: "player",
	ENEMY: "enemy",
	PLAYER_HURTBOX: "player_hurtbox",
	ENEMY_HURTBOX: "enemy_hurtbox",
	PLAYER_HITBOX: "player_hitbox",
	ENEMY_HITBOX: "enemy_hitbox",
	PICKUP: "pickup",
	INTERACTABLE: "interactable",
}


## Máscara de bits con las capas indicadas: mask(WORLD, ENEMY).
static func mask(...layers: Array) -> int:
	var result: int = 0
	for layer: int in layers:
		result |= 1 << (layer - 1)
	return result
