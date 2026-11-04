--!strict
-- Punto de entrada del cliente: arranca la interfaz y los adornos.

local Players = game:GetService("Players")

local CoinPill = require(script.CoinPill)
local PromptUi = require(script.PromptUi)
local Sfx = require(script.Sfx)
local ShopWindow = require(script.ShopWindow)
local Spinner = require(script.Spinner)

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

-- Lo que se ve siempre: el contador de monedas y el botón de la tienda
local hudGui = Instance.new("ScreenGui")
hudGui.Name = "ShopHud"
hudGui.ResetOnSpawn = false
hudGui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets

Sfx.start()
Spinner.start()
PromptUi.start()
CoinPill.start(hudGui)
ShopWindow.start(hudGui)
hudGui.Parent = playerGui
