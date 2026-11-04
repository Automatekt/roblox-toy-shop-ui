--!strict
-- Sonidos suaves de la tienda, con un interruptor para apagarlos. Solo hay dos, ambos de la
-- biblioteca de efectos licenciada de Pro Sound Effects que Roblox ofrece en el Creator Store
-- (cuenta verificada ProSoundEffects), con volumen bajo para que no asusten.

local SoundService = game:GetService("SoundService")

type SoundSpec = {
	id: number,
	volume: number,
}

local SOUNDS: { [string]: SoundSpec } = {
	-- Tintineo de llaves: al recoger una ficha
	Token = { id = 9116162487, volume = 0.22 },
	-- Caja registradora: al comprar un juguete
	Buy = { id = 9113728042, volume = 0.3 },
}

local sounds: { [string]: Sound } = {}
local enabled = true

local Sfx = {}

function Sfx.start()
	for name, spec in SOUNDS do
		local sound = Instance.new("Sound")
		sound.Name = "Shop" .. name
		sound.SoundId = "rbxassetid://" .. spec.id
		sound.Volume = spec.volume
		sound.Parent = SoundService
		sounds[name] = sound
	end
end

function Sfx.isEnabled(): boolean
	return enabled
end

function Sfx.setEnabled(value: boolean)
	enabled = value
	if not value then
		for _, sound in sounds do
			sound:Stop()
		end
	end
end

function Sfx.play(name: string)
	local sound = sounds[name]
	if enabled and sound then
		sound.TimePosition = 0
		sound:Play()
	end
end

return Sfx
