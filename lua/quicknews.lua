--[[
  Copyright (c) JW
  Licensed under the MIT License.
  See the LICENSE file in the project root for full license information.
--]]

--- @class QuickNews
local M = {}

--- @class Config
--- @field rss string RSS feed URL
--- @field height number Window height
--- @field title string Window title
--- @field max_items number Max items to show
M.config = {
    height = 10,
    max_items = 10,
}

--- @param opts Config?
M.setup = function(opts)
    M.config = vim.tbl_deep_extend("force", M.config, opts or {})
    if not M.config.rss then print("Error: missing RSS feed url") return end

    vim.api.nvim_create_user_command("QuickNews",
        function() M.get_news() end, { desc = "Show a RSS news popup" })
end

--- Open a floating scratch popup window above the command line
--- @return number buf The buffer id
--- @return number win The window id
local open_scratch_win = function()
    local win_opts = {
        relative = "editor",
        col = 0,
        width = vim.o.columns,
        style = "minimal",
        height = M.config.height,
        row = vim.o.lines - M.config.height,
        title = M.config.title
    }

    local buf = vim.api.nvim_create_buf(false, true)
    local win = vim.api.nvim_open_win(buf, true, win_opts)

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

    M.config.title = M.config.title or
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
    if not M.config.rss then return end

    local o = vim.system({ "curl", "-s", M.config.rss }, { text = true }):wait()
    if o.code ~= 0 then
        print("Curl fetch error: " .. M.config.rss)
        return
    end

    local news = parse_rss_data(o.stdout)
    if not news then news = { "Error parsing RSS feed or feed empty" } end

    local b, w = open_scratch_win()
    vim.api.nvim_buf_set_lines(b, 0, -1, false, news)
    vim.api.nvim_win_set_cursor(w, {1, 15})
end

return M
