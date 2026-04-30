-- =========================
-- lazy.nvim 自动安装
-- =========================
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local repo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({
    "git", "clone", "--filter=blob:none", "--branch=stable",
    repo, lazypath
  })

  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "克隆 lazy.nvim 失败：\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\n按任意键退出..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end

vim.opt.rtp:prepend(lazypath)

-- =========================
-- 基础设置
-- =========================
vim.opt.encoding = "utf-8"
vim.opt.fileencoding = "utf-8"

-- 文件
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undofile = true

-- 行号
vim.opt.number = true
vim.opt.relativenumber = true

-- 缩进（C风格）
vim.opt.expandtab = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.autoindent = true
vim.opt.smartindent = true

-- UI
vim.opt.wrap = false
vim.opt.cursorline = true
vim.opt.signcolumn = "yes"
vim.opt.termguicolors = true
vim.opt.scrolloff = 8

-- 鼠标 & 剪贴板
vim.opt.mouse = "a"
vim.opt.clipboard = "unnamedplus"

-- 搜索
vim.opt.hlsearch = true
vim.opt.incsearch = true
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- 命令行补全
vim.opt.wildmode = "longest:full,full"
vim.opt.wildoptions = "pum"
vim.opt.pumheight = 12

-- Leader
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- =========================
-- 快捷键
-- =========================
local keymap = vim.keymap.set
local opts = { noremap = true, silent = true }

-- 插入模式
keymap("i", "jk", "<Esc>", opts)

-- 保存 / 退出
keymap({ "n", "i", "v" }, "<C-s>", "<Esc>:w<CR>", opts)
keymap("n", "<C-q>", ":q<CR>", opts)

-- 清除搜索高亮
keymap("n", "<Esc>", ":nohlsearch<CR><Esc>", opts)

-- 居中滚动
keymap("n", "<C-u>", "<C-u>zz", opts)
keymap("n", "<C-d>", "<C-d>zz", opts)
keymap("n", "%", "%zz", opts)

-- 分屏切换
keymap("n", "<C-h>", "<C-w>h", opts)
keymap("n", "<C-j>", "<C-w>j", opts)
keymap("n", "<C-k>", "<C-w>k", opts)
keymap("n", "<C-l>", "<C-w>l", opts)

-- 分屏缩放
keymap("n", "<C-Up>", ":resize -2<CR>", opts)
keymap("n", "<C-Down>", ":resize +2<CR>", opts)
keymap("n", "<C-Left>", ":vertical resize -2<CR>", opts)
keymap("n", "<C-Right>", ":vertical resize +2<CR>", opts)

-- 文件浏览
keymap("n", "<leader>e", ":Ex<CR>", opts)

-- 禁用 Ctrl+Space
keymap({ "n", "i", "v", "x", "t" }, "<C-Space>", "<Nop>", opts)
vim.g.cmp_disable_ctrl_space = true

-- F5 编译运行 C
keymap("n", "<F5>", function()
  vim.cmd("w")
  vim.cmd("!gcc -g -Wall -Wextra % -o %:r && ./%:r")
end, opts)

-- 手动格式化
keymap("n", "<leader>f", function()
  require("conform").format({ async = true })
end, opts)

-- =========================
-- 自动命令
-- =========================
local group = vim.api.nvim_create_augroup("AutoFormat", { clear = true })

vim.api.nvim_create_autocmd("BufWritePre", {
  group = group,
  callback = function()
    require("conform").format({ async = false })
  end,
})

-- =========================
-- 插件（lazy.nvim）
-- =========================
require("lazy").setup({
  spec = {
    -- 主题
    {
      "ellisonleao/gruvbox.nvim",
      priority = 1000,
      config = function()
        vim.cmd.colorscheme("gruvbox")
      end,
    },

    -- 状态栏
    {
      "nvim-lualine/lualine.nvim",
      dependencies = { "nvim-tree/nvim-web-devicons" },
      config = true,
    },

    -- 自动括号
    {
      "windwp/nvim-autopairs",
      event = "InsertEnter",
      config = true,
    },

    -- 格式化
    {
      "stevearc/conform.nvim",
      event = { "BufWritePre" },
      config = function()
        require("conform").setup({
          formatters_by_ft = {
            c = { "clang_format" },
            cpp = { "clang_format" },
            lua = { "stylua" },
            python = { "black" },
            javascript = { "prettier" },
            typescript = { "prettier" },
          },
        })
      end,
    },
  },

  install = { colorscheme = { "gruvbox" } },
  checker = { enabled = true },
})
