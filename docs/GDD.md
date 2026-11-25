# Bro Guild — Documento de diseño

> Documento vivo: si el diseño cambia, se cambia aquí.
>
> **Temática: medieval con humor moderno** (definitiva). Los nombres que venían del casino ya están adaptados: botín, el Gremio, el tahúr, el torneo y «¿Retirarse o seguir?». Las tragaperras se quedan.

## 1. Pitch
Roguelike de hordas en 3D donde **moverte bien es dinero**: la velocidad alimenta tu racha, la racha multiplica tu oro y el oro se apuesta. Partidas de ~10 minutos, caos constante, reinicio instantáneo y el clásico "una más".

Referencias: **Megabonk** (bucle de hordas, builds rotas, cofres) y **Deadlock** (movilidad con stamina, dash-jump, slide).

## 2. Pilares
Si una idea no sirve al menos a uno, se descarta.
1. **Movimiento con techo alto** — se aprende en un minuto, se domina en semanas.
2. **Todo es una apuesta** — casi cada decisión es riesgo/recompensa, con anticipación y revelado.
3. **Caos legible** — cientos de enemigos y efectos, pero siempre sabes qué te ha golpeado y qué has ganado.
4. **Poder que se nota** — en 10 minutos pasas de esquivar a arrasar.

## 3. Bucle
| Escala | Qué haces |
|---|---|
| Segundos | Moverte (dash, slide, saltos); las armas disparan solas; recoges XP y el oro vuela solo hacia ti; rompes calaveras y bolsitas con E |
| Minutos | Subes de nivel (ruleta), abres cofres, juegas a la tragaperras, aceptas o rechazas pactos, cobras tu racha |
| Partida | Exploras el nivel juntando llaves; invocas al jefe en su portal (al minuto 10 se activa solo) → lo vences y cruzas el portal → **¿Retirarse o seguir?** |
| Entre partidas | Gastas el botín en desbloqueos y vuelves a entrar |

## 4. Movimiento
Cámara en tercera persona a una distancia moderada que crece muy poco a poco con el nivel del personaje: de un nivel a otro casi no se nota, pero hacia el nivel 100 sí hay diferencia (curva en datos). Correr es gratis; casi todo lo demás gasta **stamina** en cargas que se regeneran. Decidir cuándo gastar la última carga es la habilidad.

| Acción | Input | Stamina | Notas |
|---|---|---|---|
| Correr | WASD | — | Como en Deadlock: arrancas acelerando poco a poco y, tras unos segundos moviéndote sin soltar la dirección, pasas a **sprint**, algo más rápido. Mucho control aéreo; el momentum no se pierde de golpe |
| Salto | Espacio | — | Con coyote time y jump buffer |
| Doble salto | Espacio en el aire | 1 | Se recupera al tocar suelo; con mejoras o personajes, más saltos (triple salto). Con coyote time, Espacio es el salto normal |
| Dash | Shift | 1 | Ráfaga corta en la dirección de movimiento (sin dirección, hacia donde mira la cámara); también en el aire, donde va recto. En el suelo necesitas ir a una velocidad mínima (parado no hay dash). Al terminar conservas parte del impulso. Dashes totales = cargas de stamina; en el aire, como mucho los «dashes en el aire» (1 de partida, mejorable), que se recuperan al tocar suelo |
| Dash-jump | Espacio justo tras el dash | +1 | Ventana corta (con aviso visual: un aro dorado en los pies) → salto largo que conserva la velocidad del dash. Solo tras un dash en el suelo (también en dash → slide); pulsado al final del dash, sale al acabar. Sin stamina, Espacio es un salto normal |
| Slide | Ctrl corriendo (mantener) | — | Gratis; acelera cuesta abajo y frena cuesta arriba (en llano frena poco a poco); hurtbox baja (zona donde recibes daño). Empieza y sigue mientras vayas por encima de una velocidad mínima; termina al soltar Ctrl. Con WASD se curva hacia donde pides sin perder velocidad (como en Deadlock). Dash → slide alarga el dash sin gastar más: Ctrl en mitad de un dash en el suelo lo corta y sigue deslizando con la velocidad del dash (o mantén Ctrl al acabarlo). Si aterrizas con Ctrl mantenido y con velocidad, sigues deslizando sin perder impulso: dash → slide → slide-jump → slide |
| Slide-jump | Espacio en slide | — | Conserva el impulso |
| Caída rápida | Ctrl dos veces en el aire | 1 | El «dash hacia abajo»: picado recto al suelo hasta tocarlo (más rápido que la caída normal); con mejoras, impacto en área. Un solo Ctrl en el aire no hace nada (si aterrizas corriendo enseguida, empiezas a deslizar) |
| Salto en pared | Espacio en el aire junto a una pared | 0 / ½ | Al estilo de Deadlock: te impulsa hacia arriba y hacia donde pides, separándote de la pared (si pides hacia la pared, rebota); si ibas más rápido, conservas tu velocidad. El primero gratis; encadenados sin tocar suelo, media carga |
| Mantle | Saltar contra un borde | — | Sube bordes a media altura (de 0,3 a 2,6 m sobre los pies, en datos) con un pico de velocidad; con Ctrl sale deslizando. Funciona en el suelo y en el aire, hacia donde pides o, sin dirección, hacia la cámara |

**Reglas de entrada:** gana la primera acción que pulsas. Una acción empezada no se puede cancelar con otra hasta que termina; la excepción es el dash, que cancela cualquier acción (también otro dash) si quedan cargas. A su vez, el slide puede cortar un dash en el suelo para seguir deslizando con su impulso. Lo que pulsas durante una acción se guarda si falta muy poco para que termine (~0,1 s); si no, se pierde. Si Espacio puede hacer varias cosas a la vez, gana mantle > salto en pared > dash-jump > doble salto (orden en datos).

**Valores de partida** (viven en `data/player/movement.tres` y se ajustan jugando): 3 cargas; recarga de una carga cada ~3 s; dash de ~0,2 s.

**Arena al servicio del movimiento:** rampas para slides, bordes a media altura para mantle, paredes para saltos, desniveles y plataformas. Correr en llano debe ser la opción lenta.

**Objetivo de feel:** cruzar la arena de punta a punta en menos de 5 s con buena técnica; un jugador nuevo debe poder hacer un dash-jump en su primera partida.

## 5. Apuestas (el corazón del juego)
Toda apuesta tiene **anticipación** (giro, luces, sonido que sube), **revelado** claro por color y **coste creciente**: repetir nunca es gratis.

**Rarezas** (mismo color en todo el juego): Común (gris) · Rara (verde) · Improbable (azul) · De leyenda (amarillo) · Mítica (rojo). Pesos de partida 60/25/10/4/1; la **Suerte** sube el peso de las altas (cada punto, +1 / +2 / +3 / +5 % del suyo a rara, improbable, de leyenda y mítica).

1. **Ruleta de nivel** — al subir de nivel, 3 cartas giran como rodillos y caen en una rareza, una tras otra (con un tic-tic y una campanilla más aguda cuanto más rara); un clic las para todas; eliges una. Cada mejora dice cuánto ganas: la stat con su valor de ahora y el que queda («Daño 18 → 22»), igual en las cartas de objetos y en el revelado de los cofres.
   - *Volver a tirar:* otras 3 cartas por oro; cuesta 10 y ×1,5 con cada uso en la partida (10, 15, 23…).
   - *Doble o nada:* tras elegir una mejora que aún puede subir, «Quedármela» o «Doble o nada» (con el clic derecho se deshace la elección y se puede escoger otra carta): un 50 % sube una rareza (la mejora se vuelve a tirar con su fuerza) y si no, la pierdes y esa subida no da nada. La Suerte mejora las probabilidades sin llegar nunca al 100 % (con 200 de Suerte, un 75 %). Las míticas no se apuestan.
2. **Cofres** — repartidos por el nivel y soltados por élites. Abrirlos cuesta oro (sube con la dificultad y con cada cofre abierto en la partida). Revelado tipo "case opening": la luz recorre las rarezas antes de pararse. Dan **objetos pasivos** (§6).
3. **Tragaperras** — máquinas repartidas por el nivel (también en sitios a los que hay que subir). Pagas oro (sube con la dificultad y cada vez que usas esa máquina) y giran 3 rodillos sin pausar el juego. Cada máquina aguanta 5 tiradas y luego revienta. Símbolos: moneda (pareja: oro ×2 de lo pagado; trío: ×10), corazón (cura un 30 %; trío: vida al máximo), estrella (pareja: eliges una mejora como al subir de nivel, con el título «¡Mejora gratis!»; trío: sube un nivel todas tus armas y runas, cada una con un texto del color de la rareza que le sale) y calavera, la **maldición** (pareja: −20 % de vida máxima un minuto; trío: cinco élites). Sin dos iguales, nada. El trío (jackpot) va con cámara lenta.
4. **Racha** (un power-up de 30 s) — mientras dura, matar seguido sube la racha (×1 → ×2 → ×3 → ×5), que multiplica el oro, la experiencia y la Suerte. Si te golpean, baja un nivel. Sin botín: lo ganado es tuyo al momento.
5. **Pactos del Gremio** — cada 1000 enemigos derrotados aparece un heraldo del Gremio cerca de ti, con una columna de luz morada, un aviso y una flecha que lo señala. Si vas a hablar con él, te ofrece 3 pactos: un premio a cambio de una maldición, los dos para el resto de la partida (p. ej. «Ego lifting»: +30 % de daño y −25 % de vida máxima; «All in»: +30 de Suerte y +4 de dificultad). Los valores de cada pacto son fijos. Eliges uno, pagas oro por otros 3 (10, ×1,5 cada vez en la partida) o los rechazas, y se va. Si no vas, te espera hasta que llega el siguiente.
6. **¿Retirarse o seguir?** — al vencer al jefe: *Retirarse* termina la partida y guarda el botín. *Seguir* abre el siguiente torneo, más duro, con el botín ×2; si mueres ahí, te llevas solo la mitad.

**Stats mejorables:** como en Megabonk, cualquier stat del personaje se puede subir o bajar con mejoras, rasgos de personaje y maldiciones: velocidad de carrera, altura de salto, control aéreo, stamina, daño… Una stat nueva es mejorable desde que existe.

**Mejoras con sinergia de movimiento:** objetos pasivos que convierten el movimiento en ataque. Sin ellos, el movimiento no daña; cada copia suma su daño. Pasan por el daño % y el crítico del jugador y crecen con su área %.
- **Zapatillas en llamas** (rara): el slide deja un rastro de fuego. Lo que lo pisa se quema cada medio segundo (8 por quemadura), una sola vez aunque pise varias manchas. Cada mancha dura 3 s. Escala con tus stats como un arma: el daño % y el crítico, el área % (manchas más grandes), la duración % (duran más) y la velocidad de ataque % (quema más a menudo).
- **Bocina de estadio** (rara): cada dash suelta una onda de 4,5 m que daña (24) y empuja.
- **Cinturón de campeón** (improbable): la caída rápida explota al aterrizar: una onda de 5,5 m que daña (40), empuja fuerte y hace temblar la pantalla.

Más ideas para después: más daño mientras estás en el aire · cada carga de stamina sin gastar da crítico extra.

**Objetos con efectos al golpear:** además de stats, algunos objetos tienen una probabilidad de hacer algo con cada golpe. Cada copia suma su probabilidad. El daño del efecto sale de lo que quitó el golpe, así que escala con todo lo que lo sube (daño %, crítico, arma), y no vuelve a disparar efectos. Sus números de daño van de su color.
- **Pre-entreno caducado** (rara): 15 % de envenenar. El veneno quita un 10 % del golpe cada medio segundo durante 3 s (un 60 % en total); envenenar otra vez lo alarga.
- **Cable pelado** (improbable): 12 % de soltar un rayo que salta a los 3 enemigos más cercanos (a menos de 6 m de uno a otro) con la mitad del golpe.
- **Spray de frío** (rara): 20 % de frenar al enemigo un 40 % durante 2 s.

**Mejoras que tocan el azar** (ejemplos): Dado trucado (1 reroll gratis por nivel) · Amigo del tahúr (las maldiciones de la tragaperras a veces son premio) · Mano caliente (cofres más baratos con racha alta).

## 6. Combate
- **Armas automáticas** (como en Megabonk o Vampire Survivors): atacan solas al objetivo más cercano o al grupo más denso que vean (no disparan a lo que hay detrás de un árbol o una pared); tú te centras en moverte. Ranuras: 4 de armas y 4 de runas, hasta nivel 10 las armas y 20 las runas; al empezar solo hay 2 de cada abiertas y las otras 2 se desbloquearán (cómo, por decidir; en el HUD se ven cerradas). Todo en datos.
- **Armas iniciales**:
  - **Espada** (cuerpo a cuerpo): la cantidad de proyectiles también le afecta (más tajos).
  - **Bastón de mago**: proyectiles que explotan al contacto, con daño en área.
  - **Daga**: proyectil rápido que da a un solo enemigo. Su **rebote** hace saltar el golpe con todo su daño al enemigo más cercano, hasta una distancia máxima: empieza con 2 y sus mejoras lo suben.
  - Las armas de proyectiles (bastón y daga) también pueden mejorar la **velocidad de su proyectil** al subir de nivel.
- **Más armas** (salen al subir de nivel):
  - **Hacha arrojadiza**: sale girando hacia el enemigo, corta a todos los que pilla a su paso (también a los que pasan cerca de su filo) y vuelve a tu mano cortando otra vez; si choca con una pared, vuelve antes. Arma de media distancia contra filas de enemigos.
  - **Nube de colonia**: un aura de spray corporal a tu alrededor; cada poco, un pulso daña y aparta a todos los que tienes encima. Sus proyectiles extra son más pulsos y crece con el área. Su alcance se dibuja en el suelo, un aro que gira despacio y se ilumina con cada pulso. Brilla en la horda; sola, no hace nada.
  - **Martillo de guerra**: cae del cielo sobre el grupo de enemigos más apretado a su alcance (un aro avisa dónde) y aplasta a todos los de debajo. Lento y con mucho daño; sus proyectiles extra son más martillos sobre otros grupos.
- **Runas** (pasivas): suben stats principales con cada nivel: Fuerza (daño) · Amplitud (área) · Prisa (velocidad de ataque) · Vigor (vida máxima) · Multiplicidad (cantidad de proyectiles, también para armas cuerpo a cuerpo; con decimales: +1 la común, +1,2 la rara, +1,5 la improbable, +1,8 la de leyenda y +2,2 la mítica, y la parte decimal es la probabilidad de un proyectil más en cada ataque). Las cartas comunes mejoran poco y la rareza es lo que más pesa: una común da ×0,6 de la mejora base; una rara, ×1; improbable, ×1,4; de leyenda, ×1,8, y mítica, ×2,4.
- **Objetos de la partida** (aparte de armas y runas):
  - *Pasivos:* como los objetos de Megabonk. Salen de cofres y del jefe, tienen rareza, no ocupan ranura y se apilan: cada copia suma su efecto (+% daño, robo de vida, más oro…). Van de cultura bro en general (el gimnasio es un tema más): batido de proteínas, pizza fría de ayer, riñonera, mando de consola, gorra hacia atrás, chanclas con calcetines, rasca y gana, altavoz portátil, gafas de sol, aceite corporal, cinturón de levantar, mancuerna de oro, batido sospechoso (más daño y más dificultad), cadena de oro y la corona del Bro. Y medievales: herradura, hogaza de centeno, jarra de hidromiel, capa de viaje, antorcha, ballesta de bolsillo, grial de latón y Excalibro.
  - *Power-ups del suelo:* imán (atrae toda la experiencia del mapa), comida (cura), bomba (daño a todo lo cercano) y bebida energética (más velocidad, velocidad de ataque y daño durante unos segundos). Al cogerlos sale un texto breve: «¡Succión activada!» (imán), «¡Pollito ñam ñam!» (comida), «¡Nuclear activada!» (bomba) y «¡Modo diablo activado!» (bebida). El reloj de arena para el tiempo 5 s: los enemigos y sus disparos se quedan quietos (se les puede seguir golpeando) y la pantalla se tiñe de azul («¡Tiempo detenido!»). La llama es la racha (30 s, «¡En racha!»): ver §5. Cada uno se ve al cogerlo: la bomba es una explosión nuclear (destello, bola de fuego, hongo de humo y una onda hasta donde llega su daño), el imán tira chispas hacia ti, la comida suelta chispas verdes, la bebida un estallido y el reloj de arena una onda azul que lo congela todo. Salen de una tabla de botín con la **probabilidad de botín** (stat del jugador, muy baja: 0,5 % por enemigo normal), que multiplican los élites (×8) y los rompibles (×12). Más adelante, la misma tirada podrá dar cofres.
  - *Llaves del jefe:* repartidas por el nivel, lejos de donde apareces, con una columna de luz que se ve de lejos; se cogen con «interactuar». Con las suficientes se puede invocar al jefe antes de tiempo (§9). En el Brosque son tarjetas de socio: hay las justas, 3.
- **Rompibles** (como los jarrones de Megabonk): calaveras que sueltan experiencia y bolsitas que sueltan oro, repartidas por el nivel. Se rompen **con «interactuar» (E)**, no con ataques: premian moverse por el mapa y pararse un instante.
- **Subir de nivel**: eliges 1 de 3 opciones (arma o runa nueva, o subir una que ya tengas). Cada mejora tiene **rareza**, que se ve en el color del borde de la carta: común (gris), rara (verde), improbable (azul), de leyenda (amarilla) y mítica (roja). Cada arma tiene varias stats que puede mejorar (la espada: daño, cantidad, área y velocidad de ataque) y la rareza decide cuántas toca y cuánto: una común, una; las raras, varias; la mítica, todas, y más fuertes. La ruleta de apuestas (§5) se monta encima de esta elección.
- **Enemigos** (salen del suelo con un poco de polvo; los jefes, más despacio): enjambre cuerpo a cuerpo (rápido, frágil) · tanque lento · tirador a distancia (te obliga a moverte) · raros: el Cardioadicto (aún más rápido y frágil) y el Murciébro (vuela a la altura de la cabeza: saltar por encima de la horda no es gratis) · minibosses (entre hordas, §9) · jefes (uno por nivel, §9) · élites: cualquier enemigo puede salir élite, con una probabilidad que sube con los minutos (más grande, más vida y daño, suelta más experiencia y oro, y a veces un cofre); en el tier 2 y más, con afijos.
- **Empuje:** los golpes empujan. Cada arma tiene el suyo (la espada, más; la daga, poco), que multiplica el retroceso del personaje (mejorable). Los enemigos empujan al jugador al tocarle con un empuje fijo; el Ent-renador, mucho al embestir y con su onda. A los enemigos pesados (élites, jefes) se les mueve menos.
- **Cuerpos de los enemigos** (como en Megabonk): chocan con el mundo, con el jugador y entre ellos, y no se hacen daño entre ellos. El jugador no los atraviesa: le bloquean, le dañan al tocarle y puede saltar y quedarse de pie encima. Cuando se atascan, los de atrás trepan sobre los de delante: alrededor del jugador forman un montículo y, si está en alto, se apilan para alcanzarlo. Si lo que les tapa el paso es el escenario (unas pesas, un tronco, un muro bajo), trepan por encima.
- **Dificultad y director de oleadas**: la **dificultad** es una stat que sube sola (1 por minuto) y también con objetos o runas: **más riesgo, más recompensa**. De ella dependen cuántos enemigos salen, cuáles, cuántos élites y lo fuertes que son (vida y daño), todo en curvas de datos; los picos de cada minuto van por el reloj. También sube lo que sueltan los enemigos (experiencia y oro), las calaveras y las bolsitas. La ronda normal dura 10 min: hacia la dificultad 10 los enemigos se disparan (hace falta buena build para aguantar un poco) y en el minuto 10 el altar del jefe se activa solo. **Hordas:** en minutos marcados de la ronda (en el Brosque, el 3 y el 6) llega una horda grande alrededor del jugador durante 30 segundos, avisada unos segundos antes con un cuerno y un texto.

**Stats del personaje** (como en Megabonk o Vampire Survivors; todas mejorables, §5). Valores de partida en `data/player/`. Ya funcionan vida, regeneración, defensa, esquiva, daño y crítico; el resto de fórmulas son la intención de diseño y se confirman al implementar armas y enemigos (Hito 2). Al recibir un golpe, primero se tira la esquiva y luego la defensa reduce lo que entra. Tras un golpe que hace daño, el jugador es invulnerable 0,3 s (su modelo parpadea).

| Grupo | Stat | De partida | Efecto |
|---|---|---|---|
| Supervivencia | Vida máxima | 100 | |
| | Regeneración de vida | 0 /s | Vida por segundo |
| | Defensa | 0 | Daño recibido × 100 / (100 + defensa): 100 de defensa = mitad de daño, nunca inmune (ese 100 está en `data/combat/rules.tres`) |
| | Esquiva | 0 % (máx. 90 %) | Probabilidad de evitar un golpe entero |
| | Robo de vida | 0 % | Parte del daño hecho que te cura |
| Ataque | Daño | 100 % | Multiplica el daño de todas las armas |
| | Probabilidad de crítico | 5 % (máx. 100 %) | |
| | Daño crítico | 150 % | Un crítico hace este % del golpe |
| | Velocidad de ataque | 100 % | Divide el tiempo entre ataques de cada arma |
| | Proyectiles extra | 0 | Se suman a los de cada arma |
| | Velocidad de proyectil, área, duración, retroceso | 100 % | Multiplican lo de cada arma |
| Progresión | Experiencia ganada, oro ganado | 100 % | |
| | Suerte | 0 | Sube el peso de las rarezas altas (con 100, la mítica pasa del 1 al 3,7 %) |
| | Radio de recogida | 3 m | Distancia a la que se recoge el botín |
| | Dificultad | 0 (+1 por minuto) | Enemigos más numerosos y fuertes, más botín de los rompibles (sube con objetos o runas) |
| | Probabilidad de botín | 0,5 % | Que un enemigo normal suelte un power-up (o, más adelante, un cofre); ×8 los élites y ×12 los rompibles |
| Movimiento | Velocidad de carrera, saltos y dashes en el aire, stamina… | ver §4 | |

Las mejoras de % («+10 % de daño») multiplican; las de puntos («+5 % de crítico», «+1 proyectil», «+1 salto en el aire») suman.

## 7. Estética: sencilla pero llamativa
Dirección: **medieval con humor moderno**, nada realista; los anacronismos son bienvenidos (p. ej., tragaperras repartidas por un mundo medieval). Formas simples (primitivas o low-poly) que luzcan sin necesitar artista. Luz de antorchas y faroles: cálida, con brillos de color donde hay algo que apostar o recoger (sustituye a la anterior «casino-arcade neón»).
- **Color con significado**: cada tipo de enemigo con su color; las rarezas, iguales en cofres, cartas, números y luces.
- **Juice**: polvo pequeño a cada paso al correr (más cuanto más rápido) · screen shake por trauma al recibir daño · borde rojo al recibir daño y con poca vida (late como un corazón) · números de daño (críticos grandes y dorados) · destello blanco y sutil al golpear (sin parón) · explosión de monedas al matar · partículas: humo del color del enemigo al morir, chispas al golpear, restos al romper, destellos dorados al abrir un cofre y polvo cuando una onda golpea el suelo · imán de pickups · estela en dash y slide · balanceo al andar (el cuerpo rebota a cada paso y se mece, más cuanto más rápido vas) · FOV que se abre con la velocidad y líneas de velocidad · cámara lenta en el jackpot.
- **Sonido**: efectos sintetizados de estilo arcade (recetas en datos). La experiencia recogida seguida sube de tono, hasta una octava. Más adelante, la racha subirá el pitch de todo y los rodillos harán tic-tic-tic al frenar.
- **UI**: tipografía gruesa, animada con tweens, legible en mitad del caos.
- **Assets**: primitivas + shaders propios; si hace falta, packs CC0 (Kenney, Quaternius).

## 8. Controles
WASD mover · Ratón cámara · Espacio saltar · Shift dash · Ctrl slide (doble Ctrl en el aire: caída rápida) · E interactuar / cobrar · Tab estadísticas (mientras se mantiene, sin pausar; la rueda las desplaza) · Clic derecho (mantener) apuntar: las armas van a por lo que hay en la mira, en el centro de la pantalla · Clic central fijar al jefe (o al miniboss) como objetivo: todas las armas le disparan mientras esté a su alcance; otra vez, lo suelta · Esc pausa · R reintentar (en los resultados). Todo remapeable.

**Menú de pausa (Esc):** a la izquierda, Continuar, Opciones, Reintentar y Salir; a la derecha, un panel fijo con todas las stats del personaje, resaltando las que han cambiado mejoras o maldiciones. Mando: más adelante.

## 9. Partida y progresión
- **Ronda**: ~10 min (dificultad normal; nivel ~30 al minuto 10 si se mata casi todo). Élites por probabilidad, cada vez más a menudo.
- **Jefe**: cada nivel tiene el suyo en un **portal**. Se invoca con las llaves del nivel cuando te veas fuerte; al minuto 10 el portal se activa solo. Vencerlo antes da más recompensa. Mientras tanto siguen las oleadas (desde el minuto 10, la prórroga, muy fuertes), y no paran al vencerlo. Sale más fuerte cuanto más alta esté la dificultad.
  - *Pasar el nivel:* al vencer al jefe, su portal se abre (dorado), un texto dice que hay que cruzarlo y una flecha amarilla lo señala unos 3 s. Cruzarlo gana la partida (o, si quedan tiers, lleva al siguiente). Si mueres en la prórroga con el jefe ya vencido, también cuenta como victoria (solo en el último tier de la partida).
- **Tiers**: cada nivel tiene 3. Se elige en la selección de nivel; el tier 1 está siempre abierto y superar uno abre el siguiente. Elegir el tier 2 es jugar el 1 y, al cruzar su portal, pasar al 2 (y así con el 3): con un fundido, el mismo nivel se genera de nuevo, distinto, y conservas todo (nivel, armas, runas, objetos, oro y pactos). El reloj vuelve a 0 (miniboss y jefe a su hora), el mapa es más grande y la dificultad sube.
  - *El Brosque:* tier 1, verano (paredes a 110 m); tier 2, otoño (130 m, dificultad +10: hierba ocre, árboles naranjas, rojos y amarillos, luz baja y cálida y hojas que caen); tier 3, invierno (150 m, +20: nieve, pinos oscuros y árboles blancos, charcos helados, niebla fría y nieve que cae). Cada tier reutiliza las mismas piezas con los colores de su estación, para que el juego no crezca.
  - *Jefe final:* tras el portal del tier 3, la arena del jefe final (la misma para todos los niveles): un claro del Brosque al atardecer, con ruinas en círculo, donde solo está el jefe. Al vencerlo aparece el portal y la partida ya es una victoria, pero no se acaba hasta que cruzas el portal o mueres en la oleada infinita que empieza entonces.
  - *Mr. Brolympia* (jefe final del Brosque): el entrenador del Ent-renador, un Ent más grande con la copa naranja, camiseta negra y cinturón de campeón dorado, que lleva una pesa de piedra. Hace los ataques del Ent-renador, más fuertes, y el *Peso muerto*: levanta la pesa y la estampa como el porrazo del Trolleador.
  - *Premio:* oro por un multiplicador que baja con los minutos (×3 al empezar, ×1 desde el minuto 10) y un objeto pasivo de rareza alta (improbable o más), revelado en el HUD. Luego, la pantalla de victoria con las estadísticas y el premio por rapidez. Hasta que exista «¿Retirarse o seguir?» (Hito 8), la partida termina ahí.
  - *El Ent-renador* (jefe del Brosque): un árbol enorme vestido de entrenador personal (polo, cinta en la frente y silbato), con su barra de vida en el HUD. Los jefes no hablan. Su portal está al borde del claro. Ataques: *Burpee* (se agacha, salta adonde estabas —un aro marca dónde cae— y suelta una onda por el suelo que se esquiva saltándola o alejándote), *Series* (apunta con una franja en el suelo y embiste en línea recta tres veces) y *Bro-tes* (llama a unos arbolitos rápidos y frágiles que te persiguen). Por debajo de la mitad de su vida entra en rabia: más rápido, ataca más a menudo y llama más Bro-tes.
- **Minibosses**: entre las hordas, un enemigo grande con su barra de vida (debajo de la del jefe si coinciden, sin taparse), avisado unos segundos antes. Sale cerca del jugador, más fuerte con la dificultad, y no termina la ronda. Al vencerlo: oro y un objeto pasivo (de rara a de leyenda) revelado en el HUD.
  - *El Trolleador Cara* (miniboss del Brosque, a los 4:30): un troll jorobado con porra y una sonrisa de trollface. Ataques: *Porrazo* (se planta y levanta la porra mientras un aro marca hasta dónde llega y otro se va abriendo desde sus pies; cuando llega al borde, el golpe daña todo lo de dentro: hay que salir a tiempo) y *Salto* (como el Burpee, más corto). Con poca vida, rabia: más rápido y ataca más a menudo.
  - *Los trolls de piedra*: fuera de la pared este del Brosque, dos trolls como él se quedaron de piedra al amanecer alrededor de su olla (el guiño a El Hobbit). Solo decorado; están en un claro pequeño, rodeados de árboles.
- **Monedas**: XP (niveles) · Oro (en partida, se apuesta; lo suelta cada enemigo y llega solo al matarlo) · Bro-monedas (salen de la partida y se gastan fuera: 1 por élite y 5 por jefe; se guardan al acabar, ganes o pierdas).
- **Meta-progresión**: desbloquear personajes (cada uno con un rasgo de movimiento: triple salto, dash más largo, slide más rápido…), armas iniciales y ventajas pequeñas. Nunca más poder bruto que el que da jugar bien.
- **Personajes**: todos parten de las mismas stats básicas y cada uno cambia unas pocas según su gimmick (p. ej., +1 salto en el aire y −10 % de vida). Esas diferencias son su base: en el menú no salen como mejoras. Cada uno tiene un arma principal y una habilidad pasiva. Iniciales:

  | | Guerrero | Mago | Pícaro |
  |---|---|---|---|
  | Arma inicial | Espada | Bastón de mago | Daga |
  | Stats | +30 vida, +5 defensa, −5 % velocidad | −20 vida, +15 % área, +10 % experiencia | −10 vida, +10 % velocidad, +10 % crítico, +1 carga de stamina |
  | Movimiento | Dash un 30 % más largo | Planea manteniendo el salto (cae como mucho a 3 m/s) | +1 salto en el aire, con un mortal hacia delante |
  | Regeneración | 0,8 de vida/s | 0,4 de vida/s | 0,5 de vida/s |
  | Pasiva (crece con cada nivel) | **Veterano**: +1 % de daño por cada nivel | **Expansión arcana**: +1 % de área por cada nivel | **Letal**: +1 % de probabilidad de crítico por cada nivel |

- **Menús**: al iniciar, menú principal con Jugar, Opciones, Récords, Archivo y Abandonar (cierra el juego). En Opciones, además del sonido y la pantalla, un límite de FPS (de serie, 60): el juego no dibuja más fotogramas de los que hacen falta.
  - *Récords:* las 10 mejores partidas jugadas en este equipo, ordenadas por enemigos derrotados: con qué personaje, enemigos, tiempo, nivel alcanzado, mapa y si fue victoria o derrota. La última partida sale en azul y, al acabar una, los resultados dicen su puesto si entró.
  - *Idioma:* abajo a la izquierda del menú principal, pequeño, un globo con el idioma actual (cada uno con su nombre en su idioma: Español, English). El juego empieza en español.
  - *Jugar* → selección de personaje: lista a la izquierda, su modelo 3D en el centro y, al pasar el ratón, un panel a la derecha con nombre, stats, arma principal y habilidad pasiva. Al elegir, ese panel se cambia por la selección de nivel.
  - *Pesas de piedra (santuarios de carga, como en Megabonk):* hay ocho por el Brosque, cada una con un aro dorado en el suelo y una luz. Quedarse dentro del aro las carga (5 s de base; si sales, la carga se queda donde estaba). Cargadas, ofrecen elegir una de tres mejoras de stats distintas (daño, vida, velocidad de ataque, crítico, área, velocidad, Suerte, defensa, regeneración o experiencia), cada una con su rareza: la Suerte sube las altas y la rareza da la fuerza. Se usan una vez. Quedarse quieto con la horda cerca es el riesgo.
  - *Círculo de setas:* hay tres por el Brosque, con una luz morada. Al entrar te ofrece elegir uno de tres objetos pasivos (la Suerte ayuda) y se apaga: una sola vez cada uno.
  - *Taberna:* en el centro de una pared del borde del Brosque, sin poder entrar. Al acercarte, «interactuar» te cura la mitad de la vida por oro, cada vez más caro (y más con la dificultad).
  - *Niveles*: el Brosque (en inglés, the Brorest), la Torre del Mago y la Mazmorra. El Brosque es un **gimnasio en el bosque**: bosque low-poly de colores vivos con humor (rocas con forma de pesas, troncos-banco, carteles de «No pain, no gain») y ruinas pequeñas de piedra con musgo (un templo de columnas, muros rotos y arcos) que le dan el toque medieval, y charquitos de agua con una flor (solo decorado), tragaperras entre los árboles y mesetas para moverse en vertical. Su borde es una pared de malla que solo se ve al acercarte. Si saltas dentro de la copa de un árbol, caen unas hojitas de su color. Empieza sencillo y gana detalles con el tiempo.
  - *Archivo*: personajes, armas, runas, objetos y enemigos, con cuántos llevas descubiertos de cada tipo. Un personaje se descubre al jugar con él; un arma, una runa o un objeto, al conseguirlo; un enemigo (también el jefe), al derrotarlo. Mientras tanto sale como «?» con una pista; descubierto, enseña su ficha con lo que hace.
- **Reinicio**: de la muerte a una partida nueva en menos de 2 s (en el mismo tier).

## 10. Fuera de alcance por ahora
Multijugador · historia · consolas. (Los mapas ya se generan: el Brosque cambia cada partida.)

## 11. Decisiones abiertas
- Ninguna ahora mismo. (Los nombres del casino ya están adaptados: bote → botín, La Banca → el Gremio, crupier → tahúr, mesa → torneo, «¿Cobrar o Doblar?» → «¿Retirarse o seguir?» y estética neón → antorchas y faroles.)
