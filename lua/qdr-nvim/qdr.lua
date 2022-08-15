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
    lines = lines .. line .. "\n"
  end
  return lines
end

function runQdr()
  coroutine.wrap(function()
    -- tests the functions above
    local cwd = vim.fn.getcwd()
    local qfileDir = cwd
    while not file_exists(qfileDir .. '/qdr.yml') and qfileDir ~= "/" do
      local ix = string.find(qfileDir, "[/][^/]*[^/]$")
      if ix ~= nil then
        qfileDir = string.sub(qfileDir, 0, ix - 1)
      else
        return
      end
    end
    local qfilePath = qfileDir .. '/qdr.yml'

    local lines = lines_from(qfilePath)
    local cmdMap = lyaml.load(lines)

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
