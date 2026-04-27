-- ╔══════════════════════════════════════════════════════════════╗
-- ║  OBS Zoom & Follow Mouse                                    ║
-- ║  Segue o cursor do mouse com zoom suave durante gravação.   ║
-- ║  Ideal para tutoriais de programação e screencasts.          ║
-- ╚══════════════════════════════════════════════════════════════╝
--
-- COMO USAR:
--   1. No OBS: Ferramentas → Scripts → Adicionar este arquivo
--   2. Selecione a fonte de captura de tela nas configurações do script
--   3. Defina o atalho em Configurações → Atalhos → "Zoom & Follow: Toggle"
--   4. Pressione o atalho durante a gravação para ativar/desativar o zoom
--
-- O script aplica um crop + escala na fonte selecionada para simular
-- o zoom seguindo o ponteiro do mouse com interpolação suave.

obs = obslua

-- ── Configurações ──────────────────────────────────────────────
local source_name = ""
local zoom_factor = 2.0          -- Nível de zoom (2x = mostra metade da tela)
local follow_speed = 0.08        -- Velocidade de acompanhamento (0.01=lento, 0.2=rápido)
local zoom_active = false
local animation_speed = 0.05     -- Velocidade da animação de transição do zoom

-- ── Estado interno ─────────────────────────────────────────────
local current_zoom = 1.0
local target_zoom = 1.0
local current_x = 0.5            -- Posição normalizada (0-1)
local current_y = 0.5
local target_x = 0.5
local target_y = 0.5
local base_width = 1920
local base_height = 1080
local timer_active = false

-- ── Lerp (interpolação linear) ─────────────────────────────────
local function lerp(a, b, t)
    return a + (b - a) * t
end

-- ── Clamp ──────────────────────────────────────────────────────
local function clamp(val, min_val, max_val)
    return math.max(min_val, math.min(max_val, val))
end

-- ── Callback do timer (roda a cada frame) ──────────────────────
function tick()
    local source = obs.obs_get_source_by_name(source_name)
    if source == nil then return end

    -- Obtém posição do mouse via cursor_pos
    local pos = get_mouse_pos()
    if pos then
        target_x = pos.x / base_width
        target_y = pos.y / base_height
    end

    -- Anima zoom in/out
    if zoom_active then
        target_zoom = zoom_factor
    else
        target_zoom = 1.0
    end

    current_zoom = lerp(current_zoom, target_zoom, animation_speed)
    current_x = lerp(current_x, target_x, follow_speed)
    current_y = lerp(current_y, target_y, follow_speed)

    -- Calcula o crop baseado no zoom
    if math.abs(current_zoom - 1.0) > 0.01 then
        local crop_w = base_width / current_zoom
        local crop_h = base_height / current_zoom

        -- Centro do crop na posição do mouse
        local cx = current_x * base_width - crop_w / 2
        local cy = current_y * base_height - crop_h / 2

        -- Impede que o crop saia da tela
        cx = clamp(cx, 0, base_width - crop_w)
        cy = clamp(cy, 0, base_height - crop_h)

        local crop = {
            left = math.floor(cx),
            top = math.floor(cy),
            right = math.floor(base_width - cx - crop_w),
            bottom = math.floor(base_height - cy - crop_h),
        }

        -- Aplica o crop na fonte
        local filter = obs.obs_source_get_filter_by_name(source, "ZoomFollow_Crop")
        if filter == nil then
            -- Cria o filtro de crop se não existir
            local settings = obs.obs_data_create()
            obs.obs_data_set_int(settings, "left", crop.left)
            obs.obs_data_set_int(settings, "top", crop.top)
            obs.obs_data_set_int(settings, "right", crop.right)
            obs.obs_data_set_int(settings, "bottom", crop.bottom)
            obs.obs_data_set_bool(settings, "relative", false)

            filter = obs.obs_source_create_private("crop_filter", "ZoomFollow_Crop", settings)
            obs.obs_source_filter_add(source, filter)
            obs.obs_data_release(settings)
        else
            local settings = obs.obs_source_get_settings(filter)
            obs.obs_data_set_int(settings, "left", crop.left)
            obs.obs_data_set_int(settings, "top", crop.top)
            obs.obs_data_set_int(settings, "right", crop.right)
            obs.obs_data_set_int(settings, "bottom", crop.bottom)
            obs.obs_source_update(filter, settings)
            obs.obs_data_release(settings)
        end

        -- Ajusta escala para preencher a tela
        local scene_source = obs.obs_frontend_get_current_scene()
        local scene = obs.obs_scene_from_source(scene_source)
        local scene_item = obs.obs_scene_find_source(scene, source_name)
        if scene_item then
            local scale = obs.vec2()
            scale.x = current_zoom
            scale.y = current_zoom
            obs.obs_sceneitem_set_scale(scene_item, scale)

            -- Reposiciona para manter centralizado
            local bounds = obs.vec2()
            bounds.x = base_width
            bounds.y = base_height
            obs.obs_sceneitem_set_bounds_type(scene_item, obs.OBS_BOUNDS_SCALE_INNER)
            obs.obs_sceneitem_set_bounds(scene_item, bounds)
        end
        obs.obs_source_release(scene_source)
        obs.obs_source_release(filter)
    else
        -- Remove crop quando zoom está desativado
        local filter = obs.obs_source_get_filter_by_name(source, "ZoomFollow_Crop")
        if filter then
            local settings = obs.obs_source_get_settings(filter)
            obs.obs_data_set_int(settings, "left", 0)
            obs.obs_data_set_int(settings, "top", 0)
            obs.obs_data_set_int(settings, "right", 0)
            obs.obs_data_set_int(settings, "bottom", 0)
            obs.obs_source_update(filter, settings)
            obs.obs_data_release(settings)
            obs.obs_source_release(filter)
        end
    end

    obs.obs_source_release(source)
end

-- ── Obter posição do mouse ─────────────────────────────────────
-- Usa xdotool ou ydotool para capturar posição do cursor
function get_mouse_pos()
    -- Tenta ydotool primeiro (Wayland nativo)
    local handle = io.popen("ydotool getmouseposition 2>/dev/null || xdotool getmouselocation 2>/dev/null")
    if handle == nil then return nil end

    local result = handle:read("*a")
    handle:close()

    if result == nil or result == "" then return nil end

    -- Parse ydotool format: "x:1234 y:567"
    local x, y = result:match("x:(%d+)%s+y:(%d+)")
    if x and y then
        return { x = tonumber(x), y = tonumber(y) }
    end

    -- Parse xdotool format: "x:1234 y:567 screen:0 window:12345"
    x, y = result:match("x:(%d+)%s+y:(%d+)")
    if x and y then
        return { x = tonumber(x), y = tonumber(y) }
    end

    return nil
end

-- ── Toggle zoom ────────────────────────────────────────────────
function toggle_zoom(pressed)
    if not pressed then return end
    zoom_active = not zoom_active

    if zoom_active then
        obs.script_log(obs.LOG_INFO, "🔍 Zoom & Follow: ATIVADO")
    else
        obs.script_log(obs.LOG_INFO, "🔍 Zoom & Follow: DESATIVADO")
    end
end

-- ── Descrição do script ────────────────────────────────────────
function script_description()
    return [[
<h2>🔍 Zoom & Follow Mouse</h2>
<p>Zoom suave que segue o cursor do mouse durante screencasts.</p>
<p>Ideal para tutoriais de programação, destacando o código onde você está trabalhando.</p>
<hr>
<p><b>Como usar:</b></p>
<ol>
<li>Selecione a fonte de captura de tela abaixo</li>
<li>Defina o atalho em Configurações → Atalhos → "Zoom & Follow: Toggle"</li>
<li>Pressione o atalho durante a gravação para ativar/desativar</li>
</ol>
<p><small>Requer <code>ydotool</code> (Wayland) ou <code>xdotool</code> (X11) instalado.</small></p>
]]
end

-- ── Propriedades configuráveis ─────────────────────────────────
function script_properties()
    local props = obs.obs_properties_create()

    -- Lista de fontes disponíveis
    local source_list = obs.obs_properties_add_list(props, "source_name",
        "Fonte de Captura de Tela", obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING)

    local sources = obs.obs_enum_sources()
    if sources then
        for _, source in ipairs(sources) do
            local name = obs.obs_source_get_name(source)
            obs.obs_property_list_add_string(source_list, name, name)
        end
        obs.source_list_release(sources)
    end

    obs.obs_properties_add_float_slider(props, "zoom_factor", "Nível de Zoom", 1.5, 5.0, 0.1)
    obs.obs_properties_add_float_slider(props, "follow_speed", "Velocidade de Seguimento", 0.01, 0.3, 0.01)
    obs.obs_properties_add_float_slider(props, "animation_speed", "Velocidade da Transição", 0.01, 0.2, 0.01)
    obs.obs_properties_add_int(props, "base_width", "Largura da Tela (px)", 800, 7680, 1)
    obs.obs_properties_add_int(props, "base_height", "Altura da Tela (px)", 600, 4320, 1)

    return props
end

-- ── Defaults ───────────────────────────────────────────────────
function script_defaults(settings)
    obs.obs_data_set_default_double(settings, "zoom_factor", 2.0)
    obs.obs_data_set_default_double(settings, "follow_speed", 0.08)
    obs.obs_data_set_default_double(settings, "animation_speed", 0.05)
    obs.obs_data_set_default_int(settings, "base_width", 1920)
    obs.obs_data_set_default_int(settings, "base_height", 1080)
end

-- ── Carregar configurações ─────────────────────────────────────
function script_update(settings)
    source_name = obs.obs_data_get_string(settings, "source_name")
    zoom_factor = obs.obs_data_get_double(settings, "zoom_factor")
    follow_speed = obs.obs_data_get_double(settings, "follow_speed")
    animation_speed = obs.obs_data_get_double(settings, "animation_speed")
    base_width = obs.obs_data_get_int(settings, "base_width")
    base_height = obs.obs_data_get_int(settings, "base_height")
end

-- ── Registrar hotkey e timer ───────────────────────────────────
function script_load(settings)
    local hotkey_id = obs.obs_hotkey_register_frontend("zoom_follow_toggle",
        "Zoom & Follow: Toggle", toggle_zoom)

    local hotkey_save_array = obs.obs_data_get_array(settings, "zoom_follow_toggle")
    obs.obs_hotkey_load(hotkey_id, hotkey_save_array)
    obs.obs_data_array_release(hotkey_save_array)

    -- Timer a ~60fps
    obs.timer_add(tick, 16)
    timer_active = true
end

function script_save(settings)
    -- Hotkeys são salvas automaticamente pelo OBS
end

function script_unload()
    if timer_active then
        obs.timer_remove(tick)
        timer_active = false
    end
end
