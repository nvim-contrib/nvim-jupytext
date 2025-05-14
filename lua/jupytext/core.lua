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
  local file, err = io.open(path, "w")
  if not file then error("Could not open file for writing: " .. err) end

  for _, item in ipairs(content) do
    -- ensure we write a string
    file:write(tostring(item))
    file:write "\n"
  end

  file:close()
end

-- Convert an ipynb to a script in memory
M.ipynb_file_read = function(ipynb_path, ipynb_metadata)
  local ipynb_config = ipynb_metadata.jupytext.text_representation
  local ipynb_format = ipynb_config.extension .. ":" .. ipynb_config.format_name
  local ipynb_options = "notebook_metadata_filter=-all"

  local content, err = jupytext_run(ipynb_path, {
    ["--to"] = ipynb_format,
    ["--opt"] = ipynb_options,
    ["--output"] = "-",
  })

  if not content then error("Error reading file: " .. err) end
  -- Use opts table for vim.split: { plain = true } to treat separator literally
  return vim.split(content, "\n", { plain = true })
end

-- Read an ipynb metadata
M.ipynb_file_read_metadata = function(filename)
  local content = ""

  local file = io.open(filename, "r")
  -- read the file
  if file then
    content = file:read "a"
    -- close the file
    file:close()
  end

  -- set the default content
  if content == "" then content = "{}" end
  -- decode the content
  local ok, document = pcall(vim.json.decode, content)
  if not ok then error("Error decoding file: " .. document) end

  local metadata = document["metadata"]
  if not metadata then
    metadata = {}
    -- set the document metadata
    document["metadata"] = metadata
  end

  if not metadata.kernelspec then
    metadata["kernelspec"] = {}
    -- set the document metadata
    document["metadata"] = metadata
  end

  if not metadata.kernelspec.name then
    metadata["kernelspec"]["name"] = "python3"
    -- set the document metadata
    document["metadata"] = metadata
  end

  if not metadata.kernelspec.language then
    metadata["kernelspec"]["language"] = "python"
    -- set the document metadata
    document["metadata"] = metadata
  end

  if not metadata.jupytext then
    metadata["jupytext"] = {}
    -- set the document metadata
    document["metadata"] = metadata
  end

  if not metadata.jupytext.text_representation then
    metadata["jupytext"]["text_representation"] = {}
    -- set the document metadata
    document["metadata"] = metadata
  end

  if not metadata.jupytext.text_representation.extension then
    local extensions = {
      r = ".r",
      bash = ".sh",
      julia = ".jl",
      python = ".py",
    }
    metadata["jupytext"]["text_representation"]["extension"] = extensions[metadata.kernelspec.language]
    -- set the document metadata
    document["metadata"] = metadata
  end

  if not metadata.jupytext.text_representation.format_name then
    metadata["jupytext"]["text_representation"]["format_name"] = "percent"
    -- set the document metadata
    document["metadata"] = metadata
  end

  return document["metadata"], document["cells"] ~= nil
end

-- Convert a script to ipynb and write to disk
M.ipynb_file_write = function(ipynb_path, ipynb_metadata, script_content)
  local script_config = ipynb_metadata.jupytext.text_representation
  local script_path = vim.fn.tempname() .. script_config.extension
  nvim_file_write(script_path, script_content)

  local _, err = jupytext_run(script_path, {
    ["--update-metadata"] = vim.json.encode(ipynb_metadata),
    ["--output"] = ipynb_path,
    ["--to"] = "ipynb",
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
