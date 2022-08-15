local q = require "qdr"

local function setup(parameters)
end

vim.api.nvim_create_user_command(
    'qdr',
    function(input)
        runQdr()
    end,
    {bang = true, desc = 'a new command to do the thing'}
)

return {
    setup = setup,
}