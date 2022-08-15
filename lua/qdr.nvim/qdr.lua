local fzf = require("fzf")
local lyaml   = require "lyaml"

local execute = vim.api.nvim_command

-- see if the file exists
function file_exists(file)
  local f = io.open(file, "rb")
  if f then f:close() end
  return f ~= nil
end

-- get all lines from a file, returns an empty 
-- string if the file does not exist
function lines_from(file)
  if not file_exists(file) then return "" end
  local lines = ""
  for line in io.lines(file) do 
    lines = lines .. "\n" .. line
  end
  return lines
end

function runQdr()
  coroutine.wrap(function()
    -- tests the functions above
    local file = 'qdr.yml'
    local lines = lines_from(file)
    print(lines)

    local opt1 = "Tilt Trigger buf";
    local opt2 = "Graphql Codegen";
    local cmdMap = {
      [opt1]="tilt trigger buf",
      [opt2]="tilt trigger graphql",
    }

    local f = {}
    for k, _ in pairs(cmdMap) do
      table.insert(f, k)
    end

    local result = fzf.fzf(f, "--ansi")
    -- result is a list of lines that fzf returns, if the user has chosen
    if result then
      local command = cmdMap[result[1]]
      execute(string.format("!%s", command))
    end
  end)()
end

return { runQdr }
