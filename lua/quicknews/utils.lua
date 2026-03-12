local M = {}

--- Print error message
--- @param msg string Message
M.show_err = function(msg)
    local notify = vim.notify or print
    notify("[QuickNews] Error: " .. msg, vim.log.levels.ERROR)
end

--- Print info message
--- @param msg string Message
M.show_info = function(msg)
    local notify = vim.notify or print
    notify("[QuickNews] " .. msg, vim.log.levels.INFO)
end

--- Check the output of calling external programs using system()
--- @param prog_name string Name of the called program
--- @param call_output vim.SystemCompleted SystemCompleted 
--- @return boolean # Whether the call was succesful
M.system_call_check = function(config, prog_name, call_output)
    if call_output.code ~= 0 then
        M.show_err(string.format(
            "%s failed (code %d): %s", prog_name, call_output.code, config.rss
        ))
        return false
    end

    if not call_output.stdout or call_output.stdout == "" then
        M.show_err("Calling " .. prog_name .. " resulted in empty output")
        return false
    end

    return true
end

--- Parse the RSS feed
--- @param data string Rss raw feed data
--- @return string[] # <title, list of parsed & formatted news strings>
M.parse_rss_data = function(config, data)
    data = data:gsub("<!%[CDATA%[(.-)%]%]>", "%1")  -- Remove CDATA slop
    local result = { title = nil, items = {} }
    local headline_max_width = vim.o.columns - 20

    local channel_block = data:match("<channel>(.-)</channel>")
    result.title = channel_block:match("<title>(.-)</title>") or nil
    local matches = data:gmatch("<item>(.-)</item>")

    local i = 1
    for item_block in matches do
        local title = item_block:match("<title>(.-)</title>")
        local link = item_block:match("<link>(.-)</link>")
        local datetime = item_block:match("<pubDate>(.-)</pubDate>")
        local unixtime = vim.fn.strptime("%a, %d %b %Y %T", datetime)
        local timestamp = os.date("%y-%m-%d %H:%M", unixtime)

        title = #title > headline_max_width and
            (vim.fn.strcharpart(title, 0, headline_max_width) .. "...") or title
        table.insert(result.items, string.format("%s [%s](%s)", timestamp, title, link))

        if i >= config.max_items then break end
        i = i + 1
    end

    table.sort(result.items, function(a, b) return a > b end)
    return result
end

--- Process data pipeline
--- @param config table Configuration table passed from plugin setup
--- @param raw_rss_data string Raw RSS data
--- @return string[]|nil # Processed list of news items strings or nil on error
M.process_data = function(config, raw_rss_data)
    assert(config and raw_rss_data,
        "utils.process_data(): config and raw_rss_data are mandatory")

    local news = M.parse_rss_data(config, raw_rss_data)

    if not news or not news.items or #news.items == 0 then
        M.show_err("RSS parsing failed or no items found")
        return nil
    end

    return news
end

return M
