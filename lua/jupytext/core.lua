-- commands.lua
local M = {}

-- Run a jupytext command and return its stdout as a Lua string
local jupytext_run = function(input, options)
  local cmd = { "jupytext", input }

  for k, v in pairs(options) do
    if v ~= "" then
      table.insert(cmd, k .. "=" .. v)
    else
      table.insert(cmd, k)
    end
  end

  -- execute and capture output
  local output = vim.fn.system(cmd)

  if vim.v.shell_error ~= 0 then return nil, output end

  return output
end

-- Write the file
local nvim_file_write = function(path, content)
  local f, err = io.open(path, "w")

  if not f then error("could not open file for writing: " .. err) end

  for _, item in ipairs(content) do
    -- ensure we write a string
    f:write(tostring(item))
    f:write "\n"
  end

  f:close()
end

-- Convert an ipynb to a script in memory
M.ipynb_file_read = function(ipynb_path, to_format)
  local content, err = jupytext_run(ipynb_path, {
    ["--to"] = to_format,
    ["--output"] = "-",
  })

  if not content then error(err) end

  -- Use opts table for vim.split: { plain = true } to treat separator literally
  return vim.split(content, "\n", { plain = true })
end

-- Read an ipynb metadata
M.ipynb_file_read_metadata = function(filename)
  local language_names = {
    python3 = "python",
  }

  local language_extensions = {
    r = "r",
    R = "r",
    python = "py",
    julia = "jl",
    bash = "sh",
  }

  local metadata = vim.json.decode(io.open(filename, "r"):read "a")["metadata"]
  local language = metadata.kernelspec.language

  if language == nil then language = language_names[metadata.kernelspec.name] end

  local style = "hydrogen"
  local extension = language_extensions[language]
  local format = extension .. ":" .. style

  return {
    style = style,
    format = format,
    language = language,
    extension = extension,
  }
end

-- Convert a script to ipynb and write to disk
M.ipynb_file_write = function(ipynb_path, ipynb_metadata, script_content)
  local script_path = vim.fn.tempname() .. "." .. ipynb_metadata.extension
  nvim_file_write(script_path, script_content)

  local _, err = jupytext_run(script_path, {
    ["--update"] = "",
    ["--to"] = "ipynb",
    ["--output"] = ipynb_path,
  })

  if err then error(err) end

  -- clean up
  vim.fn.delete(script_path)
end

-- Sets the buffer lines without any history
M.nvim_buf_set_lines = function(content)
  -- Need to add an extra line so that the undo dance that comes later on
  -- doesn't delete the first line of the actual input
  table.insert(content, 1, "")

  -- Replace the buffer content with the jupytext content
  vim.api.nvim_buf_set_lines(0, 0, -1, false, content)

  -- In order to make :undo a no-op immediately after the buffer is read, we
  -- need to do this dance with 'undolevels'.  Actually discarding the undo
  -- history requires performing a change after setting 'undolevels' to -1 and,
  -- luckily, we have one we need to do (delete the extra line from the :r
  -- command)
  -- (Comment straight from goerz/jupytext.vim)
  local levels = vim.o.undolevels
  vim.o.undolevels = -1
  vim.api.nvim_command "silent 1delete"
  vim.o.undolevels = levels
end

return M
