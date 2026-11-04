--!strict
-- Sonidos suaves de la tienda, con un interruptor para apagarlos. Solo hay dos, ambos de la
-- biblioteca de efectos licenciada de Pro Sound Effects que Roblox ofrece en el Creator Store
-- (cuenta verificada ProSoundEffects), con volumen bajo para que no asusten.

local SoundService = game:GetService("SoundService")

type SoundSpec = {
	id: number,
	volume: number,
	speed: number, -- 1 = tono original; más alto es más agudo
	maxSeconds: number?, -- si se pone, el sonido se corta a ese tiempo (para los muy breves)
}

local KEYS_ID = 9116162487

local SOUNDS: { [string]: SoundSpec } = {
	-- Tintineo de llaves: al recoger una ficha
	Token = { id = KEYS_ID, volume = 0.22, speed = 1 },
	-- Caja registradora: al comprar un juguete
	Buy = { id = 9113728042, volume = 0.3, speed = 1 },
	-- Abrir y cerrar la tienda: el mismo tintineo, más agudo al abrir y más grave al cerrar, cortito
	Open = { id = KEYS_ID, volume = 0.14, speed = 1.35, maxSeconds = 0.45 },
	Close = { id = KEYS_ID, volume = 0.12, speed = 0.8, maxSeconds = 0.4 },
}

local sounds: { [string]: Sound } = {}
local playCount: { [string]: number } = {}
local enabled = true

local Sfx = {}

function Sfx.start()
	for name, spec in SOUNDS do
		local sound = Instance.new("Sound")
		sound.Name = "Shop" .. name
		sound.SoundId = "rbxassetid://" .. spec.id
		sound.Volume = spec.volume
		sound.PlaybackSpeed = spec.speed
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
		local limit = SOUNDS[name].maxSeconds
		if limit then
			-- Solo corta si nadie volvió a reproducirlo mientras tanto
			local mine = (playCount[name] or 0) + 1
			playCount[name] = mine
			task.delay(limit, function()
				if playCount[name] == mine then
					sound:Stop()
				end
			end)
		end
	end
end

return Sfx
