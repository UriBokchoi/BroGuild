extends Node
## Bus global de señales entre sistemas lejanos. Solo declara señales tipadas:
## nunca guarda estado ni tiene lógica. Quien emite y quien escucha no se conocen.

# Las señales se emiten desde otros scripts; sin esto, Godot avisa con
# UNUSED_SIGNAL en cada una.
@warning_ignore_start("unused_signal")

## Ha empezado una partida con la semilla indicada.
signal run_started(run_seed: int)
## La partida en curso ha terminado.
signal run_ended
## Se pide reintentar la partida (pausa, resultados): lo atiende [Game]. Ver [RunFlow].
signal retry_requested
## Se pide volver al menú principal (pausa, resultados): lo atiende [Game]. Ver [RunFlow].
signal main_menu_requested
## Una interfaz pide ([param wants_cursor] = true) o suelta el cursor del ratón. Mientras alguna
## lo pida, el ratón no se captura (lo gestiona MouseCapture).
signal cursor_requested(requester: Object, wants_cursor: bool)
## Cambió la stamina del jugador (cargas actuales, que pueden ser fraccionarias, y máximo).
signal player_stamina_changed(charges: float, max_charges: int)
## Cambió la vida del jugador (actual y máxima).
signal player_health_changed(current: float, maximum: float)
## El jugador ha muerto.
signal player_died
## Un enemigo recibió un golpe de [param amount] (tras su defensa) en [param position], el punto
## donde mostrar los efectos (encima de su cabeza).
signal enemy_damaged(position: Vector3, amount: float, info: DamageInfo)
## Cambió lo que el jugador puede hacer con «interactuar» (clave de traducción; vacía = nada).
signal interaction_prompt_changed(prompt_key: StringName)
## Murió [param enemy] (aún en su sitio, con su tipo y sus stats): botín, experiencia, Archivo…
signal enemy_died(enemy: Enemy)
## El jugador rompió un rompible (calavera, bolsita…) de [param data] en [param at].
signal breakable_broken(data: BreakableData, at: Vector3)
## Se recogió un recogible que da [param reward] (p. ej. [code]experience[/code]) por [param amount].
signal pickup_collected(reward: StringName, amount: float)
## Cambió la experiencia del jugador ([param current] de [param needed]) o su nivel.
signal player_xp_changed(current: float, needed: float, level: int)
## El jugador subió al nivel [param level].
signal player_leveled_up(level: int)
## Cambió el oro del jugador.
signal player_gold_changed(gold: float)
## Cambió el nivel de un arma o runa del jugador: al conseguirla (1), al subirla y al perderla (0).
signal player_item_changed(item: ItemData, level: int)
## Cambiaron las ranuras abiertas del jugador (sin limitar a las que hay: eso lo hace [LevelUpData]).
signal player_slots_changed(weapon_slots: int, rune_slots: int)
## Pasó un segundo de la ronda: van [param seconds] y si ya pasó su duración ([param overtime]). Con
## [param seconds] negativo, no hay ronda en marcha.
signal run_clock_changed(seconds: float, overtime: bool)
