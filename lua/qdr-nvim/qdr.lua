local fzf = require("fzf")
local lyaml = require "lyaml"

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

local function run_command_async(command, cb)
  -- Run the command and print exit code in a unique pattern so we can
  -- extract it from result
  local cmd_with_exit = string.format("%s ; printf \":|$?|:\"", command)
  local handle = io.popen(cmd_with_exit)
  local exit_wrap = ":|[0-9]|:$"
  if handle ~= nil then
    local full_result = handle:read("*a")
    local result = string.gsub(full_result, exit_wrap, "", 1)

    local exit_code_with_wrap = string.match(full_result, exit_wrap)
    local exit_code = tonumber(string.match(exit_code_with_wrap, "[0-9]"))
    cb(handle, result, exit_code)
    return
  end

  cb(nil, "", 0)
end

local function qdr()
  local function done(command)
    local function callback(handle, result, exit_code)
      local columns, lines = vim.o.columns, vim.o.lines
      local win_opts = {
        width = math.floor(columns * 0.5),
        height = math.floor(lines * 0.7),
        style = 'minimal',
        relative = 'editor'
      }

      win_opts.row = math.floor(((lines - win_opts.height) * 0.1) - 1)
      win_opts.col = math.floor((columns - win_opts.width) * 0.95)

      --local win = vim.api.nvim_get_current_win()
      --local buf = vim.api.nvim_get_current_buf()
      local bufnr = vim.api.nvim_create_buf(false, true)
      local winid = vim.api.nvim_open_win(bufnr, true, win_opts)

      vim.api.nvim_buf_set_text(0, 0, 0, 0, 0, {result})
      if handle ~= nil then
        handle:close()
      end

      if exit_code == 0 then
        vim.api.nvim_win_close(winid, {force=true})
        vim.api.nvim_buf_delete(bufnr)
      else
        vim.api.nvim_set_current_win(winid)
        vim.api.nvim_set_current_buf(bufnr)

        local last_line_num = vim.api.nvim_buf_line_count(bufnr)
        local last_line_text = vim.api.nvim_buf_get_lines(
          bufnr,
          last_line_num - 1,
          last_line_num,
          true
        )[1]

        --print(string.format("hiiii %s %s", last_line_num, string.len(last_line_text)))
        -- Move the cursor to the last line/column
        vim.api.nvim_win_set_cursor(winid, {last_line_num, string.len(last_line_text)})
      end
    end

    local co = coroutine.create(function()
      print(command)
      run_command_async(command, callback)
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

-- qdr()

return { qdr }
