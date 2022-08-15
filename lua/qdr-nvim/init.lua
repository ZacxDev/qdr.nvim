local q = require "qdr-nvim.qdr"

local function setup(parameters)
end

vim.api.nvim_create_user_command(
    'Qdr',
    function(input)
        runQdr()
    end,
    {bang = true, desc = 'open qdr menu'}
)

return {
    setup = setup,
}
