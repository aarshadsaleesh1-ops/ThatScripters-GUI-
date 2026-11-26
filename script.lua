-- ================================================
-- ThatScripters GUI (3 Tabs: Features | Saved | Executor)
-- Mobile + PC
-- Place in: StarterPlayer > StarterPlayerScripts
-- ================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- ================================================
-- CHARACTER HANDLING
-- ================================================
local character, humanoid, rootPart

local function setupCharacter(char)
    character = char
    humanoid = char:WaitForChild("Humanoid")
    rootPart = char:WaitForChild("HumanoidRootPart")
    if flying then startFlying() end
    if noclip then setNoclip(true) end
end

if player.Character then setupCharacter(player.Character) end
player.CharacterAdded:Connect(setupCharacter)

-- ================================================
-- STATE
-- ================================================
local flying = false
local noclip = false
local infiniteJump = false
local flyConnection, noclipConnection, jumpConnection, discoConnection
local flyBodyVelocity, flyBodyGyro
local flySpeed = 60
local defaultGravity = workspace.Gravity
local mobileMove = { forward=false, back=false, left=false, right=false, up=false, down=false }

-- ================================================
-- NOCLIP
-- ================================================
function setNoclip(state)
    noclip = state
    if noclipConnection then noclipConnection:Disconnect(); noclipConnection = nil end
    if noclip then
        noclipConnection = RunService.Stepped:Connect(function()
            if character then
                for _, part in ipairs(character:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
            end
        end)
    end
end

-- ================================================
-- INFINITE JUMP
-- ================================================
local function setInfiniteJump(state)
    infiniteJump = state
    if jumpConnection then jumpConnection:Disconnect(); jumpConnection = nil end
    if infiniteJump then
        jumpConnection = UserInputService.JumpRequest:Connect(function()
            if humanoid then humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end
        end)
    end
end

-- ================================================
-- FLY
-- ================================================
local function stopFlying()
    flying = false
    if flyConnection then flyConnection:Disconnect(); flyConnection = nil end
    if flyBodyVelocity then flyBodyVelocity:Destroy(); flyBodyVelocity = nil end
    if flyBodyGyro then flyBodyGyro:Destroy(); flyBodyGyro = nil end
    if humanoid then humanoid.PlatformStand = false end
    if flyMobileFrame then flyMobileFrame.Visible = false end
end

function startFlying()
    if not rootPart or not humanoid then return end
    flying = true
    if flyBodyVelocity then flyBodyVelocity:Destroy() end
    if flyBodyGyro then flyBodyGyro:Destroy() end

    flyBodyVelocity = Instance.new("BodyVelocity")
    flyBodyVelocity.MaxForce = Vector3.new(1e9,1e9,1e9)
    flyBodyVelocity.Velocity = Vector3.zero
    flyBodyVelocity.Parent = rootPart

    flyBodyGyro = Instance.new("BodyGyro")
    flyBodyGyro.MaxTorque = Vector3.new(1e9,1e9,1e9)
    flyBodyGyro.P = 1e4
    flyBodyGyro.Parent = rootPart

    humanoid.PlatformStand = true
    if flyMobileFrame then flyMobileFrame.Visible = true end

    flyConnection = RunService.RenderStepped:Connect(function()
        if not rootPart or not flyBodyVelocity then return end
        local cam = workspace.CurrentCamera
        local moveDir = Vector3.zero
        if UserInputService.KeyboardEnabled then
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir += cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir -= cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir -= cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir += cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir += Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir -= Vector3.new(0,1,0) end
        end
        if mobileMove.forward then moveDir += cam.CFrame.LookVector end
        if mobileMove.back then moveDir -= cam.CFrame.LookVector end
        if mobileMove.left then moveDir -= cam.CFrame.RightVector end
        if mobileMove.right then moveDir += cam.CFrame.RightVector end
        if mobileMove.up then moveDir += Vector3.new(0,1,0) end
        if mobileMove.down then moveDir -= Vector3.new(0,1,0) end
        flyBodyVelocity.Velocity = (moveDir.Magnitude > 0) and (moveDir.Unit * flySpeed) or Vector3.zero
        flyBodyGyro.CFrame = cam.CFrame
    end)
end

local function toggleFly() if flying then stopFlying() else startFlying() end end

-- ================================================
-- SPEED / GRAVITY / EFFECTS
-- ================================================
local function changeSpeed(a) if humanoid then humanoid.WalkSpeed = math.clamp(humanoid.WalkSpeed + a, 0, 500) end end
local function changeGravity(a) workspace.Gravity = math.clamp(workspace.Gravity + a, 0, 500) end
local function resetGravity() workspace.Gravity = defaultGravity end

local function disco()
    if discoConnection then
        discoConnection:Disconnect(); discoConnection = nil
        Lighting.Ambient = Color3.fromRGB(128,128,128)
        Lighting.OutdoorAmbient = Color3.fromRGB(128,128,128)
        Lighting.FogColor = Color3.fromRGB(192,192,192)
        return
    end
    discoConnection = RunService.RenderStepped:Connect(function()
        local hue = tick() % 1
        local color = Color3.fromHSV(hue, 1, 1)
        Lighting.Ambient = color; Lighting.OutdoorAmbient = color; Lighting.FogColor = color
        if character then
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then part.Color = Color3.fromHSV((hue+0.5)%1,1,1) end
            end
        end
    end)
end

local function fireAll()
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then
            for _, part in ipairs(p.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    local f = Instance.new("Fire"); f.Size=5; f.Heat=10; f.Parent=part
                end
            end
        end
    end
end

local function explodeAll()
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local ex = Instance.new("Explosion")
                ex.BlastRadius = 20; ex.BlastPressure = 500000
                ex.Position = hrp.Position; ex.Parent = workspace
            end
        end
    end
end

-- ================================================
-- SCRIPT SAVE / EXECUTE SYSTEM (Tab 2)
-- ================================================
local SCRIPT_STORAGE_KEY = "ThatScriptersSavedScripts"
local savedScripts = {}

local function loadSavedScripts()
    local raw = player:GetAttribute(SCRIPT_STORAGE_KEY)
    if raw and raw ~= "" then
        local ok, decoded = pcall(function() return HttpService:JSONDecode(raw) end)
        if ok and type(decoded) == "table" then savedScripts = decoded end
    end
end

local function saveSavedScripts()
    local ok, encoded = pcall(function() return HttpService:JSONEncode(savedScripts) end)
    if ok then player:SetAttribute(SCRIPT_STORAGE_KEY, encoded) end
end

local function executeScript(name)
    local code = savedScripts[name]
    if not code then return false, "Script not found" end
    local fn, err = loadstring(code)
    if not fn then return false, "Compile error: " .. tostring(err) end
    local ok, runErr = pcall(fn)
    if not ok then return false, "Runtime error: " .. tostring(runErr) end
    return true, "Executed: " .. name
end

-- ================================================
-- GUI BUILD
-- ================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ThatScriptersGUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = player:WaitForChild("PlayerGui")

local function corner(inst, r)
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 8); c.Parent = inst
    return c
end

local function makeButton(parent, text, callback, color, height)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, height or (isMobile and 44 or 36))
    btn.BackgroundColor3 = color or Color3.fromRGB(50, 50, 70)
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = isMobile and 15 or 14
    btn.Parent = parent
    corner(btn, 6)
    btn.MouseEnter:Connect(function() btn.BackgroundColor3 = Color3.fromRGB(80,80,120) end)
    btn.MouseLeave:Connect(function() btn.BackgroundColor3 = color or Color3.fromRGB(50,50,70) end)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- Main frame
local mainFrame = Instance.new("Frame")
mainFrame.Size = isMobile and UDim2.new(0, 260, 0, 400) or UDim2.new(0, 420, 0, 540)
mainFrame.Position = UDim2.new(0, 10, 0.5, isMobile and -200 or -270)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui
corner(mainFrame, 10)

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(80, 80, 255); stroke.Thickness = 2; stroke.Parent = mainFrame

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
title.BorderSizePixel = 0
title.Text = "⚡ ThatScripters GUI ⚡"
title.TextColor3 = Color3.fromRGB(255,255,255)
title.Font = Enum.Font.GothamBold
title.TextSize = 17
title.Parent = mainFrame
corner(title, 10)

-- Minimize
local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 30, 0, 30)
minBtn.Position = UDim2.new(1, -35, 0, 5)
minBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
minBtn.Text = "−"
minBtn.TextColor3 = Color3.fromRGB(255,255,255)
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 20
minBtn.BorderSizePixel = 0
minBtn.ZIndex = 5
minBtn.Parent = title
corner(minBtn, 6)

-- ================================================
-- TAB BAR (3 tabs, manual positioning)
-- ================================================
local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1, -10, 0, 32)
tabBar.Position = UDim2.new(0, 5, 0, 44)
tabBar.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
tabBar.BorderSizePixel = 0
tabBar.Parent = mainFrame
corner(tabBar, 6)

local function makeTab(text, xScale, xOffset)
    local t = Instance.new("TextButton")
    t.Size = UDim2.new(1/3, -2, 1, -4)
    t.Position = UDim2.new(xScale, xOffset, 0, 2)
    t.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
    t.BorderSizePixel = 0
    t.Text = text
    t.TextColor3 = Color3.fromRGB(255,255,255)
    t.Font = Enum.Font.GothamBold
    t.TextSize = isMobile and 11 or 12
    t.AutoButtonColor = true
    t.Parent = tabBar
    corner(t, 5)
    return t
end

local tab1Btn = makeTab("🎮 Features", 0, 0)
local tab2Btn = makeTab("📜 Saved", 1/3, 0)
local tab3Btn = makeTab("⚙ Exec", 2/3, 0)

-- ================================================
-- TAB 1: FEATURES
-- ================================================
local scroll1 = Instance.new("ScrollingFrame")
scroll1.Size = UDim2.new(1, -10, 1, -125)
scroll1.Position = UDim2.new(0, 5, 0, 82)
scroll1.BackgroundTransparency = 1
scroll1.BorderSizePixel = 0
scroll1.ScrollBarThickness = 6
scroll1.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll1.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll1.Parent = mainFrame

local layout1 = Instance.new("UIListLayout")
layout1.Padding = UDim.new(0, 6)
layout1.Parent = scroll1
layout1:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    scroll1.CanvasSize = UDim2.new(0, 0, 0, layout1.AbsoluteContentSize.Y + 10)
end)

makeButton(scroll1, "✈ Fly Toggle", toggleFly, Color3.fromRGB(0, 120, 200))
makeButton(scroll1, "👻 Noclip Toggle", function() setNoclip(not noclip) end, Color3.fromRGB(100, 0, 200))
makeButton(scroll1, "🦘 Infinite Jump Toggle", function() setInfiniteJump(not infiniteJump) end, Color3.fromRGB(0, 160, 100))
makeButton(scroll1, "⬇ Decrease Gravity", function() changeGravity(-50) end)
makeButton(scroll1, "⬆ Increase Gravity", function() changeGravity(50) end)
makeButton(scroll1, "🔄 Reset Gravity", resetGravity)
makeButton(scroll1, "🏃 Increase Speed", function() changeSpeed(10) end, Color3.fromRGB(200, 140, 0))
makeButton(scroll1, "🐢 Decrease Speed", function() changeSpeed(-10) end, Color3.fromRGB(200, 140, 0))
makeButton(scroll1, "🕺 Disco Effect", disco, Color3.fromRGB(255, 0, 150))
makeButton(scroll1, "🔥 Fire All", fireAll, Color3.fromRGB(200, 60, 0))
makeButton(scroll1, "💥 Explode All", explodeAll, Color3.fromRGB(200, 0, 0))

-- ================================================
-- TAB 2: SAVED SCRIPTS
-- ================================================
local tab2 = Instance.new("Frame")
tab2.Size = UDim2.new(1, -10, 1, -125)
tab2.Position = UDim2.new(0, 5, 0, 82)
tab2.BackgroundTransparency = 1
tab2.Visible = false
tab2.Parent = mainFrame

local nameBox = Instance.new("TextBox")
nameBox.Size = UDim2.new(1, 0, 0, isMobile and 32 or 28)
nameBox.Position = UDim2.new(0, 0, 0, 0)
nameBox.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
nameBox.BorderSizePixel = 0
nameBox.PlaceholderText = "Script name..."
nameBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 170)
nameBox.Text = ""
nameBox.TextColor3 = Color3.fromRGB(255,255,255)
nameBox.Font = Enum.Font.Code
nameBox.TextSize = isMobile and 13 or 12
nameBox.TextXAlignment = Enum.TextXAlignment.Left
nameBox.ClearTextOnFocus = false
nameBox.Parent = tab2
corner(nameBox, 6)

local codeBox = Instance.new("TextBox")
codeBox.Size = UDim2.new(1, 0, 0, isMobile and 110 or 160)
codeBox.Position = UDim2.new(0, 0, 0, isMobile and 38 or 34)
codeBox.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
codeBox.BorderSizePixel = 0
codeBox.PlaceholderText = "-- Write or paste Lua code here..."
codeBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 140)
codeBox.Text = ""
codeBox.TextColor3 = Color3.fromRGB(180, 255, 180)
codeBox.Font = Enum.Font.Code
codeBox.TextSize = 12
codeBox.TextXAlignment = Enum.TextXAlignment.Left
codeBox.TextYAlignment = Enum.TextYAlignment.Top
codeBox.MultiLine = true
codeBox.ClearTextOnFocus = false
codeBox.Parent = tab2
corner(codeBox, 6)

local saveBtn = Instance.new("TextButton")
saveBtn.Size = UDim2.new(0.5, -3, 0, isMobile and 34 or 30)
saveBtn.Position = UDim2.new(0, 0, 0, isMobile and 154 or 200)
saveBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 90)
saveBtn.BorderSizePixel = 0
saveBtn.Text = "💾 Save Script"
saveBtn.TextColor3 = Color3.fromRGB(255,255,255)
saveBtn.Font = Enum.Font.GothamBold
saveBtn.TextSize = isMobile and 13 or 12
saveBtn.Parent = tab2
corner(saveBtn, 6)

local clearBtn = Instance.new("TextButton")
clearBtn.Size = UDim2.new(0.5, -3, 0, isMobile and 34 or 30)
clearBtn.Position = UDim2.new(0.5, 3, 0, isMobile and 154 or 200)
clearBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
clearBtn.BorderSizePixel = 0
clearBtn.Text = "🗑 Clear Editor"
clearBtn.TextColor3 = Color3.fromRGB(255,255,255)
clearBtn.Font = Enum.Font.GothamBold
clearBtn.TextSize = isMobile and 13 or 12
clearBtn.Parent = tab2
corner(clearBtn, 6)

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, 0, 0, 20)
statusLabel.Position = UDim2.new(0, 0, 0, isMobile and 190 or 234)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Saved scripts: 0"
statusLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 11
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = tab2

local listFrame = Instance.new("ScrollingFrame")
listFrame.Size = UDim2.new(1, 0, 1, isMobile and -222 or -212)
listFrame.Position = UDim2.new(0, 0, 0, isMobile and 214 or 258)
listFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
listFrame.BorderSizePixel = 0
listFrame.ScrollBarThickness = 5
listFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
listFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
listFrame.Parent = tab2
corner(listFrame, 6)

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 4)
listLayout.Parent = listFrame
listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    listFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 8)
end)

local function refreshScriptList()
    for _, child in ipairs(listFrame:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    local count = 0
    for name, code in pairs(savedScripts) do
        count += 1
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -8, 0, isMobile and 40 or 34)
        row.BackgroundColor3 = Color3.fromRGB(35, 35, 48)
        row.BorderSizePixel = 0
        row.Parent = listFrame
        corner(row, 5)

        local nameLbl = Instance.new("TextLabel")
        nameLbl.Size = UDim2.new(1, -100, 1, 0)
        nameLbl.Position = UDim2.new(0, 6, 0, 0)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Text = "📜 " .. name
        nameLbl.TextColor3 = Color3.fromRGB(255,255,255)
        nameLbl.Font = Enum.Font.GothamSemibold
        nameLbl.TextSize = isMobile and 12 or 11
        nameLbl.TextXAlignment = Enum.TextXAlignment.Left
        nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
        nameLbl.Parent = row

        local runBtn = Instance.new("TextButton")
        runBtn.Size = UDim2.new(0, 40, 1, -6)
        runBtn.Position = UDim2.new(1, -84, 0, 3)
        runBtn.BackgroundColor3 = Color3.fromRGB(0, 160, 100)
        runBtn.Text = "▶"
        runBtn.TextColor3 = Color3.fromRGB(255,255,255)
        runBtn.Font = Enum.Font.GothamBold
        runBtn.TextSize = 14
        runBtn.BorderSizePixel = 0
        runBtn.Parent = row
        corner(runBtn, 4)

        local delBtn = Instance.new("TextButton")
        delBtn.Size = UDim2.new(0, 40, 1, -6)
        delBtn.Position = UDim2.new(1, -42, 0, 3)
        delBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
        delBtn.Text = "✕"
        delBtn.TextColor3 = Color3.fromRGB(255,255,255)
        delBtn.Font = Enum.Font.GothamBold
        delBtn.TextSize = 14
        delBtn.BorderSizePixel = 0
        delBtn.Parent = row
        corner(delBtn, 4)

        runBtn.MouseButton1Click:Connect(function()
            local ok, msg = executeScript(name)
            statusLabel.Text = msg
            statusLabel.TextColor3 = ok and Color3.fromRGB(100, 255, 150) or Color3.fromRGB(255, 100, 100)
            task.delay(3, function() statusLabel.Text = "Saved scripts: " .. count end)
        end)

        delBtn.MouseButton1Click:Connect(function()
            savedScripts[name] = nil
            saveSavedScripts()
            refreshScriptList()
        end)
    end
    statusLabel.Text = "Saved scripts: " .. count
    statusLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
end

saveBtn.MouseButton1Click:Connect(function()
    local name = nameBox.Text:gsub("^%s+", ""):gsub("%s+$", "")
    local code = codeBox.Text
    if name == "" then
        statusLabel.Text = "⚠ Enter a script name!"
        statusLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
        return
    end
    if code == "" then
        statusLabel.Text = "⚠ Editor is empty!"
        statusLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
        return
    end
    savedScripts[name] = code
    saveSavedScripts()
    refreshScriptList()
    statusLabel.Text = "✅ Saved: " .. name
    statusLabel.TextColor3 = Color3.fromRGB(100, 255, 150)
end)

clearBtn.MouseButton1Click:Connect(function()
    codeBox.Text = ""
    nameBox.Text = ""
    statusLabel.Text = "Editor cleared"
    statusLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
end)

-- ================================================
-- TAB 3: LIVE CLIENT-SIDE EXECUTOR (NEW)
-- ================================================
local tab3 = Instance.new("Frame")
tab3.Size = UDim2.new(1, -10, 1, -125)
tab3.Position = UDim2.new(0, 5, 0, 82)
tab3.BackgroundTransparency = 1
tab3.Visible = false
tab3.Parent = mainFrame

-- Quick-run row
local quickBar = Instance.new("Frame")
quickBar.Size = UDim2.new(1, 0, 0, isMobile and 28 or 24)
quickBar.Position = UDim2.new(0, 0, 0, 0)
quickBar.BackgroundTransparency = 1
quickBar.Parent = tab3

local quickLayout = Instance.new("UIListLayout")
quickLayout.FillDirection = Enum.FillDirection.Horizontal
quickLayout.Padding = UDim.new(0, 4)
quickLayout.Parent = quickBar

local function quickChip(text, code)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, isMobile and 60 or 56, 1, -2)
    b.BackgroundColor3 = Color3.fromRGB(60, 60, 90)
    b.BorderSizePixel = 0
    b.Text = text
    b.TextColor3 = Color3.fromRGB(255,255,255)
    b.Font = Enum.Font.Gotham
    b.TextSize = isMobile and 10 or 9
    b.Parent = quickBar
    corner(b, 4)
    b.MouseButton1Click:Connect(function()
        execBox.Text = code
    end)
end

quickChip("Pos", "print(character.HumanoidRootPart.Position)")
quickChip("R6/R15", "print(humanoid.RigType)")
quickChip("Lighting", "print(Lighting.ClockTime, Lighting.Brightness)")
quickChip("Health", "print(humanoid.Health .. '/' .. humanoid.MaxHealth)")
quickChip("FPS", "local f=0; RunService.RenderStepped:Connect(function() f=f+1 end); task.wait(1); print('~'..f..' FPS')")

-- Executor code box
local execBox = Instance.new("TextBox")
execBox.Size = UDim2.new(1, 0, 0, isMobile and 110 or 170)
execBox.Position = UDim2.new(0, 0, 0, isMobile and 32 or 30)
execBox.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
execBox.BorderSizePixel = 0
execBox.PlaceholderText = "-- Type client-side Lua and press EXECUTE\n-- (has access to: game, workspace, player, character, humanoid, rootPart, Lighting, RunService, UserInputService)"
execBox.PlaceholderColor3 = Color3.fromRGB(110, 110, 130)
execBox.Text = ""
execBox.TextColor3 = Color3.fromRGB(200, 255, 200)
execBox.Font = Enum.Font.Code
execBox.TextSize = 12
execBox.TextXAlignment = Enum.TextXAlignment.Left
execBox.TextYAlignment = Enum.TextYAlignment.Top
execBox.MultiLine = true
execBox.ClearTextOnFocus = false
execBox.Parent = tab3
corner(execBox, 6)

-- Execute + Clear buttons
local execBtn = Instance.new("TextButton")
execBtn.Size = UDim2.new(0.62, -3, 0, isMobile and 36 or 32)
execBtn.Position = UDim2.new(0, 0, 0, isMobile and 148 or 206)
execBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 100)
execBtn.BorderSizePixel = 0
execBtn.Text = "▶ EXECUTE"
execBtn.TextColor3 = Color3.fromRGB(255,255,255)
execBtn.Font = Enum.Font.GothamBold
execBtn.TextSize = isMobile and 14 or 13
execBtn.Parent = tab3
corner(execBtn, 6)

local execClearBtn = Instance.new("TextButton")
execClearBtn.Size = UDim2.new(0.38, -3, 0, isMobile and 36 or 32)
execClearBtn.Position = UDim2.new(0.62, 3, 0, isMobile and 148 or 206)
execClearBtn.BackgroundColor3 = Color3.fromRGB(130, 60, 60)
execClearBtn.BorderSizePixel = 0
execClearBtn.Text = "Clear"
execClearBtn.TextColor3 = Color3.fromRGB(255,255,255)
execClearBtn.Font = Enum.Font.GothamBold
execClearBtn.TextSize = isMobile and 12 or 11
execClearBtn.Parent = tab3
corner(execClearBtn, 6)

-- Output console
local console = Instance.new("ScrollingFrame")
console.Size = UDim2.new(1, 0, 1, isMobile and -190 or -240)
console.Position = UDim2.new(0, 0, 0, isMobile and 190 or 244)
console.BackgroundColor3 = Color3.fromRGB(10, 10, 14)
console.BorderSizePixel = 0
console.ScrollBarThickness = 5
console.CanvasSize = UDim2.new(0, 0, 0, 0)
console.AutomaticCanvasSize = Enum.AutomaticSize.Y
console.Parent = tab3
corner(console, 6)

local consoleLayout = Instance.new("UIListLayout")
consoleLayout.Padding = UDim.new(0, 2)
consoleLayout.Parent = console
consoleLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    console.CanvasSize = UDim2.new(0, 0, 0, consoleLayout.AbsoluteContentSize.Y + 6)
end)

local consolePad = Instance.new("UIPadding")
consolePad.PaddingLeft = UDim.new(0, 6)
consolePad.PaddingRight = UDim.new(0, 6)
consolePad.PaddingTop = UDim.new(0, 4)
consolePad.Parent = console

local function log(text, color)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, 0, 0, 0)
    l.AutomaticSize = Enum.AutomaticSize.Y
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = color or Color3.fromRGB(200, 200, 200)
    l.Font = Enum.Font.Code
    l.TextSize = 11
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextWrapped = true
    l.Parent = console
    -- auto-scroll
    task.defer(function()
        console.CanvasPosition = Vector2.new(0, math.max(0, consoleLayout.AbsoluteContentSize.Y - console.AbsoluteSize.Y + 20))
    end)
end

-- Executor with captured environment
local function executeClient(code)
    if code:gsub("%s", "") == "" then
        log("[warn] Nothing to execute.", Color3.fromRGB(255, 220, 120))
        return
    end

    local env = setmetatable({
        game = game,
        workspace = workspace,
        player = player,
        character = character,
        humanoid = humanoid,
        rootPart = rootPart,
        camera = workspace.CurrentCamera,
        Lighting = Lighting,
        RunService = RunService,
        UserInputService = UserInputService,
        Players = Players,
        HttpService = HttpService,
        Instance = Instance,
        Vector3 = Vector3,
        Vector2 = Vector2,
        CFrame = CFrame,
        Color3 = Color3,
        UDim = UDim,
        UDim2 = UDim2,
        Enum = Enum,
        task = task,
        wait = task.wait,
        spawn = task.spawn,
        delay = task.delay,
        print = function(...)
            local parts = {}
            for i = 1, select("#", ...) do
                parts[#parts+1] = tostring(select(i, ...))
            end
            log("[print] " .. table.concat(parts, " "), Color3.fromRGB(160, 220, 255))
        end,
        warn = function(...)
            local parts = {}
            for i = 1, select("#", ...) do
                parts[#parts+1] = tostring(select(i, ...))
            end
            log("[warn] " .. table.concat(parts, " "), Color3.fromRGB(255, 210, 120))
        end,
        error = function(msg, level)
            log("[error] " .. tostring(msg), Color3.fromRGB(255, 110, 110))
            error(msg, level or 1)
        end,
    }, {__index = _G})

    local fn, err = loadstring(code)
    if not fn then
        log("[compile error] " .. tostring(err), Color3.fromRGB(255, 110, 110))
        return
    end

    setfenv(fn, env)
    log("[exec] Running...", Color3.fromRGB(180, 180, 200))

    local ok, runErr = pcall(fn)
    if ok then
        log("[ok] Finished.", Color3.fromRGB(110, 255, 150))
    else
        log("[runtime error] " .. tostring(runErr), Color3.fromRGB(255, 110, 110))
    end
end

execBtn.MouseButton1Click:Connect(function()
    executeClient(execBox.Text)
end)

execClearBtn.MouseButton1Click:Connect(function()
    execBox.Text = ""
    for _, c in ipairs(console:GetChildren()) do
        if c:IsA("TextLabel") then c:Destroy() end
    end
    log("[ready] Console cleared.", Color3.fromRGB(150, 220, 150))
end)

log("[ready] Client executor loaded.", Color3.fromRGB(150, 220, 150))

-- ================================================
-- TAB SWITCHING (3-way)
-- ================================================
local activeTab = 1
local function switchTab(n)
    activeTab = n
    scroll1.Visible = (n == 1)
    tab2.Visible    = (n == 2)
    tab3.Visible    = (n == 3)
    tab1Btn.BackgroundColor3 = (n == 1) and Color3.fromRGB(80, 80, 200) or Color3.fromRGB(50, 50, 70)
    tab2Btn.BackgroundColor3 = (n == 2) and Color3.fromRGB(80, 80, 200) or Color3.fromRGB(50, 50, 70)
    tab3Btn.BackgroundColor3 = (n == 3) and Color3.fromRGB(80, 80, 200) or Color3.fromRGB(50, 50, 70)
end
tab1Btn.MouseButton1Click:Connect(function() switchTab(1) end)
tab2Btn.MouseButton1Click:Connect(function() switchTab(2) end)
tab3Btn.MouseButton1Click:Connect(function() switchTab(3) end)
switchTab(1)

-- ================================================
-- MINIMIZE
-- ================================================
local minimized = false
minBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    scroll1.Visible = (not minimized) and (activeTab == 1)
    tab2.Visible    = (not minimized) and (activeTab == 2)
    tab3.Visible    = (not minimized) and (activeTab == 3)
    tabBar.Visible = not minimized
    mainFrame.Size = minimized and UDim2.new(0, 260, 0, 40)
        or (isMobile and UDim2.new(0, 260, 0, 400) or UDim2.new(0, 420, 0, 540))
    minBtn.Text = minimized and "+" or "−"
end)

-- ================================================
-- MOBILE FLY D-PAD
-- ================================================
local flyMobileFrame
if isMobile then
    flyMobileFrame = Instance.new("Frame")
    flyMobileFrame.Size = UDim2.new(0, 180, 0, 180)
    flyMobileFrame.Position = UDim2.new(1, -200, 1, -210)
    flyMobileFrame.BackgroundTransparency = 1
    flyMobileFrame.Visible = false
    flyMobileFrame.Parent = screenGui

    local function mkDPad(text, pos, key)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, 55, 0, 55)
        b.Position = pos
        b.BackgroundColor3 = Color3.fromRGB(50, 50, 90)
        b.BackgroundTransparency = 0.3
        b.Text = text
        b.TextColor3 = Color3.fromRGB(255,255,255)
        b.Font = Enum.Font.GothamBold
        b.TextSize = 18
        b.BorderSizePixel = 0
        b.Parent = flyMobileFrame
        local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1, 0); c.Parent = b
        b.MouseButton1Down:Connect(function() mobileMove[key] = true end)
        b.MouseButton1Up:Connect(function() mobileMove[key] = false end)
        b.MouseLeave:Connect(function() mobileMove[key] = false end)
    end

    mkDPad("▲", UDim2.new(0, 62, 0, 0), "forward")
    mkDPad("▼", UDim2.new(0, 62, 0, 124), "back")
    mkDPad("◀", UDim2.new(0, 0, 0, 62), "left")
    mkDPad("▶", UDim2.new(0, 124, 0, 62), "right")
    mkDPad("⤒", UDim2.new(0, 62, 0, 62), "up")
    mkDPad("⤓", UDim2.new(0, 124, 0, 124), "down")
end

-- ================================================
-- PC KEYBINDS
-- ================================================
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.F then toggleFly()
    elseif input.KeyCode == Enum.KeyCode.N then setNoclip(not noclip)
    end
end)

-- ================================================
-- LOAD SAVED SCRIPTS
-- ================================================
loadSavedScripts()
refreshScriptList()

print("[ThatScripters GUI] Loaded | Mobile:", isMobile, "| Tabs: 3")