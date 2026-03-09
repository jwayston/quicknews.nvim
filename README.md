# quicknews.nvim

A plugin to show a quick popup window of most recent RSS feed items. A nifty tool if you want stay up to date with the most recent news of your choice.

![Showcase](example.png)

## Install

```nvim
vim.pack.add { "https://github.com/jwayston/quicknews.nvim" }

require("quicknews").setup({
    rss = "https://yle.fi/rss/uutiset/paauutiset",
})

vim.keymap.set("n", "<leader>nn", ":QuickNews<CR>", { silent = true })

```

Default values:

```nvim
require("quicknews").setup({
    rss = nil,               -- RSS feed url
    height = 10,             -- Window height
    max_items = 10,          -- Max RSS feed items to show
    title = nil,             -- Window title, nil uses RSS feed's channel title
    style = {
        underline = false    -- Force link underline removal
    }
})
```

## Usage

Triggering `:QuickNews` or `require("quicknews").get_news()` fetches the RSS feed and presents parsed results in a popup window. Fetching is done by calling `curl`.

Listed titles are markdown links and can be easily opened with `gx` for example. `q` is window's internal key binding and makes it quit.

