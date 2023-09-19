-- Set the background darkness level (0-100)
local darkness_level = 1 -- Adjust this number to set the desired darkness level

-- Calculate the background color based on the darkness level
local background_color = string.format("#%02x%02x%02x",
  math.floor(255 * (darkness_level / 100)),
  math.floor(255 * (darkness_level / 100)),
  math.floor(255 * (darkness_level / 100))
)

-- Set the background color for the Normal highlight group
vim.cmd(string.format("hi Normal guibg=%s", background_color))
