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
| `core/` | Piezas genéricas que no saben de este juego: stats, máquina de estados, componentes de combate, pool (`NodePool`), rejilla espacial (`SpatialHash`, con marcas y tope de resultados), carga de carpetas de datos (`ResourceDir`), nombres de acciones y capas. |
| `entities/` | Lo que existe en el mundo: el jugador, los enemigos y los interactuables. |
| `systems/` | Reglas y sistemas que reparten trabajo entre entidades: combate (fórmulas y armas), progresión, aparición de enemigos. Vacías, para más adelante: `gamble/` y `upgrades/`. |
| `data/` | Los `.tres` de balance y la traducción. Nada de código. |
| `ui/` | HUD, menús, panel de depuración, vista de stats, tema global y dueño del ratón. |
| `vfx/` | Efectos visuales: juice que reacciona a señales, shaders compartidos y líneas de velocidad. |
| `levels/` | Escenas jugables: el gimnasio de pruebas con su zona de combate y la prueba de estrés. |
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
  - La hitbox apunta con señales lo que toca y solo se procesa mientras toca algo.
  - `DamageCalc.attack()` aplica el daño % y el crítico del atacante (`OffenseData`).
  - La vida tira la esquiva y aplica la defensa (`CombatRules`, `data/combat/rules.tres`).
  - Cada golpe es un `DamageInfo`.
- **`HealthComponent`:** muere una sola vez, puede ser inmortal (el muñeco) y `reset()` la rellena (enemigos reutilizados). Solo se procesa si regenera.
- **Armas** (`systems/combat/weapons/`):
  - `WeaponData` lleva el `.tres` del arma con sus `WeaponStats` y un conjunto de mejoras por nivel.
  - `Weapon` es la base: ataca sola por cadencia al más cercano desde `aim_height` y combina sus stats con las del personaje (si las tiene: un enemigo no). `disarm()` la para y retira lo que tenga en juego; `rearm(espera)` la vuelve a poner en marcha. Sin objetivo, busca cada `search_interval`.
  - `TargetFinder` hace una consulta de física y apunta al centro de la hurtbox.
  - `WeaponInventory` es el nodo que crea y quita armas: lo lleva el jugador y lo crea el enemigo que tiene armas.
  - **Las mismas armas sirven a los dos bandos:** la escena dice a quién busca (`target_mask`) y a quién da su proyectil (`hit_mask`). Las de los enemigos viven en `data/enemies/weapons/`, fuera de la armería y de la subida de nivel.
  - **Proyectiles:**
    - `ProjectileWeapon` dispara desde un pool un `Projectile` por golpe, hacia el centro del objetivo; sus stats son `ProjectileStats` (velocidad de proyectil), de los que heredan `StaffStats` y `DaggerStats`. Las del jugador tienen su propio pool (al desarmarlas, sus proyectiles desaparecen); las de los enemigos usan el `ProjectilePool` compartido.
    - `ProjectilePool`: proyectiles de muchas armas, un pool por escena y un máximo en vuelo (si se llena, el disparo no sale). Lo crea el `EnemySwarm`: así los disparos de un enemigo siguen volando aunque muera.
    - `Projectile` (base abstracta) vuela recto y traza un rayo por tick (no atraviesa nada, sin `Area3D`). Golpea con `DamageCalc` + hurtbox, igual que las hitbox. Cada proyectil decide en `_impact` qué hace al dar.
    - `Bolt` (`bolt.gd`): el proyectil más simple, da al primero que toca y termina (el disparo del tirador).
- **Espada** (`sword/`): `Sword` crea `SwordSlash`, un arco con shader y hitbox, desde un pool, inclinado hacia el objetivo.
- **Bastón** (`staff/`): `StaffOrb` explota al tocar enemigo o pared y daña a todos en `explosion_radius` × área, con su explosión en shader.
- **Daga** (`dagger/`): `DaggerBlade` da a uno y, si le quedan `bounces`, salta al más cercano dentro de `bounce_range` con todo su daño.

### Enemigos — `entities/enemies/` y `systems/spawning/`
- **Tipos:** `EnemyData` (en `data/enemies/`) lleva escena, fuentes de stats (`HealthData` y `EnemyStats`: velocidad, contacto, separación, trepar y distancia que guarda) y armas (`weapons`, opcional).
- **`Enemy`** (base de las escenas):
  - Es un `RigidBody3D` sin rotación que choca con el mundo, con el jugador y con otros enemigos.
  - Fija su velocidad horizontal con `EnemySteering`: perseguir con desvío, separarse y decidir si trepa. Con `keep_distance` se queda a esa distancia (`keep_range`) mirando al objetivo.
  - Daña al tocar y con sus armas, si tiene: las crea al prepararse, esperan un poco al aparecer (`first_attack_delay`) y paran al morir (sus disparos en vuelo siguen). Avisa de su muerte y encoge.
- **`EnemySwarm`** (en el nivel) saca enemigos de un `NodePool` por tipo y los mueve en un único bucle.
  - Usa un `SpatialHash` con los vivos, marcando los apoyados para trepar, y una sola consulta de hasta `max_neighbors` vecinos.
  - Cada enemigo recalcula su rumbo cada `steering_slices` ticks; la física lo mueve en todos.
  - Tiene el `ProjectilePool` de los enemigos (`projectile_limit` en vuelo a la vez); `clear()` retira enemigos y proyectiles.
- **Oleadas:**
  - `WaveData` (en `data/waves/`): curva de enemigos por segundo según los minutos, picos, máximo a la vez, distancias de aparición y `WaveEnemy` con pesos y minuto de entrada.
  - `WaveDirector` (en el nivel) los saca alrededor del jugador, en el suelo (un rayo por intento).
- **`DamageReporter`** avisa de cada golpe con la posición de la cabeza (para los números).
- **Tipos y escenas actuales:**
  - `swarmer/`: el esbirro, rápido y frágil, ataca al tocar;
  - `shooter/`: el tirador, se queda a distancia y dispara bolas de fuego lentas (su arma y su proyectil van en la misma carpeta);
  - `target_dummy/`: muñeco de práctica inmortal con `DpsMeter`.

### Interacción — `entities/interactables/`
- `Interactable` es el área con un texto y la señal `interacted`; la detecta el `Interactor` del jugador.
- **Interactuables actuales:**
  - `teleporter/`: `Teleporter`, pisar y aparecer en su destino; también es el recogedor de caídas;
  - `armory/`: la armería de práctica (armas y runas);
  - `summoner/`: el invocador de enemigos de práctica (uno por tipo; su cartel muestra el nombre del enemigo);
  - `wave_bell/`: la campana que arranca y para el director de oleadas.

### Objetos y runas — `systems/upgrades/`
- **`ItemData`** es la base de lo que el jugador lleva y sube de nivel: armas (`WeaponData`) y runas (`RuneData`). Lleva id, nombre, descripción, `max_level()`, `kind_key()` (arma o runa) y `level_modifiers(level)` (lo que mejora cada nivel). La usan la armería y la elección al subir de nivel, y la usará el Archivo.
- **Runas** (`runes/`):
  - `RuneData` (en `data/runes/`) lleva un `StatModifierSet` por nivel, acumulativos, sobre las stats del jugador; el nivel máximo es cuántos haya.
  - `RuneInventory` (en el jugador) aplica y quita esos modificadores al subir, bajar o quitar una runa.
- **Subir de nivel** (`level_up/`):
  - `LevelUpData` (`data/progression/level_up.tres`): número de opciones, ranuras de armas y de runas, y carpetas de las que salen.
  - `LevelUpOffer` (lógica pura, con el azar inyectado) elige las opciones: subir lo que lleva sin pasar del máximo, o algo nuevo si queda ranura de su tipo.
  - `LevelUpController` (en el nivel) escucha `player_leveled_up`, abre `LevelUpPanel` (pausa y cartas, en `ui/menus/level_up/`) y aplica la elegida a las armas o runas del jugador. Usa el flujo `GAMBLE` de `Rng`: la ruleta del Hito 4 irá encima.

### Botín y progresión — `entities/pickups/` y `systems/progression/`
- **Recogibles:**
  - `PickupData` (en `data/pickups/`) lleva escena, recompensa (p. ej. `experience`, `gold`) y vuelo hacia quien recoge (`auto_collect`: vuela nada más salir, esté donde esté).
  - `Pickup` es el nodo: tipo, valor y si ya vuela. Su giro y su balanceo van en el shader, sin `_process` por nodo.
  - `xp_gem/`: la gema de experiencia.
  - `gold_coin/`: la moneda de oro (de recogida automática).
- **`PickupField`** (en el nivel): suelta recogibles en el suelo desde un pool por tipo. Cuando quien recoge está dentro de su `pickup_range` (o nada más salir, si son `auto_collect`), vuelan acelerando hacia él; al llegar, avisan por `EventBus.pickup_collected`. Todos van en un bucle y sin física.
- **`LootDropper`** (en el nivel): escucha `enemy_died` y suelta la gema con la `xp_reward` y la moneda con el `gold_reward` del enemigo. Los cofres y las probabilidades de botín irán aquí.
- **`ExperienceComponent`** (en el jugador): suma la experiencia recogida × `xp_gain` y sube de nivel con la curva de `ExperienceData` (`data/progression/experience.tres`). El jugador aleja la cámara con el nivel.
- **`WalletComponent`** (en el jugador): el oro de la partida (antes «fichas» en el GDD). Suma el recogido × `currency_gain` y lo gasta con `spend()`.
- **Stats de progresión:** `ProgressionData` (experiencia y oro ganados, suerte, radio de recogida).

### Juice y efectos — `vfx/`
- **`juice/`**, efectos que solo escuchan señales:
  - `damage_numbers/`: números de daño con pool y estilo en `data/vfx/damage_numbers.tres`;
  - `hit_wobble.gd`: bamboleo al recibir golpes.
- **`speed_lines/`:** líneas de velocidad en pantalla.
- **`shaders/`:** shaders compartidos: desenfoque de los menús y rejilla del greybox.
- **Shaders propios de una feature:** van con ella (tajo de la espada, teletransporte, líneas de velocidad).

### UI — `ui/`
- **`hud/`:** vida, stamina, experiencia y nivel (arriba), oro (debajo, `GoldCounter`) y aviso de interacción. Escuchan el `EventBus`.
- **`menus/pause/`:** menú de pausa con todas las stats del jugador.
- **`menus/armory/`:** panel de la armería.
- **`menus/level_up/`:** elección al subir de nivel (`LevelUpPanel` y sus `LevelUpCard`).
- **`stats/`:** `StatsView`, la lista de stats de cualquier `StatsComponent` (la usan la pausa y la armería); `StatFormat`, el formato de un valor; y `ModifierFormat`, que describe un modificador («+10 % Daño»).
- **`debug/`:** panel F3 con secciones (`DebugSection`); no se traduce.
- **`theme/`:** el tema global, generado por `tools/gen_themes.gd`.
- **`mouse_capture.gd`:** único dueño del modo del ratón.

### Niveles — `levels/`
- **`test_gym/test_gym.tscn`:** escena principal de pruebas. Zona de movimiento con rampas, bordes, paredes, huecos y escalones, más el pad de daño (`props/`).
- **`test_gym/zones/combat_range.tscn`:** zona de combate a 200 m del gimnasio. Muñecos, armería, invocadores (esbirros y tiradores), campana de oleadas, plataforma escalonada, teletransportes y recogedor de caídas. Las oleadas paran al volver.
- **En la raíz del gimnasio viven** `EnemySwarm`, `WaveDirector`, `PickupField`, `LootDropper`, `LevelUpController` y `LevelUpPanel`, `DamageNumbers`, HUD, pausa y panel de depuración.
- **`stress/stress_test.tscn`:** prueba de rendimiento (herramienta, sin traducir). Mantiene 300 y luego 500 esbirros sobre un jugador inmortal con la espada, mide frames y física y sale. Comando en CLAUDE.md.

## Señales del `EventBus`

| Señal | La emite | La escucha |
|---|---|---|
| `run_started`, `run_ended` | `RunState` | (nadie aún) |
| `cursor_requested` | pausa, armería, panel de depuración | `MouseCapture` |
| `player_stamina_changed` | `StaminaComponent` | `StaminaBar` |
| `player_health_changed` | `Player` | `HealthBar` |
| `player_died` | `Player` | (nadie aún: pantalla de resultados) |
| `enemy_damaged` | `DamageReporter` | `DamageNumbers` |
| `enemy_died` (el propio enemigo) | `Enemy` | `LootDropper` (y más adelante el Archivo) |
| `pickup_collected` | `PickupField` | `ExperienceComponent` (la recompensa `experience`), `WalletComponent` (`gold`) |
| `player_xp_changed` | `Player` | `XpBar` |
| `player_gold_changed` | `Player` | `GoldCounter` |
| `player_leveled_up` | `Player` | `LevelUpController` |
| `interaction_prompt_changed` | `Interactor` | `InteractionPrompt` |

## Capas de física (`core/physics_layers.gd`)

| Capa | Qué hay | Quién la mira |
|---|---|---|
| 1 `world` | Geometría, mesas y pedestales | Jugador, enemigos, cámara, sensores |
| 2 `player` | Cuerpo del jugador | Enemigos, teletransportes |
| 3 `enemy` | Cuerpos de enemigos y muñecos | Jugador, enemigos |
| 4 `player_hurtbox` | Donde el jugador recibe daño | Hitbox de enemigos y trampas, armas y proyectiles de enemigos |
| 5 `enemy_hurtbox` | Donde los enemigos reciben daño | Armas del jugador (hitbox, proyectiles y búsqueda de objetivos) |
| 6 `player_hitbox` | Tajos del jugador | — (ellos miran la 5) |
| 7 `enemy_hitbox` | Contacto de enemigos y trampas | — (miran la 4) |
| 8 `pickup` | — (los recogibles no usan física: los mueve `PickupField`) | — |
| 9 `interactable` | Armería, invocador… | `Interactor` del jugador |

## Recetas: cómo añadir…

- **Un arma:**
  1. Crea un `.tres` `WeaponData` en `data/weapons/`.
  2. Si ataca de otra forma, crea su escena con un script que herede de `Weapon` e implemente `_fire()`, en `systems/combat/weapons/<arma>/`.
  3. Traduce su nombre y descripción.

  Aparece sola en la armería.
- **Una runa:** crea un `.tres` `RuneData` en `data/runes/` con un `StatModifierSet` por nivel (sobre stats que el jugador tenga) y traduce su nombre y descripción. Aparece sola en la armería.
- **Un enemigo:**
  1. Crea un `.tres` `EnemyData` en `data/enemies/`.
  2. Si no reutiliza la escena de otro, crea la suya en `entities/enemies/<enemigo>/`, con raíz `Enemy`, como `swarmer.tscn`.
  3. Si ataca a distancia, dale `keep_distance` y un arma en `weapons`: un `WeaponData` en `data/enemies/weapons/` cuya escena busque `player_hurtbox` (como `shooter_gun.tscn`).
  4. Traduce su nombre y descripción (y los de su arma).
  5. Para que salga en las oleadas, añádelo como `WaveEnemy` en el `WaveData`; para probarlo, pon otro invocador en la zona de combate.
- **Una stat:** añade un `@export_range` en el Resource de datos que toque (`MovementData`, `OffenseData`, `WeaponStats`, `EnemyStats`…), pon su valor en el `.tres` y su fila `STAT_<NOMBRE>` en `data/i18n/strings.csv`. Un test exige la traducción.
- **Un estado de movimiento:** crea un script en `entities/player/movement/states/` que herede de `MovementState` y añade un nodo hijo de `Movement` en `player.tscn` con su acción, prioridad y reglas.
- **Un personaje:** crea un `.tres` `CharacterData` en `data/characters/` con sus diferencias de stats.
- **Un interactuable:** crea una escena con un `Interactable` (capa 9, `prompt_key`) y conecta su `interacted`.
- **Un recogible** (cura, imán…):
  1. Crea un `.tres` `PickupData` en `data/pickups/` con su escena (raíz `Pickup`) y su `reward`.
  2. Haz que el sistema que lo usa escuche `EventBus.pickup_collected` con esa recompensa.
  3. Suéltalo con `PickupField.drop()`, normalmente desde `LootDropper`.
- **Un efecto de juice:** escucha una señal (del componente o del `EventBus`) y no cambies el gameplay. Si hay muchos a la vez, usa `NodePool`.
- **Un texto de interfaz:** pon la clave en `data/i18n/strings.csv` (es y en) y la clave como texto del control, o `tr()`.
- **Una sección de depuración:** crea un `DebugSection` como hijo de las secciones del panel.
