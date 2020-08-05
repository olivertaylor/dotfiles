--[[ NOTE:

This is a scratchpad with which I am learning hammerspoon.
Not all the code here actually works.

]]

-- [ Keyboard Navigation, NOT EMACS ----------------------------------------------------

-- This code binds a series of keys when the frontmost application is NOT emacs.
-- It does this by watching the frontmost application and enabling/disabling
-- a series of bindings called noEmacsKeys
-- https://github.com/Hammerspoon/hammerspoon/issues/2081#issuecomment-668283868

-- This creates a modal hotkey object that can be turned on/on
-- by the application watcher.
-- Since you won't ever be triggering the model hotkey directly
-- set the hotkey to something that won't cause a conflict.
noEmacsKeys = hs.hotkey.modal.new({"cmd", "shift", "alt"}, "F19")
-- Now that the modal hotkey is created, you can attach the bindings
-- you'd like to activate in that 'mode'.
noEmacsKeys:bind({'ctrl'}, ',', keyStrike({'alt'}, 'left'))
noEmacsKeys:bind({'ctrl'}, '.', keyStrike({'alt'}, 'right'))
noEmacsKeys:bind({'ctrl'}, "'", keyStrike({'alt'}, 'forwarddelete'))
noEmacsKeys:bind({'ctrl'}, ';', keyStrike({'alt'}, 'delete'))
noEmacsKeeys:bind({'ctrl'}, 'u', keyStrike({'cmd'}, 'delete'))

-- Create an application watcher that deactivates the noEmacsKeys bindings
-- when an app whose name is Emacs activates.
function applicationWatcherCallback(appName, eventType, appObject)
  if (appName == "Emacs") then
    if (eventType == hs.application.watcher.activated) then
      -- Emacs just got focus, disable our hotkeys
      noEmacsKeys:exit()
    elseif (eventType == hs.application.watcher.deactivated) then
      -- Emacs just lost focus, enable our hotkeys
      noEmacsKeys:enter()
    end
  end
end

-- Create and start the application event watcher
watcher = hs.application.watcher.new(applicationWatcherCallback)
watcher:start()

-- Activate the modal state by default
noEmacsKeys:enter()

-- [ Learning! ]-------------------------------------------------------------

hs.hotkey.bind({'cmd', 'ctrl'}, '1', function() hs.alert.show("alert") end)

hs.hotkey.bind({'cmd', 'ctrl'}, '2', function() hs.alert.show("down") end, function() hs.alert.show("up") end)

function oliverDown()
   hs.alert.show("down")
end
function oliverUp()
   hs.alert.show("up")
end

hs.hotkey.bind({'cmd', 'ctrl'}, '3', oliverDown, oliverUp)

function spaceDown()
   hs.alert.show("down")
   hs.eventtap.event.newKeyEvent(hs.keycodes.map.ctrl, true):post()
   hs.eventtap.event.newKeyEvent('e', true):post()
   hs.eventtap.event.newKeyEvent(hs.keycodes.map.ctrl, false):post()
end
function spaceUp()
   hs.eventtap.keyStroke({}, 'return', 0)
end

hs.hotkey.bind({'cmd', 'ctrl'}, '4', spaceDown, spaceUp)

-- [ Mode Test ] ---------------------------------------------------

function modeTestStart()
   hs.alert.show("Mode Entered")
   testModal:enter()
end
function modeTestEnd()
   hs.alert.show("Mode Exited")
   testModal:exit()
end

testModal = hs.hotkey.modal.new({'cmd', 'ctrl', 'alt'}, 'F18')
testModal:bind({''}, 'e', keyStrike({'ctrl'}, 'e'))
hs.hotkey.bind({'cmd', 'ctrl'}, '2', modeTestStart, modeTestEnd)

-- [ Application Watcher ] -------------------------------------------------------------

emacsGroup = hs.hotkey.modal.new({'cmd'}, 'f19')
emacsGroup:bind({'cmd', 'ctrl'}, '1', hs.alert.show('Emacs is active!'))

function activeAppWatcher(appName, eventType, appObject)
  if (appName == "Emacs") then
    if (eventType == hs.application.watcher.activated) then
      emacsGroup:exit()
    elseif (eventType == hs.application.watcher.deactivated) then
      emacsGroup:enter()
    end
  end
end

hs.application.watcher.new(activeAppWatcher):start()

-- Toggle Application
-- -------------------------------------------

mash = {'cmd', 'alt', 'ctrl'}

local function toggleApplication(name)
  local app = hs.application.find(name)
  if not app or app:isHidden() then
    hs.application.launchOrFocus(name)
  elseif hs.application.frontmostApplication() ~= app then
    app:activate()
  else
    app:hide()
  end
end

hs.hotkey.bind(mash, "c", function() toggleApplication("Google Chrome") end)
hs.hotkey.bind(mash, "d", function() toggleApplication("Dash") end)
hs.hotkey.bind(mash, "f", function() toggleApplication("Finder") end)
hs.hotkey.bind(mash, "g", function() toggleApplication("SourceTree") end)
hs.hotkey.bind(mash, "m", function() toggleApplication("Mail") end)
hs.hotkey.bind(mash, "p", function() toggleApplication("System Preferences") end)
hs.hotkey.bind(mash, "s", function() toggleApplication("Spotify") end)
hs.hotkey.bind(mash, "t", function() toggleApplication("Terminal") end)
