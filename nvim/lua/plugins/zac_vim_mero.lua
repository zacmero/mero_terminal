return {
  {
    "folke/snacks.nvim",
    opts = function(_, opts)
      opts.dashboard = vim.tbl_deep_extend("force", opts.dashboard or {}, {
        enabled = vim.env.MERO_IDE_TARGET == nil or vim.env.MERO_IDE_TARGET == "",
      })
      opts.explorer = vim.tbl_deep_extend("force", opts.explorer or {}, {
        enabled = false,
        replace_netrw = false,
      })
    end,
    keys = {
      { "<leader>e", false },
      { "<leader>E", false },
      { "<leader>fe", false },
      { "<leader>fE", false },
    },
  },
  {
    "nvim-neo-tree/neo-tree.nvim",
    lazy = false,
    keys = {
      {
        "<leader>e",
        function()
          require("neo-tree.command").execute({
            toggle = true,
            dir = vim.uv.cwd(),
            position = "left",
            reveal = true,
          })
        end,
        desc = "Explorer NeoTree (cwd)",
      },
      {
        "<leader>ge",
        function()
          require("neo-tree.command").execute({ source = "git_status", toggle = true })
        end,
        desc = "Git Explorer",
      },
      {
        "<leader>fi",
        function()
          require("neo-tree.command").execute({
            action = "show",
            source = "filesystem",
            position = "left",
            dir = vim.uv.cwd(),
            reveal = true,
          })
        end,
        desc = "Mero IDE Explorer",
      },
    },
    opts = function(_, opts)
      opts.sources = { "filesystem", "buffers", "git_status" }
      opts.open_files_do_not_replace_types = { "terminal", "Trouble", "trouble", "qf", "Outline" }
      opts.filesystem = vim.tbl_deep_extend("force", opts.filesystem or {}, {
        bind_to_cwd = false,
        follow_current_file = { enabled = true },
        hijack_netrw_behavior = "disabled",
        use_libuv_file_watcher = true,
      })
      opts.window = vim.tbl_deep_extend("force", opts.window or {}, {
        width = 32,
        mappings = {
          ["l"] = "open",
          ["h"] = "close_node",
          ["<space>"] = "none",
          ["P"] = { "toggle_preview", config = { use_float = false } },
        },
      })
      opts.default_component_configs = vim.tbl_deep_extend("force", opts.default_component_configs or {}, {
        indent = {
          with_expanders = true,
          expander_collapsed = "",
          expander_expanded = "",
          expander_highlight = "NeoTreeExpander",
        },
        git_status = {
          symbols = {
            added = "A",
            deleted = "D",
            modified = "M",
            renamed = "R",
            unstaged = "󰄱",
            staged = "󰱒",
            untracked = "?",
            ignored = "",
            conflict = "",
          },
        },
      })
    end,
  },
  {
    "lewis6991/gitsigns.nvim",
    opts = function(_, opts)
      opts.signcolumn = true
      opts.numhl = true
      opts.linehl = false
      opts.word_diff = false
      opts.signs = vim.tbl_deep_extend("force", opts.signs or {}, {
        add = { text = "│" },
        change = { text = "│" },
        delete = { text = "󰍵" },
        topdelete = { text = "󰍵" },
        changedelete = { text = "│" },
        untracked = { text = "┆" },
      })
      opts.signs_staged = vim.tbl_deep_extend("force", opts.signs_staged or {}, {
        add = { text = "│" },
        change = { text = "│" },
        delete = { text = "󰍵" },
        topdelete = { text = "󰍵" },
        changedelete = { text = "│" },
      })
    end,
  },
  {
    "nvim-mini/mini.map",
    version = false,
    keys = {
      {
        "<leader>mm",
        function()
          MiniMap.toggle()
        end,
        desc = "Toggle Minimap",
      },
      {
        "<leader>mM",
        function()
          MiniMap.close()
        end,
        desc = "Close Minimap",
      },
    },
    config = function()
      local map = require("mini.map")

      map.setup({
        integrations = {
          map.gen_integration.gitsigns({
            add = "GitSignsAdd",
            change = "GitSignsChange",
            delete = "GitSignsDelete",
          }),
          map.gen_integration.diagnostic({
            error = "DiagnosticFloatingError",
            warn = "DiagnosticFloatingWarn",
          }),
          map.gen_integration.builtin_search({
            search = "Search",
          }),
        },
        symbols = {
          encode = map.gen_encode_symbols.dot("4x2"),
          scroll_line = "█",
          scroll_view = "┃",
        },
        window = {
          side = "right",
          width = 10,
          winblend = 18,
          focusable = false,
          show_integration_count = false,
        },
      })

      local minimap_group = vim.api.nvim_create_augroup("MeroMiniMap", { clear = true })

      vim.api.nvim_create_autocmd({ "BufWinEnter", "TabEnter" }, {
        group = minimap_group,
        callback = function(args)
          if vim.g.minimap_disable or vim.b[args.buf].minimap_disable then
            return
          end

          local bt = vim.bo[args.buf].buftype
          local ft = vim.bo[args.buf].filetype

          if bt ~= "" and bt ~= "help" then
            return
          end

          if vim.tbl_contains({
            "neo-tree",
            "snacks_dashboard",
            "snacks_picker_list",
            "snacks_picker_input",
            "Trouble",
            "trouble",
            "qf",
            "opencode",
            "terminal",
          }, ft) then
            return
          end

          map.open()
        end,
      })

      vim.api.nvim_create_autocmd("FileType", {
        group = minimap_group,
        pattern = {
          "neo-tree",
          "snacks_dashboard",
          "snacks_picker_list",
          "snacks_picker_input",
          "Trouble",
          "trouble",
          "qf",
          "opencode",
          "terminal",
        },
        callback = function(args)
          vim.b[args.buf].minimap_disable = true
          pcall(MiniMap.close)
        end,
      })
    end,
  },
  {
    "sudo-tee/opencode.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "folke/snacks.nvim",
      "MeanderingProgrammer/render-markdown.nvim",
    },
    cmd = { "Opencode" },
    opts = {},
    keys = {
      { "<leader>oa", "<cmd>Opencode<cr>", desc = "Opencode" },
    },
  },
  {
    "folke/todo-comments.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {},
  },
  {
    "NeogitOrg/neogit",
    dependencies = { "nvim-lua/plenary.nvim", "sindrets/diffview.nvim" },
    cmd = { "Neogit" },
    opts = {},
    keys = {
      {
        "<leader>gn",
        function()
          require("neogit").open({ kind = "split" })
        end,
        desc = "Neogit",
      },
    },
  },
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory" },
    keys = {
      { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Diffview" },
      { "<leader>gD", "<cmd>DiffviewClose<cr>", desc = "Close Diffview" },
      { "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "File History" },
    },
  },
  {
    "epwalsh/obsidian.nvim",
    version = "*",
    lazy = true,
    ft = "markdown",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    opts = function()
      local workspaces = {}

      local configured_vault = vim.env.OBSIDIAN_VAULT_DIR
      if configured_vault and configured_vault ~= "" then
        table.insert(workspaces, {
          name = "vault",
          path = configured_vault,
        })
      end

      table.insert(workspaces, {
        name = "current-markdown-dir",
        path = function()
          return assert(vim.fs.dirname(vim.api.nvim_buf_get_name(0)))
        end,
        overrides = {
          notes_subdir = vim.NIL,
          new_notes_location = "current_dir",
          templates = {
            folder = vim.NIL,
          },
          disable_frontmatter = true,
        },
      })

      return {
        workspaces = workspaces,
      }
    end,
  },
}
