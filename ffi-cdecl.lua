local script_dir = arg["script"]:gsub("[^/]+$","")
package.path = script_dir .. "gcc-lua-cdecl/?.lua;" .. package.path

local gcc = require("gcc")
local cdecl = require("gcc.cdecl")
local fficdecl = require("ffi-cdecl.ffi-cdecl")

-- Output generated assembly to /dev/null
gcc.set_asm_file_name(gcc.HOST_BIT_BUCKET)

-- Captured C declarations.
local decls = {}
-- Type declaration identifiers.
local types = {}

-- Parse C declaration from capture macro.
gcc.register_callback(gcc.PLUGIN_PRE_GENERICIZE, function(node)
  local decl, id = fficdecl.parse(node)
  if decl then
    if decl:class() == "type" or decl:code() == "type_decl" then
      types[decl] = id
    end
    table.insert(decls, {decl = decl, id = id})
  end
end)

-- Formats the given declaration as a string of C code.
local function format(decl, id)
  if decl:class() == "constant" then
    return "static const int " .. id .. " = " .. decl:value()
  end
  return cdecl.declare(decl, function(node)
    if node == decl then return id end
    return types[node]
  end)
end

-- Output captured C declarations to Lua file.
gcc.register_callback(gcc.PLUGIN_FINISH_UNIT, function()
  local result = {}
  for i, decl in ipairs(decls) do
    result[i] = format(decl.decl, decl.id) .. ";\n"
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
