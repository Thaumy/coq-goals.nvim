local function pretty(raw)
  local replaced = string.gsub(raw, '&&', '∧')
  replaced = string.gsub(replaced, '||', '∨')
  replaced = string.gsub(replaced, '%%', ' : ')
  return replaced
end

local function split_into_lines(str)
  return vim.split(str, '\n')
end

return function(curr_buf, goals_buf, goals_win)
  local pos = vim.api.nvim_win_get_cursor(0)
  local params = {
    textDocument = vim.lsp.util.make_text_document_params(curr_buf),
    position = { line = pos[1] - 1, character = pos[2] },
  }
  local clients = vim.lsp.get_clients { bufnr = curr_buf }
  local client = clients[1]
  if client == nil or vim.bo.ft ~= 'coq' then
    vim.api.nvim_buf_set_lines(goals_buf, 0, -1, true, {})
    return
  end

  local function cb(err, answer)
    if err ~= nil then
      vim.notify(err)
      return
    end

    local lines = {}

    for _, message in ipairs(answer.messages) do
      for _, it in ipairs(message.text[2]) do
        if type(it[2]) == 'string' then
          table.insert(lines, it[2])
        end
      end
    end
    vim.api.nvim_buf_set_lines(goals_buf, 0, -1, true, lines)

    if answer.goals == nil then return end

    local len = #answer.goals.goals
    for i, goal in ipairs(answer.goals.goals) do
      local max_width = 0
      for _, hyp in ipairs(goal.hyps) do
        local names = {}
        for _, name in ipairs(hyp.names) do
          table.insert(names, name)
        end

        local hyp_ty_lines = split_into_lines(pretty(hyp.ty))
        if #hyp_ty_lines == 1 then
          local line = table.concat(names, ' ') .. ' : ' .. hyp_ty_lines[1]
          max_width = math.max(max_width, vim.fn.strdisplaywidth(line))
          table.insert(lines, line)
        else
          local name_line = table.concat(names, ' ') .. ' :'
          max_width = math.max(max_width, vim.fn.strdisplaywidth(name_line))
          table.insert(lines, name_line)

          for _, line in ipairs(hyp_ty_lines) do
            local indent_line = '  ' .. line
            max_width = math.max(max_width, vim.fn.strdisplaywidth(indent_line))
            table.insert(lines, indent_line)
          end
        end
      end

      local divider_index = nil
      if #goal.hyps > 0 then
        table.insert(lines, '')
        divider_index = #lines
      end

      for _, line in ipairs(split_into_lines(pretty(goal.ty))) do
        max_width = math.max(max_width, vim.fn.strdisplaywidth(line))
        table.insert(lines, line)
      end

      if divider_index ~= nil then
        local goals_win_width = vim.api.nvim_win_get_width(goals_win)
        local divider_chars = math.min(max_width, goals_win_width)
        lines[divider_index] = string.rep('─', divider_chars)
      end

      if i ~= len then
        table.insert(lines, '')
      end
    end

    vim.api.nvim_buf_set_lines(goals_buf, 0, -1, false, lines)
  end

  client:request('proof/goals', params, cb, curr_buf)
end
