--!strict
-- El cartelito que aparece al acercarse al mostrador, con los colores del taller en vez del
-- diseño normal de Roblox. Solo cambia cómo se ve: quien decide si se abre la tienda sigue
-- siendo el aviso de proximidad (tecla, botón del mando o toque), igual que antes.

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Theme = require(ReplicatedStorage.Shared.Theme)
local Motion = require(script.Parent.Motion)
local UiKit = require(script.Parent.UiKit)

local PANEL_WIDTH = 300
local PANEL_HEIGHT = 76
local BADGE_SIZE = 52
local HEIGHT_ABOVE_PART = 3.2 -- studs por encima del mostrador
local APPEAR_SECONDS = 0.2
local HIDE_SECONDS = 0.1

local PromptUi = {}

-- Letra que se muestra en la insignia según cómo juegue la persona (nil = toque, sin letra)
local function keyText(prompt: ProximityPrompt, inputType: Enum.ProximityPromptInputType): string?
	if inputType == Enum.ProximityPromptInputType.Keyboard then
		return UserInputService:GetStringForKeyCode(prompt.KeyboardKeyCode)
	elseif inputType == Enum.ProximityPromptInputType.Gamepad then
		return (string.gsub(UserInputService:GetStringForKeyCode(prompt.GamepadKeyCode), "^Button", ""))
	end
	return nil
end

local function build(prompt: ProximityPrompt, inputType: Enum.ProximityPromptInputType, parent: Instance): (BillboardGui, UIScale)
	local gui = Instance.new("BillboardGui")
	gui.Name = "ShopPrompt"
	gui.Adornee = prompt.Parent :: Instance
	gui.Size = UDim2.fromOffset(PANEL_WIDTH, PANEL_HEIGHT)
	gui.StudsOffset = Vector3.new(0, HEIGHT_ABOVE_PART, 0)
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	gui.ResetOnSpawn = false

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.fromScale(1, 1)
	panel.BackgroundColor3 = Theme.Paper
	panel.BorderSizePixel = 0
	UiKit.corner(panel, 18)
	UiKit.stroke(panel, 4)
	panel.Parent = gui

	local scale = Instance.new("UIScale")
	scale.Parent = panel

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 12)
	layout.Parent = panel
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 12)
	padding.PaddingRight = UDim.new(0, 12)
	padding.Parent = panel

	local textLeft = 0
	local letter = keyText(prompt, inputType)
	if letter then
		local badge = Instance.new("Frame")
		badge.Name = "KeyBadge"
		badge.LayoutOrder = 1
		badge.Size = UDim2.fromOffset(BADGE_SIZE, BADGE_SIZE)
		badge.BackgroundColor3 = Theme.Sunflower
		badge.BorderSizePixel = 0
		UiKit.corner(badge, 14)
		UiKit.stroke(badge, 3)
		badge.Parent = panel
		local key = UiKit.label(badge, letter, 30, Theme.Ink, Theme.TitleFont)
		key.Size = UDim2.fromScale(1, 1)
		key.TextWrapped = false
		textLeft = BADGE_SIZE + 12
	end

	local texts = Instance.new("Frame")
	texts.Name = "Texts"
	texts.LayoutOrder = 2
	texts.Size = UDim2.new(1, -(24 + textLeft), 1, -16) -- 24 = los márgenes laterales del cartelito
	texts.BackgroundTransparency = 1
	texts.Parent = panel
	local textsLayout = Instance.new("UIListLayout")
	textsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	textsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	textsLayout.Parent = texts

	local action = UiKit.label(texts, prompt.ActionText, 24, Theme.Ink, Theme.TitleFont)
	action.LayoutOrder = 1
	action.Size = UDim2.new(1, 0, 0, 30)
	action.TextXAlignment = Enum.TextXAlignment.Left
	action.TextWrapped = false
	action.TextTruncate = Enum.TextTruncate.AtEnd

	if prompt.ObjectText ~= "" then
		local object = UiKit.label(texts, prompt.ObjectText, 15, Theme.WoodDark, Theme.BodyFont)
		object.LayoutOrder = 2
		object.Size = UDim2.new(1, 0, 0, 20)
		object.TextXAlignment = Enum.TextXAlignment.Left
		object.TextWrapped = false
		object.TextTruncate = Enum.TextTruncate.AtEnd
	end

	-- Con el dedo o el mouse, todo el cartelito es un botón; con tecla o mando no hace falta
	local hit = Instance.new("TextButton")
	hit.Name = "Hit"
	hit.Size = UDim2.fromScale(1, 1)
	hit.BackgroundTransparency = 1
	hit.Text = ""
	hit.ZIndex = 5
	hit.AutoButtonColor = false
	hit.Parent = gui -- fuera del panel: dentro, la lista de colocación lo trataría como un elemento más y empujaría el texto fuera
	hit.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			prompt:InputHoldBegin()
		end
	end)
	hit.InputEnded:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			prompt:InputHoldEnd()
		end
	end)
	hit.MouseEnter:Connect(function()
		if UserInputService.MouseEnabled then
			Motion.tween(scale, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1.05 })
		end
	end)
	hit.MouseLeave:Connect(function()
		Motion.tween(scale, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1 })
	end)

	gui.Parent = parent
	return gui, scale
end

function PromptUi.start()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	ProximityPromptService.PromptShown:Connect(function(prompt: ProximityPrompt, inputType: Enum.ProximityPromptInputType)
		if prompt.Style ~= Enum.ProximityPromptStyle.Custom or prompt.Parent == nil then
			return
		end
		local gui, scale = build(prompt, inputType, playerGui)

		-- Entra con un saltito corto; se va rápido, sin que estorbe
		scale.Scale = 0.85
		Motion.tween(scale, TweenInfo.new(APPEAR_SECONDS, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 })

		local hiddenConnection: RBXScriptConnection? = nil
		hiddenConnection = prompt.PromptHidden:Connect(function()
			if hiddenConnection then
				hiddenConnection:Disconnect()
			end
			Motion.tween(scale, TweenInfo.new(HIDE_SECONDS, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0.9 })
			task.delay(HIDE_SECONDS, function()
				gui:Destroy()
			end)
		end)
	end)
end

return PromptUi
