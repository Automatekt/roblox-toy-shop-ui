--!strict
-- Lo que se vende en la tienda: categorías, orden, precios y descripciones.
-- El nombre y el máximo de cada objeto salen de ItemCatalog, para no repetirlos.
-- El servidor busca aquí el precio: el cliente nunca dice cuánto cuesta algo.

local ItemCatalog = require(script.Parent.ItemCatalog)

export type Category = {
	Id: string,
	DisplayName: string,
}

export type Entry = {
	ItemId: string,
	Category: string,
	Price: number, -- monedas
	Description: string, -- una frase corta
}

local categories: { Category } = {
	{ Id = "WindUp", DisplayName = "De cuerda" },
	{ Id = "Blocks", DisplayName = "Bloques" },
	{ Id = "Plush", DisplayName = "Peluches" },
}

-- El orden de esta lista es el orden en que se muestran los objetos
local entries: { Entry } = {
	{ ItemId = "WoodTrain", Category = "WindUp", Price = 80, Description = "Tres vagones con ruedas que giran. ¡Chu chu!" },
	{ ItemId = "WindUpRobot", Category = "WindUp", Price = 120, Description = "Dale cuerda y camina con pasitos de lata." },
	{ ItemId = "BrassRocket", Category = "WindUp", Price = 200, Description = "Un cohete brillante para viajar a la luna." },
	{ ItemId = "MarbleBag", Category = "Blocks", Price = 10, Description = "Canicas de colores. ¡Junta todas las que quieras!" },
	{ ItemId = "LetterCube", Category = "Blocks", Price = 60, Description = "Un cubo con letras de colores para jugar." },
	{ ItemId = "BlockTower", Category = "Blocks", Price = 90, Description = "Apila los bloques sin que se caiga." },
	{ ItemId = "PieceCastle", Category = "Blocks", Price = 250, Description = "Un castillo con torres y puente levadizo." },
	{ ItemId = "TeddyBear", Category = "Plush", Price = 100, Description = "Suave y calentito, ideal para abrazar." },
	{ ItemId = "Bunny", Category = "Plush", Price = 140, Description = "Orejas largas y cola de pompón." },
	{ ItemId = "PlushDragon", Category = "Plush", Price = 300, Description = "Un dragón amistoso que no echa fuego." },
}

-- Índice por id, y comprobaciones que fallan al arrancar si el catálogo está mal armado
local byId: { [string]: Entry } = {}
local categoryIds: { [string]: boolean } = {}
for _, category in categories do
	categoryIds[category.Id] = true
	table.freeze(category)
end
for _, entry in entries do
	assert(ItemCatalog[entry.ItemId] ~= nil, "ShopCatalog: el objeto no existe en ItemCatalog: " .. entry.ItemId)
	assert(categoryIds[entry.Category], "ShopCatalog: categoría desconocida: " .. entry.Category)
	assert(byId[entry.ItemId] == nil, "ShopCatalog: objeto repetido: " .. entry.ItemId)
	assert(entry.Price > 0 and entry.Price % 1 == 0, "ShopCatalog: precio inválido: " .. entry.ItemId)
	byId[entry.ItemId] = entry
	table.freeze(entry)
end

local ShopCatalog = {}

ShopCatalog.Categories = table.freeze(categories)
ShopCatalog.Entries = table.freeze(entries)

-- Devuelve el producto de ese id, o nil si el id no es un texto o no se vende
function ShopCatalog.get(itemId: any): Entry?
	if type(itemId) ~= "string" then
		return nil
	end
	return byId[itemId]
end

return table.freeze(ShopCatalog)
