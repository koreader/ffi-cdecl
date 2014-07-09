local script_dir = arg["script"]:gsub("[^/]+$","")
package.path = script_dir .. "gcc-lua-cdecl/?.lua"

local gcc = require("gcc")
local cdecl = require("ffi-cdecl/ffi-cdecl")

-- Output generated assembly to /dev/null
gcc.set_asm_file_name(gcc.HOST_BIT_BUCKET)

local decls = {}

-- Parse C declaration from capture macro.
gcc.register_callback(gcc.PLUGIN_PRE_GENERICIZE, function(node)
  local decl = cdecl.parse(node, function(id)
    return id
  end)
  if decl then table.insert(decls, decl) end
end)

-- Output captured C declarations to Lua file.
gcc.register_callback(gcc.PLUGIN_FINISH_UNIT, function()
  local result = {}
  table.sort(decls)
  for i, decl in ipairs(decls) do
    result[i] = tostring(decl) .. ";\n"
  end
  local f = assert(io.open(arg.output, "w"))
  f:write([=[
local ffi = require("ffi")

ffi.cdef[[
]=], table.concat(result), [=[
]]

]=])
  f:close()
end)
