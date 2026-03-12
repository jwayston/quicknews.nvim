--[[
  Copyright (c) JW
  Licensed under the MIT License.
  See the LICENSE file in the project root for full license information.
--]]

local M = {}
local config = require("quicknews.config")
local utils = require("quicknews.utils")
local ui = require("quicknews.ui")

--- Internal reload function
M._reload = function()
    package.loaded["quicknews"] = nil
    package.loaded["quicknews.config"] = nil
    package.loaded["quicknews.utils"] = nil
    package.loaded["quicknews.ui"] = nil
    print("Cleared plugin cache")
    return require("quicknews")
end

--- Setup the plugin
--- @param opts table Plugin options. See README for info
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

--- Get and show news from the RSS stream in a floating window
M.get_news = function()
    lazy_init()
    if not M.config.rss then utils.show_err("RSS feed url not set") return end

    utils.show_info("Fetching latest news...")

    vim.system({ "curl", "-sf", M.config.rss }, { text = true }, function (o)
        vim.schedule(function()
            local curl_ok = utils.system_call_check(M.config, "curl", o)
            if not curl_ok then return end

            local news_items = utils.process_data(M.config, o.stdout)
            if not news_items then return end

            ui.render(M.namespace, M.config, news_items)
        end)
    end)
end

return M
