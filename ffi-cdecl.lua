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
  local decl, id, ref = fficdecl.parse(node)
  if decl then
    if decl:class() == "type" or decl:code() == "type_decl" then
      types[decl] = id
    end
    table.insert(decls, {decl = decl, id = id, ref = ref})
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
    -- Skip the C99 decls
    -- NOTE: Do double-check those, because while this appears to help with size_t,
    --       I've seen complex nested typedefs involving *ptr_t getting mangled instead...
    -- NOTE: To check for suspicious type conversions, with an x86_64 compiler,
    --       do a second run w/ -m32 in CPPFLAGS.
    if decl.id == "bool"
    or decl.id == "ptrdiff_t"
    or decl.id == "size_t"
    or decl.id == "wchar_t"
    or decl.id == "int8_t"
    or decl.id == "int16_t"
    or decl.id == "int32_t"
    or decl.id == "int64_t"
    or decl.id == "uint8_t"
    or decl.id == "uint16_t"
    or decl.id == "uint32_t"
    or decl.id == "uint64_t"
    or decl.id == "intptr_t"
    or decl.id == "uintptr_t"
    or decl.id == "ssize_t"
    then
        goto continue
    end
    -- If we have an original ref, use it instead of the resolved canonical type (cdecl_c99_type hack)...
    if decl.ref then
      -- That's always a typedef, so, just format it like the original and call it a day.
      -- The callback has already run, so the actual new name made it to the types map.
      table.insert(result, "typedef " .. decl.ref .. " " .. decl.id .. ";\n")
    else
      table.insert(result, format(decl.decl, decl.id) .. ";\n")
    end
    -- That's one janky-ass workaround to the lack of continue keyword (requires LuaJIT/Lua 5.2)...
    ::continue::
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
