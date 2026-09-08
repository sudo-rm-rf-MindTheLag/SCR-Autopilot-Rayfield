-- SCR Autopilot v2 - Rayfield Gen 2 Fixed
-- Original Script by PlaceReporter99
-- UI Rework by MindTheLag
-- Autopilot logic preserved from the original script.

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/gen2"))()

local Window = Rayfield:CreateWindow({
    name = "SCR Autopilot v2",
    subtitle = "Original by PlaceReporter99 | Reworked by MindTheLag",
    sidebarLayout = true,
    configuration = {
        autoSave = false,
        autoLoad = false,
        fileName = "SCR Autopilot v3"
    }
})

Window:CreateSection({ name = "Autopilot" })
local MainTab = Window:CreateTab({ name = "Main", icon = 4483362458 })
local AutoGuardTab = Window:CreateTab({ name = "Auto Guard", icon = 4483362458 })

Window:CreateSection({ name = "Configuration" })
local SettingsTab = Window:CreateTab({ name = "Settings", icon = 4483362458 })

Window:CreateSection({ name = "Information" })
local StatsTab = Window:CreateTab({ name = "Live Stats", icon = 4483362458 })
local RoutesTab = Window:CreateTab({ name = "Supported Routes", icon = 4483362458 })

local isEnabled = false
local cs
local nl
local autoNextLegEnabled = false
local autoDriveInitialized = false
local autoDriveRunning = false
local autoDriveState
local startAutoDrive
local stopAutoDrive
local autoGuardEnabled = false
local autoGuardRunning = false
local autoGuardToggleRef
local autopilotToggleRef

local function setToggleOff(toggleRef)
    if not toggleRef then return end
    pcall(function() toggleRef:Set(false) end)
    pcall(function() toggleRef:SetValue(false) end)
end

-- Tunable autopilot settings
local MAXSPEED = 75
local OBEYSPEEDLIMIT = true
local SAFESTOPSPEED = 30
local YELLOWSIGNALSPEED = 45
local SAFESTOPDISTANCE = 0.2
local BUFFERSTOP = 100
local BRAKEDELAY = 0

local function refreshAutoDriveFromSettings()
    if not autoDriveRunning or not autoDriveState or not autoDriveState.handlers or not autoDriveState.handlers.b then
        return
    end
    pcall(autoDriveState.handlers.b)
end

local function findDriveGui(playerGui)
    local direct = playerGui:FindFirstChild("DriveGui")
    if direct then return direct end

    local deep = playerGui:FindFirstChild("DriveGui", true)
    if deep then return deep end

    for _, gui in ipairs(playerGui:GetDescendants()) do
        if gui:IsA("ScreenGui") and string.find(string.lower(gui.Name), "drive") and gui:FindFirstChild("Cluster", true) then
            return gui
        end
    end
    return nil
end

-- MAIN
MainTab:CreateSection({ name = "Autopilot" })

autopilotToggleRef = MainTab:CreateToggle({
    name = "Enable Autopilot",
    value = false,
    flag = "Toggle1",
    callback = function(Value)
        isEnabled = Value

        if Value then
            autoGuardEnabled = false
            setToggleOff(autoGuardToggleRef)

            local ok, startedOrErr = pcall(startAutoDrive)
            if not ok then
                warn("Autopilot start failed:", startedOrErr)
                isEnabled = false
                if stopAutoDrive then stopAutoDrive() end
            elseif not startedOrErr then
                warn("Autopilot could not start yet. Enter a train cab first.")
                isEnabled = false
                if stopAutoDrive then stopAutoDrive() end
            end
        else
            if stopAutoDrive then stopAutoDrive() end
        end
    end
})

local function clickNextLeg()
    if not nl then return end
    if not nl.Visible or not nl.Active then return end

    if firesignal and nl.MouseButton1Click then
        pcall(function()
            firesignal(nl.MouseButton1Click)
        end)
        return
    end

    pcall(function()
        nl:Activate()
    end)
end

MainTab:CreateToggle({
    name = "Auto Next Leg",
    value = false,
    flag = "AutoNextLegToggle",
    callback = function(Value)
        autoNextLegEnabled = Value
        if not Value then return end

        task.spawn(function()
            while autoNextLegEnabled do
                clickNextLeg()
                task.wait(1.5)
            end
        end)
    end
})

-- AUTO GUARD
AutoGuardTab:CreateSection({ name = "Auto Guard" })
AutoGuardTab:CreateText({
    name = "Info",
    text = "Automatically presses E, T, Y, Q and R."
})

autoGuardToggleRef = AutoGuardTab:CreateToggle({
    name = "Enable Auto Guard",
    value = false,
    flag = "AutoGuardToggle",
    callback = function(Value)
        autoGuardEnabled = Value

        if Value then
            isEnabled = false
            if stopAutoDrive then stopAutoDrive() end
            setToggleOff(autopilotToggleRef)
        end

        if autoGuardEnabled and autoGuardRunning then return end

        if autoGuardEnabled then
            autoGuardRunning = true

            task.spawn(function()
                local guardVim = game:GetService("VirtualInputManager")

                local guardInput = {
                    press = function(key)
                        guardVim:SendKeyEvent(true, key, false, nil)
                        task.wait(0.005)
                        guardVim:SendKeyEvent(false, key, false, nil)
                    end
                }

                while autoGuardEnabled do
                    guardInput.press(Enum.KeyCode.E)
                    task.wait(0.1)
                    guardInput.press(Enum.KeyCode.T)
                    task.wait(0.1)
                    guardInput.press(Enum.KeyCode.Y)
                    task.wait(0.1)
                    guardInput.press(Enum.KeyCode.Q)
                    task.wait(0.1)
                    guardInput.press(Enum.KeyCode.R)
                    task.wait(0.1)
                end

                autoGuardRunning = false
            end)
        end
    end
})

-- SETTINGS
SettingsTab:CreateSection({ name = "Speed" })

SettingsTab:CreateSlider({
    name = "Max Speed",
    range = {0, 120},
    increment = 1,
    suffix = "mph",
    value = MAXSPEED,
    flag = "SETTINGS_MAXSPEED_V4",
    callback = function(Value)
        MAXSPEED = Value
        refreshAutoDriveFromSettings()
    end
})

SettingsTab:CreateSlider({
    name = "Safe Stop Speed",
    range = {0, 80},
    increment = 1,
    suffix = "mph",
    value = SAFESTOPSPEED,
    flag = "SETTINGS_SAFESTOPSPEED_V4",
    callback = function(Value)
        SAFESTOPSPEED = Value
        refreshAutoDriveFromSettings()
    end
})

SettingsTab:CreateSlider({
    name = "Yellow Signal Speed",
    range = {0, 80},
    increment = 1,
    suffix = "mph",
    value = YELLOWSIGNALSPEED,
    flag = "SETTINGS_YELLOWSIGNALSPEED_V4",
    callback = function(Value)
        YELLOWSIGNALSPEED = Value
        refreshAutoDriveFromSettings()
    end
})

SettingsTab:CreateSection({ name = "Stopping" })

SettingsTab:CreateSlider({
    name = "Safe Stop Distance",
    range = {0, 1},
    increment = 0.01,
    suffix = "mi",
    value = SAFESTOPDISTANCE,
    flag = "SETTINGS_SAFESTOPDISTANCE_V4",
    callback = function(Value)
        SAFESTOPDISTANCE = Value
        refreshAutoDriveFromSettings()
    end
})

SettingsTab:CreateSlider({
    name = "Buffer Stop Distance",
    range = {0, 300},
    increment = 1,
    suffix = "studs",
    value = BUFFERSTOP,
    flag = "SETTINGS_BUFFERSTOP_V4",
    callback = function(Value)
        BUFFERSTOP = Value
        refreshAutoDriveFromSettings()
    end
})

SettingsTab:CreateSlider({
    name = "Station Brake Delay",
    range = {0, 5},
    increment = 0.1,
    suffix = "s",
    value = BRAKEDELAY,
    flag = "SETTINGS_BRAKEDELAY_V1",
    callback = function(Value)
        BRAKEDELAY = Value
    end
})

SettingsTab:CreateText({
    name = "Brake Delay Info",
    text = "Wait time after entering the station zone before the final stop command is applied. Higher values may cause overshoots."
})

SettingsTab:CreateToggle({
    name = "Obey Speed Limit",
    value = OBEYSPEEDLIMIT,
    flag = "SETTINGS_OBEYSPEEDLIMIT_V4",
    callback = function(Value)
        OBEYSPEEDLIMIT = Value
        refreshAutoDriveFromSettings()
    end
})

-- LIVE STATS
StatsTab:CreateSection({ name = "Train" })

local statCurrentSpeed = StatsTab:CreateStat({
    name = "Current Speed",
    value = 0,
    suffix = "mph",
    numberEasing = false
})

local statSpeedLimit = StatsTab:CreateStat({
    name = "Speed Limit",
    value = 0,
    suffix = "mph",
    numberEasing = false
})

local statTargetSpeed = StatsTab:CreateStat({
    name = "Autopilot Target",
    value = 0,
    suffix = "mph",
    numberEasing = false
})

StatsTab:CreateSection({ name = "Route" })

local statNextStopDistance = StatsTab:CreateStat({
    name = "Next Stop Distance",
    value = 0,
    suffix = "mi",
    numberEasing = false
})

local statNextSignalDistance = StatsTab:CreateStat({
    name = "Next Signal Distance",
    value = 0,
    suffix = "mi",
    numberEasing = false
})

local statSignalCode = StatsTab:CreateStat({
    name = "Next Signal Code",
    value = 4,
    numberEasing = false
})

local statsNextStopText = StatsTab:CreateText({
    name = "Next Stop",
    text = "Waiting for train data..."
})

local statsSignalText = StatsTab:CreateText({
    name = "Signal Status",
    text = "Unknown"
})

StatsTab:CreateText({
    name = "Signal Legend",
    text = "0 Proceed | 1 Precaution | 2 Caution | 3 Danger | 4 Unknown"
})

local function setLiveText(handle, title, content)
    if not handle then return end

    pcall(function()
        handle:Set({ name = title, text = content })
    end)

    pcall(function()
        handle:Set(content)
    end)
end

local function parseFirstNumber(text, fallback)
    if typeof(text) ~= "string" then
        return fallback or 0
    end

    local number = text:match("[-+]?%d*%.?%d+")
    return tonumber(number) or fallback or 0
end

local function findCurrentSpeedValue(drive)
    local candidates = {
        drive.Cluster.Stats.CurrentState:FindFirstChild("Speed"),
        drive.Cluster.Stats.CurrentState:FindFirstChild("CurrentSpeed"),
        drive.Cluster.Spedometer:FindFirstChild("Speed"),
        drive.Cluster.Spedometer:FindFirstChild("CurrentSpeed")
    }

    for _, obj in ipairs(candidates) do
        if obj and obj:IsA("TextLabel") then
            return parseFirstNumber(obj.Text, 0)
        end
    end

    local currentState = drive.Cluster.Stats:FindFirstChild("CurrentState")
    if currentState then
        for _, obj in ipairs(currentState:GetDescendants()) do
            if obj:IsA("TextLabel") then
                local lowered = string.lower(obj.Name)
                if lowered:find("speed") and not lowered:find("limit") then
                    return parseFirstNumber(obj.Text, 0)
                end
            end
        end
    end

    return 0
end

local function signalCodeToText(code)
    if code == 0 then return "Proceed" end
    if code == 1 then return "Precaution" end
    if code == 2 then return "Caution" end
    if code == 3 then return "Danger" end
    return "Unknown"
end

local function updateLiveStats()
    local state = autoDriveState

    if not state or not state.refs then
        pcall(function() statTargetSpeed:Set(0) end)
        return
    end

    local refs = state.refs
    local live = state.live

    pcall(function()
        statCurrentSpeed:Set(findCurrentSpeedValue(refs.drive))
    end)

    pcall(function()
        statSpeedLimit:Set(parseFirstNumber(refs.speedl.Text, 0))
    end)

    pcall(function()
        statNextStopDistance:Set(parseFirstNumber(refs.d.Text, 0))
    end)

    pcall(function()
        statNextSignalDistance:Set(parseFirstNumber(refs.signald.Text, 0))
    end)

    if live then
        pcall(function()
            statTargetSpeed:Set(live.targetSpeed or 0)
        end)

        pcall(function()
            statSignalCode:Set(live.signalCode or 4)
        end)

        setLiveText(statsNextStopText, "Next Stop", live.nextStop or "Unknown")
        setLiveText(statsSignalText, "Signal Status", signalCodeToText(live.signalCode or 4))
    end
end

task.spawn(function()
    while task.wait(0.25) do
        updateLiveStats()
    end
end)

-- SUPPORTED ROUTES
RoutesTab:CreateSection({ name = "Metro" })
RoutesTab:CreateText({ name = "R002", text = "Stepford Central → Port Benton" })
RoutesTab:CreateText({ name = "R047", text = "St Helens Bridge → Port Benton" })
RoutesTab:CreateText({ name = "R132", text = "Stepford Central → Barton, clockwise" })
RoutesTab:CreateText({ name = "R134", text = "St Helens Bridge → Barton, clockwise" })

RoutesTab:CreateSection({ name = "Connect" })
RoutesTab:CreateText({ name = "R039", text = "Benton → Leighton City" })
RoutesTab:CreateText({ name = "R004", text = "St Helens Bridge → Edgemead" })

RoutesTab:CreateSection({ name = "Waterline" })
RoutesTab:CreateText({ name = "R018", text = "Newry Harbour → Farleigh" })

RoutesTab:CreateSection({ name = "Express" })
RoutesTab:CreateText({ name = "R086", text = "Newry → Leighton City" })
RoutesTab:CreateText({ name = "Warning", text = "Eden Quay has short platforms, so your train may overshoot." })

RoutesTab:CreateSection({ name = "Airlink" })
RoutesTab:CreateText({ name = "Supported Routes", text = "None." })

-- ORIGINAL AUTOPILOT BACKEND STARTS HERE

local function disconnectAutoDriveConnections()
    if not autoDriveState or not autoDriveState.connections then
        return
    end

    for _, connection in pairs(autoDriveState.connections) do
        if connection then
            connection:Disconnect()
        end
    end

    autoDriveState.connections = {}
end

startAutoDrive = function()
    if autoDriveRunning then
        return true
    end

    if not autoDriveInitialized then
        print("AUTO DRIVE")

        local state = { connections = {}, live = { targetSpeed = 0, signalCode = 4, nextStop = "Unknown" } }
        local player = game.Players.LocalPlayer

        if not player then
            warn("Autopilot: LocalPlayer not found")
            return false
        end

        local playerGui = player:FindFirstChild("PlayerGui")

        if not playerGui then
            warn("Autopilot: PlayerGui not found")
            return false
        end

        local drive = findDriveGui(playerGui)

        if not drive then
            task.wait(2)
            drive = findDriveGui(playerGui)
        end

        if not drive then
            warn("Autopilot: DriveGui not found. Join and take control of a train first.")
            return false
        end

        state.cs = Instance.new("BindableEvent")
        state.cs.Name = "ChangeSpeed"
        cs = state.cs

        local okBuf, bufOrErr = pcall(function()
            return loadstring(game:HttpGet("https://raw.githubusercontent.com/PlaceReporter99/SCR-Autopilot/refs/heads/main/const/RouteBuffers.lua"))()
        end)

        if not okBuf then
            warn("Autopilot: failed to load route buffers:", tostring(bufOrErr))
            return false
        end

        state.buf = bufOrErr

        signalv = {
            ["proceed"] = 0,
            ["precaution"] = 1,
            ["caution"] = 2,
            ["danger"] = 3,
            ["unknown"] = 4
        }

        local fex = Instance.new("BindableEvent")
        fex.Name = "ExecuteFunction"
        fex.Event:Connect(function(f)
            f()
        end)

        local vim = game:GetService("VirtualInputManager")

        input = {
            hold = function(key, time)
                print("Holding key", key)
                vim:SendKeyEvent(true, key, false, nil)
                task.wait(time)
                vim:SendKeyEvent(false, key, false, nil)
                print("Finished holding key", key)
            end,

            press = function(key)
                print("Pressing key", key)
                vim:SendKeyEvent(true, key, false, nil)
                task.wait(0.005)
                vim:SendKeyEvent(false, key, false, nil)
            end,

            start = function(key)
                print("starting key", key)
                vim:SendKeyEvent(true, key, false, nil)
            end,

            stop = function(key)
                print("stopping key", key)
                vim:SendKeyEvent(false, key, false, nil)
            end
        }

        -- ORIGINAL REFERENCES
        local schd = drive.Additional.DetailsStack.AdvanceContainer.Main.ScheduleDetails
        local left = schd.Counters
        local cluster = drive.Cluster
        local arm = cluster.Spedometer.TargetIndicator
        local d = left.Distance
        local msg = drive.Additional.DetailsStack.MessageContainer
        local signal = drive.Additional.DetailsStack.AdvanceContainer.Signal.Standard
        local signald = drive.Additional.DetailsStack.AdvanceContainer.Signal.Distance
        local speedl = drive.Cluster.Stats.CurrentState.SpeedLimit.Limit
        nl = drive.Summary.SummaryPage.Controls.NextLeg

        state.live.nextStop = schd.NextStop.Text

        local function getD(v)
            return (workspace.CurrentCamera.Focus.Position - v).Magnitude
        end

        local function getSpeedLimit()
            if OBEYSPEEDLIMIT then
                return tonumber(speedl.Text) or 1000
            end
            return 1000
        end

        local function getSignal()
            local result = signalv.unknown

            if signal.Danger.BackgroundTransparency == 0 then
                result = signalv.danger
            elseif signal.Precaution.BackgroundTransparency == 0 then
                result = signalv.precaution
            elseif signal.Caution.BackgroundTransparency == 0 then
                result = signalv.caution
            elseif signal.Proceed.BackgroundTransparency == 0 then
                result = signalv.proceed
            end

            state.live.signalCode = result
            return result
        end

        local function getSignalDistance()
            return tonumber(signald.Text:sub(1, -4)) or math.huge
        end

        speed_angle = function(speed)
            return speed * 1.2 - 31
        end

        -- EXACT ORIGINAL TARGET LOGIC
        function target(speed)
            state.live.targetSpeed = speed or 0
            local tt = false

            local stopr = cs.Event:Connect(function()
                tt = true
            end)

            input.stop(Enum.KeyCode.W)
            input.stop(Enum.KeyCode.S)

            if -1.8 <= speed_angle(speed) - arm.Rotation and speed_angle(speed) - arm.Rotation <= 1.8 then
                -- already near target speed
            elseif speed_angle(speed) < arm.Rotation then
                input.start(Enum.KeyCode.S)

                while speed_angle(speed) < arm.Rotation or tt do
                    task.wait(0.005)
                end

                input.stop(Enum.KeyCode.S)

            elseif speed_angle(speed) > arm.Rotation then
                input.start(Enum.KeyCode.W)

                while speed_angle(speed) > arm.Rotation or tt do
                    task.wait(0.005)
                end

                input.stop(Enum.KeyCode.W)
            end

            stopr:Disconnect()
        end

        -- EXACT ORIGINAL CLOCK HANDLER
        local function onClockTick()
            input.press(Enum.KeyCode.T)
            input.press(Enum.KeyCode.Q)

            local dist = tonumber(d.Text:sub(1, -4))

            if not dist then
                return
            end

            if arm.Rotation <= speed_angle(10)
                and dist ~= 0
                and (getSignal() ~= signalv.danger or getSignalDistance() > dist)
            then
                task.wait(10)

                local distAfterWait = tonumber(d.Text:sub(1, -4))

                if not distAfterWait then
                    return
                end

                if arm.Rotation <= speed_angle(10)
                    and distAfterWait ~= 0
                    and (getSignal() ~= signalv.danger or getSignalDistance() > distAfterWait)
                then
                    cs:Fire(SAFESTOPSPEED)
                end
            end
        end

        -- EXACT ORIGINAL SPEED HANDLER
        local function b()
            local num = tonumber(d.Text:sub(1, -4))
            state.live.nextStop = schd.NextStop.Text

            if num and num > 0 then
                state.stationBrakeDelayApplied = false
            end

            if not num then
                return
            end

            if num == 0 or (getSignal() == signalv.danger and num >= getSignalDistance()) then
                if num == 0 then
                    local plat = string.gsub(schd.Platform.Text, "Platform ", "")
                    local st = schd.NextStop.Text

                    if state.buf[st] and state.buf[st][plat] then
                        while getD(state.buf[st][plat]) >= BUFFERSTOP and autoDriveRunning do
                            cs:Fire(15)
                            task.wait(0.1)
                        end
                    end
                end

                if num == 0 and BRAKEDELAY > 0 and not state.stationBrakeDelayApplied then
                    state.stationBrakeDelayApplied = true
                    task.wait(BRAKEDELAY)
                end

                cs:Fire(0)

            elseif num <= SAFESTOPDISTANCE then
                cs:Fire(math.min(SAFESTOPSPEED, getSpeedLimit()))

            elseif getSignal() == signalv.caution then
                cs:Fire(math.min(YELLOWSIGNALSPEED, getSpeedLimit()))

            elseif num > SAFESTOPDISTANCE
                and (getSignal() == signalv.precaution or getSignal() == signalv.proceed)
            then
                cs:Fire(math.min(MAXSPEED, getSpeedLimit()))
            end
        end

        -- EXACT ORIGINAL MESSAGE HANDLER
        local function under(child)
            if child.Name == "DriveMessage"
                and (string.match(child.TextLabel.Text, "longside")
                or string.match(child.TextLabel.Text, "uffer"))
            then
                cs:Fire(5)
                task.wait(3)
                cs:Fire(0)
            end
        end

        state.refs = {
            drive = drive,
            d = d,
            signald = signald,
            speedl = speedl,
            msg = msg,
            schd = schd,
            signal = signal
        }

        state.handlers = {
            onClockTick = onClockTick,
            b = b,
            under = under
        }

        state.getSpeedLimit = getSpeedLimit

        cs.Event:Connect(function(a)
            target(a)
        end)

        autoDriveState = state
        autoDriveInitialized = true
    end

    autoDriveRunning = true
    disconnectAutoDriveConnections()

    local refs = autoDriveState.refs
    local handlers = autoDriveState.handlers

    autoDriveState.connections.clock =
        refs.drive.Clock.TextLabel:GetPropertyChangedSignal("Text"):Connect(handlers.onClockTick)

    autoDriveState.connections.distance =
        refs.d:GetPropertyChangedSignal("Text"):Connect(handlers.b)

    autoDriveState.connections.signalDistance =
        refs.signald:GetPropertyChangedSignal("Text"):Connect(handlers.b)

    autoDriveState.connections.speedLimit =
        refs.speedl:GetPropertyChangedSignal("Text"):Connect(handlers.b)

    autoDriveState.connections.msg =
        refs.msg.ChildAdded:Connect(handlers.under)

    autoDriveState.handlers.b()

    if cs and autoDriveState.getSpeedLimit then
        cs:Fire(math.min(MAXSPEED, autoDriveState.getSpeedLimit()))
    end

    return true
end

stopAutoDrive = function()
    autoDriveRunning = false
    disconnectAutoDriveConnections()

    if cs then
        cs:Fire(0)
    end
end
