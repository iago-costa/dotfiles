import XMonad
import XMonad.Config.Xfce
import XMonad.Hooks.EwmhDesktops
import XMonad.Hooks.SetWMName
import XMonad.Layout.ToggleLayouts
import XMonad.Util.EZConfig (additionalKeys)

import qualified XMonad.StackSet as W

-- The main function.
main = xmonad myConfig 


myConfig = xfceConfig
    { terminal = "alacritty"
    , modMask = mod4Mask -- Use Win as MOD key
    , startupHook = ewmhDesktopsStartup >> setWMName "LG3D" -- for some reason the double greater sign is escaped here due to wiki formatting, replace this with proper greater signs!
    -- , keys = myKeys
    , workspaces = myWorkspaces
    , logHook = myLogHook
    } `additionalKeys` myKeys


-- Key bindings
myKeys = [
    -- keys to handle brightness and volume
    ((mod4Mask, xK_F3), spawn "amixer -q set Master toggle")
    , ((mod4Mask, xK_F5), spawn "amixer -q set Master 2%-")
    , ((mod4Mask, xK_F6), spawn "amixer -q set Master 2%+")
    -- , ((modm, xK_F8), spawn "xbacklight -dec 10")
    -- , ((modm, xK_F9), spawn "xbacklight -inc 10")
    -- key to toggle full view layout for active window
    , ((mod4Mask, xK_f), sendMessage (Toggle "Full"))
    -- , ((mod4Mask, xK_f), spawn "firefox")
    ]

myWorkspaces = ["1:main", "2:web", "3:code", "4:chat", "5:media", "6:other", "7:other", "8:other", "9:other"]
 

-- get the current workspace using the command xprop -root | grep _NET_CURRENT_DESKTOP
-- then send in logHook
myLogWorkpace = do
    ws <- gets windowset
    let tag = W.currentTag ws
    io $ writeFile "/tmp/.xmonad-workspace"
        ("WS=" ++ tag)
    return ()

-- get number of active windows and send to logHook
myLogActiveWindows = do
    n <- gets $ Just . length . W.index . windowset
    io $ writeFile "/tmp/.xmonad-active-windows" -- with legend "Active Windows: " ++ show n
        (case n of
            Just n' -> "AWs=" ++ show n'
            Nothing -> "0")
    return ()

myLogHook = myLogWorkpace >> myLogActiveWindows


