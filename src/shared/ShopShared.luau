--!strict
-- Lo que comparten el servidor y la pantalla de la tienda: el nombre de la única
-- petición y los resultados posibles de una compra.

-- "Ok" es la única respuesta que significa compra hecha. El resto son motivos claros
-- por los que no se cobró nada.
export type Result =
	"Ok"
	| "InvalidRequest" -- la petición venía mal armada (no era un id de texto, o traía de más)
	| "UnknownItem" -- ese id no se vende
	| "NotEnoughCoins" -- no alcanzan las monedas
	| "AlreadyOwned" -- es un juguete único y ya lo tiene
	| "InventoryFull" -- ya tiene el máximo de ese objeto
	| "TooFast" -- demasiadas peticiones seguidas
	| "Cooldown" -- acaba de comprar: hay que esperar un momento
	| "NoData" -- sus datos todavía no cargaron
	| "Error" -- algo inesperado; no se cobró

return table.freeze({
	RemoteName = "PurchaseRequest",
})
