# Tienda para niños con interfaz responsive (Roblox)

Pieza 2 del portafolio. Una tienda dentro de un taller de juguetes: catálogo de 10 juguetes en 3 categorías, compra con las monedas del juego, y una interfaz que se adapta a celular, tableta, PC y mando.

**Cómo se hizo:** el código se desarrolla dirigiendo a Claude (IA) y se verifica con pruebas en Roblox Studio. No está escrito a mano.

**Estado:** construida y revisada por lectura; las pruebas en Studio están en la sección "Qué está probado y qué no".

## Qué hace

- **Catálogo:** 10 juguetes en 3 categorías (De cuerda, Bloques, Peluches), cada uno con precio, descripción corta y una vista previa en 3D que gira despacio. Se empieza con 300 monedas.
- **Comprar:** un toque o clic elige un juguete y muestra su detalle; un segundo toque (o el botón "¡Lo quiero!") lo compra. Es igual con mouse, dedo y mando, para evitar compras por accidente.
- **Ganar monedas:** ocho fichas doradas repartidas por el taller (15 monedas cada una). Vuelven a aparecer solas a los 20 segundos. Sin tiempos que apuren.
- **Pensado para niños:** botones y textos grandes, avisos amables que explican qué hacer ("Te faltan 40 monedas. ¡Junta fichas por el taller!"), sin cuentas regresivas, ofertas falsas, cajas de azar ni avisos que den culpa. Todo se compra solo con las monedas del juego.
- **Animaciones suaves:** la ventana aparece con un rebote corto, las tarjetas entran una tras otra, se levantan al enfocarlas (cursor, toque o mando), saltan al comprar, el contador de monedas cuenta, y dos engranajes tenues giran muy despacio de fondo. Una opción de **menos movimiento** apaga los saltos, giros y engranajes.
- **Sonidos suaves:** dos sonidos de volumen bajo (al recoger una ficha y al comprar), con un interruptor para apagarlos.

## Decisiones de diseño

**El servidor decide todo.** El cliente solo manda una petición: "comprar el objeto con este id". El servidor busca el precio en su propio catálogo, comprueba el dinero y el espacio, cobra y entrega. No hay cantidad ni precio en la petición.

**Una sola puerta.** Hay una única `RemoteFunction` (`PurchaseRequest`) que puede cambiar datos. El servidor la valida con estas reglas:
- Solo acepta un argumento, de tipo texto, de 1 a 40 caracteres. Cualquier otra cosa devuelve `InvalidRequest`.
- El id debe existir en el catálogo de la tienda (`UnknownItem` si no).
- Spam: mínimo 0.3 s entre peticiones; más de 8 en 5 segundos silencia al jugador 5 s (`TooFast`).
- Cooldown de 1 s tras una compra hecha (`Cooldown`).
- Comprueba el espacio (`AlreadyOwned` o `InventoryFull`) y el dinero (`NotEnoughCoins`) **antes** de cobrar.
- Cobra y entrega sin esperas entre medias (no pueden mezclarse dos peticiones); si la entrega fallara, devuelve el dinero.

**Los datos solo los ve su dueño.** Igual que en la pieza 1: monedas e inventario van como atributos del `PlayerGui` del jugador, que Roblox solo envía a su dueño.

**Estilo "Taller de juguetes".** Papel crema y madera de fondo, cuatro colores de caja de juguetes (tomate, girasol, cielo, menta) más uva, contornos gruesos de color tinta y esquinas redondeadas, como recortes de cartón. Títulos con FredokaOne y texto con Nunito. Es distinto de la pieza 1 (ruinas doradas al atardecer, de exterior).

**Todo el mundo es código.** El taller y los juguetes se arman con piezas propias (`WorkshopBuilder`, `ToyModels`); no hay modelos descargados.

## Archivos y para qué sirve cada uno

**Servidor** (`src/server`)
- `init.server.luau`: punto de entrada, arranca todo en orden.
- `ShopService.luau`: la compra, con todas las validaciones.
- `TokenService.luau`: las fichas de monedas (mide la distancia en el servidor).
- `WorkshopBuilder.luau`: construye el taller (suelo, paredes, estantes, mostrador, cartel, engranajes, lámparas).
- `WorkshopLayout.luau`: dónde está cada cosa del taller.
- `DataService.luau`, `DataReplicator.luau`, `DataTemplate.luau`: carga, guardado (cada 60 s y al salir) y copia de los datos al jugador. Copiados de la pieza 1.
- `CurrencyService.luau`, `InventoryService.luau`, `Validation.luau`: monedas e inventario con sus validaciones. Copiados de la pieza 1.
- `Packages/ProfileStore.luau`: librería de terceros (ver Licencias).

**Compartido** (`src/shared`)
- `ItemCatalog.luau`: los 10 objetos con su nombre y su máximo.
- `ShopCatalog.luau`: categorías, orden, precios y descripciones. Se comprueba al arrancar.
- `ShopShared.luau`: nombre de la petición y resultados posibles de una compra.
- `ToyModels.luau`: los 10 juguetes armados con piezas.
- `Theme.luau`: colores y tipografías.
- `DataAttributes.luau`: nombres de los atributos con los que el servidor y la pantalla se entienden.

**Cliente** (`src/client`)
- `init.client.luau`: punto de entrada del cliente.
- `ShopWindow.luau`: la ventana (categorías, cuadrícula, detalle, interruptores) y su distribución en pantalla ancha o angosta.
- `ShopCard.luau`: una tarjeta de juguete, con sus animaciones.
- `ShopDetail.luau`: el panel de detalle y el botón de comprar.
- `ToyPreview.luau`: la vista previa en 3D.
- `PurchaseClient.luau`: pide la compra al servidor y arma el mensaje para el jugador.
- `CoinPill.luau`: el contador de monedas.
- `UiKit.luau`: piezas de interfaz que se repiten (botones, interruptores, moneda dibujada).
- `Motion.luau`: la opción de menos movimiento, en un solo lugar.
- `Spinner.luau`: hace girar fichas y engranajes del taller (solo adorno).
- `GearDecor.luau`: los engranajes tenues del fondo de la ventana.
- `Sfx.luau`: los dos sonidos y su interruptor.

## Cómo instalarlo y probarlo

1. Instala [Rokit](https://github.com/rojo-rbx/rokit) y, dentro de esta carpeta, ejecuta `rokit install` (instala Rojo 7.7.1).
2. En esta carpeta ejecuta `rojo serve` y déjalo abierto.
3. En Roblox Studio abre un lugar Baseplate nuevo, ve a Plugins > Rojo y pulsa **Connect**. Acepta los cambios.
4. Pulsa **Play**. Apareces en el taller, de cara al mostrador. Arriba a la derecha está tu contador de monedas y a la derecha, a media altura, el botón **Tienda**.
5. Camina por el taller para recoger fichas doradas, y abre la tienda con el botón **Tienda** o con la tecla E junto al mostrador.
6. Para probar en celular o tableta: pestaña Prueba, emulador de dispositivos, y pulsa Play. Para probar con mando, conéctalo y usa el emulador de consola.

## Sonidos

Solo se usan dos audios de la biblioteca de efectos licenciada de Pro Sound Effects que Roblox ofrece en el Creator Store (cuenta verificada ProSoundEffects). No son audios creados por Roblox.

| Momento | ID | Nombre | Volumen |
|---|---|---|---|
| Recoger una ficha | `9116162487` | Key Dings Metal Clinking 3 (SFX) | 0.22 |
| Comprar un juguete | `9113728042` | Cash Register 1 (SFX) | 0.3 |

Se verificó en la pieza 1 que estos audios cargan y suenan en Studio y en un juego publicado.

## Qué está probado y qué no

**Hecho:**
- El proyecto compila con Rojo.
- Revisión de código por lectura con un revisor de solo lectura (ver abajo).

**Sin probar todavía** (se irá completando con las pruebas en Studio):
- Las validaciones del servidor con peticiones raras, spam y cooldown, desde la barra de comandos.
- La ventana y sus textos en celular, tableta y PC, con el peor caso de texto.
- Mouse (cursor encima), toque (elegir y confirmar) y mando (foco y botón B).
- Las animaciones, la opción de menos movimiento y los sonidos.
- El guardado real de lo comprado (necesita el lugar publicado).
- El rendimiento en un celular modesto.

## Límites conocidos

- **La opción de menos movimiento y la de sonido no se recuerdan** entre sesiones. Guardarlas habría exigido una segunda petición al servidor, y se decidió dejar una sola (la de comprar). Se pueden volver a activar en un toque.
- **La compra funciona desde cualquier parte del taller**, no solo junto al mostrador. El servidor valida el dinero y el espacio igual.
- **Las vistas previas en 3D pesan en celulares muy modestos:** solo se dibujan las tarjetas de la categoría visible, más una en el detalle.
- **Los juguetes son de adorno:** comprarlos los pone en el inventario del jugador, pero todavía no hacen nada en el juego.

## Licencias

ProfileStore, de MAD STUDIO (loleris), se usa bajo licencia Apache 2.0. La copia completa está en `licenses/ProfileStore-LICENSE.txt` y el origen en `THIRD_PARTY.md`.
