local root = vim.fn.fnamemodify(".", ":p")
local plenary_path = os.getenv("PLENARY_PATH") or "/tmp/plenary.nvim"

vim.opt.rtp:append(root)
vim.opt.rtp:append(plenary_path)
vim.cmd("runtime! plugin/plenary.vim")

vim.opt.swapfile = false
vim.opt.packpath = ""

require("quicknews")
