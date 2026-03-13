local utils = require("quicknews.utils")

describe("utils.system_call_check", function()
    local config = { rss = "https://example.com/rss" }

    it("returns true on successful curl call", function()
        local ok_output = { code = 0, stdout = "valid rss data", stderr = "" }
        local result = utils.system_call_check(config, "curl", ok_output)
        assert.is_true(result)
    end)

    it("returns false and shows error on non-zero exit code", function()
        local fail_output = { code = 7, stdout = "", stderr = "failed to connect" }
        local error_msg = nil
        utils.show_err = function(msg) error_msg = msg end
        local result = utils.system_call_check(config, "curl", fail_output)

        assert.is_false(result)
        assert.is_not_nil(error_msg)
        assert.is_true(error_msg:match("failed %(code 7%)") ~= nil)
    end)

    it("returns false and shows error on empty stdout", function()
        local empty_output = { code = 0, stdout = "", stderr = "" }
        local error_msg = nil
        utils.show_err = function(msg) error_msg = msg end
        local result = utils.system_call_check(config, "curl", empty_output)

        assert.is_false(result)
        assert.is_not_nil(error_msg)
        assert.is_true(error_msg:match("empty output") ~= nil)
    end)
end)

describe("utils.parse_rss_data", function()
    local config = { rss = "https://example.com/rss", max_items = 2 }

    it("returns { title = nil } when feed is missing channel title", function()
        local data = "<channel><notitle></notitle></channel>"
        local result = utils.parse_rss_data(config, data)
        assert.is_nil(result.title)
    end)

    it("returns { title = \"\" } when channel title is empty ", function()
        local data = "<channel><title></title></channel>"
        local result = utils.parse_rss_data(config, data)
        assert.is(result.title == "")
    end)

    it("returns parsed channel title", function()
        local data = "<channel><title>Fancy title!!</title></channel>"
        local result = utils.parse_rss_data(config, data)
        assert.is_not_nil(result.title)
        assert.is_true(result.title:match("Fancy title!!") ~= nil)
    end)

    it("returns items when missing pubDate in the feed data", function()
        local data = "<item><title>t</title><link>l</link></item>"
        local result = utils.parse_rss_data(config, data)
        assert(#result.items > 0)
        assert(result.items[1] == "[t](l)")
    end)

    it("returns items when item properties order is different", function()
        local data = "<item><pubDate></pubDate><link>l</link><title>t</title></item>"
        local result = utils.parse_rss_data(config, data)
        assert(#result.items > 0)
        assert(result.items[1] == "[t](l)")
    end)

    it("parses item's pubDate correctly", function()
        local data = "<item><pubDate>Thu, 12 Mar 2026 22:12:17 GMT</pubDate><link>l</link><title>t</title></item>"
        local result = utils.parse_rss_data(config, data)
        assert(#result.items > 0)
        assert(result.items[1] == "26-03-12 22:12 [t](l)")
    end)

    it("correctly removes cdata slop", function()
        local data = "<item><link><![CDATA[l]]></link><title><![CDATA[title]]></title></item>"
        local result = utils.parse_rss_data(config, data)
        assert(#result.items > 0)
        assert(result.items[1] == "[title](l)")
    end)

    it("does not parse more than max_items from the feed", function()
        local data = "<item><link>l1</link><title>t1</title></item>" ..
                          "<item><title>t2</title><link>l2</link></item>" ..
                          "<item><title>t3</title><link>l3</link></item>"
        local result = utils.parse_rss_data(config, data)
        assert(#result.items == 2)
    end)
end)

describe("utils.md_link_extract_url", function()
    local line = "26-03-12 10:00 [Title](https://yle.fi/uutiset/123?query=true)"

    it("extracts correct url from a markdown link", function()
        local url = utils.md_link_extract_url(line)
        assert(url == "https://yle.fi/uutiset/123?query=true")
    end)
end)
