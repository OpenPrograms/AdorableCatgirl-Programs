local filesystem = require("filesystem")
local args = {...}
local file = io.open(args[1], "rb")

local header = "HHHHHHHHHHHHH"

local magic = 0x71c7

local dent = {}
while true do
	local mgk = file:read(2)
	local e = "<"
	if string.unpack("<H", mgk) ~= magic then
		e = ">"
	end
	dent.magic, dent.dev, dent.ino, dent.mode, dent.uid, dent.gid, dent.nlink, dent.rdev,
	dent.mtime_hi, dent.mtime_lo, dent.namesize, dent.filesize_hi,
	dent.filesize_lo = string.unpack(e..header, mgk..file:read(header:packsize()-2))
	if dent.magic ~= magic then
		error(string.format("bad magic! (%x ~= %x)", dent.magic, magic))
	end
	dent.mtime = (dent.mtime_hi << 16) | dent.mtime_lo
	dent.filesize = (dent.filesize_hi << 16) | dent.filesize_lo
	local name = file:read(dent.namesize):sub(1, dent.namesize - 1)
	if name == "TRAILER!!!" then break end
	dent.name = name
	print(name)
	if dent.namesize & 1 > 0 then file:seek("cur", 1) end
	if (dent.mode & 0xF000 == 0x8000) then
		local dir = dent.name:match("(.+)/.*%.?.+$")
		if (dir) then
			filesystem.makeDirectory(os.getenv("PWD").."/"..dir)
			--os.execute(string.format("mkdir -p %q", os.getenv("PWD").."/"..dir))
		end
		local hand = io.open(dent.name, "w")
		local remaining = dent.filesize
		while remaining > 0 do
			local chunk = 2048
			if chunk > remaining then chunk = remaining end
			local buffer = assert(file:read(chunk))
			if (#buffer ~= chunk) then
				error("unexpected eof")
			end
			hand:write(buffer)
			remaining = remaining - chunk
		end
		hand:close()
	end
	if dent.filesize & 1 > 0 then file:seek("cur", 1) end
end
