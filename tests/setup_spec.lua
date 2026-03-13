
describe("M.setup", function()
    local qn = require("quicknews")

    it("throws error if rss is missing or not a string", function()
        assert.has_error(function() qn.setup({ rss = 123 }) end)
        assert.has_error(function() qn.setup({ rss = nil }) end)
        assert.has_error(function() qn.setup({}) end)
    end)

    it("accepts valid configuration", function()
        assert.has_no_error(function()
            qn.setup({ rss = "https://example.com", height = 20 })
        end)
        assert.has_no_error(function()
            qn.setup({ rss = "https://example.com", title = nil })
        end)
        assert.has_no_error(function()
            qn.setup({ rss = "https://example.com", title = "title" })
        end)
    end)

    it("rejects invalid configuration", function()
        assert.has_error(function() qn.setup({ rss = "x", max_items = "x"}) end)
        assert.has_error(function() qn.setup({ rss = "x", height = "x"}) end)
        assert.has_error(function() qn.setup({ rss = "x", title = 1}) end)
        assert.has_error(function() qn.setup({
            rss = "x", style = { underline = 0 }})
        end)
    end)
end)

