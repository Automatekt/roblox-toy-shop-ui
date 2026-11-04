--!strict
-- Hablar con el servidor para comprar, y convertir su respuesta en un mensaje amable.
-- El cliente solo manda el id del objeto; el servidor decide si se puede y cuánto cuesta.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ShopShared = require(ReplicatedStorage.Shared.ShopShared)

type Result = ShopShared.Result

local PurchaseClient = {}

-- Pide comprar un objeto y espera la respuesta. Si algo falla en el camino, devuelve "Error".
function PurchaseClient.buy(itemId: string): Result
	local remote = ReplicatedStorage:WaitForChild(ShopShared.RemoteName, 10)
	if remote == nil or not remote:IsA("RemoteFunction") then
		return "Error"
	end
	local remoteFunction = remote :: RemoteFunction
	local ok, result = pcall(function()
		return remoteFunction:InvokeServer(itemId)
	end)
	if not ok or type(result) ~= "string" then
		return "Error"
	end
	return result :: Result
end

-- Texto para el jugador y si es una buena noticia. Sin culpas ni presión: los avisos
-- explican qué pasó y qué se puede hacer.
function PurchaseClient.messageFor(result: Result, itemName: string, missingCoins: number): (string, boolean)
	if result == "Ok" then
		return `¡Listo! {itemName} ya es tuyo.`, true
	elseif result == "NotEnoughCoins" then
		return `Te faltan {missingCoins} monedas. ¡Junta fichas por el taller!`, false
	elseif result == "AlreadyOwned" then
		return "¡Ya tienes este juguete!", false
	elseif result == "InventoryFull" then
		return "Ya tienes todas las que caben.", false
	elseif result == "TooFast" then
		return "Más despacio, ¡un momento!", false
	elseif result == "Cooldown" then
		return "Espera un segundito.", false
	end
	return "Algo salió mal. Prueba otra vez.", false
end

return PurchaseClient
