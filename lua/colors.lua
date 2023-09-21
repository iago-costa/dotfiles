 -- Set the background darkness level (0-100)
 local darkness_level = 1 -- Adjust this number to set the desired darkness level

 -- Calculate the background color based on the darkness level
 local background_color = string.format("#%02x%02x%02x",
   math.floor(255 * (darkness_level / 100)),
   math.floor(255 * (darkness_level / 100)),
   math.floor(255 * (darkness_level / 100))
 )

 -- Set the background color using a Vim command
 vim.api.nvim_command("hi Normal guibg=" .. background_color)

-- set autocommand to force background color on VimEnter
--
vim.cmd('autocmd VimEnter * highlight Normal guibg=' .. background_color)
