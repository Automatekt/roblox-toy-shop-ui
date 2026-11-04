--!strict
-- El panel de detalle: vista previa grande, nombre, descripción, precio y el botón de
-- comprar. El contenido se desplaza si la pantalla es chica, para que ningún texto se corte;
-- el botón de comprar queda siempre fijo y visible abajo.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemCatalog = require(ReplicatedStorage.Shared.ItemCatalog)
local ShopCatalog = require(ReplicatedStorage.Shared.ShopCatalog)
local Theme = require(ReplicatedStorage.Shared.Theme)
local ToyPreview = require(script.Parent.ToyPreview)
local UiKit = require(script.Parent.UiKit)

local BUY_HEIGHT = 56 -- zona de toque cómoda
local PREVIEW_HEIGHT = 124
local PLACEHOLDER_TEXT = "Toca un juguete para verlo de cerca."

export type BuyState = "ready" | "owned" | "busy"

export type Detail = {
	frame: Frame,
	preview: ToyPreview.Preview,
	buyButton: TextButton,
	showPlaceholder: () -> (),
	showEntry: (entry: ShopCatalog.Entry, owned: number, coins: number) -> (),
	setBuyState: (state: BuyState) -> (),
}

local ShopDetail = {}

function ShopDetail.new(parent: Instance, onBuy: () -> ()): Detail
	local frame = Instance.new("Frame")
	frame.Name = "Detail"
	frame.BackgroundColor3 = Theme.Paper
	frame.BorderSizePixel = 0
	UiKit.corner(frame, 14)
	UiKit.stroke(frame, 3)
	frame.Parent = parent

	-- Zona que se desplaza
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "Scroll"
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.Size = UDim2.new(1, 0, 1, -(BUY_HEIGHT + 18))
	scroll.CanvasSize = UDim2.fromOffset(0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.ScrollBarThickness = 6
	scroll.ScrollingDirection = Enum.ScrollingDirection.Y
	scroll.Parent = frame

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 10)
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 14)
	padding.PaddingBottom = UDim.new(0, 6)
	padding.Parent = scroll

	local list = Instance.new("UIListLayout")
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, 8)
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.Parent = scroll

	local previewHolder = Instance.new("Frame")
	previewHolder.Name = "PreviewHolder"
	previewHolder.LayoutOrder = 1
	previewHolder.Size = UDim2.new(1, 0, 0, PREVIEW_HEIGHT)
	previewHolder.BackgroundColor3 = Theme.Cream
	previewHolder.BorderSizePixel = 0
	UiKit.corner(previewHolder, 12)
	previewHolder.Parent = scroll
	local preview = ToyPreview.new(previewHolder)
	preview.viewport.Size = UDim2.fromScale(1, 1)

	local function autoLabel(text: string, size: number, font: Enum.Font, color: Color3, order: number): TextLabel
		local label = UiKit.label(scroll, text, size, color, font)
		label.LayoutOrder = order
		label.Size = UDim2.new(1, 0, 0, 0)
		label.AutomaticSize = Enum.AutomaticSize.Y
		label.TextXAlignment = Enum.TextXAlignment.Center
		return label
	end

	local nameLabel = autoLabel("", 26, Theme.TitleFont, Theme.Ink, 2)
	local descriptionLabel = autoLabel("", 19, Theme.BodyFont, Theme.Ink, 3)

	local priceRow = Instance.new("Frame")
	priceRow.Name = "PriceRow"
	priceRow.LayoutOrder = 4
	priceRow.BackgroundTransparency = 1
	priceRow.Size = UDim2.new(1, 0, 0, 34)
	priceRow.Parent = scroll
	local priceLayout = Instance.new("UIListLayout")
	priceLayout.FillDirection = Enum.FillDirection.Horizontal
	priceLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	priceLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	priceLayout.Padding = UDim.new(0, 8)
	priceLayout.Parent = priceRow
	UiKit.coinIcon(priceRow, 30)
	local priceLabel = UiKit.label(priceRow, "", 28, Theme.Ink, Theme.TitleFont)
	priceLabel.AutomaticSize = Enum.AutomaticSize.X
	priceLabel.Size = UDim2.fromOffset(0, 34)
	priceLabel.TextWrapped = false

	local hintLabel = autoLabel("", 18, Theme.BodyFont, Theme.Ink:Lerp(Theme.Sky, 0.55), 5)

	-- Mensaje de cuando no hay nada elegido
	local placeholder = UiKit.label(frame, PLACEHOLDER_TEXT, 21, Theme.Ink, Theme.BodyFont)
	placeholder.Name = "Placeholder"
	placeholder.AnchorPoint = Vector2.new(0.5, 0.5)
	placeholder.Position = UDim2.new(0.5, 0, 0.45, 0)
	placeholder.Size = UDim2.new(1, -28, 0, 90)
	placeholder.TextXAlignment = Enum.TextXAlignment.Center

	-- El botón de comprar, fijo abajo
	local buyButton = UiKit.blockButton(frame, "¡Lo quiero!", 26, Theme.Tomato, Theme.Paper)
	buyButton.Name = "Buy"
	buyButton.AnchorPoint = Vector2.new(0.5, 1)
	buyButton.Position = UDim2.new(0.5, 0, 1, -10)
	buyButton.Size = UDim2.new(1, -20, 0, BUY_HEIGHT)
	buyButton.Activated:Connect(onBuy)

	local function setBuyState(state: BuyState)
		if state == "owned" then
			buyButton.Text = "¡Ya lo tienes!"
			buyButton.BackgroundColor3 = Theme.Mint
			buyButton.AutoButtonColor = false
		elseif state == "busy" then
			buyButton.Text = "Un momento..."
			buyButton.BackgroundColor3 = Theme.Wood
		else
			buyButton.Text = "¡Lo quiero!"
			buyButton.BackgroundColor3 = Theme.Tomato
		end
	end

	local shownId: string? = nil -- el juguete que muestra la vista previa ahora

	local function showPlaceholder()
		shownId = nil
		scroll.Visible = false
		placeholder.Visible = true
		buyButton.Visible = false
	end

	local function showEntry(entry: ShopCatalog.Entry, owned: number, coins: number)
		local info = ItemCatalog[entry.ItemId]
		if shownId ~= entry.ItemId then
			shownId = entry.ItemId
			preview.show(entry.ItemId)
			scroll.CanvasPosition = Vector2.zero
		end
		scroll.Visible = true
		placeholder.Visible = false
		buyButton.Visible = true

		nameLabel.Text = info.DisplayName
		descriptionLabel.Text = entry.Description
		priceLabel.Text = tostring(entry.Price)

		local full = owned + 1 > info.MaxStack
		if full then
			hintLabel.Text = if info.MaxStack == 1 then "¡Este juguete ya es tuyo!" else "Ya tienes todas las que caben."
		elseif coins < entry.Price then
			hintLabel.Text = `Te faltan {entry.Price - coins} monedas`
		elseif info.MaxStack > 1 and owned > 0 then
			hintLabel.Text = `Ya tienes {owned}`
		else
			hintLabel.Text = ""
		end
		hintLabel.Visible = hintLabel.Text ~= ""
		setBuyState(if full then "owned" else "ready")
	end

	showPlaceholder()

	return {
		frame = frame,
		preview = preview,
		buyButton = buyButton,
		showPlaceholder = showPlaceholder,
		showEntry = showEntry,
		setBuyState = setBuyState,
	}
end

return ShopDetail
