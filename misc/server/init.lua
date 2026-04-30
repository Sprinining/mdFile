-- 自动安装 lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
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

-- 文件编码统一UTF-8
vim.opt.encoding = "utf-8"
vim.opt.fileencoding = "utf-8"

-- 关闭临时垃圾文件，避免目录到处产生.swap/.bak
vim.opt.swapfile = false   -- 不生成交换文件
vim.opt.backup = false     -- 不生成备份文件
vim.opt.undofile = true   -- 持久化撤销，关闭文件再打开依然可以撤销

-- 行号设置
vim.opt.number = true           -- 显示绝对行号
vim.opt.relativenumber = true    -- 显示相对行号，方便快速跳转

-- C语言标准缩进配置
vim.opt.expandtab = true        -- Tab键自动转为空格
vim.opt.tabstop = 4             -- 一个Tab宽度=4个空格
vim.opt.shiftwidth = 4          -- 缩进、对齐宽度=4
vim.opt.softtabstop = 4         -- 编辑时光感Tab宽度=4
vim.opt.autoindent = true       -- 换行自动继承上一行缩进
vim.opt.smartindent = true       -- C语言语法智能缩进

-- 界面显示优化
vim.opt.wrap = false            -- 关闭文本自动换行
vim.opt.cursorline = true       -- 高亮当前所在行
vim.opt.signcolumn = "yes"      -- 左侧图标列固定宽度，防止界面左右跳动
vim.opt.termguicolors = true    -- 开启终端真彩色，主题正常显色
vim.cmd.colorscheme("gruvbox")   -- 设置内置深色主题
vim.opt.scrolloff = 8           -- 光标上下永远预留8行空白，不紧贴屏幕边缘

-- 鼠标支持 + WSL与Windows系统剪贴板互通（完美生效）
vim.opt.mouse = "a"             -- 所有模式都可以用鼠标点击、滚动
vim.opt.clipboard = "unnamedplus"

-- 搜索相关设置
vim.opt.hlsearch = true         -- 高亮搜索匹配结果
vim.opt.incsearch = true        -- 输入时实时增量搜索
vim.opt.ignorecase = true       -- 搜索默认忽略大小写
vim.opt.smartcase = true        -- 搜索含大写字母时自动区分大小写

-- 命令行 Tab 补全优化
vim.opt.wildmode = "longest:full,full"
vim.opt.wildoptions = "pum"
vim.opt.pumheight = 12

-- 设置前缀快捷键 Leader = 空格键
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- jk 快速退出插入模式
vim.keymap.set("i", "jk", "<Esc>", {noremap = true, silent = true})

-- 全模式 Ctrl+S 保存
vim.keymap.set({"n", "i", "v"}, "<C-s>", "<Esc>:w<CR>", {noremap = true, silent = true})

-- Ctrl+Q 关闭窗口
vim.keymap.set("n", "<C-q>", ":q<CR>", {noremap = true, silent = true})

-- ESC 清除搜索高亮
vim.keymap.set("n", "<Esc>", ":nohlsearch<CR><Esc>", {noremap = true, silent = true})

-- 翻页光标居中
vim.keymap.set("n", "<C-u>", "<C-u>zz", {noremap = true, silent = true})
vim.keymap.set("n", "<C-d>", "<C-d>zz", {noremap = true, silent = true})

-- 跳括号居中
vim.keymap.set("n", "%", "%zz", {noremap = true, silent = true})

-- Ctrl+hjkl 切换分屏
vim.keymap.set("n", "<C-h>", "<C-w>h", {noremap = true, silent = true})
vim.keymap.set("n", "<C-j>", "<C-w>j", {noremap = true, silent = true})
vim.keymap.set("n", "<C-k>", "<C-w>k", {noremap = true, silent = true})
vim.keymap.set("n", "<C-l>", "<C-w>l", {noremap = true, silent = true})

-- Ctrl+方向键 调整分屏大小
vim.keymap.set("n", "<C-Up>", ":resize -2<CR>", {noremap = true, silent = true})
vim.keymap.set("n", "<C-Down>", ":resize +2<CR>", {noremap = true, silent = true})
vim.keymap.set("n", "<C-Left>", ":vertical resize -2<CR>", {noremap = true, silent = true})
vim.keymap.set("n", "<C-Right>", ":vertical resize +2<CR>", {noremap = true, silent = true})

-- 一键打开文件目录
vim.keymap.set("n", "<leader>e", ":Ex<CR>", {noremap = true, silent = true})

-- 禁用所有模式下的 Ctrl+Space
vim.keymap.set({'n', 'i', 'v', 'x', 't'}, '<C-Space>', '<Nop>', { noremap = true, silent = true })

-- 防止插件（如 nvim-cmp、LuaSnip）重新绑定
vim.g.cmp_disable_ctrl_space = true

-- ========== WSL Linux 专用 F5 一键编译运行C ==========
vim.keymap.set("n", "<F5>", function()
  vim.cmd("w")
  vim.cmd("!gcc -g -Wall -Wextra % -o %:r && ./%:r")
end)

-- 手动格式化快捷键
vim.keymap.set("n", "<leader>f", function()
  require("conform").format({ async = true })
end, { noremap = true, silent = true })

-- 保存自动格式化
vim.api.nvim_create_autocmd("BufWritePre", {
  callback = function()
    require("conform").format({ async = false })
  end,
})

-- 加载并配置 lazy.nvim
require("lazy").setup({
  -- 在这里添加你需要的插件
  spec = {
      -- 状态栏
    {
      "nvim-lualine/lualine.nvim",
      dependencies = { 'nvim-tree/nvim-web-devicons' },
      config = true,
    },

    -- 自动括号
    { "windwp/nvim-autopairs", event = "InsertEnter", config = true },

    -- 代码格式化
    {
      "stevearc/conform.nvim",
      event = { "BufWritePre" },
      config = function()
        require("conform").setup({
          formatters_by_ft = {
            cpp = { "clang_format" },
            c = { "clang_format" },
            lua = { "stylua" },
            python = { "black" },
            javascript = { "prettier" },
            typescript = { "prettier" },
          },
        })
      end,
    },

  },

  -- 安装插件时使用的配色方案
  install = { colorscheme = { "gruvbox" } },

  -- 自动检查插件更新
  checker = { enabled = true },
})

