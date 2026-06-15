-- Regression guard for the Lua 5.1 FFI of Data.Enum (Char <-> code point).
--
-- pslua compiles a PureScript Char as a Lua string of its UTF-8 bytes, so the
-- Char FFI must speak code points, not raw bytes:
--   #79 toCharCode must decode the first UTF-8 code point (JS c.charCodeAt(0)),
--       not return the leading byte (`c:byte()` gave 195 for 'é', not 233).
--   #80 fromCharCode must UTF-8-encode the code point (JS String.fromCharCode
--       over 0..65535); `string.char` alone errors above 255 and emits a raw
--       byte for 128..255.
-- Both are correct only over ASCII 0..127 in the old code; they back
-- Data.Enum's Char toEnum/fromEnum/cardinality.
--
-- Run from the repo root: `lua test/regression/enum.lua`.
local E = dofile("src/Data/Enum.lua")

local failures = 0

local function check(name, cond, detail)
  if cond then
    print("ok   - " .. name)
  else
    failures = failures + 1
    print("FAIL - " .. name .. ": " .. tostring(detail))
  end
end

-- pcall-guard fromCharCode: the old `string.char` binding throws for n > 255.
local function fcc(n)
  local ok, r = pcall(E.fromCharCode, n)
  if ok then return r end
  return nil
end

local function bytes(...) return string.char(...) end

local function hex(s)
  if s == nil then return "<error>" end
  local parts = {}
  for i = 1, #s do parts[i] = string.format("%02X", s:byte(i)) end
  return table.concat(parts, " ")
end

--------------------------------------------------------------------------------
-- #79 toCharCode decodes the first UTF-8 code point --------------------------

check("toCharCode 'A' (1 byte)", E.toCharCode(bytes(0x41)) == 65, "got " .. tostring(E.toCharCode(bytes(0x41))))
check("toCharCode 'é' U+00E9 (2 bytes)", E.toCharCode(bytes(0xC3, 0xA9)) == 233,
      "got " .. tostring(E.toCharCode(bytes(0xC3, 0xA9))))
check("toCharCode 'Ā' U+0100 (2 bytes)", E.toCharCode(bytes(0xC4, 0x80)) == 256,
      "got " .. tostring(E.toCharCode(bytes(0xC4, 0x80))))
check("toCharCode U+FFFF top (3 bytes)", E.toCharCode(bytes(0xEF, 0xBF, 0xBF)) == 65535,
      "got " .. tostring(E.toCharCode(bytes(0xEF, 0xBF, 0xBF))))

-- A lone code-unit byte from Data.String.CodeUnits (a 1-byte slice that is the
-- lead/continuation byte of a multibyte char): toCharCode must return that byte
-- and NOT read a missing c:byte(2) and crash. Data.String.CodePoints reassembles
-- code points from these bytes itself, so byte-in == byte-out is required.
check("toCharCode lone lead byte 0xC3 -> 195 (no crash)", E.toCharCode(bytes(0xC3)) == 195,
      "got " .. tostring(E.toCharCode(bytes(0xC3))))
check("toCharCode lone continuation byte 0x80 -> 128 (no crash)", E.toCharCode(bytes(0x80)) == 128,
      "got " .. tostring(E.toCharCode(bytes(0x80))))
check("toCharCode lone byte 0xF0 -> 240 (no crash)", E.toCharCode(bytes(0xF0)) == 240,
      "got " .. tostring(E.toCharCode(bytes(0xF0))))

--------------------------------------------------------------------------------
-- #80 fromCharCode UTF-8-encodes the code point (no error above 255) ---------

check("fromCharCode 65 -> 'A'", fcc(65) == bytes(0x41), "got " .. hex(fcc(65)))
check("fromCharCode 233 -> 'é'", fcc(233) == bytes(0xC3, 0xA9), "got " .. hex(fcc(233)))
check("fromCharCode 256 -> 'Ā' (was a runtime error)", fcc(256) == bytes(0xC4, 0x80), "got " .. hex(fcc(256)))
check("fromCharCode 65535 -> U+FFFF", fcc(65535) == bytes(0xEF, 0xBF, 0xBF), "got " .. hex(fcc(65535)))

--------------------------------------------------------------------------------
-- round-trip toCharCode . fromCharCode = id over the Char range --------------

for _, n in ipairs({0, 65, 127, 128, 233, 256, 1000, 40000, 65535}) do
  local s = fcc(n)
  local back = s and E.toCharCode(s) or nil
  check("round-trip code point " .. n, back == n, "got " .. tostring(back))
end

--------------------------------------------------------------------------------

if failures > 0 then error(failures .. " regression check(s) failed") end
print("purescript-lua-enums: all FFI regression checks passed")
