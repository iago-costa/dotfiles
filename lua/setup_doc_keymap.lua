
local START_MARKER_NAME = "init doc key"
local START_MARKER = "%-%- " .. START_MARKER_NAME
local END_MARKER_NAME = "end doc key"
local END_MARKER = "%-%- " .. END_MARKER_NAME
local SPECIAL_DOC_SEPARATOR = ":"

function load_doc_named_commands()
    -- Set the named command to open the floating windows :LoadDoc
    vim.cmd([[command! LoadDoc lua load_doc()]])
end

load_doc_named_commands()

function load_doc()
    local buffers = {"flaot_bufnr", "float_bufnr2"}

    for _, buffer_name in ipairs(buffers) do
        -- Check if the buffer exists
        if vim.fn.bufexists(buffer_name) == 1 then
            -- Delete the existing buffer
            vim.api.nvim_buf_delete(vim.fn.bufnr(buffer_name, true), { force = true })
        end
    end
    
    -- Get the width and height of the Neovim window
    local width = vim.api.nvim_get_option("columns")
    local height = vim.api.nvim_get_option("lines")

    -- Calculate the width for each floating window
    local float_width = math.floor(width / 4)
    local float_height = math.floor(height / 2)

    -- Calculate the position for the first floating window
    local float_row = math.floor((height - float_height) / 2)
    local float_col = math.floor((width - float_width) / 4)

    -- Create the first floating window set a name for the buffer
    local float_bufnr = vim.api.nvim_create_buf(false, true)
    -- Delete old buffer with the same name
    vim.cmd([[autocmd! CursorMoved,CursorMovedI float_bufnr]])
    vim.api.nvim_buf_set_name(float_bufnr, "float_bufnr")
    local float_opts = {
        relative = "editor",
        width = float_width,
        height = float_height,
        row = float_row,
        col = float_col,
        style = "minimal",
        focusable = true,
        title = 'Keymap',
        border = "rounded",
    }
    local float_win = vim.api.nvim_open_win(float_bufnr, true, float_opts)

    -- Calculate the position for the second floating window
    local float_row2 = float_row
    local space_between_floats = 3
    local float_col2 = float_col + space_between_floats + float_width

    -- Create the second floating window
    local float_bufnr2 = vim.api.nvim_create_buf(false, true)
    -- Delete old buffer with the same name
    vim.cmd([[autocmd! CursorMoved,CursorMovedI float_bufnr2]])
    vim.api.nvim_buf_set_name(float_bufnr2, "float_bufnr2")
    
    local float_opts2 = {
        relative = "editor",
        width = float_width,
        height = float_height,
        row = float_row2,
        col = float_col2,
        style = "minimal",
        focusable = true,
        title = 'Doc',
        border = "rounded",
    }
    local float_win2 = vim.api.nvim_open_win(float_bufnr2, true, float_opts2)

    -- Set the keymap for the windows
    -- Esc to quit the windows need affect the two windows in the same time
    vim.api.nvim_buf_set_keymap(float_bufnr, "n", "<Esc>", "<cmd>q!<CR>", { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(float_bufnr2, "n", "<Esc>", "<cmd>q!<CR>", { noremap = true, silent = true })

    -- <Leader><Leader> to quit the windows need affect the two windows in the same time
    vim.api.nvim_buf_set_keymap(float_bufnr, "n", "<Leader><Leader>", "<cmd>q!<CR>", { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(float_bufnr2, "n", "<Leader><Leader>", "<cmd>q!<CR>", { noremap = true, silent = true })

    -- Set see numbers in the windows
    vim.api.nvim_win_set_option(float_win, "number", true)
    vim.api.nvim_win_set_option(float_win2, "number", true)
    
    -- Set modifiable in the windows
    vim.api.nvim_buf_set_option(float_bufnr, "modifiable", true)
    vim.api.nvim_buf_set_option(float_bufnr2, "modifiable", true)

    -- Set focus in the first window
    vim.api.nvim_set_current_win(float_win)

    -- Set the content of the first window
    set_all_full_path_files_in_buffer(".config/nvim/lua", float_bufnr)
    
    -- Set on click dismiss the floating windows
    -- vim.api.nvim_buf_set_keymap(float_bufnr, "n", "<LeftMouse>", "<cmd>q!<CR>", { noremap = true, silent = true })
    -- vim.api.nvim_buf_set_keymap(float_bufnr2, "n", "<LeftMouse>", "<cmd>q!<CR>", { noremap = true, silent = true })

    -- Set up the autocommands to trigger the function on cursor movement
    vim.cmd([[autocmd CursorMoved,CursorMovedI float_bufnr lua on_cursor_moved()]])

    -- Dismiss the autocmd when the window is closed
    vim.cmd([[autocmd BufWinLeave float_bufnr lua vim.cmd("autocmd! CursorMoved,CursorMovedI float_bufnr")]])
    vim.cmd([[autocmd BufWinLeave float_bufnr2 lua vim.cmd("autocmd! CursorMoved,CursorMovedI float_bufnr2")]])
    
    -- Close the float_win2 when the float_win is closed
    vim.cmd([[autocmd BufWinLeave float_bufnr lua closeFloatWin2()]])
    vim.cmd([[autocmd BufWinLeave float_bufnr2 lua closeFloatWin2()]])

    -- Define a custom highlight group for green text
    vim.api.nvim_command('highlight Green ctermfg=green guifg=green')

    -- Define a custom highlight group for red text
    vim.api.nvim_command('highlight Red ctermfg=red guifg=red')

    -- Define a custom highlight group for blue text
    vim.api.nvim_command('highlight Blue ctermfg=blue guifg=blue')

    -- Define a custom highlight group for black text
    vim.api.nvim_command('highlight White ctermfg=white guifg=white')
end


function closeFloatWin2()
    local float_win2 = vim.fn.win_findbuf(vim.fn.bufnr('float_bufnr2'))
    local float_win = vim.fn.win_findbuf(vim.fn.bufnr('float_bufnr'))
    -- Close the float_win2
    if float_win2[1] then
        vim.api.nvim_win_close(float_win2[1], true)
    end

    -- Close the float_win
    if float_win[1] then
        vim.api.nvim_win_close(float_win[1], true)
    end
end


function load_doc_from_file_path(buffer, keymap_file_path)
    -- Read the keymap file and insert its contents into the buffer
    local keymap_file = io.open(keymap_file_path, "r")
    if keymap_file then
        local keymap_contents = keymap_file:read("*a")

        -- Extract the block between "-- init doc key" and "-- end doc key"
        local start_marker, end_marker = keymap_contents:match("(" .. START_MARKER .. ")(.-)(" .. END_MARKER .. ")")
        if start_marker and end_marker then
            keymap_contents = start_marker .. end_marker
            keymap_contents = keymap_contents:gsub(START_MARKER, "")
            
            -- Escape all - with %-
            keymap_contents = keymap_contents:gsub("-", "%-")

            -- Transform the keymap contents line by line to remove the leading "-- "
            local keymap_lines = {}
            for line in keymap_contents:gmatch("[^\r\n]+") do
                line = line:gsub("%-%- ", "")
                table.insert(keymap_lines, line)
            end

            -- Load the keymap_lines_color in buffer
            vim.api.nvim_buf_set_lines(buffer, 0, -1, false, keymap_lines)

            -- Transform the keymap_lines for each line add color red to before : and color green to after :
            local color_reset = "White"
            local colors = { 
                red =  "Green", 
                green = "Red" 
            }
            local colors_index = { "red", "green"}
            local keymap_lines_color = {}

            for index, line in ipairs(keymap_lines) do
                local color_index = 1
                for part in line:gmatch("([^" .. SPECIAL_DOC_SEPARATOR .. "]+)") do
                    local color = colors[colors_index[color_index]] or color_reset
                    -- Use find with escape character - to find start_column and end_column
                    local start_column, end_column = line:find(part, 1, true)
                    vim.api.nvim_buf_add_highlight(buffer, -1, color, index - 1, start_column - 1, end_column) 
                    color_index = color_index + 1
                end
            end
        else
            -- If keymap_lines is empty, add a message to the buffer
            vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { "No valid keymap block found in the file." })
            -- print("No valid keymap block found in the file.")
        end
    end
    io.close(keymap_file)
end


-- Define a function to set lines in a buffer by its name
local function set_lines_by_buffer_name(current_buf_name, lines)
    -- Find the buffer by name
    current_buf_name = vim.fn.getcwd() .. "/" .. current_buf_name
    local buf_id
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        local name = vim.api.nvim_buf_get_name(buf)
        -- print("name: " .. name)
        -- concat the current_buf_name with the full path
        if name == current_buf_name then
            buf_id = buf
            break
        end
    end

    -- If the buffer was found, set its lines
    if buf_id then
        vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, lines)
    else
        print("Buffer not found with name: " .. current_buf_name)
    end
end


function get_buffer_id_by_name(current_buf_name)
    -- Find the buffer by name
    current_buf_name = vim.fn.getcwd() .. "/" .. current_buf_name
    local buf_id
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        local name = vim.api.nvim_buf_get_name(buf)
        -- print("buffer_id: " .. name)
        -- concat the current_buf_name with the full path
        if name == current_buf_name then
            buf_id = buf
            break
        end
    end
    return buf_id
end


-- Define a function to be called when the cursor moves
function on_cursor_moved()
    -- Get the cursor position
    local cursor = vim.fn.getcurpos()
    local row = cursor[2]

    -- Get the buffer ID of the current buffer
    local buf_id = vim.api.nvim_get_current_buf()

    -- Get the content of the current row
    local line_content = vim.api.nvim_buf_get_lines(buf_id, row - 1, row, false)[1]

    -- Clear the highlight for all other lines in the buffer
    for i = 0, vim.api.nvim_buf_line_count(buf_id) - 1 do
        if i ~= row - 1 then
            vim.api.nvim_buf_clear_namespace(buf_id, -1, i, i + 1)
        end
    end
    
    -- Add icon to initial of the current row arrow to the left side
    local icon = ""
    -- Set in the first column of the current row virtual text
    vim.api.nvim_buf_set_virtual_text(buf_id, -1, row - 1, {{icon, "White"}}, {})

    -- Add highlight to the current row
    vim.api.nvim_buf_add_highlight(buf_id, -1, "Blue", row - 1, 0, -1)

    -- print("line_content: " .. line_content)
    local target_buf_id = get_buffer_id_by_name("float_bufnr2")

    -- local float_win2 = vim.fn.win_findbuf(vim.fn.bufnr('float_bufnr2')) 

    local float_win2 = vim.fn.win_findbuf(target_buf_id)

    -- Update the title of the floating window
    local title = "Doc: " .. line_content

    -- Update the title of the floating window
    vim.api.nvim_win_set_config(float_win2[1], { title = title })

    -- Redraw the window to reflect the changes
    -- vim.api.nvim_win_redraw(floating_window_id)

    load_doc_from_file_path(target_buf_id, line_content)
end


function get_all_full_path_files_in_dir(dir)
    local files = {}
    -- Get all full path files in dir
    for _, file in ipairs(vim.fn.globpath(dir, "*", true, true)) do
        if verify_file_content(file) then
            table.insert(files, file)
        end
    end
    return files
end


function set_all_full_path_files_in_buffer(dir, buffer)
    -- Concat $HOME with dir
    dir = vim.fn.expand("$HOME") .. "/" .. dir
    local files = get_all_full_path_files_in_dir(dir)
    if #files == 0 then
        print("No files with doc found in dir: " .. dir)
    else
        vim.api.nvim_buf_set_lines(buffer, 0, -1, false, files)
    end
end


function verify_file_content(file_path)
    -- Get only the file name which have -- init doc key and -- end doc key in the file
 
    local file = io.open(file_path, "r")
    if file then
        local file_content = file:read("*a")
        if file_content:find(START_MARKER_NAME, 1, true) and file_content:find(END_MARKER_NAME, 1, true) then
            return true
        end
    end
    return false
end
