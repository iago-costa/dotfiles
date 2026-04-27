-- ╔══════════════════════════════════════════════════════════════╗
-- ║  OBS Auto Chapter Markers                                    ║
-- ║  Cria marcadores automáticos baseados em mudanças de janela. ║
-- ║  Os marcadores aparecem como capítulos no YouTube.           ║
-- ╚══════════════════════════════════════════════════════════════╝
--
-- COMO USAR:
--   1. No OBS: Ferramentas → Scripts → Adicionar este arquivo
--   2. Os marcadores são gravados em um arquivo .txt ao lado do vídeo
--   3. Cole os timestamps na descrição do YouTube para capítulos automáticos
--
-- O script detecta mudanças na janela ativa (via título) e registra
-- o timestamp. Isso gera automaticamente uma lista de capítulos.

obs = obslua

-- ── Estado ─────────────────────────────────────────────────────
local markers = {}
local recording = false
local recording_start = 0
local last_window_title = ""
local output_file = ""
local check_interval = 2000      -- Verificar janela a cada 2 segundos
local min_chapter_duration = 15  -- Mínimo de 15s entre capítulos

-- ── Obter título da janela ativa ───────────────────────────────
function get_active_window_title()
    -- Wayland: usa niri msg ou swaymsg
    local handle = io.popen([[
        niri msg focused-window 2>/dev/null | grep -oP '(?<=title: ").*(?=")' ||
        swaymsg -t get_tree 2>/dev/null | jq -r '.. | select(.focused? == true) | .name // empty' ||
        xdotool getactivewindow getwindowname 2>/dev/null
    ]])
    if handle == nil then return "" end
    local result = handle:read("*l") or ""
    handle:close()
    return result
end

-- ── Formatar timestamp ─────────────────────────────────────────
function format_timestamp(seconds)
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = math.floor(seconds % 60)

    if h > 0 then
        return string.format("%d:%02d:%02d", h, m, s)
    else
        return string.format("%d:%02d", m, s)
    end
end

-- ── Limpar título para nome de capítulo ────────────────────────
function clean_title(title)
    -- Remove prefixos comuns de editores e terminais
    title = title:gsub("^%d+%s*[-–—]%s*", "")            -- Remove números iniciais
    title = title:gsub("^●%s*", "")                       -- Remove indicador de modificado
    title = title:gsub("^%[.*%]%s*", "")                  -- Remove [tags]
    title = title:gsub("%s*[-–—]%s*Helix$", "")           -- Remove "- Helix"
    title = title:gsub("%s*[-–—]%s*Zellij$", "")          -- Remove "- Zellij"
    title = title:gsub("%s*[-–—]%s*Ghostty$", "")         -- Remove "- Ghostty"
    title = title:gsub("%s*[-–—]%s*Mozilla Firefox$", "")  -- Remove "- Mozilla Firefox"
    title = title:gsub("%s*[-–—]%s*Vivaldi$", "")         -- Remove "- Vivaldi"
    title = title:gsub("%s*[-–—]%s*Google Chrome$", "")   -- Remove "- Google Chrome"

    -- Limita comprimento
    if #title > 60 then
        title = title:sub(1, 57) .. "..."
    end

    return title
end

-- ── Tick: verifica mudança de janela ───────────────────────────
function check_window()
    if not recording then return end

    local title = get_active_window_title()
    if title == "" or title == last_window_title then return end

    local elapsed = os.time() - recording_start

    -- Verifica duração mínima entre capítulos
    if #markers > 0 then
        local last_marker_time = markers[#markers].time
        if (elapsed - last_marker_time) < min_chapter_duration then
            return
        end
    end

    last_window_title = title
    local clean = clean_title(title)

    table.insert(markers, {
        time = elapsed,
        title = clean,
    })

    obs.script_log(obs.LOG_INFO, string.format(
        "📌 Marcador [%s]: %s", format_timestamp(elapsed), clean))
end

-- ── Salvar marcadores em arquivo ───────────────────────────────
function save_markers()
    if #markers == 0 then
        obs.script_log(obs.LOG_INFO, "📌 Nenhum marcador para salvar")
        return
    end

    -- Sempre adiciona "Introdução" no início se não houver
    if markers[1].time > 0 then
        table.insert(markers, 1, { time = 0, title = "Introdução" })
    end

    local file = io.open(output_file, "w")
    if file == nil then
        obs.script_log(obs.LOG_WARNING, "📌 Erro ao salvar marcadores em: " .. output_file)
        return
    end

    file:write("── YouTube Chapters ──────────────────────\n")
    file:write("Cole na descrição do vídeo:\n\n")

    for _, marker in ipairs(markers) do
        file:write(string.format("%s %s\n", format_timestamp(marker.time), marker.title))
    end

    file:write("\n── Raw Data ──────────────────────────────\n")
    for _, marker in ipairs(markers) do
        file:write(string.format("[%d] %s\n", marker.time, marker.title))
    end

    file:close()
    obs.script_log(obs.LOG_INFO, "📌 Marcadores salvos em: " .. output_file)
end

-- ── Eventos do OBS ─────────────────────────────────────────────
function on_event(event)
    if event == obs.OBS_FRONTEND_EVENT_RECORDING_STARTED then
        recording = true
        recording_start = os.time()
        markers = {}
        last_window_title = ""

        -- Define arquivo de saída baseado no nome do vídeo
        local output_dir = obs.obs_frontend_get_current_record_output_path and
            obs.obs_frontend_get_current_record_output_path() or os.getenv("HOME") .. "/Videos"
        output_file = output_dir .. "/chapters_" .. os.date("%Y-%m-%d_%H-%M-%S") .. ".txt"

        obs.script_log(obs.LOG_INFO, "📌 Auto Chapters: Gravação iniciada")

    elseif event == obs.OBS_FRONTEND_EVENT_RECORDING_STOPPED then
        recording = false
        save_markers()
        obs.script_log(obs.LOG_INFO, "📌 Auto Chapters: Gravação finalizada")
    end
end

-- ── Descrição ──────────────────────────────────────────────────
function script_description()
    return [[
<h2>📌 Auto Chapter Markers</h2>
<p>Gera automaticamente capítulos do YouTube baseados em mudanças de janela ativa.</p>
<p>Detecta quando você troca de editor/terminal/navegador e registra o timestamp.</p>
<hr>
<p><b>Saída:</b> Arquivo <code>chapters_*.txt</code> na pasta de gravação.</p>
<p>Basta copiar e colar na descrição do YouTube!</p>
]]
end

-- ── Propriedades ───────────────────────────────────────────────
function script_properties()
    local props = obs.obs_properties_create()
    obs.obs_properties_add_int(props, "check_interval", "Intervalo de Verificação (ms)", 500, 10000, 100)
    obs.obs_properties_add_int(props, "min_chapter_duration", "Duração Mín. de Capítulo (s)", 5, 120, 5)
    return props
end

function script_defaults(settings)
    obs.obs_data_set_default_int(settings, "check_interval", 2000)
    obs.obs_data_set_default_int(settings, "min_chapter_duration", 15)
end

function script_update(settings)
    check_interval = obs.obs_data_get_int(settings, "check_interval")
    min_chapter_duration = obs.obs_data_get_int(settings, "min_chapter_duration")
end

function script_load(settings)
    obs.obs_frontend_add_event_callback(on_event)
    obs.timer_add(check_window, check_interval)
end

function script_unload()
    obs.timer_remove(check_window)
end
