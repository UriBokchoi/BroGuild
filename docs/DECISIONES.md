# Decisiones

Registro de decisiones de arquitectura y de proyecto: fecha, decisión y por qué.
Las nuevas van al final. Si una decisión se revierte, se añade otra que lo diga; las antiguas no se borran.

## 2026-11-06 · Nombre definitivo «Bro Guild» y temática medieval con humor
- **Decisión:** el juego se llama **Bro Guild** (`config/name` en `project.godot`). La temática pasa de casino-neón a **medieval con humor moderno**, sin realismo. Las apuestas siguen siendo el corazón del juego, pero sin casino; las **tragaperras repartidas por el mapa se quedan**. El repo de GitHub (`DuskTower`) y la carpeta local (`dusk-tower`) conservan el nombre anterior.
- **Por qué:** decisión del diseñador. El GDD aún usa nombres de casino (fichas, La Banca, crupier, mesa…); se adaptarán en una sesión de diseño aparte y están listados como pendientes en `GDD.md` §11.

## 2026-11-06 · Identificadores de código según la mecánica, no la temática
- **Decisión:** en código, señales y datos se nombra la mecánica (`currency`, `gamble`, `streak`, `pot`, `boss`…), nunca el disfraz temático (`chips`, `la_banca`…). Los nombres visibles para el jugador viven en las traducciones (`data/i18n/`).
- **Por qué:** la temática ya ha cambiado una vez. Así un cambio de nombres o de ambientación solo toca textos y assets, no código ni `.tres`.

## 2026-11-06 · Carpeta de datos de usuario fija: `bro_guild`
- **Decisión:** `application/config/use_custom_user_dir=true` y `custom_user_dir_name="bro_guild"`. En Windows, `user://` queda en `%APPDATA%/bro_guild`.
- **Por qué:** por defecto Godot deriva la carpeta de `config/name`; si el título cambiara, guardados, ajustes y remapeos quedarían huérfanos.

## 2026-11-06 · Arranque del repositorio
- **Decisión:** `main` parte del commit inicial que GitHub creó con el `README.md`. Todo lo demás entra por PR desde ramas `feat/…`, `fix/…`, `refactor/…` o `docs/…`. Los commits de este repo usan el email noreply de GitHub (`git config user.email` local).
- **Por qué:** cumple la regla «nunca commits directos a `main`» sin excepciones y no expone el email personal en un repo público.

## 2026-11-06 · Estructura: `addons/`, `tools/` y dónde van los Resources
- **Decisión:** a la estructura de `CLAUDE.md` se añaden `addons/` (solo GUT) y `tools/` (validación por terminal). El script que define un Resource (`class_name MovementData`) vive con su feature o sistema (`entities/player/`, `systems/combat/`…); las instancias de balance (`.tres`) viven en `data/`. Las carpetas vacías llevan `.gitkeep` hasta que reciben contenido.
- **Por qué:** «contenido = datos» pide un único sitio donde ajustar el balance (`data/`), y «lo de una feature va junto» pide que el código no se separe de su escena. Separar clase (código) e instancias (balance) cumple ambas.

## 2026-11-06 · Escena de pruebas: medidas provisionales del greybox
- **Decisión:** `levels/test_gym/test_gym.tscn` es la escena principal hasta que exista un menú. 1 unidad = 1 m. Piezas (CSG con colisión, capa 1 = mundo), casi todas con su medida en el nombre del nodo o en el de su grupo:
  - suelo de 100×100 m con rejilla de 1 m (líneas fuertes cada 5 m);
  - rampas de 10/20/30/40/50° hasta una terraza de 3 m (50° supera el `floor_max_angle` por defecto, 45°);
  - pendiente de 15° y 30 m para el slide;
  - bordes de 0,5 a 2,5 m (mantle);
  - chimeneas de 3 y 5 m de ancho y 8 m de alto, y un muro de 20×6 m (saltos en pared);
  - plataformas a 2 m con huecos de 3/5/7/9 m;
  - escalones flotantes cada 1,5 m hasta 7,5 m;
  - pista de 60 m entre dos pórticos.
- **Por qué:** el GDD no fija métricas y el jugador aún no existe. Un rango de valores permite calibrar el movimiento del Hito 1 sin rehacer la escena. Colores: suelo gris, rampas azules, paredes marrones, plataformas claras, marcas naranjas.

## 2026-11-06 · Rutas `res://` (no `uid://`) en `project.godot`
- **Decisión:** escena principal y autoloads se registran con ruta `res://`.
- **Por qué:** comprobado en 4.7.2: en un clon recién hecho (sin `.godot/`) una escena principal `uid://` aborta y un autoload `uid://` queda a `null` sin error de salida. Contrapartida: si se mueve uno de esos archivos, hay que actualizar la ruta a mano.

## 2026-11-06 · Validación por terminal: `tools/validate.sh`
- **Decisión:** un único script hace importación → carga de todos los scripts, escenas, recursos y shaders (`tools/ci/check_project.gd`) → smoke test de la escena principal → GUT, y falla si un paso sale con código ≠ 0 o si su salida contiene `ERROR`, `WARNING` o `Parse Error`. La ruta de Godot llega por la variable `GODOT`.
- **Por qué (comprobado en 4.7.2):**
  - Godot sale con 0 con errores de script en tiempo de ejecución, con scripts que no compilan durante `--import` o el smoke test, y con errores de shader.
  - Los warnings de GDScript solo se imprimen con el depurador local (`-d`), que hay que combinar con `--ignore-error-breaks` para que no se quede en bucle ante un error.
  - `--check-only` da «Identifier not found» en cualquier script que use un autoload, así que se sustituye por un runner que carga cada script sin caché.
  - GUT sale con 0 si un test no compila (lo ignora), si falta la caché de clases o si no se ejecuta nada; por eso se exige además el mensaje «All tests passed». Y solo falla un test por errores dentro de su cuerpo: el hook `tests/hooks/post_run.gd` hace fallar la ejecución por errores en `before_*`/`after_*` y por `push_warning`, respetando los esperados (`assert_push_error`).
  - Un asset que no se importa deja su `.import` con `valid=false` y Godot no lo reintenta: se busca esa marca tras cada importación.
  - Un shader no se compila al cargarlo, sino al pedir sus parámetros; el comprobador lo fuerza para que aparezcan sus errores.
  - Las escenas y los `.tres` que la escena principal no usa también se cargan, para que una referencia rota no pase desapercibida.

## 2026-11-06 · Warnings estrictos de GDScript
- **Decisión:** `untyped_declaration` = error; `unsafe_property_access`, `unsafe_method_access` y `unsafe_call_argument` = warning (la validación los rechaza igual). `unsafe_cast` queda desactivado. Los addons siguen excluidos (`directory_rules` por defecto; en 4.7 ya no existe `exclude_addons`).
- **Por qué:** hace cumplir el tipado estático de `CLAUDE.md` en vez de confiar en la disciplina. `unsafe_cast` avisaría en cada `as` sobre un `Variant`, que es justo la forma correcta de tipar.

## 2026-11-06 · Autoloads del Hito 0: `EventBus`, `Rng`, `RunState`
- **Decisión:** solo estos tres, en ese orden; `Audio` llegará con el sonido (Hito 4) y `Save` con el guardado (Hito 6). Sus scripts no llevan `class_name` (Godot da error si coincide con el nombre del autoload); se usan por su nombre global, que ya está tipado.
  - `EventBus`: solo señales tipadas; `@warning_ignore_start("unused_signal")` porque se emiten desde fuera.
  - `Rng`: un `RandomNumberGenerator` por sistema (`Rng.Stream`: LOOT, WAVES, GAMBLE, COMBAT, ENEMIES, COSMETIC). Semilla de cada uno = `hash("<semilla>:<NOMBRE>")`, así que añadir o reordenar generadores no cambia los existentes. COSMETIC existe para que los efectos no consuman azar de gameplay. La lógica pura recibe el generador por parámetro.
  - `RunState`: ciclo de vida de la partida (`start_run(seed)` siembra `Rng` y emite `run_started`; `end_run()`). Empezar con una partida en curso la termina antes (reinicio).
- **Por qué:** autoloads mínimos y sin lógica de gameplay (`CLAUDE.md` regla 5); generadores separados para que los bugs sean reproducibles (regla 8). Pendiente para cuando haya partidas: forzar la semilla desde la línea de comandos para reproducir un bug.

## 2026-11-06 · Tests con GUT 9.7.1, copiado en el repo
- **Decisión:** GUT 9.7.1 (rama `godot_4_7`) copiado tal cual en `addons/gut/` desde el zip oficial (sha256 `14969aa4…4086`), con el plugin activado para el panel del editor. Configuración en `.gutconfig.json`; tests en `tests/unit/`.
- **Por qué:** es la versión que GUT marca para Godot 4.7; la Asset Library solo ofrece la 9.6.1 (para 4.6). Copiado en el repo, cualquier clon tiene los tests sin pasos extra. Comprobado en 4.7.2: importación limpia y sin warnings con el tipado estricto. Para actualizarlo: rama propia, sustituir la carpeta entera y pasar `validate.sh`.

## 2026-11-06 · InputMap: una acción por tecla, con teclas físicas
- **Decisión:** 10 acciones del GDD §8: `move_forward/back/left/right` (WASD), `jump` (Espacio), `dash` (Shift), `slide` (Ctrl), `interact` (E), `show_stats` (Tab), `pause` (Esc). Teclas físicas, dispositivo «todos» y zona muerta 0,2 (lo mismo que escribe el editor de 4.7). Los nombres viven en `core/input_actions.gd` (`InputActions.JUMP`…); un test comprueba que coinciden en ambos sentidos con Project Settings.
- **Por qué:** una tecla con varios usos es una sola acción que cada estado interpreta (Espacio = salto, doble salto, salto en pared, dash-jump, slide-jump y mantle; Ctrl = slide o caída rápida; E = interactuar o, manteniendo, cobrar). Dos acciones en la misma tecla se descuadrarían al remapear. Mirar con el ratón no es una acción (`InputEventMouseMotion`, sensibilidad en datos). Acciones de depuración, cartas, reroll o pactos se añadirán con su sistema.

## 2026-11-06 · Capas de física con nombre
- **Decisión:** 1 `world`, 2 `player`, 3 `enemy`, 4 `player_hurtbox`, 5 `enemy_hurtbox`, 6 `player_hitbox`, 7 `enemy_hitbox`, 8 `pickup`, 9 `interactable`. Constantes y nombres en `core/physics_layers.gd`; un test comprueba que coinciden con Project Settings. Convención: **hitbox hace daño, hurtbox lo recibe**.
- **Por qué:** separar cuerpo y hurtbox permite cambiar la forma que recibe daño (la hurtbox baja del slide) sin tocar la colisión con el mundo. Previsto para el rendimiento con 300+ enemigos: los enemigos no chocarán entre sí (su máscara no incluirá `enemy`; la separación se hará en el steering) y la cámara solo chocará con `world`; se decide del todo en el Hito 2.

## 2026-11-07 · Nombre confirmado; carpeta y repo renombrados
- **Decisión:** el nombre definitivo es **Bro Guild** (descartado «Bro Code»). La carpeta local pasa de `dusk-tower` a `bro-guild` y el repo de GitHub, de `DuskTower` a `BroGuild` (GitHub redirige las URL antiguas).
- **Por qué:** decisión del diseñador. Sustituye a la parte de la entrada del 2026-11-06 que decía que el repo y la carpeta conservaban el nombre anterior. El proyecto hay que volver a añadirlo en el gestor de proyectos de Godot (Importar → `D:/Documentos/bro-guild/project.godot`).

## 2026-11-08 · Versiones: etiquetas por hito y ramas fusionadas
- **Decisión:** al cerrar un hito, su último commit en `main` lleva una etiqueta anotada `hito-N` (`hito-0` = `880208e`). GitHub borra la rama de un PR al fusionarlo (`delete_branch_on_merge`); `feat/cimientos` se borró a mano por la misma razón.
- **Por qué:** el diseñador prefiere no borrar nada que no esté guardado. Una rama fusionada es obsoleta: sus commits siguen en `main` y GitHub la puede restaurar desde su PR. Las etiquetas dejan cada versión jugable a mano (`git switch --detach hito-0`).

## 2026-11-08 · Stats: StatBlock, StatModifier y StatsComponent
- **Decisión:**
  - Valor final = (base + Σ planos) × (1 + Σ porcentajes) × Π multiplicadores, limitado a [mínimo, máximo] y, si la stat es entera, redondeado al más cercano (x,5 sube). Se recalcula solo al cambiar sus modificadores y se guarda; `stat_changed(stat, value, previous)` solo se emite si el valor cambia.
  - Todo `float`/`int` con `@export` o `@export_range` de un Resource de datos es una stat, con su valor como base. El `@export_range` es también el límite en juego (`or_greater`/`or_less` lo abren; con `radians_as_degrees` se pasa a radianes). Los `int` son stats enteras; enums, bools y curvas no son stats.
  - Cada modificador se aplica con su origen (la mejora, el pacto, el rasgo…) y se quita por origen; una vez aplicado es inmutable. Una stat que no existe es un error, para cazar erratas en los `.tres`.
  - `StatsComponent` junta las stats de los Resources de datos de una entidad y mantiene una copia resuelta de cada uno: el juego lee `move.run_speed` con tipo, y el `.tres` original no cambia nunca.
- **Por qué:** añadir una stat es añadir un `@export` al Resource, sin registrarla en ningún otro sitio, y mejoras y personajes la modifican por su nombre desde sus `.tres`. Las copias resueltas evitan una lista de constantes que repita los nombres y dan autocompletado y comprobación de tipos. Usar el rango del inspector como límite evita una segunda fuente de verdad e impide, por ejemplo, que una maldición deje una velocidad en negativo.

## 2026-11-08 · Valores de datos solo en el `.tres`
- **Decisión:** los scripts de Resources de datos (`CameraData`, `MovementData`…) declaran los campos con valor neutro (0, `false` o `null`), y los valores de verdad van en su `.tres` de `data/`. Ese valor neutro no se cambia nunca.
- **Por qué:** Godot no guarda en el `.tres` las propiedades que coinciden con el valor por defecto del script (comprobado en 4.7.2). Si el script trae valores de balance, el `.tres` sale casi vacío, el valor real queda escondido en el código y cambiar un valor por defecto cambiaría el juego sin tocar `data/`. Con valores neutros, todo lo ajustado es distinto del defecto y siempre queda escrito en el `.tres`.

## 2026-11-08 · Interpolación de física
- **Decisión:** `physics/common/physics_interpolation = true` y `physics_jitter_fix = 0` (la documentación de Godot pide quitar la corrección de tirones al interpolar). Lo que se mueve en `_process` (cámaras) va con `physics_interpolation_mode = OFF` y sigue `get_global_transform_interpolated()` de su objetivo. Al teletransportar algo (aparecer, reaparecer), `reset_physics_interpolation()`.
- **Por qué:** la física va a 60 ticks por segundo. Sin interpolar, en monitores de 144 Hz el jugador y la cámara se moverían a saltos.

## 2026-11-08 · Cámara en tercera persona
- **Decisión:** `CameraRig` (`entities/player/camera/`) es una escena propia con `top_level`. Sigue a su `target` a la altura del pivote, gira con el ratón y se aleja con el nivel: distancia = `base_distance` × `distance_by_level(nivel)`. La curva va del nivel 1 al 100 y, pasado el último punto, se queda en su valor. Un `SpringArm3D` con una esfera de 0,25 m que solo choca con `world` la acerca en vez de atravesar paredes y suelo. Valores de partida en `data/player/camera.tres`: 5 m a nivel 1 y ×1,4 lineal hasta 7 m a nivel 100 (2 cm por nivel); pivote a 1,6 m; FOV 75°; sensibilidad 0,15 °/px; inclinación entre −70° y 35°, empezando en −15°.
- **Convenciones:** los ángulos de los datos se guardan en radianes con `radians_as_degrees` (el inspector muestra grados, como en los nodos de Godot). La sensibilidad va en grados por píxel y usa `screen_relative`, que no cambia con el escalado de la ventana. Hasta el Hito 2 el nivel se cambia en `CameraRig.level` desde el inspector remoto; luego lo pondrá la progresión.
- **Por qué:** una escena propia permite reutilizar la cámara y probarla sola. Una curva multiplicadora permite cambiar la distancia base sin rehacer la forma.

## 2026-11-08 · Captura del ratón
- **Decisión:** `MouseCapture` (`ui/mouse_capture.gd`) va en la escena principal: captura el ratón al empezar, Esc (`pause`) lo suelta y un clic lo vuelve a capturar. El clic no es una acción del InputMap, igual que mirar con el ratón. Es provisional: el menú de pausa se quedará con Esc.
- **Por qué:** el modo del ratón es de toda la partida (menús, ruleta de nivel, pausa), no del jugador. Además, así los tests que instancian al jugador no capturan el ratón.

## 2026-11-08 · Tests de integración
- **Decisión:** los tests que instancian escenas van en `tests/integration/`, con la misma ruta que el código (`entities/player/player.tscn` → `tests/integration/entities/player/test_player_scene.gd`). `tests/unit/` queda para lógica pura.
- **Por qué:** separar lo que depende de escenas deja claro qué se rompe cuando cambia una escena y qué cuando cambia la lógica.

## 2026-11-08 · Máquina de estados y reglas de las acciones
- **Decisión:**
  - `StateMachine` y `State` (`core/state_machine/`) son genéricos, para el jugador y para futuras IAs. Cada estado es un nodo hijo con su script y declara en el inspector cómo participa en las acciones: `trigger_action`, `priority`, `committed`, `cancels_committed` e `interrupts`.
  - La máquina guarda las acciones pedidas (`request`) en orden y aplica las reglas del GDD:
    - gana la primera que puede ejecutarse, y como mucho entra una por tick;
    - entre estados de la misma acción entra el de mayor prioridad que pueda;
    - un estado comprometido solo lo cancelan los estados que cancelan (el dash) o los que lo listan en `interrupts` (el slide-jump al slide);
    - lo pulsado durante un estado comprometido se guarda si le quedan `committed_end_buffer` segundos o menos y si no, se descarta;
    - lo que todavía no puede entrar espera `buffer_time` segundos (el jump buffer).
  - Los dos tiempos salen de `movement.tres` (`input_buffer_time` 0,12 s y `action_end_buffer_time` 0,1 s), y `Player` los pasa a la máquina en cada tick.
  - Se puede volver a entrar en el estado activo (dash sobre dash). Los estados no cambian de estado en `enter`/`exit`, solo en `physics_update`.
- **Jugador:**
  - `player.gd` solo monta el `MovementContext` (cuerpo, stats resueltas y estados neutros Suelo/Aire), avanza la máquina y llama a `move_and_slide()`, el único sitio donde se hace.
  - `PlayerInput` reenvía las pulsaciones de las acciones que activan algún estado, así que un estado nuevo con su acción no obliga a tocarlo.
  - Los estados heredan de `MovementState` (contexto tipado, `settle()` para volver a Suelo o Aire, `apply_gravity()`).
- **Gravedad:** sale del salto. Con `jump_height` y `jump_time_to_apex`, la gravedad es 2h/t² y la velocidad de salto 2h/t, con un tope de caída `max_fall_speed`. Valores de partida: 2 m en 0,35 s (≈ 32,7 m/s² y 11,4 m/s) y caída máxima de 40 m/s.
- **Por qué:** las reglas viven en un solo sitio y cada mecánica solo declara sus datos. Un estado nuevo (un gancho, por ejemplo) es un nodo con su script, sin tocar los demás. Definir el salto por altura y tiempo permite ajustar el feel con dos números que se entienden; la gravedad cuadra sola.

## 2026-11-08 · Arrays tipados con la propia clase
- **Decisión:** `State.interrupts` es `Array[Node]`, no `Array[State]`.
- **Por qué:** en 4.7.2, un array tipado con la propia clase del script (`Array[State]` dentro de `State`) hace que el script se referencie a sí mismo, y Godot avisa al salir de que `state.gd` sigue en uso y hay instancias perdidas. `validate.sh` lo detecta. Se tipa con la clase nativa y se documenta qué contiene.

## 2026-11-08 · Correr, saltar y control aéreo
- **Decisión:**
  - **Dirección pedida:** WASD (`Input.get_vector`) girado según el giro horizontal de la cámara (`CameraRig.get_yaw()`). `Player` la deja cada tick en `MovementContext.wish_direction`, así que los estados no leen el Input y se pueden probar sin teclado.
  - **Suelo:** acelera hacia `wish × run_speed` con `ground_acceleration` y frena con `ground_deceleration` al soltar.
  - **Aire:** acelera hacia la dirección pedida con `air_acceleration`, apuntando a la mayor de `run_speed` y la velocidad que ya se lleva. Así se puede girar y frenar (pidiendo lo contrario), pero no se pierde de golpe el impulso por encima de la carrera, y tampoco se gana velocidad haciendo zigzag en el aire. Sin dirección, frena con `air_deceleration` (0 de partida: se conserva todo).
  - **Salto:** `JumpState` da `jump_velocity()` al entrar y pasa al aire en el mismo tick. Entra si hay suelo o queda coyote time: `coyote_time` arranca al dejar el suelo sin saltar y lo gasta el salto. El jump buffer es el `input_buffer_time` de la máquina.
  - **Modelo:** `BodyFacing` gira el modelo (no el cuerpo físico) hacia la velocidad horizontal a `turn_speed`.
  - **Valores de partida:** carrera 9 m/s (aceleración 60 m/s², frenada 50 m/s²), aire 30 m/s², coyote 0,12 s y giro 720 °/s. Al integrar por ticks, el salto de 2 m llega a ≈ 2,09 m.
- **`StatsComponent`** registra sus datos en `_enter_tree` en vez de en `_ready`. Así cualquier nodo los lee en su `_ready` sin depender del orden de los hermanos.
- **Por qué:** el GDD pide carrera rápida, mucho control aéreo y que el impulso no se pierda de golpe; esa regla del aire deja que el dash y el dash-jump conserven su velocidad sin trucos aparte. Todos los números son stats, así que mejoras y personajes pueden cambiarlos.

## 2026-11-09 · Panel de depuración
- **Decisión:**
  - **Panel:** `DebugPanel` (`ui/debug/`) es un `CanvasLayer` que F3 (acción `toggle_debug`) muestra u oculta. Solo existe en builds de depuración y solo se actualiza mientras se ve.
  - **Secciones:** cada bloque es un `DebugSection`, hijo de `%Sections`, que recibe al jugador en `setup()` y se refresca cada frame. Un sistema nuevo añade su sección sin tocar el panel. De partida hay tres:
    - movimiento (estado, velocidades, suelo, coyote);
    - cámara (deslizador de nivel hasta el último punto de la curva);
    - stats: todas las del jugador con su valor y su base, y botones ±10 % que aplican un `StatModifier` en nombre del panel, como haría una mejora; «reset» los quita.
  - **Textos:** muestra nombres internos sin traducir (excepción a la regla 14).
  - **Foco:** sus botones y deslizadores no cogen el foco, para que Espacio siga saltando.
  - **Accesos nuevos:** `Player.context` es público para leer; `StatsComponent` y `StatBlock` dan `get_stats()` y `get_base()`.
- **Por qué:** el diseñador quiere que todas las stats sean mejorables, como en Megabonk (GDD §5). La sección de stats lo deja probar ya, antes de que exista el sistema de mejoras (Hito 3), y cualquier stat nueva aparece en el panel sin tocarlo. Un modificador en % sobre una base 0 (p. ej. `air_deceleration`) no cambia nada; para esas stats, las mejoras usarán modificadores planos.

## 2026-11-09 · Menú de pausa
- **Decisión:**
  - **Apertura:** Esc (`pause`) abre `PauseMenu` (`ui/menus/pause/`). Pausa el árbol (`get_tree().paused`), pide el cursor y deja el foco en «Continuar» para manejarlo también con el teclado. Funciona en pausa con `process_mode = ALWAYS`.
  - **Izquierda:** título y botones Continuar, Opciones (desactivado hasta que tenga función), Reintentar (por ahora recarga la escena; en el Hito 2 pasará por `RunState`) y Salir.
  - **Derecha:** un panel fijo con `StatsView`: todas las stats del jugador agrupadas como en sus datos, con nombre traducido, unidad (sacada del `@export_range`) y scroll. Las que difieren de su base salen resaltadas, con la base al lado. Encabezados y filas salen solos de los datos: una stat nueva solo necesita su traducción.
  - **Cierre:** al cerrar se suelta el foco; si no, Espacio pulsaría el botón en vez de saltar. «Continuar» no estaba en el pedido: se añadió porque es lo normal en una pausa (Esc también cierra).
- **Por qué:** lo pidió el diseñador, con las stats visibles como en Megabonk. `StatsView` es reutilizable para la pantalla de stats (Tab) del Hito 3.

## 2026-11-09 · Ratón con un solo dueño (sustituye a «Captura del ratón»)
- **Decisión:** `MouseCapture` captura el ratón salvo mientras alguna interfaz pida el cursor con `EventBus.cursor_requested(requester, wants_cursor)`. Lo piden el menú de pausa y el panel de depuración (F3), así que ya no hace falta Esc para pulsar los botones del panel. Se conecta en `_enter_tree` para no perder peticiones y olvida a quien pidió el cursor y ya no existe. Desaparecen «Esc suelta el ratón» y «clic para recapturar».
- **Por qué:** cada interfaz futura (ruleta de nivel, cofres, tragaperras) solo emite la señal; el modo del ratón se decide en un único sitio.

## 2026-11-09 · Textos traducibles y Theme global
- **Decisión:**
  - **Textos:** viven en `data/i18n/strings.csv` (`keys,es,en`).
    - Godot genera los `.translation` al importar (están en `.gitignore`; un clon nuevo necesita `--import`, que ya hace `validate.sh`). Sin el idioma del sistema, se usa el inglés.
    - En las escenas, el texto de un control es la clave y Godot lo traduce solo. Las etiquetas de números desactivan la autotraducción.
    - Las stats se traducen como `STAT_<NOMBRE>` y sus grupos como `STAT_GROUP_<GRUPO>`, por eso los `@export_group` de los datos usan identificadores (`run`, `jump`, `air`, `input`). Un test exige que cada stat del jugador tenga su nombre en todos los idiomas.
  - **Estilo:** `ui/theme/main_theme.tres` (`gui/theme/custom`) tiene una paleta pizarra oscura con acentos dorados y la fuente por defecto de Godot en negrita (`FontVariation`, sin assets externos). Lleva variaciones de tipo para títulos, encabezados, filas de stats y espaciados de menú (`ScreenMargin`, `MenuList`, `StatList`), y estilos de botón, panel y barra de scroll.
  - **Panel de depuración:** usa su propio tema compacto (`ui/debug/debug_theme.tres`) y no se traduce.
  - **Fondo de los menús:** `vfx/shaders/screen_blur.gdshader` difumina y tiñe lo que hay detrás.
- **Por qué:** era la tarea siguiente del ROADMAP y el menú de pausa es la primera interfaz de verdad; así nace ya traducible y con estilo en un solo sitio.
- **Comprobado en 4.7.2:**
  - Los Resources traen sus propios grupos de propiedades (`Resource`), sin stats: el panel solo pone un encabezado cuando el grupo tiene alguna stat.
  - `String.num(9.0, 2)` devuelve `"9.0"`: `StatFormat` quita los ceros del final.
  - Un script lanzado con `-s` se compila antes que los autoloads: si nombra una clase que usa uno (p. ej. `PauseMenu` usa `EventBus`), esa clase no compila. En esos scripts hay que usar `call()`.

## 2026-11-09 · Stamina por cargas y HUD mínimo
- **Decisión:**
  - **Datos:** `StaminaData` (`data/player/stamina.tres`) es la segunda fuente de stats del jugador: `max_charges` (entera) y `recharge_time` por carga. Valores de partida del GDD: 3 cargas, 3 s por carga. Al ser stats, salen solas en el menú de pausa y en F3, y son mejorables (+1 carga con un modificador plano).
  - **Lógica:** `StaminaPool` es lógica pura con cargas fraccionarias (el ½ del salto en pared) y recarga continua; tiene un margen de 1e-6 para que los errores de coma flotante no impidan gastar una carga recién recargada.
  - **Componente:** `StaminaComponent` lo actualiza con las stats en cada tick, así que una mejora del máximo se nota al momento. Avisa con su señal `changed` y con `EventBus.player_stamina_changed` para la interfaz. Los estados de movimiento la encuentran en `MovementContext.stamina`; el coste de cada acción será una stat de esa acción.
  - **HUD:** `ui/hud/hud.tscn` con `StaminaBar`: una barra por carga (variación `ChargeBar` del Theme), la que recarga a medias. Se rehace si cambia el máximo. Escucha desde `_enter_tree`, así que recibe el primer aviso, que se emite en el `_ready` del jugador.
- **Por qué:** el GDD define la stamina por cargas que se regeneran y pide decidir cuándo gastar la última. La barra a medias deja ver cuánto falta. Separar sus datos de `MovementData` deja cada Resource con un solo tema y demuestra que el jugador admite varias fuentes de stats.

## 2026-11-09 · Dash, picado y doble salto
- **Decisión:**
  - **Dash** (`DashState`; en la escena: acción `dash`, comprometido, cancela):
    - va en la dirección pedida o, sin dirección, hacia donde mira la cámara (`MovementContext.view_forward`), a `dash_speed` durante `dash_duration`;
    - en el aire va recto, sin gravedad;
    - al terminar, la velocidad horizontal se queda en `dash_exit_speed` como mucho;
    - gasta `dash_cost`.
  - **Picado** (`DownDashState`; misma acción con prioridad 10, comprometido, cancela):
    - entra si estás en el aire, sin dirección y a menos de `down_dash_window` de un dash que empezó en el aire;
    - va hacia abajo a `down_dash_speed` durante `down_dash_duration`, o hasta tocar suelo;
    - gasta `down_dash_cost` además del dash.
    - El contexto guarda un reloj de juego (`elapsed`) y el momento y el lugar del último dash.
  - **Doble salto** (`DoubleJumpState`; acción `jump`, prioridad 10):
    - entra en el aire si no queda coyote time (con coyote, Espacio es el salto normal), quedan `air_jumps` y hay stamina;
    - sube `air_jump_height` con la gravedad del salto;
    - los saltos en el aire se recuperan al entrar en Suelo.
  - **Prioridades de la acción `jump`:** Jump 0 y doble salto 10. Quedan libres 20 (dash-jump), 30 (salto en pared) y 40 (mantle), para el orden del GDD.
  - **Valores de partida:**
    - dash: 28 m/s durante 0,2 s (≈ 5,6 m) y salida a 12 m/s; 1 dash en el aire por salto (`air_dashes`, añadido a petición del diseñador: los dashes totales los limita la stamina y los del aire, esta stat; el picado no cuenta);
    - picado: 30 m/s durante 0,2 s, con ventana de 0,3 s;
    - doble salto: 1 salto de 2 m;
    - todo cuesta 1 carga.
- **Por qué:** el GDD define las acciones, sus teclas y su coste; lo que no decía (el dash recto en el aire, la velocidad de salida, la duración y la ventana del picado, la altura del doble salto) queda en datos con valores razonables, para ajustarlo jugando o desde F3. Sin salida limitada, el control aéreo conservaría los 28 m/s del dash hasta aterrizar.
- **Tests:** con física real, cada `await wait_physics_frames(1)` en bucle avanza unos 2 ticks de GUT. Los tests comprueban en momentos con margen, no en ticks exactos.

## 2026-11-09 · Stats de combate y progresión
- **Decisión:**
  - Tres Resources de datos nuevos, fuentes de stats del jugador junto a movimiento y stamina:
    - `HealthData` (`core/components/health/`, genérico para jugador y enemigos): vida máxima, regeneración, defensa, esquiva (como mucho 90 %) y robo de vida;
    - `OffenseData` (`systems/combat/`): daño, crítico, daño crítico, velocidad de ataque, proyectiles extra, velocidad de proyectil, área, duración y retroceso;
    - `ProgressionData` (`systems/progression/`): experiencia y fichas ganadas, suerte y radio de recogida.
  - Instancias en `data/player/{health,offense,progression}.tres`. Las fuentes van en ese orden y luego movimiento y stamina, así que el menú de pausa muestra primero lo de combate.
  - **Unidades:** los porcentajes se guardan como porcentaje (100 = normal, 5 = 5 %). Así una mejora de «+10 % de daño» es PERCENT 0.1 y «+5 % de crítico», FLAT 5, y el menú los muestra tal cual.
  - **Valores de partida y fórmulas:** en la tabla «Stats del personaje» del GDD (§6).
  - **Sin lógica todavía:** no hay sistemas que las usen; vida, armas, experiencia y botín llegan en el Hito 2 y leerán estas stats. Las fórmulas se escriben en código cuando exista lo que las usa, para no dejar constantes de balance sueltas antes de tiempo.
- **Por qué:** el diseñador quiere las stats típicas de Megabonk o Vampire Survivors (daño, crítico, proyectiles, defensa, vida, multiplicador de experiencia…), mejorables y visibles desde ya. Al ser datos, una stat nueva es un `@export` más y su traducción.

## 2026-11-09 · Slide y slide-jump
- **Decisión:**
  - **Slide** (`SlideState`; acción `slide`, comprometido):
    - entra en el suelo a partir de `slide_min_speed` y conserva la velocidad que llevas;
    - cada tick suma el tirón de la pendiente (`slide_gravity` × la componente de la gravedad sobre el suelo: acelera cuesta abajo, frena cuesta arriba, nada en llano) y frena con `slide_friction`, sin pasar de `slide_max_speed`;
    - termina al soltar Ctrl (`MovementContext.slide_held`, que pone `Player` cada tick), al bajar de la velocidad mínima o al dejar el suelo (pasa al aire con coyote time).
  - **Dash → slide:** `DashState.slide` apunta al slide. Si al acabar el dash se mantiene Ctrl y el slide puede entrar, pasa a él sin el recorte de salida: el slide alarga el dash.
  - **Slide-jump** (`SlideJumpState`; acción `jump`, prioridad 5, `interrupts = [Slide]`): solo entra mientras interrumpe al slide (`interrupts.has(current)`, sin una referencia aparte). Da la velocidad del salto normal y conserva todo el impulso horizontal.
  - **Agachado:** `BodyCrouch` agacha el modelo, solo visual, con suavizado y los pies en el suelo, mientras el estado es uno de `crouch_states` (en la escena, el slide). La colisión no cambia; la hurtbox baja llegará con el combate.
  - **Valores de partida:** mínima 6 m/s, máxima 22 m/s, frenada 5 m/s² y tirón 30 m/s². Elegidos para que la rampa de 15° del gimnasio acelere (comprobado: de 9 a 14,6 m/s bajándola) y en llano el slide dure algo más de medio segundo desde la carrera.
- **Por qué:** el GDD pide un slide gratis que acelere cuesta abajo y frene cuesta arriba, el slide-jump con impulso y que dash → slide alargue el dash. Que el slide-jump use `interrupts` confirma que la regla «nada se cancela salvo con el dash» admite continuaciones diseñadas sin excepciones en la máquina.

## 2026-11-09 · Personajes: stats básicas y diferencias
- **Decisión:**
  - Las stats de `data/player/*.tres` son las básicas, comunes a todos los personajes.
  - Un personaje es un `CharacterData` (`entities/player/characters/`, instancias en `data/characters/`): un `StatModifierSet` (lista de `StatModifier` que se aplican y se quitan juntos) con las claves de traducción de su nombre y su descripción.
  - `StatBlock` tiene dos capas. Los modificadores de base (`add_base_modifier`) cambian la base con la misma fórmula; las mejoras (`add_modifier`) se calculan encima. `get_base` devuelve la base del personaje, así que el menú solo resalta lo que cambian las mejoras.
  - `StatsComponent.base_sets` aplica los personajes al entrar en el árbol, justo después de definir las stats; en la escena del jugador, el personaje base.
  - **Cambiar de personaje:** elegirlo será poner otro `CharacterData` en `base_sets` antes de crear al jugador. Los gimmicks que no sean stats (habilidades propias) se añadirán al `CharacterData` cuando lleguen.
  - Solo existe el personaje base, sin diferencias: los personajes concretos los decide el diseñador. Un test comprueba que cada personaje de `data/characters/` tiene su nombre y su descripción traducidos y que solo toca stats que existen.
- **Por qué:** el diseñador quiere unas stats básicas y que cada personaje varíe un poco según su gimmick. Como diferencias sobre una base común, un personaje nuevo es un `.tres` con 2-3 modificadores, y cambiar una stat básica afecta a todos.

## 2026-11-09 · Dash-jump
- **Decisión:**
  - **Ventana:** `DashState` apunta en el contexto la dirección del dash y, al acabar (no si otro dash o el picado lo cancelan), el momento (`dash_end_time`). `MovementContext.is_dash_jump_open()` dice si la ventana está abierta: el dash fue en el suelo y no han pasado más de `dash_jump_window` segundos.
  - **Estado** (`DashJumpState`; acción `jump`, prioridad 20, `interrupts = [Slide]`):
    - entra con la ventana abierta y stamina para `dash_jump_cost`;
    - da la velocidad del dash en su dirección y sube `dash_jump_height`; el control aéreo conserva esa velocidad;
    - gasta la ventana.
  - **Casos que salen solos de las reglas:**
    - pulsar en los últimos 0,1 s del dash lo guarda hasta que acaba;
    - en dash → slide funciona dentro de la ventana;
    - sin stamina, entra el salto normal.
  - **Aviso visual:** `DashJumpCue` enseña un aro dorado en los pies mientras `is_dash_jump_open()`. Solo lee el contexto.
  - **Valores de partida:** ventana 0,15 s, altura 2 m y coste 1 carga. Con el dash a 28 m/s, el salto mide ≈ 21 m (medido en el gimnasio), de sobra para el hueco de 9 m. Se ajusta en los datos.
- **Por qué:** el GDD pide el dash-jump justo tras el dash, con ventana corta y aviso visual, y que conserve la velocidad del dash. La ventana se mide desde el final del dash para que encaje con la regla de que nada interrumpe al dash.

## 2026-11-09 · Girar durante el slide
- **Decisión:** el slide se curva con WASD. Cada tick, `SlideState.steer()` gira la parte horizontal de la velocidad hacia la dirección pedida, como mucho `slide_turn_speed` (180 °/s de partida), sin cambiar su rapidez ni la parte vertical. Sin dirección, sigue recto. Pedir hacia atrás lo da la vuelta poco a poco; la frenada sigue siendo la del slide.
- **Por qué:** lo pidió el diseñador: moverse mientras desliza, como en Deadlock, y no ir siempre hacia delante. Girar sin perder velocidad mantiene el slide como forma rápida de moverse y de esquivar.

## 2026-11-09 · Plan: movimiento, combate y menús
- **Decisión:**
  - **Orden:** el diseñador decide terminar el movimiento y después el combate (Hito 2, en la zona de pruebas), y luego los menús y el flujo de partida (Hito 3). Los mapas de los tres niveles iniciales (el Brosque, la Torre del Mago y la Mazmorra) van después del juice (Hito 6).
  - **Movimiento pendiente:** cancelar el dash con un slide (solo en el suelo, con la velocidad del dash), salto en pared al estilo Deadlock, caída rápida, mantle y sensación de velocidad.
  - **Combate:**
    - personajes iniciales: Guerrero (espada), Mago (bastón de mago) y Pícaro (daga);
    - armas automáticas con 4 ranuras de armas y 4 de runas, nivel máximo 5 (valores por defecto, en datos);
    - subir de nivel = elegir 1 de 3;
    - runas: Fuerza, Amplitud, Prisa, Vigor y Multiplicidad (cantidad de proyectiles, que también afecta a la espada; el nombre es provisional).
  - **Menús:**
    - menú principal: Jugar, Archivo y Abandonar;
    - selección de personaje con panel de info al pasar el ratón y modelo 3D en el centro;
    - selección de nivel en el lugar del panel de info;
    - Archivo con desbloqueos por conseguir o derrotar.
  - **Arquitectura prevista:**
    - `WeaponData` y `RuneData` con un `StatModifierSet` por nivel;
    - `EnemyData` con `HealthData`;
    - `LevelData`;
    - un catálogo `data/content.tres` del que salen los menús, el Archivo y las opciones al subir de nivel;
    - `Save` para los desbloqueos;
    - escena raíz `Game` con el flujo de pantallas.
- **Por qué:** lo pidió el diseñador. Todo lo nuevo es contenido en datos sobre los sistemas que ya existen (stats con dos capas, conjuntos de modificadores), así que añadir un arma, una runa, un enemigo o un nivel será crear su `.tres`.

## 2026-11-09 · El slide corta el dash en el suelo
- **Decisión:** el nodo Slide lista a Dash en sus `interrupts`, así que Ctrl a mitad de un dash corta el dash si se puede deslizar (en el suelo y con velocidad). El slide sigue con la velocidad del dash, recortada a la máxima del slide. `DashState.exit()` abre la ventana del dash-jump cuando el siguiente estado es el slide, así que dash → slide → Espacio sigue siendo un dash-jump. En el aire no hace nada.
- **Por qué:** lo pidió el diseñador: cancelar el dash a la mitad con un slide y usar ese impulso, solo en el suelo. Es una continuación diseñada, así que va por `interrupts`, sin excepciones en la máquina; el GDD lo añade a las reglas de entrada.

## 2026-11-09 · Salto en pared
- **Decisión:**
  - **Detección:** `WallSensor` lanza 12 rayos horizontales a la altura del centro del cuerpo contra el mundo y devuelve la normal de la pared casi vertical más cercana dentro de `wall_jump_reach` (0,75 m desde el centro). No hace falta estar empujando la pared. `MovementContext.wall_normal()` lo consulta.
  - **Salto** (`WallJumpState`; acción `jump`, prioridad 30, por encima del dash-jump y del doble salto como pide el GDD):
    - entra en el aire con una pared al alcance;
    - sale hacia la dirección pedida, rebotada si apunta a la pared, más la normal de la pared, así que siempre se separa de ella; sin dirección, sale recto hacia fuera;
    - la velocidad horizontal es la mayor entre la que llevabas y `wall_jump_speed` (10 m/s), y sube `wall_jump_height` (1,8 m);
    - no gasta saltos en el aire.
  - **Coste:** el primero es gratis y los encadenados sin tocar suelo cuestan `wall_jump_chain_cost` (½ carga); el suelo reinicia la cadena.
  - **Comprobado en el gimnasio:** en la chimenea de 3 m se sube de pared a pared (dos saltos, unos 4,5 m de altura).
- **Por qué:** el GDD y el diseñador piden un salto en pared al estilo de Deadlock: responsivo, hacia donde apuntas y encadenable con stamina. Los rayos alrededor detectan la pared aunque no te estés moviendo contra ella, que es lo que lo hace responsivo.

## 2026-11-10 · Caída rápida
- **Decisión:** `FastFallState` (acción `slide`, prioridad 10, comprometida) entra en el aire si hay stamina para `fast_fall_cost` (1 carga). Fija la velocidad recta hacia abajo a `fast_fall_speed` (45 m/s, más que la caída máxima normal), sin impulso horizontal, hasta tocar suelo. Al aterrizar emite `slammed(impact_speed)` para la futura mejora de impacto en área y el juice; la caída no llama a efectos. Comparte Ctrl con el slide sin conflicto: el slide solo entra en el suelo y la caída rápida solo en el aire. Sin stamina, Ctrl en el aire queda en el buffer y, si aterrizas corriendo enseguida, empiezas a deslizar.
- **Por qué:** el GDD la define como «picado al suelo». Recta, sin impulso horizontal, deja apuntar dónde caes, que es lo que importará para el impacto en área. Es distinta del picado (doble Shift), que es una ráfaga corta hacia abajo.

## 2026-11-10 · Mantle
- **Decisión:**
  - **Detección:** `LedgeSensor` busca un borde en tres pasos:
    1. un rayo hacia delante, justo por encima de `mantle_min_height`, encuentra una pared de cara al cuerpo dentro de `mantle_reach`;
    2. un rayo hacia abajo desde `mantle_max_height`, un poco dentro del borde, encuentra su parte de arriba (si el borde es más alto, el rayo nace dentro del bloque y no da: no hay mantle);
    3. una consulta con la cápsula del cuerpo comprueba que cabe encima, pasado el filo.
    - La dirección es la pedida o, sin dirección, la de la cámara.
  - **Estado** (`MantleState`; acción `jump`, prioridad 40, la más alta como pide el GDD; comprometido):
    - sube en vertical a `mantle_climb_speed` hasta pasar el borde;
    - luego avanza hacia dentro con la gravedad puesta (para acabar pisándolo) y sale a `mantle_exit_speed`;
    - con Ctrl mantenido pasa al slide; tiene un tiempo máximo por si algo lo atasca.
    - Gratis. Funciona en el suelo y en el aire.
  - **Valores de partida:** de 0,3 a 2,6 m, alcance 0,8 m, subida y salida a 12 m/s. Comprobado en los cinco bordes del gimnasio (0,5 a 2,5 m).
- **Por qué:** el GDD lo define como subir bordes a media altura con un pico de velocidad y salir deslizando con Ctrl. Con la detección por rayos y la comprobación de la cápsula, un borde nuevo del mapa funciona sin marcarlo a mano.

## 2026-11-10 · Sensación de velocidad
- **Decisión:**
  - **FOV dinámico:** `CameraData.fov_by_speed` (curva: velocidad horizontal en m/s → grados que se suman) y `fov_smoothing`. `CameraRig` abre el FOV con la velocidad de su objetivo si es un `CharacterBody3D`, suavizado. De partida: sin cambio hasta la carrera (9 m/s) y +14° a la velocidad del dash (28 m/s).
  - **Estela:** `SpeedTrail` (un `GPUParticles3D`) emite puntos dorados suaves en el mundo mientras el estado es uno de `trail_states` (en la escena: dash, dash-jump, picado y slide). Escucha `state_changed`.
  - **Líneas de velocidad:** `SpeedLines` (`vfx/speed_lines/`, una capa de pantalla con el shader `speed_lines.gdshader`) dibuja rayas radiales finas en los bordes. Aparecen a partir de 15 m/s y están a tope a 28 m/s, suavizadas; por debajo de una intensidad mínima ni se dibujan.
  - Las tres son solo visuales: leen la velocidad o el estado y no cambian el movimiento (juice desacoplado).
- **Por qué:** el ROADMAP pide FOV dinámico, estela de dash y líneas de velocidad para que moverse rápido se note. Ajustadas mirando capturas: las primeras líneas tapaban demasiado y la estela eran cuadrados, así que pasaron a ser finas, solo en los bordes, y puntos difuminados.

## 2026-11-10 · Toque Deadlock: arranque, sprint, dash, caída rápida y slides encadenados
- **Decisión:**
  - **Arranque progresivo:** `ground_acceleration` baja de 60 a 25 m/s² (unos 0,35 s hasta los 9 m/s).
  - **Sprint:** `MovementState.track_sprint()` (en Suelo y Aire) cuenta los segundos seguidos pidiendo dirección y soltarla lo reinicia; las acciones no lo cortan. Tras `sprint_delay` (2 s), `MovementContext.ground_speed()` pasa de `run_speed` (9 m/s) a `sprint_speed` (11,5 m/s). El suelo acelera hacia esa velocidad y el control aéreo la respeta.
  - **Dash:** en el suelo exige ir al menos a `dash_min_speed` (3 m/s, por debajo de caminar), así que parado o arrancando no hay dash. En el aire no se exige, para no quitar el dash tras un salto vertical.
  - **Caída rápida con doble Ctrl:**
    - `PlayerInput` avisa de cada pulsación (`action_pressed`) y el contexto apunta la última y la anterior de cada acción (`record_press`, `is_double_tap`);
    - `FastFallState` entra si las dos últimas pulsaciones de Ctrl están a menos de `fast_fall_double_tap_window` (0,3 s), así que un solo Ctrl en el aire ya no hace nada;
    - el picado de doble Shift (`DownDashState` y sus stats) se quita por obsoleto: había dos «dash hacia abajo» y el diseñador quiere el de doble Ctrl. Ahora doble Shift en el aire son dos dashes normales, limitados por `air_dashes`. El código antiguo queda en git.
  - **Slides encadenados:**
    - `AirState.slide`: al aterrizar con Ctrl mantenido y velocidad suficiente, pasa a slide en vez de a Suelo, sin perder el impulso;
    - el slide también cuenta como tocar suelo (`touch_ground()`: devuelve saltos y dashes en el aire y reinicia la cadena de saltos en pared);
    - comprobado en el gimnasio: sprint 11,5 → dash 28 → slide 22 → slide-jump 20,3 → aterriza deslizando a 20,3 m/s.
- **Por qué:** el diseñador quiere que se sienta como Deadlock: arranque con peso, sprint al mantener el movimiento, dash que pide ir lanzado, el dash hacia abajo en la tecla de agacharse y poder encadenar slides conservando el impulso.

## 2026-11-13 · Vida, daño y muerte
- **Decisión:**
  - **Fórmulas** (`systems/combat/`):
    - `DamageCalc` es estático y sin estado: `attack()` aplica el daño % y tira el crítico del atacante; `evades()` tira la esquiva; `after_armor()` aplica la defensa.
    - La constante de la defensa (`armor_for_half_damage`, 100) vive en `CombatRules` (`data/combat/rules.tres`), no en el código.
    - Cada golpe es un `DamageInfo` (cantidad, si es crítico y quién lo hizo), para que los números de daño, el robo de vida o los afijos lo lean sin cambiar la firma.
  - **Componentes** (`core/components/`), iguales para jugador y enemigos:
    - `HealthComponent` lee `HealthData` de su `StatsComponent`. Recibe golpes: primero esquiva y luego defensa; nunca baja de 0; muere una sola vez (`died`) y muerto no recibe daño ni cura. Regenera en `_physics_process`. Subir la vida máxima cura la diferencia; bajarla solo recorta.
    - `HurtboxComponent` (un `Area3D` que se deja detectar y no detecta) pasa el golpe a su vida.
    - `HitboxComponent` (un `Area3D` que detecta) consulta en cada tick las hurtbox que toca y les pega con las stats de ataque de quien la lleva (`attacker_stats`, opcional). `rehit_interval` a 0 pega una vez a cada objetivo; con un valor, repite mientras toque (daño de contacto).
    - El azar sale del flujo `COMBAT` de `Rng`, y los tests le ponen su propio generador con semilla.
  - **Jugador:**
    - Hurtbox en la capa `player_hurtbox`.
    - `BodyCrouch` baja también su cápsula en el slide, al momento y no suavizada como el modelo, porque es lógica de juego. La forma es `resource_local_to_scene` para que cada instancia baje la suya.
    - Al morir se para (sin procesar física ni velocidad) y avisa por `EventBus.player_died`. La pantalla de resultados llegará con su tarea; de momento se reinicia con Esc → Reintentar.
  - **HUD:** barra de vida roja encima de la de stamina, centradas abajo; escucha `EventBus.player_health_changed`.
  - **Gimnasio:** un pad rojo (`DamagePad`, 10 de daño cada 0,5 s) para probar el daño sin enemigos.
- **Por qué:** el ROADMAP pide vida, daño y muerte con las fórmulas del GDD y la hurtbox baja en el slide. Con componentes compartidos, los enemigos, armas y trampas que vengan solo combinan hitbox, hurtbox y vida.

## 2026-11-13 · Armas automáticas, espada y zona de práctica de combate
- **Decisión:**
  - **Datos del arma** (`systems/combat/weapons/`):
    - `WeaponStats` son las stats propias del arma: daño, tiempo entre ataques, proyectiles, pausa entre golpes, área, duración y alcance. Son stats de verdad (`StatsComponent` propio de cada arma), así que sus mejoras son modificadores.
    - `WeaponData` (`data/weapons/*.tres`) lleva id estable, nombre, descripción, escena, stats de nivel 1 y un `StatModifierSet` por nivel a partir del 2. El nivel máximo es uno más que los conjuntos (la espada llega a 5).
  - **Arma automática:**
    - `Weapon` (base abstracta) ataca sola cuando acaba su espera y hay un objetivo a su alcance. Cada ataque son N golpes (proyectiles del arma + los del personaje) separados por la pausa entre golpes; el golpe i va al i-ésimo enemigo más cercano.
    - Combina sus stats con `OffenseData`: la velocidad de ataque divide la espera, el área y la duración multiplican, y el daño % y el crítico van en el golpe (`HitboxComponent`).
    - `TargetFinder` hace una consulta de física (esfera sobre `enemy_hurtbox`), así que cualquier cosa con esa hurtbox es un objetivo.
    - `WeaponInventory` (en el jugador) crea, quita y lista armas. Al morir, el jugador lo desactiva.
  - **Espada:**
    - Cada golpe es un `SwordSlash`: un arco dibujado con shader (media luna que barre y se desvanece) y una hitbox que golpea una vez a cada enemigo.
    - Los tajos alternan lado e inclinación, salen de un pool y se escalan al alcance × área (el área también alarga su alcance).
    - Valores de partida: 20 de daño cada 1,1 s, 2,8 m, 1 tajo. Por nivel: +6 daño, +1 tajo, +25 % área, +10 daño y −20 % de espera.
  - **Golpes:**
    - `HealthComponent.damaged` informa de lo que valía el golpe tras la defensa, aunque pase de la vida que quedaba, que es lo que muestran los números. `take_damage()` devuelve la vida quitada de verdad.
    - Nuevo `immortal`: avisa de los golpes sin perder vida.
    - `HitboxComponent` solo golpea con `monitoring` activo y tiene `reset_hits()` para cada ataque nuevo.
  - **Números de daño** (`vfx/juice/damage_numbers/`):
    - Los enemigos avisan de cada golpe por `EventBus.enemy_damaged`, con un `DamageReporter` sobre la cabeza.
    - `DamageNumbers`, en el nivel, saca `Label3D` de un `NodePool` (`core/pooling/`): saltan en arco con un «pop» de escala y se desvanecen.
    - Blancos los normales; amarillos y ×1,5 los críticos. Siempre del mismo tamaño en pantalla y por encima de todo.
    - Estilo en `data/vfx/damage_numbers.tres`. El azar es del flujo cosmético. Con demasiados en pantalla, los nuevos no salen.
  - **Muñeco de práctica** (`entities/enemies/target_dummy/`):
    - Capas de enemigo, vida inmortal, `DamageReporter` y `DpsMeter`. El DPS se mide desde el primer golpe; tras 3 s sin golpes se cierra con el intervalo medio, sin contar la espera.
    - `HitWobble` (juice) lo inclina con un muelle, alejándolo de quien golpea.
  - **Interacción:**
    - `Interactable` (área en la capa `interactable`, con su texto) e `Interactor` (área del jugador): elige el más cercano, avisa al HUD por `EventBus.interaction_prompt_changed` y lo activa con E.
    - El HUD muestra la tecla dibujada y el texto encima de la vida.
  - **Zona de práctica** (`levels/test_gym/zones/combat_range.tscn`, a 200 m del gimnasio):
    - cinco muñecos (uno solo, un grupo de tres y uno lejos);
    - la armería: su panel (`ui/menus/armory/`) lista todo `data/weapons` (`ResourceDir.load_all`), equipa, quita y sube o baja de nivel, y muestra las stats del arma con la vista de stats de la pausa. Pausa el juego y Esc lo cierra sin abrir la pausa;
    - un recogedor de caídas.
    - `Teleporter` (pisar = ir a su destino) une las dos zonas. El destino de la vuelta lo pone el gimnasio.
  - **Herramientas:** el generador de temas pasa a `tools/gen_themes.gd`; solo existía fuera del repositorio.
- **Por qué:** el ROADMAP pedía la base de armas y la espada. El diseñador quería además probar el combate con calma: una zona aparte del movimiento, muñecos con DPS, números de daño con efecto (blancos y críticos amarillos, como en Megabonk) y una forma de cambiar de armas. Todo queda en datos y componentes, así que un arma nueva aparece sola en la armería, y cualquier enemigo con `DamageReporter` saca números.

## 2026-11-15 · Enemigo cuerpo a cuerpo, enjambre y pooling
- **Decisión:**
  - **Datos:** `EnemyData` (`data/enemies/*.tres`) lleva id estable, nombre, descripción, escena y sus fuentes de stats: un `HealthData` y un `EnemyStats` con velocidad, aceleración, daño y ritmo de contacto, y radio y fuerza de separación. Son stats de verdad, así que los afijos de élite serán modificadores.
  - **Primer enemigo:** el «enjambre cuerpo a cuerpo» del GDD, con id `swarmer` y nombre provisional «Esbirro». Tiene 30 de vida, va a 6 m/s y hace 8 de daño al tocar cada 0,8 s.
  - **`Enemy`** (base de las escenas de enemigo):
    - Persigue y se separa con `EnemySteering` (funciones puras en el plano XZ). Choca solo con el mundo y cae con la gravedad del mundo.
    - Hace daño con una `HitboxComponent` de contacto que repite mientras toca.
    - Al morir deja de recibir y de hacer daño, avisa por `EventBus.enemy_died` (para experiencia, botín y Archivo), encoge 0,15 s y desaparece.
    - No tiene `_physics_process` propio.
  - **`EnemySwarm`** (`systems/spawning/`):
    - Un `NodePool` por tipo de enemigo. Al desactivarse, el enemigo queda con `process_mode` desactivado, lo que también lo saca de la física.
    - Mueve a todos los enemigos en un único bucle. Cada tick rellena un `SpatialHash` (`core/`, rejilla XZ) y cada enemigo solo mira las celdas cercanas para separarse, sin comparar todos con todos.
    - Retira a los que caen por debajo de `kill_height`.
    - Quien decida cuándo y dónde salen (el director, el invocador) solo llama a `spawn()`.
  - **`HealthComponent.reset()`** devuelve la vida llena a un enemigo reutilizado.
  - **Práctica:** un `Summoner` en la zona de combate saca con E un anillo de 12 esbirros a 10 m de quien lo usa. El `EnemySwarm` vive en el nivel y la zona se lo pasa al invocador.
  - **Sin retroceso ni destello** al golpear (Hito 5). Los choques y el apilado, en la entrada siguiente.
- **Por qué:** el ROADMAP pide un enemigo cuerpo a cuerpo con datos, steering simple y pooling, y CLAUDE.md pide 300+ enemigos sin navegación por enemigo. El bucle único y el hash espacial son la base para medirlo en la escena de estrés del director de oleadas.

## 2026-11-16 · Enemigos físicos que chocan y se apilan
- **Decisión:**
  - **Cuerpos:**
    - `Enemy` pasa de `CharacterBody3D` a `RigidBody3D` sin rotación, sin dormir y sin fricción. Choca con el mundo, con el jugador y con otros enemigos.
    - El jugador choca también con la capa `enemy`: no los atraviesa y puede quedarse de pie encima. Sus sensores de pared y de borde siguen mirando solo el mundo, así que no hay salto en pared ni mantle sobre enemigos.
    - Entre ellos no se hacen daño, porque su hitbox de contacto solo mira la hurtbox del jugador.
  - **Movimiento:** el enjambre solo fija la velocidad horizontal de cada enemigo; la gravedad, los empujones y las pilas los resuelve Jolt. Cada enemigo se acerca con su propio desvío (`approach_spread`, al azar del flujo `ENEMIES` al aparecer), que desaparece al llegar, para que la horda no vaya en rayos perfectos.
  - **Trepar** (`climb_speed`, `climb_height`): un enemigo trepa (sube a `climb_speed`) si cumple todo esto:
    - quiere avanzar y va frenado;
    - tiene delante, a su alcance, un enemigo apoyado (que ni sube ni cae);
    - ese enemigo está más cerca del objetivo que él;
    - sus pies están por debajo de los del objetivo + `climb_height`.
  - **Cómo se llegó ahí, probando con 40 esbirros:**
    - sin trepar, un corro cerrado se atasca como un arco de piedra;
    - sin la regla de «más cerca del objetivo», dos vecinos trepan uno sobre otro sin parar;
    - sin la de «apoyado», la horda entera sube de una pieza;
    - con fricción, el que trepa arrastra a sus vecinos hacia arriba;
    - sin `climb_height`, levantan una torre de 20 m encima del jugador.
  - **Resultado:** con todo eso forman un montículo estable (media de 2,5 m) y, si el jugador está en alto, se apilan para llegar a él.
  - **Separación:** solo cuenta vecinos a su altura (distancia en 3D), para no deshacer las pilas. El enjambre apunta al principio de cada tick qué enemigos están apoyados, en un segundo `SpatialHash`, para que el resultado no dependa del orden del bucle.
  - **Esbirro:** separación 0,3; trepa a 3,5 m/s hasta 1,5 m sobre el objetivo; desvío de 25°.
  - **Visto en las pruebas:** la horda empuja un poco al jugador (unos 0,5 m/s con 40 encima): el cuerpo del jugador sale de los solapes.
- **Por qué:** el diseñador pidió que los enemigos choquen con él y entre ellos sin hacerse daño y que se puedan acumular, mirando Megabonk. Allí los enemigos se apilan en una masa que avanza hacia el jugador. Con cuerpos físicos el apilado sale de la física y el retroceso de las armas será un impulso.

## 2026-11-16 · Organización del jugador y mapa del código
- **Decisión:**
  - **Movimiento del jugador:** `movement_context.gd`, `movement_data.gd`, `wall_sensor.gd`, `ledge_sensor.gd` y `states/` pasan a `entities/player/movement/`.
  - **Lo que muestra el cuerpo:** `body_crouch.gd`, `body_facing.gd`, `dash_jump_cue.gd` y `speed_trail.gd` pasan a `entities/player/feedback/`.
  - **Líneas de velocidad:** el shader pasa de `vfx/shaders/` a `vfx/speed_lines/`, junto a su escena. En `vfx/shaders/` quedan solo los shaders compartidos.
  - **Tests:** se movieron igual, porque replican las rutas.
  - **Rutas antiguas:** las entradas anteriores de este documento citan las de entonces.
  - **Mapa:** nuevo `docs/MAPA.md`, con para qué sirve cada carpeta y sistema, las señales del `EventBus`, las capas de física y recetas para añadir contenido. CLAUDE.md lo enlaza y pide actualizarlo al crear, mover o quitar un sistema.
- **Por qué:** el diseñador pidió ordenar los archivos y dejar escrita la intención de cada cosa. En `entities/player/` había doce scripts sueltos de tres temas distintos.

## 2026-11-16 · Director de oleadas, prueba de estrés y rendimiento del enjambre
- **Decisión:**
  - **Oleadas:**
    - `WaveData` (`data/waves/test_gym.tres`) lleva:
      - una curva de enemigos por segundo según los minutos (0,6 al empezar, 1,5 a los 2 min, 3,5 a los 5, 7 a los 10 y 12 a los 20);
      - un pico ×3 los últimos 10 s de cada minuto;
      - 250 enemigos a la vez como mucho;
      - aparición a 16–24 m;
      - `WaveEnemy` con peso y minuto de entrada.
    - `WaveDirector` acumula la fracción de enemigos de cada tick y los saca en el suelo (un rayo hacia abajo por intento, en un punto al azar del flujo `WAVES`). En el máximo no acumula.
    - En la zona de práctica, la **campana** (`WaveBell`) arranca o para el director; parar retira a los enemigos. Al volver por la plataforma, las oleadas paran.
    - El `Interactor` vuelve a avisar si el texto del interactuable enfocado cambia (la campana).
  - **Prueba de estrés** (`levels/stress/stress_test.tscn`):
    - Mantiene 300 y luego 500 esbirros sobre un jugador quieto, inmortal y con la espada.
    - Calienta 5 s y mide 8 s por fase, sin V-Sync y con semilla fija.
    - Escribe la media por frame, el 1 % más lento y el tiempo de física, y sale.
  - **Rendimiento:** la primera medición dio 300 enemigos a 22 fps y 500 a 7 fps (con ventana). Un banco headless mostró que el cuello de botella era el bucle del enjambre en GDScript: 14 ms por tick con 300; Jolt, unos 6 ms. Cambios:
    1. `SpatialHash` sin diccionarios: se reconstruye cada tick ordenando por celdas en arrays empaquetados. Con marcas por elemento, tope de resultados, exclusión por índice y celdas que crecen si todo está muy disperso.
    2. Una sola consulta de vecinos por enemigo; los apoyados para trepar van marcados, sin un segundo hash.
    3. Como mucho 8 vecinos por enemigo (`max_neighbors`).
    4. El rumbo de cada enemigo se recalcula cada 3 ticks (`steering_slices`), repartidos, con el delta multiplicado.
    5. `HitboxComponent` apunta con `area_entered`/`area_exited` lo que toca y solo se procesa mientras toca algo. Su reloj de golpes repetidos son los ticks de física del motor.
    6. `HealthComponent` solo se procesa si regenera.
    - El bucle pasó a 3 ms con 300 y 5 ms con 500.
    - Bajar las iteraciones del solver de Jolt en caliente no cambió nada medible, así que no se toca la configuración de física.
  - **Medición tras los cambios** (RX 6800 XT, con ventana):
    - **300 enemigos:** 7,7 ms por frame (130 fps); el 1 % más lento, 17,9 ms; física, 10 ms por frame.
    - **500 enemigos:** 17,5 ms por frame (57 fps); el 1 % más lento, 34,8 ms; física, 15,3 ms.
  - **Queda para cuando haga falta:** dibujar los enemigos con `MultiMesh`, menos ticks de steering y ajustar Jolt.
- **Por qué:** el ROADMAP pide el director con la curva en datos y una escena de estrés con fps medidos, y CLAUDE.md pide 60 fps con 300+ enemigos. Medir antes de optimizar señaló el bucle en GDScript, no el render ni la física.

## 2026-11-16 · Experiencia: gemas, recogida y niveles
- **Decisión:**
  - **Botín:**
    - `LootDropper` escucha `EventBus.enemy_died`, que ahora pasa el propio enemigo para leer sus stats ya resueltas, y suelta una gema con su `xp_reward` (stat nueva de `EnemyStats`; el esbirro da 1).
    - Las fichas, los cofres y las probabilidades de botín irán en el mismo sitio.
  - **Recogibles:**
    - `PickupData` (`data/pickups/xp_gem.tres`) lleva su escena, su recompensa (`experience`) y su vuelo: empieza a 4 m/s, acelera a 40 m/s², se recoge a 0,6 m y vuela al pecho.
    - `PickupField` los deja en el suelo (un rayo), con un pool por tipo. Los mueve en un único bucle, sin física: entran en vuelo cuando quien recoge está dentro de su `pickup_range` (3 m) y ya no se sueltan. Al llegar avisa por `EventBus.pickup_collected(reward, amount)`.
    - El giro y el balanceo de la gema van en su shader, con un desfase por posición, para que cientos no cuesten un `_process` cada uno.
  - **Niveles:**
    - `ExperienceComponent` (en el jugador) suma lo recogido de su recompensa × `xp_gain` y sube de nivel con la curva de `ExperienceData` (`data/progression/experience.tres`). Puede subir varios de golpe y pasa lo que sobra; nivel máximo 100.
    - Curva de partida, experiencia para pasar de nivel: 5 en el nivel 1, 15 en el 5, 30 en el 10, 70 en el 20, 250 en el 50 y 700 en el 99.
    - El jugador aleja la cámara con el nivel (`CameraRig.level`, que ya existía) y avisa por `EventBus` (`player_xp_changed`, `player_leveled_up`).
  - **HUD:** barra de experiencia a todo lo ancho arriba, con el nivel a la izquierda (color de experiencia `4fb6ff`). El tiempo de partida llegará con la tarea de resultados.
  - **Capa `pickup`:** sigue sin usarse; los recogibles no necesitan física.
- **Por qué:** el ROADMAP pide gemas atraídas por el radio de recogida y niveles con curva en datos. Con un único campo sin física, cientos de gemas apenas cuestan, y la recompensa como nombre deja añadir fichas o curas sin tocar el campo.

## 2026-11-16 · Runas y base común de objetos
- **Decisión:**
  - **Base común:** `ItemData` (abstracta, `systems/upgrades/`) es la base de lo que el jugador lleva y sube de nivel. `WeaponData` pasa a heredar de ella; sus `.tres` no cambian.
  - **Runas** (`RuneData`, `data/runes/`):
    - un `StatModifierSet` por nivel, acumulativos, sobre las stats del jugador;
    - el nivel máximo es cuántos conjuntos haya;
    - si todos los niveles dan lo mismo, el `.tres` repite el mismo conjunto.
  - **`RuneInventory`** (nodo `Runes` del jugador) aplica los niveles 1..n con el conjunto de cada nivel como origen y los quita al bajar o quitar la runa.
  - **Las cinco iniciales:**

    | Runa | Por nivel | Nivel máximo |
    |---|---|---|
    | Fuerza | +10 % de daño | 5 |
    | Amplitud | +10 % de área | 5 |
    | Prisa | +8 % de velocidad de ataque | 5 |
    | Vigor | +20 de vida máxima | 5 |
    | Multiplicidad | +1 proyectil | 3 |

    Multiplicidad se queda en 3 porque cinco tajos extra harían la espada desmedida; está en datos.
  - **Armería de práctica:** muestra armas y runas en dos secciones con la misma fila (`ArmoryRow` trabaja con `ItemData`). Para una runa, el panel de la derecha muestra todas las stats del jugador, con lo que cambian sus runas resaltado.
  - **Orden del ROADMAP:** las runas se hicieron antes que «Subir de nivel», para que la elección de 1 de 3 tenga opciones.
- **Por qué:** el GDD define las runas como pasivas que suben stats principales con cada nivel. Con modificadores en datos, añadir una runa es un `.tres`, y la base común deja tratar igual a armas y runas en la elección, el Archivo y la armería.

## 2026-11-16 · Subir de nivel: elegir 1 de 3
- **Decisión:**
  - **Datos:** `LevelUpData` (`data/progression/level_up.tres`): 3 opciones, 4 ranuras de armas y 4 de runas, y las carpetas de las que salen (más adelante, solo lo desbloqueado).
  - **Qué se ofrece** (`LevelUpOffer`, lógica pura):
    - lo que ya lleva y no está al máximo, un nivel más;
    - lo nuevo, solo si queda ranura de su tipo;
    - opciones distintas, todas con el mismo peso por ahora (las rarezas son del Hito 4).
    - El azar es el del flujo `GAMBLE`, reproducible con semilla.
  - **Flujo** (`LevelUpController`):
    - escucha `player_leveled_up` y cuenta las elecciones pendientes; si se suben varios niveles de golpe, elección tras elección (la siguiente se abre diferida, fuera de la señal de la carta pulsada);
    - si no queda nada que ofrecer, no pregunta;
    - aplica la elegida: añadir el arma o subirla, o poner la runa a su nivel.
  - **Interfaz** (`LevelUpPanel`):
    - pausa, pide el cursor y muestra una carta por opción: tipo, nombre, «Nuevo» o «Nv. a → b», descripción y lo que mejora (`ModifierFormat`, p. ej. «+10 % Daño»);
    - Esc no la salta: si abriera la pausa, al cerrarla el juego seguiría con las cartas delante.
  - **`ItemData`** gana `kind_key()` y `level_modifiers(level)` para describir cualquier objeto igual.
- **Por qué:** el GDD pide elegir 1 de 3 entre armas y runas nuevas o mejorarlas, con 4 ranuras de cada y nivel máximo 5. La ruleta, el reroll y el doble o nada del Hito 4 se montan encima de esta elección y del mismo flujo de azar.

## 2026-11-16 · Bastón de mago, daga y proyectiles
- **Decisión:**
  - **Proyectiles:**
    - `ProjectileWeapon` (base de las armas que disparan) saca un `Projectile` de un pool por golpe, desde `aim_height` hacia el centro de la hurtbox del objetivo.
    - El `Projectile` vuela recto y en cada tick traza un rayo del tramo que recorre (capas `enemy_hurtbox` y `world`). Así no atraviesa nada aunque vaya a 30 m/s ni necesita un `Area3D` por bala.
    - Golpea con el mismo `DamageCalc` y la misma hurtbox que las hitbox, y su vida es la duración del arma.
  - **Stats:** `ProjectileStats` añade la velocidad de proyectil (la multiplica la del personaje). `StaffStats` añade `explosion_radius`; `DaggerStats`, `bounces` y `bounce_range`. Todos son stats mejorables.
  - **Bastón** (`data/weapons/staff.tres`):
    - El orbe va a 12 m/s y explota al tocar a un enemigo o una pared. Hace 18 de daño a todos los que hay a 2 m × área, cada uno con su tirada de crítico.
    - La explosión es una esfera con shader de 0,3 s.
    - Cada 1,5 s. Mejoras por nivel: +6 daño, +0,5 m de radio, +1 orbe, y +10 daño con −20 % de espera.
  - **Daga** (`data/weapons/dagger.tres`):
    - Va a 30 m/s y hace 12 de daño a uno solo.
    - Si le quedan rebotes, salta al enemigo más cercano que aún no haya tocado, a menos de 6 m, con todo su daño.
    - Cada 0,8 s. Mejoras por nivel: +1 rebote, +5 daño, +1 daga, y +1 rebote con −20 % de espera.
    - Las mejoras de rebote son fijas por nivel. La «probabilidad de mejorar el rebote» que pidió el diseñador llegará con las rarezas y la ruleta del Hito 4.
  - **Armería y subir de nivel:** las dos armas aparecen solas, porque salen de `data/weapons/`.
- **Por qué:** el GDD define el bastón (explosión en área al contacto) y la daga (rápida, a un objetivo, con rebote). Con el rayo por tick y el pool, cientos de proyectiles salen baratos y precisos, y un arma nueva de proyectiles solo necesita su escena de proyectil.

## 2026-11-16 · Tirador a distancia y armas de enemigos
- **Decisión:**
  - **Los enemigos llevan armas como el jugador:**
    - `EnemyData.weapons` es una lista de `WeaponData`. El enemigo crea su `WeaponInventory` al prepararse, con sus propias stats como las de quien la lleva.
    - Sin `OffenseData`, el arma usa solo las suyas (`StatsComponent.find_resolved`, que no da error si falta). Un élite podrá llevar `OffenseData` para pegar más fuerte.
    - La escena del arma dice a quién busca (`target_mask = player_hurtbox`) y la del proyectil a quién da (`hit_mask = world + player_hurtbox`). Los disparos de enemigos atraviesan a los otros enemigos.
    - Las armas de enemigos viven en `data/enemies/weapons/`, una subcarpeta que no leen la armería ni la subida de nivel. Un test lo comprueba y exige que solo apunten al jugador.
  - **Ciclo del arma:**
    - `Weapon.disarm()` para el arma y corta el ataque a medias. `rearm(espera)` la vuelve a poner en marcha. El enemigo la desarma al morir.
    - Al aparecer, el enemigo espera entre 0,5 y 1 vez la cadencia del arma (`first_attack_delay`, al azar). Así no dispara nada más salir y los que salen juntos no van sincronizados.
  - **Proyectiles de enemigos** (lo pidió el diseñador al probarlo):
    - **Siguen volando aunque muera el tirador.** Por eso no viven en el arma, que se apaga con el enemigo, sino en un `ProjectilePool` compartido del `EnemySwarm`, que el enemigo reparte a sus armas (`ProjectileWeapon.shared_pool`).
    - **Máximo a la vez:** `EnemySwarm.projectile_limit`, 80. Con el máximo alcanzado, los disparos nuevos no salen; los que ya vuelan no desaparecen de golpe.
    - Desaparecen al chocar con el mundo (suelo, paredes) y tras una distancia larga: viven 4 s a 11 m/s, unos 44 m. Atraviesan a los enemigos.
    - Las armas del jugador siguen con su propio pool. Al desarmarlas, sus proyectiles desaparecen.
  - **Búsqueda espaciada:** sin objetivo, un arma vuelve a buscar cada `search_interval` en vez de en cada tick: 0,25 s en el tirador y 0 (cada tick) en las del jugador. Con decenas de tiradores fuera de alcance se ahorran consultas de física.
  - **Guardar la distancia:**
    - `EnemyStats.keep_distance` (0 = va hasta el objetivo). Con ella, `EnemySteering.keep_range` se acerca si está lejos, se aleja si está cerca y frena en ±2 m (`RANGE_FADE`) para no temblar en el borde.
    - Mantiene su desvío de aproximación, así que se reparten alrededor, y mira siempre al objetivo, también al retroceder.
    - Con `climb_speed` 0 ya no trepa nunca. Antes, un enemigo atascado mientras caía se quedaba flotando.
  - **El tirador:**

    | Qué | Valores |
    |---|---|
    | Datos | `data/enemies/shooter.tres` |
    | Vida y movimiento | 20 de vida, 4 m/s, no trepa |
    | Distancia | se queda a 11 m |
    | Contacto | 4 de daño |
    | Experiencia | suelta 2 |
    | Arma | `shooter_gun`: bola de fuego de 10 de daño cada 2,5 s, a 11 m/s, alcance 18 m, vida 4 s (unos 44 m) |

    - Su bola va lenta y apunta adonde estás al disparar, sin adelantarse: quieto te da y moviéndote la esquivas. Seis tiradores matan en unos 6 s a un jugador quieto.
    - Aspecto: cuerpo azul, un ojo naranja y visera. La bola es naranja con halo.
  - **Oleadas:** el tirador sale desde el minuto 0,5 con peso 0,12 frente al 1 del esbirro (uno de cada nueve, más o menos).
  - **Zona de combate:**
    - Hay un invocador por tipo (`CombatRange.summoners`). El cartel de cada invocador muestra el nombre de su enemigo.
    - El de tiradores saca 6 a 14 m.
    - Se borró la clave `SUMMONER_TITLE`, que quedó sin uso.
- **Por qué:** el GDD pide un tirador que obligue a moverse. Reutilizar `Weapon` y `Projectile` evita un segundo sistema de disparo. Además, cualquier enemigo (un élite, un jefe) puede llevar cualquier arma con solo datos.

## 2026-11-16 · Oro
- **Decisión:**
  - **Las «fichas» del GDD pasan a ser oro.** El diseñador pidió oro, y así se cierra una de las adaptaciones medievales pendientes (§11). El GDD, el MAPA y la traducción de `currency_gain` («Oro ganado») ya lo llaman así. El resto de nombres de casino siguen pendientes.
  - **Se cobra solo al matar:**
    - Cada enemigo suelta una moneda con su `EnemyStats.gold_reward`: 1 el esbirro, 2 el tirador.
    - La moneda (`data/pickups/gold_coin.tres`) es `auto_collect`: vuela hacia el jugador nada más salir, esté donde esté, sin tener que pasar por encima ni depender del radio de recogida. Arranca a 3 m/s y acelera a 60 m/s²: unos 0,8 s desde 20 m.
    - Es una moneda dorada de pie que gira (en el shader, como la gema).
  - **`WalletComponent`** (nodo `Wallet` del jugador): suma el oro × `currency_gain` y avisa por `EventBus.player_gold_changed`. Ya tiene `spend()` para los cofres, el reroll y las tragaperras del Hito 4. Guarda decimales, porque el multiplicador los da, y el HUD muestra el entero.
  - **HUD:** `GoldCounter` va debajo de la barra de experiencia, con una moneda dibujada (`CoinIcon`) y la cantidad en dorado.
- **Por qué:** el diseñador quiere el oro sin recogerlo a mano, solo matando. Reutiliza el `PickupField` (pool, vuelo y aviso por el `EventBus`), así que la moneda se ve llegar sin un sistema nuevo.

## 2026-11-16 · Gemas de experiencia por niveles
- **Decisión:**
  - **Fundirse:**
    - Cada 0,5 s (`PickupField.merge_interval`), las gemas que esperan en el suelo se agrupan por zonas de 2,5 m de lado (`PickupData.merge_radius`).
    - Si en una zona hay 5 o más (`merge_count`), la de más valor se queda con la suma y las demás vuelven al pool.
    - Las que ya vuelan hacia el jugador no se tocan.
    - Las zonas se desplazan media zona en pasadas alternas, para que un grupo partido por un borde se junte en la siguiente.
    - Es una rejilla por pasada: O(n), sin física ni comparar todas con todas.
  - **Niveles por valor:**
    - `PickupTier` guarda desde qué valor se usa, el color y el tamaño. Vive en `PickupData.tiers`.
    - La gema: azul ×1, verde desde 5 (×1,25), roja desde 25 (×1,5) y morada desde 100 (×1,8).
    - El color es un parámetro de instancia del shader (`instance uniform`): miles de gemas siguen compartiendo un único material.
  - **El oro no se funde:** vuela nada más salir.
- **Por qué:** el diseñador notó demasiadas gemas en pantalla. Fundirlas reduce nodos visibles y ruido, y una gema grande de otro color se lee como un premio que merece ir a buscar. Todo en datos, así que otro recogible puede tener niveles sin código.

## 2026-11-16 · Élites
- **Decisión:**
  - **Cualquier enemigo puede salir élite.** Quien lo saca lo decide:
    - El `WaveDirector` tira por cada enemigo con `WaveData.elite_chance`, una curva de probabilidad (%) según los minutos. En el gimnasio va del 1 % al empezar al 6 % a los 10 min y al 12 % a los 20; se reajustará con la dificultad.
    - El invocador de élites de la zona de práctica saca 4 esbirros élite.
  - **`EliteData`** (`data/enemies/elite.tres`):

    | Qué | Élite |
    |---|---|
    | Vida | ×5 |
    | Daño al tocar | ×1,5 |
    | Daño de sus armas | ×1,5 |
    | Experiencia y oro que suelta | ×5 (un esbirro élite suelta una gema verde) |
    | Radio de separación | ×1,6 |
    | Tamaño | ×1,6 |
    | Brillo | borde dorado que late |

  - **Mejoras de una vida:**
    - `Enemy.boost(StatModifierSet)` reparte cada modificador a la stat que lo tenga, sea del enemigo (`max_health`, `contact_damage`, `xp_reward`…) o de sus armas (`damage`).
    - `Enemy.promote(EliteData)` usa `boost` y además le cambia tamaño y brillo.
    - Al volver a salir del pool (`spawn`), se quitan todas: el mismo nodo sirve de normal o de élite.
    - El escalado de la dificultad usará el mismo `boost`.
  - **Tamaño:**
    - El cuerpo de un `RigidBody3D` no se puede escalar, porque la física le quita la escala. Por eso se escalan las formas de colisión (cuerpo, hurtbox y contacto), el modelo y los marcadores (los números de daño salen sobre su cabeza), incluida su posición, para que sigan apoyadas en el suelo.
    - La masa sube al cubo del tamaño: un élite empuja a los pequeños y no al revés.
  - **Brillo:** `elite_glow.gdshader`, un borde de luz aditivo que late, puesto como `material_overlay` en las mallas del modelo. No hace falta un material por enemigo.
- **Por qué:** el diseñador pidió un % de élites más grandes, que peguen más y suelten más experiencia. Hacerlo con modificadores de stats deja cualquier combinación en datos. Los afijos y el cofre del GDD (Hito 7) se montarán encima de `EliteData`.

## 2026-11-16 · Dificultad: ronda normal de 10 minutos
- **Decisión:**
  - **Por qué se reajusta:** el diseñador notó que el escalado iba muy rápido, tanto del jugador como de los enemigos. Una ronda normal debe durar como mucho 10 minutos, y a partir de ahí deben salir enemigos muy fuertes que exijan una buena build para aguantar un poco.
  - **`WaveData` es la dificultad de una ronda.** `data/waves/test_gym.tres` es la normal; otras dificultades serán otros `.tres`. Añade:
    - **`round_minutes`** (10): la duración de la ronda. Pasada, es la **prórroga**: las curvas se disparan y el reloj del HUD se pone en rojo. Cuando exista el jefe (Hito 8), saldrá aquí.
    - **`stat_scaling`**: lista de `StatScaling` (una stat y una curva de multiplicador según los minutos). El `WaveDirector` saca cada enemigo con los multiplicadores de su minuto (`Enemy.boost`, como los élites). Sirve para cualquier stat de enemigo o de sus armas: un test lo exige.
  - **Curvas de la ronda normal:**

    | Minuto | Enemigos por segundo | Vida × | Daño × (contacto y armas) | Élites |
    |---|---|---|---|---|
    | 0 | 0,8 | 1 | 1 | 1 % |
    | 5 | 2,5 | 2,2 | 1,3 | 3 % |
    | 10 | 5 | 5 | 1,7 | 5 % |
    | 11 | 8 | 12 | 3 | 15 % |
    | 13 | 10 | 30 | 6 | 30 % |
    | 15 | 12 | 60 | 10 | 33 % |

    - Los picos de cada minuto pasan de ×3 a ×2,5.
    - Antes, el ritmo llegaba a 7 por segundo en el minuto 10 y los enemigos no se hacían más fuertes.
  - **Experiencia del jugador:**
    - Cada nivel pide 5 más que el anterior (6 para pasar del 1 al 2, 51 del 10 al 11, 151 del 30 al 31).
    - Antes subía más despacio: pedía 30 en el nivel 10 y 70 en el 20.
  - **Simulación** (script de prueba con los datos, matando el 90 %; un tirador vale 2 y un élite ×5):

    | Minuto | 1 | 3 | 6 | 8 | 10 |
    |---|---|---|---|---|---|
    | Nivel | 5 | 11 | 19 | 25 | 30 |

    Una build completa (4 armas y 4 runas al máximo) son unas 40 elecciones. Al minuto 10 vas a tres cuartos, así que lo que elijas importa.
  - **Reloj de la ronda** (`RunClock`, arriba en el centro, minutos:segundos):
    - El `WaveDirector` lo avisa cada segundo por `EventBus.run_clock_changed`. Con segundos negativos, no hay ronda y se oculta.
    - En la prórroga se pone rojo.
    - Se adelanta de la tarea «Muerte, resultados y reinicio», porque es lo que deja ver la dificultad.
- **Por qué:** todo vive en curvas de datos, así que las dificultades y los ajustes de playtest son cambiar puntos de una curva. El escalado reutiliza el mismo `boost` que los élites, sin un sistema nuevo.

## 2026-11-16 · Muerte, resultados y reinicio rápido
- **Decisión:**
  - **`RunRecorder`** (`systems/run/`, en el nivel):
    - Apunta la partida en un `RunStats` escuchando el `EventBus`: enemigos derrotados (`enemy_died`), cuántos eran élites, daño infligido (`enemy_damaged`), oro ganado y nivel.
    - El oro cuenta lo ganado aunque luego se gaste: suma solo las subidas de `player_gold_changed`.
    - El tiempo es el del reloj de la ronda (`run_clock_changed`); sin ronda en marcha, el que lleva el nivel.
    - Al morir el jugador deja de apuntar. Lo que llega después (la moneda que aún volaba) no cuenta.
  - **`ResultsPanel`** (`ui/menus/results/`):
    - Al morir el jugador espera 1 s (`delay`, para verle caer), pausa, pide el cursor y muestra «Has caído» con tiempo, nivel, enemigos y élites derrotados, oro ganado y daño infligido.
    - «Reintentar» tiene el foco: Enter o Espacio también lo pulsan. Lleva escrita su tecla, que sale del InputMap.
    - «Salir» cierra el juego, como en la pausa, hasta que exista el menú principal (Hito 3). Esc no cierra los resultados.
  - **Reinicio rápido:**
    - Acción nueva `retry` (R, tecla física), solo en los resultados.
    - Recarga el nivel (`reload_current_scene`): unos 0,2 s en el gimnasio, muy por debajo de los 2 s del GDD.
    - Cuando exista el flujo de partida (Hito 3), pasará por `RunState` con semilla nueva.
  - **Muerto, no se sube de nivel:** el `LevelUpController` ignora las subidas de un jugador muerto. Si no, las gemas que aún volaban abrirían las cartas encima de los resultados.
- **Por qué:** el GDD pide reinicio instantáneo («una más») y ver cómo te ha ido. Apuntar con un nodo que solo escucha deja los resultados desacoplados del gameplay, y servirá para el bote, el Archivo y el resumen de partida del Hito 8.

## 2026-11-16 · Frases de muerte
- **Decisión:** en los resultados, en vez de «Has caído», sale al azar una frase de muerte gamer (flujo `COSMETIC` de `Rng`). Las frases las propuso el diseñador:
  - «GG bro»
  - «Just git gud»
  - «¿Skill issue?»
  - «El 99 % se rinde justo antes de conseguirlo»
  - «A la próxima inténtalo al menos»
  - «Mi primo pequeño lo haría mejor»
  - «Has muerto»
- **Cómo se añaden:** son claves `DEATH_LINE_*` en la lista `death_lines` de `results_panel.tscn`. Una frase nueva es su clave en la lista y su traducción; un test exige que todas estén traducidas. El título se parte en varias líneas si no cabe (hasta 900 px de ancho).
- **Por qué:** da personalidad a la muerte, que se va a ver muchas veces («una más»).

## 2026-11-16 · Personajes iniciales: Guerrero, Mago y Pícaro
- **Decisión** (propuesta aprobada por el diseñador; el Pícaro, con sus cambios):

  | | Guerrero | Mago | Pícaro |
  |---|---|---|---|
  | Arma inicial | Espada | Bastón | Daga |
  | Stats | +30 vida, +5 defensa, −5 % velocidad (carrera y sprint) | −20 vida, +15 % área, +10 % experiencia | −10 vida, +10 % velocidad, +10 % crítico, +1 carga de stamina |
  | Movimiento | `dash_duration` +30 % (dash más largo) | Planea: `glide_fall_speed` 3 m/s | `air_jumps` +1 |
  | Pasiva | Aguante: +2 % de daño por enemigo a ≤ 5 m, hasta 15 (+30 %), contado cada 0,25 s | Eco arcano: cada 4.º ataque de cada arma suma tantos golpes como tiene | Letal: +1 % de crítico por nivel |

  - **El Pícaro:** el diseñador pidió más stamina y que la pasiva fuera de crítico, en lugar de «golpe bajo tras el dash».
  - **`CharacterData`** añade color, arma inicial, pasiva (escena) y los textos de la pasiva. Las diferencias siguen siendo la base de las stats.
  - **Pasivas:**
    - `CharacterPassive` es un nodo que el jugador añade al elegir el personaje. Sus modificadores llevan la pasiva como fuente y se quitan al irse.
    - Los números viven en la escena de cada pasiva (`entities/player/characters/passives/`).
    - El Eco arcano usa dos cosas nuevas del arma: la señal `attack_started` y `add_shots()`.
  - **Planeo:** `MovementData.glide_fall_speed` (0 = no planea) limita la caída mientras se mantiene el salto (`MovementContext.jump_held`). Es una stat: una mejora podría dar planeo a cualquiera.
  - **Elegir personaje:**
    - `Player.set_character()` cambia base, arma inicial y pasiva en el momento, con la vida llena.
    - `RunState.character` guarda la elección: reintentar sigue con el mismo personaje.
    - Sin elección, el jugador usa su `character`. En el gimnasio es el Guerrero; la escena del jugador sola va sin personaje, para que los tests no hereden armas.
    - En la zona de combate hay tres pedestales (`CharacterPedestal`) con la figura y el color de cada uno.
  - **Se borra `data/characters/base.tres`:** ya no tiene sentido; la base son las stats de `data/player/`.
- **Por qué:** cierra la decisión abierta del GDD (§11). Todo va en datos y escenas: un personaje nuevo es un `.tres`, y una pasiva nueva, un script corto con su escena.

## 2026-11-16 · Cierre del Hito 2: prueba de estrés
- **Medición** (`levels/stress/stress_test.tscn`, RX 6800 XT; dos pasadas de cada uno, el mismo día y en las mismas condiciones):

  | | 300 enemigos | 500 enemigos |
  |---|---|---|
  | `main` (antes de las ramas del Hito 2) | 9,0 ms (111 fps), física 10,8 ms | 16,7–18,3 ms (55–60 fps), física 15,2–15,6 ms |
  | Con todo el Hito 2 | 8,6–9,7 ms (103–117 fps), física 10,8–11,6 ms | 17,2–18,6 ms (54–58 fps), física 15,8–16,6 ms |

- **Lectura:** sin pérdida apreciable; la diferencia entre pasadas (±10 %) es mayor que entre versiones. Los 130 fps de la primera medición salieron con el equipo en otro estado, así que solo vale comparar mediciones del mismo día.
- **Ajuste:** un enemigo que vuelve del pool solo rehace formas y materiales si fue élite. Así no se reescriben las formas de colisión en cada aparición.

## 2026-11-17 · Aspecto de los personajes, ranuras de armas y runas, y opciones
- **Aspecto:** cada personaje lleva su color y sus piezas en un `CharacterModel` común: cuerpo, manos y puntos de anclaje (manos, cabeza, espalda). Las piezas se listan en `CharacterData.attachments` (`ModelAttachment`: escena, punto y colocación).
  - Las piezas (espada, escudo, bastón, sombrero, daga) son assets propios hechos con mallas básicas de Godot, en `assets/models/props/`, para poder reutilizarlas.
  - Hasta tener modelos de verdad, un personaje nuevo solo necesita datos.
- **Ranuras:**
  - Hay 4 de armas y 4 de runas (`LevelUpData.max_*_slots`), pero al empezar solo hay 2 abiertas de cada tipo.
  - Las abiertas son stats del jugador (`weapon_slots`, `rune_slots`, en `ProgressionData`): desbloquear una será un modificador +1, venga de donde venga (meta, mejora, personaje). Nunca pasan de las que hay.
  - El HUD muestra las cerradas con un candado.
- **Iconos:** armas y runas tienen `icon` (SVG propios en `assets/textures/icons/`). Se usan en el HUD y en las cartas.
- **Opciones:**
  - Las guarda el autoload `Save` (ya previsto en `CLAUDE.md`) en `user://settings.cfg` con `ConfigFile`. No se usa un `.tres`: cargar recursos de `user://` puede ejecutar código.
  - Los buses son Master, Music y Effects (`default_bus_layout.tres`).
  - Mientras no se elija un tamaño, la ventana se queda como diga el proyecto: no se cambia ningún Project Setting.
  - En headless no se toca la ventana, así que los tests y la validación no la mueven.
- **Por qué:** lo pidió el diseñador, y todo queda en datos. Las opciones adelantan una parte del Hito 8. La sensibilidad y el remapeo siguen allí.

## 2026-11-17 · Opciones: «Aplicar» y el juego dentro del editor
- **Problema:** el diseñador probaba desde el editor, que ejecuta el juego incrustado en la pestaña «Juego». Ahí la ventana es del editor: Godot rechaza la pantalla completa y el cambio de tamaño («Embedded window only supports Windowed mode»), así que esas opciones no hacían nada.
- **Decisión:**
  - Con `Engine.is_embedded_in_editor()` (`GameSettings.can_change_window()`), dentro del editor se aplica solo el VSync. El panel avisa y desactiva pantalla completa y resolución.
  - Para probarlas hay que ejecutar el juego en su propia ventana.
  - Las opciones de pantalla esperan a «Aplicar», que las aplica y las guarda. El volumen sigue al momento, para oírlo mientras se ajusta.
  - «Volver» descarta lo de pantalla que no se aplicó.
  - Solo se ofrecen tamaños que caben en el área útil de la pantalla, sin la barra de tareas.
- **Por qué:** lo pidió el diseñador («falta botón de aplicar»). Además, cambiar la ventana al tocar cada control es incómodo y arriesgado; con «Aplicar», el cambio se hace una vez, cuando se decide.

## 2026-11-17 · Flujo de partida, `RunSystems` y el Brosque v1
- **`Game`** es la escena principal y lleva el flujo: menú → nivel → menú. Cada pantalla sustituye a la anterior.
  - Reintentar y volver al menú se piden por el `EventBus` (`RunFlow`). Así cada nivel se sigue pudiendo ejecutar solo (F6): sin `Game` que escuche, recarga la escena o cierra el juego.
  - `validate.sh` arranca además cada nivel, porque la escena principal ya no entra en partida.
- **`RunSystems`:** los sistemas de una partida (jugador, horda, oleadas, botín, subir de nivel, HUD, pausa, resultados, depuración) salen del gimnasio a una escena común. El gimnasio y el Brosque la instancian con sus oleadas, su personaje de serie y su punto de aparición. Se extrajo al segundo nivel, para no copiarlos.
- **Bosque con MultiMesh:** los ~300 árboles se dibujan con cinco MultiMesh (tronco y copas) y chocan con un solo cuerpo con un cilindro por tronco. Así cuesta pocas llamadas de dibujo, que hacen falta para la horda.
  - Lo generaba `tools/gen_brosque_forest.gd` con semilla fija (sustituido: ahora el mapa entero se genera al cargar; ver «Mapa procedural»).
  - Hay que generarlo con ventana: en headless el render es ficticio y el MultiMesh se guarda sin transformaciones.
  - Los colores por árbol necesitan `vertex_color_is_srgb` en el material.
- **Diseño acordado** (GDD §6 y §9):
  - Calaveras y bolsitas se rompen al tocarlas.
  - Hay tres tipos de objetos de partida: pasivos de cofre apilables, recogibles del suelo y llaves del jefe.
  - El jefe se invoca en un altar con llaves; al minuto 10 el altar se activa solo.
  - El Brosque es un gimnasio en el bosque.
  - Las tragaperras, las rarezas y los cofres se adelantan al Hito 3 para el Brosque.

## 2026-11-17 · La dificultad es una stat
- **Decisión:**
  - La dificultad es la stat `difficulty` del jugador (`ProgressionData`), con base 0. El `WaveDirector` le suma la parte del tiempo: un modificador de +1 por minuto en marcha, que se actualiza cada segundo y se quita al parar. Objetos y runas podrán sumarle más (FLAT) o multiplicarla (PERCENT).
  - Las curvas de `WaveData` (aparición, élites, escalado de stats y `WaveEnemy.from_difficulty`) van según la dificultad, no según los minutos. Sin bonus, dificultad = minutos, así que el balance de la ronda normal no cambia.
  - Los picos y la duración de la ronda siguen yendo por el reloj.
  - Calaveras y bolsitas dan `amount + amount_per_difficulty × dificultad`.
  - El HUD la muestra con una calavera.
- **Por qué:** el diseñador quiere que la dificultad suba sola y también con objetos y runas, con más riesgo y más recompensa. Al ser una stat, cualquier mejora la toca con el sistema de modificadores de siempre y sale en la pausa. Al medirla en «minutos equivalentes», los datos que ya había siguen valiendo.

## 2026-11-17 · Probabilidad de botín, tablas ponderadas y bebida energética
- **Probabilidad de botín** (`drop_chance`): stat del jugador, 0,5 % de serie (muy baja, como pidió el diseñador). Es la probabilidad de que un enemigo normal suelte un extra. Los élites la multiplican por 8 y los rompibles por 12, según sus datos. Objetos y runas podrán subirla.
- **Qué extra sale** lo decide una `WeightedTable` (`core/`): entradas con peso, y cada uso hereda su tipo de entrada (`BonusDrop`: recogible y valor). Sustituye a las probabilidades sueltas por recogible de la versión anterior. Las tragaperras y los cofres usarán la misma tabla, y la Suerte desplazará sus pesos cuando lleguen las rarezas. Los cofres entrarán en esta misma tirada.
- **Bebida energética:** un `BuffEffect` aplica un `StatModifierSet` de datos (+25 % de carrera y sprint, +30 % de velocidad de ataque y +20 % de daño) durante los segundos que vale el recogible (10). Otra lata reinicia la cuenta en lugar de acumularse, para que no se vuelva imparable.
- **`LootDropper`** lee la dificultad y la probabilidad de botín directamente de las stats del jugador (`player_stats`) en lugar de guardar la última dificultad que avisó el `EventBus`: es más simple, y el `EventBus` queda para el HUD.

## 2026-11-17 · Tragaperras
- **Diseño** (propuesto y aceptado):
  - Cuatro máquinas en el Brosque: una en el claro y tres en las mesetas.
  - Coste: 15 de oro + 5 por punto de dificultad, ×1,5 cada vez que se usa esa misma máquina.
  - Tres rodillos con cuatro símbolos de pesos 4, 3, 2 y 3: moneda, corazón, estrella y calavera.
  - Trío = jackpot, pareja = premio menor, todos distintos = nada. Con esos pesos sale ≈ 7 % de tríos, ≈ 57 % de parejas y ≈ 35 % de nada.
  - No pausa: apostar con la horda encima forma parte del riesgo.
- **Montaje:**
  - Los símbolos son `SlotSymbol` sobre la `WeightedTable`.
  - Los premios (`SlotOutcome`) son recompensas por `pickup_collected`, igual que los recogibles. Así se reutiliza lo que ya había: el monedero cobra el oro (con su `currency_gain`) y los `PickupEffect` aplican la cura y la maldición (otra vez `BuffEffect`).
  - Solo hacen falta dos efectos nuevos: la mejora gratis y la oleada de élites (`WaveDirector.spawn_elites`).
  - El HUD y la cámara lenta se enteran por `slot_spun` y `slot_resolved`.
- **El aviso de «interactuar» lleva el coste:** la máquina pone en su `prompt_key` el texto ya formateado; el `Label` no encuentra la clave y lo muestra tal cual. Así no hubo que tocar el `Interactor`.

## 2026-11-17 · Mejoras con rareza
- **Decisión:**
  - Las subidas de nivel ya no son listas fijas por nivel. Cada una es una `ItemUpgrade` tirada: una `Rarity` (de una `WeightedTable` en `data/rarities/`) elige cuántas stats distintas de las `upgrade_stats` del objeto toca y con qué fuerza.

    | Rareza | Peso | Stats que toca | Fuerza |
    |---|---|---|---|
    | Común | 60 | 1 | ×1 |
    | Rara | 25 | 1–2 | ×1,25 |
    | Improbable | 10 | 2 | ×1,5 |
    | De leyenda | 4 | 2–3 | ×2 |
    | Mítica | 1 | todas | ×2,5 |

  - Nivel máximo: armas 10, runas 20 (`ItemData.level_cap`).
  - Armas y runas guardan su historial de mejoras para poder quitar la última (armería).
  - La armería y las herramientas usan una mejora estándar sin rareza (todas sus stats como una común). Las runas dan esa mejora estándar al conseguirlas.
  - La recarga del arma mejora como multiplicador (×0,92 la común); la rareza escala lo que se aleja de 1. En % se acumularía sumando y podría llegar a 0.
  - Proyectiles y rebotes van en enteros y nunca suman menos de 1.
- **Por qué:** lo pidió el diseñador (colores y que las raras toquen varias cosas). Todo va en datos: un arma nueva solo lista sus stats mejorables, y una rareza nueva es un `.tres`.
- **Pendiente:** con 20 niveles, Multiplicidad (+1 proyectil por mejora) puede quedar muy fuerte; habrá que mirarlo jugando.

## 2026-11-17 · Ritmo algo más lento y enemigos más duros
- **Decisión** (lo pidió el diseñador):
  - Todo se mueve un 15 % más despacio: carrera 9 → 7,6 m/s, sprint 11,5 → 9,8, dash 28 → 24, slide y salto en pared en proporción. Esbirro 6 → 5,1 m/s, tirador 4 → 3,4 y sus bolas 11 → 9,4 m/s (con más duración, para que lleguen igual de lejos).
  - Los enemigos tienen un 50 % más de vida: esbirro 30 → 45, tirador 20 → 30.
  - Salen al mismo ritmo, porque las curvas de aparición no cambian.
- **Además:** cada personaje regenera un poco de vida de base (0,8 / 0,4 / 0,5 por segundo) y el Pícaro da un mortal en el doble salto (`BodyFlip`, solo visual).

## 2026-11-17 · Mapa procedural
- **Decisión:**
  - El Brosque se genera al cargar, con la semilla de la partida (nuevo flujo `LAYOUT` de `Rng`): reintentar da otro mapa y una semilla reproduce el mismo.
  - Un `LevelLayout` reparte las `LayoutPiece` de su `LayoutData`, con círculos de suelo que no se pisan: dos mesetas altas y tres bajas fuera del claro, una tragaperras, ocho pesas y seis bancos. Luego pone tres tragaperras encima de mesetas al azar.
  - `ForestBuilder` hace el bosque alrededor: árboles sueltos que esquivan las piezas, el anillo junto a las paredes con colisión y la banda grande de fuera sin colisión. Todo con MultiMesh, como antes.
  - Las paredes y la zona de los enemigos no cambian. Calaveras y bolsitas se reparten después, sobre lo generado.
  - Se borran `tools/gen_brosque_forest.gd` y `forest.tscn`, que eran el bosque horneado.
- **Por qué:** lo pidió el diseñador, y es más rejugable. Un nivel nuevo solo necesita su `LayoutData` con sus piezas.
- **Coste:** generar 2.600 árboles y 300 colisiones al cargar es instantáneo. En el juego no cambia nada respecto al bosque horneado.

## 2026-11-17 · Suerte
- **Decisión:**
  - Cada entrada de una `WeightedTable` lleva `luck_scaling`: el % de su peso que gana por cada punto de Suerte. Su peso con Suerte es `peso × (1 + Suerte × luck_scaling / 100)`. Con 0 no le afecta.
  - Las rarezas lo llevan creciente: común 0, rara 1, improbable 2, de leyenda 3, mítica 5. Con 100 de Suerte, los pesos 60/25/10/4/1 pasan a 60/50/30/16/6: la común baja del 60 al 37 %, y la mítica sube del 1 al 3,7 %.
  - Usan la Suerte del jugador (`ProgressionData.luck`, 0 de base) las cartas de subir de nivel y las mejoras gratis de la tragaperras. Los power-ups y los símbolos de la tragaperras no escalan, de momento.
- **Por qué:** lo pide el GDD (§5). Va en la tabla genérica para que los cofres y los objetos la usen sin código nuevo. Escala con el peso, y no sumando, para que una entrada de peso 0 siga sin salir nunca.
- **Pendiente:** aún no hay nada que dé Suerte; llegará con los objetos de los cofres.

## 2026-11-17 · Cofres y objetos pasivos
- **Decisión:**
  - **Objetos pasivos:** `PassiveItemData` es un `StatModifierSet` con id, textos, icono y una rareza fija. Viven en `data/items/` y el jugador los lleva en `PassiveInventory`. Cada copia aplica sus modificadores con su propio origen: se apilan y se puede quitar una.
  - **15 objetos de cultura bro** como propuesta inicial, para cambiar en datos. El gimnasio es solo un tema más (lo pidió el diseñador: «cosas de bro en general, no solo gym»):

    | Rareza | Objetos |
    |---|---|
    | Común | batido de proteínas (+10 % vida), pizza fría de ayer (+0,4 vida/s), riñonera (+15 % oro), mando de consola (+8 % vel. ataque) |
    | Rara | gorra hacia atrás (+10 % daño), chanclas con calcetines (+6 % carrera y sprint), rasca y gana (+10 Suerte), altavoz portátil (+12 % área) |
    | Improbable | gafas de sol (+6 % crítico), aceite corporal (+5 % esquiva), cinturón de levantar (+10 defensa) |
    | De leyenda | mancuerna de oro (+1 proyectil), batido sospechoso (+25 % daño y +3 dificultad), cadena de oro (+25 % oro y +10 Suerte) |
    | Mítica | corona del Bro (+15 % daño, vel. ataque, vida y área) |

  - **Cofres:** cuestan `(20 + 4 × dificultad) × 1,3^cofres abiertos` en la partida. Tiran una rareza de la tabla de siempre con la Suerte del jugador y sacan un objeto de esa rareza; si no hay ninguno, uno de la de debajo.
  - El revelado dura 1,6 s en el HUD sin pausar: la luz recorre las cinco rarezas, frena y se para. Después llega el objeto y el cofre desaparece.
  - En el Brosque hay 7: cinco en el suelo y dos encima de las mesetas que no tienen tragaperras.
- **Por qué:** lo pide el GDD (§5.2 y §6) y es la segunda apuesta de la partida. No se usa el robo de vida porque aún no está implementado.
- **Coste:** cada cofre cuenta los abiertos escuchando `chest_opened`. Un cofre que aparezca a mitad de partida (por ejemplo, soltado por un élite) empezaría a contar desde 0: habrá que pasarle la cuenta cuando lleguen.

## 2026-11-17 · Jefe del Brosque: el Ent-renador
- **Decisión:**
  - **El jefe es un enemigo más:** `Boss` hereda de `Enemy` y sale del mismo `EnemySwarm` y su pool. Sus ataques son nodos hijos (`BossAttack`: salto con onda, embestidas, refuerzos), con sus números en `@export` de la escena del jefe. Un jefe nuevo es una escena con sus ataques, un `EnemyData` y un `BossData`; un ataque nuevo es un script que hereda de `BossAttack`.
    - Recalcula su rumbo en cada tick (`Enemy.steer_every_tick`); los demás, cada tres.
    - La bomba no le hace nada (`Enemy.is_boss()`): quita una parte de la vida máxima y mataría al jefe de golpe.
  - **El encuentro** (`BossEncounter`, en `RunSystems`) lleva lo del nivel: cuenta las llaves, saca al jefe, pasa al HUD su vida y sus gritos, pone sus refuerzos por el director (`WaveDirector.spawn_around`, con el escalado del momento) y da la victoria. Cada nivel elige su `BossData` en `RunSystems.boss`, como sus oleadas.
  - **Escalado:** el jefe sale con la dificultad del momento, con sus propias curvas en `BossData`. Vida ×1 con dificultad 0, ×1,6 con 5, ×2,6 con 10, ×5 con 15 y ×9 con 20, sobre una base de 5.000. Daño ×1, ×1,7 y ×3 con 0, 10 y 20. Las curvas de las oleadas se disparan en la prórroga (vida ×12 con 11): con ellas, el jefe del minuto 10 sería imposible.
  - **El altar** es una pieza del mapa generado. Va la primera (siempre cabe), entre 24 y 28 m del centro, al borde del claro, y mirando hacia él: `LayoutPiece.ring` y `face_center`. Ahí la pelea es en terreno abierto. El altar pide el jefe al usarlo y, forzado, al empezar la prórroga: «al minuto 10 el altar se activa solo». El encuentro decide si hay llaves suficientes.
  - **Las llaves** (tarjetas de socio en el Brosque): las reparte un `BreakableScatter`, 5 a más de 25 m del centro (`min_center_distance`) y a 25 m entre sí, para que haya que explorar. Hacen falta 3. Las tarjetas y el altar listo tienen una columna de luz que se ve desde lejos. El shader de la columna pasa a `vfx/shaders/light_beam.gdshader`, porque ahora lo usan tres escenas.
  - **Ataques del Ent-renador** (cada 3,5 s, cada 2,2 s con rabia):
    - **Burpee:** un aro marca adonde salta, hasta 20 m. Al caer, la onda llega a 13 m en 0,9 s con 1,6 × su daño al tocar. Solo daña a lo que está a menos de 1,3 m del suelo de la onda y en su borde: se esquiva saltando o alejándose.
    - **Series:** tres embestidas de 16 m a 20 m/s, con una franja de aviso y 1,5 × daño al tocar mientras embiste.
    - **Bro-tes:** 4 refuerzos, o 6 con rabia.
    - La rabia empieza por debajo del 50 % de su vida: +35 % de velocidad y +20 % de daño al tocar, sin rellenarle la vida.
  - **Premio:** oro × `early_bonus` según los minutos al vencerlo. Es ×3 en el 0, ×2,5 en el 4, ×1,7 en el 7 y ×1 desde el 10, sobre 150 de oro; llega como un recogible y cuenta el % de oro. Además, un objeto de un `ItemPool` solo con improbable, de leyenda y mítica.
    - Lo que sale de un cofre se sacó a `ItemPool` para tirar igual en los dos sitios.
    - El panel del cofre revela cualquier objeto por la señal nueva `item_revealed`; `chest_opened` queda para contar los cofres abiertos.
  - **Victoria:** al caer el jefe paran las oleadas y se retiran los demás enemigos. El jefe termina de caer: `EnemySwarm.clear(keep_dying)`.
    - Llega el premio y se avisa con `boss_defeated`. El `RunRecorder` deja de apuntar y la pantalla de resultados muestra la victoria a los 4 s, para ver caer al jefe y el revelado.
    - Lo primero que pasa, muerte o victoria, manda.
- **Por qué:**
  - Lo pide el GDD (§9) y el diseñador aprobó el Ent-renador.
  - Reutilizar `Enemy` da gratis el pool, el combate, los números de daño, el botín y el Archivo.
  - Los ataques como nodos dejan cada jefe en su escena, sin `if` por jefe.
- **Pendiente:**
  - Los números son una primera propuesta que hay que probar jugando. Lo primero: la vida del jefe frente al daño de una build del minuto 5 al 10.
  - El premio aún no sirve de mucho, porque la partida termina al vencerlo. Pesará cuando lleguen el bote y «¿Cobrar o Doblar?» (Hitos 7 y 8).
  - El salto confía en la física: aterriza cuando deja de caer o, si algo lo frena, pasado el doble de su tiempo en el aire.
  - Los refuerzos no cuentan para el máximo de enemigos a la vez.

## 2026-11-17 · El juego empieza en español
- **Decisión:** el idioma es una opción más (`GameSettings.locale`, guardada en `user://settings.cfg`). Un juego recién estrenado empieza en español (`SettingsData.default_locale = "es"`) aunque el sistema esté en otro idioma, y `Save` lo aplica al arrancar. El inglés sigue traducido.
- **Por qué:** lo pidió el diseñador. Se hace en las opciones y no en `project.godot` para que un selector de idioma futuro solo tenga que cambiar esa opción.

## 2026-11-18 · Equilibrio: menos escalado y personajes más parejos
- **Problema** (del diseñador, jugando): todo escalaba demasiado (armas y mejoras); el Guerrero se disparaba y el Mago y el Pícaro se sentían flojos.
- **Cómo se midió:** una simulación por terminal. Cada personaje, quieto, contra una horda de 104 esbirros inmortales a su alrededor y contra uno solo (un jefe). Al empezar, y con una build de mitad de partida: arma a nivel 10 con mejoras tiradas, Fuerza y Multiplicidad a nivel 8 (o su máximo) y nivel 25. Daño por segundo medio de 6 tiradas:

  | | Horda antes | Horda ahora | Jefe antes | Jefe ahora |
  |---|---|---|---|---|
  | Guerrero | 172 → 12.480 (×72) | 133 → 4.950 (×37) | 20 → 493 | 20 → 328 |
  | Mago | 116 → 4.060 (×35) | 177 → 5.160 (×29) | 14 → 259 | 17 → 239 |
  | Pícaro | 16 → 1.940 (×124) | 69 → 1.840 (×27) | 17 → 529 | 22 → 384 |

  Hacia el minuto 10 los enemigos tienen ×5 de vida y salen ×6 más a menudo (×30 en total): la build ya no los deja tan atrás.
- **Decisión:**
  - **Lo que más multiplicaba eran los proyectiles** (cada uno es un golpe entero más):
    - Multiplicidad llega como mucho a nivel 3 (antes, 20).
    - Al subir un arma, la mejora de proyectiles sale la mitad de veces: `UpgradeStat.weight` = 0,5 (el resto, 1).
  - **Runas por nivel:** Fuerza y Amplitud, +6 % (antes +10 %); Prisa, +5 % (antes +8 %).
  - **Rarezas:** de leyenda ×1,75 (antes ×2) y mítica ×2 (antes ×2,5).
  - **Espada:** mejora de daño +3 (antes +5) y de área +5 % (antes +12 %), porque el área hace el arco más grande y le da enemigos en proporción al cuadrado; tiempo de recarga ×0,95 (antes ×0,92).
  - **Bastón:** daño 26 (antes 18), proyectil a 15 m/s (antes 12), explosión de 2,2 m (antes 2); mejoras de daño +3,5, de radio +10 % y de recarga ×0,94.
  - **Daga:** daño 15 (antes 12), recarga 0,7 s (antes 0,8) y empieza con 2 rebotes; mejoras de daño +2,5 y de recarga ×0,94.
  - **Pasivas** (las pidió así el diseñador): todas suben una stat por nivel, como Letal. Son datos de `LevelStatPassive`:
    - Veterano (Guerrero): +1 % de daño;
    - Expansión arcana (Mago): +1 % de área;
    - Letal (Pícaro): +1 % de crítico.
    - Se quitan Aguante y Eco arcano. Con ellos se van `Weapon.attack_started` y `add_shots`, que solo usaba el Eco.
- **Resultado:** el Guerrero y el Mago son los de la horda (de cerca y en área); el Pícaro, el mejor contra un solo enemigo.
- **Pendiente:** el *feel* lo decide el diseñador jugando. La simulación no se mueve ni recibe daño, y los enemigos están quietos y muy juntos (favorece el área).

## 2026-11-18 · Botín más llamativo
- **Decisión:** los power-ups (comida, imán, bomba y bebida energética) llevan un `DropGlow`: una columna de luz corta y un aro que late en el suelo, del color de cada uno. Las gemas de experiencia laten y destellan en los bordes, y las monedas destellan al ponerse de cara. Todo en shaders, sin `_process`. El aro (`ground_ring.gdshader`) pasa a `vfx/shaders` porque lo usan el jefe y los power-ups.
- **Por qué:** lo pidió el diseñador: entre la horda no se veía lo que soltaban los enemigos. Los power-ups son pocos (pueden llevar mallas propias); las gemas salen a cientos, así que solo cambia su shader.

## 2026-11-18 · Aviso sutil de lo que se puede usar
- **Decisión:** lo que se usa con «interactuar» destella encima de sus mallas (`material_overlay`). Lo hace `InteractHint`, que escucha a su `Interactable`:
  - De siempre, un borde de luz muy suave y una franja que lo recorre de abajo arriba cada 3 s. La franja es un plano algo inclinado que barre el mundo: las piezas de un objeto destellan a la vez y cada objeto, a su momento.
  - El elegido (el más cercano, el que se usaría con E) lleva un borde más marcado y franjas más seguidas: el `Interactor` se lo dice con `Interactable.set_focused`.
  - Al desactivarse (cofre abierto, altar usado), nada.
  - Solo en las mallas: con un texto (`Label3D`) encima se vería un rectángulo.
- **Por qué:** lo pidió el diseñador, algo sutil. Un borde fijo en todo el mapa cansaría la vista; una franja de vez en cuando se nota sin molestar.

## 2026-11-18 · Ruinas en el Brosque
- **Decisión:** tres piezas nuevas de piedra con musgo, repartidas por el mapa generado fuera del claro: un templo de columnas rotas (1), muros caídos (3) y arcos medio derrumbados (2). Tienen colisión; sus bordes, de hasta 2,6 m, se pueden subir con el mantle. Solo mallas básicas y tres materiales (`ruin_stone`, `ruin_stone_dark` y `moss`).
- **Por qué:** lo pidió el diseñador, para que el Brosque parezca más medieval. Como piezas del `LayoutData`, salen en sitios distintos en cada partida y no se pisan con lo demás.

## 2026-11-18 · Ent-renador: las tarjetas justas y menos daño
- **Decisión:** en el Brosque hay exactamente las tarjetas que pide el jefe (3; un test lo exige). El Ent-renador hace menos daño: al tocar, 16 (antes 22); la onda del Burpee, ×1,3 (antes ×1,6); las embestidas, ×1,25 (antes ×1,5).
- **Por qué:** lo pidió el diseñador jugando: sobraban tarjetas y el jefe pegaba demasiado.

## 2026-11-18 · Equilibrio, segunda vuelta: las comunes mejoran poco
- **Corrección del diseñador:** sin topes nuevos (armas hasta 10 y runas hasta 20, también Multiplicidad: se podrán ampliar) y sin cambiar lo a menudo que sale cada mejora. El problema eran las cartas comunes, demasiado buenas.
- **Decisión:**
  - Se deshacen el tope 3 de Multiplicidad y el peso de las mejoras (`UpgradeStat.weight`).
  - La rareza pesa más: la mejora base de cada stat es la de una carta rara, y cada rareza la multiplica así: común ×0,6, rara ×1, improbable ×1,4, de leyenda ×1,8 y mítica ×2,4 (antes 1 / 1,25 / 1,5 / 2 / 2,5).
  - Las mejoras base vuelven a valores parecidos a los originales:
    - Fuerza y Amplitud, +10 %; Prisa, +8 %;
    - espada: +5 de daño, +8 % de área y ×0,92 de recarga;
    - bastón: +5 de daño, +12 % de radio, +15 % de velocidad de proyectil y ×0,92;
    - daga: +4 de daño, +12 % de velocidad de proyectil y ×0,92.
  - Los enteros (proyectiles, rebotes) siguen dando como poco 1.
  - Daño de base: espada 18 (antes 20) y daga 17 (antes 15).
- **Resultado** (`tools/sim_balance.gd`, % de la media en su escenario):

  | | Horda, build | Jefe, build | Media |
  |---|---|---|---|
  | Guerrero | 111 % | 97 % | 104 % |
  | Mago | 132 % | 66 % | 99 % |
  | Pícaro | 57 % | 136 % | 97 % |

  Cada uno tiene su papel: el Mago, la horda; el Pícaro, el jefe; y el Guerrero, bueno en los dos.
- **Para personajes nuevos:** la simulación toma todos los de `data/characters/`. Un personaje nuevo debería quedar cerca del 100 % en la media de los dos escenarios, fuerte en su papel y flojo en el otro. Se pasa al tocar armas, runas, rarezas o personajes.
- **Pendiente:** con Multiplicidad hasta 20, una build que la suba mucho se dispara (cada proyectil es un golpe entero). Si al jugar se nota, el siguiente paso es que la carta común de enteros no siempre dé 1.

## 2026-11-18 · «I-frames» del jugador
- **Decisión:** nueva stat de vida, `invulnerability_time`: tras un golpe que hace daño, no se recibe más durante ese tiempo. El jugador tiene 0,3 s; los enemigos, 0. Se ve: el modelo del jugador parpadea (`InvulnerabilityBlink`).
  - El tiempo se mide con el reloj de la física (`PhysicsClock`, sacado de la hitbox, que ya lo usaba): la vida no necesita `_process`.
  - Un golpe esquivado no da invulnerabilidad.
- **Por qué:** lo pidió el diseñador. Con la horda encima, varios golpes en el mismo instante quitaban la vida de golpe. Es una stat, así que algo podrá mejorarla.

## 2026-11-18 · Los golpes empujan
- **Decisión:** cada golpe (`DamageInfo`) lleva un empuje: una velocidad en el suelo, desde quien golpea hacia quien recibe.
  - **Del jugador:** el de cada arma (`WeaponStats.knockback`: espada 7 m/s, bastón 6, daga 3) por su retroceso % (`OffenseData.knockback`, 100 %, mejorable más adelante). La explosión del bastón empuja hacia fuera desde su centro.
  - **De los enemigos:** fijo, al tocar (`EnemyStats.knockback`: esbirro 4, tirador 3, Bro-te 3, Ent-renador 10; el disparo del tirador, 2). La embestida del Ent-renador empuja ×2 y su onda, 9 m/s hacia fuera.
  - **Al recibirlo**, un enemigo lo suma a su velocidad dividido por su masa: los élites (más pesados) y el jefe (40) se mueven menos. Se suma a la velocidad y no con un impulso de la física, porque el rumbo del enjambre lo pisaría antes de aplicarse.
  - **El jugador** lo recibe en `KnockbackReceiver`: lo suelta sobre el cuerpo y se frena a 40 m/s². Va aparte de la velocidad del movimiento, así que los estados no lo pisan. No le empuja un golpe esquivado.
- **Por qué:** lo pidió el diseñador. El árbol atravesaba al jugador sin moverlo y quedaba raro, y pegar sin empujar se sentía plano.

## 2026-11-18 · Textos breves en el HUD
- **Decisión:** un aviso genérico, `AnnouncementFeed`, en el centro bajo la barra del jefe. Escucha `EventBus.announced` (clave, valores y color): cada texto sale con un pequeño salto, se ve 1,6 s, se desvanece, y se apilan hasta 5. Los power-ups dicen el suyo al recogerlos (`PickupData.announce_key` y `announce_color`, del color de su columna de luz):
  - imán, «¡Succión activada!»;
  - comida, «¡Pollito ñam ñam!»;
  - bomba, «¡Nuclear activada!»;
  - bebida energética, «¡Modo diablo activado!».
- **Por qué:** lo pidió el diseñador. Es genérico porque también lo usan las mejoras de la tragaperras (de su rareza) y lo que venga.

## 2026-11-18 · Mejoras de la tragaperras: elegir y «todo mejorado»
- **Decisión** (elegida por el diseñador):
  - **Pareja de estrellas:** se elige como al subir de nivel. `UpgradeChoiceEffect` pide la elección (`upgrade_choice_requested`). El `LevelUpController` la pone en la misma cola que las subidas de nivel y abre las cartas con el título «¡Mejora gratis!».
  - **Trío de estrellas:** «¡JACKPOT! Todo mejorado». `UpgradeAllEffect` sube un nivel cada arma y runa que no esté al máximo, cada una con su mejora tirada con la Suerte. Cada subida sale en el HUD («Espada sube a nivel 4») del color de su rareza.
  - El viejo `UpgradeEffect` (al azar) pasa a ser `UpgradeAllEffect`.
- **Por qué:** elegir es más interesante que el azar. El trío, más raro, recompensa con todo de golpe y enseña qué ha salido.

## 2026-11-18 · Power-up: parar el tiempo
- **Decisión:** nuevo power-up, el reloj de arena (`data/pickups/time_stop.tres`). Sale de la misma tabla que los demás (peso 1,5; la bomba tiene 2).
  - Al cogerlo, el `EnemySwarm` para el tiempo 5 s (`freeze_for`). Cada enemigo se congela (`Enemy.set_frozen`): su cuerpo pasa a estático, sin daño al tocar ni armas, y se le puede seguir golpeando. Los que salen mientras nacen congelados.
  - Los disparos enemigos se paran en el aire: su pool deja de procesarse.
  - La pantalla se tiñe de azul (`TimeStopFilter`, una capa bajo el HUD con un shader que desatura y tiñe), y el HUD dice «¡Tiempo detenido!».
- **Por qué:** lo pidió el diseñador. Congelar en vez de pausar deja que el jugador siga pegando y moviéndose: es un respiro y una ventana de daño. El director sigue sacando enemigos, que nacen congelados, y el reloj de la ronda no se para.

## 2026-11-18 · Selector de idioma en el menú principal
- **Decisión:** abajo a la izquierda del menú principal, pequeño, un `LanguagePicker`: un desplegable con un globo y el idioma actual. Ofrece un idioma por cada traducción cargada, con su nombre en su propio idioma (la clave `LANGUAGE_NAME` de cada columna del CSV: «Español», «English»). Al elegir, lo pone al momento y lo guarda en las opciones (`GameSettings.locale`). Un idioma nuevo aparece solo al añadir su columna.
- **Por qué:** lo pidió el diseñador, a mano y sin estorbar el menú. Va en `ui/widgets/` para poder ponerlo también en las opciones.

## 2026-11-18 · Las armas solo apuntan a lo que se ve
- **Decisión:** el `TargetFinder` descarta los objetivos que no se ven. Lanza un rayo desde el pecho de quien dispara hasta el centro del objetivo contra las capas que tapan la vista (`Weapon.sight_mask`: el mundo, con árboles, mesetas, ruinas y props). Los rayos se tiran del más cercano al más lejano y solo hasta tener los objetivos que hacen falta. Vale para todas las armas: el tirador tampoco dispara a través de un árbol.
- **Por qué:** lo pidió el diseñador. Disparar a lo que no se ve gastaba ataques contra paredes y quedaba raro.
- **Coste:** como mucho un rayo por candidato al buscar (una vez por ataque, o cada `search_interval` sin objetivo).

## 2026-11-18 · Ritmo más tranquilo: menos enemigos, menos vida, todo algo más lento
- **Petición del diseñador:** bajar la cantidad de enemigos y su vida, y que el jugador y los enemigos no vayan tan rápido.
- **Decisión** (oleadas del Brosque y datos de enemigos y jugador):
  - **Enemigos por segundo**, un 25 % menos en toda la curva: 0,6 al empezar (antes 0,8), 3,75 con dificultad 10 (antes 5), 9 con 15 (antes 12). Picos ×2 (antes ×2,5) y como mucho 180 a la vez (antes 250).
  - **Vida de base:** esbirro 38 (antes 45), tirador 26 y Bro-te 26 (antes 30).
  - **Vida por dificultad**, un 15-25 % menos: ×1,4 con 3, ×2,2 con 6, ×4,2 con 10 (antes ×5), ×9 con 11 y ×110 con 20 (antes 150).
  - **Velocidad**, un 10 % menos:
    - enemigos: esbirro 4,6, tirador 3,1, Bro-te 5,6, Ent-renador 3,8 y su embestida 18 m/s;
    - jugador: correr 6,8, esprintar 8,8, dash 21,6 (salida 9,2) y slide de 4,6 a 16,8 m/s.
  - **Experiencia y oro por enemigo**, un 30 % más (esbirro 1,3; tirador 2,6; Bro-te 0,65). Como salen un 25 % menos, se sube de nivel y se gana oro más o menos igual que antes.
- **Pendiente:** el *feel* lo decide el diseñador jugando. Si la ronda se queda corta de presión hacia el minuto 8-10, lo primero es subir la curva de enemigos por segundo en ese tramo.

## 2026-11-18 · Taberna en la pared del Brosque
- **Decisión:** una taberna medieval en el centro de la pared norte, mirando hacia dentro y con media casa tras la pared invisible. No se entra.
  - Al acercarse, «interactuar» cura la mitad de la vida máxima por oro: 15 + 3 × dificultad, ×1,5 por cada uso de esa taberna. Con la vida llena no cobra.
  - Lo dice en el HUD: «¡Salud!», «Sin oro no hay jarra» o «Ya estás como una rosa».
  - La mecánica es `HealShop` con `HealShopData`, así que otro nivel puede tener su propio sitio de curas.
  - Su sitio está reservado en el mapa generado (`LayoutData.reserved`: x, z y radio). Ahí no va ninguna pieza ni ningún árbol, tampoco los del anillo del borde y la banda de fuera, que antes no miraban nada.
- **Por qué:** lo pidió el diseñador. Curar por oro compite con los cofres y las tragaperras: otra decisión de en qué gastar.

## 2026-11-18 · Círculo de setas y objetos medievales
- **Decisión:**
  - **Círculo de setas** (`ChoiceShrine` con un `ItemPool`): hay dos por el Brosque, como piezas del mapa, con un aro y una columna de luz moradas.
    - Al usarlo ofrece 3 objetos pasivos distintos, tirados con la Suerte (`ItemPool.roll_several`), y se elige uno en un panel que pausa (`ItemChoicePanel`).
    - Se usa una vez y se apaga. Es gratis: el precio es ir a buscarlo.
  - **8 objetos medievales** (ya hay 23):

    | Rareza | Objetos |
    |---|---|
    | Común | herradura (+6 Suerte), hogaza de centeno (+0,5 vida/s), jarra de hidromiel (+10 % experiencia) |
    | Rara | capa de viaje (+5 % carrera y sprint), antorcha (+10 % área) |
    | Improbable | ballesta de bolsillo (+20 % velocidad de proyectil, +3 % crítico) |
    | De leyenda | grial de latón (+1,2 vida/s, +10 % vida) |
    | Mítica | Excalibro (+25 % daño, +10 % crítico) |

  - Los paneles que pausan y obligan a elegir comparten base (`ModalPanel`) y piezas de carta (`CardParts`), sacadas del de subir de nivel.
- **Por qué:** lo pidió el diseñador. Elegir entre tres premia explorar sin pagar.

## 2026-11-18 · Récords locales de partidas
- **Decisión:**
  - **Qué se guarda:** al morir o al vencer al jefe, `RunRecorder` apunta la partida (`RunRecord`): personaje, mapa, enemigos y élites derrotados, tiempo, nivel alcanzado, si se ganó y cuándo. La guarda `Save.record_run()` en `user://leaderboard.cfg`, una sola vez por partida. Abandonar desde la pausa no cuenta.
  - **Orden:** `Leaderboard` ordena por enemigos derrotados. A igualdad, primero las victorias y luego las partidas más largas. Guarda las 20 mejores (`SettingsData.leaderboard_size`).
  - **Dónde se ve:** «Récords», en el menú principal (`LeaderboardPanel`), con la última partida en azul. Al acabar una partida, los resultados dicen su puesto si entró.
  - **Tests:** solo apunta el `RunRecorder` de `run_systems.tscn` (`record_runs`). Un hook de GUT previo (`tests/hooks/pre_run.gd`) lleva los récords a un archivo de pruebas durante toda la ejecución, así un test que mate al jugador en un nivel entero no ensucia los de verdad.
  - **Personaje:** se guarda como el nombre del archivo (`warrior`) y su clave de nombre, ya que `CharacterData` no tiene id propio.
- **Por qué:** lo pidió el diseñador: ver tus partidas ordenadas por enemigos y con qué personaje. Solo en local: no hay cuentas ni servidor.

## 2026-11-18 · Enemigos de las oleadas algo más duros
- **Decisión:** suben las stats de base del esbirro y del tirador. Como el escalado por dificultad las multiplica, también pegan más en los minutos altos.

  | Enemigo | Vida | Daño |
  |---|---|---|
  | Esbirro | 38 → 46 | contacto 8 → 10 |
  | Tirador | 26 → 32 | contacto 4 → 5, disparo 10 → 12 |

  No cambian ni la velocidad ni la cantidad de enemigos (se bajaron a propósito en el cambio de ritmo). Tampoco el jefe ni sus Bro-tes.
- **Por qué:** el diseñador vio que, tras el cambio de ritmo, la partida se había vuelto muy fácil y a los enemigos les costaba seguir el ritmo del jugador. Del jefe dijo que estaba bien así.

## 2026-11-18 · Los objetos dicen lo que hacen a partir de sus datos
- **Decisión:**
  - **Revelado:** el revelado de un cofre o del premio del jefe (`ChestPanel`) enseña lo que hace el objeto debajo del nombre, una línea por modificador (`ModifierFormat.describe_all`, como las cartas). Después, en gris, su frase.
  - **Descripciones:** pasan a ser solo una frase con gracia, sin cifras. Las 15 que llevaban el efecto escrito se han reescrito.
  - **Test:** uno de datos falla si la descripción de un objeto lleva cifras en algún idioma.
- **Por qué:** el diseñador vio objetos que al conseguirlos solo enseñaban la descripción. Los 8 medievales tienen frase, no efecto, y el revelado no enseñaba los modificadores. Con el efecto escrito en la frase, además, salía repetido en las cartas del círculo de setas y se quedaría desfasado al cambiar un valor.

## 2026-11-18 · Los modificadores que suman llevan la unidad de su stat
- **Decisión:** `ModifierFormat` pone la unidad de la stat cuando el modificador suma. La saca de su `@export_range`, como el panel de stats, y salen «+10 % Probabilidad de crítico» o «+0.5 m/s Velocidad al correr».
  - `StatFormat.range_hint(stat)` recorre una vez las clases de datos del proyecto (los `Resource`, sin addons ni tests).
  - Si dos clases declaran la misma stat con unidades distintas, se queda sin unidad, porque depende de a quién se aplique. Les pasa a `damage`, `projectile_speed`, `duration` y `knockback`: en el jugador son un %, y en las armas un número, m/s o segundos.
- **Por qué:** el diseñador vio «+10 Probabilidad de crítico» sin el %, como si fueran puntos sueltos. Sacarlo de los datos evita una lista de unidades a mano que se desfase.

## 2026-11-18 · Multiplicidad con decimales
- **Decisión:**
  - **Proyectiles con decimales:** `OffenseData.projectile_count` pasa a ser decimal. Cada ataque lanza la parte entera y, con la probabilidad de la parte decimal, un golpe más (`Weapon.roll_shots`, con el azar de combate). Con 2,3 salen dos golpes y un 30 % de veces tres. Los proyectiles propios de cada arma siguen siendo enteros.
  - **Mejora con parte fija:** `UpgradeStat` gana una parte fija que no cambia con la rareza (`fixed`) y un redondeo (`step`). La mejora es `fixed + value × fuerza`.
  - **La runa de Multiplicidad** (parte fija 0,56, `value` 0,68, a un decimal) da:

    | Común | Rara | Improbable | De leyenda | Mítica |
    |---|---|---|---|---|
    | +1 | +1,2 | +1,5 | +1,8 | +2,2 |

    Antes daba siempre +1, o +2 alguna vez.
- **Por qué:** lo pidió el diseñador: que la común sea el +1 y las demás den más, con decimales. Solo con multiplicar por la rareza, la común (×0,6) se quedaría por debajo de 1 o la mítica muy por encima de 2,2. La parte fija junta las rarezas sin topes.

## 2026-11-18 · Catálogo de contenido y Archivo
- **Decisión:**
  - **Catálogo:** `data/content.tres` (`ContentCatalog`) lista lo que se puede descubrir, por tipos (`ContentCategory`). Cada tipo lleva su nombre, la pista de cómo se descubre, las stats que enseña y sus entradas en orden: personajes, armas, runas, objetos (por rareza) y enemigos.
    - Las pestañas del Archivo salen de los tipos, así que un tipo nuevo es solo datos.
    - Un test avisa si un `.tres` de las carpetas de datos no está en el catálogo, con su id, nombre, frase e icono.
  - **Ids e iconos:** personajes y enemigos ganan icono (SVG como los objetos) y los personajes, `id`. Los récords lo usan en vez del nombre del archivo.
  - **Lo descubierto:** se guarda en `user://archive.cfg` (`Discoveries`, por tipo e id) en cuanto hay algo nuevo.
    - Lo apunta `ArchiveRecorder`, que en las partidas escucha señales que ya existían.
    - Un personaje se descubre al jugar con él; un arma, runa u objeto, al conseguirlo (la inicial también), y un enemigo, al derrotarlo. Un élite cuenta como su enemigo, y el jefe también entra.
    - El muñeco del gimnasio no está en el catálogo y no cuenta.
  - **Archivo** (menú principal): una pestaña por tipo con su cuenta («2/3»), casillas con el icono (o «?») y la ficha a la derecha.
    - Personajes: diferencias de stats, arma inicial y pasiva.
    - Objetos: rareza y modificadores.
    - Runas: qué mejoran.
    - Armas y enemigos: sus `shown_stats`.
    - Lo no descubierto: «???» y la pista.
  - El menú principal abre sus tres paneles igual (`_wire`).
  - **Tests:** el hook previo de GUT también lleva el Archivo a un archivo de pruebas.
- **Por qué:** cierra el Hito 3. El diseñador pidió que los objetos entraran también y que los personajes salgan como «???» hasta jugar con ellos.
  - Los menús y la subida de nivel siguen sacando lo suyo de sus carpetas. Pasarán al catálogo cuando haya desbloqueos de verdad (Hito 8), que es cuando importa ofrecer solo lo desbloqueado.

## 2026-11-18 · La validación no toca récords ni Archivo
- **Decisión:** `Save.use_scratch_files(prefijo)` lleva récords y Archivo a `user://<prefijo>_*.cfg`, que empiezan vacíos.
  - El hook previo de GUT lo usa con `test`.
  - El juego lo usa si arranca con `-- --no-save`. `validate.sh` lo pasa al arrancar el menú y los niveles.
- **Por qué:** al validar, el paso que juega el Brosque unos segundos apuntó el Guerrero y la espada en el Archivo de verdad del jugador. Ese archivo se ha borrado, y los récords de verdad del diseñador no se tocaron.

## 2026-11-18 · Feedback al recibir daño: temblor y borde rojo
- **Decisión:**
  - **Temblor de pantalla** (`ScreenShake`, en el jugador): cada golpe suma «trauma» según la parte de la vida que quita.
    - Un golpe que quitara toda la vida da 2,5 de trauma; cualquier golpe, al menos 0,3. El trauma no pasa de 1 y baja 2,2 por segundo.
    - La cámara se desplaza (`h_offset`, `v_offset`) hasta 0,15 m y se inclina hasta 1,5°, por el trauma al cuadrado y con ruido.
    - Solo mueve la cámara, no el `CameraRig`: el giro, la puntería y el movimiento no cambian.
  - **Borde rojo** (`DamageVignette`, en `RunSystems`, por debajo del HUD), con un shader de viñeta casi rectangular:
    - al perder vida, un destello (0,6) que se apaga en 0,4 s;
    - por debajo del 35 % de la vida, un rojo que no se apaga y late, de 0,35 a 0,8 de fuerza y de 1,1 a 2,2 latidos por segundo según lo poca que quede;
    - curarse no destella.
  - Todo son valores exportados en sus escenas, como el resto del juice.
- **Por qué:** quienes lo han probado echaban en falta notar los golpes. El hit-stop y el flash al golpear siguen en el Hito 5.

## 2026-11-18 · Los enemigos trepan por el escenario
- **Decisión:** un enemigo que lleva un rato queriendo avanzar sin poder mira si tiene delante el mundo.
  - **Cuándo:** `EnemyStats.wall_climb_delay`, 0,35 s en esbirros y Bro-tes.
  - **Cómo lo mira:** una esfera pequeña delante, a la altura del cuerpo, con una sola consulta de física y solo cuando va atascado.
  - **Si hay mundo:** trepa por él a su `climb_speed` durante `wall_climb_time` (0,8 s, unos 2,8 m). Si sigue atascado, espera y lo vuelve a intentar.
  - Trepar encima de otros enemigos sigue igual.
- **Por qué:** quienes lo han probado vieron enemigos atascados en las pesas del Brosque.
  - Antes solo trepaban encima de otros enemigos, y contra una roca o un muro empujaban y se quedaban quietos.
  - Las pesas eran la peor trampa: discos de 2 m con un hueco bajo la barra donde se encajaban.
  - La consulta de física solo para los atascados mantiene el coste bajo con cientos de enemigos (sin navegación por enemigo).

## 2026-11-18 · Efectos de sonido sintetizados
- **Decisión:** los efectos de sonido se sintetizan en el proyecto, sin descargar nada.
  - **Recetas:** cada sonido es una receta en datos (`SfxRecipe`, `data/audio/sfx/`, al estilo de sfxr): onda, tono que se desliza, arpegio, vibrato, ruido, filtro de graves y envolvente.
  - **Generación:** `tools/gen_sfx.gd` la convierte en un `.wav` (`SfxSynth`, 44,1 kHz, 16 bits, mono) en `assets/audio/sfx/`. Hay 24.
  - **Qué suena con qué:** lo dice `data/audio/sfx_bank.tres` (`SfxBank` de `SoundCue`): golpe al jugador y su muerte, subir de nivel, golpe y muerte de enemigos, jefe (aparece y cae), cada recogible por su recompensa, rompibles, cofres (abrir, revelar, sin oro), tragaperras (giro, premio, nada, maldición, jackpot) y botones.
  - **Saturación:** cada `SoundCue` limita sus voces a la vez y su separación mínima, para que cien muertes a la vez no saturen. La variación de tono sale del azar cosmético de `Rng`.
  - **Racha de experiencia:** la experiencia recogida seguida sube un semitono cada vez, hasta una octava. Solo sube con lo que suena, para que con el imán se oiga cada escalón.
  - **Reproductor:** `Sfx`, un autoload nuevo, porque los sonidos cruzan pantallas (menú, selección y partida). Escucha el `EventBus` y cualquier botón que entre en el árbol, y suena por el bus `Effects`, que ya tenía volumen en las opciones, también en pausa.
- **Por qué:** quienes lo han probado echaban en falta sonido. Sintetizar deja todo en datos y sin licencias, y suena a arcade, a juego con el estilo.
  - Si un día hay sonidos grabados, basta con cambiar el audio de cada `SoundCue`.
  - Sin música por ahora: con síntesis sencilla quedaría pobre.

## 2026-11-18 · Moneda de verdad y vida en números
- **Decisión:**
  - **Moneda:** el sonido de recoger oro pasa de un arpegio de juego de plataformas a un «clinc» metálico.
    - El sintetizador gana parciales (`SfxRecipe.partials`): varios tonos a la vez, inarmónicos (×1; 1,47; 2,09; 2,56; 3,21), que es lo que hace sonar a metal.
    - Gana también una caída curvada (`decay_curve`), que se apaga deprisa y luego se arrastra.
    - La moneda suena a la mitad de antes y con más variación de tono (±8 %), para que muchas seguidas no suenen iguales.
  - **Vida en números:** la barra de vida del HUD pasa de 16 a 24 px de alto y lleva dentro la vida y la máxima («85 / 120»), con contorno. La vida se redondea hacia arriba para no ver un 0 estando vivo.
- **Por qué:** lo pidió el diseñador. La moneda sonaba muy alta y demasiado de juego de plataformas, y quería ver su vida exacta.

## 2026-11-19 · Ruleta al subir de nivel y volver a tirar
- **Decisión:**
  - **La ruleta** (GDD §5): al abrirse la elección, cada carta de mejora gira por las rarezas, cada vez más despacio, y se para en la suya, una tras otra.
    - La primera gira 0,9 s, cada siguiente 0,35 s más, con 2 vueltas enteras (`LevelUpData`).
    - Mientras gira, la carta no se puede elegir y esconde lo que mejora; el borde y el nombre van cambiando de color.
    - Un clic o «aceptar» (Espacio, Intro) las para todas, para no frenar una partida de horda.
    - Las cartas de un objeto nuevo no giran (no tienen rareza).
    - Suena un tic en cada paso y, al pararse, una campanilla más aguda cuanto más rara (`EventBus.upgrade_spin_ticked` y `upgrade_revealed`, que escucha `Sfx`).
  - **Volver a tirar:** un botón debajo de las cartas pide otras 3 para la misma elección.
    - Cuesta 10 de oro y ×1,5 cada vez en la partida (10, 15, 23…: `LevelUpData.reroll_cost_at`).
    - Lo cobra `LevelUpController` y sirve también en las mejoras gratis de la tragaperras.
    - Mientras giran las cartas o sin oro suficiente, está desactivado.
  - **Al cerrarse**, el panel quita sus cartas: antes seguían girando (y sonando) por detrás.
  - **`Sfx` sin pantalla:** sin pantalla (tests y validación) lleva la cuenta de lo que suena pero no reproduce, y las voces se cuentan por lo que dura cada sonido.
    - Godot deja viva la reproducción de un sonido a medias al salir y avisa de fugas, lo que hacía fallar al azar los tests sueltos.
    - Al cerrar el juego, `Sfx` para y suelta lo que suena.
- **Por qué:** es el primer paso del Hito 4: la apuesta con anticipación (giro, tic-tic), revelado por color y coste creciente que pide el GDD.

## 2026-11-19 · Algo más de vida para los enemigos de las oleadas
- **Decisión:** vida de base un 15 % más: esbirro 46 → 53 y tirador 32 → 37. El daño, la velocidad y la cantidad no cambian, ni el jefe ni sus Bro-tes.
- **Por qué:** lo pidió el diseñador: los enemigos aún caían demasiado rápido. El escalado por dificultad multiplica la base, así que se nota en toda la partida.

## 2026-11-19 · Hordas en los minutos 3 y 6
- **Decisión:** las rondas pueden tener hordas (`WaveData.hordes`, de `HordeData`).
  - **Cuándo y cuántos:** cada horda tiene su minuto, cuántos enemigos, cuántos de ellos élites, en cuántos segundos salen y cuánto aviso.
  - **Aviso:** `WaveDirector` avisa unos segundos antes, con el texto en el HUD (`announced`) y un cuerno de guerra (`EventBus.horde_incoming`, que escucha `Sfx`).
  - **Salida:** saca los enemigos repartidos en su tiempo alrededor del jugador, con el escalado de la dificultad. No cuentan para el máximo a la vez, para que la horda llegue entera.
  - **Brosque:**

    | Minuto | Enemigos | Élites | Sale en | Aviso |
    |---|---|---|---|---|
    | 3 | 35 | 0 | 2 s | 3 s |
    | 6 | 55 | 3 | 2,5 s | 3 s |

- **Por qué:** lo pidió el diseñador: momentos de presión marcados en la ronda, además de los picos de cada minuto.
  - Repartir la salida evita el tirón de sacar 50 enemigos en el mismo fotograma.
  - Con aviso, el jugador se prepara (se coloca, guarda el dash), que es parte de la gracia.

## 2026-11-19 · Sin tirones al golpear a muchos a la vez
- **Decisión:** medido con un banco (cargar el Brosque, 120 o 200 esbirros pegados al jugador y matarlos de un golpe), aparecieron tres causas.

  | Causa | Antes | Arreglo |
  |---|---|---|
  | Números de daño: un golpe a 120 creaba 90 etiquetas 3D nuevas y las dibujaba | 196 ms la 1.ª vez | Como mucho 24 nuevos por fotograma (`max_per_frame`); 96 preparados al empezar, con la fuente y los dígitos ya escritos |
  | Botín: 240 recogibles en el mismo fotograma, creando escenas si se acababa el pool | ~10 ms por golpe | Como mucho 40 por tick de física (`LootDropper.max_drops_per_tick`), el resto en los siguientes; 150 de experiencia y 150 de oro preparados al empezar (`PickupData.prewarm`) |
  | `StatFormat.range_hint` cargaba todos los scripts del proyecto la primera vez que una carta mostraba una mejora que suma (al azar: según la carta) | 180 ms en partida, 1,3 s en frío | Solo carga los scripts de recursos (lo dice la lista de clases globales) y se hace al cargar el menú y el nivel (`warm_up`) |

  - **Resultado con 120 muertes de un golpe:** el golpe pasa de 21 a 6,5 ms, y el peor fotograma de 196 a 15 ms la 1.ª vez y de 46 a 11 ms después.
  - **Subir de nivel justo después** pasa de 209 a 50 ms; queda el primer dibujo del panel, con el juego ya en pausa.
- **Por qué:** a quien lo probó le daba tirones al pegar a muchos a la vez.
  - El tercero era un fallo nuevo de cuando los modificadores ganaron unidades. Además, cien números de daño a la vez no se leen.
  - Pendiente para el Hito 5: preparar el desenfoque del panel al cargar y medir 300 enemigos.

## 2026-11-19 · Decimales con coma en español
- **Decisión:** el separador decimal es una traducción (`NUMBER_DECIMAL_SEPARATOR`: «,» en español y «.» en inglés). Lo usan los números de la interfaz:
  - `StatFormat.number` y `format`: el panel de stats, los efectos de mejoras y objetos («+0,5 m/s», «×1,5») y el premio por rapidez;
  - `StatFormat.fixed`: el contador de dificultad, con sus ceros («0,0»).

  El panel de depuración sigue con punto (no se traduce).
- **Por qué:** en español se escribe «0,5». Como traducción, un idioma nuevo pone el suyo sin tocar código.

## 2026-11-19 · Destello blanco al golpear, sin parón
- **Decisión:** cada golpe a un enemigo lo ilumina un instante (`HitFlash`, en las escenas de los enemigos y del muñeco).
  - **Cómo:** una capa blanca aditiva y suave (18 %) encima de su cuerpo durante 0,08 s. Cada golpe la vuelve a encender.
  - **Qué se ilumina:** solo el cuerpo (el tronco y la copa en el Bro-te); los ojos y los cuernos no hace falta. El jefe, entero.
  - **Élites:** al acabar, devuelve la capa que hubiera, el brillo del élite.
  - **Coste:** solo trabaja mientras destella. Con 120 golpes a la vez, el golpe sigue en unos 7 ms.
  - **Sin hit-stop:** el diseñador prefiere que el juego no se pare al golpear.
- **Por qué:** pegar se sentía plano. El destello confirma el golpe sin tapar al enemigo (al 35 % se quedaban casi blancos).

## 2026-11-19 · La simulación de equilibrio, con enemigos que persiguen
- **Decisión:** en `tools/sim_balance.gd` los esbirros inmortales persiguen al personaje. Antes estaban quietos.
- **Por qué:** desde que los golpes empujan, la espada mandaba a los muñecos quietos fuera de su alcance y no volvían; el Guerrero salía con un 2 % de la media. En la partida, los enemigos vuelven.
- **Lo que mide ahora:**
  - **Horda pegada al jugador quieto:** gana el área. Mago 184 %, Guerrero 104 %, Pícaro 12 % al empezar; con build 133 %, 144 % y 23 %.
  - **Jefe:** al empezar, 87 %, 85 % y 128 %; con build, 86 %, 51 % y 163 %.
- **Cómo leerlo:** la daga del Pícaro da a 3 enemigos por lanzamiento, frente al arco de la espada o la explosión del bastón. El escenario quieto exagera la ventaja del área, porque jugando te mueves y la horda va detrás. El «jefe» de la simulación es un esbirro ligero que la espada aparta; el Ent-renador pesa más.
- **Pendiente:** la decisión del diseñador sobre el Pícaro en horda.

## 2026-11-19 · Doble o nada al subir de nivel
- **Decisión:** al elegir una carta de mejora que aún puede subir de rareza (no una mítica ni un objeto nuevo), salen «Quedármela» y «Doble o nada (X %)».
  - **Ganar:** la mejora se vuelve a tirar con la rareza siguiente (`LevelUpData.next_rarity`), así que sale más fuerte.
  - **Perder:** esa subida no da nada.
  - **Probabilidad:** 50 % de base. La Suerte da una parte de lo que falta hasta el 100 % (`double_luck_half`: con 200 de Suerte, la mitad, un 75 %) y nunca llega a él.
  - **Animación:** la carta gira 1 s entre su rareza y la siguiente (la misma ruleta) y cae en la ganadora, que la sustituye, o se queda en gris con «¡Nada!». El resultado se ve 0,7 s, con su sonido (el del jackpot o el de la nada de la tragaperras). Un clic lo acelera.
  - **Quién decide:** el resultado lo tira `LevelUpController` con el azar de apuestas; el panel solo lo enseña.
- **Por qué:** es el segundo paso del Hito 4 (GDD §5): la apuesta sobre la carta elegida, con anticipación y revelado por color.

## 2026-11-19 · Estadísticas con Tab
- **Decisión:** mientras se mantiene Tab (`show_stats`) sale a la derecha la misma lista de stats que en la pausa (`StatsOverlay`, con su `StatsView`).
  - No pausa, y se actualiza cada 0,25 s.
  - Como el ratón está capturado, la rueda desplaza la lista.
  - Mide 380 px de ancho, para no tapar al jugador.
  - En pausa no sale: allí ya están.
- **Por qué:** es el último punto de interfaz del Hito 4. Mantener en vez de alternar evita dejarla abierta encima de la partida sin querer.

## 2026-11-19 · Opción de temblor de pantalla
- **Decisión:** las opciones ganan «Temblor de pantalla», de 0 a 100 %. Por defecto, 100 % (`SettingsData.default_screen_shake`).
  - Se guarda con las demás (`GameSettings.screen_shake`) y se aplica al momento, como el volumen.
  - `ScreenShake` multiplica el trauma de cada golpe por ella: a 0 %, la pantalla no tiembla.
  - El borde rojo no cambia.
- **Por qué:** el temblor marea a algunos jugadores, y es la opción de accesibilidad habitual en juegos con temblor.

## 2026-11-19 · El panel de subir de nivel, preparado al cargar
- **Decisión:** al cargar el nivel, `LevelUpController` prepara el panel (`LevelUpPanel.warm_up`).
  - Lo dibuja dos fotogramas casi transparente (1 %), sin pausar ni pedir el cursor, con una carta de ejemplo: una mejora mítica, que toca todas sus stats, y un objeto nuevo.
  - La carta de ejemplo sale de su propio azar, no del de las apuestas.
  - Mientras tanto no cuenta como abierto (`is_open`), y una subida de nivel de verdad lo cancela.
- **Por qué:** la primera vez que se dibujaba (el desenfoque y los textos de las cartas) costaba unos 40 ms más en dos fotogramas. Medido: el primer panel pasa de 11 + 38 + 27 ms a 9 + 18 + 12 ms, y el tirón queda escondido en la carga.

## 2026-11-19 · Nombres medievales en vez de los del casino
- **Decisión:** el GDD y el ROADMAP dejan los nombres que venían del casino:

  | Antes | Ahora |
  |---|---|
  | Bote | Botín |
  | La Banca | El Gremio (encaja con *Bro Guild*) |
  | Crupier | Tahúr |
  | Mesa (la siguiente) | Torneo; una partida es una ronda |
  | «¿Cobrar o Doblar?» | «¿Retirarse o seguir?» |
  | Estética neón | Luz de antorchas y faroles, con brillos de color donde hay algo que apostar o recoger |

  Las tragaperras se quedan, como anacronismo con gracia. El Hito 7 pasa a llamarse «El torneo».
- **De paso:** el GDD ya no pone los mapas generados como fuera de alcance, porque el Brosque cambia cada partida.
- **Por qué:** el plan del Hito 4 lo proponía y el diseñador lo aprobó. Así no quedan decisiones abiertas en el §11.

## 2026-11-19 · Medida de rendimiento: 300 enemigos
- **Medida:** la escena de estrés (`levels/stress/`, con ventana, sin V-Sync y la semilla fija) con todo lo de hoy: sonidos, destello, hordas y números limitados.

  | Enemigos a la vez | Media | El 1 % más lento | Física |
  |---|---|---|---|
  | 300 | 8,3 ms (120 fps) | 13,2 ms (~76 fps) | 9,5 ms |
  | 500 | 15,8 ms (63 fps) | 27,3 ms | 13,8 ms |

- **Lectura:** el objetivo del Hito 5 (300 enemigos a 60 fps) se cumple en el equipo de desarrollo. Con 500, la media aguanta 60 fps, pero el 1 % más lento baja. El máximo de la oleada es 180 y las hordas suben un poco más. Queda por medir en un equipo más modesto.

## 2026-11-21 · Hordas de 30 segundos, enemigos que pegan más y efectos más bajos
- **Hordas:** cada horda dura 30 s, saliendo poco a poco alrededor del jugador, y trae muchos más enemigos.

  | Minuto | Antes | Ahora |
  |---|---|---|
  | 3 | 35 enemigos en 2 s | 150 en 30 s |
  | 6 | 55 enemigos con 3 élites, en 2,5 s | 240 con 6 élites, en 30 s |

  Siguen sin contar para el máximo a la vez. Con lo que mata el jugador, quedan muy por debajo de los 500 medidos.
- **Daño de los enemigos, un 15 % más:**

  | Enemigo | Antes | Ahora |
  |---|---|---|
  | Esbirro | 10 | 11,5 |
  | Tirador (contacto / disparo) | 5 / 12 | 6 / 14 |
  | Bro-te | 6 | 7 |

  El jefe no cambia.
- **Efectos de sonido:** toda la mezcla baja 6 dB, la mitad de fuerte (`SfxBank.volume_db`), sin cambiar las proporciones entre sonidos. La barra de «Efectos» de las opciones sigue encima.
- **Por qué:** lo pidió el diseñador: hordas que sean un momento de aguante, no una ola, que todo pegue un poco más (los enemigos) y efectos algo más suaves de base.

## 2026-11-23 · Tres objetos con sinergia de movimiento
- **Decisión:** el movimiento daña solo con su objeto pasivo. Cada objeto sube una stat de daño de `MovementSynergyData`, que es 0 sin él, y cada copia suma otra vez. Los tres pasan por el daño % y el crítico del jugador y crecen con su área %:

  | Objeto | Rareza | Qué hace | Daño por copia | Tamaño |
  |---|---|---|---|---|
  | Zapatillas en llamas | Rara | El slide deja manchas de fuego cada metro; queman cada 0,5 s | 8 por quemadura | 1,2 m de radio, 3 s |
  | Bocina de estadio | Rara | Cada dash suelta una onda que empuja | 24 | 4,5 m en 0,3 s |
  | Cinturón de campeón | Improbable | La caída rápida explota al aterrizar, con temblor de pantalla | 40 | 5,5 m en 0,22 s |

- **Cómo:**
  - **Ondas:** el dash y la caída reutilizan la `Shockwave` del jefe. Ahora acepta las stats de ataque de quien la lanza y un tamaño, y su número de resultados por tick (`max_results`) es un dato: el jugador mira 128 hurtbox para no dejarse enemigos en una horda.
  - **Fuego:** el rastro vive en un solo nodo (`FireTrail`), con manchas en un búfer circular; si hacen falta más, reutiliza la más vieja. Cada quemadura es una consulta de física por mancha. Un enemigo se quema una vez por tick aunque pise varias manchas, y encadenar slides no adelanta el ritmo.
  - **Sonido:** viento para la onda y golpe grave para la explosión. El fuego no suena, para no llenar la mezcla.
- **Por qué objetos y no runas:** primero fueron runas (Brasas, Vendaval, Terremoto), pero el diseñador las prefirió como objetos. Así no ocupan una de las 4 ranuras de runa, salen de cofres, del jefe y del círculo de setas, y se apilan como el resto de pasivos.
- **Por qué así:** el GDD pide mejoras que premien moverse bien. Que el daño dependa del objeto deja el movimiento base igual y hace de la sinergia una elección de build. La onda del dash es más débil que la explosión porque sale más a menudo: el dash recarga stamina y la caída exige estar en el aire. No se pueden medir con `tools/sim_balance.gd`, porque allí el jugador no se mueve; habrá que probarlas jugando.

## 2026-11-23 · Miniboss: el Trolleador Cara
- **Decisión:** un miniboss sale a los 4:30 del Brosque, entre las dos hordas. Es el Trolleador Cara, un troll con porra y sonrisa de trollface.
  - **Base:** es un `Boss` como el Ent-renador (rabia, gritos, inmune a la bomba). Lo saca un `MiniBossEncounter` según `WaveData.mini_bosses`.
  - **Aviso y salida:** se anuncia 4 s antes y aparece a 16–22 m del jugador, escalado con la dificultad igual que el jefe.
  - **Ataques:**
    - *Porrazo*, nuevo `SlamAttack`, en área: un aro fijo marca 7,5 m y otro se abre desde sus pies en 1,2 s; cuando llega al borde cae el golpe, con 1,6 × su daño al tocar.
    - *Salto*, el `LeapAttack` del Ent-renador más corto.
  - **Premio:** 60 de oro y un objeto de rara a de leyenda, revelado como el del jefe.
  - **Base de stats:** 2200 de vida, 18 de contacto y 3,4 m/s. A los 4:30 sale con unas 1,5 veces esa vida.
- **Las dos barras:** la barra de jefe es ahora una escena (`boss_bar.tscn`) con dos instancias en una columna arriba en el centro. Arriba, la del jefe; debajo, la del miniboss, más pequeña y verde; después, los textos breves. Si coinciden, se apilan y nunca se tapan. Un test lo comprueba con sus rectángulos.
- **Jefes que trepan:** el Ent-renador no tenía stats de trepar y su sonda de muros salía a 0,55 m del centro, dentro de su propio cuerpo de 1,2 m. Ahora trepa como los esbirros (`climb_speed` 5,5, `wall_climb_time` 1,2) y su sonda sale a 1,5 m, por delante del cuerpo. Lo mismo el troll. Un test lo pone contra las pesas: antes se quedaba pegado en x = 5,8 y ahora pasa al otro lado.
- **Trolls de piedra:** el mismo modelo del troll en dos posturas, pintado de piedra con `StoneStatue`, con musgo y una olla. Están fuera de la pared este, en un claro reservado del bosque (`LayoutData.reserved`) para que se vean desde dentro, y algo más grandes que el vivo para que destaquen de lejos.
- **Escalado sin ciclos:** el cálculo del escalado con la dificultad pasa de `WaveData.scaling_for` a `StatScaling.modifiers_for`. `WaveData` ahora lleva `MiniBossData` dentro y, si `MiniBossData` llamara a `WaveData`, los dos scripts se referenciarían en círculo. Ese ciclo dejaba memoria sin liberar al salir, y la validación lo detectó.
- **Por qué:** lo pidió el diseñador. El miniboss rompe la espera entre hordas con un enemigo que hay que esquivar, no solo golpear, y da un objeto a mitad de ronda. Los trolls de piedra anticipan al vivo.

## 2026-11-23 · Tres armas nuevas: hacha, colonia y martillo
- **Decisión:** tres armas que atacan de formas que aún no había. Cada una usa los proyectiles extra a su manera:

  | Arma | Cómo ataca | Proyectiles extra | Base |
  |---|---|---|---|
  | Hacha arrojadiza | Va y vuelve atravesando. Corta lo que cruza y lo que pasa a menos de 0,9 m × área de su filo; vuelve antes si choca con una pared | Más hachas | 16 de daño cada 1,5 s |
  | Nube de colonia | Aura de 3,2 m × área. Con alguien dentro, pulso a todos los de dentro con un empuje leve; no necesita verlos | Más pulsos seguidos | 7 cada 0,7 s |
  | Martillo de guerra | Cae del cielo sobre el grupo más denso a su alcance (16 m) y aplasta a todos en 2,6 m × área | Más martillos, cada uno sobre otro grupo | 30 cada 2 s |

- **Medida** (nivel 1, sin mejoras del personaje, DPS contra muñecos durante 12 s):

  | Arma | Horda pegada (24 a 1,8–4 m) | Sueltos (10 a 6–12 m) |
  |---|---|---|
  | Espada | 231 | 0 |
  | Bastón | 191 | 17 |
  | Daga | 75 | 72 |
  | Hacha | 93 con 14 de daño (ahora 16: unos 107) | 19 |
  | Colonia | 241 | 0 |
  | Martillo | 180 | 15 |

  Con un rayo fino, el hacha solo daba a uno por pasada (19 en la horda). Por eso corta también a lo ancho con su filo.
- **Por qué:** lo pidió el diseñador; el GDD ya hablaba de armas que van al grupo más denso.
  - **Papeles distintos:** la colonia es la espada de la horda (fuerte encima, nula lejos), el martillo castiga los grupos apretados y el hacha va a media distancia contra filas.
  - **Equilibrio:** ninguna pasa de lo que ya hacían espada y bastón a nivel 1. Las mejoras son las de siempre, con las comunes flojas.

## 2026-11-23 · Balanceo al andar
- **Decisión:** en el suelo, el cuerpo del jugador rebota a cada paso y se mece un poco de lado a lado (`BodyBob`). Rebota más alto y da más pasos cuanto más rápido va respecto a su carrera:

  | | Rebote | Pasos por segundo |
  |---|---|---|
  | Despacio | casi nada | 1,8 |
  | A la carrera | 8 cm | 3,2 |
  | Por encima de la carrera (mejoras) | hasta 12 cm (×1,5) | 3,2 |

  En el slide, en el aire o parado no rebota, y vuelve a su sitio suavemente.
- **Cómo:** mueve las partes del modelo (`Skin` y `Sockets`), no el modelo entero, porque el modelo ya lo agachan, giran y voltean otros nodos (`BodyCrouch`, `BodyFacing`, `BodyFlip`) y se pisarían. Va en el tick de física, con la interpolación del proyecto, para que sea igual a cualquier tasa de fotogramas. Avisa de cada paso (`stepped`): ahí saldrá el polvo de los pasos.
- **Hit-stop, descartado:** el diseñador no quiere parones al golpear. El GDD ya no lo lista; el golpe se nota con el destello blanco, los números y el sonido.
- **Por qué:** lo pidió el diseñador, para que correr se sienta como correr.

## 2026-11-23 · Luz del Brosque: media tarde cálida
- **Decisión:** el Brosque deja el aspecto plano y lavado por una luz de media tarde, siguiendo el GDD (cálida, con brillo en lo que se recoge). El entorno vive en `levels/brosque/environment.tres` y lo comparte el menú principal.

  | | Antes | Ahora |
  |---|---|---|
  | Sol | Blanco, energía 1 | Cálido (1; 0,89; 0,72), energía 1,25 |
  | Cielo | Azul verdoso | Azul más profundo arriba y horizonte cálido |
  | Niebla | Verdosa, tiñe el cielo | Dorada, con algo de dispersión del sol, sin tapar el cielo (20 %) |
  | Tonemap | Filmic | ACES, contraste ×1,06 y saturación ×1,15 |
  | Glow | Por defecto | Intensidad 0,7, umbral 0,95: brillan las gemas, los ojos y las luces |
  | Sombras de contacto | No | SSAO |
  | Hierba | Un verde plano | Manchas grandes claras y oscuras, calvas secas y grano fino (`grass.gdshader`) |

- **Coste:** con 300 esbirros vivos alrededor del jugador en el Brosque (1280 × 720, sin V-Sync, equipo de desarrollo), el SSAO no se nota: 8,0 ms con él y 7,8 ms sin él. Ese fotograma lo limita la física, no la gráfica. En gráficas flojas podría pesar más; si hace falta, irá como opción en «Opciones».
- **Por qué:** el diseñador pidió perfeccionar el aspecto. Antes todo era un verde pastel uniforme y la niebla verdosa apagaba la distancia: costaba leer el suelo y faltaba calidez.

## 2026-11-23 · Partículas
- **Decisión:** estallidos cortos de puntos suaves (un mismo `soft_dot_quad.tres`), sin texturas ni artista:

  | Efecto | Cuándo | Cómo se ve |
  |---|---|---|
  | Humo | Muere un enemigo | 18 puntos de su color (`EnemyData.color`, nuevo) que se abren y se apagan |
  | Chispas | Golpe a un enemigo | 6 chispas cálidas, rápidas, que caen |
  | Restos | Se rompe una calavera o una bolsita | 12 trocitos claros que saltan y caen |
  | Destellos | Se abre un cofre | 26 puntos dorados que suben |
  | Polvo | Una onda golpea el suelo (porrazo y salto del troll, Burpee, la caída del jugador) | Un anillo de polvo que se abre a ras de suelo |

- **Cómo:**
  - **Efectos globales:** los tres primeros los lanza un `BurstEmitter` que escucha el `EventBus`. Lleva una reserva circular y un tope por fotograma (10 humos, 8 chispas, 3 restos): una bomba o un tajo a cien enemigos no lanza cien estallidos a la vez.
  - **Efectos de escena:** destellos y polvo van dentro de su escena, conectados a una señal nueva (`Chest.opened`, `Shockwave.started`). En la onda del dash el polvo está oculto, porque el dash puede ser en el aire.
- **Monedas:** ya salen volando del enemigo como botín, así que no llevan partículas propias.
- **Coste**, con un golpe a 120 esbirros pegados (banco del Brosque, 1280 × 720):

  | | Sin partículas | Con partículas |
  |---|---|---|
  | Golpe que mata a los 120 | 7,0 ms; peor fotograma 13,5 ms | 7,4 ms; peor fotograma 14,8 ms |
  | Golpe a 120 sin matar (en caliente) | Peor fotograma ~20 ms | Peor fotograma ~20 ms |

  El pico de ~20 ms sale igual sin partículas: viene de la física de los 120 apilados tras el empuje.
- **Por qué:** era lo que faltaba del juice del GDD. Cada golpe, muerte o premio se lee de un vistazo en mitad de la horda.

## 2026-11-23 · UI animada
- **Decisión:** la interfaz se mueve con tweens cortos, todos con sus tiempos en `data/ui/motion.tres` (`UiMotionData`):

  | Qué | Cómo |
  |---|---|
  | Botones | Crecen un 4 % con el ratón o el foco y se hunden al 96 % al pulsarlos, en 0,08 s. Los engancha todos el autoload `UiJuice` al entrar en el árbol, salvo las cartas de mejora, que tienen su propia animación |
  | Paneles | Aparecen en 0,16 s, de transparentes y al 94 % a su tamaño |
  | Contadores y casillas | Saltan al 118 % y vuelven en 0,22 s: el oro al ganar, la casilla de un arma, runa u objeto al llegar o subir de nivel, el número de nivel |
  | Experiencia | La barra se llena suave en 0,18 s; al subir de nivel empieza de nuevo al momento |
  | Vida | Al perderla, la barra baja de golpe y deja un rastro claro que se vacía tras 0,35 s, en 0,45 s; al curarse, sube suave |

- **Por qué:** el GDD pide una UI animada y legible en mitad del caos. El rastro de la vida dice cuánto quitó el golpe sin leer números. La vida baja al momento para no esconder el peligro.

## 2026-11-23 · Pulido tras las pruebas (Hito 5b)
- **Decisión:** arreglos y cambios tras una partida de prueba del diseñador.
  - **Opciones:** en pantalla completa, la resolución que se ve es la de la pantalla. Antes salía el tamaño de ventana guardado, que no era el real.
  - **Taberna:** el tejado y la chimenea chocan (dos cajas inclinadas y una recta). Antes la caja del edificio llegaba a 4,2 m y el tejado, que llega a unos 6 m, se atravesaba.
  - **Jefes sin gritos:** se quitan del todo: la señal, los textos, la línea de la barra y las frases de los datos. Solo queda el aviso de llegada del nivel («¡Llega el Ent-renador!»), que es del narrador, no del jefe.
  - **Barras de jefe:** nombre a la izquierda, vida en números a la derecha y barra fina. Antes eran el nombre grande centrado, una barra gruesa y una línea de gritos; ocupan menos y se leen mejor. Las dos barras juntas ya no tapan la pantalla.
  - **Experiencia:** baja a una franja fina a lo ancho, abajo del todo, con el nivel pequeño a la izquierda (como en Megabonk). Arriba quedan el oro, el reloj y la dificultad.
  - **Stats al elegir:** la vista de Tab también funciona con el panel de subir de nivel o el de elegir objeto abiertos (el juego está en pausa), por encima de ellos, y los dos lo recuerdan con un texto. En el menú de pausa sigue sin salir, porque la pausa ya las enseña.
  - **Elegir nivel:** cada nivel lleva su objetivo y su lore (`LevelData.goal_key` y `lore_key`), y la ficha del nivel señalado sale debajo de la lista. El lore completo vive en `docs/LORE.md`, que escribe el diseñador y que dice qué claves del CSV le tocan.
  - **Hacha arrojadiza:** gira tumbada (en horizontal, como un aspa), su modelo es 1,7 veces más grande, crece con el área y su filo llega a 1,2 m (antes 0,9 m). Corta a más gente por pasada.
- **Por qué:** lo pidió el diseñador tras probar la partida.

## 2026-11-23 · Portal del jefe y cómo se gana
- **Decisión:** el altar del jefe pasa a ser un **portal** (`BossPortal`), y vencer al jefe ya no termina la partida.
  - **El portal:** un aro de piedra con un remolino (`portal_vortex.gdshader`) y un pedestal delante con las ranuras de las llaves. Se invoca igual que antes: con las llaves o, forzado, al empezar la prórroga. El remolino dice en qué punto está: violeta y tenue sin llaves, más vivo con ellas y dorado al abrirse.
  - **Al vencer al jefe:** llega el premio como antes, pero las oleadas siguen. El portal se abre, salen dos textos («¡Ent-renador vencido!» y «Cruza su portal para pasar el nivel», de `BossData.defeated_keys`) y una flecha amarilla junto al jugador lo señala 3 s (`PortalArrow`).
  - **Victoria** (`EventBus.run_won`, la emite `BossEncounter` una sola vez): al cruzar el portal abierto (`level_exit_reached`) o al morir en la prórroga con el jefe vencido. Solo entonces paran las oleadas y se retiran los enemigos. La pantalla de resultados y el `RunRecorder` escuchan `run_won` en vez de `boss_defeated`.
  - **Morir y ganar a la vez:** la muerte llega por `player_died` y, en la prórroga, `BossEncounter` responde con `run_won` en el mismo aviso. Los resultados y el `RunRecorder` atienden la muerte al final del fotograma (`call_deferred`), así que la victoria llega antes y manda.
  - El premio por rapidez es el del momento en que cae el jefe, no el de cruzar el portal: no se pierde por recoger lo que quede.
- **Por qué:** lo pidió el diseñador. Pasar el nivel es una decisión del jugador (cruzar) y deja un rato para recoger el botín. Morir en la prórroga con el jefe vencido ya no castiga a quien hizo lo difícil.

## 2026-11-23 · Las mejoras dicen cuánto ganas
- **Decisión:** las cartas de subir de nivel y de elegir objeto ponen cada stat con su valor de ahora y el que quedará: «Daño 18 → 27», «Tiempo entre ataques 1,1 s → 0,94 s», «Daño 100 % → 125 %». Sustituye a «+9 Daño»: una línea por stat, así la carta no crece. El revelado del cofre, que tiene sitio, deja las dos cosas: «+25 % Daño (100 % → 125 %)».
  - **Qué stats:** las del arma para sus mejoras, y las del jugador para runas y objetos. Un arma nueva no muestra números: aún no tiene mejoras.
  - **Cálculo:** `StatBlock.preview` calcula el valor con los modificadores de más, con la misma fórmula, sus límites y su redondeo, sin aplicarlos. El formato y la unidad salen de la propiedad de datos de la stat (`StatsComponent.get_property`), como en la vista de stats. Si varios modificadores tocan la misma stat, sale una sola línea con todos.
  - **Cofre:** el texto se escribe al empezar el revelado, porque al acabar el objeto puede haber llegado ya y el «antes» lo contaría.
  - **Paneles que no caben:** con el aviso de Tab (Hito 5b) y cartas de tres mejoras, el panel de subir de nivel medía 698 px de alto en una pantalla de 648 y cortaba el título. `ModalPanel.fit_to_screen` encoge su contenedor lo justo cuando no cabe; lo llevan subir de nivel y elegir objeto.
- **Por qué:** lo pidió el diseñador. «+10 %» no dice cuánto es; con los dos números se ve la ganancia real y se comparan cartas de un vistazo.

## 2026-11-23 · El alcance de la colonia, en el suelo
- **Decisión:** la burbuja de la nube de colonia se cambia por un dibujo en el suelo, como en Megabonk: un aro de trazos en el borde del aura, otro fino por dentro con ocho marcas y un velo muy tenue que se aclara hacia el centro. Gira a 12 °/s y se aviva en cada pulso. Va en un plano suelto (`top_level`) que un rayo pone en el suelo bajo el jugador, así que al saltar se queda abajo, que es donde están los enemigos. Se borra `cologne_cloud.gdshader`.
- **Por qué:** lo pidió el diseñador: la burbuja tapaba al jugador y no dejaba ver hasta dónde llegaba. En el suelo el borde se lee de un vistazo y no tapa nada.

## 2026-11-23 · El borde del mapa se ve al acercarse
- **Decisión:** las paredes de choque del borde (invisibles hasta ahora) llevan delante una pared de malla de rombos (`MapBoundary`, `boundary_wall.gdshader`). Solo se ve en un círculo alrededor del jugador: del todo a 3 m y nada a 11 m. Los rombos suben despacio, hay una franja más marcada abajo y por arriba se apaga. A más de 11 m de todos los bordes, las paredes ni se dibujan.
  - Es solo visual. Lo que choca siguen siendo las cajas `Bounds` del nivel; un test comprueba que su cara de dentro coincide con `MapBoundary.half_extent`.
  - El brillo es una esfera alrededor del jugador: se ve igual al saltar o en una meseta pegada al borde.
- **Por qué:** lo pidió el diseñador. Chocar con un muro invisible parecía un fallo, y ver el borde desde lejos rompería el bosque. Así avisa solo cuando hace falta.

## 2026-11-23 · Los power-ups se ven al cogerlos
- **Decisión:** cada power-up tiene un efecto en el suelo bajo el jugador al cogerlo (`PowerUpFx`). Escucha `pickup_collected`, igual que los `PickupEffect`, pero solo es visual.

  | Power-up | Efecto |
  |---|---|
  | Bomba | Explosión nuclear: destello blanco de 0,45 s, temblor fuerte, bola de fuego, columna de humo, sombrero que sube hasta unos 3,8 m, polvo hacia fuera y una onda en el suelo hasta 15 m, el alcance de su daño (un test lo comprueba) |
  | Imán | Onda azul de 10 m y chispas que van hacia el jugador |
  | Comida | Chispas verdes que suben y un destello verde muy suave |
  | Bebida energética | Estallido lima, rayas que suben y un temblor pequeño |
  | Reloj de arena | Onda azul de 22 m, escarcha y un destello azul, junto con el tinte que ya tenía |

  - **Piezas:** cada efecto es una escena `FxBurst`, con partículas de un solo disparo, aros en el suelo con el shader `ground_ring` y nodos que suben (el sombrero del hongo). Dice qué temblor y qué destello quiere, y `PowerUpFx` los aplica. Las escenas sencillas se generaron con los mismos parámetros; la bomba está hecha a mano.
  - **Altura del hongo:** con la cámara detrás del jugador, lo que pasa de unos 4 m queda fuera de plano. Por eso el sombrero no sube de ahí: se ve como una cúpula de humo encima. La columna es semitransparente para no tapar al jugador más de un segundo.
  - **En el suelo:** si se coge en el aire, un rayo pone el efecto en el suelo, igual que el aro de la colonia.
- **Por qué:** lo pidió el diseñador. Coger un power-up ya decía algo en texto, pero no se sentía. La bomba tenía que parecer una bomba.

## 2026-11-24 · Los enemigos salen del suelo
- **Decisión:** al salir del pool, el modelo de un enemigo crece con un pequeño rebote mientras sube desde 0,6 m bajo sus pies, en 0,35 s, y levanta un poco de polvo. El Ent-renador y el Trolleador tardan 0,8 s y salen desde 2,5 m. El cuerpo y su choque están desde el primer momento: solo se anima el modelo.
  - Se anima en `_process` del propio enemigo y solo mientras aparece. Por fotograma, no por tick: el rumbo se calcula cada tres ticks (`steering_slices`) y a ese ritmo la animación iría a saltos.
  - El polvo va por una señal nueva, `enemy_spawned`, con otro `BurstEmitter` (`spawn_dust`, 10 partículas, como mucho 8 por fotograma: una horda no dispara cien a la vez).
  - Si muere mientras sale, deja de aparecer y encoge como siempre.
- **Por qué:** lo pidió el diseñador. Antes los enemigos aparecían de golpe; así se ve de dónde salen y da tiempo a reaccionar.

## 2026-11-24 · Pulido tras las pruebas (2) (Hito 5c)
- **Decisión:** arreglos de la segunda tanda de pruebas del diseñador.
  - **Elegir nivel:** un clic marca el nivel (se queda hundido) y saca debajo su objetivo y su lore; abajo, «Jugar» encima de «Volver». Antes, el clic empezaba la partida y la ficha salía al pasar el ratón: no daba tiempo a leerla. Los botones de nivel son más bajos (`SmallButton`) y el lore más ancho, para que la lista, la ficha y los dos botones quepan en 720p.
  - **Stats importantes:** la vista de stats (pausa, Tab y armería) enseña solo las que algo del juego puede cambiar: algún modificador o mejora de los datos, o la dificultad, que sube sola. Quedan 23 de las 72 del jugador; las otras 49 son tiempos y márgenes internos del movimiento (coyote time, mantle, slide…) que no cambian nunca. Una mejora nueva sobre una stat la hace aparecer sola.
    - Se buscan solo en las carpetas de datos que cambian al jugador. Buscar en todo `data` cargaba los niveles con sus escenas y tardaba 1,7 s; así son 0,4 s en frío, al cargar el nivel, y menos con los datos ya cargados. Un test (lento a propósito) mira todo `data` y avisa si una stat del jugador cambia desde una carpeta que no está en la lista.
  - **Rastro de fuego:** ya escalaba con el daño %, el crítico, el área % y la duración %, pero no con la velocidad de ataque %, que en las armas acorta la espera. Ahora quema cada 0,5 s ÷ velocidad de ataque: con un 200 %, cada 0,25 s.
  - **Optimizar:** medido en el Brosque a 1080p con una sonda (sin VSync, el peor caso):

    | Qué | Antes | Ahora |
    |---|---|---|
    | Fotogramas por segundo, sin enemigos | ~880 (sin límite) | 60 (límite de serie) |
    | Triángulos por fotograma, sin enemigos | 2,6 M | 0,43 M |
    | Triángulos por fotograma, con 300 esbirros | 9,3 M | 1,6 M |
    | Llamadas de dibujo, con 300 esbirros | 640 | 890 |

    - **Límite de FPS:** el juego no tenía. Con el VSync quitado dibujaba cientos de fotogramas por segundo, también en los menús, y el ordenador iba a tope sin que se notara nada. Ahora es una opción de pantalla (30, 60, 90, 120, 144, 165, 240 o sin límite), de serie 60, que se aplica al arrancar (`Engine.max_fps`). Las opciones ya guardadas sin ella toman el 60.
    - **Mallas redondas:** las esferas, cápsulas, cilindros y toros que usaban la resolución de serie de Godot (64 segmentos: miles de triángulos por enemigo, y cada uno se dibuja también en cada pasada de sombra) pasan a 16 × 8, 16 × 4, 12 y 24 × 8. En el estilo low-poly no se nota. El cuerpo del jugador se queda como estaba: siempre está grande en pantalla.
    - **Bosque por trozos:** era un MultiMesh por parte para todo el mapa (unos 2.000 árboles con la banda de fuera). Un MultiMesh es un solo objeto para el motor: se dibujaban todos los árboles siempre, en la vista y en las cuatro pasadas de sombra. Ahora va en trozos de 40 m (`ForestData.chunk_size`) y el motor descarta los que no se ven. Suben algo las llamadas de dibujo, pero cada una mueve muchos menos triángulos.
    - **Física:** con 180 esbirros apretados, el rumbo del enjambre cuesta 1 ms por tick y la física, unos 4–6 ms. Bajar los pasos del solver de Jolt (10 → 6) no cambió nada medible. Se deja en el backlog: a 60 Hz es una parte de un núcleo y no crece con los FPS.
- **Por qué:** lo pidió el diseñador tras probar.

## 2026-11-24 · Hojas al meterse en las copas
- **Decisión:** al meter el cuerpo en la copa de un árbol (saltando o desde una meseta), caen unas 18 hojitas del color de ese árbol, algo más claras para que se vean contra la copa. Salen del borde de abajo de la copa, donde no las tapa la propia copa, giran y se balancean al caer (turbulencia). El mismo árbol espera 1,5 s antes de soltar más.
  - Los árboles son MultiMesh, sin nodos propios: `CanopyLeaves` toma la lista que genera el mapa (`LevelLayout.get_trees`) y trata cada copa como un cilindro (`ForestBuilder.canopy`: radio y franja de alturas según su forma y su tamaño).
  - Cada 0,1 s mira solo las celdas de 8 m alrededor del jugador. Los árboles de fuera de las paredes no se miran: no se puede llegar a ellos.
  - La hoja es un SVG blanco con forma de hoja (`assets/textures/vfx/leaf.svg`); la partícula le pone el color del árbol.
- **Por qué:** lo pidió el diseñador. Las copas no chocan, y meterse dentro no daba ninguna respuesta.

## 2026-11-24 · El Brosque, más grande
- **Decisión:** el Brosque pasa de paredes a 80 m del centro a 110 m: casi el doble de área (×1,9). Lo que hay dentro crece en proporción:

  | Qué | Antes | Ahora |
  |---|---|---|
  | Zona de juego (piezas, rompibles) | ±70 m | ±96 m |
  | Mesetas (altas / bajas) | 2 / 3 | 3 / 5 |
  | Tragaperras (suelo / mesetas) | 1 / 3 | 2 / 4 |
  | Cofres (suelo / mesetas) | 5 / 2 | 8 / 3 |
  | Círculos de setas | 2 | 3 |
  | Ruinas (templo, muros, arcos) | 1, 3, 2 | 2, 5, 3 |
  | Pesas / bancos | 8 / 6 | 14 / 10 |
  | Calaveras / bolsitas / charcos | 30 / 20 / 14 | 56 / 38 / 26 |
  | Árboles sueltos | 150 | 280 |
  | Tarjetas de socio | 3, a más de 25 m del centro y entre sí | 3, a más de 34 m |

  - Se mueven con la pared la taberna (centro de la pared norte), los trolls de piedra (fuera de la pared este), el anillo de árboles junto a las paredes, la banda de bosque de fuera, el suelo, la zona donde salen los enemigos (`play_area`), el borde que se ve (`MapBoundary`) y las hojas de las copas.
  - El claro del centro y el portal del jefe (a 24–28 m) no cambian: el comienzo se siente igual.
  - Los tests del nivel ya no llevan números a mano: leen las cantidades de los datos del mapa y la pared del borde.
  - El rendimiento apenas cambia gracias al bosque por trozos: sin enemigos, de 0,43 M a 0,49 M triángulos y de 760 a 940 llamadas de dibujo.
- **Por qué:** lo pidió el diseñador: el mapa se quedaba pequeño para explorar.

## 2026-11-24 · Objetos con efectos al golpear
- **Decisión:** los objetos pasivos pueden llevar efectos que salen con una probabilidad en cada golpe del jugador (`PassiveItemData.on_hit`), además de sus stats. Tres efectos y un objeto nuevo para cada uno:

  | Objeto | Rareza | Efecto |
  |---|---|---|
  | Pre-entreno caducado | Rara | 15 %: veneno, un 10 % del golpe cada 0,5 s durante 3 s (60 % en total) |
  | Cable pelado | Improbable | 12 %: rayo a los 3 enemigos más cercanos (6 m de salto), con la mitad del golpe |
  | Spray de frío | Rara | 20 %: frena un 40 % durante 2 s |

  - **Escala con el golpe:** el daño de un efecto es una parte de lo que quitó el golpe. Así crece con todo lo que sube el golpe (daño %, crítico, arma) sin stats nuevas. A media, el veneno suma un 9 % de daño y el rayo un 18 %, repartido entre varios.
  - **Copias:** cada copia suma la probabilidad del efecto, como las stats suman sus modificadores. Sin topes: si con muchas copias sale siempre, es la recompensa de apostar por ese objeto.
  - **Sin cadenas:** el daño de un efecto no vuelve a tirar efectos (`DamageInfo.triggers_effects`). Si no, un rayo podría envenenar y ese veneno soltar otro rayo.
  - **Por dónde pasa:** `DamageReporter`, que ya avisaba de cada golpe a un enemigo, avisa también de a quién (`enemy_hit`). Así sirve para cualquier arma, proyectil, onda o rastro, sin tocar cada uno.
  - **Se ve:** los números de daño del veneno salen verdes y los del rayo celestes (`DamageInfo.kind`); el rayo dibuja una línea entre los enemigos. El frío, de momento, solo se nota en lo que tardan.
  - **Fichas:** cada efecto tiene su línea con sus números («15 % al golpear: veneno (60 % del golpe en 3 s)») en las cartas de elegir objeto, el revelado del cofre y el Archivo. La frase del objeto sigue sin cifras.
- **Por qué:** lo pidió el diseñador. Objetos que solo suben stats se parecen mucho; un efecto cambia cómo se juega con ellos.

## 2026-11-24 · Polvo de los pasos
- **Decisión:** a cada paso (`BodyBob.stepped`) sale un soplo pequeño de polvo a los pies (`StepDust`, 6 partículas en 0,45 s), un pie a cada lado de la marcha. Cuanto más rápido, más polvo: un 40 % de las partículas a la rapidez mínima y todas a la de carrera. Andando muy despacio, por debajo del 40 % de la carrera, nada. Solo sale con los pies en el suelo, porque `BodyBob` solo avisa de los pasos ahí.
- **Por qué:** lo pidió el diseñador para el final del Hito 5. Remata la sensación de correr del balanceo sin tapar nada.

## 2026-11-24 · Repaso de los comentarios
- **Decisión:** se reescriben las cabeceras de clase de 97 scripts (las de 5 o más líneas) para que se lean como escritas a mano: qué es y cómo se usa, en frases llanas y en 2–5 líneas, con muy pocas referencias de documentación (`[member …]`, `[code]…[/code]`). El detalle que ya está en `docs/MAPA.md` (qué señales escucha, qué variaciones del tema usa) sale de la cabecera. Quedan unas 260 líneas de comentario menos.
  - Solo cambian comentarios: un script compara cada archivo antes y después sin sus líneas de comentario y sin las vacías, y tienen que ser iguales.
  - Los comentarios de una línea de cada `@export` se quedan: son la ayuda del inspector. También los bloques largos dentro de las funciones que explican el porqué (por qué trepan los de atrás y no los de delante, por qué el veneno se cuenta en ticks…).
  - La norma queda en `CLAUDE.md` para el código nuevo.
- **Por qué:** lo pidió el diseñador. Las cabeceras largas, llenas de referencias, se leían como texto generado y escondían lo importante.

## 2026-11-24 · Pedidos tras las pruebas (3) (Hito 5d)
- **Decisión:** lo que pidió el diseñador tras probar otra vez.
  - **Deshacer la elección:** con «Quedármela» y «Doble o nada» a la vista, el clic derecho vuelve a la elección entre todas las cartas (`LevelUpPanel.cancel_bet`). El subtítulo lo recuerda. Antes, elegir una carta obligaba a quedársela o apostarla.
  - **Árboles en los trolls:** el hueco que el bosque guarda a los trolls de piedra baja de 18 a 7 m de radio (más los 2 m de margen del bosque). Siguen viéndose desde la pared, pero ahora en un claro pequeño rodeado de árboles, no en una explanada pelada.
- **Por qué:** lo pidió el diseñador tras probar.

## 2026-11-24 · Las pesas son santuarios de carga
- **Decisión:** las pesas de piedra del Brosque funcionan como los santuarios de carga de Megabonk (`ChargeShrine`). Quedarse dentro de su aro dorado las carga en 5 s de base. Al salir, la carga se queda donde estaba: no se pierde lo hecho, pero hay que volver. Cargadas, pausan y ofrecen 3 mejoras de stats distintas, cada una con su rareza; la elegida se suma a las stats del jugador para toda la partida. Se usan una vez.
  - **Mejoras:** diez stats posibles (`data/shrines/dumbbell.tres`), con su fuerza para una rareza rara: +8 % de daño, velocidad de ataque, área o experiencia; +5 % de velocidad; +15 de vida; +4 % de crítico; +5 de Suerte; +2 de defensa; +0,3/s de regeneración. La rareza sale de la misma tabla que las cartas, con la Suerte, y multiplica esa fuerza: una común da el 60 % y una mítica el 240 %. Las mismas `UpgradeStat` que usan armas y runas, así que el redondeo y las unidades son los de siempre.
  - **Cuántas:** las pesas bajan de 14 a 8, y todas son santuarios. Así cada pesa que se ve funciona y no salen demasiadas mejoras por partida.
  - **Riesgo:** cargar pide quedarse en un sitio con la horda alrededor. Por eso la carga no se pierde al salir: se puede ir y volver.
  - **Panel propio** (`StatChoicePanel`): no es un objeto, así que no va a la barra de objetos. Cada carta dice la stat, lo que suma y cómo queda («100 % → 108 %»).
- **Por qué:** lo pidió el diseñador. Las pesas eran solo decorado; ahora son una decisión más del mapa: ¿me paro aquí con la horda encima?

## 2026-11-24 · Hito 7: el plan acordado y los cofres de élite
- **Plan:** el diseñador cambió el Hito 7.
  - **Racha:** pasa a ser un power-up de 30 s, sin botín: mientras dura, matar seguido sube el multiplicador de oro, experiencia y Suerte, y un golpe lo baja.
  - **Pactos:** los ofrece un heraldo del Gremio que aparece cada 1000 enemigos derrotados.
  - **Apuntar:** mantener el clic derecho apunta con el ratón y el clic central fija al jefe como objetivo.
  - **Afijos de los élites:** solo en el tier 2 o más de cada nivel. Los tiers (Brosque tier 1, 2 y 3) se detallarán más adelante; van al Hito 6.
- **Cofres de élite:** todos los élites tienen un 10 % de soltar un cofre al morir (`EliteData.chest_chance`). Es un cofre normal: cuesta oro y sube el precio de los demás, como los del mapa. Los élites con afijos tendrán más probabilidad.
- **Por qué:** lo pidió el diseñador. Un cofre que cuesta oro sigue siendo una decisión; si se quisieran gratis, es otro `ChestData` en `EliteData.chest`.

## 2026-11-24 · Apuntar con el clic derecho y fijar al jefe con el central
- **Decisión:** las armas siguen siendo automáticas, pero el jugador puede decir adónde.
  - **Apuntar (mantener clic derecho):** sale una mira en el centro de la pantalla. Las armas eligen lo más cercano al punto del mundo que hay bajo la mira, no lo más cercano al jugador, pero siempre dentro de su alcance y viéndolo. Se apunta moviendo la cámara con el ratón, como siempre.
  - **Fijar (clic central):** fija el jefe vivo más cercano (también los minibosses) y le sale una marca roja encima. Todas las armas le disparan mientras esté a su alcance; si se aleja, vuelven a lo de siempre. Otro clic central lo suelta, y al morir se suelta solo.
  - **Dónde vive:** un nodo `Targeting` en el jugador. Cada arma lo consulta en `_candidates` (primero lo fijado, luego la mira y luego lo de siempre). Las armas de los enemigos no tienen `Targeting` y no cambian. El martillo elige el grupo más denso entre esos candidatos.
  - Son acciones del InputMap (`aim` y `lock_target`): se podrán cambiar cuando llegue el remapeo.
- **Por qué:** lo pidió el diseñador: con el jefe en pantalla, las armas se perdían en los esbirros de alrededor.
