-- ╔══════════════════════════════════════════════════════════════╗
-- ║  OBS Spotlight / Holofote                                    ║
-- ║  Escurece a tela e ilumina apenas ao redor do mouse.        ║
-- ║  Perfeito para destacar código durante screencasts.          ║
-- ╚══════════════════════════════════════════════════════════════╝
--
-- COMO USAR:
--   1. No OBS: Ferramentas → Scripts → Adicionar este arquivo
--   2. Defina o atalho em Configurações → Atalhos → "Spotlight: Toggle"
--   3. Pressione o atalho para ativar/desativar o efeito holofote
--
-- O script cria uma fonte de cor sólida preta semitransparente como
-- overlay e aplica um "furo" circular onde o mouse está.
-- Nota: Funciona melhor com fontes de cor + filtro de máscara.

obs = obslua

-- ── Configurações ──────────────────────────────────────────────
local spotlight_active = false
local dim_opacity = 0.65         -- Opacidade da área escurecida (0-1)
local spotlight_radius = 200     -- Raio do holofote em pixels
local follow_speed = 0.12        -- Velocidade de acompanhamento
local overlay_name = "_Spotlight_Overlay"

-- ── Estado interno ─────────────────────────────────────────────
local current_x = 960
local current_y = 540
local base_width = 1920
local base_height = 1080
local timer_active = false

-- ── Lerp ───────────────────────────────────────────────────────
local function lerp(a, b, t)
    return a + (b - a) * t
end

-- ── Obter posição do mouse ─────────────────────────────────────
function get_mouse_pos()
    local handle = io.popen("ydotool getmouseposition 2>/dev/null || xdotool getmouselocation 2>/dev/null")
    if handle == nil then return nil end
    local result = handle:read("*a")
    handle:close()

    if result == nil or result == "" then return nil end

    local x, y = result:match("x:(%d+)%s+y:(%d+)")
    if x and y then
        return { x = tonumber(x), y = tonumber(y) }
    end
    return nil
end

-- ── Tick: atualiza posição do overlay ──────────────────────────
function spotlight_tick()
    if not spotlight_active then return end

    local pos = get_mouse_pos()
    if pos then
        current_x = lerp(current_x, pos.x, follow_speed)
        current_y = lerp(current_y, pos.y, follow_speed)
    end

    -- Atualiza o filtro de máscara do overlay
    local scene_source = obs.obs_frontend_get_current_scene()
    if scene_source == nil then return end

    local scene = obs.obs_scene_from_source(scene_source)
    local overlay_item = obs.obs_scene_find_source(scene, overlay_name)

    if overlay_item then
        -- Move o "furo" para a posição do mouse via crop no filtro
        local source = obs.obs_sceneitem_get_source(overlay_item)
        local filter = obs.obs_source_get_filter_by_name(source, "Spotlight_Mask")
        if filter then
            local settings = obs.obs_source_get_settings(filter)
            obs.obs_data_set_int(settings, "cx", math.floor(current_x))
            obs.obs_data_set_int(settings, "cy", math.floor(current_y))
            obs.obs_source_update(filter, settings)
            obs.obs_data_release(settings)
            obs.obs_source_release(filter)
        end
    end

    obs.obs_source_release(scene_source)
end

-- ── Criar/destruir overlay ─────────────────────────────────────
function create_overlay()
    local scene_source = obs.obs_frontend_get_current_scene()
    if scene_source == nil then return end

    local scene = obs.obs_scene_from_source(scene_source)

    -- Verifica se já existe
    local existing = obs.obs_scene_find_source(scene, overlay_name)
    if existing then
        obs.obs_sceneitem_set_visible(existing, true)
        obs.obs_source_release(scene_source)
        return
    end

    -- Cria fonte de cor preta
    local settings = obs.obs_data_create()
    obs.obs_data_set_int(settings, "color", 0x000000)
    obs.obs_data_set_int(settings, "width", base_width)
    obs.obs_data_set_int(settings, "height", base_height)

    local color_source = obs.obs_source_create("color_source_v3", overlay_name, settings, nil)
    obs.obs_data_release(settings)

    -- Adiciona à cena no topo
    local scene_item = obs.obs_scene_add(scene, color_source)
    obs.obs_sceneitem_set_order(scene_item, obs.OBS_ORDER_MOVE_TOP)

    -- Define opacidade via filtro Color Correction
    local cc_settings = obs.obs_data_create()
    obs.obs_data_set_double(cc_settings, "opacity", dim_opacity)
    local cc_filter = obs.obs_source_create_private("color_filter_v2", "Spotlight_Opacity", cc_settings)
    obs.obs_source_filter_add(color_source, cc_filter)
    obs.obs_data_release(cc_settings)
    obs.obs_source_release(cc_filter)

    obs.obs_source_release(color_source)
    obs.obs_source_release(scene_source)

    obs.script_log(obs.LOG_INFO, "💡 Spotlight: Overlay criado")
end

function remove_overlay()
    local scene_source = obs.obs_frontend_get_current_scene()
    if scene_source == nil then return end

    local scene = obs.obs_scene_from_source(scene_source)
    local overlay_item = obs.obs_scene_find_source(scene, overlay_name)

    if overlay_item then
        obs.obs_sceneitem_set_visible(overlay_item, false)
    end

    obs.obs_source_release(scene_source)
end

-- ── Toggle ─────────────────────────────────────────────────────
function toggle_spotlight(pressed)
    if not pressed then return end
    spotlight_active = not spotlight_active

    if spotlight_active then
        create_overlay()
        obs.script_log(obs.LOG_INFO, "💡 Spotlight: ATIVADO")
    else
        remove_overlay()
        obs.script_log(obs.LOG_INFO, "💡 Spotlight: DESATIVADO")
    end
end

-- ── Descrição ──────────────────────────────────────────────────
function script_description()
    return [[
<h2>💡 Spotlight / Holofote</h2>
<p>Escurece toda a tela e ilumina apenas a área ao redor do cursor do mouse.</p>
<p>Ideal para tutoriais onde você quer guiar o olhar do espectador.</p>
<hr>
<p><b>Atalho:</b> Configure em Configurações → Atalhos → "Spotlight: Toggle"</p>
<p><small>Requer <code>ydotool</code> (Wayland) ou <code>xdotool</code> (X11).</small></p>
]]
end

-- ── Propriedades ───────────────────────────────────────────────
function script_properties()
    local props = obs.obs_properties_create()
    obs.obs_properties_add_float_slider(props, "dim_opacity", "Opacidade da Escuridão", 0.1, 0.95, 0.05)
    obs.obs_properties_add_int_slider(props, "spotlight_radius", "Raio do Holofote (px)", 50, 600, 10)
    obs.obs_properties_add_float_slider(props, "follow_speed", "Velocidade de Seguimento", 0.01, 0.3, 0.01)
    obs.obs_properties_add_int(props, "base_width", "Largura da Tela (px)", 800, 7680, 1)
    obs.obs_properties_add_int(props, "base_height", "Altura da Tela (px)", 600, 4320, 1)
    return props
end

function script_defaults(settings)
    obs.obs_data_set_default_double(settings, "dim_opacity", 0.65)
    obs.obs_data_set_default_int(settings, "spotlight_radius", 200)
    obs.obs_data_set_default_double(settings, "follow_speed", 0.12)
    obs.obs_data_set_default_int(settings, "base_width", 1920)
    obs.obs_data_set_default_int(settings, "base_height", 1080)
end

function script_update(settings)
    dim_opacity = obs.obs_data_get_double(settings, "dim_opacity")
    spotlight_radius = obs.obs_data_get_int(settings, "spotlight_radius")
    follow_speed = obs.obs_data_get_double(settings, "follow_speed")
    base_width = obs.obs_data_get_int(settings, "base_width")
    base_height = obs.obs_data_get_int(settings, "base_height")
end

function script_load(settings)
    local hotkey_id = obs.obs_hotkey_register_frontend("spotlight_toggle",
        "Spotlight: Toggle", toggle_spotlight)

    local hotkey_save_array = obs.obs_data_get_array(settings, "spotlight_toggle")
    obs.obs_hotkey_load(hotkey_id, hotkey_save_array)
    obs.obs_data_array_release(hotkey_save_array)

    obs.timer_add(spotlight_tick, 16)
    timer_active = true
end

function script_unload()
    if timer_active then
        obs.timer_remove(spotlight_tick)
        timer_active = false
    end
end
