--!strict
-- Hace girar y flotar los adornos que el servidor marca con la etiqueta "Spin" (fichas y
-- engranajes). Solo es visual y solo en esta pantalla: el servidor no sabe nada de esto.
-- Atributos que lee de cada objeto: SpinSpeed (grados por segundo), SpinAxis ("X", "Y" o "Z")
-- y Bob (cuánto sube y baja, en studs).

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local Motion = require(script.Parent.Motion)

type Entry = {
	base: CFrame, -- cómo estaba al aparecer
	speed: number, -- radianes por segundo
	axis: Vector3,
	bob: number,
	phase: number,
	resting: boolean, -- ya está en su posición base (con "menos movimiento")
}

local AXES: { [string]: Vector3 } = {
	X = Vector3.xAxis,
	Y = Vector3.yAxis,
	Z = Vector3.zAxis,
}

local BOB_SPEED = 2 -- radianes por segundo del sube y baja

local entries: { [PVInstance]: Entry } = {}

local Spinner = {}

local function addEntry(instance: PVInstance)
	if entries[instance] ~= nil then
		return
	end
	local speed = instance:GetAttribute("SpinSpeed")
	local axisName = instance:GetAttribute("SpinAxis")
	local bob = instance:GetAttribute("Bob")
	local savedBase = instance:GetAttribute("SpinBase")
	entries[instance] = {
		base = if typeof(savedBase) == "CFrame" then savedBase else instance:GetPivot(),
		speed = math.rad(if type(speed) == "number" then speed else 20),
		axis = AXES[if type(axisName) == "string" then axisName else "Y"] or Vector3.yAxis,
		bob = if type(bob) == "number" then bob else 0,
		phase = math.random() * 2 * math.pi, -- para que no suban y bajen todas a la vez
		resting = false,
	}
end

-- Los modelos llegan al cliente por partes: se espera a que estén todas (el servidor dice cuántas)
-- antes de moverlos, para que no queden descolocados.
local function register(instance: Instance)
	if not instance:IsA("PVInstance") then
		return
	end
	local expected = instance:GetAttribute("SpinParts")
	if instance:IsA("Model") and type(expected) == "number" then
		task.spawn(function()
			local waited = 0
			while instance.Parent ~= nil and #instance:GetDescendants() < expected and waited < 10 do
				waited += task.wait()
			end
			if instance.Parent ~= nil and #instance:GetDescendants() >= expected then
				addEntry(instance)
			end
		end)
	else
		addEntry(instance)
	end
end

local function unregister(instance: Instance)
	if instance:IsA("PVInstance") then
		entries[instance] = nil
	end
end

function Spinner.start()
	for _, instance in CollectionService:GetTagged("Spin") do
		register(instance)
	end
	CollectionService:GetInstanceAddedSignal("Spin"):Connect(register)
	CollectionService:GetInstanceRemovedSignal("Spin"):Connect(unregister)

	-- Una sola conexión para todos los adornos; vive toda la sesión
	RunService.Heartbeat:Connect(function()
		local now = os.clock()
		local still = Motion.isReduced()
		for instance, entry in entries do
			if instance.Parent == nil then
				entries[instance] = nil
				continue
			end
			if still then
				if not entry.resting then
					instance:PivotTo(entry.base)
					entry.resting = true
				end
				continue
			end
			entry.resting = false
			local angle = if still then 0 else entry.speed * now
			local lift = if still then 0 else math.sin(now * BOB_SPEED + entry.phase) * entry.bob
			local position = entry.base.Position + Vector3.new(0, lift, 0)
			instance:PivotTo(CFrame.new(position) * CFrame.fromAxisAngle(entry.axis, angle) * entry.base.Rotation)
		end
	end)
end

return Spinner
