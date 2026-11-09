# ROADMAP

- La tarea actual es la **primera casilla sin marcar**. Claude la marca `[x]` al terminarla.
- Cada hito acaba con algo jugable. **Hecho** = validación sin errores + lo he probado y me convence.
- Si una tarea es grande, se parte aquí en subtareas antes de empezarla.
- Los nombres que vienen del casino (fichas, La Banca, mesa…) están pendientes de adaptar a la temática medieval (GDD §11).

## Hito 0 — Cimientos
- [x] Proyecto Godot 4.7 (Forward+) con `.gitignore` y `.gitattributes`; git y GitHub funcionando (push y PR)
- [x] Comandos de Godot verificados y anotados en `CLAUDE.md`
- [x] Estructura de carpetas de `CLAUDE.md`
- [x] Autoloads tipados: `EventBus`, `RunState`, `Rng` (con semilla)
- [x] InputMap con todas las acciones del GDD y capas de física con nombre
- [x] GUT instalado con un test de ejemplo que pase
- [x] Escena de pruebas en gris: suelo, rampas, bordes, paredes y plataformas
- [x] `docs/DECISIONES.md` con las primeras decisiones

## Hito 1 — Movimiento (si no se siente bien, no se avanza)
- [x] `StatBlock` + `StatModifier` (con tests): los parámetros de movimiento se leen como stats, para que mejoras y personajes los modifiquen
- [x] Jugador (`CharacterBody3D`) y cámara en tercera persona con ratón (distancia que crece con el nivel, curva en datos; interpolación de física activada); Esc suelta el ratón (aún sin menú de pausa)
- [x] Máquina de estados + `data/player/movement.tres` (gana la primera acción; nada se cancela salvo con el dash)
- [x] Correr, saltar, coyote time, jump buffer y control aéreo
- [x] Panel de depuración con F3 (velocidad, estado, suelo/coyote y nivel de la cámara; cada sistema nuevo añade lo suyo), con las stats modificables como haría una mejora
- [x] Textos traducibles (CSV en `data/i18n/`, español e inglés) y `Theme` global, antes del primer HUD
- [x] Menú de pausa (Esc): continuar, opciones (aún sin función), reintentar y salir, con un panel fijo de todas las stats del jugador (con scroll)
- [x] Stamina por cargas + HUD mínimo
- [x] Dash (suelo y aire), picado (doble Shift en el aire sin dirección) y doble salto
- [x] Slide con pendientes y slide-jump
- [x] Dash-jump con ventana y aviso visual
- [x] Cancelar el dash con un slide (solo en el suelo), que sigue con la velocidad del dash
- [x] Salto en pared al estilo Deadlock (el primero gratis; encadenados sin tocar suelo, media carga)
- [ ] Caída rápida (Ctrl en el aire)
- [ ] Mantle (subir bordes a media altura; con Ctrl sale deslizando)
- [ ] Sensación de velocidad: FOV dinámico, estela de dash, líneas de velocidad

## Hito 2 — Combate en la zona de pruebas
- [x] Stats de combate y progresión del personaje en datos (vida, regeneración, defensa, esquiva, robo de vida, daño, crítico, velocidad de ataque, proyectiles, área, duración, retroceso, experiencia, fichas, suerte, radio de recogida), visibles en la pausa y en F3
- [x] Personajes en datos: stats básicas comunes y cada personaje con sus diferencias (`data/characters/`; de momento solo el personaje base)
- [ ] Vida, daño y muerte: `HealthComponent`, `HitboxComponent`, `HurtboxComponent` con las fórmulas del GDD (defensa, esquiva, crítico); hurtbox baja en el slide
- [ ] Armas: `WeaponData` (stats del arma y mejoras por nivel) y base de arma automática (cadencia y objetivo); la espada (cuerpo a cuerpo)
- [ ] Enemigo cuerpo a cuerpo con `EnemyData`, steering simple y pooling; barra de vida en el HUD
- [ ] Director de oleadas en la zona de pruebas (curva en datos) y escena de estrés con 300 y 500 enemigos y fps medidos (se repite al cerrar cada hito)
- [ ] Experiencia: gemas atraídas por el radio de recogida, niveles con curva en datos (la cámara ya se aleja con el nivel)
- [ ] Subir de nivel: elegir 1 de 3 entre armas y runas nuevas o mejorarlas; 4 ranuras de armas y 4 de runas, nivel máximo 5
- [ ] Runas: `RuneData` (modificadores por nivel) y las 5 iniciales: Fuerza (daño), Amplitud (área), Prisa (velocidad de ataque), Vigor (vida) y Multiplicidad (cantidad de proyectiles)
- [ ] Bastón de mago (proyectiles que explotan al contacto con daño en área) y daga (proyectil rápido a un objetivo; sus mejoras pueden subir su rebote, que da todo el daño al enemigo más cercano dentro de una distancia máxima)
- [ ] Segundo enemigo (tirador a distancia)
- [ ] Muerte, resultados y reinicio rápido; HUD de experiencia, nivel y tiempo
- [ ] Personajes iniciales: Guerrero (espada), Mago (bastón) y Pícaro (daga), cada uno con sus diferencias de stats y su habilidad pasiva

## Hito 3 — Menús y flujo de partida
- [ ] Escena raíz `Game` con el flujo de pantallas; `RunState` guarda personaje, nivel y semilla; «Salir» de la pausa vuelve al menú
- [ ] Menú principal: Jugar, Archivo y Abandonar (cierra el juego)
- [ ] Selección de personaje: lista a la izquierda, modelo 3D en el centro, a la derecha (al pasar el ratón) nombre, stats, arma principal y habilidad pasiva
- [ ] Selección de nivel (sustituye al panel de info al elegir personaje): el Brosque, la Torre del Mago y la Mazmorra (de momento, los tres cargan la zona de pruebas)
- [ ] Catálogo de contenido (`data/content.tres`) y `Save` con desbloqueos persistentes
- [ ] Archivo: personajes, armas, runas y enemigos; se desbloquean al conseguirlos o al derrotar al enemigo («???» mientras tanto)

## Hito 4 — Apuestas v1
- [ ] GDD adaptado a la temática medieval (pendientes de §11)
- [ ] `WeightedTable`, rarezas en datos y Suerte (tests con semilla)
- [ ] Ruleta de nivel: las 3 opciones de subir de nivel giran como rodillos; reroll de coste creciente
- [ ] Doble o nada sobre la opción elegida
- [ ] Cofres con coste creciente y revelado de rareza
- [ ] Más armas y runas en `.tres` (3 con sinergia de movimiento)
- [ ] Pantalla de estadísticas (Tab), reutilizando la lista de stats de la pausa

## Hito 5 — Juice y look
- [ ] Entorno según la dirección visual del GDD (luz, glow y tonemapping)
- [ ] Materiales con color propio por tipo de enemigo y rareza
- [ ] Hit-stop, screen shake, flash y números de daño
- [ ] Partículas: muertes, fichas, cofres, impactos
- [ ] Sonidos con tono creciente y UI animada
- [ ] Rendimiento: 300+ enemigos a 60 fps

## Hito 6 — Niveles
- [ ] El Brosque (bosque bro)
- [ ] La Torre del Mago
- [ ] La Mazmorra

## Hito 7 — La mesa de juego
- [ ] Racha y bote (niveles, multiplicador, cobrar, perder al ser golpeado)
- [ ] Tragaperras repartidas por el mapa
- [ ] Pactos de la Banca
- [ ] Élites con afijos que sueltan cofres

## Hito 8 — Cierre de partida y meta
- [ ] Jefe "La Banca" al minuto 10
- [ ] ¿Cobrar o Doblar? y mesas siguientes
- [ ] Resumen de partida
- [ ] Desbloqueos (personajes, armas, ventajas) y condiciones para conseguirlos
- [ ] Opciones (sensibilidad, volumen, remapeo)

## Backlog (sin orden)
- Raíles/ziplines y plataformas de salto
- Más armas, enemigos y personajes con movimiento propio
- Nuevas arenas; generación procedural
- Retos diarios con semilla compartida
- Soporte de mando
- Actualizar a Godot 4.8 cuando sea estable
