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
