# i18n

Internationalization functions for LÖVE. We might rename it to something more interesting later.

# Specifying a language

It's just a Lua table.

Several real-world examples can be found [here, in our LD33 entry](https://github.com/excessive/ludum-dare-33/tree/master/assets/lang).

```lua
return {
  locale = "en",
  base   = "assets/sounds/en",
  quotes = { "\"", "\"" }, -- NYI, but planned. Several languages use different quotes.
  strings = {
    ["main/play"]    = { text = "Play", audio = "play.ogg" },
    ["main/options"] = { text = "Options" },
    -- etc
  }
}
```

# Usage
```lua
local lang = require "i18n"

-- load all your language files. the filenames are of no significance.
lang:load("languages/en.lua")

-- set default locale if a string is not available in the current one.
-- Note: will not return audio for fallback language (that would be really weird).
lang:set_fallback("en")

-- set locale to source data from
lang:set_locale("en")

-- translated string, path to audio, and whether the string is from fallback.
-- can also be written as lang:get("key")
lang "main/play" -- => "Play", "assets/sounds/en/play.ogg", false
```
