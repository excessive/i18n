local i18n = {}
i18n.__index = i18n
i18n.__call  = function(self, key)
	return self:get(key)
end

local d = console and console.d or print
local i = console and console.i or print
local e = console and console.e or print

local ok, memoize = pcall(require, "memoize")
if not ok then
	i("Memoize not available. Using passthrough.")
	memoize = function(f)
		return f
	end
end

local function new()
	return setmetatable({
		locale   = false,
		fallback = false,
		strings  = {},
	}, i18n)
end

function i18n:load(file)
	if not love.filesystem.isFile(file) then
		return false
	end
	local locale
	local bork = function(msg)
		e(string.format("Error loading locale %s: %s", file, tostring(msg)))
		return false
	end
	local ok, msg = pcall(function()
		local ok, chunk = pcall(love.filesystem.load, file)
		if not ok then
			return bork(chunk)
		end
		local data = chunk()

		-- Sanity check!
		assert(type(data) == "table")
		assert(type(data.locale) == "string")
		assert(type(data.base) == "string")
		assert(type(data.quotes) == "table")
		assert(#data.quotes == 2)
		assert(type(data.strings) == "table")

		locale = data
	end)
	if not ok then
		return bork(msg)
	end

	locale.strings.base = locale.base
	self.strings[locale.locale] = locale.strings

	i(string.format("Loaded locale \"%s\" from \"%s\"", locale.locale, file))
	self:invalidate_cache()

	return true
end

function i18n:set_fallback(locale)
	self:invalidate_cache()
	self.fallback = locale
end

function i18n:set_locale(locale)
	self:invalidate_cache()
	self.locale = locale
end

-- Returns 3 values: text, audio, fallback.
-- - Text is mandatory and is guaranteed to be a string.
-- - Audio is optional and will return the full path to the audio clip for the
--   key. If missing, will return false.
-- - Fallback will be true if the key was missing from your selected language,
--   but present in the fallback locale.
local function gen_get()
	return function(self, key)
		assert(type(key) == "string", "Expected key of type 'string', got type '"..type(key).."'")
		local lang = self.strings[self.locale]
		local fallback = false
		if not lang or type(lang) == "table" and not lang[key] then
			lang = self.strings[self.fallback]
			fallback = true
		end
		if lang and type(lang[key]) == "table" and type(lang[key].text) == "string" then
			local value = lang[key]
			if fallback then
				-- d(string.format(
				-- 	"String \"%s\" missing from locale %s, using fallback",
				-- 	key, self.locale
				-- ))
			end
			-- Do not return audio for different languages if we're falling back.
			-- The voice mismatch would be strange, subtitles-only is better.
			return value.text, (fallback == false) and (value.audio and string.format("%s/%s", lang.base, value.audio) or false) or false, fallback
		else
			d(string.format(
				"String \"%s\" missing from locale %s and fallback (%s)",
				key, self.locale, self.fallback
			))
			return key, false, false
		end
	end
end

function i18n:invalidate_cache()
	self._get_internal = gen_get()
end

function i18n:get(key)
	if not self._get_internal then
		self:invalidate_cache()
	end
	return memoize(self._get_internal)(self, key)
end

return setmetatable({new=new},{__call=function(_,...) return new(...) end})
