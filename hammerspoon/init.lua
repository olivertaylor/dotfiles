--[[ INFO ----------------------------------------

KeyCodes:
f1, f2, f3, f4, f5, f6, f7, f8, f9, f10, f11, f12, f13, f14, f15,
f16, f17, f18, f19, f20, pad, pad*, pad+, pad/, pad-, pad=,
pad0, pad1, pad2, pad3, pad4, pad5, pad6, pad7, pad8, pad9,
padclear, padenter, return, tab, space, delete, escape, help,
home, pageup, forwarddelete, end, pagedown, left, right, down, up,
shift, rightshift, cmd, rightcmd, alt, rightalt, ctrl, rightctrl,
capslock, fn

Inspiration:
- http://www.hammerspoon.org/Spoons/Seal.html
- https://medium.com/@robhowlett/hammerspoon-the-best-mac-software-youve-never-heard-of-40c2df6db0f8
- https://github.com/jasonrudolph/keyboard
- https://github.com/dbmrq/dotfiles
- https://github.com/raulchen/dotfiles
- https://github.com/justintanner/universal-emacs-keybindings

]] ---------------------------------------------------

hs.window.animationDuration = 0
local hyper = {"ctrl", "alt", "cmd"}

-- Spoons
-- -----------------------------------------------

-- Load SpoonInstall, so we can easily load our other Spoons
hs.loadSpoon("SpoonInstall")
spoon.SpoonInstall.use_syncinstall = true
Install=spoon.SpoonInstall

local anycomplete = require "anycomplete"
anycomplete.registerDefaultBindings()

-- Draw pretty rounded corners on all screens
Install:andUse("RoundedCorners", { start = true })


-- Misc Bindings
-- -----------------------------------------------

-- remap ; to f12
-- remap fn+; to ;
-- It is important that fn+; comes first

function remapF12()
   hs.eventtap.event.newKeyEvent({}, ';', true):post()
end
hs.hotkey.bind({'fn'}, ';', remapF12)

-- this must come second:
function sendF12()
   hs.eventtap.event.newKeyEvent({}, 'f12', true):post()
end
hs.hotkey.bind({}, ';', sendF12)

-- Window Control
-- -----------------------------------------------

function snap_window(dir)
   local thiswindow = hs.window.frontmostWindow()
   local loc = thiswindow:frame()
   
   local thisscreen = thiswindow:screen()
   local screenrect = thisscreen:frame()
   
   if dir == 'left' then
      loc.x = 0
   elseif dir == 'right' then
      loc.x = screenrect.w - loc.w
   elseif dir == 'up' then
      loc.y = 0
   elseif dir == 'down' then
      loc.y = screenrect.h - loc.h
   end
   thiswindow:setFrame(loc)
end

-- Move windows around the screen
hs.hotkey.bind(hyper, "[", function() snap_window('left') end)
hs.hotkey.bind(hyper, "]", function() snap_window('right') end)

-- Resize and Move Windows
hs.hotkey.bind(hyper, 'left', function() hs.window.focusedWindow():moveToUnit({0, 0, 1/2, 1}) end)
hs.hotkey.bind(hyper, 'right', function() hs.window.focusedWindow():moveToUnit({1/2, 0, 1/2, 1}) end)
hs.hotkey.bind(hyper, 'h', function() hs.window.focusedWindow():moveToUnit({0, 0, 1/3, 1}) end)
hs.hotkey.bind(hyper, 'j', function() hs.window.focusedWindow():moveToUnit({0, 0, 2/3, 1}) end)
hs.hotkey.bind(hyper, 'k', function() hs.window.focusedWindow():moveToUnit({1/3, 0, 2/3, 1}) end)
hs.hotkey.bind(hyper, 'l', function() hs.window.focusedWindow():moveToUnit({2/3, 0, 1/3, 1}) end)

-- window hints
hs.hotkey.bind(hyper, 'i', hs.hints.windowHints)

-- window grid
hs.grid.setGrid('6x4', nil, nil)
hs.grid.setMargins({0, 0})
hs.hotkey.bind(hyper, ';', hs.grid.show)


-- Reload Config
-- -----------------------------------------------

-- Notify when this file is loaded
hs.notify.new({title='Hammerspoon', informativeText='Ready to rock 🤘'}):send()

-- Create a binding for reloading the config
hs.hotkey.bind({'cmd', 'ctrl'}, 'r', function() hs.reload() end)

-- Automatically reload the config when anything in the hammerspoon dir changes
function reloadConfig(files)
   doReload = false
   for _,file in pairs(files) do
      if file:sub(-4) == ".lua" then
	 doReload = true
      end
   end
   if doReload then
      hs.reload()
   end
end
configWatcher = hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", reloadConfig):start()


-- Application Launcher
-- -----------------------------------------------

local applicationHotkeys = {
   -- don't use f (full-screen app)
   s = 'Safari',
   t = 'Terminal',
   a = 'Music',
   m = 'Mail',
   e = 'Emacs',
   b = 'BBEdit',
   o = 'Tot',
   k = 'Slack',
}

for key, app in pairs(applicationHotkeys) do
   hs.hotkey.bind({'ctrl', 'cmd'}, key, function()
	 hs.application.launchOrFocus(app)
   end)
end


-- Word Move/Delete
-- -----------------------------------------------

-- This, remember, is system-wide, so Terminal/Emacs will need to accept
-- alt+delete, cmd+delete, ctrl+alt+b, ctrl+alt+f, and alt+forwarddelete

function deleteWordBack()
   hs.eventtap.event.newKeyEvent(hs.keycodes.map.alt, true):post()
   hs.eventtap.event.newKeyEvent('delete', true):post()
   hs.eventtap.event.newKeyEvent(hs.keycodes.map.alt, false):post()
end
hs.hotkey.bind({'ctrl'}, 'w', deleteWordBack)
hs.hotkey.bind({'ctrl'}, ',', deleteWordBack)

function deleteWordForward()
   hs.eventtap.event.newKeyEvent(hs.keycodes.map.alt, true):post()
   hs.eventtap.event.newKeyEvent('forwarddelete', true):post()
   hs.eventtap.event.newKeyEvent(hs.keycodes.map.alt, false):post()
end
hs.hotkey.bind({'alt'}, 'd', deleteWordForward)
hs.hotkey.bind({'ctrl'}, '.', deleteWordForward)

function deleteLineBack()
   hs.eventtap.event.newKeyEvent(hs.keycodes.map.cmd, true):post()
   hs.eventtap.event.newKeyEvent('delete', true):post()
   hs.eventtap.event.newKeyEvent(hs.keycodes.map.cmd, false):post()
end
hs.hotkey.bind({'ctrl'}, 'u', deleteLineBack)

function moveWordBack()
   hs.eventtap.event.newKeyEvent(hs.keycodes.map.ctrl, true):post()
   hs.eventtap.event.newKeyEvent(hs.keycodes.map.alt, true):post()
   hs.eventtap.event.newKeyEvent('b', true):post()
   hs.eventtap.event.newKeyEvent(hs.keycodes.map.ctrl, false):post()
   hs.eventtap.event.newKeyEvent(hs.keycodes.map.alt, false):post()
end
hs.hotkey.bind({'ctrl'}, ';', moveWordBack)

function moveWordForward()
   hs.eventtap.event.newKeyEvent(hs.keycodes.map.ctrl, true):post()
   hs.eventtap.event.newKeyEvent(hs.keycodes.map.alt, true):post()
   hs.eventtap.event.newKeyEvent('f', true):post()
   hs.eventtap.event.newKeyEvent(hs.keycodes.map.ctrl, false):post()
   hs.eventtap.event.newKeyEvent(hs.keycodes.map.alt, false):post()
end
hs.hotkey.bind({'ctrl'}, "'", moveWordForward)


end


