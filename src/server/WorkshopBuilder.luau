--!strict
-- Construye el taller de juguetes: un cuarto de madera, de día, con estantes, un mostrador,
-- engranajes en la pared y lámparas. Todo es código (piezas propias), sin modelos descargados.
-- Presupuesto de rendimiento: unas 140 piezas ancladas y 4 luces sin sombras.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ToyModels = require(ReplicatedStorage.Shared.ToyModels)
local Theme = require(ReplicatedStorage.Shared.Theme)
local WorkshopLayout = require(script.Parent.WorkshopLayout)

local PI = math.pi
local H = WorkshopLayout.HalfSize
local WALL_HEIGHT = WorkshopLayout.WallHeight

local WorkshopBuilder = {}

local function newPart(
	parent: Instance,
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material,
	solid: boolean
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	if not solid then
		-- Lo decorativo no choca ni gasta cálculo de sombras
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.CastShadow = false
	end
	part.Parent = parent
	return part
end

local function newFolder(parent: Instance, name: string): Folder
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end

-- Cilindro de pie (la Part cilíndrica de Roblox se acuesta sobre el eje X)
local function newColumn(parent: Instance, name: string, position: Vector3, height: number, diameter: number, color: Color3, material: Enum.Material): Part
	local part = newPart(parent, name, Vector3.new(height, diameter, diameter), CFrame.new(position) * CFrame.Angles(0, 0, PI / 2), color, material, false)
	part.Shape = Enum.PartType.Cylinder
	return part
end

local function newBall(parent: Instance, name: string, position: Vector3, diameter: number, color: Color3, material: Enum.Material): Part
	local part = newPart(parent, name, Vector3.one * diameter, CFrame.new(position), color, material, false)
	part.Shape = Enum.PartType.Ball
	return part
end

-- Suelo de madera, un tapete redondo y el suelo de afuera por si la cámara sube
local function buildFloor(parent: Instance)
	newPart(parent, "Floor", Vector3.new(2 * H, 1, 2 * H), CFrame.new(0, -0.5, 0), Theme.Wood:Lerp(Theme.Cream, 0.35), Enum.Material.WoodPlanks, true)

	local outside = newPart(parent, "Outside", Vector3.new(600, 1, 600), CFrame.new(0, -1.55, 0), Theme.Mint:Lerp(Theme.Cream, 0.3), Enum.Material.Grass, true)
	outside.CanQuery = false

	-- Tapete de tres anillos
	local function rug(name: string, diameter: number, y: number, color: Color3)
		local disc = newPart(parent, name, Vector3.new(0.2, diameter, diameter), CFrame.new(0, y, 2) * CFrame.Angles(0, 0, PI / 2), color, Enum.Material.Fabric, false)
		disc.Shape = Enum.PartType.Cylinder
	end
	rug("RugOuter", 20, 0.1, Theme.Tomato)
	rug("RugMiddle", 15, 0.12, Theme.Sunflower)
	rug("RugInner", 10, 0.14, Theme.Sky)
end

-- Cuatro paredes crema con friso de madera abajo, y vigas de techo (sin techo cerrado:
-- así entra la luz del día y la cámara no se tapa)
local function buildWalls(parent: Instance)
	local length = 2 * H + 2
	local mid = WALL_HEIGHT / 2
	newPart(parent, "WallBack", Vector3.new(length, WALL_HEIGHT, 1), CFrame.new(0, mid, -H - 0.5), Theme.Cream, Enum.Material.SmoothPlastic, true)
	newPart(parent, "WallFront", Vector3.new(length, WALL_HEIGHT, 1), CFrame.new(0, mid, H + 0.5), Theme.Cream, Enum.Material.SmoothPlastic, true)
	newPart(parent, "WallLeft", Vector3.new(1, WALL_HEIGHT, 2 * H), CFrame.new(-H - 0.5, mid, 0), Theme.Cream, Enum.Material.SmoothPlastic, true)
	newPart(parent, "WallRight", Vector3.new(1, WALL_HEIGHT, 2 * H), CFrame.new(H + 0.5, mid, 0), Theme.Cream, Enum.Material.SmoothPlastic, true)

	local trim = Theme.Wood:Lerp(Theme.Cream, 0.2)
	newPart(parent, "TrimBack", Vector3.new(2 * H, 6, 0.4), CFrame.new(0, 3, -H + 0.2), trim, Enum.Material.WoodPlanks, false)
	newPart(parent, "TrimFront", Vector3.new(2 * H, 6, 0.4), CFrame.new(0, 3, H - 0.2), trim, Enum.Material.WoodPlanks, false)
	newPart(parent, "TrimLeft", Vector3.new(0.4, 6, 2 * H), CFrame.new(-H + 0.2, 3, 0), trim, Enum.Material.WoodPlanks, false)
	newPart(parent, "TrimRight", Vector3.new(0.4, 6, 2 * H), CFrame.new(H - 0.2, 3, 0), trim, Enum.Material.WoodPlanks, false)

	for _, z in { -20, -10, 0, 10, 20 } do
		newPart(parent, "Beam", Vector3.new(length, 0.8, 1), CFrame.new(0, WALL_HEIGHT + 0.4, z), Theme.WoodDark, Enum.Material.Wood, false)
	end
end

-- Ventanas en las paredes laterales, por encima de los estantes
local function buildWindows(parent: Instance)
	local paneColor = Theme.Sky:Lerp(Theme.Paper, 0.6)
	for _, side in { -1, 1 } do
		for _, z in { -10, 10 } do
			newPart(parent, "WindowFrame", Vector3.new(0.5, 6.4, 6.4), CFrame.new(side * (H - 0.25), 16, z), Theme.WoodDark, Enum.Material.Wood, false)
			newPart(parent, "WindowPane", Vector3.new(0.3, 5, 5), CFrame.new(side * (H - 0.55), 16, z), paneColor, Enum.Material.Neon, false)
		end
	end
end

-- Mostrador de la tienda: aquí está el botón para abrirla
local function buildCounter(parent: Instance)
	local center = WorkshopLayout.CounterPosition
	local size = WorkshopLayout.CounterSize
	newPart(parent, "CounterBase", Vector3.new(size.X, 3, 3.4), CFrame.new(center.X, 1.5, center.Z), Theme.Wood, Enum.Material.WoodPlanks, true)
	local top = newPart(parent, "CounterTop", Vector3.new(size.X + 0.8, 0.5, size.Z + 0.2), CFrame.new(center.X, 3.25, center.Z), Theme.Cream, Enum.Material.SmoothPlastic, true)

	local colors = { Theme.Tomato, Theme.Sky, Theme.Sunflower }
	for index, color in colors do
		newPart(parent, "CounterPanel", Vector3.new(4, 2, 0.15), CFrame.new(center.X + (index - 2) * 5.2, 1.5, center.Z + 1.75), color, Enum.Material.SmoothPlastic, false)
	end

	-- El botón de abrir la tienda. El servidor no hace nada al pulsarlo: la pantalla de la
	-- tienda se abre en el cliente, y cada compra se valida igual desde cualquier sitio.
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Abrir la tienda"
	prompt.ObjectText = "Taller de juguetes"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt:SetAttribute("OpensShop", true)
	prompt.Parent = top
end

-- Cartel del taller en la pared del fondo
local function buildSign(parent: Instance)
	local board = newPart(parent, "SignBoard", Vector3.new(20, 4.4, 0.6), CFrame.new(0, 10, -H + 0.3), Theme.Tomato, Enum.Material.SmoothPlastic, false)

	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Back -- la cara que mira hacia el cuarto
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.Parent = board

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Theme.TitleFont
	label.Text = "TALLER DE JUGUETES"
	label.TextColor3 = Theme.Cream
	label.TextStrokeColor3 = Theme.Ink
	label.TextStrokeTransparency = 0.2
	label.TextScaled = true
	label.Parent = gui
end

-- Un engranaje de pared: disco, dientes y centro. Gira despacio en el cliente (etiqueta "Spin").
local function buildGear(parent: Instance, center: Vector3, radius: number, teeth: number, color: Color3, hubColor: Color3, speed: number)
	local gear = Instance.new("Model")
	gear.Name = "Gear"

	-- El eje del cilindro es X; se gira 90 grados para que el disco quede mirando al cuarto (+Z)
	local faceRoom = CFrame.Angles(0, PI / 2, 0)
	local disc = newPart(gear, "Disc", Vector3.new(0.8, radius * 2, radius * 2), CFrame.new(center) * faceRoom, color, Enum.Material.Metal, false)
	disc.Shape = Enum.PartType.Cylinder
	local hub = newPart(gear, "Hub", Vector3.new(1, radius * 0.9, radius * 0.9), CFrame.new(center) * faceRoom, hubColor, Enum.Material.Metal, false)
	hub.Shape = Enum.PartType.Cylinder

	for index = 0, teeth - 1 do
		local angle = index * 2 * PI / teeth
		local offset = Vector3.new(math.cos(angle), math.sin(angle), 0) * (radius + 0.25)
		newPart(gear, "Tooth", Vector3.new(0.9, 1.2, 0.8), CFrame.new(center + offset) * CFrame.Angles(0, 0, angle), color, Enum.Material.Metal, false)
	end

	gear.PrimaryPart = disc
	gear:SetAttribute("SpinSpeed", speed)
	gear:SetAttribute("SpinAxis", "Z")
	CollectionService:AddTag(gear, "Spin")
	gear.Parent = parent
end

local function buildGears(parent: Instance)
	local z = -H + 0.5
	buildGear(parent, Vector3.new(-20, 14, z), 5, 8, Theme.Sunflower, Theme.Tomato, 8)
	buildGear(parent, Vector3.new(-9.5, 17.5, z), 3.2, 6, Theme.Sky, Theme.Paper, -12)
	buildGear(parent, Vector3.new(20, 13, z), 6, 8, Theme.Tomato, Theme.Sunflower, 6)
end

-- Pone un juguete sobre una superficie: lo escala, lo gira hacia el cuarto y lo apoya
local function placeToy(parent: Instance, itemId: string, x: number, topY: number, z: number, yaw: number, scale: number)
	local toy = ToyModels.build(itemId)
	if toy == nil then
		return
	end
	toy:ScaleTo(scale)
	toy:PivotTo(CFrame.new(x, topY, z) * CFrame.Angles(0, yaw, 0))
	-- Se baja o sube lo justo para que la parte de abajo toque la superficie
	local boxCFrame, boxSize = toy:GetBoundingBox()
	local bottom = boxCFrame.Position.Y - boxSize.Y / 2
	toy:PivotTo(toy:GetPivot() + Vector3.new(0, topY - bottom, 0))
	toy.Parent = parent
end

-- Dos estanterías junto a las paredes laterales, con juguetes
local function buildShelves(parent: Instance)
	local toysBySide: { [number]: { string } } = {
		[-1] = { "LetterCube", "BlockTower", "MarbleBag" },
		[1] = { "BrassRocket", "PieceCastle", "WoodTrain" },
	}
	local boardHeights = { 3.4, 6.8, 10.2 }

	for _, side in { -1, 1 } do
		local wallX = side * H
		local frontX = wallX - side * 1.2 -- el centro de las tablas, hacia el cuarto
		newPart(parent, "ShelfBack", Vector3.new(0.4, 12, 23), CFrame.new(wallX - side * 0.6, 6, 0), Theme.WoodDark, Enum.Material.Wood, false)
		for _, y in boardHeights do
			newPart(parent, "ShelfBoard", Vector3.new(2.4, 0.5, 23), CFrame.new(frontX, y, 0), Theme.Wood, Enum.Material.WoodPlanks, false)
		end
		for _, z in { -11.5, 11.5 } do
			newPart(parent, "ShelfPost", Vector3.new(2.4, 12, 0.5), CFrame.new(frontX, 6, z), Theme.WoodDark, Enum.Material.Wood, false)
		end

		-- Los juguetes miran hacia el centro del cuarto
		local yaw = if side == -1 then PI / 2 else -PI / 2
		local toys = toysBySide[side]
		for index, itemId in toys do
			local z = (index - 2) * 7
			placeToy(parent, itemId, frontX, boardHeights[2] + 0.25, z, yaw, 0.6)
		end
	end
end

-- Un osito y un cubo sobre el mostrador, como bienvenida
local function buildCounterToys(parent: Instance)
	local center = WorkshopLayout.CounterPosition
	placeToy(parent, "TeddyBear", center.X - 5.5, 3.5, center.Z, 0, 0.9)
	placeToy(parent, "LetterCube", center.X + 5.5, 3.5, center.Z, PI / 9, 0.7)
end

-- Cuatro lámparas colgantes con luz cálida y sin sombras (las sombras pesan en celular)
local function buildLamps(parent: Instance)
	local shadeColor = Theme.Sunflower:Lerp(Theme.Paper, 0.4)
	for _, x in { -10, 10 } do
		for _, z in { -8, 8 } do
			newColumn(parent, "LampCord", Vector3.new(x, 20.75, z), 2.5, 0.15, Theme.Ink, Enum.Material.SmoothPlastic)
			local shade = newBall(parent, "LampShade", Vector3.new(x, 19, z), 1.8, shadeColor, Enum.Material.Neon)
			local light = Instance.new("PointLight")
			light.Color = Theme.Cream
			light.Range = 28
			light.Brightness = 1.2
			light.Shadows = false
			light.Parent = shade
		end
	end
end

-- Punto de aparición de los jugadores, invisible, mirando al mostrador
local function buildSpawn(parent: Instance)
	for _, child in workspace:GetChildren() do
		if child:IsA("SpawnLocation") then
			child:Destroy() -- el de la plantilla de Studio
		end
	end
	local spawnPad = Instance.new("SpawnLocation")
	spawnPad.Name = "SpawnLocation"
	spawnPad.Size = Vector3.new(6, 1, 6)
	spawnPad.CFrame = CFrame.new(WorkshopLayout.SpawnPosition)
	spawnPad.Anchored = true
	spawnPad.Neutral = true
	spawnPad.Duration = 0
	spawnPad.Transparency = 1
	spawnPad.CanCollide = false -- invisible y sin estorbar: el jugador aparece a ras del suelo
	for _, child in spawnPad:GetChildren() do
		if child:IsA("Decal") then
			child:Destroy() -- la calcomanía que Roblox le pone por defecto
		end
	end
	spawnPad.Parent = parent
end

-- Construye todo el taller y devuelve la carpeta que lo contiene
function WorkshopBuilder.build(): Folder
	local previous = workspace:FindFirstChild("Map")
	if previous then
		previous:Destroy()
	end
	local template = workspace:FindFirstChild("Baseplate")
	if template then
		template:Destroy() -- el suelo de la plantilla de Studio
	end

	local map = Instance.new("Folder")
	map.Name = "Map"

	buildFloor(newFolder(map, "Floor"))
	buildWalls(newFolder(map, "Walls"))
	buildWindows(newFolder(map, "Windows"))
	buildCounter(newFolder(map, "Counter"))
	buildCounterToys(newFolder(map, "CounterToys"))
	buildSign(newFolder(map, "Sign"))
	buildGears(newFolder(map, "Gears"))
	buildShelves(newFolder(map, "Shelves"))
	buildLamps(newFolder(map, "Lamps"))
	buildSpawn(map)

	map.Parent = workspace
	return map
end

return WorkshopBuilder
