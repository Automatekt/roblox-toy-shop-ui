--!strict
-- Los juguetes de la tienda, armados con piezas simples. Sirven para la vista previa de la
-- tienda y para decorar los estantes del taller. Cada juguete cabe en una caja de unos
-- 5 studs, centrada en el origen. Son solo adorno: sin colisión y sin luz propia.

local Theme = require(script.Parent.Theme)

local PI = math.pi
local V = Vector3.new

type Spec = {
	kind: "Block" | "Ball" | "Cylinder",
	size: Vector3, -- bloque: ancho, alto, fondo. Bola: solo X (el diámetro). Cilindro: diámetro, alto, diámetro
	pos: Vector3,
	color: Color3,
	rot: Vector3?, -- grados
	material: Enum.Material?,
}

local function block(size: Vector3, pos: Vector3, color: Color3, rot: Vector3?, material: Enum.Material?): Spec
	return { kind = "Block", size = size, pos = pos, color = color, rot = rot, material = material }
end

local function ball(diameter: number, pos: Vector3, color: Color3, material: Enum.Material?): Spec
	return { kind = "Ball", size = V(diameter, diameter, diameter), pos = pos, color = color, material = material }
end

-- Cilindro de pie; con "rot" se acuesta o se inclina
local function cyl(diameter: number, height: number, pos: Vector3, color: Color3, rot: Vector3?, material: Enum.Material?): Spec
	return { kind = "Cylinder", size = V(diameter, height, diameter), pos = pos, color = color, rot = rot, material = material }
end

local Fabric = Enum.Material.Fabric
local Wood = Enum.Material.Wood
local Metal = Enum.Material.Metal

local definitions: { [string]: { Spec } } = {
	WindUpRobot = {
		block(V(2, 2, 1.4), V(0, 0, 0), Theme.Tomato, nil, Metal),
		block(V(1.6, 1.3, 1.3), V(0, 1.6, 0), Theme.Sky, nil, Metal),
		ball(0.4, V(-0.4, 1.75, 0.62), Theme.Ink),
		ball(0.4, V(0.4, 1.75, 0.62), Theme.Ink),
		cyl(0.16, 0.8, V(0, 2.6, 0), Theme.Ink),
		ball(0.4, V(0, 3.05, 0), Theme.Sunflower),
		block(V(0.5, 1.4, 0.5), V(-1.35, 0, 0), Theme.Sunflower),
		block(V(0.5, 1.4, 0.5), V(1.35, 0, 0), Theme.Sunflower),
		block(V(0.7, 1.2, 0.8), V(-0.55, -1.6, 0), Theme.Sunflower),
		block(V(0.7, 1.2, 0.8), V(0.55, -1.6, 0), Theme.Sunflower),
		cyl(0.2, 0.9, V(0, 0.2, -1.1), Theme.Sunflower, V(90, 0, 0)),
		block(V(1.2, 0.5, 0.2), V(0, 0.2, -1.6), Theme.Sunflower),
	},
	BrassRocket = {
		cyl(1.8, 3, V(0, 0, 0), Theme.Sunflower, nil, Metal),
		ball(1.8, V(0, 1.9, 0), Theme.Tomato),
		ball(0.9, V(0, 0.6, 0.85), Theme.Sky),
		block(V(0.25, 1.2, 1), V(-1, -1.1, 0), Theme.Tomato),
		block(V(0.25, 1.2, 1), V(1, -1.1, 0), Theme.Tomato),
		block(V(1, 1.2, 0.25), V(0, -1.1, -1), Theme.Tomato),
		cyl(1, 0.5, V(0, -1.75, 0), Theme.Ink),
	},
	WoodTrain = {
		cyl(1.4, 2.4, V(-1.4, 0.3, 0), Theme.Tomato, V(0, 0, 90), Metal),
		cyl(0.5, 0.9, V(-2, 1.2, 0), Theme.Ink),
		block(V(1.4, 1.6, 1.5), V(0.2, 0.5, 0), Theme.Sky, nil, Wood),
		block(V(1.7, 0.2, 1.8), V(0.2, 1.4, 0), Theme.Wood, nil, Wood),
		block(V(1.8, 1, 1.5), V(2.4, 0.2, 0), Theme.Sunflower, nil, Wood),
		cyl(0.9, 0.3, V(-1.5, -0.5, 0.85), Theme.Ink, V(90, 0, 0)),
		cyl(0.9, 0.3, V(-1.5, -0.5, -0.85), Theme.Ink, V(90, 0, 0)),
		cyl(0.9, 0.3, V(2.4, -0.5, 0.85), Theme.Ink, V(90, 0, 0)),
		cyl(0.9, 0.3, V(2.4, -0.5, -0.85), Theme.Ink, V(90, 0, 0)),
	},
	LetterCube = {
		block(V(2.6, 2.6, 2.6), V(0, 0, 0), Theme.Cream, nil, Wood),
		block(V(1.6, 1.6, 0.1), V(0, 0, 1.3), Theme.Tomato),
		block(V(0.1, 1.6, 1.6), V(1.3, 0, 0), Theme.Sky),
		block(V(1.6, 0.1, 1.6), V(0, 1.3, 0), Theme.Mint),
	},
	BlockTower = {
		block(V(2.4, 1.1, 2.4), V(0, -1.6, 0), Theme.Tomato, nil, Wood),
		block(V(2, 1.1, 2), V(0, -0.5, 0), Theme.Sky, V(0, 12, 0), Wood),
		block(V(1.6, 1.1, 1.6), V(0, 0.6, 0), Theme.Sunflower, V(0, -10, 0), Wood),
		block(V(1.2, 1.1, 1.2), V(0, 1.7, 0), Theme.Mint, V(0, 8, 0), Wood),
		ball(0.9, V(0, 2.65, 0), Theme.Tomato),
	},
	PieceCastle = {
		block(V(4.4, 1.4, 3.2), V(0, -1.3, 0), Theme.Cream, nil, Wood),
		block(V(1.6, 2, 1.6), V(0, 0.4, 0), Theme.Wood, nil, Wood),
		cyl(1, 3, V(-1.9, 0.9, 0), Theme.Sky),
		cyl(1, 3, V(1.9, 0.9, 0), Theme.Sky),
		ball(1.2, V(-1.9, 2.6, 0), Theme.Tomato),
		ball(1.2, V(1.9, 2.6, 0), Theme.Tomato),
		block(V(1.2, 1.4, 0.1), V(0, -1.1, 1.62), Theme.WoodDark),
	},
	MarbleBag = {
		cyl(2.2, 2, V(0, 0, 0), Theme.Wood, nil, Fabric),
		cyl(1.2, 0.4, V(0, 1.1, 0), Theme.Tomato),
		ball(0.8, V(1.5, -0.7, 1.4), Theme.Sky),
		ball(0.8, V(0.5, -0.8, 1.7), Theme.Tomato),
		ball(0.8, V(-0.6, -0.8, 1.5), Theme.Mint),
		ball(0.8, V(-1.6, -0.7, 1.2), Theme.Sunflower),
	},
	TeddyBear = {
		ball(2.4, V(0, -0.6, 0), Theme.Wood, Fabric),
		ball(1.8, V(0, 1.1, 0), Theme.Wood, Fabric),
		ball(0.7, V(-0.8, 1.9, 0), Theme.Wood, Fabric),
		ball(0.7, V(0.8, 1.9, 0), Theme.Wood, Fabric),
		ball(0.8, V(0, 0.95, 0.8), Theme.Cream, Fabric),
		ball(0.3, V(0, 1.15, 1.15), Theme.Ink),
		ball(0.22, V(-0.4, 1.4, 0.8), Theme.Ink),
		ball(0.22, V(0.4, 1.4, 0.8), Theme.Ink),
		ball(0.9, V(-1.3, -0.2, 0.4), Theme.Wood, Fabric),
		ball(0.9, V(1.3, -0.2, 0.4), Theme.Wood, Fabric),
		ball(1, V(-0.8, -1.7, 0.5), Theme.Wood, Fabric),
		ball(1, V(0.8, -1.7, 0.5), Theme.Wood, Fabric),
	},
	Bunny = {
		ball(2.2, V(0, -0.6, 0), Theme.Paper, Fabric),
		ball(1.6, V(0, 1, 0.2), Theme.Paper, Fabric),
		block(V(0.5, 1.8, 0.3), V(-0.4, 2.4, 0.1), Theme.Paper, V(0, 0, 8), Fabric),
		block(V(0.5, 1.8, 0.3), V(0.4, 2.4, 0.1), Theme.Paper, V(0, 0, -8), Fabric),
		ball(0.22, V(-0.35, 1.2, 0.95), Theme.Ink),
		ball(0.22, V(0.35, 1.2, 0.95), Theme.Ink),
		ball(0.28, V(0, 0.9, 1), Theme.Tomato),
		ball(0.8, V(0, -0.9, -1.1), Theme.Paper, Fabric),
		ball(0.8, V(-0.7, -1.7, 0.7), Theme.Paper, Fabric),
		ball(0.8, V(0.7, -1.7, 0.7), Theme.Paper, Fabric),
	},
	PlushDragon = {
		ball(2.4, V(0, -0.5, 0), Theme.Mint, Fabric),
		ball(1.7, V(0, 1.2, 0.5), Theme.Mint, Fabric),
		ball(0.9, V(0, 1, 1.3), Theme.Paper, Fabric),
		ball(0.3, V(-0.45, 1.7, 1.05), Theme.Ink),
		ball(0.3, V(0.45, 1.7, 1.05), Theme.Ink),
		block(V(0.25, 0.7, 0.25), V(-0.5, 2.1, 0.4), Theme.Sunflower),
		block(V(0.25, 0.7, 0.25), V(0.5, 2.1, 0.4), Theme.Sunflower),
		block(V(0.2, 1.6, 1.4), V(-1.4, 0.2, -0.5), Theme.Tomato, V(0, 0, 25), Fabric),
		block(V(0.2, 1.6, 1.4), V(1.4, 0.2, -0.5), Theme.Tomato, V(0, 0, -25), Fabric),
		ball(0.9, V(0, -1.2, -1.4), Theme.Mint, Fabric),
		ball(0.6, V(0, -0.9, -2), Theme.Mint, Fabric),
	},
}

local ToyModels = {}

-- Arma el juguete de ese objeto, o devuelve nil si no hay uno con ese id.
-- Quien lo pide lo coloca (PivotTo) y lo pone dentro del mundo o de una vista previa.
function ToyModels.build(itemId: string): Model?
	local specs = definitions[itemId]
	if specs == nil then
		return nil
	end

	local model = Instance.new("Model")
	model.Name = itemId
	for _, spec in specs do
		local part = Instance.new("Part")
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.CastShadow = false
		part.TopSurface = Enum.SurfaceType.Smooth
		part.BottomSurface = Enum.SurfaceType.Smooth
		part.Color = spec.color
		part.Material = spec.material or Enum.Material.SmoothPlastic

		local rotation = CFrame.new()
		if spec.rot then
			rotation = CFrame.Angles(math.rad(spec.rot.X), math.rad(spec.rot.Y), math.rad(spec.rot.Z))
		end
		local cframe = CFrame.new(spec.pos) * rotation

		if spec.kind == "Ball" then
			part.Shape = Enum.PartType.Ball
			part.Size = spec.size
		elseif spec.kind == "Cylinder" then
			-- El cilindro de Roblox tiene su eje en X: se endereza para que quede de pie
			part.Shape = Enum.PartType.Cylinder
			part.Size = V(spec.size.Y, spec.size.X, spec.size.Z)
			cframe = cframe * CFrame.Angles(0, 0, PI / 2)
		else
			part.Size = spec.size
		end
		part.CFrame = cframe
		part.Parent = model
	end
	return model
end

return table.freeze(ToyModels)
