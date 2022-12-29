local q = require "qdr-nvim.qdr"

local function setup(parameters)
end

vim.api.nvim_create_user_command(
    'Qdr',
    function(input)
        Qdr()
    end,
    {bang = true, desc = 'open qdr menu'}
)

return {
    setup = setup,
}
