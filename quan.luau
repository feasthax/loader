--[[
    QuantumLib — flat dark monospace UI library
    Scraped/extended from the quantum whitelist UI theme.

    Features:
        • Clean padding throughout
        • Topbar tabs
        • Square filled toggles (translucent fill + glow on enable, grey + no glow off)
        • Compact buttons
        • Square-handle sliders (smooth animation, counting value text)
        • Sections
        • Runtime theming — every element re-reads palette and updates instantly

    Usage:
        local Quantum = loadstring(...)()
        local win = Quantum:Window({ Title = "quantum", Size = Vector2.new(420, 360) })
        local tab = win:Tab("main")
        local sec = tab:Section("automation")
        sec:Button("run", function() end)
        sec:Toggle("auto collect", false, function(state) end)
        sec:Slider("speed", 0, 100, 50, function(v) end)
        win:Theme("blue")            -- swap accent palette, everything updates live
        win:SetAccent(Color3.fromRGB(94,207,138))  -- or custom accent
--]]

local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local CoreGui           = game:GetService("CoreGui")
local Players           = game:GetService("Players")

-- ── Palettes ───────────────────────────────────────────────────────────────────
-- Base flat-dark chrome is shared; only the accent (and its derived tints) varies.

local function derive(accent)
    return {
        bg          = Color3.fromRGB(26,  26,  26),
        bgPanel     = Color3.fromRGB(29,  29,  29),
        bgInput     = Color3.fromRGB(20,  20,  20),
        bgBtn       = Color3.fromRGB(37,  37,  37),
        bgBtnHover  = Color3.fromRGB(46,  46,  46),
        titleBar    = Color3.fromRGB(34,  34,  34),
        border      = Color3.fromRGB(56,  56,  56),
        track       = Color3.fromRGB(45,  45,  45),
        txtPrimary  = Color3.fromRGB(200, 200, 200),
        txtMuted    = Color3.fromRGB(136, 136, 136),
        txtDim      = Color3.fromRGB(85,  85,  85),
        accent      = accent,
        accentText  = accent,
        -- toggle-off neutral
        offFill     = Color3.fromRGB(60,  60,  60),
        offBorder   = Color3.fromRGB(70,  70,  70),
    }
end

local PALETTES = {
    blue   = derive(Color3.fromRGB(77,  159, 223)),
    green  = derive(Color3.fromRGB(94,  207, 138)),
    red    = derive(Color3.fromRGB(220, 80,  80)),
    yellow = derive(Color3.fromRGB(220, 180, 60)),
    purple = derive(Color3.fromRGB(168, 130, 232)),
    cyan   = derive(Color3.fromRGB(80,  200, 210)),
    orange = derive(Color3.fromRGB(232, 150, 80)),
    mono   = derive(Color3.fromRGB(200, 200, 200)),
}

-- ── Helpers ─────────────────────────────────────────────────────────────────────

local QuantumLib = {}
QuantumLib.__index = QuantumLib

local function stroke(parent, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color         = color or Color3.fromRGB(56, 56, 56)
    s.Thickness     = thickness or 1
    s.Transparency  = transparency or 0
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent        = parent
    return s
end

local function pad(parent, p)
    local u = Instance.new("UIPadding")
    u.PaddingTop    = UDim.new(0, p)
    u.PaddingBottom = UDim.new(0, p)
    u.PaddingLeft   = UDim.new(0, p)
    u.PaddingRight  = UDim.new(0, p)
    u.Parent        = parent
    return u
end

local function label(parent, text, size, color, x)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Text           = text
    l.TextSize       = size or 11
    l.TextColor3     = color or Color3.fromRGB(136, 136, 136)
    l.Font           = Enum.Font.Code
    l.TextXAlignment = x or Enum.TextXAlignment.Left
    l.TextYAlignment = Enum.TextYAlignment.Center
    l.BorderSizePixel = 0
    l.Parent         = parent
    return l
end

local TI_FAST = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TI_SMOOTH = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function tween(obj, props, info)
    local t = TweenService:Create(obj, info or TI_FAST, props)
    t:Play()
    return t
end

-- ── Window ───────────────────────────────────────────────────────────────────────

function QuantumLib:Window(opts)
    opts = opts or {}
    local self = setmetatable({}, QuantumLib)

    self.palette   = table.clone(PALETTES[opts.Theme or "blue"])
    self._themed   = {}   -- list of {inst, fn} repaint callbacks
    self.tabs      = {}
    self.activeTab = nil

    local size = opts.Size or Vector2.new(420, 360)
    local WIN_W, WIN_H = size.X, size.Y

    local existing = CoreGui:FindFirstChild("QuantumLibGUI")
    if existing then existing:Destroy() end

    local gui = Instance.new("ScreenGui")
    gui.Name            = "QuantumLibGUI"
    gui.ResetOnSpawn    = false
    gui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
    gui.Parent          = CoreGui
    self.gui = gui

    local window = Instance.new("Frame")
    window.Name             = "Window"
    window.Size             = UDim2.fromOffset(WIN_W, WIN_H)
    window.Position         = UDim2.new(0.5, -WIN_W/2, 0.5, -WIN_H/2)
    window.BackgroundColor3 = self.palette.bg
    window.BorderSizePixel  = 0
    window.Active           = true
    window.Parent           = gui
    self.window = window
    local winStroke = stroke(window, self.palette.border, 1)
    self:_register(window, function(p) window.BackgroundColor3 = p.bg; winStroke.Color = p.border end)

    -- Title bar
    local titleBar = Instance.new("Frame")
    titleBar.Size             = UDim2.new(1, 0, 0, 24)
    titleBar.BackgroundColor3 = self.palette.titleBar
    titleBar.BorderSizePixel  = 0
    titleBar.Parent           = window
    self:_register(titleBar, function(p) titleBar.BackgroundColor3 = p.titleBar end)

    local titleDiv = Instance.new("Frame")
    titleDiv.Size             = UDim2.new(1, 0, 0, 1)
    titleDiv.Position         = UDim2.new(0, 0, 1, -1)
    titleDiv.BackgroundColor3 = self.palette.border
    titleDiv.BorderSizePixel  = 0
    titleDiv.Parent           = titleBar
    self:_register(titleDiv, function(p) titleDiv.BackgroundColor3 = p.border end)

    local titleLbl = label(titleBar, opts.Title or "quantum", 11, self.palette.txtPrimary, Enum.TextXAlignment.Center)
    titleLbl.Size = UDim2.new(1, 0, 1, 0)
    self:_register(titleLbl, function(p) titleLbl.TextColor3 = p.txtPrimary end)

    -- Drag
    local dragging, dragStart, startPos
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging, dragStart, startPos = true, input.Position, window.Position
        end
    end)
    titleBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local d = input.Position - dragStart
            window.Position = UDim2.fromOffset(startPos.X.Offset + d.X, startPos.Y.Offset + d.Y)
        end
    end)

    -- Topbar (tab strip)
    local topbar = Instance.new("Frame")
    topbar.Size             = UDim2.new(1, 0, 0, 28)
    topbar.Position         = UDim2.fromOffset(0, 24)
    topbar.BackgroundColor3 = self.palette.bgPanel
    topbar.BorderSizePixel  = 0
    topbar.Parent           = window
    self:_register(topbar, function(p) topbar.BackgroundColor3 = p.bgPanel end)
    self.topbar = topbar

    local topDiv = Instance.new("Frame")
    topDiv.Size             = UDim2.new(1, 0, 0, 1)
    topDiv.Position         = UDim2.new(0, 0, 1, -1)
    topDiv.BackgroundColor3 = self.palette.border
    topDiv.BorderSizePixel  = 0
    topDiv.Parent           = topbar
    self:_register(topDiv, function(p) topDiv.BackgroundColor3 = p.border end)

    local tabList = Instance.new("UIListLayout")
    tabList.FillDirection = Enum.FillDirection.Horizontal
    tabList.SortOrder     = Enum.SortOrder.LayoutOrder
    tabList.Parent        = topbar

    -- Content holder (one page per tab)
    local content = Instance.new("Frame")
    content.Name             = "Content"
    content.Size             = UDim2.new(1, 0, 1, -52)
    content.Position         = UDim2.fromOffset(0, 52)
    content.BackgroundColor3 = self.palette.bgPanel
    content.BorderSizePixel  = 0
    content.Parent           = window
    self:_register(content, function(p) content.BackgroundColor3 = p.bgPanel end)
    self.content = content

    return self
end

-- repaint registry
function QuantumLib:_register(inst, fn)
    table.insert(self._themed, fn)
    fn(self.palette)
end

function QuantumLib:_repaint()
    for _, fn in ipairs(self._themed) do
        pcall(fn, self.palette)
    end
end

function QuantumLib:Theme(name)
    local p = PALETTES[name]
    if not p then return end
    self.palette = table.clone(p)
    self:_repaint()
end

function QuantumLib:SetAccent(color)
    self.palette.accent     = color
    self.palette.accentText = color
    self:_repaint()
end

-- ── Tab ────────────────────────────────────────────────────────────────────────

function QuantumLib:Tab(name)
    local win = self

    local btn = Instance.new("TextButton")
    btn.Size             = UDim2.fromOffset(0, 28)
    btn.AutomaticSize    = Enum.AutomaticSize.X
    btn.BackgroundColor3 = self.palette.bgPanel
    btn.BorderSizePixel  = 0
    btn.AutoButtonColor  = false
    btn.Text             = ""
    btn.Parent           = self.topbar

    local btnPad = Instance.new("UIPadding")
    btnPad.PaddingLeft  = UDim.new(0, 14)
    btnPad.PaddingRight = UDim.new(0, 14)
    btnPad.Parent       = btn

    local btnLbl = label(btn, name, 11, self.palette.txtMuted, Enum.TextXAlignment.Center)
    btnLbl.Size = UDim2.new(1, 0, 1, 0)

    -- active underline indicator
    local indicator = Instance.new("Frame")
    indicator.Size             = UDim2.new(1, 0, 0, 2)
    indicator.Position         = UDim2.new(0, 0, 1, -2)
    indicator.BackgroundColor3 = self.palette.accent
    indicator.BackgroundTransparency = 1
    indicator.BorderSizePixel  = 0
    indicator.Parent           = btn

    -- page
    local page = Instance.new("ScrollingFrame")
    page.Size                   = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel        = 0
    page.ScrollBarThickness     = 2
    page.ScrollBarImageColor3   = self.palette.border
    page.CanvasSize             = UDim2.new(0, 0, 0, 0)
    page.AutomaticCanvasSize    = Enum.AutomaticSize.Y
    page.Visible                = false
    page.Parent                 = self.content
    pad(page, 10)

    local pageList = Instance.new("UIListLayout")
    pageList.Padding   = UDim.new(0, 8)
    pageList.SortOrder = Enum.SortOrder.LayoutOrder
    pageList.Parent    = page

    local tab = { name = name, page = page, btn = btn, _win = win }

    local function setActive(active)
        if active then
            btnLbl.TextColor3 = win.palette.accentText
            tween(indicator, { BackgroundTransparency = 0 })
            page.Visible = true
        else
            btnLbl.TextColor3 = win.palette.txtMuted
            tween(indicator, { BackgroundTransparency = 1 })
            page.Visible = false
        end
    end
    tab._setActive = setActive

    btn.MouseButton1Click:Connect(function()
        for _, t in ipairs(win.tabs) do t._setActive(false) end
        win.activeTab = tab
        setActive(true)
    end)
    btn.MouseEnter:Connect(function()
        if win.activeTab ~= tab then btnLbl.TextColor3 = win.palette.txtPrimary end
    end)
    btn.MouseLeave:Connect(function()
        if win.activeTab ~= tab then btnLbl.TextColor3 = win.palette.txtMuted end
    end)

    win:_register(btn, function(p) btn.BackgroundColor3 = p.bgPanel end)
    win:_register(indicator, function(p) indicator.BackgroundColor3 = p.accent end)
    win:_register(btnLbl, function(p)
        btnLbl.TextColor3 = (win.activeTab == tab) and p.accentText or p.txtMuted
    end)
    win:_register(page, function(p) page.ScrollBarImageColor3 = p.border end)

    table.insert(win.tabs, tab)
    if not win.activeTab then
        win.activeTab = tab
        setActive(true)
    end

    return setmetatable(tab, { __index = QuantumLib._TabMethods })
end

-- ── Section + elements live on a TabMethods table ───────────────────────────────

QuantumLib._TabMethods = {}
local TM = QuantumLib._TabMethods

function TM:Section(title)
    local win  = self._win
    local page = self.page

    local container = Instance.new("Frame")
    container.BackgroundColor3 = win.palette.bg
    container.BorderSizePixel  = 0
    container.AutomaticSize    = Enum.AutomaticSize.Y
    container.Size             = UDim2.new(1, 0, 0, 0)
    container.Parent           = page
    local cStroke = stroke(container, win.palette.border, 1)
    win:_register(container, function(p) container.BackgroundColor3 = p.bg; cStroke.Color = p.border end)

    local cList = Instance.new("UIListLayout")
    cList.Padding   = UDim.new(0, 6)
    cList.SortOrder = Enum.SortOrder.LayoutOrder
    cList.Parent    = container
    pad(container, 10)

    local header = label(container, title, 11, win.palette.txtMuted, Enum.TextXAlignment.Left)
    header.Size = UDim2.new(1, 0, 0, 14)
    win:_register(header, function(p) header.TextColor3 = p.txtMuted end)

    local sec = { _win = win, _holder = container }
    return setmetatable(sec, { __index = QuantumLib._SectionMethods })
end

-- ── Section element methods ──────────────────────────────────────────────────────

QuantumLib._SectionMethods = {}
local SM = QuantumLib._SectionMethods

-- Button (compact)
function SM:Button(text, callback)
    local win = self._win
    local btn = Instance.new("TextButton")
    btn.Size             = UDim2.new(1, 0, 0, 24)
    btn.BackgroundColor3 = win.palette.bgBtn
    btn.BorderSizePixel  = 0
    btn.AutoButtonColor  = false
    btn.Text             = text
    btn.Font             = Enum.Font.Code
    btn.TextSize         = 11
    btn.TextColor3       = win.palette.txtPrimary
    btn.Parent           = self._holder
    local s = stroke(btn, win.palette.border, 1)

    btn.MouseEnter:Connect(function() tween(btn, { BackgroundColor3 = win.palette.bgBtnHover }) end)
    btn.MouseLeave:Connect(function() tween(btn, { BackgroundColor3 = win.palette.bgBtn }) end)
    btn.MouseButton1Down:Connect(function() s.Color = win.palette.accent end)
    btn.MouseButton1Up:Connect(function() s.Color = win.palette.border end)
    btn.MouseButton1Click:Connect(function() if callback then task.spawn(callback) end end)

    win:_register(btn, function(p) btn.BackgroundColor3 = p.bgBtn; btn.TextColor3 = p.txtPrimary; s.Color = p.border end)
    return btn
end

-- Toggle (square, filled; translucent fill + glow on, grey + no glow off)
function SM:Toggle(text, default, callback)
    local win   = self._win
    local state = default and true or false

    local row = Instance.new("Frame")
    row.Size             = UDim2.new(1, 0, 0, 22)
    row.BackgroundTransparency = 1
    row.Parent           = self._holder

    local lbl = label(row, text, 11, win.palette.txtPrimary, Enum.TextXAlignment.Left)
    lbl.Size     = UDim2.new(1, -30, 1, 0)
    lbl.Position = UDim2.fromOffset(0, 0)
    win:_register(lbl, function(p) lbl.TextColor3 = p.txtPrimary end)

    -- square box
    local box = Instance.new("TextButton")
    box.Size             = UDim2.fromOffset(18, 18)
    box.Position         = UDim2.new(1, -18, 0.5, -9)
    box.BackgroundColor3 = win.palette.bgInput
    box.BorderSizePixel  = 0
    box.Text             = ""
    box.AutoButtonColor  = false
    box.Parent           = row
    local boxStroke = stroke(box, win.palette.offBorder, 1)

    -- translucent fill that animates in
    local fill = Instance.new("Frame")
    fill.Size                  = UDim2.new(1, 0, 1, 0)
    fill.BackgroundColor3      = win.palette.accent
    fill.BackgroundTransparency = state and 0.35 or 1
    fill.BorderSizePixel       = 0
    fill.Parent                = box

    -- glow (UIStroke acting as outer glow when on)
    local glow = Instance.new("UIStroke")
    glow.Color        = win.palette.accent
    glow.Thickness    = 2
    glow.Transparency = state and 0.2 or 1
    glow.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    glow.Parent       = box

    local function paint()
        if state then
            tween(fill, { BackgroundTransparency = 0.35, BackgroundColor3 = win.palette.accent })
            tween(glow, { Transparency = 0.2 })
            glow.Color = win.palette.accent
            fill.BackgroundColor3 = win.palette.accent
            boxStroke.Color = win.palette.accent
        else
            tween(fill, { BackgroundTransparency = 1 })
            tween(glow, { Transparency = 1 })
            boxStroke.Color = win.palette.offBorder
        end
    end
    paint()

    box.MouseButton1Click:Connect(function()
        state = not state
        paint()
        if callback then task.spawn(callback, state) end
    end)

    win:_register(box, function(p)
        box.BackgroundColor3 = p.bgInput
        fill.BackgroundColor3 = p.accent
        glow.Color = p.accent
        boxStroke.Color = state and p.accent or p.offBorder
    end)

    return {
        Set = function(_, v) state = v and true or false; paint(); if callback then task.spawn(callback, state) end end,
        Get = function() return state end,
    }
end

-- Slider (square draggable handle, smooth, counting text)
function SM:Slider(text, min, max, default, callback)
    local win = self._win
    min, max = min or 0, max or 100
    local value = math.clamp(default or min, min, max)

    local row = Instance.new("Frame")
    row.Size             = UDim2.new(1, 0, 0, 32)
    row.BackgroundTransparency = 1
    row.Parent           = self._holder

    local lbl = label(row, text, 11, win.palette.txtPrimary, Enum.TextXAlignment.Left)
    lbl.Size = UDim2.new(0.7, 0, 0, 14)
    win:_register(lbl, function(p) lbl.TextColor3 = p.txtPrimary end)

    local valLbl = label(row, tostring(value), 11, win.palette.accentText, Enum.TextXAlignment.Right)
    valLbl.Size     = UDim2.new(0.3, 0, 0, 14)
    valLbl.Position = UDim2.new(0.7, 0, 0, 0)
    win:_register(valLbl, function(p) valLbl.TextColor3 = p.accentText end)

    -- track
    local track = Instance.new("Frame")
    track.Size             = UDim2.new(1, 0, 0, 6)
    track.Position         = UDim2.new(0, 0, 0, 20)
    track.BackgroundColor3 = win.palette.track
    track.BorderSizePixel  = 0
    track.Parent           = row
    local tStroke = stroke(track, win.palette.border, 1)
    win:_register(track, function(p) track.BackgroundColor3 = p.track; tStroke.Color = p.border end)

    -- filled portion
    local fillPct = (value - min) / (max - min)
    local fill = Instance.new("Frame")
    fill.Size             = UDim2.new(fillPct, 0, 1, 0)
    fill.BackgroundColor3 = win.palette.accent
    fill.BorderSizePixel  = 0
    fill.Parent           = track
    win:_register(fill, function(p) fill.BackgroundColor3 = p.accent end)

    -- square handle
    local handle = Instance.new("Frame")
    handle.Size             = UDim2.fromOffset(10, 14)
    handle.AnchorPoint      = Vector2.new(0.5, 0.5)
    handle.Position         = UDim2.new(fillPct, 0, 0.5, 0)
    handle.BackgroundColor3 = win.palette.accent
    handle.BorderSizePixel  = 0
    handle.ZIndex           = 3
    handle.Parent           = track
    local hStroke = stroke(handle, win.palette.bg, 1)
    win:_register(handle, function(p) handle.BackgroundColor3 = p.accent; hStroke.Color = p.bg end)

    local dragging = false

    local function setFromX(px)
        local rel = math.clamp((px - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local raw = min + (max - min) * rel
        local newVal = math.floor(raw + 0.5)
        if newVal ~= value then
            value = newVal
            valLbl.Text = tostring(value)
            if callback then task.spawn(callback, value) end
        end
        local pct = (value - min) / (max - min)
        tween(fill,   { Size = UDim2.new(pct, 0, 1, 0) }, TI_SMOOTH)
        tween(handle, { Position = UDim2.new(pct, 0, 0.5, 0) }, TI_SMOOTH)
    end

    track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; setFromX(i.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            setFromX(i.Position.X)
        end
    end)

    return {
        Set = function(_, v)
            value = math.clamp(v, min, max)
            valLbl.Text = tostring(value)
            local pct = (value - min) / (max - min)
            tween(fill,   { Size = UDim2.new(pct, 0, 1, 0) }, TI_SMOOTH)
            tween(handle, { Position = UDim2.new(pct, 0, 0.5, 0) }, TI_SMOOTH)
            if callback then task.spawn(callback, value) end
        end,
        Get = function() return value end,
    }
end

-- Theme switcher dropdown helper (optional convenience)
function SM:ThemeButtons(names)
    local win = self._win
    names = names or { "blue", "green", "red", "yellow", "purple", "cyan", "orange", "mono" }
    local wrap = Instance.new("Frame")
    wrap.Size                  = UDim2.new(1, 0, 0, 22)
    wrap.BackgroundTransparency = 1
    wrap.Parent                = self._holder
    local grid = Instance.new("UIListLayout")
    grid.FillDirection = Enum.FillDirection.Horizontal
    grid.Padding       = UDim.new(0, 4)
    grid.Parent        = wrap

    for _, n in ipairs(names) do
        local sw = Instance.new("TextButton")
        sw.Size             = UDim2.fromOffset(20, 20)
        sw.Text             = ""
        sw.BackgroundColor3 = PALETTES[n].accent
        sw.BorderSizePixel  = 0
        sw.AutoButtonColor  = false
        sw.Parent           = wrap
        stroke(sw, win.palette.border, 1)
        sw.MouseButton1Click:Connect(function() win:Theme(n) end)
    end
    return wrap
end

return QuantumLib
