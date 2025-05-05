---@diagnostic disable: undefined-global

-- ============================
-- 1. Global Variables
-- ============================
vim.g.mapleader = " " -- Set leader key
vim.g.maplocalleader = "," -- Set local leader key
vim.g.have_nerd_font = true -- Enable Nerd Font support
vim.g.lightweight_mode = os.getenv("NVIM_LIGHTWEIGHT") == "1" -- Lightweight mode flag

-- ============================
-- 2. Options
-- ============================
local opt = vim.opt
opt.tabstop = 4 -- Set the width of a tab character to 4 spaces
opt.shiftwidth = 4 -- Set the number of spaces for auto-indentation
opt.expandtab = true -- Convert tab characters to spaces
opt.softtabstop = 4 -- Set the number of spaces for a tab in insert mode
opt.clipboard = "unnamedplus" -- Use system clipboard
opt.laststatus = 3 -- Always show single status line at the bottom
opt.lazyredraw = true -- Skip redraws for speed
opt.cmdheight = 0 -- Disable command line
opt.undofile = true -- Enable persistent undo
opt.undodir = vim.fn.stdpath("data") .. "/undo" -- Set undo directory
opt.swapfile = false -- Disable swap files
opt.number = true -- Show line numbers
opt.relativenumber = true -- Show relative line numbers
opt.wildmenu = true -- Enable command-line completion menu
opt.wildmode = "longest:full" -- Set command-line completion mode
opt.hidden = true -- Allow unsaved buffers to be hidden
opt.autoread = true -- Automatically read files when they change
opt.numberwidth = 2 -- Set line number width
opt.encoding = "utf-8" -- Set file encoding to UTF-8
opt.termguicolors = true -- Enable 24-bit RGB colors
opt.splitright = true -- Split windows to the right
opt.splitbelow = true -- Split windows below
opt.signcolumn = "yes" -- Always show sign column

-- ============================
-- 3. Keymaps
-- ============================
local keymap = vim.keymap.set
local opts = { noremap = true, silent = true }

local get_opts = function(desc)
	return vim.tbl_extend("force", opts, { desc = desc })
end

keymap("n", "j", "gj", get_opts("Move down by visual line"))
keymap("n", "k", "gk", get_opts("Move up by visual line"))
keymap("n", "<leader>h", ":setlocal hlsearch!<CR>", get_opts("Toggle [h]ighlight search"))
keymap("n", "<leader>q", vim.diagnostic.setloclist, get_opts("Add [q]uickfix list for diagnostics"))
keymap("t", "<Esc>", "<C-\\><C-n>", get_opts("Exit terminal mode"))

-- open terminal at the bottom or switch to existing
keymap("n", "<leader>ot", function()
	local term_buf = nil
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_get_option(buf, "buftype") == "terminal" then
			term_buf = buf
			break
		end
	end
	if term_buf then
		vim.cmd("botright split | resize 10")
		vim.api.nvim_set_current_buf(term_buf)
	else
		vim.cmd("botright split | resize 10 | terminal")
	end
end, get_opts("[O]pen [T]erminal"))

-- open terminal at the bottom with small size
keymap("n", "<leader>nt", ":botright split | resize 10 | terminal<CR>", get_opts("[N]ew [T]erminal"))

-- ============================
-- 4. Autocommands
-- ============================

-- emit OSC7 signal to update terminal title
vim.api.nvim_create_autocmd("DirChanged", {
	callback = function(args)
		local cwd = args.file
		local osc7 = string.format("\x1b]7;file://%s%s\x1b\\", vim.loop.os_gethostname(), cwd)
		vim.api.nvim_chan_send(vim.v.stderr, osc7)
	end,
})

-- for avoiding the error message when read only mode
vim.api.nvim_create_autocmd("BufNewFile", {
	callback = function()
		vim.bo.fileencoding = "utf-8" -- Set file encoding (disk representation)
	end,
})

-- highlight yanked text
vim.api.nvim_create_autocmd("TextYankPost", {
	group = vim.api.nvim_create_augroup("highlight-yank", { clear = true }),
	callback = function()
		vim.highlight.on_yank({ timeout = 350 })
	end,
})

-- disable auto-wrap and continuation for comments
vim.api.nvim_create_autocmd("FileType", {
	pattern = "*",
	callback = function()
		-- Disable auto-wrap and continuation for comments
		vim.opt_local.formatoptions:remove({ "c", "r", "o" })
	end,
})

-- disable some options for copilot buffers
vim.api.nvim_create_autocmd("BufEnter", {
	pattern = "copilot-*",
	once = true, -- Load the latest state only once
	callback = function()
		-- Set buffer-local options
		vim.opt_local.relativenumber = false
		vim.opt_local.number = false
		vim.opt_local.conceallevel = 0
		vim.b.miniindentscope_disable = true
	end,
})

-- disable miniindentscope in terminal buffers
vim.api.nvim_create_autocmd("TermOpen", {
	callback = function()
		vim.b.miniindentscope_disable = true
	end,
})

-- ==========================
-- 5. Filetype-specific settings
-- ==========================

-- insert a line with "import pdb; pdb.set_trace()" in Python files
vim.api.nvim_create_autocmd("FileType", {
	pattern = "python",
	callback = function()
		vim.keymap.set("n", "<leader>ip", function()
			local trace = "import pdb; pdb.set_trace()"
			local indent = vim.fn.indent(vim.fn.line("."))
			local indented_trace = string.rep(" ", indent) .. trace
			vim.api.nvim_put({ indented_trace }, "l", true, true)
		end, get_opts("[I]nsert [P]db trace"))
	end,
})

-- ============================
-- 6. Plugins (lazy.nvim)
-- ============================

-- Install lazy.nvim if not already installed
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"--branch=stable",
		"https://github.com/folke/lazy.nvim.git",
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({

	-- copilot completion
	{
		"zbirenbaum/copilot.lua",
		cmd = "Copilot",
		event = "InsertEnter",
		enabled = not vim.g.lightweight_mode,
		config = function()
			-- turn off copilot suggestions
			-- nvim-cmp will handle completion
			require("copilot").setup({
				panel = { enabled = false },
				suggestion = { enabled = false },
				-- filetypes = { ["*"] = true },
			})
		end,
	},

	-- copilot chat
	{
		"CopilotC-Nvim/CopilotChat.nvim",
		dependencies = {
			"zbirenbaum/copilot.lua",
			"nvim-lua/plenary.nvim",
		},
		enabled = not vim.g.lightweight_mode,
		build = "make tiktoken",
		opts = {
			mappings = { reset = { normal = "<C-x>", insert = "<C-x>" } },
			chat_autocomplete = true,
			sticky = "#buffers:visible",
			model = "claude-3.7-sonnet-thought",
			question_header = "  ", -- Header to use for user questions
			answer_header = "   ", -- Header to use for AI answers
			error_header = "   ", -- Header to use for errors
			separator = "───", -- Separator to use in chat
			references_display = "write",
			prompts = {
				-- Text related prompts
				Formal = "Please make the following text more formal.",
				Natural = "Please make the following text more natural, human-like and causal",
				Translate = "Please translate the following text to English. if english, please translate to korean.",
				Summarize = {
					prompt = "You are a technical writer. Your job is to summarize the conversation in a clean and concise manner.\n"
						.. "Your summary will be uploaded technical documentation.\n"
						.. "- Format in markdown with clear sections\n"
						.. "- use H1 heading for title with meaningful title\n"
						.. "- Choose main topics and subtopics\n"
						.. "- Write in a clear and concise manner\n"
						.. "- Make it informative and easy to understand\n"
						.. "- Every heading starts with appropriate emoji\n"
						.. "- Give examples for clarity\n"
						.. "- If table, latex, mermaid or code are needed to explain, use it\n\n",
					progress = function()
						return false
					end,
					callback = function(response, source)
						local chat = require("CopilotChat")
						chat.chat:append("Plan updated successfully!", source.winnr)
						local chat_file = os.getenv("HOME")
							.. "/Projects/notes/copilot/"
							.. os.date("%Y-%m-%d-%H-%M-%S")
							.. ".md"
						local dir = vim.fn.fnamemodify(chat_file, ":h")
						vim.fn.mkdir(dir, "p")
						local file = io.open(chat_file, "w")
						if file then
							file:write(response)
							file:close()
						end
					end,
				},
			},
		},
		cmd = "CopilotChat",
		keys = {
			{ "<leader>cc", ":CopilotChat<CR>", desc = "[C]opilot [C]hat" },
			{ "<leader>cs", ":CopilotChatSave latest<CR>", desc = "[C]opilot [S]ave as latest.json" },
			{ "<leader>cl", ":CopilotChatLoad latest<CR>", desc = "[C]opilot [L]ave as latest.json" },
		},
	},

	-- better code parsing
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		main = "nvim-treesitter.configs", -- Sets main module to use for opts
		opts = {
			ensure_installed = {
				"python",
				"cpp",
				"javascript",
				"lua",
				"bash",
				"markdown",
				"markdown_inline",
				"dockerfile",
				"yaml",
				"json",
				"toml",
			},
			auto_install = true,
			-- native highlight is better for csv
			highlight = { enable = true, disable = { "csv" } },
			indent = { enable = true },
		},
	},

	-- fuzzy finder for everything
	{
		"nvim-telescope/telescope.nvim",
		event = "VimEnter",
		dependencies = {
			"nvim-lua/plenary.nvim",
			{
				"nvim-telescope/telescope-fzf-native.nvim",
				build = "make",
				cond = function()
					return vim.fn.executable("make") == 1
				end,
			},
			"nvim-telescope/telescope-ui-select.nvim",
			{ "nvim-tree/nvim-web-devicons", enabled = vim.g.have_nerd_font },
		},
		config = function()
			require("telescope").setup({
				extensions = {
					["ui-select"] = require("telescope.themes").get_dropdown(),
				},
				pickers = {
					buffers = {
						mappings = {
							i = {
								["<C-d>"] = require("telescope.actions").delete_buffer,
							},
							n = {
								["<C-d>"] = require("telescope.actions").delete_buffer,
							},
						},
					},
				},
			})
			pcall(require("telescope").load_extension, "fzf")
			pcall(require("telescope").load_extension, "ui-select")
			pcall(require("telescope").load_extension, "workspaces")

			local builtin = require("telescope.builtin")
			vim.keymap.set("n", "<leader><leader>", function()
				builtin.find_files({ find_command = { "rg", "--files", "--hidden", "-g", "!*.git" } })
			end)
			vim.keymap.set("n", "<leader>sb", builtin.buffers, { desc = "Search Buffers" })
			vim.keymap.set("n", "<leader>st", builtin.builtin, { desc = "[S]earch [T]elescope" })
			vim.keymap.set("n", "<leader>sd", builtin.diagnostics, { desc = "[S]earch [D]iagnostics" })
			vim.keymap.set("n", "<leader>sg", builtin.live_grep, { desc = "[S]earch by [G]rep" })
			vim.keymap.set("n", "<leader>sf", function()
				local cwd = vim.fn.input("Enter directory: ", "", "dir")
				if cwd and cwd ~= "" then
					builtin.find_files({
						find_command = { "rg", "--files", "--hidden", "-g", "!*.git" },
						cwd = cwd,
					})
				end
			end, { desc = "[S]earch [F]iles" })
		end,
	},

	-- better file explorer than netrw
	{
		"nvim-neo-tree/neo-tree.nvim",
		branch = "v3.x",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-tree/nvim-web-devicons",
			"MunifTanjim/nui.nvim",
		},
		opts = {
			source_selector = {
				winbar = false,
				sources = {
					{ source = "filesystem", display_name = " Files" },
					{ source = "buffers", display_name = " Buffers" },
					{ source = "git_status", display_name = " Git" },
				},
			},
		},
		config = function()
			vim.keymap.set("n", "<leader>of", ":Neotree toggle<CR>", { desc = "[O]pen [F]ile Explorer" })
		end,
	},

	-- low contrast version of gruvbox
	{
		"sainnhe/gruvbox-material",
		priority = 1000,
		config = function()
			vim.g.gruvbox_material_transparent_background = 2
			vim.g.gruvbox_material_disable_italic_comment = false
			vim.g.gruvbox_material_enable_bold = false
			vim.g.gruvbox_material_enable_italic = false
			vim.g.gruvbox_material_background = "soft"
			vim.g.gruvbox_material_foreground = "mix" -- 'original' | 'mix' | 'material''
			vim.g.gruvbox_material_float_style = "dim"
			vim.cmd.colorscheme("gruvbox-material")
		end,
	},

	-- highlight todo, notes, etc
	{
		"folke/todo-comments.nvim",
		event = "VimEnter",
		dependencies = { "nvim-lua/plenary.nvim" },
		opts = { signs = true },
	},

	-- git wrapper for neovim
	{ "tpope/vim-fugitive" },

	-- nvim mini: nvim plugin collection
	{
		"echasnovski/mini.nvim",
		config = function()
			require("mini.comment").setup()
			require("mini.trailspace").setup()
			require("mini.indentscope").setup()
			require("mini.diff").setup()
			vim.keymap.set("n", "<leader>ts", MiniTrailspace.trim, { desc = "Trim trailing whitespace" })
		end,
	},

	-- better statusline
	{
		"nvim-lualine/lualine.nvim",
		dependencies = {
			"nvim-tree/nvim-web-devicons",
			"AndreM222/copilot-lualine",
		},
		opts = {
			options = {
				icons_enabled = true,
				theme = "gruvbox-material",
				component_separators = "",
				section_separators = { left = "", right = "" },
			},
			sections = {
				lualine_a = { { "mode", separator = { left = "" }, right_padding = 2 } },
				lualine_b = { "filename", "branch", "diff" },
				lualine_c = {
					"%=",
				},
				lualine_x = {},
				lualine_y = {
					"diagnostics",
					"encoding",
					"filetype",
				},
				lualine_z = {
					{
						"copilot",
						separator = { right = "" },
						left_padding = 2,
					},
				},
			},
		},
	},

	-- autocompletion
	{
		"hrsh7th/nvim-cmp",
		event = { "InsertEnter", "CmdlineEnter" },
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-nvim-lsp-signature-help",
			"hrsh7th/cmp-path",
			"hrsh7th/cmp-calc",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-cmdline",
			"hrsh7th/cmp-emoji",
			{
				"zbirenbaum/copilot-cmp",
				config = function()
					require("copilot_cmp").setup()
				end,
			},
		},
		config = function()
			local cmp = require("cmp")
			local has_words_before = function()
				if vim.api.nvim_buf_get_option(0, "buftype") == "prompt" then
					return false
				end
				local line, col = unpack(vim.api.nvim_win_get_cursor(0))
				return col ~= 0
					and vim.api.nvim_buf_get_text(0, line - 1, 0, line - 1, col, {})[1]:match("^%s*$") == nil
			end

			-- global setup
			cmp.setup({
				window = {
					completion = cmp.config.window.bordered(),
					documentation = cmp.config.window.bordered(),
				},
				mapping = cmp.mapping.preset.insert({
					["<C-n>"] = vim.schedule_wrap(function(_)
						if cmp.visible() and has_words_before() then
							cmp.select_next_item({ behavior = cmp.SelectBehavior.Select })
						end
					end),
					["<C-p>"] = cmp.mapping.select_prev_item(),
					["<C-b>"] = cmp.mapping.scroll_docs(-4),
					["<C-f>"] = cmp.mapping.scroll_docs(4),
					["<C-y>"] = cmp.mapping.confirm({ select = true }),
					["<C-Space>"] = cmp.mapping.complete({}),
				}),
				sources = {
					{ name = "path", group_index = 1 },
					{ name = "calc", group_index = 1 },
					{ name = "emoji", group_index = 1 },
					{ name = "copilot", group_index = 2 },
					{ name = "nvim_lsp", group_index = 2 },
					{ name = "nvim_lsp_signature_help", group_index = 2 },
					{
						name = "buffer",
						option = {
							get_bufnrs = function()
								return vim.api.nvim_list_bufs()
							end,
						},
						group_index = 3,
					},
				},
				experimental = {
					ghost_text = {
						hl_group = "LspCodeLens",
					},
				},
			})

			-- `/` cmdline setup
			cmp.setup.cmdline({ "/", "?" }, {
				mapping = cmp.mapping.preset.cmdline(),
				sources = {
					{ name = "buffer" },
				},
			})

			-- `:` cmdline setup
			cmp.setup.cmdline(":", {
				mapping = cmp.mapping.preset.cmdline(),
				sources = cmp.config.sources({ { name = "path" } }, { { name = "cmdline" } }),
				matching = { disallow_symbol_nonprefix_matching = false },
			})
		end,
	},

	-- autoformat
	{
		"stevearc/conform.nvim",
		event = { "BufWritePre" },
		cmd = { "ConformInfo" },
		keys = {
			{
				"<leader>f",
				function()
					require("conform").format({ async = true, lsp_format = "fallback" })
				end,
				mode = "",
				desc = "[F]ormat buffer",
			},
		},
		opts = {
			notify_on_error = false,
			formatters_by_ft = {
				lua = { "stylua" },
				python = { "ruff_fix", "ruff_format", "ruff_organize_imports" },
				json = { "jq" },
			},
		},
	},

	-- lsp configuration
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			{ "williamboman/mason.nvim", opts = {} },
			"williamboman/mason-lspconfig.nvim",
			"WhoIsSethDaniel/mason-tool-installer.nvim",
			{ "j-hui/fidget.nvim", opts = {} },
		},
		enabled = not vim.g.lightweight_mode,
		config = function()
			-- setup autoinstalled LSPs
			local capabilities = vim.lsp.protocol.make_client_capabilities()
			capabilities = vim.tbl_deep_extend("force", capabilities, require("cmp_nvim_lsp").default_capabilities())
			local servers = {
				pyright = {},
				clangd = {},
				lua_ls = {},
				ts_ls = {},
				dockerls = {},
				marksman = {},
			}
			local ensure_installed = vim.tbl_keys(servers or {})
			vim.list_extend(ensure_installed, {
				"stylua",
				"ruff",
				"jq",
			})
			require("mason-tool-installer").setup({
				ensure_installed = ensure_installed,
				auto_update = false,
				run_on_start = true,
				start_delay = 3000, -- 3 second delay
				max_concurrent_installers = 4,
			})
			require("mason-lspconfig").setup({
				ensure_installed = {},
				automatic_installation = false,
				handlers = {
					function(server_name)
						local server = servers[server_name] or {}
						server.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server.capabilities or {})
						require("lspconfig")[server_name].setup(server)
					end,
				},
			})

			-- setup diagnostic signs
			vim.diagnostic.config({
				severity_sort = true,
				float = { border = "rounded", source = "if_many" },
				underline = { severity = vim.diagnostic.severity.ERROR },
				signs = vim.g.have_nerd_font and {
					text = {
						[vim.diagnostic.severity.ERROR] = "󰅚 ",
						[vim.diagnostic.severity.WARN] = "󰀪 ",
						[vim.diagnostic.severity.INFO] = "󰋽 ",
						[vim.diagnostic.severity.HINT] = "󰌶 ",
					},
				} or {},
			})

			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("lsp_config", { clear = true }),
				callback = function(event)
					local bufopts = { noremap = true, silent = true, buffer = event.buf }
					vim.keymap.set("n", "gd", vim.lsp.buf.definition, bufopts)
					vim.keymap.set("n", "gD", vim.lsp.buf.declaration, bufopts)
					vim.keymap.set("n", "gi", vim.lsp.buf.implementation, bufopts)
					vim.keymap.set("n", "gr", vim.lsp.buf.references, bufopts)
					vim.keymap.set("n", "K", vim.lsp.buf.hover, bufopts)
					vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, bufopts)
				end,
			})
		end,
	},

	{
		"natecraddock/workspaces.nvim",
		config = function()
			require("workspaces").setup()
			vim.keymap.set("n", "<leader>sw", function()
				vim.cmd("WorkspacesSyncDirs")
				vim.cmd("WorkspacesOpen")
			end, { desc = "[S]earch [W]orkspaces" })
		end,
	},

	{
		"mrjones2014/smart-splits.nvim",
		config = function()
			-- resizing splits
			vim.keymap.set("n", "<C-Left>", require("smart-splits").resize_left)
			vim.keymap.set("n", "<C-Down>", require("smart-splits").resize_down)
			vim.keymap.set("n", "<C-Up>", require("smart-splits").resize_up)
			vim.keymap.set("n", "<C-Right>", require("smart-splits").resize_right)
			-- moving between splits
			vim.keymap.set("n", "<C-h>", require("smart-splits").move_cursor_left)
			vim.keymap.set("n", "<C-j>", require("smart-splits").move_cursor_down)
			vim.keymap.set("n", "<C-k>", require("smart-splits").move_cursor_up)
			vim.keymap.set("n", "<C-l>", require("smart-splits").move_cursor_right)
		end,
	},
})
