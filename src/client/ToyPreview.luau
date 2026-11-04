--!strict
-- Vista previa en 3D de un juguete dentro de un cuadro de la pantalla (ViewportFrame).
-- Cada tarjeta tiene una quieta; el panel de detalle tiene una que puede girar.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ToyModels = require(ReplicatedStorage.Shared.ToyModels)

local FIELD_OF_VIEW = 30
local VIEW_DIRECTION = Vector3.new(0.45, 0.3, 1).Unit -- desde dónde se mira el juguete

export type Preview = {
	viewport: ViewportFrame,
	show: (itemId: string) -> (),
	setAngle: (radians: number) -> (),
}

local ToyPreview = {}

function ToyPreview.new(parent: Instance): Preview
	local viewport = Instance.new("ViewportFrame")
	viewport.Name = "Preview"
	viewport.BackgroundTransparency = 1
	viewport.Ambient = Color3.fromRGB(190, 184, 172)
	viewport.LightColor = Color3.fromRGB(255, 244, 226)
	viewport.LightDirection = Vector3.new(-0.5, -1, -0.7)

	local camera = Instance.new("Camera")
	camera.FieldOfView = FIELD_OF_VIEW
	camera.Parent = viewport
	viewport.CurrentCamera = camera
	viewport.Parent = parent

	local model: Model? = nil
	local center = Vector3.zero
	local basePivot = CFrame.new()

	local function show(itemId: string)
		if model then
			model:Destroy()
			model = nil
		end
		local toy = ToyModels.build(itemId)
		if toy == nil then
			return
		end
		toy.Parent = viewport
		model = toy

		-- La cámara se aleja lo justo para que el juguete entero quepa
		local boxCFrame, boxSize = toy:GetBoundingBox()
		center = boxCFrame.Position
		basePivot = toy:GetPivot()
		local radius = boxSize.Magnitude / 2
		local distance = radius / math.tan(math.rad(FIELD_OF_VIEW / 2)) * 1.08
		camera.CFrame = CFrame.lookAt(center + VIEW_DIRECTION * distance, center)
	end

	-- Gira el juguete sobre sí mismo (alrededor de su centro, en vertical)
	local function setAngle(radians: number)
		if model == nil then
			return
		end
		model:PivotTo(CFrame.new(center) * CFrame.Angles(0, radians, 0) * CFrame.new(-center) * basePivot)
	end

	return { viewport = viewport, show = show, setAngle = setAngle }
end

return ToyPreview
