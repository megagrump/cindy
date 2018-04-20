local cindy = {
	_VERSION     = 'cindy 0.1',
	_LICENSE     = 'WTFPL, http://www.wtfpl.net',
	_URL         = 'https://github.com/megagrump/cindy',
	_DESCRIPTION = 'True Colors for LÖVE 11',
}

--[[-----------------------------------------------------------------------------------------------------------------

cindy adds functions to LÖVE 11.x that accept/return colors in the [0-255] range instead of the newly introduced
[0.0-1.0] range.

In love.graphics:
- rawClear
- getRawColor, setRawColor
- getRawBackgroundColor, setRawBackgroundColor
- getRawColorMask, setRawColorMask

In ImageData:
- getRawPixel, setRawPixel
- mapRawPixel

In ParticleSystem:
- setRawColors, getRawColors

In SpriteBatch:
- getRawColor, setRawColor

These functions behave the same as their built-in counterparts, except for the different value range.
Note that calling them has additional runtime costs.

To replace all original functions, call cindy.applyPatch() at the start of the program: require('cindy').applyPatch()
This effectively restores the pre-11.0 behavior.

-------------------------------------------------------------------------------------------------------------------]]

local gfx, reg = love.graphics, debug.getregistry()
local ImageData, ParticleSystem, SpriteBatch = reg.ImageData, reg.ParticleSystem, reg.SpriteBatch
local clear, getColor, setColor = gfx.clear, gfx.getColor, gfx.setColor
local getBackgroundColor, setBackgroundColor = gfx.getBackgroundColor, gfx.setBackgroundColor
local getColorMask, setColorMask = gfx.getColorMask, gfx.setColorMask
local getPixel, setPixel, mapPixel = ImageData.getPixel, ImageData.setPixel, ImageData.mapPixel
local getParticleColors, setParticleColors = ParticleSystem.getColors, ParticleSystem.setColors
local getBatchColor, setBatchColor = SpriteBatch.getColor, SpriteBatch.setColor

---------------------------------------------------------------------------------------------------------------------

-- convert RGBA values from [0-1] to [0-255]
function cindy.rgba2raw(r, g, b, a)
	return
		math.floor(r * 255 + .5),
		math.floor(g * 255 + .5),
		math.floor(b * 255 + .5),
		a and math.floor(a * 255 + .5)
end

-- convert RGBA values from [0-255] to [0-1]
function cindy.raw2rgba(r, g, b, a)
	return r / 255, g / 255, b / 255, a and a / 255
end

-- convert RGBA value table from [0-1] to [0-255]
function cindy.table2raw(color)
	return { cindy.rgba2raw(unpack(color)) }
end

-- convert RGBA value table from [0-255] to [0-1]
function cindy.raw2table(color)
	return { cindy.raw2rgba(unpack(color)) }
end

-- convert RGBA values or table from [0-1] to [0-255]
function cindy.color2raw(r, g, b, a)
	if type(r) == 'table' then
		return cindy.table2raw(r)
	end

	return rgba2raw(r, g, b, a)
end

-- convert RGBA values or table from [0-255] to [0-1]
function cindy.raw2color(r, g, b, a)
	if type(r) == 'table' then
		return cindy.raw2table(r)
	end

	return cindy.raw2rgba(r, g, b, a)
end

-- patch all LÖVE functions to accept colors in the [0-255] range
function cindy.applyPatch()
	gfx.clear, gfx.getColor, gfx.setColor = gfx.rawClear, gfx.getRawColor, gfx.setRawColor
	gfx.getBackgroundColor, gfx.setBackgroundColor = gfx.getRawBackgroundColor, gfx.setRawBackgroundColor
	gfx.getColorMask, gfx.setColorMask = gfx.getRawMaskColor, gfx.setRawMaskColor
	ImageData.getPixel, ImageData.setPixel = ImageData.getRawPixel, ImageData.setRawPixel
	ImageData.mapPixel = ImageData.mapRawPixel
	ParticleSystem.getColors, ParticleSystem.setColors = ParticleSystem.getRawColors, ParticleSystem.setRawColors
	SpriteBatch.getColor, SpriteBatch.setColor = SpriteBatch.getRawColor, SpriteBatch.setRawColor
end

---------------------------------------------------------------------------------------------------------------------

function gfx.getRawColor()
	return cindy.rgba2raw(getColor())
end

function gfx.setRawColor(r, g, b, a)
	return setColor(cindy.raw2color(r, g, b, a))
end

function gfx.getRawBackgroundColor()
	return cindy.rgba2raw(getBackgroundColor())
end

function gfx.setRawBackgroundColor(r, g, b, a)
	return setBackgroundColor(cindy.raw2color(r, g, b, a))
end

function gfx.getRawColorMask()
	return cindy.rgba2raw(getColorMask())
end

function gfx.setRawColorMask(r, g, b, a)
	return setColorMask(cindy.raw2color(r, g, b, a))
end

function gfx.rawClear(...)
	local args = {...}

	if #args == 0 or type(args[1]) == 'boolean' then
		return clear(...)
	end

	for i = 1, #args do
		if type(args[i]) == 'table' then
			args[i] = cindy.raw2table(args[i])
		elseif type(args[i]) == 'number' then
			args[i] = args[i] / 255
		end
	end

	return clear(unpack(args))
end

---------------------------------------------------------------------------------------------------------------------

function ImageData:getRawPixel(x, y)
	return cindy.color2raw(getPixel(self, x, y))
end

function ImageData:setRawPixel(x, y, r, g, b, a)
	return setPixel(self, x, y, cindy.raw2color(r, g, b, a))
end

function ImageData:mapRawPixel(fn)
	return mapPixel(self, function(x, y, r, g, b, a)
		return raw2color(fn(x, y, rgba2raw(r, g, b, a)))
	end)
end

---------------------------------------------------------------------------------------------------------------------

function ParticleSystem:setRawColors(...)
	local args = {...}

	if type(args[1]) == 'table' then
		for i = 1, #args do
			args[i] = cindy.raw2table(args[i])
		end
	else
		for i = 1, #args do
			args[i] = args[i] / 255
		end
	end

	return setParticleColors(self, unpack(args))
end

function ParticleSystem:getRawColors()
	local colors = { getParticleColors(self) }

	for i = 1, #colors do
		colors[i] = math.floor(colors[i] * 255 + .5)
	end

	return unpack(colors)
end

---------------------------------------------------------------------------------------------------------------------

function SpriteBatch:getRawColor()
	return cindy.rgba2raw(getBatchColor(self))
end

function SpriteBatch:setRawColor(r, g, b, a)
	if r then
		return setBatchColor(self, cindy.raw2color(r, g, b, a))
	end

	return setBatchColor(self)
end

---------------------------------------------------------------------------------------------------------------------

return cindy
