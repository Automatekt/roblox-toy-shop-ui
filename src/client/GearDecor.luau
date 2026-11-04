--!strict
-- Un engranaje dibujado con cuadros de interfaz, de adorno en el fondo de la ventana:
-- muy tenue y con un giro lentísimo (una vuelta en casi un minuto). Se detiene con
-- la opción "menos movimiento" y mientras la ventana está cerrada.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Theme = require(ReplicatedStorage.Shared.Theme)

local TEETH = 8
local OPACITY = 0.78 -- transparencia de las piezas: se nota apenas

export type Gear = {
	start: () -> (),
	stop: () -> (),
}

local GearDecor = {}

-- "position" es el centro, en escala del contenedor. "sizeScale" es el diámetro como parte
-- del ancho del contenedor. Una vuelta completa tarda "secondsPerTurn" (negativo = al revés).
function GearDecor.new(parent: Instance, position: UDim2, sizeScale: number, secondsPerTurn: number): Gear
	local holder = Instance.new("Frame")
	holder.Name = "GearDecor"
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Position = position
	holder.Size = UDim2.fromScale(sizeScale, sizeScale)
	holder.BackgroundTransparency = 1
	holder.Active = false

	-- El tamaño sale del ancho: cuadrado en cualquier pantalla
	local square = Instance.new("UIAspectRatioConstraint")
	square.AspectRatio = 1
	square.DominantAxis = Enum.DominantAxis.Width
	square.Parent = holder

	local function piece(size: number, center: UDim2, round: boolean, color: Color3, transparency: number, rotation: number): Frame
		local frame = Instance.new("Frame")
		frame.AnchorPoint = Vector2.new(0.5, 0.5)
		frame.Position = center
		frame.Size = UDim2.fromScale(size, size)
		frame.BackgroundColor3 = color
		frame.BackgroundTransparency = transparency
		frame.BorderSizePixel = 0
		frame.Rotation = rotation
		frame.Active = false
		if round then
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0.5, 0)
			corner.Parent = frame
		end
		frame.Parent = holder
		return frame
	end

	-- Dientes: cuadrados girados, repartidos por el borde
	for index = 0, TEETH - 1 do
		local angle = index * 2 * math.pi / TEETH
		local x = 0.5 + math.cos(angle) * 0.44
		local y = 0.5 + math.sin(angle) * 0.44
		piece(0.2, UDim2.fromScale(x, y), false, Theme.Wood, OPACITY, math.deg(angle))
	end
	piece(0.82, UDim2.fromScale(0.5, 0.5), true, Theme.Wood, OPACITY, 0) -- cuerpo
	piece(0.34, UDim2.fromScale(0.5, 0.5), true, Theme.Cream, 0, 0) -- agujero del centro

	holder.Parent = parent

	local info = TweenInfo.new(math.abs(secondsPerTurn), Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1)
	local goal = { Rotation = if secondsPerTurn >= 0 then 360 else -360 }
	local tween: Tween? = nil

	return {
		start = function()
			if tween then
				return
			end
			holder.Rotation = 0
			tween = TweenService:Create(holder, info, goal)
			tween:Play()
		end,
		stop = function()
			if tween then
				tween:Cancel()
				tween = nil
			end
			holder.Rotation = 0
		end,
	}
end

return GearDecor
