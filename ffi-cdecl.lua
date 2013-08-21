local script_dir = arg["script"]:gsub("[^/]+$","")
package.path = script_dir .. "gcc-lua-cdecl/?.lua"

-- based on gcc-lua-cdecl documentation
local gcc = require("gcc")
local cdecl = require("gcc.cdecl")

-- send assembler output to /dev/null
gcc.set_asm_file_name(gcc.HOST_BIT_BUCKET)

-- invoke Lua function after translation unit has been parsed
gcc.register_callback(gcc.PLUGIN_FINISH_UNIT, function()
  -- get global variables in reverse order of declaration
  local nodes = gcc.get_variables()
  for i = #nodes, 1, -1 do
    local orig = nodes[i]:name():value()
    if orig:match("^cdecl_func__") then
      -- get function or variable pointed to by initial value
      local decl = nodes[i]:initial():operand()
      -- output function or variable declaration
      print(cdecl.declare(decl) .. ";")
    end
    local name = orig:match("^cdecl_type__(.+)")
    if name then
      -- get type declaration of pointee type
      local decl = nodes[i]:type():type():name()
      -- output type declaration with API name
      print(cdecl.declare(decl, function(node)
        if node == decl then return name end
      end) .. ";")
    end
    local name = orig:match("^cdecl_struct__(.+)") or
        orig:match("^cdecl_enum__(.+)") or
        orig:match("^cdecl_union__(.+)")
    if name then
      -- get pointee type
      local type = nodes[i]:type():type()
      -- output type with API name
      print(cdecl.declare(type, function(node)
        if node == type then return name end
      end) .. ";")
    end
    local name = orig:match("^cdecl_const__(.+)")
    if name then
      -- extract constant value
      local value = nodes[i]:initial():value()
      -- output constant with API name
      print(("static const int %s = %d;"):format(name, value))
    end
  end
end)
