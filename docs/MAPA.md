# Mapa del código — Bro Guild

Para qué sirve cada carpeta y cada sistema, cómo se conectan y dónde se añade cada cosa. Es la guía para orientarse antes de tocar nada.

- **Por qué** se hizo así: `docs/DECISIONES.md`.
- **Qué** tiene que hacer el juego: `docs/GDD.md`.
- **Qué toca ahora**: `docs/ROADMAP.md`.

Se actualiza al crear, mover o quitar un sistema o una carpeta, no al cambiar detalles. Cada script tiene además su docstring `##` con su intención.

## Las cinco ideas que ordenan todo

1. **Datos fuera del código.** Cada número de balance o de feel vive en un `.tres` de `data/` (o en un `@export` de su escena). Todo número exportado de un Resource de datos es una **stat** mejorable con modificadores.
2. **Composición.** Las entidades son nodos con componentes (`StatsComponent`, `HealthComponent`, `HitboxComponent`, `HurtboxComponent`…), no clases enormes. Herencia solo en bases cortas (`State`, `Weapon`, `Enemy`).
3. **Llamar hacia abajo, señales hacia arriba.** Un nodo llama a sus hijos; los hijos avisan con señales. Entre sistemas lejanos, `EventBus`. El juice (números, bamboleos, estelas) solo escucha.
4. **Una feature, una carpeta.** El script, la escena y los Resources propios de una feature van juntos. El script de un Resource de datos va con su sistema; sus `.tres` de balance, en `data/`.
5. **Los tests replican las rutas.** `x/y/z.gd` se prueba en `tests/unit/x/y/test_z.gd` (lógica) o en `tests/integration/x/y/test_z.gd` (escenas).

## Carpetas

| Carpeta | Qué va ahí |
|---|---|
| `autoload/` | Los únicos singletons: `EventBus` (solo señales), `Rng` (todo el azar, un generador por sistema) y `RunState` (partida en curso). Sin lógica de gameplay. |
| `core/` | Piezas genéricas que no saben de este juego: stats, máquina de estados, componentes de combate, pool, rejilla espacial, carga de carpetas de datos, nombres de acciones y capas. |
| `entities/` | Lo que existe en el mundo: el jugador, los enemigos y los interactuables. |
| `systems/` | Reglas y sistemas que reparten trabajo entre entidades: combate (fórmulas y armas), progresión, aparición de enemigos. Vacías, para más adelante: `gamble/` y `upgrades/`. |
| `data/` | Los `.tres` de balance y la traducción. Nada de código. |
| `ui/` | HUD, menús, panel de depuración, vista de stats, tema global y dueño del ratón. |
| `vfx/` | Efectos visuales: juice que reacciona a señales, shaders compartidos y líneas de velocidad. |
| `levels/` | Escenas jugables. De momento, el gimnasio de pruebas con su zona de combate. |
| `tools/` | Validación por terminal (`validate.sh`, `ci/`) y generadores (`gen_themes.gd`). |
| `tests/` | GUT: `unit/` y `integration/`, con la misma ruta que el código. `hooks/` es el script de fin de ejecución. |
| `docs/` | GDD, ROADMAP, DECISIONES y este mapa. |
| `assets/` | Modelos, texturas, audio y fuentes (aún vacíos) y `CREDITS.md`. |

## Sistemas

### Stats — `core/stats/`
- **Para qué:** que cualquier número del juego se pueda mejorar o empeorar sin tocarlo a mano, como en Megabonk.
- `StatsComponent` (nodo) convierte en stats los números exportados de sus `sources` (Resources de datos) y guarda copias «resueltas» que el juego lee con tipo (`get_resolved(MovementData)`).
- `StatBlock` es el único sitio donde se calcula una stat: `(base + Σ planos) × (1 + Σ %) × Π multiplicadores`. El rango de cada `@export_range` es su límite en juego (`RangeHint`).
- Los modificadores son `StatModifier`; los que van juntos (un personaje, una mejora, un nivel de arma) forman un `StatModifierSet`.
- **Lo usan:** el jugador (vida, ataque, progresión, movimiento, stamina), cada arma (sus `WeaponStats`) y cada enemigo (`HealthData` + `EnemyStats`).

### Máquina de estados — `core/state_machine/`
- **Para qué:** el movimiento del jugador (y lo que venga) como estados separados, sin `if` gigantes.
- `StateMachine` aplica las reglas de entrada: gana la primera acción, solo el dash cancela, buffer al final de una acción.
- Cada `State` declara en el inspector su acción, su prioridad, si es comprometido, si cancela y a quién puede interrumpir.

### Jugador — `entities/player/`
`player.tscn` monta todos los componentes; `player.gd` solo los conecta y mueve el cuerpo (y se teletransporta y muere).

| Subcarpeta o nodo | Para qué |
|---|---|
| `movement/` | `MovementContext` (estado compartido entre estados), `MovementData` (sus stats), `WallSensor` y `LedgeSensor` (rayos que solo miran el mundo) y `states/`: suelo, aire, salto, doble salto, dash, dash-jump, slide, slide-jump, salto en pared, caída rápida y mantle. Base común: `MovementState`. |
| `feedback/` | Lo que el cuerpo muestra: `BodyCrouch` (agacha el modelo y baja la hurtbox en el slide), `BodyFacing` (gira el modelo), `DashJumpCue` (aro de la ventana del dash-jump) y `SpeedTrail` (estela). |
| `stamina/` | Cargas de stamina: `StaminaPool` (lógica pura), `StaminaComponent` (nodo que recarga y avisa por EventBus) y `StaminaData`. |
| `camera/` | `CameraRig` (tercera persona, se mueve en `_process` siguiendo la posición interpolada) y `CameraData`. |
| `characters/` | `CharacterData`: las diferencias de un personaje sobre las stats básicas. |
| `player_input.gd` | Convierte el InputMap en acciones de la máquina y en la dirección pedida, relativa a la cámara. |
| `interactor.gd` | Zona que encuentra el `Interactable` más cercano y lo activa con E. |
| Nodos `Health`, `Hurtbox` y `Weapons` | Vida, zona donde recibe daño y `WeaponInventory` con sus armas. |

### Combate — `core/components/` y `systems/combat/`
- **Golpe:** una `HitboxComponent` toca una `HurtboxComponent`, que pasa el golpe a su `HealthComponent`.
  - `DamageCalc.attack()` aplica el daño % y el crítico del atacante (`OffenseData`).
  - La vida tira la esquiva y aplica la defensa (`CombatRules`, `data/combat/rules.tres`).
  - Cada golpe es un `DamageInfo`.
- **`HealthComponent`:** muere una sola vez, puede ser inmortal (el muñeco) y `reset()` la rellena (enemigos reutilizados).
- **Armas** (`systems/combat/weapons/`):
  - `WeaponData` lleva el `.tres` del arma con sus `WeaponStats` y un conjunto de mejoras por nivel.
  - `Weapon` es la base: ataca sola por cadencia al más cercano desde `aim_height` y combina sus stats con las del personaje.
  - `TargetFinder` hace una consulta de física y apunta al centro de la hurtbox.
  - `WeaponInventory` es el nodo del jugador que crea y quita armas.
- **Espada** (`sword/`): `Sword` crea `SwordSlash`, un arco con shader y hitbox, desde un pool, inclinado hacia el objetivo.

### Enemigos — `entities/enemies/` y `systems/spawning/`
- **Tipos:** `EnemyData` (en `data/enemies/`) lleva escena y fuentes de stats: `HealthData` y `EnemyStats` (velocidad, contacto, separación y trepar).
- **`Enemy`** (base de las escenas):
  - Es un `RigidBody3D` sin rotación que choca con el mundo, con el jugador y con otros enemigos.
  - Fija su velocidad horizontal con `EnemySteering`: perseguir con desvío, separarse y decidir si trepa.
  - Daña al tocar, avisa de su muerte y encoge.
- **`EnemySwarm`** (en el nivel) saca enemigos de un `NodePool` por tipo y los mueve en un único bucle. Usa dos `SpatialHash`: vecinos y apoyos para trepar.
- **`DamageReporter`** avisa de cada golpe con la posición de la cabeza (para los números).
- **Tipos y escenas actuales:**
  - `swarmer/`: el esbirro, primer enemigo;
  - `target_dummy/`: muñeco de práctica inmortal con `DpsMeter`.

### Interacción — `entities/interactables/`
- `Interactable` es el área con un texto y la señal `interacted`; la detecta el `Interactor` del jugador.
- **Interactuables actuales:**
  - `teleporter/`: `Teleporter`, pisar y aparecer en su destino; también es el recogedor de caídas;
  - `armory/`: la armería de práctica;
  - `summoner/`: el invocador de enemigos de práctica.

### Juice y efectos — `vfx/`
- **`juice/`**, efectos que solo escuchan señales:
  - `damage_numbers/`: números de daño con pool y estilo en `data/vfx/damage_numbers.tres`;
  - `hit_wobble.gd`: bamboleo al recibir golpes.
- **`speed_lines/`:** líneas de velocidad en pantalla.
- **`shaders/`:** shaders compartidos: desenfoque de los menús y rejilla del greybox.
- **Shaders propios de una feature:** van con ella (tajo de la espada, teletransporte, líneas de velocidad).

### UI — `ui/`
- **`hud/`:** vida, stamina y aviso de interacción. Escuchan el `EventBus`.
- **`menus/pause/`:** menú de pausa con todas las stats del jugador.
- **`menus/armory/`:** panel de la armería.
- **`stats/`:** `StatsView`, la lista de stats de cualquier `StatsComponent` (la usan la pausa y la armería), y `StatFormat`.
- **`debug/`:** panel F3 con secciones (`DebugSection`); no se traduce.
- **`theme/`:** el tema global, generado por `tools/gen_themes.gd`.
- **`mouse_capture.gd`:** único dueño del modo del ratón.

### Niveles — `levels/test_gym/`
- **`test_gym.tscn`:** escena principal de pruebas. Zona de movimiento con rampas, bordes, paredes, huecos y escalones, más el pad de daño (`props/`).
- **`zones/combat_range.tscn`:** zona de combate a 200 m del gimnasio. Muñecos, armería, invocador, plataforma escalonada, teletransportes y recogedor de caídas.
- **En la raíz del nivel viven** `EnemySwarm`, `DamageNumbers`, HUD, pausa y panel de depuración.

## Señales del `EventBus`

| Señal | La emite | La escucha |
|---|---|---|
| `run_started`, `run_ended` | `RunState` | (nadie aún) |
| `cursor_requested` | pausa, armería, panel de depuración | `MouseCapture` |
| `player_stamina_changed` | `StaminaComponent` | `StaminaBar` |
| `player_health_changed` | `Player` | `HealthBar` |
| `player_died` | `Player` | (nadie aún: pantalla de resultados) |
| `enemy_damaged` | `DamageReporter` | `DamageNumbers` |
| `enemy_died` | `Enemy` | (nadie aún: experiencia, Archivo) |
| `interaction_prompt_changed` | `Interactor` | `InteractionPrompt` |

## Capas de física (`core/physics_layers.gd`)

| Capa | Qué hay | Quién la mira |
|---|---|---|
| 1 `world` | Geometría, mesas y pedestales | Jugador, enemigos, cámara, sensores |
| 2 `player` | Cuerpo del jugador | Enemigos, teletransportes |
| 3 `enemy` | Cuerpos de enemigos y muñecos | Jugador, enemigos |
| 4 `player_hurtbox` | Donde el jugador recibe daño | Hitbox de enemigos y trampas |
| 5 `enemy_hurtbox` | Donde los enemigos reciben daño | Armas del jugador (hitbox y búsqueda de objetivos) |
| 6 `player_hitbox` | Tajos y proyectiles del jugador | — (ellos miran la 5) |
| 7 `enemy_hitbox` | Contacto de enemigos y trampas | — (miran la 4) |
| 8 `pickup` | Botín (aún no hay) | — |
| 9 `interactable` | Armería, invocador… | `Interactor` del jugador |

## Recetas: cómo añadir…

- **Un arma:**
  1. Crea un `.tres` `WeaponData` en `data/weapons/`.
  2. Si ataca de otra forma, crea su escena con un script que herede de `Weapon` e implemente `_fire()`, en `systems/combat/weapons/<arma>/`.
  3. Traduce su nombre y descripción.

  Aparece sola en la armería.
- **Un enemigo:**
  1. Crea un `.tres` `EnemyData` en `data/enemies/`.
  2. Si no reutiliza la escena de otro, crea la suya en `entities/enemies/<enemigo>/`, con raíz `Enemy`, como `swarmer.tscn`.
  3. Traduce su nombre y descripción.
- **Una stat:** añade un `@export_range` en el Resource de datos que toque (`MovementData`, `OffenseData`, `WeaponStats`, `EnemyStats`…), pon su valor en el `.tres` y su fila `STAT_<NOMBRE>` en `data/i18n/strings.csv`. Un test exige la traducción.
- **Un estado de movimiento:** crea un script en `entities/player/movement/states/` que herede de `MovementState` y añade un nodo hijo de `Movement` en `player.tscn` con su acción, prioridad y reglas.
- **Un personaje:** crea un `.tres` `CharacterData` en `data/characters/` con sus diferencias de stats.
- **Un interactuable:** crea una escena con un `Interactable` (capa 9, `prompt_key`) y conecta su `interacted`.
- **Un efecto de juice:** escucha una señal (del componente o del `EventBus`) y no cambies el gameplay. Si hay muchos a la vez, usa `NodePool`.
- **Un texto de interfaz:** pon la clave en `data/i18n/strings.csv` (es y en) y la clave como texto del control, o `tr()`.
- **Una sección de depuración:** crea un `DebugSection` como hijo de las secciones del panel.
