-- SCR Autopilot v2
-- Original Script by PlaceReporter99
-- UI Rework by MindTheLag
-- Rayfield Gen2 UI Rewrite

local Rayfield = loadstring(
    game:HttpGet("https://sirius.menu/gen2")
)()

--==================================================
-- WINDOW
--==================================================

local Window = Rayfield:CreateWindow({
    name = "SCR Autopilot v2",
    subtitle = "Original by PlaceReporter99 | Reworked by MindTheLag",
    sidebarLayout = true,

    configuration = {
        autoSave = false,
        autoLoad = false,
        fileName = "SCRAutopilot"
    }
})

--==================================================
-- STATE
--==================================================

local isEnabled = false
local autoNextLegEnabled = false

local autoDriveInitialized = false
local autoDriveRunning = false
local autoDriveState = nil

local autoGuardEnabled = false
local autoGuardRunning = false

local cs = nil
local nl = nil

local startAutoDrive
local stopAutoDrive

--==================================================
-- SETTINGS
--==================================================

local MAXSPEED = 75
local OBEYSPEEDLIMIT = true
local SAFESTOPSPEED = 30
local YELLOWSIGNALSPEED = 45
local SAFESTOPDISTANCE = 0.2
local BUFFERSTOP = 100

--==================================================
-- TABS
--==================================================

Window:CreateSection({
    name = "Autopilot"
})

local MainTab = Window:CreateTab({
    name = "Main",
    icon = 0
})

local AutoGuardTab = Window:CreateTab({
    name = "Auto Guard",
    icon = 0
})

Window:CreateSection({
    name = "Configuration"
})

local SettingsTab = Window:CreateTab({
    name = "Settings",
    icon = 0
})

Window:CreateSection({
    name = "Information"
})

local RoutesTab = Window:CreateTab({
    name = "Supported Routes",
    icon = 0
})

--==================================================
-- SUPPORTED ROUTES TAB
--==================================================

RoutesTab:CreateSection({
    name = "Metro"
})

RoutesTab:CreateText({
    name = "R002",
    text = "Stepford Central → Port Benton"
})

RoutesTab:CreateText({
    name = "R047",
    text = "St Helens Bridge → Port Benton"
})

RoutesTab:CreateText({
    name = "R132",
    text = "Stepford Central → Barton, clockwise"
})

RoutesTab:CreateText({
    name = "R134",
    text = "St Helens Bridge → Barton, clockwise"
})

RoutesTab:CreateSection({
    name = "Connect"
})

RoutesTab:CreateText({
    name = "R039",
    text = "Benton → Leighton City"
})

RoutesTab:CreateText({
    name = "R004",
    text = "St Helens Bridge → Edgemead"
})

RoutesTab:CreateSection({
    name = "Waterline"
})

RoutesTab:CreateText({
    name = "R018",
    text = "Newry Harbour → Farleigh"
})

RoutesTab:CreateSection({
    name = "Express"
})

RoutesTab:CreateText({
    name = "R086",
    text = "Newry → Leighton City"
})

RoutesTab:CreateText({
    name = "Warning",
    text = "Eden Quay has short platforms, so trains may overshoot."
})

RoutesTab:CreateSection({
    name = "Airlink"
})

RoutesTab:CreateText({
    name = "Airlink",
    text = "No supported routes."
})

--==================================================
-- HELPERS
--==================================================

local function setWindowValue(flag, value)
    pcall(function()
        Window:Set(flag, value)
    end)
end

local function refreshAutoDriveFromSettings()
    if not autoDriveRunning then
        return
    end

    if not autoDriveState then
        return
    end

    if not autoDriveState.handlers then
        return
    end

    if autoDriveState.handlers.updateSpeed then
        pcall(autoDriveState.handlers.updateSpeed)
    end
end

local function findDriveGui(playerGui)
    local direct = playerGui:FindFirstChild("DriveGui")

    if direct then
        return direct
    end

    local deep = playerGui:FindFirstChild("DriveGui", true)

    if deep then
        return deep
    end

    for _, gui in ipairs(playerGui:GetDescendants()) do
        if gui:IsA("ScreenGui")
            and string.find(string.lower(gui.Name), "drive")
            and gui:FindFirstChild("Cluster", true)
        then
            return gui
        end
    end

    return nil
end

local function disconnectAutoDriveConnections()
    if not autoDriveState then
        return
    end

    if not autoDriveState.connections then
        return
    end

    for _, connection in pairs(autoDriveState.connections) do
        if connection then
            pcall(function()
                connection:Disconnect()
            end)
        end
    end

    autoDriveState.connections = {}
end

--==================================================
-- MAIN TAB
--==================================================

MainTab:CreateSection({
    name = "Autopilot"
})

MainTab:CreateToggle({
    name = "Enable Autopilot",
    value = false,
    flag = "AutopilotEnabled",

    callback = function(value)
        isEnabled = value

        if value then
            autoGuardEnabled = false
            setWindowValue("AutoGuardEnabled", false)

            local success, result = pcall(function()
                return startAutoDrive()
            end)

            if not success or not result then
                warn("Autopilot failed:", result)
                isEnabled = false

                if stopAutoDrive then
                    stopAutoDrive()
                end

                setWindowValue("AutopilotEnabled", false)
            end
        else
            if stopAutoDrive then
                stopAutoDrive()
            end
        end
    end
})

--==================================================
-- AUTO NEXT LEG
--==================================================

local function clickNextLeg()
    if not nl then
        return
    end

    if not nl.Visible then
        return
    end

    if not nl.Active then
        return
    end

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
    flag = "AutoNextLegEnabled",

    callback = function(value)
        autoNextLegEnabled = value

        if not value then
            return
        end

        task.spawn(function()
            while autoNextLegEnabled do
                clickNextLeg()
                task.wait(1.5)
            end
        end)
    end
})

--==================================================
-- AUTO GUARD TAB
--==================================================

AutoGuardTab:CreateSection({
    name = "Auto Guard"
})

AutoGuardTab:CreateText({
    name = "Info",
    text = "Automatically presses E, T, Y, Q and R."
})

AutoGuardTab:CreateToggle({
    name = "Enable Auto Guard",
    value = false,
    flag = "AutoGuardEnabled",

    callback = function(value)
        autoGuardEnabled = value

        if value then
            isEnabled = false

            if stopAutoDrive then
                stopAutoDrive()
            end

            setWindowValue("AutopilotEnabled", false)
        end

        if autoGuardEnabled and autoGuardRunning then
            return
        end

        if not autoGuardEnabled then
            return
        end

        autoGuardRunning = true

        task.spawn(function()
            local vim = game:GetService("VirtualInputManager")

            local function press(key)
                vim:SendKeyEvent(true, key, false, nil)
                task.wait(0.005)
                vim:SendKeyEvent(false, key, false, nil)
            end

            while autoGuardEnabled do
                press(Enum.KeyCode.E)
                task.wait(0.1)

                press(Enum.KeyCode.T)
                task.wait(0.1)

                press(Enum.KeyCode.Y)
                task.wait(0.1)

                press(Enum.KeyCode.Q)
                task.wait(0.1)

                press(Enum.KeyCode.R)
                task.wait(0.1)
            end

            autoGuardRunning = false
        end)
    end
})

--==================================================
-- SETTINGS TAB
--==================================================

SettingsTab:CreateSection({
    name = "Speed"
})

SettingsTab:CreateSlider({
    name = "Max Speed",
    range = {0, 120},
    increment = 1,
    suffix = " mph",
    value = MAXSPEED,
    flag = "MaxSpeed",

    callback = function(value)
        MAXSPEED = value
        refreshAutoDriveFromSettings()
    end
})

SettingsTab:CreateSlider({
    name = "Safe Stop Speed",
    range = {0, 80},
    increment = 1,
    suffix = " mph",
    value = SAFESTOPSPEED,
    flag = "SafeStopSpeed",

    callback = function(value)
        SAFESTOPSPEED = value
        refreshAutoDriveFromSettings()
    end
})

SettingsTab:CreateSlider({
    name = "Yellow Signal Speed",
    range = {0, 80},
    increment = 1,
    suffix = " mph",
    value = YELLOWSIGNALSPEED,
    flag = "YellowSignalSpeed",

    callback = function(value)
        YELLOWSIGNALSPEED = value
        refreshAutoDriveFromSettings()
    end
})

SettingsTab:CreateToggle({
    name = "Obey Speed Limit",
    value = OBEYSPEEDLIMIT,
    flag = "ObeySpeedLimit",

    callback = function(value)
        OBEYSPEEDLIMIT = value
        refreshAutoDriveFromSettings()
    end
})

SettingsTab:CreateSection({
    name = "Stopping"
})

SettingsTab:CreateSlider({
    name = "Safe Stop Distance",
    range = {0, 1},
    increment = 0.01,
    suffix = " mi",
    value = SAFESTOPDISTANCE,
    flag = "SafeStopDistance",

    callback = function(value)
        SAFESTOPDISTANCE = value
        refreshAutoDriveFromSettings()
    end
})

SettingsTab:CreateSlider({
    name = "Buffer Stop Distance",
    range = {0, 300},
    increment = 1,
    suffix = " studs",
    value = BUFFERSTOP,
    flag = "BufferStopDistance",

    callback = function(value)
        BUFFERSTOP = value
        refreshAutoDriveFromSettings()
    end
})

--==================================================
-- AUTOPILOT INITIALIZATION
--==================================================

startAutoDrive = function()
    if autoDriveRunning then
        return true
    end

    if not autoDriveInitialized then
        local state = {
            connections = {}
        }

        local player = game:GetService("Players").LocalPlayer

        if not player then
            warn("Autopilot: LocalPlayer not found")
            return false
        end

        local playerGui = player:FindFirstChildOfClass("PlayerGui")

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
            warn("Autopilot: DriveGui not found. Enter a train cab first.")
            return false
        end

        state.cs = Instance.new("BindableEvent")
        state.cs.Name = "ChangeSpeed"
        cs = state.cs

        local success, routeBuffers = pcall(function()
            return loadstring(
                game:HttpGet(
                    "https://raw.githubusercontent.com/PlaceReporter99/SCR-Autopilot/refs/heads/main/const/RouteBuffers.lua"
                )
            )()
        end)

        if not success then
            warn("Autopilot: Failed to load route buffers:", routeBuffers)
            return false
        end

        state.buf = routeBuffers

        local signalv = {
            proceed = 0,
            precaution = 1,
            caution = 2,
            danger = 3,
            unknown = 4
        }

        local vim = game:GetService("VirtualInputManager")
        local input = {}

        function input.press(key)
            vim:SendKeyEvent(true, key, false, nil)
            task.wait(0.005)
            vim:SendKeyEvent(false, key, false, nil)
        end

        function input.start(key)
            vim:SendKeyEvent(true, key, false, nil)
        end

        function input.stop(key)
            vim:SendKeyEvent(false, key, false, nil)
        end

        local schd =
            drive.Additional.DetailsStack.AdvanceContainer.Main.ScheduleDetails

        local cluster = drive.Cluster
        local arm = cluster.Spedometer.TargetIndicator
        local distance = schd.Counters.Distance

        local messageContainer =
            drive.Additional.DetailsStack.MessageContainer

        local signal =
            drive.Additional.DetailsStack.AdvanceContainer.Signal.Standard

        local signalDistance =
            drive.Additional.DetailsStack.AdvanceContainer.Signal.Distance

        local speedLimit =
            drive.Cluster.Stats.CurrentState.SpeedLimit.Limit

        nl =
            drive.Summary.SummaryPage.Controls.NextLeg

        local function getD(position)
            return (
                workspace.CurrentCamera.Focus.Position - position
            ).Magnitude
        end

        local function getSpeedLimit()
            if OBEYSPEEDLIMIT then
                return tonumber(speedLimit.Text) or 1000
            end

            return 1000
        end

        local function getSignal()
            if signal.Danger.BackgroundTransparency == 0 then
                return signalv.danger
            end

            if signal.Precaution.BackgroundTransparency == 0 then
                return signalv.precaution
            end

            if signal.Caution.BackgroundTransparency == 0 then
                return signalv.caution
            end

            if signal.Proceed.BackgroundTransparency == 0 then
                return signalv.proceed
            end

            return signalv.unknown
        end

        local function getSignalDistance()
            return tonumber(signalDistance.Text:sub(1, -4))
                or math.huge
        end

        local function speedAngle(speed)
            return speed * 1.2 - 31
        end

        local function target(speed)
            local interrupted = false

            local connection = cs.Event:Connect(function()
                interrupted = true
            end)

            input.stop(Enum.KeyCode.W)
            input.stop(Enum.KeyCode.S)

            local targetRotation = speedAngle(speed)

            if math.abs(targetRotation - arm.Rotation) <= 1.8 then
                -- Already near target speed

            elseif targetRotation < arm.Rotation then
                input.start(Enum.KeyCode.S)

                while targetRotation < arm.Rotation
                    and not interrupted
                    and autoDriveRunning
                do
                    task.wait(0.005)
                end

                input.stop(Enum.KeyCode.S)

            else
                input.start(Enum.KeyCode.W)

                while targetRotation > arm.Rotation
                    and not interrupted
                    and autoDriveRunning
                do
                    task.wait(0.005)
                end

                input.stop(Enum.KeyCode.W)
            end

            connection:Disconnect()
        end

        local function onClockTick()
            input.press(Enum.KeyCode.T)
            input.press(Enum.KeyCode.Q)

            local dist = tonumber(distance.Text:sub(1, -4))

            if not dist then
                return
            end

            if arm.Rotation <= speedAngle(10)
                and dist ~= 0
                and (
                    getSignal() ~= signalv.danger
                    or getSignalDistance() > dist
                )
            then
                task.wait(10)

                if not autoDriveRunning then
                    return
                end

                local newDist =
                    tonumber(distance.Text:sub(1, -4))

                if not newDist then
                    return
                end

                if arm.Rotation <= speedAngle(10)
                    and newDist ~= 0
                    and (
                        getSignal() ~= signalv.danger
                        or getSignalDistance() > newDist
                    )
                then
                    cs:Fire(SAFESTOPSPEED)
                end
            end
        end

        local function updateSpeed()
            local num =
                tonumber(distance.Text:sub(1, -4))

            if not num then
                return
            end

            if num == 0
                or (
                    getSignal() == signalv.danger
                    and num >= getSignalDistance()
                )
            then
                if num == 0 then
                    local platform =
                        string.gsub(
                            schd.Platform.Text,
                            "Platform ",
                            ""
                        )

                    local station =
                        schd.NextStop.Text

                    if state.buf[station]
                        and state.buf[station][platform]
                    then
                        while getD(
                            state.buf[station][platform]
                        ) >= BUFFERSTOP
                            and autoDriveRunning
                        do
                            cs:Fire(15)
                            task.wait(0.1)
                        end
                    end
                end

                cs:Fire(0)

            elseif num <= SAFESTOPDISTANCE then
                cs:Fire(
                    math.min(
                        SAFESTOPSPEED,
                        getSpeedLimit()
                    )
                )

            elseif getSignal() == signalv.caution then
                cs:Fire(
                    math.min(
                        YELLOWSIGNALSPEED,
                        getSpeedLimit()
                    )
                )

            elseif num > SAFESTOPDISTANCE
                and (
                    getSignal() == signalv.precaution
                    or getSignal() == signalv.proceed
                )
            then
                cs:Fire(
                    math.min(
                        MAXSPEED,
                        getSpeedLimit()
                    )
                )
            end
        end

        local function under(child)
            if child.Name ~= "DriveMessage" then
                return
            end

            local label =
                child:FindFirstChild("TextLabel")

            if not label then
                return
            end

            local text = label.Text

            if string.match(text, "longside")
                or string.match(text, "uffer")
            then
                cs:Fire(5)

                task.wait(3)

                if autoDriveRunning then
                    cs:Fire(0)
                end
            end
        end

        state.refs = {
            drive = drive,
            distance = distance,
            signalDistance = signalDistance,
            speedLimit = speedLimit,
            messageContainer = messageContainer
        }

        state.handlers = {
            onClockTick = onClockTick,
            updateSpeed = updateSpeed,
            under = under
        }

        state.getSpeedLimit = getSpeedLimit

        cs.Event:Connect(target)

        autoDriveState = state
        autoDriveInitialized = true
    end

    autoDriveRunning = true
    disconnectAutoDriveConnections()

    local refs = autoDriveState.refs
    local handlers = autoDriveState.handlers

    autoDriveState.connections.clock =
        refs.drive.Clock.TextLabel
        :GetPropertyChangedSignal("Text")
        :Connect(handlers.onClockTick)

    autoDriveState.connections.distance =
        refs.distance
        :GetPropertyChangedSignal("Text")
        :Connect(handlers.updateSpeed)

    autoDriveState.connections.signalDistance =
        refs.signalDistance
        :GetPropertyChangedSignal("Text")
        :Connect(handlers.updateSpeed)

    autoDriveState.connections.speedLimit =
        refs.speedLimit
        :GetPropertyChangedSignal("Text")
        :Connect(handlers.updateSpeed)

    autoDriveState.connections.message =
        refs.messageContainer.ChildAdded
        :Connect(handlers.under)

    handlers.updateSpeed()

    if cs and autoDriveState.getSpeedLimit then
        cs:Fire(
            math.min(
                MAXSPEED,
                autoDriveState.getSpeedLimit()
            )
        )
    end

    return true
end

--==================================================
-- STOP AUTOPILOT
--==================================================

stopAutoDrive = function()
    autoDriveRunning = false

    disconnectAutoDriveConnections()

    pcall(function()
        local vim =
            game:GetService("VirtualInputManager")

        vim:SendKeyEvent(
            false,
            Enum.KeyCode.W,
            false,
            nil
        )

        vim:SendKeyEvent(
            false,
            Enum.KeyCode.S,
            false,
            nil
        )
    end)

    if cs then
        cs:Fire(0)
    end
end

--==================================================
-- INITIAL TAB
--==================================================

Window:Navigate("Main")
