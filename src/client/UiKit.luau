--!strict
-- Piezas pequeñas de interfaz que se repiten: esquinas, contornos, textos, la moneda
-- dibujada y el efecto de "botón que se hunde" al pulsarlo.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Theme = require(ReplicatedStorage.Shared.Theme)
local Motion = require(script.Parent.Motion)

local PRESS_SCALE = 0.96
local PRESS_SECONDS = 0.08

local UiKit = {}

function UiKit.corner(parent: Instance, radius: number): UICorner
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
	return corner
end

-- Esquinas totalmente redondas (círculo o píldora)
function UiKit.round(parent: Instance): UICorner
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = parent
	return corner
end

-- Contorno grueso de color tinta: es lo que da el aspecto de "recortes de cartón"
function UiKit.stroke(parent: Instance, thickness: number, color: Color3?): UIStroke
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = thickness
	stroke.Color = color or Theme.Ink
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = parent
	return stroke
end

function UiKit.label(parent: Instance, text: string, size: number, color: Color3?, font: Enum.Font?): TextLabel
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Font = font or Theme.BodyFont
	label.TextSize = size
	label.TextColor3 = color or Theme.Ink
	label.Text = text
	label.TextWrapped = true
	label.Parent = parent
	return label
end

-- Moneda dibujada con dos círculos: oro con borde y un anillo en el centro
function UiKit.coinIcon(parent: Instance, size: number): Frame
	local coin = Instance.new("Frame")
	coin.Name = "CoinIcon"
	coin.Size = UDim2.fromOffset(size, size)
	coin.BackgroundColor3 = Theme.Sunflower
	coin.BorderSizePixel = 0
	UiKit.round(coin)
	UiKit.stroke(coin, math.max(2, math.floor(size / 10)))

	local ring = Instance.new("Frame")
	ring.Name = "Ring"
	ring.AnchorPoint = Vector2.new(0.5, 0.5)
	ring.Position = UDim2.fromScale(0.5, 0.5)
	ring.Size = UDim2.fromScale(0.56, 0.56)
	ring.BackgroundTransparency = 1
	UiKit.round(ring)
	UiKit.stroke(ring, math.max(1.5, size / 14), Theme.Wood:Lerp(Theme.Sunflower, 0.35))
	ring.Parent = coin

	coin.Parent = parent
	return coin
end

-- Quita el recuadro blanco que Roblox dibuja al enfocar un botón con el mando: cada
-- botón muestra el foco a su manera (contorno de color), igual que con el cursor.
function UiKit.hideDefaultFocus(button: GuiButton)
	local none = Instance.new("Frame")
	none.BackgroundTransparency = 1
	none.BorderSizePixel = 0
	button.SelectionImageObject = none
end

-- ¿Se está jugando con mando ahora mismo?
function UiKit.isGamepadActive(): boolean
	return string.sub(UserInputService:GetLastInputType().Name, 1, 7) == "Gamepad"
end

-- Botón de bloque: fondo de color, contorno, texto grande. Se hunde un poco al pulsarlo.
function UiKit.blockButton(parent: Instance, text: string, textSize: number, color: Color3, textColor: Color3): TextButton
	local button = Instance.new("TextButton")
	button.AutoButtonColor = false
	button.BackgroundColor3 = color
	button.BorderSizePixel = 0
	button.Font = Theme.TitleFont
	button.TextSize = textSize
	button.TextColor3 = textColor
	button.Text = text
	UiKit.corner(button, 14)
	local stroke = UiKit.stroke(button, 3)
	UiKit.pressable(button)
	UiKit.hideDefaultFocus(button)

	-- Foco con cursor (solo si hay mouse) o con mando: el contorno se pone azul y más grueso
	local function setFocus(focused: boolean)
		stroke.Color = if focused then Theme.Sky else Theme.Ink
		stroke.Thickness = if focused then 5 else 3
	end
	button.MouseEnter:Connect(function()
		if UserInputService.MouseEnabled then
			setFocus(true)
		end
	end)
	button.MouseLeave:Connect(function()
		setFocus(false)
	end)
	button.SelectionGained:Connect(function()
		setFocus(true)
	end)
	button.SelectionLost:Connect(function()
		setFocus(false)
	end)

	button.Parent = parent
	return button
end

-- Efecto de pulsar: el botón se achica un poco mientras está apretado y vuelve al soltar.
-- Funciona igual con mouse, dedo y mando (todos disparan el mismo evento de pulsación).
function UiKit.pressable(button: GuiButton): UIScale
	local scale = Instance.new("UIScale")
	scale.Parent = button

	local function setScale(target: number)
		Motion.tween(scale, TweenInfo.new(PRESS_SECONDS, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = target })
	end
	button.MouseButton1Down:Connect(function()
		setScale(PRESS_SCALE)
	end)
	button.MouseButton1Up:Connect(function()
		setScale(1)
	end)
	button.MouseLeave:Connect(function()
		setScale(1)
	end)
	return scale
end

return UiKit
