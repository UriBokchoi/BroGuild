class_name CombatRules
extends Resource
## Constantes de las fórmulas de combate (GDD §6, «Stats del personaje»). Los valores viven en
## [code]data/combat/rules.tres[/code]; aquí valen 0 a propósito (ver DECISIONES, «Valores de datos
## solo en el .tres»). No son stats: son reglas iguales para todos.

## Puntos de defensa con los que el daño recibido se queda en la mitad. La defensa reduce con
## rendimientos decrecientes y nunca llega a hacer inmune: daño × k / (k + defensa).
@export_range(1.0, 1000.0, 1.0, "or_greater") var armor_for_half_damage: float = 0.0
