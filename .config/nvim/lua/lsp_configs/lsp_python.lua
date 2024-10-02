local nvim_lsp = require('lspconfig')

-- Configure Pyright for Python
-- nvim_lsp.pyright.setup {
--   cmd = { "pyright" },
--   filetypes = { "python" },
--   settings = {
--     python = {
--       pythonPath = vim.fn.exepath("python3"),
--       analysis = {
--         autoSearchPaths = true,
--         useLibraryCodeForTypes = true,
--         diagnosticMode = "workspace",
--         typeCheckingMode = "basic",
--       }
--     }
--   }
-- }

local lspconfig = require("lspconfig")
lspconfig.basedpyright.setup {}

-- Configure pylsp for Python
local venv_path = os.getenv('VIRTUAL_ENV')
local py_path = nil
-- decide which python executable to use for mypy
if venv_path ~= nil then
  py_path = venv_path .. "/bin/python3"
else
  py_path = vim.g.python3_host_prog
end

nvim_lsp.pylsp.setup {
  cmd = { "pylsp" },
  filetypes = { "python" },
  settings = {
    pylsp = {
      plugins = {
        -- formatter options
        black = { enabled = true },
        autopep8 = { enabled = false },
        yapf = { enabled = false },
        -- linter options
        pylint = { enabled = true, executable = "pylint" },
        ruff = { enabled = false },
        pyflakes = { enabled = false },
        pycodestyle = { enabled = false },
        -- type checker
        pylsp_mypy = {
          enabled = true,
          overrides = { "--python-executable", py_path, true },
          report_progress = true,
          live_mode = false
        },
        -- auto-completion options
        jedi_completion = { fuzzy = true },
        -- import sorting
        isort = { enabled = true },
      },
    },
  },
  flags = {
    debounce_text_changes = 200,
  },
}
