--!strict
-- Punto de entrada del servidor: arranca los sistemas de la tienda.

local DataService = require(script.DataService)
local DataReplicator = require(script.DataReplicator)
local ShopService = require(script.ShopService)
local TokenService = require(script.TokenService)
local WorkshopBuilder = require(script.WorkshopBuilder)

-- El taller se construye antes que nada para que exista cuando entren los jugadores
WorkshopBuilder.build()

-- Los servicios que reaccionan a la carga de datos se registran antes de cargar
-- a nadie, para no perder a ningún jugador
DataReplicator.start()
ShopService.start()
TokenService.start()
DataService.start()
