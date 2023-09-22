

local setup_doc_keymap = {}


local START_MARKER_NAME = "init doc key"
local START_MARKER = "%-%- " .. START_MARKER_NAME
local END_MARKER_NAME = "end doc key"
local END_MARKER = "%-%- " .. END_MARKER_NAME
local SPECIAL_DOC_SEPARATOR = ":"

local KEYMAP_WIN_BUFFER_NAME = "float_bufnr"
local DOC_WIN_BUFFER_NAME = "float_bufnr2"
local FILTER_WIN_BUFFER_NAME = "float_bufnr3"

local PATH_FILES_LUA = ".config/nvim/lua"
local ACTUAL_LINE = 1

function load_doc_named_commands()
    -- Set the named command to open the floating windows :LoadDoc
    vim.cmd([[command! LoadDoc lua load_doc()]])
end

load_doc_named_commands()

function load_doc()
    local buffers = { KEYMAP_WIN_BUFFER_NAME, DOC_WIN_BUFFER_NAME, FILTER_WIN_BUFFER_NAME }
    for _, bufname in ipairs(buffers) do
        current_buf_name = vim.fn.getcwd() .. "/" .. bufname
        local bufnr = vim.fn.bufnr(current_buf_name)
        if bufnr ~= -1 then
            vim.api.nvim_buf_delete(bufnr, { force = true })
        end
    end
    
    -- Get the width and height of the Neovim window
    local width = vim.api.nvim_get_option("columns")
    local height = vim.api.nvim_get_option("lines")

    -- Calculate the width for each floating window
    local float_width = math.floor(width / 3)
    local float_height = math.floor(height / 1.5)

    -- Calculate the position for the first floating window
    local float_row = math.floor((height - float_height) / 3.5)
    local float_col = math.floor((width - float_width) / 4)

    -- Create the first floating window set a name for the buffer
    local float_bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(float_bufnr, KEYMAP_WIN_BUFFER_NAME)
    local float_opts = {
        relative = "editor",
        width = float_width,
        height = float_height,
        row = float_row,
        col = float_col,
        style = "minimal",
        focusable = false,
        title = 'Keymap',
        border = "rounded",
    }
    local float_win = vim.api.nvim_open_win(float_bufnr, true, float_opts)

    -- Calculate the position for the second floating window
    local float_row2 = float_row
    local space_between_floats = 2
    local float_col2 = float_col + space_between_floats + float_width

    -- Create the second floating window
    local float_bufnr2 = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(float_bufnr2, DOC_WIN_BUFFER_NAME)
    local float_opts2 = {
        relative = "editor",
        width = float_width,
        height = float_height + 3,
        row = float_row2,
        col = float_col2,
        style = "minimal",
        focusable = true,
        title = 'Doc',
        border = "rounded",
    }
    local float_win2 = vim.api.nvim_open_win(float_bufnr2, true, float_opts2)

    -- Calculate the position for the second floating window
    local space_between_floats = 2
    local float_col3 = float_col
    local float_row3 = float_row + space_between_floats + float_height

    -- Create the first floating window to filter the files in the first floating window
    local float_bufnr3 = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(float_bufnr3, FILTER_WIN_BUFFER_NAME)
    local float_opts3 = {
        relative = "editor",
        width = (float_width * 1),
        height = 1,
        row = float_row3,
        col = float_col3,
        style = "minimal",
        focusable = true,
        title = 'Filter',
        border = "rounded",
    }
    local float_win3 = vim.api.nvim_open_win(float_bufnr3, true, float_opts3)

    -- Esc to quit the windows
    vim.api.nvim_buf_set_keymap(float_bufnr, "n", "<Esc>", "<cmd>q!<CR>", { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(float_bufnr2, "n", "<Esc>", "<cmd>q!<CR>", { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(float_bufnr3, "n", "<Esc>", "<cmd>q!<CR>", { noremap = true, silent = true })

    -- <Leader><Leader> to quit the windows 
    vim.api.nvim_buf_set_keymap(float_bufnr, "n", "<Leader><Leader>", "<cmd>q!<CR>", { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(float_bufnr2, "n", "<Leader><Leader>", "<cmd>q!<CR>", { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(float_bufnr3, "n", "<Leader><Leader>", "<cmd>q!<CR>", { noremap = true, silent = true })

    -- Set see numbers in the windows
    vim.api.nvim_win_set_option(float_win, "number", true)
    vim.api.nvim_win_set_option(float_win2, "number", true)
    
    -- Set modifiable in the windows
    vim.api.nvim_buf_set_option(float_bufnr, "modifiable", true)
    vim.api.nvim_buf_set_option(float_bufnr2, "modifiable", true)
    vim.api.nvim_buf_set_option(float_bufnr3, "modifiable", true)

    -- Set focus in the window
    vim.api.nvim_set_current_win(float_win3)

    -- Open in insert mode the window float_win3
    vim.api.nvim_feedkeys("i", "n", false)

    -- On Up Down in the window float_win3, execute function move_virtual_cursor_bellow or move_virtual_cursor_above in insert mode and normal mode
    vim.api.nvim_buf_set_keymap(float_bufnr3, "n", "<Up>", "<cmd>lua move_virtual_cursor_above()<CR>", { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(float_bufnr3, "n", "<Down>", "<cmd>lua move_virtual_cursor_bellow()<CR>", { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(float_bufnr3, "i", "<Up>", "<cmd>lua move_virtual_cursor_above()<CR>", { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(float_bufnr3, "i", "<Down>", "<cmd>lua move_virtual_cursor_bellow()<CR>", { noremap = true, silent = true })

    -- Set the content of the first window
    set_all_full_path_files_in_buffer(PATH_FILES_LUA, float_bufnr)

    -- Initialize the virtual cursor
    initialize_virtual_cursor()
    
    -- Set up the autocommands to trigger the function on cursor movement get name of the buffer from KEYMAP_WIN_BUFFER_NAME
    vim.cmd([[autocmd CursorMoved,CursorMovedI ]] .. FILTER_WIN_BUFFER_NAME .. [[ lua on_write()]])

    -- Dismiss the autocmd when the window is closed
    vim.cmd([[autocmd BufWinLeave ]] .. KEYMAP_WIN_BUFFER_NAME .. [[ lua vim.cmd("autocmd! CursorMoved,CursorMovedI ]] .. KEYMAP_WIN_BUFFER_NAME .. [[")]])
    vim.cmd([[autocmd BufWinLeave ]] .. DOC_WIN_BUFFER_NAME .. [[ lua vim.cmd("autocmd! CursorMoved,CursorMovedI ]] .. DOC_WIN_BUFFER_NAME .. [[")]])
    vim.cmd([[autocmd BufWinLeave ]] .. FILTER_WIN_BUFFER_NAME .. [[ lua vim.cmd("autocmd! CursorMoved,CursorMovedI ]] .. FILTER_WIN_BUFFER_NAME .. [[")]])

    -- Close the float_win2 when the float_win is closed
    vim.cmd([[autocmd BufWinLeave ]] .. KEYMAP_WIN_BUFFER_NAME .. [[ lua closeFloatWindows()]])
    vim.cmd([[autocmd BufWinLeave ]] .. DOC_WIN_BUFFER_NAME .. [[ lua closeFloatWindows()]])
    vim.cmd([[autocmd BufWinLeave ]] .. FILTER_WIN_BUFFER_NAME .. [[ lua closeFloatWindows()]])

    -- Define a custom highlight group for green text
    vim.api.nvim_command('highlight Green ctermfg=green guifg=green')

    -- Define a custom highlight group for red text
    vim.api.nvim_command('highlight Red ctermfg=red guifg=red')

    -- Define a custom highlight group for blue text
    vim.api.nvim_command('highlight Blue ctermfg=blue guifg=blue')

    -- Define a custom highlight group for black text
    vim.api.nvim_command('highlight White ctermfg=white guifg=white')
end


function initialize_virtual_cursor()
    ACTUAL_LINE = 1

    local keymap_buffer_id = get_buffer_id_by_name(KEYMAP_WIN_BUFFER_NAME)

    -- Verify with the buffer KEYMAP_WIN_BUFFER_NAME have chars in the first line
    local first_line = vim.api.nvim_buf_get_lines(keymap_buffer_id, 0, 1, false)[1]
    if first_line == nil or first_line == "" then
        return
    else
        -- Load in the buffer DOC_WIN_BUFFER_NAME the content of the line in the buffer KEYMAP_WIN_BUFFER_NAME
        local line = vim.api.nvim_buf_get_lines(keymap_buffer_id, ACTUAL_LINE - 1, ACTUAL_LINE, false)[1]

        -- Change background color of the line in the buffer KEYMAP_WIN_BUFFER_NAME
        vim.api.nvim_buf_add_highlight(keymap_buffer_id, -1, "Green", ACTUAL_LINE - 1, 0, -1)

        load_doc_from_file_path(get_buffer_id_by_name(DOC_WIN_BUFFER_NAME), line)
    end
end


function move_virtual_cursor_bellow()
    keymap_buffer_id = get_buffer_id_by_name(KEYMAP_WIN_BUFFER_NAME)
    PREVIOUS_LINE = ACTUAL_LINE
    ACTUAL_LINE = ACTUAL_LINE + 1
    if ACTUAL_LINE > vim.api.nvim_buf_line_count(keymap_buffer_id) then
        ACTUAL_LINE = 1
        PREVIOUS_LINE = vim.api.nvim_buf_line_count(keymap_buffer_id)
    end

    -- Load in the buffer DOC_WIN_BUFFER_NAME the content of the line in the buffer KEYMAP_WIN_BUFFER_NAME
    local line = vim.api.nvim_buf_get_lines(keymap_buffer_id, ACTUAL_LINE - 1, ACTUAL_LINE, false)[1]
    
    -- Change background color of the line in the buffer KEYMAP_WIN_BUFFER_NAME
    vim.api.nvim_buf_add_highlight(keymap_buffer_id, -1, "Green", ACTUAL_LINE - 1, 0, -1)
    
    -- Clear the highlight for PREVIOUS_LINE
    vim.api.nvim_buf_clear_namespace(keymap_buffer_id, -1, PREVIOUS_LINE - 1, PREVIOUS_LINE)

    load_doc_from_file_path(get_buffer_id_by_name(DOC_WIN_BUFFER_NAME), line)
end


function move_virtual_cursor_above()
    keymap_buffer_id = get_buffer_id_by_name(KEYMAP_WIN_BUFFER_NAME)
    NEXT_LINE = ACTUAL_LINE 
    ACTUAL_LINE = ACTUAL_LINE - 1
    if ACTUAL_LINE < 1 then
        ACTUAL_LINE = vim.api.nvim_buf_line_count(keymap_buffer_id)
        NEXT_LINE = 0
    end

    -- Load in the buffer DOC_WIN_BUFFER_NAME the content of the line in the buffer KEYMAP_WIN_BUFFER_NAME
    local line = vim.api.nvim_buf_get_lines(keymap_buffer_id, ACTUAL_LINE - 1, ACTUAL_LINE, false)[1]
    
    -- Change background color of the line in the buffer KEYMAP_WIN_BUFFER_NAME
    vim.api.nvim_buf_add_highlight(keymap_buffer_id, -1, "Green", ACTUAL_LINE - 1, 0, -1)

    -- Clear the highlight for NEXT_LINE
    vim.api.nvim_buf_clear_namespace(keymap_buffer_id, -1, NEXT_LINE, NEXT_LINE + 1)

    load_doc_from_file_path(get_buffer_id_by_name(DOC_WIN_BUFFER_NAME), line)
end



function closeFloatWindows()
    local float_win = vim.fn.win_findbuf(vim.fn.bufnr(KEYMAP_WIN_BUFFER_NAME))
    local float_win2 = vim.fn.win_findbuf(vim.fn.bufnr(DOC_WIN_BUFFER_NAME))
    local float_win3 = vim.fn.win_findbuf(vim.fn.bufnr(FILTER_WIN_BUFFER_NAME))

    -- Close the float_win
    if float_win[1] then
        vim.api.nvim_win_close(float_win[1], true)
    end

    -- Close the float_win2
    if float_win2[1] then
        vim.api.nvim_win_close(float_win2[1], true)
    end

    -- Close the float_win3
    if float_win3[1] then
        vim.api.nvim_win_close(float_win3[1], true)
    end
end


function load_doc_from_file_path(buffer, keymap_file_path)
    update_title_doc_window(keymap_file_path)
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
                    local start_column, end_column = line:find(part, 1, true)
                    vim.api.nvim_buf_add_highlight(buffer, -1, color, index - 1, start_column - 1, end_column) 
                    color_index = color_index + 1
                end
            end
        else
            vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { "No valid keymap block found in the file." })
        end
    end
    io.close(keymap_file)
end


local function set_lines_by_buffer_name(current_buf_name, lines)
    local buf_id = get_buffer_id_by_name(current_buf_name)

    if buf_id then
        vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, lines)
    else
        print("Buffer not found with name: " .. current_buf_name)
    end
end


function get_buffer_id_by_name(current_buf_name)
    current_buf_name = vim.fn.getcwd() .. "/" .. current_buf_name
    local buf_id
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        local name = vim.api.nvim_buf_get_name(buf)
        if name == current_buf_name then
            buf_id = buf
            break
        end
    end
    return buf_id
end


function update_title_doc_window(new_title)
    local target_buf_id = get_buffer_id_by_name(DOC_WIN_BUFFER_NAME)
    local float_win2 = vim.fn.win_findbuf(target_buf_id)

    -- Update the title of the floating window
    local title = "Doc: " .. new_title
    vim.api.nvim_win_set_config(float_win2[1], { title = title })
end


function on_write()
    -- On write the buffer FILTER_WIN_BUFFER_NAME, update the buffer KEYMAP_WIN_BUFFER_NAME
    local buf_id = get_buffer_id_by_name(FILTER_WIN_BUFFER_NAME)
    local line = vim.api.nvim_buf_get_lines(buf_id, 0, 1, false)[1]
    if line == nil or line == "" then
        set_all_full_path_files_in_buffer(PATH_FILES_LUA, get_buffer_id_by_name(KEYMAP_WIN_BUFFER_NAME))
    else
        local files = get_all_full_path_files_in_dir(PATH_FILES_LUA)
        local files_filtered = {}

        for _, file in ipairs(files) do
            if file:find(line, 1, true) then
                table.insert(files_filtered, file)
            end
        end

        set_lines_by_buffer_name(KEYMAP_WIN_BUFFER_NAME, files_filtered)
        highlight_text_in_buffer(KEYMAP_WIN_BUFFER_NAME, line)
    end
    initialize_virtual_cursor()
end


function highlight_text_in_buffer(buffer_name, text)
    -- Get the buffer ID of the current buffer
    buffer_id = get_buffer_id_by_name(buffer_name)

    -- Get content of the buffer
    local lines = vim.api.nvim_buf_get_lines(buffer_id, 0, -1, false)

    -- Map the position of the text in the buffer
    local positions = {}
    for index, line in ipairs(lines) do
        local start_column, end_column = line:find(text, 1, true)
        if start_column then
            table.insert(positions, { index - 1, start_column - 1, end_column })
            vim.api.nvim_buf_add_highlight(buffer_id, -1, "Blue", index - 1, start_column - 1, end_column)
        end
    end
end


function get_all_full_path_files_in_dir(dir)
    local files = {}
    dir = vim.fn.expand("$HOME") .. "/" .. dir
    print("dir: " .. dir)
    for _, file in ipairs(vim.fn.globpath(dir, "*", true, true)) do
        if verify_file_content(file) then
            table.insert(files, file)
        end
    end
    return files
end


function set_all_full_path_files_in_buffer(dir, buffer)
    local files = get_all_full_path_files_in_dir(dir)
    if #files == 0 then
        print("No files with doc found in dir: " .. dir)
    else
        vim.api.nvim_buf_set_lines(buffer, 0, -1, false, files)
    end
end


function verify_file_content(file_path)
    local file = io.open(file_path, "r")
    if file then
        local file_content = file:read("*a")
        if file_content:find(START_MARKER_NAME, 1, true) and file_content:find(END_MARKER_NAME, 1, true) then
            return true
        end
    end
    return false
end
