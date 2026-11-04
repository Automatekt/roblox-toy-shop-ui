--!strict
-- La tienda en el servidor. Es el único punto donde el cliente puede pedir algo:
-- "comprar el objeto con este id". El servidor busca el precio, comprueba el dinero y
-- el espacio, cobra y entrega. El cliente solo recibe un resultado.
--
-- Nada de lo que llega se da por bueno: se revisa el tipo, el largo, que sobren
-- argumentos, que el objeto exista, la velocidad de las peticiones y el cooldown.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CurrencyService = require(script.Parent.CurrencyService)
local InventoryService = require(script.Parent.InventoryService)
local ItemCatalog = require(ReplicatedStorage.Shared.ItemCatalog)
local ShopCatalog = require(ReplicatedStorage.Shared.ShopCatalog)
local ShopShared = require(ReplicatedStorage.Shared.ShopShared)

type Result = ShopShared.Result

local MAX_ID_LENGTH = 40 -- ningún id real es más largo; evita textos enormes
local MIN_INTERVAL = 0.3 -- segundos mínimos entre dos peticiones del mismo jugador
local WINDOW_SECONDS = 5 -- ventana para contar ráfagas de peticiones
local WINDOW_LIMIT = 8 -- más de esto dentro de la ventana es spam
local MUTE_SECONDS = 5 -- castigo suave: se ignoran sus peticiones un rato
local PURCHASE_COOLDOWN = 1 -- segundos entre dos compras hechas

type PlayerState = {
	lastRequest: number,
	recent: { number }, -- momentos de las últimas peticiones, dentro de la ventana
	mutedUntil: number,
	lastPurchase: number,
}

local states: { [Player]: PlayerState } = {}

local ShopService = {}

local function getState(player: Player): PlayerState
	local state = states[player]
	if state == nil then
		state = { lastRequest = -math.huge, recent = {}, mutedUntil = 0, lastPurchase = -math.huge }
		states[player] = state
	end
	return state
end

-- Anota la petición y dice si se puede atender (no es spam)
local function passesRateLimit(state: PlayerState, now: number): boolean
	if now < state.mutedUntil then
		return false
	end
	local tooSoon = now - state.lastRequest < MIN_INTERVAL
	state.lastRequest = now

	local recent = state.recent
	table.insert(recent, now)
	while #recent > 0 and now - recent[1] > WINDOW_SECONDS do
		table.remove(recent, 1)
	end
	if #recent > WINDOW_LIMIT then
		state.mutedUntil = now + MUTE_SECONDS
		table.clear(recent)
		return false
	end
	return not tooSoon
end

-- Atiende una petición de compra. Siempre devuelve un texto de ShopShared.Result.
-- No hay esperas (yield) entre comprobar y cobrar, así que dos peticiones no se pisan.
local function handlePurchase(player: Player, itemId: any, extraArgs: number): Result
	local state = getState(player)
	local now = os.clock()

	if not passesRateLimit(state, now) then
		return "TooFast"
	end

	-- Solo se acepta un argumento: el id, como texto corto. No hay cantidad: siempre es 1.
	if extraArgs > 0 or type(itemId) ~= "string" or #itemId == 0 or #itemId > MAX_ID_LENGTH then
		return "InvalidRequest"
	end

	local entry = ShopCatalog.get(itemId)
	if entry == nil then
		return "UnknownItem"
	end

	if now - state.lastPurchase < PURCHASE_COOLDOWN then
		return "Cooldown"
	end

	-- Primero se comprueba todo; después se cobra y se entrega
	local owned = InventoryService.getItemCount(player, entry.ItemId)
	local coins = CurrencyService.getCoins(player)
	if owned == nil or coins == nil then
		return "NoData"
	end
	local maxStack = ItemCatalog[entry.ItemId].MaxStack
	if owned + 1 > maxStack then
		return if maxStack == 1 then "AlreadyOwned" else "InventoryFull"
	end
	if coins < entry.Price then
		return "NotEnoughCoins"
	end

	if CurrencyService.spendCoins(player, entry.Price) ~= "Ok" then
		return "Error"
	end
	if InventoryService.addItem(player, entry.ItemId, 1) ~= "Ok" then
		-- No debería pasar, porque ya se comprobó el espacio. Por seguridad se devuelve el dinero.
		CurrencyService.addCoins(player, entry.Price)
		return "Error"
	end

	state.lastPurchase = now
	return "Ok"
end

function ShopService.start()
	local remote = Instance.new("RemoteFunction")
	remote.Name = ShopShared.RemoteName

	-- "..." recoge cualquier argumento de más para rechazarlo
	remote.OnServerInvoke = function(player: Player, itemId: any, ...: any): Result
		local ok, result = pcall(handlePurchase, player, itemId, select("#", ...))
		if not ok then
			warn("[ShopService] error al atender una compra de " .. player.Name .. ": " .. tostring(result))
			return "Error"
		end
		return result
	end
	remote.Parent = ReplicatedStorage

	Players.PlayerRemoving:Connect(function(player: Player)
		states[player] = nil
	end)
end

return ShopService
