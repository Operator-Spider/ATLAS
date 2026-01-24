--!strict
-- LocalScript (place in StarterPlayerScripts)
-- Listens for ReplicatedStorage.ATLAS_ERROR_HANDLER and displays a client-side error UI (Studio only use is fine)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")

local player = Players.LocalPlayer

local REMOTE_NAME = "ATLAS_ERROR_HANDLER"
local ACCENT_COLOR = Color3.fromRGB(255, 104, 122)
local LOGO_ASSET_ID = "rbxassetid://85889182161641"

-- ---------- UI helpers ----------
local function tween(obj: Instance, info: TweenInfo, props: {[string]: any})
	local t = TweenService:Create(obj, info, props)
	t:Play()
	return t
end

local function safeDestroy(x: Instance?)
	if x and x.Parent then
		x:Destroy()
	end
end

local function formatPayload(message: any, data: any): string
	local function stringify(val: any, depth: number, seen: {[any]: boolean}): {string}
		local indent = string.rep("  ", depth)
		local lines: {string} = {}

		local t = typeof(val)
		if t == "table" then
			if seen[val] then
				table.insert(lines, indent .. "<cycle>")
				return lines
			end
			seen[val] = true

			local keys = {}
			for k in pairs(val) do table.insert(keys, k) end
			table.sort(keys, function(a, b)
				return tostring(a) < tostring(b)
			end)

			if #keys == 0 then
				table.insert(lines, indent .. "{}")
				return lines
			end

			table.insert(lines, indent .. "{")
			for _, k in ipairs(keys) do
				local v = val[k]
				local keyStr = tostring(k)
				if typeof(v) == "table" then
					table.insert(lines, indent .. "  " .. keyStr .. ":")
					local nested = stringify(v, depth + 2, seen)
					for _, ln in ipairs(nested) do table.insert(lines, ln) end
				else
					table.insert(lines, indent .. "  " .. keyStr .. ": " .. tostring(v))
				end
			end
			table.insert(lines, indent .. "}")
		else
			if t == "string" then
				table.insert(lines, indent .. '"' .. val .. '"')
			else
				table.insert(lines, indent .. tostring(val))
			end
		end

		return lines
	end

	local lines = {}
	table.insert(lines, "ATLAS Error Handler")
	table.insert(lines, "--------------------")
	table.insert(lines, "Message: " .. tostring(message))
	table.insert(lines, "")
	table.insert(lines, "Data:")

	local serialized = stringify(data, 1, {})
	for _, ln in ipairs(serialized) do table.insert(lines, ln) end

	return table.concat(lines, "\n")
end

local function ensureGui(): ScreenGui
	local existing = player:FindFirstChildOfClass("PlayerGui") and player.PlayerGui:FindFirstChild("ATLAS_ErrorUI")
	if existing and existing:IsA("ScreenGui") then
		return existing
	end

	local sg = Instance.new("ScreenGui")
	sg.Name = "ATLAS_ErrorUI"
	sg.IgnoreGuiInset = true
	sg.ResetOnSpawn = false
	sg.DisplayOrder = 999999
	sg.Parent = player:WaitForChild("PlayerGui")
	return sg
end

local function buildUI(sg: ScreenGui)
	-- Root overlay
	local overlay = Instance.new("Frame")
	overlay.Name = "Overlay"
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 1
	overlay.BorderSizePixel = 0
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.Parent = sg

	-- Force focus to UI (helps keep mouse free)
	overlay.Active = true
	pcall(function()
		overlay.Modal = true
	end)

	local blurHint = Instance.new("TextLabel")
	blurHint.Name = "Hint"
	blurHint.BackgroundTransparency = 1
	blurHint.Text = ""
	blurHint.Size = UDim2.fromScale(1, 1)
	blurHint.Parent = overlay

	-- Card
	local card = Instance.new("Frame")
	card.Name = "Card"
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Position = UDim2.fromScale(0.5, 1.2) -- start off-screen for slide-up
	card.Size = UDim2.fromOffset(640, 420)
	card.BackgroundColor3 = Color3.fromRGB(16, 16, 22)
	card.BackgroundTransparency = 1
	card.BorderSizePixel = 0
	card.Parent = overlay

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = card

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 1
	stroke.Transparency = 1
	stroke.Color = ACCENT_COLOR
	stroke.Parent = card

	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 18)
	pad.PaddingBottom = UDim.new(0, 18)
	pad.PaddingLeft = UDim.new(0, 18)
	pad.PaddingRight = UDim.new(0, 18)
	pad.Parent = card

	-- Title row
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, -72, 0, 34)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 20
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = ACCENT_COLOR
	title.Text = "ATLAS Error"
	title.TextTransparency = 1
	title.Parent = card

	local logo = Instance.new("ImageLabel")
	logo.Name = "Logo"
	logo.AnchorPoint = Vector2.new(1, 0)
	logo.BackgroundTransparency = 1
	logo.Position = UDim2.new(1, -12, 0, -8)
	logo.Size = UDim2.fromOffset(48, 48)
	logo.Image = LOGO_ASSET_ID
	logo.ImageColor3 = Color3.fromRGB(255, 255, 255)
	logo.ImageTransparency = 1
	logo.Parent = card

	local logoCorner = Instance.new("UICorner")
	logoCorner.CornerRadius = UDim.new(1, 0)
	logoCorner.Parent = logo

	local subtitle = Instance.new("TextLabel")
	subtitle.Name = "Subtitle"
	subtitle.BackgroundTransparency = 1
	subtitle.Position = UDim2.new(0, 0, 0, 38)
	subtitle.Size = UDim2.new(1, 0, 0, 22)
	subtitle.Font = Enum.Font.Gotham
	subtitle.TextSize = 14
	subtitle.TextXAlignment = Enum.TextXAlignment.Left
	subtitle.TextColor3 = Color3.fromRGB(222, 222, 230)
	subtitle.Text = "A licensing/whitelist error was reported by the server."
	subtitle.TextTransparency = 1
	subtitle.Parent = card

	local counter = Instance.new("TextLabel")
	counter.Name = "Counter"
	counter.BackgroundTransparency = 1
	counter.Position = UDim2.new(0, 0, 0, 60)
	counter.Size = UDim2.new(1, 0, 0, 20)
	counter.Font = Enum.Font.GothamMedium
	counter.TextSize = 14
	counter.TextXAlignment = Enum.TextXAlignment.Left
	counter.TextColor3 = ACCENT_COLOR
	counter.Text = "Number of Product Issues: 0"
	counter.TextTransparency = 1
	counter.Parent = card

	-- Loading row
	local loadingRow = Instance.new("Frame")
	loadingRow.Name = "LoadingRow"
	loadingRow.BackgroundTransparency = 1
	loadingRow.Position = UDim2.new(0, 0, 0, 86)
	loadingRow.Size = UDim2.new(1, 0, 0, 40)
	loadingRow.Parent = card

	local spinner = Instance.new("ImageLabel")
	spinner.Name = "Spinner"
	spinner.BackgroundTransparency = 1
	spinner.Size = UDim2.fromOffset(26, 26)
	spinner.Position = UDim2.fromOffset(0, 7)
	-- Built-in Roblox asset; if it ever fails, it just won't show but script still works.
	spinner.Image = "rbxassetid://6031094678" -- circular spinner-ish icon
	spinner.ImageColor3 = ACCENT_COLOR
	spinner.ImageTransparency = 1
	spinner.Parent = loadingRow

	local loadingText = Instance.new("TextLabel")
	loadingText.Name = "LoadingText"
	loadingText.BackgroundTransparency = 1
	loadingText.Position = UDim2.fromOffset(36, 0)
	loadingText.Size = UDim2.new(1, -36, 1, 0)
	loadingText.Font = Enum.Font.GothamMedium
	loadingText.TextSize = 14
	loadingText.TextXAlignment = Enum.TextXAlignment.Left
	loadingText.TextColor3 = ACCENT_COLOR
	loadingText.Text = "Preparing report…"
	loadingText.TextTransparency = 1
	loadingText.Parent = loadingRow

	-- Body / list area
	local body = Instance.new("Frame")
	body.Name = "Body"
	body.BackgroundColor3 = Color3.fromRGB(14, 14, 20)
	body.BorderSizePixel = 0
	body.Position = UDim2.new(0, 0, 0, 124)
	body.Size = UDim2.new(1, 0, 1, -190)
	body.BackgroundTransparency = 1
	body.Parent = card

	local bodyCorner = Instance.new("UICorner")
	bodyCorner.CornerRadius = UDim.new(0, 10)
	bodyCorner.Parent = body

	local bodyStroke = Instance.new("UIStroke")
	bodyStroke.Thickness = 1
	bodyStroke.Transparency = 1
	bodyStroke.Color = ACCENT_COLOR
	bodyStroke.Parent = body

	local bodyPad = Instance.new("UIPadding")
	bodyPad.PaddingTop = UDim.new(0, 10)
	bodyPad.PaddingBottom = UDim.new(0, 10)
	bodyPad.PaddingLeft = UDim.new(0, 10)
	bodyPad.PaddingRight = UDim.new(0, 10)
	bodyPad.Parent = body

	local scroller = Instance.new("ScrollingFrame")
	scroller.Name = "Scroller"
	scroller.BackgroundTransparency = 1
	scroller.BorderSizePixel = 0
	scroller.Size = UDim2.fromScale(1, 1)
	scroller.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroller.ScrollBarThickness = 6
	scroller.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroller.ScrollBarImageColor3 = ACCENT_COLOR
	scroller.Parent = body

	local list = Instance.new("UIListLayout")
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, 12)
	list.Parent = scroller

	-- Footer buttons
	local footer = Instance.new("Frame")
	footer.Name = "Footer"
	footer.BackgroundTransparency = 1
	footer.Size = UDim2.new(1, 0, 0, 44)
	footer.Position = UDim2.new(0, 0, 1, -44)
	footer.Parent = card

	local buttonRow = Instance.new("Frame")
	buttonRow.Name = "ButtonRow"
	buttonRow.BackgroundTransparency = 1
	buttonRow.Size = UDim2.fromScale(1, 1)
	buttonRow.Parent = footer

	local rowLayout = Instance.new("UIListLayout")
	rowLayout.FillDirection = Enum.FillDirection.Horizontal
	rowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	rowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	rowLayout.Padding = UDim.new(0, 10)
	rowLayout.Parent = buttonRow

	local function makeButton(text: string)
		local b = Instance.new("TextButton")
		b.AutoButtonColor = false
		b.Size = UDim2.fromOffset(140, 36)
		b.BackgroundColor3 = Color3.fromRGB(30, 26, 34)
		b.BorderSizePixel = 0
		b.Font = Enum.Font.GothamSemibold
		b.TextSize = 14
		b.TextColor3 = ACCENT_COLOR
		b.Text = text
		b.BackgroundTransparency = 1
		b.TextTransparency = 1

		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 10)
		c.Parent = b

		local s = Instance.new("UIStroke")
		s.Thickness = 1
		s.Transparency = 0.35
		s.Color = ACCENT_COLOR
		s.Parent = b

		return b
	end

	local closeBtn = makeButton("Close")
	closeBtn.Name = "CloseButton"
	closeBtn.Parent = buttonRow

	return {
		Overlay = overlay,
		Card = card,
		Title = title,
		Subtitle = subtitle,
		Counter = counter,
		LoadingRow = loadingRow,
		Spinner = spinner,
		LoadingText = loadingText,
		Body = body,
		BodyStroke = bodyStroke,
		Scroller = scroller,
		CloseButton = closeBtn,
		CardStroke = stroke,
		Logo = logo,
		_bound = false,
	}
end

local uiState = {
	gui = nil :: ScreenGui?,
	refs = nil :: any,
	spinConn = nil :: RBXScriptConnection?,
	open = false,

	-- multi-error support
	errorLog = {} :: {string},
	errorCount = 0,

	-- cursor unlock enforcement
	cursorConn = nil :: RBXScriptConnection?,
	prevMouseBehavior = nil :: Enum.MouseBehavior?,
	prevMouseIconEnabled = nil :: boolean?,
	prevCameraType = nil :: Enum.CameraType?,
	prevCameraMode = nil :: Enum.CameraMode?,
	latestCard = nil :: any,
}

local function stopSpinner()
	if uiState.spinConn then
		uiState.spinConn:Disconnect()
		uiState.spinConn = nil
	end
end

local function startSpinner(img: ImageLabel)
	stopSpinner()
	local rot = 0
	uiState.spinConn = RunService.RenderStepped:Connect(function(dt)
		rot += dt * 360 -- deg/sec
		img.Rotation = rot % 360
	end)
end

local function selectAll(textBox: TextBox)
	textBox:CaptureFocus()
	textBox.CursorPosition = 1
	textBox.SelectionStart = #textBox.Text + 1
end

local function tryClipboardCopy(text: string): boolean
	local ok = pcall(function()
		(setclipboard :: any)(text)
	end)
	return ok
end

-- Cursor unlock that works even if the player is in first person:
-- keep MouseBehavior Default, keep the UI modal, and temporarily force the camera to Scriptable while the UI is open.
local function beginForceFreeCursor()
	if uiState.cursorConn then
		return
	end

	uiState.prevMouseBehavior = UserInputService.MouseBehavior
	uiState.prevMouseIconEnabled = UserInputService.MouseIconEnabled

	local cam = workspace.CurrentCamera
	if cam then
		uiState.prevCameraType = cam.CameraType
	end
	uiState.prevCameraMode = player.CameraMode

	local function sinkAction(_: string, state: Enum.UserInputState, _: InputObject)
		if state == Enum.UserInputState.Begin then
			return Enum.ContextActionResult.Sink
		end
		return Enum.ContextActionResult.Pass
	end
	ContextActionService:BindActionAtPriority(
		"ATLAS_SINK_SHIFTLOCK",
		sinkAction,
		false,
		10000,
		Enum.KeyCode.LeftShift,
		Enum.KeyCode.RightShift
	)

	uiState.cursorConn = RunService.RenderStepped:Connect(function()
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true

		local cam2 = workspace.CurrentCamera
		if cam2 then
			cam2.CameraType = Enum.CameraType.Scriptable
		end

		player.CameraMode = Enum.CameraMode.Classic
	end)
end

local function endForceFreeCursor()
	if uiState.cursorConn then
		uiState.cursorConn:Disconnect()
		uiState.cursorConn = nil
	end

	ContextActionService:UnbindAction("ATLAS_SINK_SHIFTLOCK")

	if uiState.prevMouseBehavior then
		UserInputService.MouseBehavior = uiState.prevMouseBehavior
	else
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	end

	if uiState.prevMouseIconEnabled ~= nil then
		UserInputService.MouseIconEnabled = uiState.prevMouseIconEnabled
	else
		UserInputService.MouseIconEnabled = true
	end

	local cam = workspace.CurrentCamera
	if cam and uiState.prevCameraType then
		cam.CameraType = uiState.prevCameraType
	end

	if uiState.prevCameraMode then
		player.CameraMode = uiState.prevCameraMode
	end
end

local function addErrorCard(refs, text: string, index: number)
	local scroller: ScrollingFrame = refs.Scroller

	local card = Instance.new("Frame")
	card.Name = "ErrorCard" .. tostring(index)
	card.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
	card.BackgroundTransparency = 0
	card.BorderSizePixel = 0
	card.Size = UDim2.new(1, -6, 0, 0)
	card.AutomaticSize = Enum.AutomaticSize.Y
	card.Parent = scroller

	local stack = Instance.new("UIListLayout")
	stack.FillDirection = Enum.FillDirection.Vertical
	stack.SortOrder = Enum.SortOrder.LayoutOrder
	stack.Padding = UDim.new(0, 8)
	stack.Parent = card

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = card

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 1
	stroke.Transparency = 0.25
	stroke.Color = ACCENT_COLOR
	stroke.Parent = card

	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 12)
	pad.PaddingBottom = UDim.new(0, 12)
	pad.PaddingLeft = UDim.new(0, 12)
	pad.PaddingRight = UDim.new(0, 12)
	pad.Parent = card

	local header = Instance.new("Frame")
	header.Name = "Header"
	header.BackgroundTransparency = 1
	header.Size = UDim2.new(1, 0, 0, 28)
	header.Parent = card
	header.LayoutOrder = 1

	local headerLayout = Instance.new("UIListLayout")
	headerLayout.FillDirection = Enum.FillDirection.Horizontal
	headerLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	headerLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	headerLayout.Padding = UDim.new(0, 8)
	headerLayout.Parent = header

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, -260, 1, 0)
	title.Font = Enum.Font.GothamSemibold
	title.TextSize = 15
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = ACCENT_COLOR
	title.Text = ("Error #%d"):format(index)
	title.LayoutOrder = 1
	title.Parent = header

	local textBox = Instance.new("TextBox")
	textBox.Name = "Text"
	textBox.BackgroundTransparency = 1
	textBox.ClearTextOnFocus = false
	textBox.MultiLine = true
	textBox.TextEditable = false
	textBox.TextWrapped = false
	textBox.TextXAlignment = Enum.TextXAlignment.Left
	textBox.TextYAlignment = Enum.TextYAlignment.Top
	textBox.Font = Enum.Font.Code
	textBox.TextSize = 14
	textBox.TextColor3 = Color3.fromRGB(240, 240, 248)
	textBox.Text = text
	textBox.TextTransparency = 1
	textBox.AutomaticSize = Enum.AutomaticSize.Y
	textBox.Size = UDim2.new(1, 0, 0, 0)
	textBox.Parent = card
	textBox.LayoutOrder = 2

	local selectBtn = Instance.new("TextButton")
	selectBtn.Name = "Select"
	selectBtn.AutoButtonColor = false
	selectBtn.Size = UDim2.fromOffset(120, 30)
	selectBtn.BackgroundColor3 = Color3.fromRGB(36, 28, 36)
	selectBtn.BorderSizePixel = 0
	selectBtn.Font = Enum.Font.GothamSemibold
	selectBtn.TextSize = 14
	selectBtn.TextColor3 = ACCENT_COLOR
	selectBtn.Text = "Select"
	selectBtn.BackgroundTransparency = 1
	selectBtn.TextTransparency = 1
	selectBtn.LayoutOrder = 3
	selectBtn.Parent = card

	local sc = Instance.new("UICorner")
	sc.CornerRadius = UDim.new(0, 8)
	sc.Parent = selectBtn

	local ss = Instance.new("UIStroke")
	ss.Thickness = 1
	ss.Transparency = 0.35
	ss.Color = ACCENT_COLOR
	ss.Parent = selectBtn

	local function hover(btn: TextButton, over: boolean)
		if over then
			tween(btn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(54, 40, 54)})
		else
			tween(btn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(36, 28, 36)})
		end
	end

	selectBtn.MouseEnter:Connect(function() hover(selectBtn, true) end)
	selectBtn.MouseLeave:Connect(function() hover(selectBtn, false) end)
	selectBtn.MouseButton1Click:Connect(function()
		selectAll(textBox)
		selectBtn.Text = "Selected"
		task.delay(0.9, function()
			selectBtn.Text = "Select"
		end)
	end)

	card.LayoutOrder = index

	return {
		Card = card,
		TextBox = textBox,
		SelectButton = selectBtn,
	}
end

local function showError(message: any, data: any)
	local sg = uiState.gui
	if not sg or not sg.Parent then
		sg = ensureGui()
		uiState.gui = sg
		uiState.refs = buildUI(sg)
	end

	local r = uiState.refs
	uiState.open = true

	-- start closed state for animation every time
	r.Overlay.BackgroundTransparency = 1
	r.Card.Position = UDim2.fromScale(0.5, 1.2)
	r.Card.BackgroundTransparency = 1
	r.CardStroke.Transparency = 1
	r.Title.TextTransparency = 1
	r.Subtitle.TextTransparency = 1
	r.Counter.TextTransparency = 1
	r.Logo.ImageTransparency = 1
	r.Body.BackgroundTransparency = 1
	r.BodyStroke.Transparency = 1
	r.Spinner.ImageTransparency = 1
	r.LoadingText.TextTransparency = 1
	-- footer buttons (only close)
	r.CloseButton.BackgroundTransparency = 1
	r.CloseButton.TextTransparency = 1

	-- Ensure cursor is free (including first person)
	beginForceFreeCursor()

	-- Build payload and add card
	local report = formatPayload(message, data)
	uiState.errorCount += 1
	table.insert(uiState.errorLog, report)

	if r.Counter then
		r.Counter.Text = "Number of Product Issues: " .. tostring(uiState.errorCount)
	end

	local cardRefs = addErrorCard(r, report, uiState.errorCount)
	uiState.latestCard = cardRefs

	-- scroll to bottom after layout updates
	task.defer(function()
		if uiState.refs and uiState.refs.Scroller then
			local sc: ScrollingFrame = uiState.refs.Scroller
			sc.CanvasPosition = Vector2.new(0, math.max(0, sc.AbsoluteCanvasSize.Y))
		end
	end)

	-- Fade in + slide up
	tween(r.Overlay, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0.35})
	tween(r.Card, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0, Position = UDim2.fromScale(0.5, 0.5)})
	tween(r.CardStroke, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 0.15})
		tween(r.Title, TweenInfo.new(0.18), {TextTransparency = 0})
		tween(r.Subtitle, TweenInfo.new(0.18), {TextTransparency = 0})
		tween(r.Counter, TweenInfo.new(0.18), {TextTransparency = 0})
		tween(r.Logo, TweenInfo.new(0.18), {ImageTransparency = 0})

	-- Loading reveal
	r.LoadingText.Text = "Preparing report…"
	startSpinner(r.Spinner)
	tween(r.Spinner, TweenInfo.new(0.12), {ImageTransparency = 0.05})
	tween(r.LoadingText, TweenInfo.new(0.12), {TextTransparency = 0})

	-- Keep body/buttons hidden briefly for a “loading” feel
	task.delay(0.9, function()
		if not uiState.open or not uiState.refs then return end

		r.LoadingText.Text = "ATLAS Error Report"
		stopSpinner()

		tween(r.Body, TweenInfo.new(0.18), {BackgroundTransparency = 0})
		tween(r.BodyStroke, TweenInfo.new(0.18), {Transparency = 0.35})
		tween(cardRefs.TextBox, TweenInfo.new(0.18), {TextTransparency = 0})
		tween(cardRefs.SelectButton, TweenInfo.new(0.18), {BackgroundTransparency = 0})
		tween(cardRefs.SelectButton, TweenInfo.new(0.18), {TextTransparency = 0})
		tween(r.CloseButton, TweenInfo.new(0.18), {BackgroundTransparency = 0})
		tween(r.CloseButton, TweenInfo.new(0.18), {TextTransparency = 0})
	end)

	-- Bind shared buttons once
	if not r._bound then
		r._bound = true

		local function hover(btn: TextButton, over: boolean)
			if over then
				tween(btn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(54, 40, 54)})
			else
				tween(btn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(30, 26, 34)})
			end
		end

		for _, btn in ipairs({r.CloseButton}) do
			btn.MouseEnter:Connect(function() hover(btn, true) end)
			btn.MouseLeave:Connect(function() hover(btn, false) end)
		end

		r.CloseButton.MouseButton1Click:Connect(function()
			uiState.open = false
			stopSpinner()
			endForceFreeCursor()

			if uiState.refs then
				local rr = uiState.refs
				tween(rr.Overlay, TweenInfo.new(0.15), {BackgroundTransparency = 1})
				tween(rr.Card, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {BackgroundTransparency = 1, Position = UDim2.fromScale(0.5, 1.2)})
				tween(rr.CardStroke, TweenInfo.new(0.15), {Transparency = 1})
				tween(rr.Title, TweenInfo.new(0.15), {TextTransparency = 1})
				tween(rr.Subtitle, TweenInfo.new(0.15), {TextTransparency = 1})
				tween(rr.Counter, TweenInfo.new(0.15), {TextTransparency = 1})
				tween(rr.Body, TweenInfo.new(0.15), {BackgroundTransparency = 1})
				tween(rr.BodyStroke, TweenInfo.new(0.15), {Transparency = 1})
				tween(rr.Spinner, TweenInfo.new(0.15), {ImageTransparency = 1})
				tween(rr.LoadingText, TweenInfo.new(0.15), {TextTransparency = 1})
				tween(rr.CloseButton, TweenInfo.new(0.15), {BackgroundTransparency = 1})
				tween(rr.CloseButton, TweenInfo.new(0.15), {TextTransparency = 1})
			end

			task.delay(0.2, function()
				if uiState.gui then
					safeDestroy(uiState.gui)
				end
				uiState.gui = nil
				uiState.refs = nil
				uiState.latestCard = nil
				uiState.errorLog = {}
				uiState.errorCount = 0
			end)
		end)
	end
end

-- ---------- Wire up remote ----------
local remote = ReplicatedStorage:FindFirstChild(REMOTE_NAME)
if not remote then
	remote = ReplicatedStorage:WaitForChild(REMOTE_NAME)
end

(remote :: RemoteEvent).OnClientEvent:Connect(function(message, data)
	showError(message, data)
end)
