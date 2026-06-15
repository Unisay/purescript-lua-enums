return {
  toCharCode = (function(c)
    -- pslua compiles a PureScript Char as a string of its UTF-8 bytes, so decode
    -- the first code point (JS does c.charCodeAt(0)) rather than the first byte.
    local b1 = c:byte(1)
    if b1 < 0x80 then return b1 end
    if b1 < 0xE0 then return (b1 - 0xC0) * 0x40 + (c:byte(2) - 0x80) end
    if b1 < 0xF0 then return (b1 - 0xE0) * 0x1000 + (c:byte(2) - 0x80) * 0x40 + (c:byte(3) - 0x80) end
    return (b1 - 0xF0) * 0x40000 + (c:byte(2) - 0x80) * 0x1000 + (c:byte(3) - 0x80) * 0x40 + (c:byte(4) - 0x80)
  end),
  fromCharCode = (function(n)
    -- Encode the code point as UTF-8 (JS String.fromCharCode over 0..65535);
    -- string.char alone errors above 255 and emits a raw byte for 128..255.
    if n < 0x80 then return string.char(n) end
    if n < 0x800 then return string.char(0xC0 + math.floor(n / 0x40), 0x80 + (n % 0x40)) end
    if n < 0x10000 then
      return string.char(0xE0 + math.floor(n / 0x1000), 0x80 + (math.floor(n / 0x40) % 0x40), 0x80 + (n % 0x40))
    end
    return string.char(0xF0 + math.floor(n / 0x40000), 0x80 + (math.floor(n / 0x1000) % 0x40),
                       0x80 + (math.floor(n / 0x40) % 0x40), 0x80 + (n % 0x40))
  end)
}
