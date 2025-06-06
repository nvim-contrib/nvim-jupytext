local M = {}

M.check = function()
  vim.health.start "nvim-jupytext"

  -- let's check if jupytext is installed
  vim.fn.system "jupytext --version"

  if vim.v.shell_error == 0 then
    vim.health.ok "Jupytext is available"
  else
    vim.health.error("Jupytext is not available", "Install jupytext via `pip install jupytext`")
  end
end

return M
