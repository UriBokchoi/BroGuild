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
- Godot 4.7.x estable · renderer Forward+ (D3D12 en Windows) · física Jolt · 3D · GDScript con tipado estático (sin C#).
- Warnings de GDScript (Project Settings): declaración sin tipo = **error**; acceso inseguro a propiedad/método y argumento inseguro = warning, que la validación también rechaza.
- Addons: solo GUT para tests (o gdUnit4 si GUT no es compatible con nuestra versión). Cualquier otro, pregunta antes.
- Actualizar a Godot 4.8 cuando sea estable: en su propia rama, nunca de paso.

## Comandos
Ejecutable de consola de Godot 4.7.2 en esta máquina (Git Bash):
`G="D:/Descargas/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe"`
- **Validación completa**: `GODOT="$G" tools/validate.sh` — importación, todos los scripts, smoke test y tests. Sale con ≠ 0 si un paso falla o si su salida contiene ERROR/WARNING.
- Importar recursos: `"$G" --headless --path . --import` (hace falta tras crear un `class_name` nuevo y en un clon recién hecho).
- Comprobar todos los scripts, con warnings: `"$G" --headless --path . -s res://tools/ci/check_scripts.gd -d --ignore-error-breaks`
- Smoke test (arranca la escena principal y sale): `"$G" --headless --path . --quit-after 600 -d --ignore-error-breaks`
- Tests (GUT 9.7.1, configuración en `.gutconfig.json`): `"$G" --headless --path . -s res://addons/gut/gut_cmdln.gd -gconfig=res://.gutconfig.json`. GUT sale con 0 si un test no compila (se lo salta): fíate de `validate.sh`, no solo de esto.

Comprobado en 4.7.2 (detalle en `docs/DECISIONES.md`):
- Godot sale con 0 aunque haya errores de script o de shader: hay que leer la salida (lo hace `validate.sh`).
- Los warnings de GDScript solo se imprimen con `-d`, y `-d` sin `--ignore-error-breaks` se queda en bucle en el depurador ante un error.
- No uses `--check-only`: da un falso error en cualquier script que use un autoload y no muestra warnings.

**Validación**: una tarea no está terminada si `tools/validate.sh` falla o si VS Code muestra errores de GDScript en «Problemas».

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
- `project.godot`: el editor lo reescribe al abrir el proyecto y al cambiar cualquier ajuste, así que pisaría una edición hecha por fuera. Antes de tocarlo, pídeme que cierre el editor. Escríbelo con la API (`ProjectSettings.set_setting()` + `save()` desde un script headless con `-s`), no a mano: así queda igual que si lo guardara el editor. Ojo: un `InputEventKey.new()` lleva `device = 16`; el editor usa `-1` («todos»).
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
- `tests/unit/` replica la ruta del código (`autoload/rng.gd` → `tests/unit/autoload/test_rng.gd`). Archivos `test_*.gd` que extienden `GutTest`, con el mismo tipado estricto que el resto.
- Para probar un autoload sin tocar el global, instancia su script: `const RngService := preload("res://autoload/rng.gd")`.
- El *feel* no se testea: lo pruebo yo jugando.

## Nunca
- Meter una mecánica en `player.gd` "porque es más rápido": va en su estado o componente.
- Reescribir un sistema entero para arreglar un bug pequeño.
- Añadir dependencias, cambiar de versión de Godot o tocar `main` sin preguntar.
- Dar por terminado algo que no has ejecutado.
