--!strict
-- Dónde está cada cosa del taller. El escenario, las fichas y el mostrador preguntan
-- aquí para no pisarse. El centro del taller es el origen y el suelo está en y = 0.
-- El taller es un cuadrado de 56 x 56 studs: las paredes están a 28 del centro.

local WorkshopLayout = {}

WorkshopLayout.HalfSize = 28 -- de la pared al centro
WorkshopLayout.WallHeight = 22
WorkshopLayout.SpawnPosition = Vector3.new(0, 0.5, 16)
WorkshopLayout.CounterPosition = Vector3.new(0, 0, -18) -- el mostrador de la tienda, de espaldas a la pared del fondo
WorkshopLayout.CounterSize = Vector3.new(16, 4, 4)

-- Dónde aparecen las fichas de monedas (x, z); la altura la pone TokenService
WorkshopLayout.TokenSpots = {
	Vector2.new(-14, -8),
	Vector2.new(14, -8),
	Vector2.new(-19, 6),
	Vector2.new(19, 6),
	Vector2.new(-8, 12),
	Vector2.new(8, 12),
	Vector2.new(-20, -18),
	Vector2.new(20, -18),
}

return WorkshopLayout
