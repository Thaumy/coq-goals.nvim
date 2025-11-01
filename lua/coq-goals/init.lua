local update_goals = require 'coq-goals.update_goals'

local goals_buf = vim.api.nvim_create_buf(false, true)
local goals_win = nil

local function setup(opts)
  vim.api.nvim_create_autocmd('CursorMoved', {
    callback = function(args)
      local ft = vim.api.nvim_get_option_value('ft', { buf = args.buf })
      if ft == 'coq' and goals_win ~= nil then
        update_goals(args.buf, goals_buf, goals_win)
      end
    end,
  })

  vim.api.nvim_create_autocmd('BufEnter', {
    callback = function(args)
      local ft = vim.api.nvim_get_option_value('ft', { buf = args.buf })
      if ft == 'coq' and goals_win == nil then
        goals_win = vim.api.nvim_open_win(goals_buf, false, {
          split = 'right',
          width = opts.width or 50,
        })
        vim.api.nvim_set_option_value('wrap', true, { win = goals_win })
        vim.api.nvim_set_option_value('number', false, { win = goals_win })
      end
    end,
  })

  vim.api.nvim_create_autocmd('BufLeave', {
    callback = function(args)
      local ft = vim.api.nvim_get_option_value('ft', { buf = args.buf })
      if ft == 'coq' and goals_win ~= nil then
        vim.api.nvim_win_close(goals_win, false)
        goals_win = nil
      end
    end,
  })
end

return {
  setup = setup,
}
