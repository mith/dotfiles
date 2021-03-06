require'nvim-treesitter.configs'.setup {
    highlight = {
        enable = true
    },
    indent = {
        enable = true;
    },
    keymaps = {
        -- You can use the capture groups defined in textobjects.scm
        ["af"] = "@function.outer",
        ["if"] = "@function.inner",
        ["ac"] = "@class.outer",
        ["ic"] = "@class.inner",
    }
}

local dap = require('dap')
dap.adapters.rust = {
    type = 'executable',
    attach = {
        pidProperty = "pid",
        pidSelect = "ask"
    },
    command = 'lldb-vscode',
    env = {
        LLDB_LAUNCH_FLAG_LAUNCH_IN_TTY = "YES"
    },
    name = "lldb"
}

dap.configurations.rust = {
    {
        type = 'rust';
        request = 'launch';
        name = "Launch file";
        cwd = '${workspaceFolder}';
        program = '${workspaceFolder}/target/debug/kloonorio';
        env = {
            CARGO_MANIFEST_DIR = '${workspaceFolder}';
        }
    },
}

vim.cmd [[
    command! -complete=file -nargs=* DebugC lua require "my_debug".start_c_debugger({<f-args>}, "gdb")
]]
vim.cmd [[
    command! -complete=file -nargs=* DebugRust lua require "my_debug".start_c_debugger({<f-args>}, "gdb", "rust-gdb")
]]

-------------------------
-- LSP Configuration
-------------------------

local lspconfig = require('lspconfig')
local on_attach = function(client, bufnr)
  local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
  -- Mappings.
  local opts = { noremap=true, silent=true }
  buf_set_keymap('n', 'gD', '<Cmd>lua vim.lsp.buf.declaration()<CR>', opts)
  buf_set_keymap('n', 'gd', ':Lspsaga preview_definition<CR>', opts)
  buf_set_keymap('n', 'K', [[:Lspsaga hover_doc<CR>]], opts)
  buf_set_keymap('n', '<C-k>', [[:Lspsaga signature_help<CR>]], opts)
  buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
  buf_set_keymap('n', '<leader>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
  buf_set_keymap('n', '<leader>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts)
  buf_set_keymap('n', '<leader>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opts)
  buf_set_keymap('n', '<leader>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
  buf_set_keymap('n', '<leader>rn', [[:Lspsaga rename<CR>]], opts)
  buf_set_keymap('n', '<leader>cd', ':Lspsaga show_line_diagnostics<CR>', opts)
  buf_set_keymap('n', '<leader>cc', [[<cmd>lua require('lspsaga.diagnostic').show_cursor_diagnostics()<CR>]], opts)
  buf_set_keymap('n', '[d', ':Lspsaga diagnostic_jump_next<CR>', opts)
  buf_set_keymap('n', ']d', ':Lspsaga diagnostic_jump_prev<CR>', opts)
  buf_set_keymap('n', '<leader>q', '<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>', opts)
  buf_set_keymap('n', '<leader>a', [[:Lspsaga code_action<CR>]], opts)
  buf_set_keymap('v', '<leader>a', [[:<C-U>Lspsaga range_code_action<CR>]], opts)
  buf_set_keymap('n', 'gr', [[:Lspsaga lsp_finder<CR>]], opts)
  buf_set_keymap('n', '<leader>s', '<cmd>Telescope lsp_workspace_symbols<CR>', opts)

  -- Set some keybinds conditional on server capabilities
  if client.resolved_capabilities.document_formatting then
    buf_set_keymap("n", "<leader>f", "<cmd>lua vim.lsp.buf.formatting()<CR>", opts)
  elseif client.resolved_capabilities.document_range_formatting then
    buf_set_keymap("n", "<leader>f", "<cmd>lua vim.lsp.buf.range_formatting()<CR>", opts)
  end

  -- Set autocommands conditional on server_capabilities
  if client.resolved_capabilities.document_highlight then
    vim.api.nvim_exec([[
      hi LspReferenceRead cterm=bold ctermbg=red guibg=#282828
      hi LspReferenceText cterm=bold ctermbg=red guibg=#282828
      hi LspReferenceWrite cterm=bold ctermbg=red guibg=#282828
      augroup lsp_document_highlight
        autocmd! * <buffer>
        autocmd CursorHold <buffer> lua vim.lsp.buf.document_highlight()
        autocmd CursorMoved <buffer> lua vim.lsp.buf.clear_references()
      augroup END
    ]], false)
  end
end

local lspconfigs = require('lspconfig/configs')
if not lspconfig.rnix_lsp then
    lspconfigs.rnix_lsp = {
        default_config = {
            cmd = { "rnix-lsp" },
            root_dir= function() vim.fn.getcwd() end;
            filetypes = { "nix" },
        }
    };
end

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities.textDocument.completion.completionItem.snippetSupport = true

-- Use a loop to conveniently both setup defined servers
-- and map buffer local keybindings when the language server attaches
local servers = { "rust_analyzer", "rnix_lsp", "pyright", "bashls", "cmake", "vimls" }
for _, lsp in ipairs(servers) do
  lspconfig[lsp].setup {
      on_attach = on_attach,
      capabilities = capabilities
  }
end

lspconfig["clangd"].setup {
    on_attach = on_attach,
    cmd = { "clangd", "--background-index", "--compile-commands-dir=build" }
}

lspconfig.omnisharp.setup {
    cmd = { "/run/current-system/sw/bin/omnisharp", "-lsp", "--hostPID", tostring(vim.fn.getpid()) };
}

require'lspconfig'.sumneko_lua.setup {
  cmd = {"lua-language-server"};
  settings = {
    Lua = {
      runtime = {
        -- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
        version = 'LuaJIT',
        -- Setup your lua path
        path = vim.split(package.path, ';'),
      },
      diagnostics = {
        -- Get the language server to recognize the `vim` global
        globals = {'vim'},
      },
      workspace = {
        -- Make the server aware of Neovim runtime files
        library = {
          [vim.fn.expand('$VIMRUNTIME/lua')] = true,
          [vim.fn.expand('$VIMRUNTIME/lua/vim/lsp')] = true,
        },
      },
    },
  },
}

local saga = require('lspsaga')
saga.init_lsp_saga {
    code_action_keys = {
        quit = { '<ESC>', '<C-c>' },
        exec = '<CR>'
    },
    rename_action_keys = {
        quit = { '<ESC>', '<C-c>' },
        exec = '<CR>'
    }
}

require'compe'.setup {
  enabled = true;
  source = {
    path = true;
    buffer = true;
    nvim_lsp = true;
    nvim_lua = true;
    nvim_treesitter = true;
  };
}

local t = function(str)
  return vim.api.nvim_replace_termcodes(str, true, true, true)
end

local check_back_space = function()
    local col = vim.fn.col('.') - 1
    if col == 0 or vim.fn.getline('.'):sub(col, col):match('%s') then
        return true
    else
        return false
    end
end

-- Use (s-)tab to:
--- move to prev/next item in completion menuone
--- jump to prev/next snippet's placeholder
_G.tab_complete = function()
  if vim.fn.pumvisible() == 1 then
    return t "<C-n>"
  elseif vim.fn.call("vsnip#available", {1}) == 1 then
    return t "<Plug>(vsnip-expand-or-jump)"
  elseif check_back_space() then
    return t "<Tab>"
  else
    return vim.fn['compe#complete']()
  end
end
_G.s_tab_complete = function()
  if vim.fn.pumvisible() == 1 then
    return t "<C-p>"
  elseif vim.fn.call("vsnip#jumpable", {-1}) == 1 then
    return t "<Plug>(vsnip-jump-prev)"
  else
    return t "<S-Tab>"
  end
end

vim.api.nvim_set_keymap("i", "<Tab>", "v:lua.tab_complete()", {expr = true})
vim.api.nvim_set_keymap("s", "<Tab>", "v:lua.tab_complete()", {expr = true})
vim.api.nvim_set_keymap("i", "<S-Tab>", "v:lua.s_tab_complete()", {expr = true})
vim.api.nvim_set_keymap("s", "<S-Tab>", "v:lua.s_tab_complete()", {expr = true})
-------------------------
-- Telescope

local actions = require('telescope.actions')
require('telescope').setup{
    defaults = {
        layout_strategy = 'flex';
        mappings = {
            i = {
                ["<esc>"] = actions.close,
            }
        }
    }
}
require('telescope').load_extension('fzy_native')
require('telescope').load_extension('frecency')


require('nvim-web-devicons').setup{}

local lualine = require('lualine')
lualine.options = {
    theme = 'seoul256',
    section_separators = nil,
    component_separators = nil,
    icons_enabled = true,
}
lualine.sections = {
    lualine_a = { 'mode' },
    lualine_b = { 'branch' },
    lualine_c = { 'filename' },
    lualine_x = {
        { 'diagnostics',
          sources = { 'nvim_lsp' },
        },
    },
    lualine_y = { 'progress' },
    lualine_z = { 'location'  },
}
lualine.inactive_sections = {
    lualine_a = { 'mode' },
    lualine_b = { 'branch' },
    lualine_c = { 'filename' },
    lualine_x = {
        { 'diagnostics',
          sources = { 'nvim_lsp' },
        },
    },
    lualine_y = { 'progress' },
    lualine_z = { 'location'  },
}
lualine.status()

-- require('neuron').setup {
--     neuron_dir = "~/notes",
-- }
-- local neogit = require("neogit")
-- neogit.setup {}
