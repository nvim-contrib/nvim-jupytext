local M = {}

M.setup = function()
  local core = require "jupytext.core"
  -- create the auto group
  local augroup = vim.api.nvim_create_augroup("jupytext", { clear = true })

  -- create the aut command for read
  vim.api.nvim_create_autocmd("BufReadCmd", {
    group = augroup,
    pattern = { "*.ipynb" },
    callback = function(ctx)
      local file_path = vim.fn.resolve(vim.fn.expand(ctx.match))
      local file_metadata = core.read_ipynb_metadata(file_path)
      local file_content = core.read_ipynb(file_path, file_metadata.format)

      -- Replace the buffer content with the jupytext content
      core.nvim_buf_set_lines(file_content)
      -- Set the filetype
      vim.api.nvim_command("setlocal fenc=utf-8 ft=" .. file_metadata.language)
    end,
  })

  -- create the aut command for write
  vim.api.nvim_create_autocmd({ "BufWriteCmd", "FileWriteCmd" }, {
    group = augroup,
    pattern = { "*.ipynb" },
    callback = function(ctx)
      local file_path = vim.fn.resolve(vim.fn.expand(ctx.match))
      local file_metadata = core.read_ipynb_metadata(file_path)
      local file_content = vim.api.nvim_buf_get_lines(ctx.buf, 0, -1, false)

      -- write the content
      core.write_ipynb(file_path, file_metadata, file_content)
      -- set the buffer to non-modified
      vim.api.nvim_set_option_value("modified", false, { buf = ctx.buf })

      local event = "BufWritePost"
      -- get the corrent event name
      if ctx.event == "FileWriteCmd" then event = "FileWritePost" end

      -- trigger the corrent event name
      vim.api.nvim_exec_autocmds(event, { pattern = ctx.match })
    end,
  })

  -- If we are using LazyVim make sure to run the LazyFile event so that the LSP
  -- and other important plugins get going
  if pcall(require, "lazy") then
    vim.api.nvim_exec_autocmds("User", {
      pattern = "LazyFile",
      modeline = false,
    })
  end
end

return M
