--!strict
-- Una tarjeta de juguete en la cuadrícula: vista previa, nombre, precio y, si ya lo tienes,
-- una etiqueta. Un toque la selecciona; un segundo toque confirma (lo decide ShopWindow).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local ItemCatalog = require(ReplicatedStorage.Shared.ItemCatalog)
local ShopCatalog = require(ReplicatedStorage.Shared.ShopCatalog)
local Theme = require(ReplicatedStorage.Shared.Theme)
local Motion = require(script.Parent.Motion)
local ToyPreview = require(script.Parent.ToyPreview)
local UiKit = require(script.Parent.UiKit)

export type Card = {
	itemId: string,
	category: string,
	root: Frame, -- la casilla de la cuadrícula; se muestra u oculta con root.Visible
	button: TextButton,
	playEnter: (delaySeconds: number) -> (),
	pop: () -> (),
	setOwned: (count: number) -> (),
	setSelected: (selected: boolean) -> (),
	setHighlight: (highlighted: boolean) -> (),
}

local ShopCard = {}

function ShopCard.new(parent: Instance, entry: ShopCatalog.Entry, layoutOrder: number, onActivate: (itemId: string) -> ()): Card
	local info = ItemCatalog[entry.ItemId]

	-- La casilla ocupa su lugar en la cuadrícula; la tarjeta vive dentro y puede crecer y
	-- girar desde su centro sin mover a las demás.
	local slot = Instance.new("Frame")
	slot.Name = entry.ItemId
	slot.BackgroundTransparency = 1
	slot.LayoutOrder = layoutOrder

	local button = Instance.new("TextButton")
	button.Name = "Card"
	button.AnchorPoint = Vector2.new(0.5, 0.5)
	button.Position = UDim2.fromScale(0.5, 0.5)
	button.Size = UDim2.fromScale(1, 1)
	button.Text = ""
	button.AutoButtonColor = false
	button.BackgroundColor3 = Theme.Paper
	button.BorderSizePixel = 0
	UiKit.corner(button, 14)
	local stroke = UiKit.stroke(button, 3)

	local scale = Instance.new("UIScale")
	scale.Parent = button
	-- Unas giran a un lado y otras al otro, para que no se vea mecánico
	local wiggle = if layoutOrder % 2 == 0 then 2.5 else -2.5

	local preview = ToyPreview.new(button)
	preview.viewport.Position = UDim2.fromOffset(6, 6)
	preview.viewport.Size = UDim2.new(1, -12, 0.46, 0)
	preview.show(entry.ItemId)

	local name = UiKit.label(button, info.DisplayName, 16, Theme.Ink, Theme.TitleFont)
	name.Position = UDim2.new(0, 6, 0.49, 0)
	name.Size = UDim2.new(1, -12, 0.31, 0)
	name.TextXAlignment = Enum.TextXAlignment.Center
	name.TextYAlignment = Enum.TextYAlignment.Center

	-- Precio: moneda y número, centrados
	local priceRow = Instance.new("Frame")
	priceRow.BackgroundTransparency = 1
	priceRow.Position = UDim2.new(0, 6, 0.81, 0)
	priceRow.Size = UDim2.new(1, -12, 0.17, 0)
	priceRow.Parent = button
	local rowLayout = Instance.new("UIListLayout")
	rowLayout.FillDirection = Enum.FillDirection.Horizontal
	rowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	rowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	rowLayout.Padding = UDim.new(0, 5)
	rowLayout.Parent = priceRow
	UiKit.coinIcon(priceRow, 20)
	local price = UiKit.label(priceRow, tostring(entry.Price), 18, Theme.Ink, Theme.TitleFont)
	price.AutomaticSize = Enum.AutomaticSize.X
	price.Size = UDim2.fromOffset(0, 22)
	price.TextWrapped = false

	-- Etiqueta de "ya lo tienes" arriba a la derecha
	local badge = UiKit.label(button, "", 16, Theme.Ink, Theme.TitleFont)
	badge.AnchorPoint = Vector2.new(1, 0)
	badge.Position = UDim2.new(1, -8, 0, 8)
	badge.Size = UDim2.fromOffset(0, 24)
	badge.AutomaticSize = Enum.AutomaticSize.X
	badge.BackgroundTransparency = 0
	badge.BackgroundColor3 = Theme.Mint
	badge.TextWrapped = false
	badge.Visible = false
	badge.ZIndex = 3
	UiKit.round(badge)
	UiKit.stroke(badge, 2)
	local badgePadding = Instance.new("UIPadding")
	badgePadding.PaddingLeft = UDim.new(0, 8)
	badgePadding.PaddingRight = UDim.new(0, 8)
	badgePadding.Parent = badge

	local selected = false
	local highlighted = false

	local LIFT_INFO = TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	-- Al enfocarla (cursor o mando) la tarjeta se levanta y se inclina un poco; al elegirla
	-- queda un poco más grande. Con "menos movimiento" solo cambia el contorno.
	local function applyLift()
		if Motion.isReduced() then
			scale.Scale = 1
			button.Rotation = 0
			return
		end
		local target = if selected then 1.05 elseif highlighted then 1.07 else 1
		Motion.tween(scale, LIFT_INFO, { Scale = target })
		Motion.tween(button, LIFT_INFO, { Rotation = if highlighted and not selected then wiggle else 0 })
	end

	-- El contorno cuenta el estado: normal, enfocado (cursor o mando) o elegido
	local function refreshLook()
		if selected then
			stroke.Color = Theme.Tomato
			stroke.Thickness = 5
			button.BackgroundColor3 = Theme.Cream
		elseif highlighted then
			stroke.Color = Theme.Sky
			stroke.Thickness = 4
			button.BackgroundColor3 = Theme.Paper
		else
			stroke.Color = Theme.Ink
			stroke.Thickness = 3
			button.BackgroundColor3 = Theme.Paper
		end
		applyLift()
	end

	-- Tres formas de "enfocar" una tarjeta, todas con el mismo aspecto:
	-- cursor encima (mouse), selección con el mando, o elegida con un toque (selected)
	UiKit.hideDefaultFocus(button)
	button.MouseEnter:Connect(function()
		if UserInputService.MouseEnabled then
			highlighted = true
			refreshLook()
		end
	end)
	button.MouseLeave:Connect(function()
		highlighted = false
		refreshLook()
	end)
	button.SelectionGained:Connect(function()
		highlighted = true
		refreshLook()
	end)
	button.SelectionLost:Connect(function()
		highlighted = false
		refreshLook()
	end)

	button.Activated:Connect(function()
		onActivate(entry.ItemId)
	end)

	button.Parent = slot
	slot.Parent = parent

	-- Entrada: la tarjeta aparece con un saltito, una tras otra (la ventana pasa el retraso)
	local function playEnter(delaySeconds: number)
		if Motion.isReduced() then
			scale.Scale = 1
			return
		end
		scale.Scale = 0.01
		task.delay(delaySeconds, function()
			Motion.tween(scale, TweenInfo.new(0.24, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 })
		end)
	end

	-- Al comprar: un saltito de alegría
	local function pop()
		if Motion.isReduced() then
			return
		end
		local grow = Motion.tween(scale, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1.16 })
		if grow then
			grow.Completed:Once(function()
				Motion.tween(scale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = if selected then 1.05 else 1 })
			end)
		end
	end

	return {
		itemId = entry.ItemId,
		category = entry.Category,
		root = slot,
		button = button,
		playEnter = playEnter,
		pop = pop,
		setOwned = function(count: number)
			badge.Visible = count > 0
			badge.Text = if info.MaxStack == 1 then "¡Tuyo!" else `x{count}`
		end,
		setSelected = function(value: boolean)
			selected = value
			refreshLook()
		end,
		setHighlight = function(value: boolean)
			highlighted = value
			refreshLook()
		end,
	}
end

return ShopCard
