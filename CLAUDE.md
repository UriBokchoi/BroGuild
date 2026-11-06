# CLAUDE.md — Bro Guild

Roguelike de hordas en 3D, frenético y con apuestas en cada decisión: el bucle de Megabonk con la movilidad de Deadlock.
Proyecto a largo plazo: se va a ampliar durante meses, así que la arquitectura manda sobre la prisa.

- Diseño: `docs/GDD.md` — léelo antes de tocar gameplay.
- Plan: `docs/ROADMAP.md` — la tarea actual es la primera casilla sin marcar.
- Decisiones de arquitectura: `docs/DECISIONES.md` (créalo si no existe; fecha, decisión y por qué).

## Cómo trabajamos
- Háblame en español, directo y breve. Identificadores de código en inglés; comentarios y documentación en español.
- **Plan antes que código** si la tarea toca 3+ archivos o crea un sistema nuevo: qué archivos, escenas y Resources vas a crear o cambiar, y cómo lo probaré. Espera mi OK.
- **Pasos pequeños**: cada commit deja el juego ejecutable.
- **Ramas**: una por tarea (`feat/…`, `fix/…`, `refactor/…`), creada desde `main` actualizado. Nunca commits directos a `main`.
- **Commits** pequeños, Conventional Commits en español: `feat(movement): añade dash con cargas de stamina`.
- **Al terminar una tarea**: pasa la validación (ver Comandos), marca la casilla en `docs/ROADMAP.md` y dime **cómo probarlo**: qué escena abrir, qué teclas pulsar y qué debería notar. Push y PR a `main` cuando yo lo diga.
- El *feel* lo decido yo jugando. Si hay que elegir entre opciones de diseño o algo no está en el GDD, pregunta: no inventes mecánicas.
- Si un cambio altera el diseño acordado, actualiza `docs/GDD.md` en el mismo commit.

## Stack
- Godot 4.7.x estable · renderer Forward+ · 3D · GDScript con tipado estático (sin C#).
- Addons: solo GUT para tests (o gdUnit4 si GUT no es compatible con nuestra versión). Cualquier otro, pregunta antes.
- Actualizar a Godot 4.8 cuando sea estable: en su propia rama, nunca de paso.

## Comandos
`godot` = ejecutable de Godot 4.7. En el Hito 0 comprueba cuál es en esta máquina y sustitúyelo aquí por la ruta exacta.
- Importar recursos: `godot --headless --path . --import`
- Comprobar un script: `godot --headless --path . --check-only --script res://ruta/al_script.gd`
- Smoke test (arranca la escena principal y sale): `godot --headless --path . --quit-after 600`
- Tests: *(se rellena en el Hito 0 al instalar GUT)*

**Validación**: una tarea no está terminada si la importación, el smoke test o los tests dan errores o warnings nuevos, o si VS Code muestra errores de GDScript en «Problemas».

## Arquitectura (reglas, no sugerencias)
1. **Cero números mágicos.** Todo valor de balance o feel (velocidades, daños, costes, probabilidades, tiempos, colores) vive en Resources `.tres` dentro de `data/`, o en `@export` si es propio de una escena. En la lógica solo hay nombres.
2. **Contenido = datos.** Cada concepto tiene su Resource tipado (`WeaponData`, `EnemyData`, `UpgradeData`, `RarityTable`…). Añadir un arma, enemigo o mejora es crear un `.tres`, sin tocar código.
3. **Composición antes que herencia.** Comportamiento en nodos-componente reutilizables (`HealthComponent`, `HitboxComponent`, `HurtboxComponent`, `StatsComponent`…). Herencia solo para bases claras y poco profundas.
4. **Llamar hacia abajo, señales hacia arriba.** Un nodo llama a sus hijos; los hijos avisan con señales. Entre sistemas lejanos: `EventBus` (autoload que solo declara señales tipadas).
5. **Autoloads mínimos:** `EventBus`, `RunState` (partida en curso), `Rng`, `Audio`, `Save`. Nada de lógica de gameplay suelta en ellos.
6. **Movimiento = máquina de estados.** Un script por estado (`Ground`, `Air`, `Dash`, `Slide`, `WallJump`, `Mantle`…) y parámetros en `data/player/movement.tres`. Nada de `if` gigantes en `player.gd`.
7. **Stats con modificadores.** Las mejoras nunca tocan variables a mano: añaden `StatModifier` (plano, %, multiplicador) a un `StatBlock`, que calcula el valor final en un único sitio.
8. **Todo el azar pasa por `Rng`**, con semilla por partida y un generador por sistema (botín, oleadas, apuestas) para que los bugs sean reproducibles. Tablas ponderadas (`WeightedTable`) y rarezas en datos; la Suerte modifica pesos, nunca `if` repartidos por el código.
9. **Juice desacoplado.** Screen shake, hit-stop, números de daño, flashes y sonidos reaccionan a señales. El gameplay emite eventos; no llama a efectos.
10. **Pooling** para enemigos, proyectiles, pickups y números de daño. Nada de `instantiate()`/`queue_free()` por cada bala.
11. **Sin rutas frágiles.** Prohibido `get_node("../../X")` y `get_parent().get_parent()`. Usa `@export var x: Node3D` o `%NombreUnico`.
12. **Input por acciones** del InputMap (`move_forward`, `jump`, `dash`, `slide`, `interact`…), nunca teclas directas.
13. **Capas de física con nombre** en Project Settings, con sus constantes en un único archivo (`core/physics_layers.gd`).
14. **UI sin literales:** textos con `tr("CLAVE")` (CSV de traducción en `data/i18n/`) y estilos en un `Theme` global.
15. Toda escena se puede ejecutar sola (F6) para probarla.

## Rendimiento
Objetivo: 60 fps estables con 300+ enemigos. Enemigos con steering simple (sin `NavigationAgent3D` por enemigo), colisiones baratas y pooling. Si un cambio puede costar rendimiento, avísame.

## Estilo GDScript
- Tipado estático siempre: `var speed: float = 0.0`, `func take_damage(amount: float) -> void:`. `class_name` en todo tipo reutilizable.
- Orden del script (guía de estilo oficial): `class_name`/`extends` → docstring `##` → señales → enums → constantes → `@export` → variables → `@onready` → métodos virtuales (`_ready`, `_physics_process`…) → públicos → privados (`_nombre`).
- `snake_case` en archivos, funciones y variables; `PascalCase` en clases y nodos; `CONSTANT_CASE` en constantes. Señales en pasado: `died`, `currency_changed`.
- Nombra la mecánica, no la temática: `currency`, `streak`, `pot`; nunca nombres de la temática como `chips` o `la_banca` (ver `docs/DECISIONES.md`).
- Funciones cortas (≈ menos de 40 líneas) y scripts con una sola responsabilidad (≈ menos de 300 líneas). Si crece, divide.
- Comentarios para el *por qué*, no el *qué*. Docstrings `##` en clases y métodos públicos.
- Sin código muerto ni `print()` de depuración en los commits. A la segunda vez que copias algo, extráelo.

## Archivos de Godot
- Tengo el editor de Godot abierto mientras trabajas: antes de editar a mano una escena `.tscn`, avísame para que la guarde y no se pisen los cambios.
- `.tscn` y `.tres` en formato texto. Si los creas a mano, no inventes UIDs: omítelos y Godot los genera.
- Los archivos `.uid` se versionan; `.godot/` no (va en `.gitignore`).
- Mover o renombrar escenas o scripts rompe referencias: avísame antes y, si lo haces tú, mueve también su `.uid` y actualiza todas las rutas.
- No cambies Project Settings globales (resolución, física, render) sin decírmelo.
- Assets solo con licencia libre (mejor CC0: Kenney, Quaternius…), anotando origen y licencia en `assets/CREDITS.md`.

## Estructura
```
CLAUDE.md
docs/        GDD.md, ROADMAP.md, DECISIONES.md
addons/      solo GUT (tests)
autoload/    EventBus, RunState, Rng, Audio, Save
core/        piezas genéricas: state_machine/, stats/, components/, pooling/, weighted_table.gd
entities/    player/ (+ states/), enemies/, pickups/, interactables/
systems/     combat/, gamble/, upgrades/, spawning/, progression/
data/        .tres de balance: player/, weapons/, enemies/, upgrades/, rarities/, i18n/
ui/          hud/, menus/, widgets/, theme
vfx/         shaders/, particles/, juice/
levels/      arenas y escena de pruebas
assets/      models/, textures/, audio/, fonts/, CREDITS.md
tests/       tests de lógica pura (unit/ replica la ruta del código que prueban)
tools/       validación por terminal (validate.sh, ci/)
```
Escena, script y recursos propios de una feature van juntos en su carpeta. El script de un Resource (`class_name MovementData`) va con su feature o sistema; sus instancias de balance (`.tres`), en `data/`.

## Tests
- GUT para lógica pura: stats y modificadores, tablas ponderadas, economía y reglas de las apuestas (siempre con semilla fija).
- El *feel* no se testea: lo pruebo yo jugando.

## Nunca
- Meter una mecánica en `player.gd` "porque es más rápido": va en su estado o componente.
- Reescribir un sistema entero para arreglar un bug pequeño.
- Añadir dependencias, cambiar de versión de Godot o tocar `main` sin preguntar.
- Dar por terminado algo que no has ejecutado.
