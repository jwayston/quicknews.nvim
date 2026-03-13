describe("ui.colorize_buf", function()

    it("adds extmarks for timestamps and titles when calling ui.render", function()
        local ns = vim.api.nvim_create_namespace("TestNS")
        local config = { height = 10 }
        local news = { title = "test", items = { "26-03-12 10:00 [Title](url)" } }

        require("quicknews.ui").render(ns, config, news)

        local bufs = vim.api.nvim_list_bufs()
        local test_buf = bufs[#bufs]

        local extmarks = vim.api.nvim_buf_get_extmarks(test_buf, ns, 0, -1, {})
        assert(#extmarks >= 2)
    end)
end)
