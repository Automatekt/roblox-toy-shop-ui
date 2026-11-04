--!strict
-- Los objetos que existen en el juego. El servidor solo acepta ids de esta lista,
-- y el cliente la usa para mostrar los nombres. Los precios y las categorías de la
-- tienda están aparte, en ShopCatalog.

export type ItemInfo = {
	DisplayName: string,
	MaxStack: number, -- máximo que un jugador puede tener de este objeto
}

local items: { [string]: ItemInfo } = {
	WindUpRobot = { DisplayName = "Robot de cuerda", MaxStack = 1 },
	BrassRocket = { DisplayName = "Cohete de latón", MaxStack = 1 },
	WoodTrain = { DisplayName = "Tren de madera", MaxStack = 1 },
	LetterCube = { DisplayName = "Cubo de letras", MaxStack = 1 },
	BlockTower = { DisplayName = "Torre de bloques", MaxStack = 1 },
	PieceCastle = { DisplayName = "Castillo de piezas", MaxStack = 1 },
	MarbleBag = { DisplayName = "Bolsa de canicas", MaxStack = 99 },
	TeddyBear = { DisplayName = "Osito de peluche", MaxStack = 1 },
	Bunny = { DisplayName = "Conejo de peluche", MaxStack = 1 },
	PlushDragon = { DisplayName = "Dragón de peluche", MaxStack = 1 },
}

-- Congelado para que ningún script cambie el catálogo por accidente
for _, info in items do
	table.freeze(info)
end

return table.freeze(items)
