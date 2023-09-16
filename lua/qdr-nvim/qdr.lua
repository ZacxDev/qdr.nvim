local fzf = require("fzf")
local lyaml = require "lyaml"
local api = vim.api

function read_file(filename)
    local file = io.open(filename, "r") -- open for reading
    if not file then return nil end
    local content = file:read("*all") -- read the entire content
    file:close()
    return content
end

_G.zhandle_term_close = function()
    local exit_code = read_file("/tmp/nvim_terminal_exitcode.txt")

    -- Check the exit code
    if exit_code ~= "0\n" then
        local buf = _G.qdr_get_new_buf()
        local win_id = _G.qdr_get_new_win(buf)

        vim.cmd("terminal")
        vim.fn.chansend(vim.b.terminal_job_id, "cat /tmp/nvim_terminal_output.txt\n")
    end

    -- Clear the autocmd after it's executed
    vim.cmd("autocmd! CaptureExitCode")

    vim.cmd("sleep 200m")

    -- Clean up the temporary file
    os.remove("/tmp/nvim_terminal_output.txt")
    os.remove("/tmp/nvim_terminal_exitcode.txt")
end

local function get_new_buf()
    local buf = api.nvim_create_buf(false, true)
    return buf
end

local function get_new_win(buf)
    local width = api.nvim_get_option("columns")
    local height = api.nvim_get_option("lines")
    
    local win_width = math.floor(width * 0.3)
    local win_height = math.floor(height * 0.3)
    
    local row = 0
    local col = width - win_width
    
    local win_id = api.nvim_open_win(buf, true, {
        relative = "editor",
        width = win_width,
        height = win_height,
        col = col,
        row = row,
        style = "minimal"
    })

    return win_id
end

_G.qdr_get_new_buf = get_new_buf
_G.qdr_get_new_win = get_new_win

local function open_top_right_terminal_and_check(inputCmd)
    local buf = get_new_buf()
    local original_win_id = api.nvim_get_current_win()
    local win_id = get_new_win(buf)

    vim.cmd("terminal")

    vim.fn.chansend(vim.b.terminal_job_id, "bash -c \"" .. inputCmd .. "\" 2> /tmp/nvim_terminal_output.txt >&1 ; echo $? > /tmp/nvim_terminal_exitcode.txt && exit 0 ; exit 1\n")
    vim.cmd("sleep 100m")

    -- Set up the autocmd for TermClose
    vim.cmd(string.format([[
    augroup CaptureExitCode
        autocmd!
        autocmd TermClose * execute "lua _G.zhandle_term_close(%s, %s)"
    augroup END
    ]], buf, win_id))

    vim.cmd("sleep 100m")

    api.nvim_set_current_win(original_win_id)
end

-- see if the file exists
local function file_exists(file)
  local f = io.open(file, "rb")
  if f then f:close() end
  return f ~= nil
end

-- get all lines from a file, returns an empty 
-- string if the file does not exist
local function lines_from(file)
  if not file_exists(file) then return "" end
  local lines = ""
  for line in io.lines(file) do 
    lines = lines .. line .. "\n"
  end
  return lines
end

local function run_command_async(command)
  open_top_right_terminal_and_check(command)
end

function Qdr()
  local function done(command)
    local co = coroutine.create(function()
      print(command)
      run_command_async(command)
    end)

    coroutine.resume(co)
  end

  local command = ""
  local function run_fzf()
    -- tests the functions above
    local cwd = vim.fn.getcwd()
    local qfileDir = cwd
    while not file_exists(qfileDir .. '/qdr.yml') and qfileDir ~= "/" do
      local ix = string.find(qfileDir, "[/][^/]*[^/]$")
      if ix ~= nil then
        qfileDir = string.sub(qfileDir, 0, ix - 1)
      else
        print("No qdr.yml file found")
        return
      end
    end
    local qfilePath = qfileDir .. '/qdr.yml'

    local qdrLines = lines_from(qfilePath)
    local cmdMap = lyaml.load(qdrLines)

    local f = {}
    for k, _ in pairs(cmdMap) do
      table.insert(f, k)
    end

    coroutine.wrap(function()
      local fzf_selections = fzf.fzf(f, "--ansi")
      if fzf_selections then
        command = cmdMap[fzf_selections[1]]
        done(command)
      end
    end)()
  end

  run_fzf()
end

Qdr()

return { Qdr }
