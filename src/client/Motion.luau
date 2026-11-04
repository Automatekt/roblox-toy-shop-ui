--!strict
-- Una sola decisión para todo el movimiento de adorno: ¿está activada la opción
-- "menos movimiento"? Las animaciones preguntan aquí. Con menos movimiento, los cambios
-- se aplican al instante y los adornos que se mueven solos se quedan quietos.

local TweenService = game:GetService("TweenService")

local reduced = false
local listeners: { (boolean) -> () } = {}

local Motion = {}

function Motion.isReduced(): boolean
	return reduced
end

function Motion.setReduced(value: boolean)
	if value == reduced then
		return
	end
	reduced = value
	for _, listener in listeners do
		task.spawn(listener, value)
	end
end

-- Avisa cuando cambia la opción. Las conexiones viven toda la sesión.
function Motion.onChanged(listener: (boolean) -> ())
	table.insert(listeners, listener)
end

-- Anima propiedades de un objeto. Con menos movimiento las pone de golpe y no devuelve nada.
-- Crear un tween nuevo sobre la misma propiedad cancela el anterior: sirve para interrumpir.
function Motion.tween(instance: Instance, info: TweenInfo, goals: { [string]: any }): Tween?
	if reduced then
		for property, value in goals do
			(instance :: any)[property] = value
		end
		return nil
	end
	local tween = TweenService:Create(instance, info, goals)
	tween:Play()
	return tween
end

return Motion
