
local ffi = require("ffi")
local bit = require("bit")
local io = require("io")

-- Prediction
local ct = ffi.new("int32_t[256][2]")
local cxt = 1

local function readeof(stream)
  local c = stream:read(1)
  if not c then return -1 end
  return c:byte()
end

-- That helps.
local floor = math.floor
local shr = bit.rshift
local shl = bit.lshift
local band = bit.band

local function predict(y)
  ct[cxt][y] = ct[cxt][y] + 1
  if ct[cxt][y] > 65534 then
    ct[cxt][0] = shr(ct[cxt][0], 1)
    ct[cxt][1] = shr(ct[cxt][1], 1)
  end
  cxt = cxt + cxt + y
  if cxt >= 256 then cxt = 1 end
  local pr0 = floor(4096 * (ct[cxt][1] + 1) / (ct[cxt][0] + ct[cxt][1] + 2))
  return pr0
end

ffi.cdef[[
  typedef struct {
    uint32_t x1, x2, p;
  } ac_t;
]]

local AC = {}
AC.__index = AC

function AC.new(stream)
  local self = setmetatable({}, AC)
  self.stream = stream
  self.ac = ffi.new("ac_t")
  self.ac.x1 = 0
  self.ac.x2 = 0xFFFFFFFF
  self.ac.p = 2048
  return self
end

function AC:ac_flush()
  self.stream:write(string.char(shr(self.ac.x1, 24)))
end

function AC:ac_rescale()
  self.ac.x1 = shl(self.ac.x1, 8)
  self.ac.x2 = bit.bor(shl(self.ac.x2, 8), 255)
end

function AC:encode_bit(y)
  local range = self.ac.x2 - self.ac.x1
  local xmid = self.ac.x1 + shr(range, 12) * self.ac.p + shr(band(range, 0xfff) * self.ac.p, 12)
  self.ac.p = predict(y)
  if y == 1 then
    self.ac.x2 = xmid
  else
    self.ac.x1 = xmid + 1
  end
  while band(bit.bxor(self.ac.x1, self.ac.x2), 0xff000000) == 0 do
    self:ac_flush()
    self:ac_rescale()
  end
end

local function encode_file(input, output)
  input:seek("end")
  local length = input:seek()
  input:seek("set")
  output:write(string.char(band(shr(length, 24), 0xFF)))
  output:write(string.char(band(shr(length, 16), 0xFF)))
  output:write(string.char(band(shr(length, 8), 0xFF)))
  output:write(string.char(band(length, 0xFF)))
  local ac = AC.new(output)
  while true do
    local c = readeof(input)
    if c == -1 then break end
    for i = 7, 0, -1 do
      ac:encode_bit(band(shr(c, i), 1))
    end
  end
  ac:ac_flush()
end

local input = assert(io.open(arg[1], "rb"))
local output = assert(io.open(arg[2], "wb"))

collectgarbage("stop") -- snake oil.
encode_file(input, output)
collectgarbage("restart")

input:close()
output:close()
