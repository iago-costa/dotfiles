import XMonad
import XMonad.Config.Xfce
import XMonad.Hooks.EwmhDesktops
import XMonad.Hooks.SetWMName
import XMonad.Layout.ToggleLayouts
import XMonad.Util.EZConfig (additionalKeys, additionalKeysP)
import XMonad.Util.Run (spawnPipe)
import XMonad.Hooks.ManageDocks
import qualified XMonad.Layout.Grid as Grid
import qualified XMonad.StackSet as W
import qualified Data.Map as M
import XMonad.Layout.Spacing (spacing)
import XMonad.Actions.CycleWS (nextWS, prevWS)

-- The main function.
main = 
  do
    xmproc <- spawnPipe "/run/current-system/sw/bin/xmobar"
    xmonad myConfig 

myConfig = xfceConfig
    { terminal = "alacritty"
    , modMask = mod4Mask -- Use Win as MOD key
    , startupHook = ewmhDesktopsStartup >> setWMName "LG3D"
    , workspaces = myWorkspaces
    , logHook = myLogHook
    -- , layoutHook = avoidStruts $ toggleLayouts Full (Tall 1 (3/100) (1/2))
    , layoutHook = avoidStruts $ toggleLayouts Full (spacing 10 $ Tall 1 (3/100) (1/2))
    , mouseBindings = myMouseBindings
    } `additionalKeys` myKeys `additionalKeysP` myKeysP

-- Key bindings
myKeys = [
    -- ((mod4Mask, xK_d), spawn "Thunar")
    ]

myKeysP = [    
    ("M-x w", spawn "xmessage 'woohoo!'")
    -- key to toggle full view layout for active window
    , ("M-f", sendMessage (Toggle "Full"))
    , ("M-d", spawn "xfce4-appfinder")
    ]

myMouseBindings (XConfig {XMonad.modMask = modm}) = M.fromList $
    [ ((modm, button1), (\w -> focus w >> mouseMoveWindow w >> windows W.shiftMaster))
    , ((modm, button2), (\w -> focus w >> windows W.shiftMaster))
    , ((modm, button3), (\w -> focus w >> mouseResizeWindow w >> windows W.shiftMaster))
    , ((modm, button4), (\_ -> prevWS))
    , ((modm, button5), (\_ -> nextWS))
    ]

myWorkspaces = ["1", "2", "3", "4", "5", "6", "7", "8", "9"]
 
-- get the current workspace
myLogWorkpace = do
    ws <- gets windowset
    let tag = W.currentTag ws
    io $ writeFile "/tmp/.xmonad-workspace"
        ("Work=" ++ tag)
    return ()

-- get number of active windows and send to logHook
myLogActiveWindows = do
    n <- gets $ Just . length . W.index . windowset
    io $ writeFile "/tmp/.xmonad-active-windows" -- with legend "Active Windows: " ++ show n
        (case n of
            Just n' -> "WNum=" ++ show n'
            Nothing -> "0")
    return ()

-- get the name of the active window
myActiveWindowName = do
    n <- gets $ Just . W.current . windowset
    io $ writeFile "/tmp/.xmonad-active-window-name"
        (case n of
            Just n' -> "Win=" ++ show n'
            Nothing -> "0")
    return ()

myLogHook = myLogWorkpace >> myLogActiveWindows >> myActiveWindowName


