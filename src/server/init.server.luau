--!strict
-- Punto de entrada del servidor: arranca los sistemas de la tienda.

local DataService = require(script.DataService)
local DataReplicator = require(script.DataReplicator)

-- Los servicios que reaccionan a la carga de datos se registran antes de cargar
-- a nadie, para no perder a ningún jugador
DataReplicator.start()
DataService.start()
