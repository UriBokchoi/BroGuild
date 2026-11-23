class_name MovementSynergyData
extends Resource
## Daño de las mejoras con sinergia de movimiento (GDD §6): el slide deja un rastro de fuego
## ([FireTrail]), cada dash suelta una onda y la caída rápida explota al aterrizar
## ([SynergyWave]). Valen 0 sin su objeto (no hacen nada) y cada copia del objeto los sube. Pasan por el daño % y
## el crítico del jugador; su tamaño, por el área %. Los valores viven en
## [code]data/player/movement_synergy.tres[/code]; aquí todo vale 0 a propósito.

@export_group("synergy")
## Daño de cada quemadura del rastro de fuego del slide (0 = sin rastro).
@export_range(0.0, 1000.0, 0.5, "or_greater") var fire_trail_damage: float = 0.0
## Daño de la onda que suelta cada dash (0 = sin onda).
@export_range(0.0, 1000.0, 0.5, "or_greater") var dash_wave_damage: float = 0.0
## Daño de la explosión al aterrizar de una caída rápida (0 = sin explosión).
@export_range(0.0, 1000.0, 0.5, "or_greater") var slam_damage: float = 0.0
