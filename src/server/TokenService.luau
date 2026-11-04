--!strict
-- Fichas de monedas repartidas por el taller. Al tocarlas, el servidor suma las monedas
-- (si el jugador está cerca) y la ficha desaparece un rato y vuelve sola. Son la forma
-- de ganar monedas para la tienda. Sin tiempos que apuren: siempre vuelven a aparecer.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local CurrencyService = require(script.Parent.CurrencyService)
local WorkshopLayout = require(script.Parent.WorkshopLayout)

local TOKEN_VALUE = 15 -- monedas por ficha
local RESPAWN_SECONDS = 20
local MAX_PICKUP_DISTANCE = 9 -- el servidor mide la distancia: no se confía en el toque solo
local MIN_PICKUP_INTERVAL = 0.5 -- segundos entre dos fichas del mismo jugador: frena el vaciado en ráfaga
local TOKEN_HEIGHT = 3
local TOKEN_DIAMETER = 2.4

local lastPickup: { [Player]: number } = {}

local TokenService = {}

-- Ficha de oro: un disco. El cliente la hace girar y flotar (etiqueta "Spin"), solo de adorno.
local function buildToken(parent: Instance, spot: Vector2): Part
	local token = Instance.new("Part")
	token.Name = "Token"
	token.Shape = Enum.PartType.Cylinder
	token.Size = Vector3.new(0.4, TOKEN_DIAMETER, TOKEN_DIAMETER) -- el eje del cilindro es X: es un disco de canto
	token.CFrame = CFrame.new(spot.X, TOKEN_HEIGHT, spot.Y)
	token.Color = Color3.fromHex("#F6C945")
	token.Material = Enum.Material.Metal
	token.Anchored = true
	token.CanCollide = false
	token.CanQuery = false
	token.CastShadow = false
	token.TopSurface = Enum.SurfaceType.Smooth
	token.BottomSurface = Enum.SurfaceType.Smooth
	token:SetAttribute("SpinSpeed", 90) -- grados por segundo
	token:SetAttribute("SpinAxis", "Y")
	token:SetAttribute("Bob", 0.35) -- cuánto sube y baja, en studs
	CollectionService:AddTag(token, "Spin")
	token.Parent = parent
	return token
end

local function setAvailable(token: Part, available: boolean)
	token.Transparency = if available then 0 else 1
	token.CanTouch = available
	token:SetAttribute("Available", available)
end

local function connectPickup(token: Part)
	token.Touched:Connect(function(hit: BasePart)
		if token:GetAttribute("Available") ~= true then
			return
		end
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if player == nil then
			return
		end
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if humanoid == nil or humanoid.Health <= 0 or root == nil or not root:IsA("BasePart") then
			return
		end
		if (root.Position - token.Position).Magnitude > MAX_PICKUP_DISTANCE then
			return
		end

		local now = os.clock()
		if now - (lastPickup[player] or -math.huge) < MIN_PICKUP_INTERVAL then
			return -- la ficha se queda; podrá recogerla un instante después
		end

		-- Se marca como tomada ANTES de sumar, para que dos toques seguidos no la cuenten dos veces
		setAvailable(token, false)
		if CurrencyService.addCoins(player, TOKEN_VALUE) ~= "Ok" then
			setAvailable(token, true) -- saldo al tope o sin datos: la ficha se queda para después
			return
		end
		lastPickup[player] = now
		task.delay(RESPAWN_SECONDS, function()
			if token.Parent ~= nil then
				setAvailable(token, true)
			end
		end)
	end)
end

function TokenService.start()
	local folder = Instance.new("Folder")
	folder.Name = "Tokens"
	folder.Parent = workspace

	Players.PlayerRemoving:Connect(function(player: Player)
		lastPickup[player] = nil
	end)

	for _, spot in WorkshopLayout.TokenSpots do
		local token = buildToken(folder, spot)
		setAvailable(token, true)
		connectPickup(token)
	end
end

return TokenService
