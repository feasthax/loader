local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui          = game:GetService("CoreGui")
local Players          = game:GetService("Players")

local function Derive(Accent)
	return {
		Bg         = Color3.fromRGB(26,  26,  26),
		BgPanel    = Color3.fromRGB(29,  29,  29),
		BgInput    = Color3.fromRGB(20,  20,  20),
		BgBtn      = Color3.fromRGB(37,  37,  37),
		BgBtnHover = Color3.fromRGB(46,  46,  46),
		TitleBar   = Color3.fromRGB(34,  34,  34),
		Border     = Color3.fromRGB(56,  56,  56),
		Track      = Color3.fromRGB(45,  45,  45),
		TxtPrimary = Color3.fromRGB(200, 200, 200),
		TxtMuted   = Color3.fromRGB(136, 136, 136),
		TxtDim     = Color3.fromRGB(85,  85,  85),
		Accent     = Accent,
		AccentText = Accent,
		OffFill    = Color3.fromRGB(60,  60,  60),
		OffBorder  = Color3.fromRGB(70,  70,  70),
	}
end

local Palettes = {
	Blue   = Derive(Color3.fromRGB(77,  159, 223)),
	Green  = Derive(Color3.fromRGB(94,  207, 138)),
	Red    = Derive(Color3.fromRGB(220, 80,  80)),
	Yellow = Derive(Color3.fromRGB(220, 180, 60)),
	Purple = Derive(Color3.fromRGB(168, 130, 232)),
	Cyan   = Derive(Color3.fromRGB(80,  200, 210)),
	Orange = Derive(Color3.fromRGB(232, 150, 80)),
	Mono   = Derive(Color3.fromRGB(200, 200, 200)),
}

local QuantumLib = {}
QuantumLib.__index = QuantumLib

local function Stroke(Parent, Color, Thickness, Transparency)
	local S = Instance.new("UIStroke")
	S.Color           = Color or Color3.fromRGB(56, 56, 56)
	S.Thickness       = Thickness or 1
	S.Transparency    = Transparency or 0
	S.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	S.Parent          = Parent
	return S
end

local function Pad(Parent, P)
	local U = Instance.new("UIPadding")
	U.PaddingTop    = UDim.new(0, P)
	U.PaddingBottom = UDim.new(0, P)
	U.PaddingLeft   = UDim.new(0, P)
	U.PaddingRight  = UDim.new(0, P)
	U.Parent        = Parent
	return U
end

local function Label(Parent, Text, Size, Color, X)
	local L = Instance.new("TextLabel")
	L.BackgroundTransparency = 1
	L.Text            = Text
	L.TextSize        = Size or 11
	L.TextColor3      = Color or Color3.fromRGB(136, 136, 136)
	L.Font            = Enum.Font.Code
	L.TextXAlignment  = X or Enum.TextXAlignment.Left
	L.TextYAlignment  = Enum.TextYAlignment.Center
	L.BorderSizePixel = 0
	L.Parent          = Parent
	return L
end

local TiFast   = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TiSmooth = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function Tween(Obj, Props, Info)
	local T = TweenService:Create(Obj, Info or TiFast, Props)
	T:Play()
	return T
end

function QuantumLib:Window(Opts)
	Opts = Opts or {}
	local self = setmetatable({}, QuantumLib)

	self.Palette   = table.clone(Palettes[Opts.Theme or "Blue"])
	self.Themed    = {}
	self.Tabs      = {}
	self.ActiveTab = nil

	local Size = Opts.Size or Vector2.new(420, 360)
	local WinW, WinH = Size.X, Size.Y

	local Existing = CoreGui:FindFirstChild("QuantumLibGUI")
	if Existing then Existing:Destroy() end

	local Gui = Instance.new("ScreenGui")
	Gui.Name           = "QuantumLibGUI"
	Gui.ResetOnSpawn   = false
	Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	Gui.Parent         = CoreGui
	self.Gui = Gui

	local Window = Instance.new("Frame")
	Window.Name             = "Window"
	Window.Size             = UDim2.fromOffset(WinW, WinH)
	Window.Position         = UDim2.fromOffset(
		math.floor(workspace.CurrentCamera.ViewportSize.X / 2 - WinW / 2),
		math.floor(workspace.CurrentCamera.ViewportSize.Y / 2 - WinH / 2)
	)
	Window.BackgroundColor3 = self.Palette.Bg
	Window.BorderSizePixel  = 0
	Window.Active           = true
	Window.Parent           = Gui
	self.Window = Window
	local WinStroke = Stroke(Window, self.Palette.Border, 1)
	self:Register(Window, function(P) Window.BackgroundColor3 = P.Bg; WinStroke.Color = P.Border end)

	local TitleBar = Instance.new("Frame")
	TitleBar.Size             = UDim2.new(1, 0, 0, 24)
	TitleBar.BackgroundColor3 = self.Palette.TitleBar
	TitleBar.BorderSizePixel  = 0
	TitleBar.Active           = true
	TitleBar.Parent           = Window
	self:Register(TitleBar, function(P) TitleBar.BackgroundColor3 = P.TitleBar end)

	local TitleDiv = Instance.new("Frame")
	TitleDiv.Size             = UDim2.new(1, 0, 0, 1)
	TitleDiv.Position         = UDim2.new(0, 0, 1, -1)
	TitleDiv.BackgroundColor3 = self.Palette.Border
	TitleDiv.BorderSizePixel  = 0
	TitleDiv.Parent           = TitleBar
	self:Register(TitleDiv, function(P) TitleDiv.BackgroundColor3 = P.Border end)

	local TitleLbl = Label(TitleBar, Opts.Title or "quantum", 11, self.Palette.TxtPrimary, Enum.TextXAlignment.Center)
	TitleLbl.Size = UDim2.new(1, 0, 1, 0)
	self:Register(TitleLbl, function(P) TitleLbl.TextColor3 = P.TxtPrimary end)

	local Dragging, DragStart, StartPos
	TitleBar.InputBegan:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
			Dragging  = true
			DragStart = Input.Position
			StartPos  = Vector2.new(Window.AbsolutePosition.X, Window.AbsolutePosition.Y)
			Input.Changed:Connect(function()
				if Input.UserInputState == Enum.UserInputState.End then
					Dragging = false
				end
			end)
		end
	end)
	UserInputService.InputChanged:Connect(function(Input)
		if Dragging and (Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch) then
			local D = Input.Position - DragStart
			Window.Position = UDim2.fromOffset(StartPos.X + D.X, StartPos.Y + D.Y)
		end
	end)

	local Topbar = Instance.new("Frame")
	Topbar.Size             = UDim2.new(1, 0, 0, 28)
	Topbar.Position         = UDim2.fromOffset(0, 24)
	Topbar.BackgroundColor3 = self.Palette.BgPanel
	Topbar.BorderSizePixel  = 0
	Topbar.ClipsDescendants = true
	Topbar.Parent           = Window
	self:Register(Topbar, function(P) Topbar.BackgroundColor3 = P.BgPanel end)
	self.Topbar = Topbar

	local TopDiv = Instance.new("Frame")
	TopDiv.Size             = UDim2.new(1, 0, 0, 1)
	TopDiv.Position         = UDim2.new(0, 0, 1, -1)
	TopDiv.BackgroundColor3 = self.Palette.Border
	TopDiv.BorderSizePixel  = 0
	TopDiv.Parent           = Topbar
	self:Register(TopDiv, function(P) TopDiv.BackgroundColor3 = P.Border end)

	local TabList = Instance.new("UIListLayout")
	TabList.FillDirection = Enum.FillDirection.Horizontal
	TabList.SortOrder     = Enum.SortOrder.LayoutOrder
	TabList.Parent        = Topbar

	local Content = Instance.new("Frame")
	Content.Name             = "Content"
	Content.Size             = UDim2.new(1, 0, 1, -52)
	Content.Position         = UDim2.fromOffset(0, 52)
	Content.BackgroundColor3 = self.Palette.BgPanel
	Content.BorderSizePixel  = 0
	Content.Parent           = Window
	self:Register(Content, function(P) Content.BackgroundColor3 = P.BgPanel end)
	self.Content = Content

	return self
end

function QuantumLib:Register(Inst, Fn)
	table.insert(self.Themed, Fn)
	Fn(self.Palette)
end

function QuantumLib:Repaint()
	for _, Fn in ipairs(self.Themed) do
		pcall(Fn, self.Palette)
	end
end

function QuantumLib:Theme(Name)
	local P = Palettes[Name]
	if not P then return end
	self.Palette = table.clone(P)
	self:Repaint()
end

function QuantumLib:SetAccent(Color)
	self.Palette.Accent     = Color
	self.Palette.AccentText = Color
	self:Repaint()
end

function QuantumLib:Tab(Name)
	local Win = self

	local Btn = Instance.new("TextButton")
	Btn.Size             = UDim2.fromOffset(0, 28)
	Btn.AutomaticSize    = Enum.AutomaticSize.X
	Btn.BackgroundColor3 = self.Palette.BgPanel
	Btn.BorderSizePixel  = 0
	Btn.AutoButtonColor  = false
	Btn.Text             = ""
	Btn.Parent           = self.Topbar

	local BtnPad = Instance.new("UIPadding")
	BtnPad.PaddingLeft  = UDim.new(0, 14)
	BtnPad.PaddingRight = UDim.new(0, 14)
	BtnPad.Parent       = Btn

	local BtnLbl = Label(Btn, Name, 11, self.Palette.TxtMuted, Enum.TextXAlignment.Center)
	BtnLbl.Size = UDim2.new(1, 0, 1, 0)

	local Indicator = Instance.new("Frame")
	Indicator.Size                    = UDim2.new(1, 0, 0, 2)
	Indicator.Position                = UDim2.new(0, 0, 1, -2)
	Indicator.BackgroundColor3        = self.Palette.Accent
	Indicator.BackgroundTransparency  = 1
	Indicator.BorderSizePixel         = 0
	Indicator.Parent                  = Btn

	local Page = Instance.new("ScrollingFrame")
	Page.Size                = UDim2.new(1, 0, 1, 0)
	Page.BackgroundTransparency = 1
	Page.BorderSizePixel     = 0
	Page.ScrollBarThickness  = 2
	Page.ScrollBarImageColor3 = self.Palette.Border
	Page.CanvasSize          = UDim2.new(0, 0, 0, 0)
	Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
	Page.Visible             = false
	Page.Parent              = self.Content
	Pad(Page, 10)

	local PageList = Instance.new("UIListLayout")
	PageList.Padding   = UDim.new(0, 8)
	PageList.SortOrder = Enum.SortOrder.LayoutOrder
	PageList.Parent    = Page

	local Tab = { Name = Name, Page = Page, Btn = Btn, Win = Win }

	local function SetActive(Active)
		if Active then
			BtnLbl.TextColor3 = Win.Palette.AccentText
			Tween(Indicator, { BackgroundTransparency = 0 })
			Page.Visible = true
		else
			BtnLbl.TextColor3 = Win.Palette.TxtMuted
			Tween(Indicator, { BackgroundTransparency = 1 })
			Page.Visible = false
		end
	end
	Tab.SetActive = SetActive

	Btn.MouseButton1Click:Connect(function()
		for _, T in ipairs(Win.Tabs) do T.SetActive(false) end
		Win.ActiveTab = Tab
		SetActive(true)
	end)
	Btn.MouseEnter:Connect(function()
		if Win.ActiveTab ~= Tab then BtnLbl.TextColor3 = Win.Palette.TxtPrimary end
	end)
	Btn.MouseLeave:Connect(function()
		if Win.ActiveTab ~= Tab then BtnLbl.TextColor3 = Win.Palette.TxtMuted end
	end)

	Win:Register(Btn, function(P) Btn.BackgroundColor3 = P.BgPanel end)
	Win:Register(Indicator, function(P) Indicator.BackgroundColor3 = P.Accent end)
	Win:Register(BtnLbl, function(P)
		BtnLbl.TextColor3 = (Win.ActiveTab == Tab) and P.AccentText or P.TxtMuted
	end)
	Win:Register(Page, function(P) Page.ScrollBarImageColor3 = P.Border end)

	table.insert(Win.Tabs, Tab)
	if not Win.ActiveTab then
		Win.ActiveTab = Tab
		SetActive(true)
	end

	return setmetatable(Tab, { __index = QuantumLib.TabMethods })
end

QuantumLib.TabMethods = {}
local TM = QuantumLib.TabMethods

function TM:Section(Title)
	local Win  = self.Win
	local Page = self.Page

	local Container = Instance.new("Frame")
	Container.BackgroundColor3 = Win.Palette.Bg
	Container.BorderSizePixel  = 0
	Container.AutomaticSize    = Enum.AutomaticSize.Y
	Container.Size             = UDim2.new(1, 0, 0, 0)
	Container.Parent           = Page
	local CStroke = Stroke(Container, Win.Palette.Border, 1)
	Win:Register(Container, function(P) Container.BackgroundColor3 = P.Bg; CStroke.Color = P.Border end)

	local CList = Instance.new("UIListLayout")
	CList.Padding           = UDim.new(0, 6)
	CList.SortOrder         = Enum.SortOrder.LayoutOrder
	CList.HorizontalAlignment = Enum.HorizontalAlignment.Center
	CList.Parent            = Container
	Pad(Container, 10)

	local Header = Label(Container, Title, 11, Win.Palette.TxtMuted, Enum.TextXAlignment.Center)
	Header.Size = UDim2.new(1, 0, 0, 14)
	Win:Register(Header, function(P) Header.TextColor3 = P.TxtMuted end)

	local Sec = { Win = Win, Holder = Container }
	return setmetatable(Sec, { __index = QuantumLib.SectionMethods })
end

QuantumLib.SectionMethods = {}
local SM = QuantumLib.SectionMethods

function SM:Button(Text, Callback)
	local Win = self.Win
	local Btn = Instance.new("TextButton")
	Btn.Size             = UDim2.new(1, 0, 0, 24)
	Btn.BackgroundColor3 = Win.Palette.BgBtn
	Btn.BorderSizePixel  = 0
	Btn.AutoButtonColor  = false
	Btn.Text             = Text
	Btn.Font             = Enum.Font.Code
	Btn.TextSize         = 11
	Btn.TextColor3       = Win.Palette.TxtPrimary
	Btn.Parent           = self.Holder
	local S = Stroke(Btn, Win.Palette.Border, 1)

	Btn.MouseEnter:Connect(function() Tween(Btn, { BackgroundColor3 = Win.Palette.BgBtnHover }) end)
	Btn.MouseLeave:Connect(function() Tween(Btn, { BackgroundColor3 = Win.Palette.BgBtn }) end)
	Btn.MouseButton1Down:Connect(function() S.Color = Win.Palette.Accent end)
	Btn.MouseButton1Up:Connect(function() S.Color = Win.Palette.Border end)
	Btn.MouseButton1Click:Connect(function() if Callback then task.spawn(Callback) end end)

	Win:Register(Btn, function(P) Btn.BackgroundColor3 = P.BgBtn; Btn.TextColor3 = P.TxtPrimary; S.Color = P.Border end)
	return Btn
end

function SM:Toggle(Text, Default, Callback)
	local Win   = self.Win
	local State = Default and true or false

	local Row = Instance.new("Frame")
	Row.Size                   = UDim2.new(1, 0, 0, 22)
	Row.BackgroundTransparency = 1
	Row.Parent                 = self.Holder

	local Lbl = Label(Row, Text, 11, Win.Palette.TxtPrimary, Enum.TextXAlignment.Left)
	Lbl.Size     = UDim2.new(1, -30, 1, 0)
	Lbl.Position = UDim2.fromOffset(0, 0)
	Win:Register(Lbl, function(P) Lbl.TextColor3 = P.TxtPrimary end)

	local Box = Instance.new("TextButton")
	Box.Size             = UDim2.fromOffset(18, 18)
	Box.Position         = UDim2.new(1, -18, 0.5, -9)
	Box.BackgroundColor3 = Win.Palette.BgInput
	Box.BorderSizePixel  = 0
	Box.Text             = ""
	Box.AutoButtonColor  = false
	Box.Parent           = Row
	local BoxStroke = Stroke(Box, Win.Palette.OffBorder, 1)

	local Fill = Instance.new("Frame")
	Fill.Size                   = UDim2.new(1, 0, 1, 0)
	Fill.BackgroundColor3       = Win.Palette.Accent
	Fill.BackgroundTransparency = State and 0.35 or 1
	Fill.BorderSizePixel        = 0
	Fill.Parent                 = Box

	local Glow = Instance.new("UIStroke")
	Glow.Color           = Win.Palette.Accent
	Glow.Thickness       = 2
	Glow.Transparency    = State and 0.2 or 1
	Glow.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	Glow.Parent          = Box

	local function Paint()
		if State then
			Tween(Fill, { BackgroundTransparency = 0.35, BackgroundColor3 = Win.Palette.Accent })
			Tween(Glow, { Transparency = 0.2 })
			Glow.Color = Win.Palette.Accent
			Fill.BackgroundColor3 = Win.Palette.Accent
			BoxStroke.Color = Win.Palette.Accent
		else
			Tween(Fill, { BackgroundTransparency = 1 })
			Tween(Glow, { Transparency = 1 })
			BoxStroke.Color = Win.Palette.OffBorder
		end
	end
	Paint()

	Box.MouseButton1Click:Connect(function()
		State = not State
		Paint()
		if Callback then task.spawn(Callback, State) end
	end)

	Win:Register(Box, function(P)
		Box.BackgroundColor3 = P.BgInput
		Fill.BackgroundColor3 = P.Accent
		Glow.Color = P.Accent
		BoxStroke.Color = State and P.Accent or P.OffBorder
	end)

	return {
		Set = function(_, V) State = V and true or false; Paint(); if Callback then task.spawn(Callback, State) end end,
		Get = function() return State end,
	}
end

function SM:Slider(Text, Min, Max, Default, Callback)
	local Win = self.Win
	Min, Max = Min or 0, Max or 100
	local Value = math.clamp(Default or Min, Min, Max)

	local Row = Instance.new("Frame")
	Row.Size                   = UDim2.new(1, 0, 0, 26)
	Row.BackgroundTransparency = 1
	Row.Parent                 = self.Holder

	local Lbl = Label(Row, Text, 11, Win.Palette.TxtPrimary, Enum.TextXAlignment.Left)
	Lbl.Size = UDim2.new(0.7, 0, 0, 12)
	Win:Register(Lbl, function(P) Lbl.TextColor3 = P.TxtPrimary end)

	local ValLbl = Label(Row, tostring(Value), 11, Win.Palette.AccentText, Enum.TextXAlignment.Right)
	ValLbl.Size     = UDim2.new(0.3, 0, 0, 12)
	ValLbl.Position = UDim2.new(0.7, 0, 0, 0)
	Win:Register(ValLbl, function(P) ValLbl.TextColor3 = P.AccentText end)

	local Track = Instance.new("Frame")
	Track.Size             = UDim2.new(1, 0, 0, 5)
	Track.Position         = UDim2.new(0, 0, 0, 17)
	Track.BackgroundColor3 = Win.Palette.Track
	Track.BorderSizePixel  = 0
	Track.Parent           = Row
	local TStroke = Stroke(Track, Win.Palette.Border, 1)
	Win:Register(Track, function(P) Track.BackgroundColor3 = P.Track; TStroke.Color = P.Border end)

	local FillPct = (Value - Min) / (Max - Min)
	local Fill = Instance.new("Frame")
	Fill.Size             = UDim2.new(FillPct, 0, 1, 0)
	Fill.BackgroundColor3 = Win.Palette.Accent
	Fill.BorderSizePixel  = 0
	Fill.Parent           = Track
	Win:Register(Fill, function(P) Fill.BackgroundColor3 = P.Accent end)

	local Handle = Instance.new("Frame")
	Handle.Size             = UDim2.fromOffset(10, 13)
	Handle.AnchorPoint      = Vector2.new(0.5, 0.5)
	Handle.Position         = UDim2.new(FillPct, 0, 0.5, 0)
	Handle.BackgroundColor3 = Win.Palette.Accent
	Handle.BorderSizePixel  = 0
	Handle.ZIndex           = 3
	Handle.Parent           = Track
	local HStroke = Stroke(Handle, Win.Palette.Bg, 1)
	Win:Register(Handle, function(P) Handle.BackgroundColor3 = P.Accent; HStroke.Color = P.Bg end)

	local Dragging = false

	local function SetFromX(Px)
		local Rel = math.clamp((Px - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
		local Raw = Min + (Max - Min) * Rel
		local NewVal = math.floor(Raw + 0.5)
		if NewVal ~= Value then
			Value = NewVal
			ValLbl.Text = tostring(Value)
			if Callback then task.spawn(Callback, Value) end
		end
		local Pct = (Value - Min) / (Max - Min)
		Tween(Fill,   { Size = UDim2.new(Pct, 0, 1, 0) }, TiSmooth)
		Tween(Handle, { Position = UDim2.new(Pct, 0, 0.5, 0) }, TiSmooth)
	end

	Track.InputBegan:Connect(function(I)
		if I.UserInputType == Enum.UserInputType.MouseButton1 or I.UserInputType == Enum.UserInputType.Touch then
			Dragging = true
			SetFromX(I.Position.X)
		end
	end)
	UserInputService.InputEnded:Connect(function(I)
		if I.UserInputType == Enum.UserInputType.MouseButton1 or I.UserInputType == Enum.UserInputType.Touch then
			Dragging = false
		end
	end)
	UserInputService.InputChanged:Connect(function(I)
		if Dragging and (I.UserInputType == Enum.UserInputType.MouseMovement or I.UserInputType == Enum.UserInputType.Touch) then
			SetFromX(I.Position.X)
		end
	end)

	return {
		Set = function(_, V)
			Value = math.clamp(V, Min, Max)
			ValLbl.Text = tostring(Value)
			local Pct = (Value - Min) / (Max - Min)
			Tween(Fill,   { Size = UDim2.new(Pct, 0, 1, 0) }, TiSmooth)
			Tween(Handle, { Position = UDim2.new(Pct, 0, 0.5, 0) }, TiSmooth)
			if Callback then task.spawn(Callback, Value) end
		end,
		Get = function() return Value end,
	}
end

function SM:ThemeButtons(Names)
	local Win = self.Win
	Names = Names or { "Blue", "Green", "Red", "Yellow", "Purple", "Cyan", "Orange", "Mono" }
	local Wrap = Instance.new("Frame")
	Wrap.Size                   = UDim2.new(1, 0, 0, 22)
	Wrap.BackgroundTransparency = 1
	Wrap.Parent                 = self.Holder
	local Grid = Instance.new("UIListLayout")
	Grid.FillDirection      = Enum.FillDirection.Horizontal
	Grid.Padding            = UDim.new(0, 4)
	Grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
	Grid.Parent             = Wrap

	for _, N in ipairs(Names) do
		local Sw = Instance.new("TextButton")
		Sw.Size             = UDim2.fromOffset(20, 20)
		Sw.Text             = ""
		Sw.BackgroundColor3 = Palettes[N].Accent
		Sw.BorderSizePixel  = 0
		Sw.AutoButtonColor  = false
		Sw.Parent           = Wrap
		Stroke(Sw, Win.Palette.Border, 1)
		Sw.MouseButton1Click:Connect(function() Win:Theme(N) end)
	end
	return Wrap
end

return QuantumLib
