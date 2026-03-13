local M = {}

local utils = require("quicknews.utils")

--- Open a floating scratch popup window above the command line
--- @param namespace number Namespace id
--- @param config table Configuration table passed from plugin setup
--- @param opts table Window options
--- @return number buf The buffer id
--- @return number win The window id
local open_scratch_win = function(namespace, config, opts)
    local win_opts = vim.tbl_deep_extend("force", {
        relative = "editor",
        col = 0,
        row = vim.o.lines - config.height,
        width = vim.o.columns,
        height = config.height,
        style = "minimal",
    }, opts or {})

    local buf = vim.api.nvim_create_buf(false, true)
    local win = vim.api.nvim_open_win(buf, true, win_opts)

    vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })
    vim.api.nvim_win_set_hl_ns(win, namespace)

    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].filetype = "markdown"
    vim.wo[win].conceallevel = 3
    vim.wo[win].concealcursor = "nc"
    vim.wo[win].wrap = false

    vim.keymap.set("n", "q", ":close<CR>", { buffer = buf, silent = true })
    vim.keymap.set("n", "<CR>", function()
        local line = vim.api.nvim_get_current_line()
        local url = md_link_extract_url(line)
        if url then vim.ui.open(url) end
    end, { buffer = buf, silent = true })
    return buf, win
end

--- Colorize the buffer's contents
--- @param buf number Buffer id
--- @param namespace number Namespace id
--- @param pre_buf_data string[] List of strings. Should be identical to buffer's contents
local colorize_buf = function(buf, namespace, pre_buf_data)
    for i, line in ipairs(pre_buf_data) do
        local line_idx = i - 1

        --- Timestamp higlight
        vim.api.nvim_buf_set_extmark(buf, namespace, line_idx, 0, {
            end_col = 14,
            hl_group = "Comment",
        })

        -- Title highlight
        local title_start = line:find("%[")
        local title_end = line:find("%]")

        if title_start and title_end then
            vim.api.nvim_buf_set_extmark(buf, namespace, line_idx, title_start - 1, {
                end_col = title_end - 1,
                hl_group = "String",
            })
        end
    end
end

--- Render the UI
--- @param namespace number Neovim namespace id 
--- @param config table Configuration table passed from plugin setup
--- @param news table The parsed RSS object { title: string, items: string[] }
M.render = function(namespace, config, news)
    assert(namespace and config,
        "ui.render(): namespace or config not provided")

    vim.api.nvim_echo({{ "" }}, false, {})  -- Clear command line area

    local b, w = open_scratch_win(namespace, config, {
        title = config.title or news.title or "Latest news"
    })

    vim.api.nvim_buf_set_lines(b, 0, -1, false, news.items)
    vim.api.nvim_win_set_cursor(w, { 1, 15 })

    colorize_buf(b, namespace, news.items)
end

return M
