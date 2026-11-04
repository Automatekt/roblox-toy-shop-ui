--!strict
-- Colores y tipografías del "Taller de juguetes". Todo el mundo y toda la interfaz
-- salen de aquí, para que nada quede fuera de estilo.
-- Idea: papel crema y madera de fondo, y cuatro colores de caja de juguetes con medida.

local function hex(value: string): Color3
	return Color3.fromHex(value)
end

return table.freeze({
	-- Fondos y madera
	Cream = hex("#F6EBD0"), -- papel
	Paper = hex("#FFF8E6"), -- papel más claro, para tarjetas
	Wood = hex("#C58B52"),
	WoodDark = hex("#7A4E2B"),
	Ink = hex("#3A2A1E"), -- texto y contornos: marrón oscuro, nunca negro puro

	-- Colores de juguete
	Tomato = hex("#E5533D"),
	Sunflower = hex("#F6C945"),
	Sky = hex("#3FA7D6"),
	Mint = hex("#6CC6A1"),
	Grape = hex("#9B6BC4"),

	-- Tipografías: títulos redondeados y texto fácil de leer
	TitleFont = Enum.Font.FredokaOne,
	BodyFont = Enum.Font.Nunito,
})
