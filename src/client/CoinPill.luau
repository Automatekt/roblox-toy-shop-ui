--!strict
-- El contador de monedas, siempre visible arriba a la derecha. Solo lee el saldo que el
-- servidor deja en el PlayerGui de este jugador (nadie más lo recibe); no tiene botones.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local DataAttributes = require(ReplicatedStorage.Shared.DataAttributes)
local Theme = require(ReplicatedStorage.Shared.Theme)
local Motion = require(script.Parent.Motion)
local Sfx = require(script.Parent.Sfx)
local UiKit = require(script.Parent.UiKit)

local PILL_HEIGHT = 48
local COIN_SIZE = 32
local TEXT_SIZE = 26

local CoinPill = {}

-- 1234567 -> "1,234,567"
function CoinPill.formatNumber(n: number): string
	local digits = tostring(math.floor(n))
	local grouped = digits:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (grouped:gsub("^,", ""))
end

function CoinPill.start(gui: ScreenGui)
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	local pill = Instance.new("Frame")
	pill.Name = "CoinPill"
	pill.AnchorPoint = Vector2.new(1, 0)
	pill.Position = UDim2.new(1, -12, 0, 12)
	pill.Size = UDim2.fromOffset(0, PILL_HEIGHT)
	pill.AutomaticSize = Enum.AutomaticSize.X
	pill.BackgroundColor3 = Theme.Paper
	pill.Active = false -- solo informa: no bloquea toques ni clics
	UiKit.round(pill)
	UiKit.stroke(pill, 3)

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 8)
	padding.PaddingRight = UDim.new(0, 16)
	padding.Parent = pill

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, 8)
	layout.Parent = pill

	UiKit.coinIcon(pill, COIN_SIZE)

	local amount = UiKit.label(pill, "0", TEXT_SIZE, Theme.Ink, Theme.TitleFont)
	amount.Name = "Amount"
	amount.AutomaticSize = Enum.AutomaticSize.X
	amount.Size = UDim2.fromOffset(0, PILL_HEIGHT)
	amount.TextWrapped = false
	amount.TextXAlignment = Enum.TextXAlignment.Left

	local bump = Instance.new("UIScale")
	bump.Parent = pill

	-- El número sube o baja contando, en vez de saltar de golpe
	local counter = Instance.new("NumberValue")
	counter.Changed:Connect(function(value: number)
		amount.Text = CoinPill.formatNumber(math.floor(value + 0.5))
	end)
	local shown: number? = nil -- nil hasta el primer dibujo con datos
	local countTween: Tween? = nil

	-- Un "+15" que flota debajo del contador cuando ganas monedas
	local function floatGain(gained: number)
		local floating = UiKit.label(gui, "+" .. CoinPill.formatNumber(gained), 24, Theme.Ink, Theme.TitleFont)
		floating.AnchorPoint = Vector2.new(1, 0)
		floating.Position = UDim2.new(1, -24, 0, 12 + PILL_HEIGHT + 4)
		floating.Size = UDim2.fromOffset(120, 30)
		floating.TextXAlignment = Enum.TextXAlignment.Right
		floating.TextStrokeColor3 = Theme.Paper
		floating.TextStrokeTransparency = 0.2
		local tween = TweenService:Create(floating, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.new(1, -24, 0, 12 + PILL_HEIGHT + 28),
			TextTransparency = 1,
			TextStrokeTransparency = 1,
		})
		tween.Completed:Once(function()
			floating:Destroy()
		end)
		tween:Play()
	end

	local function render()
		-- Hasta que el servidor termina de cargar los datos no se anima nada: así no sale un "+300" al entrar
		if playerGui:GetAttribute(DataAttributes.Loaded) ~= true then
			shown = nil
			counter.Value = 0
			amount.Text = "0"
			return
		end
		local value = playerGui:GetAttribute(DataAttributes.Coins)
		local coins = if type(value) == "number" then value else 0
		local before = shown
		shown = coins
		if before == nil or coins == before then
			counter.Value = coins
			amount.Text = CoinPill.formatNumber(coins)
			return
		end
		if countTween then
			countTween:Cancel()
		end
		local seconds = math.clamp(math.abs(coins - before) / 300, 0.3, 0.8)
		countTween = Motion.tween(counter, TweenInfo.new(seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Value = coins })
		if coins > before then
			Sfx.play("Token")
		end
		if coins > before and not Motion.isReduced() then
			bump.Scale = 1.12
			Motion.tween(bump, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 })
			floatGain(coins - before)
		end
	end

	-- Vive toda la sesión, así que estas conexiones no necesitan limpiarse
	playerGui:GetAttributeChangedSignal(DataAttributes.Coins):Connect(render)
	playerGui:GetAttributeChangedSignal(DataAttributes.Loaded):Connect(render)
	render()
	pill.Parent = gui
end

return CoinPill
