--!strict
-- Una tarjeta de juguete en la cuadrícula: vista previa, nombre, precio y, si ya lo tienes,
-- una etiqueta. Un toque la selecciona; un segundo toque confirma (lo decide ShopWindow).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local ItemCatalog = require(ReplicatedStorage.Shared.ItemCatalog)
local ShopCatalog = require(ReplicatedStorage.Shared.ShopCatalog)
local Theme = require(ReplicatedStorage.Shared.Theme)
local ToyPreview = require(script.Parent.ToyPreview)
local UiKit = require(script.Parent.UiKit)

export type Card = {
	itemId: string,
	category: string,
	button: TextButton,
	setOwned: (count: number) -> (),
	setSelected: (selected: boolean) -> (),
	setHighlight: (highlighted: boolean) -> (),
}

local ShopCard = {}

function ShopCard.new(parent: Instance, entry: ShopCatalog.Entry, layoutOrder: number, onActivate: (itemId: string) -> ()): Card
	local info = ItemCatalog[entry.ItemId]

	local button = Instance.new("TextButton")
	button.Name = entry.ItemId
	button.Text = ""
	button.AutoButtonColor = false
	button.BackgroundColor3 = Theme.Paper
	button.BorderSizePixel = 0
	button.LayoutOrder = layoutOrder
	UiKit.corner(button, 14)
	local stroke = UiKit.stroke(button, 3)

	local preview = ToyPreview.new(button)
	preview.viewport.Position = UDim2.fromOffset(6, 6)
	preview.viewport.Size = UDim2.new(1, -12, 0.48, 0)
	preview.show(entry.ItemId)

	local name = UiKit.label(button, info.DisplayName, 16, Theme.Ink, Theme.TitleFont)
	name.Position = UDim2.new(0, 6, 0.5, 0)
	name.Size = UDim2.new(1, -12, 0.29, 0)
	name.TextXAlignment = Enum.TextXAlignment.Center
	name.TextYAlignment = Enum.TextYAlignment.Center

	-- Precio: moneda y número, centrados
	local priceRow = Instance.new("Frame")
	priceRow.BackgroundTransparency = 1
	priceRow.Position = UDim2.new(0, 6, 0.79, 0)
	priceRow.Size = UDim2.new(1, -12, 0.19, 0)
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

	button.Parent = parent

	return {
		itemId = entry.ItemId,
		category = entry.Category,
		button = button,
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
