-- OBS Recording Timer Overlay
-- Mostra timer discreto com alertas visuais (TikTok 60s, Shorts 8min)
-- Setup: Crie fonte de Texto na cena, selecione-a nas configs do script

obs = obslua
local text_source_name = ""
local recording = false
local recording_start = 0
local warn1 = 55
local warn2 = 480
local warn3 = 600

function format_time(s)
    local h = math.floor(s / 3600)
    local m = math.floor((s % 3600) / 60)
    local sec = math.floor(s % 60)
    if h > 0 then return string.format("%d:%02d:%02d", h, m, sec)
    else return string.format("%02d:%02d", m, sec) end
end

function set_text(text)
    local src = obs.obs_get_source_by_name(text_source_name)
    if src == nil then return end
    local s = obs.obs_data_create()
    obs.obs_data_set_string(s, "text", text)
    obs.obs_source_update(src, s)
    obs.obs_data_release(s)
    obs.obs_source_release(src)
end

function update_timer()
    if not recording then return end
    local elapsed = os.difftime(os.time(), recording_start)
    local display = "REC " .. format_time(elapsed)
    if elapsed >= warn3 then display = "! " .. format_time(elapsed) .. " [LONGO]"
    elseif elapsed >= warn2 then display = "> " .. format_time(elapsed) .. " [>8min]"
    elseif elapsed >= warn1 then display = "~ " .. format_time(elapsed) .. " [~1min]" end
    set_text(display)
end

function on_event(event)
    if event == obs.OBS_FRONTEND_EVENT_RECORDING_STARTED then
        recording = true; recording_start = os.time()
    elseif event == obs.OBS_FRONTEND_EVENT_RECORDING_STOPPED then
        recording = false
        set_text("FIM " .. format_time(os.difftime(os.time(), recording_start)))
    end
end

function script_description()
    return "<h2>Recording Timer</h2><p>Timer com alertas para TikTok/YouTube.</p>"
end

function script_properties()
    local props = obs.obs_properties_create()
    local sl = obs.obs_properties_add_list(props, "text_source_name", "Fonte de Texto",
        obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING)
    local sources = obs.obs_enum_sources()
    if sources then
        for _, src in ipairs(sources) do
            local sid = obs.obs_source_get_unversioned_id(src)
            if sid == "text_ft2_source" or sid == "text_ft2_source_v2" then
                obs.obs_property_list_add_string(sl, obs.obs_source_get_name(src), obs.obs_source_get_name(src))
            end
        end
        obs.source_list_release(sources)
    end
    obs.obs_properties_add_int(props, "warn1", "Aviso TikTok (s)", 10, 300, 5)
    obs.obs_properties_add_int(props, "warn2", "Aviso Shorts (s)", 60, 900, 10)
    obs.obs_properties_add_int(props, "warn3", "Aviso Longo (s)", 120, 3600, 30)
    return props
end

function script_defaults(s)
    obs.obs_data_set_default_int(s, "warn1", 55)
    obs.obs_data_set_default_int(s, "warn2", 480)
    obs.obs_data_set_default_int(s, "warn3", 600)
end

function script_update(s)
    text_source_name = obs.obs_data_get_string(s, "text_source_name")
    warn1 = obs.obs_data_get_int(s, "warn1")
    warn2 = obs.obs_data_get_int(s, "warn2")
    warn3 = obs.obs_data_get_int(s, "warn3")
end

function script_load(s)
    obs.obs_frontend_add_event_callback(on_event)
    obs.timer_add(update_timer, 1000)
end

function script_unload() obs.timer_remove(update_timer) end
