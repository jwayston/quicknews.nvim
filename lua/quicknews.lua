--[[
  Copyright (c) JW
  Licensed under the MIT License.
  See the LICENSE file in the project root for full license information.
--]]

--- @class QuickNews
local M = {}

local notify = vim.notify or print
local namespace = vim.api.nvim_create_namespace("QuickNews")
local win_opts = {
    relative = "editor",
    col = 0,
    width = vim.o.columns,
    style = "minimal",
}

--- @class Config
M.config = {
    rss = nil,               -- RSS feed url
    height = 10,             -- Window height
    max_items = 10,          -- Max RSS feed items to show
    title = nil,             -- Window title, nil uses RSS feed's channel title
    style = {
        underline = false    -- Force link underline removal
    }
}

--- @param opts Config?
M.setup = function(opts)
    M.config = vim.tbl_deep_extend("force", M.config, opts or {})

    vim.api.nvim_create_user_command("QuickNews",
        function() M.get_news() end, { desc = "Show a RSS news popup" })

    vim.api.nvim_set_hl(namespace, "Underlined", { underline = M.config.style.underline })
    win_opts.height = M.config.height
    win_opts.row = vim.o.lines - win_opts.height
end

--- Print error message
--- @param msg string Message
local show_err = function(msg)
    vim.notify("[QuickNews] Error: " .. msg, vim.log.levels.ERROR)
end

--- Open a floating scratch popup window above the command line
--- @return number buf The buffer id
--- @return number win The window id
local open_scratch_win = function()
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
    return buf, win
end

--- Parse the RSS feed
--- @param data string Rss raw feed data
--- @return string[] # List of parsed & formatted news strings 
local parse_rss_data = function(data)
    local res = {}
    local title_max_width = vim.o.columns - 20
    local r_item = [[\v\<item\>\<title\>([^<]+)\<\/title\>]] ..
                    [[\<link\>([^<]+)\<\/link\>]] ..
                    [[.{-}\<pubDate\>([^<]+)\<\/pubDate\>]]

    win_opts.title = M.config.title or
        data:match("<channel><title>(.-)</title>") or ""

    local matches = vim.fn.matchstrlist({data}, r_item, {submatches = true})
    local max_items = M.config.max_items
    local limit = (max_items > 0) and math.min(max_items, #matches) or #matches

    for i = 1, limit do
        local m = matches[i]
        local unixtime = vim.fn.strptime("%a, %d %b %Y %T", m.submatches[3])
        local timestamp = os.date("%y-%m-%d %H:%M", unixtime)
        local title = m.submatches[1]
        local link = m.submatches[2]

        title = #title > title_max_width and
            (vim.fn.strcharpart(title, 0, title_max_width) .. "...") or title
        table.insert(res, string.format("%s [%s](%s)", timestamp, title, link))
    end

    table.sort(res, function(a, b) return a > b end)
    return res
end

--- Get and show news from the RSS stream in a floating window
M.get_news = function()
    if not M.config.rss then show_err("RSS feed url not set") return end

    local o = vim.system({ "curl", "-sf", M.config.rss }, { text = true }):wait()
    if o.code ~= 0 then
        show_err(string.format("fetch failed (code %d): %s", o.code, M.config.rss))
        return
    end

    if not o.stdout then show_err("Empty RSS feed") return end

    local news = parse_rss_data(o.stdout)
    if not news then show_err("RSS parsing failed") return end

    local b, w = open_scratch_win()
    vim.api.nvim_buf_set_lines(b, 0, -1, false, news)
    vim.api.nvim_win_set_cursor(w, {1, 15})
end

return M
