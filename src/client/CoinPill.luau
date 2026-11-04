--!strict
-- El contador de monedas, siempre visible arriba a la derecha. Solo lee el saldo que el
-- servidor deja en el PlayerGui de este jugador (nadie más lo recibe); no tiene botones.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataAttributes = require(ReplicatedStorage.Shared.DataAttributes)
local Theme = require(ReplicatedStorage.Shared.Theme)
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

	local function render()
		local coins = playerGui:GetAttribute(DataAttributes.Coins)
		amount.Text = CoinPill.formatNumber(if type(coins) == "number" then coins else 0)
	end

	-- Vive toda la sesión, así que estas conexiones no necesitan limpiarse
	playerGui:GetAttributeChangedSignal(DataAttributes.Coins):Connect(render)
	render()
	pill.Parent = gui
end

return CoinPill
