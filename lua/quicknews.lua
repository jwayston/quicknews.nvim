--[[
  Copyright (c) JW
  Licensed under the MIT License.
  See the LICENSE file in the project root for full license information.
--]]

--- @class QuickNews
local M = {}
local config = require("quicknews.config")

M.setup = function(opts)
    opts = opts or {}

    M.config = vim.tbl_deep_extend("force", config.defaults, opts)

    vim.validate({
        rss = { M.config.rss, "string" },
        height = { M.config.height, "number" },
        max_items = { M.config.max_items, "number" },
        title = { M.config.title, "string", true },
        ["style.underline"] = { M.config.style.underline, "boolean" }
    })

    vim.api.nvim_create_user_command("QuickNews", function()
        M.get_news() end,
    {})
end

--- Lazy init operations
local lazy_init = function()
    if M._initialized then return end
    M.namespace = vim.api.nvim_create_namespace("QuickNews")
    vim.api.nvim_set_hl(M.namespace, "Underlined", {
        underline = M.config.style.underline
    })
    M._initialized = true
end

--- Print error message
--- @param msg string Message
local show_err = function(msg)
    local notify = vim.notify or print
    notify("[QuickNews] Error: " .. msg, vim.log.levels.ERROR)
end

--- Print info message
--- @param msg string Message
local show_info = function(msg)
    local notify = vim.notify or print
    notify("[QuickNews] " .. msg, vim.log.levels.INFO)
end

--- Open a floating scratch popup window above the command line
--- @param opts table Window options
--- @return number buf The buffer id
--- @return number win The window id
local open_scratch_win = function(opts)
    local win_opts = vim.tbl_deep_extend("force", {
        relative = "editor",
        col = 0,
        row = vim.o.lines - M.config.height,
        width = vim.o.columns,
        height = M.config.height,
        style = "minimal",
    }, opts or {})

    local buf = vim.api.nvim_create_buf(false, true)
    local win = vim.api.nvim_open_win(buf, true, win_opts)

    vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })
    vim.api.nvim_win_set_hl_ns(win, M.namespace)

    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].filetype = "markdown"
    vim.wo[win].conceallevel = 3
    vim.wo[win].concealcursor = "nc"
    vim.wo[win].wrap = false

    vim.keymap.set("n", "q", ":close<CR>", { buffer = buf, silent = true })
    return buf, win
end

--- Parse the RSS feed
--- @param data string Rss raw feed data
--- @return table # <title, list of parsed & formatted news strings>
local parse_rss_data = function(data)
    data = data:gsub("<!%[CDATA%[(.-)%]%]>", "%1")  -- Remove CDATA slop
    local result = { title = nil, items = {} }
    local headline_max_width = vim.o.columns - 20

    local channel_block = data:match("<channel>(.-)</channel>")
    result.title = channel_block:match("<title>(.-)</title>") or nil
    local matches = data:gmatch("<item>(.-)</item>")

    local i = 1
    for item_block in matches do
        local title = item_block:match("<title>(.-)</title>")
        local link = item_block:match("<link>(.-)</title>")
        local datetime = item_block:match("<pubDate>(.-)</pubDate>")
        local unixtime = vim.fn.strptime("%a, %d %b %Y %T", datetime)
        local timestamp = os.date("%y-%m-%d %H:%M", unixtime)

        title = #title > headline_max_width and
            (vim.fn.strcharpart(title, 0, headline_max_width) .. "...") or title
        table.insert(result.items, string.format("%s [%s](%s)", timestamp, title, link))

        if i >= M.config.max_items then break end
        i = i + 1
    end

    table.sort(result.items, function(a, b) return a > b end)
    return result
end

--- Get and show news from the RSS stream in a floating window
M.get_news = function()
    lazy_init()
    if not M.config.rss then show_err("RSS feed url not set") return end

    show_info("Fetching latest news...")

    vim.system({ "curl", "-sf", M.config.rss }, { text = true }, function (o)
        vim.schedule(function()
            if o.code ~= 0 then
                show_err(string.format("fetch failed (code %d): %s", o.code, M.config.rss))
                return
            end

            if not o.stdout or o.stdout == "" then
                show_err("Empty RSS feed")
                return
            end

            local news = parse_rss_data(o.stdout)
            if not news or not news.items or #news.items == 0 then
                show_err("RSS parsing failed or no items found")
                return
            end

            vim.api.nvim_echo({{ "" }}, false, {})  -- Clear command line area

            local b, w = open_scratch_win({ title = M.config.title or news.title })
            vim.api.nvim_buf_set_lines(b, 0, -1, false, news.items)
            vim.api.nvim_win_set_cursor(w, { 1, 15 })
        end)
    end)

end

return M
