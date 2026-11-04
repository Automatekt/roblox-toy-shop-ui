--!strict
-- La ventana de la tienda: categorías, cuadrícula de juguetes y panel de detalle.
-- Se adapta al tamaño de la pantalla: en pantallas anchas pone las categorías a la
-- izquierda y el detalle a la derecha; en pantallas angostas lo apila todo hacia abajo.
-- El cliente solo pide "comprar este id"; el servidor decide si se puede.

local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local DataAttributes = require(ReplicatedStorage.Shared.DataAttributes)
local ItemCatalog = require(ReplicatedStorage.Shared.ItemCatalog)
local ShopCatalog = require(ReplicatedStorage.Shared.ShopCatalog)
local Theme = require(ReplicatedStorage.Shared.Theme)
local GearDecor = require(script.Parent.GearDecor)
local Motion = require(script.Parent.Motion)
local PurchaseClient = require(script.Parent.PurchaseClient)
local Sfx = require(script.Parent.Sfx)
local ShopCard = require(script.Parent.ShopCard)
local ShopDetail = require(script.Parent.ShopDetail)
local UiKit = require(script.Parent.UiKit)

local HEADER_HEIGHT = 44
local BOTTOM_ROW = 40 -- alto de cada fila de la barra de abajo
local BOTTOM_NARROW_WIDTH = 400 -- por debajo de este ancho los interruptores van en dos filas
local GAP = 10
local TABS_WIDTH = 112
local MIN_CARD_WIDTH = 108
local CARD_GAP = 8
local GRID_PADDING = 6
local CLOSE_ACTION = "CloseShop"
local MIN_REQUEST_INTERVAL = 0.45 -- segundos entre dos compras desde este cliente (el servidor también limita)
local TOAST_SECONDS = 2.6

local ShopWindow = {}

function ShopWindow.start(hudGui: ScreenGui)
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local categories = ShopCatalog.Categories

	local gui = Instance.new("ScreenGui")
	gui.Name = "ShopWindow"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 10
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	gui.Enabled = false

	-- Fondo que oscurece el taller y no deja pasar toques a lo que hay detrás
	local dim = Instance.new("Frame")
	dim.Name = "Dim"
	dim.Size = UDim2.fromScale(1, 1)
	dim.BackgroundColor3 = Theme.Ink
	dim.BackgroundTransparency = 0.45
	dim.BorderSizePixel = 0
	dim.Active = true
	dim.Parent = gui

	local window = Instance.new("Frame")
	window.Name = "Window"
	window.AnchorPoint = Vector2.new(0.5, 0.5)
	window.Position = UDim2.fromScale(0.5, 0.5)
	window.Size = UDim2.fromScale(0.94, 0.9)
	window.BackgroundColor3 = Theme.Cream
	window.BorderSizePixel = 0
	UiKit.corner(window, 20)
	UiKit.stroke(window, 4)
	window.Parent = gui

	local limit = Instance.new("UISizeConstraint")
	limit.MaxSize = Vector2.new(940, 600)
	limit.MinSize = Vector2.new(280, 220)
	limit.Parent = window

	local windowScale = Instance.new("UIScale")
	windowScale.Parent = window

	-- Engranajes tenues de fondo, detrás de todo lo demás, girando muy despacio
	local gears = {
		GearDecor.new(window, UDim2.fromScale(0.88, 0.8), 0.2, 55),
		GearDecor.new(window, UDim2.fromScale(0.1, 0.18), 0.14, -42),
	}

	-- Una línea fina por dentro, como la costura de una caja de cartón
	local stitch = Instance.new("Frame")
	stitch.Name = "Stitch"
	stitch.Position = UDim2.fromOffset(7, 7)
	stitch.Size = UDim2.new(1, -14, 1, -14)
	stitch.BackgroundTransparency = 1
	UiKit.corner(stitch, 14)
	UiKit.stroke(stitch, 2, Theme.Wood)
	stitch.Parent = window

	local content = Instance.new("Frame")
	content.Name = "Content"
	content.Position = UDim2.fromOffset(16, 16)
	content.Size = UDim2.new(1, -32, 1, -32)
	content.BackgroundTransparency = 1
	content.Parent = window

	-- Encabezado: título y botón de cerrar
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, HEADER_HEIGHT)
	header.BackgroundTransparency = 1
	header.Parent = content

	local title = UiKit.label(header, "Taller de juguetes", 30, Theme.Ink, Theme.TitleFont)
	title.Size = UDim2.new(1, -60, 1, 0)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextWrapped = false

	local closeButton = UiKit.blockButton(header, "X", 26, Theme.Tomato, Theme.Paper)
	closeButton.Name = "Close"
	closeButton.AnchorPoint = Vector2.new(1, 0.5)
	closeButton.Position = UDim2.new(1, 0, 0.5, 0)
	closeButton.Size = UDim2.fromOffset(44, 44)

	-- Cuerpo: categorías, cuadrícula y detalle (se acomodan en layoutBody)
	local body = Instance.new("Frame")
	body.Name = "Body"
	body.Position = UDim2.fromOffset(0, HEADER_HEIGHT + 8)
	body.Size = UDim2.new(1, 0, 1, -(HEADER_HEIGHT + 8 + BOTTOM_ROW + 8))
	body.BackgroundTransparency = 1
	body.Parent = content

	local bottomBar = Instance.new("Frame")
	bottomBar.Name = "BottomBar"
	bottomBar.AnchorPoint = Vector2.new(0, 1)
	bottomBar.Position = UDim2.fromScale(0, 1)
	bottomBar.Size = UDim2.new(1, 0, 0, BOTTOM_ROW)
	bottomBar.BackgroundTransparency = 1
	bottomBar.Parent = content

	local tabsFrame = Instance.new("Frame")
	tabsFrame.Name = "Tabs"
	tabsFrame.BackgroundTransparency = 1
	tabsFrame.Parent = body
	local tabsLayout = Instance.new("UIListLayout")
	tabsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	tabsLayout.Padding = UDim.new(0, 8)
	tabsLayout.Parent = tabsFrame

	local grid = Instance.new("ScrollingFrame")
	grid.Name = "Grid"
	grid.BackgroundTransparency = 1
	grid.BorderSizePixel = 0
	grid.CanvasSize = UDim2.fromOffset(0, 0)
	grid.AutomaticCanvasSize = Enum.AutomaticSize.Y
	grid.ScrollBarThickness = 8
	grid.ScrollingDirection = Enum.ScrollingDirection.Y
	grid.Parent = body
	local gridPadding = Instance.new("UIPadding")
	gridPadding.PaddingTop = UDim.new(0, GRID_PADDING)
	gridPadding.PaddingBottom = UDim.new(0, GRID_PADDING)
	gridPadding.PaddingLeft = UDim.new(0, GRID_PADDING)
	gridPadding.PaddingRight = UDim.new(0, GRID_PADDING)
	gridPadding.Parent = grid
	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	gridLayout.CellPadding = UDim2.fromOffset(CARD_GAP, CARD_GAP)
	gridLayout.CellSize = UDim2.fromOffset(MIN_CARD_WIDTH, 132)
	gridLayout.Parent = grid

	-- Interruptores de la barra de abajo: sonido y menos movimiento
	local bottomLayout = Instance.new("UIListLayout")
	bottomLayout.FillDirection = Enum.FillDirection.Horizontal
	bottomLayout.Wraps = true
	bottomLayout.Padding = UDim.new(0, 8)
	bottomLayout.SortOrder = Enum.SortOrder.LayoutOrder
	bottomLayout.Parent = bottomBar

	local soundToggle = UiKit.toggle(bottomBar, "Sonido", Sfx.isEnabled(), function(on: boolean)
		Sfx.setEnabled(on)
	end)
	soundToggle.LayoutOrder = 1
	local motionToggle = UiKit.toggle(bottomBar, "Menos movimiento", Motion.isReduced(), function(on: boolean)
		Motion.setReduced(on)
	end)
	motionToggle.LayoutOrder = 2

	-- Aviso corto de resultado, encima del cuerpo
	local toast = Instance.new("Frame")
	toast.Name = "Toast"
	toast.AnchorPoint = Vector2.new(0.5, 1)
	toast.Position = UDim2.new(0.5, 0, 1, -8)
	toast.Size = UDim2.fromOffset(0, 0)
	toast.AutomaticSize = Enum.AutomaticSize.XY
	toast.BackgroundColor3 = Theme.Mint
	toast.Visible = false
	toast.ZIndex = 20
	UiKit.round(toast)
	UiKit.stroke(toast, 3)
	toast.Parent = body
	local toastPadding = Instance.new("UIPadding")
	toastPadding.PaddingLeft = UDim.new(0, 18)
	toastPadding.PaddingRight = UDim.new(0, 18)
	toastPadding.PaddingTop = UDim.new(0, 8)
	toastPadding.PaddingBottom = UDim.new(0, 8)
	toastPadding.Parent = toast
	local toastLimit = Instance.new("UISizeConstraint")
	toastLimit.MaxSize = Vector2.new(520, 120)
	toastLimit.Parent = toast
	local toastScale = Instance.new("UIScale")
	toastScale.Parent = toast
	local toastLabel = UiKit.label(toast, "", 20, Theme.Ink, Theme.TitleFont)
	toastLabel.AutomaticSize = Enum.AutomaticSize.XY
	toastLabel.Size = UDim2.fromOffset(0, 0)
	toastLabel.TextXAlignment = Enum.TextXAlignment.Center
	toastLabel.ZIndex = 21

	-- Estado
	local category = categories[1].Id
	local selectedId: string? = nil
	local pending = false
	local lastRequest = -math.huge
	local toastToken = 0

	local function getCoins(): number
		local value = playerGui:GetAttribute(DataAttributes.Coins)
		return if type(value) == "number" then value else 0
	end

	local function getOwned(itemId: string): number
		local value = playerGui:GetAttribute(DataAttributes.itemKey(itemId))
		return if type(value) == "number" then value else 0
	end

	local function showToast(text: string, good: boolean)
		toastToken += 1
		local mine = toastToken
		toastLabel.Text = text
		toast.BackgroundColor3 = if good then Theme.Mint else Theme.Sunflower
		toastScale.Scale = 0.9
		toast.Visible = true
		Motion.tween(toastScale, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 })
		task.delay(TOAST_SECONDS, function()
			if toastToken == mine then
				toast.Visible = false
			end
		end)
	end

	-- Panel de detalle
	local attemptBuy: (itemId: string) -> ()
	local detail = ShopDetail.new(body, function()
		if selectedId then
			attemptBuy(selectedId)
		end
	end)

	-- Tarjetas, una por producto
	local cards: { [string]: ShopCard.Card } = {}
	local tabs: { [string]: TextButton } = {}

	local previewAngle = 0.5

	local function selectItem(itemId: string?)
		if selectedId and cards[selectedId] then
			cards[selectedId].setSelected(false)
		end
		selectedId = itemId
		if itemId == nil then
			detail.showPlaceholder()
			return
		end
		cards[itemId].setSelected(true)
		local entry = ShopCatalog.get(itemId)
		if entry then
			detail.showEntry(entry, getOwned(itemId), getCoins())
			previewAngle = 0.5 -- un ángulo agradable de tres cuartos; con movimiento empieza a girar desde ahí
			detail.preview.setAngle(previewAngle)
		end
	end

	-- Un toque elige el juguete; un segundo toque sobre el mismo lo compra
	local function onCardActivated(itemId: string)
		if pending then
			return
		end
		if selectedId ~= itemId then
			selectItem(itemId)
		else
			attemptBuy(itemId)
		end
	end

	for index, entry in ShopCatalog.Entries do
		cards[entry.ItemId] = ShopCard.new(grid, entry, index, onCardActivated)
	end

	-- Actualiza las etiquetas de "ya lo tienes" y el detalle con los datos del servidor
	local function refresh()
		for itemId, card in cards do
			card.setOwned(getOwned(itemId))
		end
		if selectedId then
			local entry = ShopCatalog.get(selectedId)
			if entry then
				detail.showEntry(entry, getOwned(selectedId), getCoins())
			end
		end
	end

	function attemptBuy(itemId: string)
		if pending or os.clock() - lastRequest < MIN_REQUEST_INTERVAL then
			return
		end
		local entry = ShopCatalog.get(itemId)
		if entry == nil then
			return
		end
		local info = ItemCatalog[itemId]

		-- Si ya no cabe, se avisa sin molestar al servidor (él también lo comprobaría)
		if getOwned(itemId) + 1 > info.MaxStack then
			local text = PurchaseClient.messageFor(if info.MaxStack == 1 then "AlreadyOwned" else "InventoryFull", info.DisplayName, 0)
			showToast(text, false)
			return
		end

		pending = true
		lastRequest = os.clock()
		detail.setBuyState("busy")
		task.spawn(function()
			local result = PurchaseClient.buy(itemId)
			pending = false
			local missing = math.max(0, entry.Price - getCoins())
			local text, good = PurchaseClient.messageFor(result, info.DisplayName, missing)
			showToast(text, good)
			refresh()
			if result == "Ok" then
				Sfx.play("Buy")
				if cards[itemId] then
					cards[itemId].pop()
				end
			end
		end)
	end

	local function setCategory(categoryId: string)
		category = categoryId
		for tabId, tab in tabs do
			tab.BackgroundColor3 = if tabId == categoryId then Theme.Sunflower else Theme.Paper
		end
		local shown = 0
		for _, entry in ShopCatalog.Entries do
			local card = cards[entry.ItemId]
			local visible = card.category == categoryId
			card.root.Visible = visible
			if visible then
				card.playEnter(math.min(shown, 8) * 0.045)
				shown += 1
			end
		end
		selectItem(nil)
		grid.CanvasPosition = Vector2.zero
	end

	for index, categoryInfo in categories do
		local tab = UiKit.blockButton(tabsFrame, categoryInfo.DisplayName, 20, Theme.Paper, Theme.Ink)
		tab.Name = categoryInfo.Id
		tab.LayoutOrder = index
		tab.Activated:Connect(function()
			setCategory(categoryInfo.Id)
		end)
		tabs[categoryInfo.Id] = tab
	end

	-- Acomoda la cuadrícula: cuántas columnas caben y de qué tamaño es cada tarjeta
	local function layoutGrid(gridWidth: number)
		local usable = gridWidth - 2 * GRID_PADDING - 10 -- 10 = barra de desplazamiento
		local columns = math.max(1, math.floor((usable + CARD_GAP) / (MIN_CARD_WIDTH + CARD_GAP)))
		local cardWidth = math.floor((usable - (columns - 1) * CARD_GAP) / columns)
		local cardHeight = math.max(132, math.floor(cardWidth * 1.1))
		gridLayout.CellSize = UDim2.fromOffset(cardWidth, cardHeight)
	end

	-- En pantallas muy angostas los interruptores pasan a dos filas y el cuerpo cede ese espacio
	local function layoutBottom()
		local narrow = content.AbsoluteSize.X > 0 and content.AbsoluteSize.X < BOTTOM_NARROW_WIDTH
		local height = if narrow then BOTTOM_ROW * 2 + 8 else BOTTOM_ROW
		bottomBar.Size = UDim2.new(1, 0, 0, height)
		body.Size = UDim2.new(1, 0, 1, -(HEADER_HEIGHT + 8 + height + 8))
	end

	-- Dos disposiciones: ancha (tres columnas) y angosta (todo apilado)
	local function layoutBody()
		local size = body.AbsoluteSize
		if size.X < 50 or size.Y < 50 then
			return
		end
		local wide = size.X >= 560 and size.X >= size.Y * 1.2
		local count = #categories

		if wide then
			local detailWidth = math.clamp(math.floor(size.X * 0.36), 200, 300)
			local gridWidth = size.X - TABS_WIDTH - detailWidth - 2 * GAP
			tabsLayout.FillDirection = Enum.FillDirection.Vertical
			tabsFrame.Position = UDim2.fromOffset(0, 0)
			tabsFrame.Size = UDim2.fromOffset(TABS_WIDTH, size.Y)
			for _, tab in tabs do
				tab.Size = UDim2.new(1, 0, 0, 54)
			end
			grid.Position = UDim2.fromOffset(TABS_WIDTH + GAP, 0)
			grid.Size = UDim2.fromOffset(gridWidth, size.Y)
			detail.frame.Position = UDim2.fromOffset(size.X - detailWidth, 0)
			detail.frame.Size = UDim2.fromOffset(detailWidth, size.Y)
			layoutGrid(gridWidth)
		else
			local tabsHeight = 48
			local rest = size.Y - tabsHeight - GAP
			local gridHeight = math.floor(rest * 0.52)
			tabsLayout.FillDirection = Enum.FillDirection.Horizontal
			tabsFrame.Position = UDim2.fromOffset(0, 0)
			tabsFrame.Size = UDim2.fromOffset(size.X, tabsHeight)
			for _, tab in tabs do
				tab.Size = UDim2.new(1 / count, -math.ceil(8 * (count - 1) / count), 1, 0)
			end
			grid.Position = UDim2.fromOffset(0, tabsHeight + GAP)
			grid.Size = UDim2.fromOffset(size.X, gridHeight)
			detail.frame.Position = UDim2.fromOffset(0, tabsHeight + GAP + gridHeight + GAP)
			detail.frame.Size = UDim2.fromOffset(size.X, rest - gridHeight - GAP)
			layoutGrid(size.X)
		end
	end

	-- La vista previa gira despacio mientras la ventana está abierta (quieta con "menos movimiento")
	local rotator: RBXScriptConnection? = nil

	local function startBackground()
		if not Motion.isReduced() then
			for _, gear in gears do
				gear.start()
			end
		end
		if rotator == nil then
			rotator = RunService.Heartbeat:Connect(function(dt: number)
				if selectedId == nil or Motion.isReduced() then
					return
				end
				previewAngle += dt * 0.9
				detail.preview.setAngle(previewAngle)
			end)
		end
	end

	local function stopBackground()
		for _, gear in gears do
			gear.stop()
		end
		if rotator then
			rotator:Disconnect()
			rotator = nil
		end
	end

	-- Si se cambia la opción con la ventana abierta, el fondo se adapta al momento
	Motion.onChanged(function(reduced: boolean)
		if not gui.Enabled then
			return
		end
		if reduced then
			for _, gear in gears do
				gear.stop()
			end
		else
			startBackground()
		end
	end)

	-- Cerrar es rápido: no hay que esperar nada para volver al juego
	local function close()
		gui.Enabled = false
		stopBackground()
		GuiService.SelectedObject = nil
		ContextActionService:UnbindAction(CLOSE_ACTION)
	end

	-- Con mando, el botón B cierra la tienda mientras está abierta
	local function onCloseAction(_: string, state: Enum.UserInputState): Enum.ContextActionResult
		if state == Enum.UserInputState.Begin then
			close()
		end
		return Enum.ContextActionResult.Sink
	end

	-- A dónde va el foco al abrir con mando: el primer juguete de la categoría
	local function firstFocusTarget(): GuiObject
		for _, entry in ShopCatalog.Entries do
			if entry.Category == category then
				return cards[entry.ItemId].button
			end
		end
		return closeButton
	end

	local function open()
		if gui.Enabled then
			return
		end
		gui.Enabled = true
		dim.BackgroundTransparency = 1
		windowScale.Scale = 0.92
		Motion.tween(dim, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 0.45 })
		Motion.tween(windowScale, TweenInfo.new(0.26, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 })
		setCategory(category)
		refresh()
		layoutBottom()
		layoutBody()
		startBackground()
		ContextActionService:BindAction(CLOSE_ACTION, onCloseAction, false, Enum.KeyCode.ButtonB)
		if UiKit.isGamepadActive() then
			GuiService.SelectedObject = firstFocusTarget()
		end
	end

	closeButton.Activated:Connect(close)
	body:GetPropertyChangedSignal("AbsoluteSize"):Connect(layoutBody)
	content:GetPropertyChangedSignal("AbsoluteSize"):Connect(layoutBottom)

	-- Se mantiene al día con lo que el servidor deja en el PlayerGui de este jugador
	playerGui:GetAttributeChangedSignal(DataAttributes.Coins):Connect(refresh)
	for _, entry in ShopCatalog.Entries do
		playerGui:GetAttributeChangedSignal(DataAttributes.itemKey(entry.ItemId)):Connect(refresh)
	end

	-- Botón fijo para abrir la tienda desde cualquier lugar del taller
	local openButton = UiKit.blockButton(hudGui, "Tienda", 26, Theme.Wood, Theme.Paper)
	openButton.Name = "OpenShop"
	openButton.AnchorPoint = Vector2.new(1, 0.5)
	openButton.Position = UDim2.new(1, -12, 0.5, 0)
	openButton.Size = UDim2.fromOffset(0, 58)
	openButton.AutomaticSize = Enum.AutomaticSize.X
	local openPadding = Instance.new("UIPadding")
	openPadding.PaddingLeft = UDim.new(0, 18)
	openPadding.PaddingRight = UDim.new(0, 18)
	openPadding.Parent = openButton
	openButton.Activated:Connect(open)

	-- El mostrador también abre la tienda (el servidor no hace nada al pulsarlo)
	ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt)
		if prompt:GetAttribute("OpensShop") == true then
			open()
		end
	end)

	gui.Parent = playerGui
end

return ShopWindow
