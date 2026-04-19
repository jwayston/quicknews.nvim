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

--- Extracts url from a text line containing a markdown link
--- @param line string Text line
--- @return string|nil # Url or nil on error
M.md_link_extract_url = function(line)
    return line:match("%]%((.-)%)")
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
--- @return table # { title: string, items: string[] }
M.parse_rss_data = function(config, data)
    data = data:gsub("<!%[CDATA%[(.-)%]%]>", "%1")  -- Remove CDATA slop
    local link_section_width = 20
    local result = { title = nil, items = {} }
    local headline_max_width = vim.o.columns - link_section_width

    local channel_block = data:match("<channel>(.-)</channel>")
    if channel_block then
        result.title = channel_block:match("<title>(.-)</title>") or nil
    end
    local matches = data:gmatch("<item>(.-)</item>")

    local i = 1
    local months = {Jan=1, Feb=2, Mar=3, Apr=4, May=5, Jun=6, Jul=7, Aug=8, Sep=9, Oct=10, Nov=11, Dec=12}
    for item_block in matches do
        local timestamp = ""
        local title = item_block:match("<title>(.-)</title>")
        local link = item_block:match("<link>(.-)</link>")
        local datetime = item_block:match("<pubDate>(.-)</pubDate>")

        if not title or not link then return result end
        if datetime and datetime ~= "" then
	    local day, month_str, year, hour, min, sec = datetime:match("%a+, (%d+) (%a+) (%d+) (%d+):(%d+):(%d+)")
	    timestamp = string.format("%s-%02d-%s %s:%s ", year, months[month_str], day, hour, min)
        end

        title = #title > headline_max_width and
            (vim.fn.strcharpart(title, 0, headline_max_width) .. "...") or title
        table.insert(result.items, string.format("%s[%s](%s)", timestamp, title, link))

        if i >= config.max_items then break end
        i = i + 1
    end

    table.sort(result.items, function(a, b) return a > b end)
    return result
end

--- Process data pipeline
--- @param config table Configuration table passed from plugin setup
--- @param raw_rss_data string Raw RSS data
--- @return table|nil # { title: string, items: string[] }
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
