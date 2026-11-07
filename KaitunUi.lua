local playersService = game:GetService("Players")
local userInputService = game:GetService("UserInputService")

local THEME = {
	background = Color3.fromRGB(13, 13, 15),
	header = Color3.fromRGB(19, 19, 22),
	field = Color3.fromRGB(22, 22, 26),
	accent = Color3.fromRGB(255, 70, 70),
	text = Color3.fromRGB(240, 240, 240),
	muted = Color3.fromRGB(140, 140, 150),
}

local KaitunUi = {}
KaitunUi.__index = KaitunUi

local function create(className, properties, children)
	local instance = Instance.new(className)
	for key, value in properties do
		instance[key] = value
	end
	for _, child in children or {} do
		child.Parent = instance
	end
	return instance
end

local function corner(radius)
	return create("UICorner", { CornerRadius = UDim.new(0, radius) })
end

local function label(properties)
	properties.BackgroundTransparency = 1
	properties.Font = properties.Font or Enum.Font.GothamBold
	properties.TextColor3 = properties.TextColor3 or THEME.text
	properties.TextXAlignment = properties.TextXAlignment or Enum.TextXAlignment.Left
	return create("TextLabel", properties)
end

-- options: title, subtitle, icon, fields = { { name, label, large } }
function KaitunUi.new(options)
	local self = setmetatable({ values = {}, connections = {} }, KaitunUi)

	local screen = create("ScreenGui", {
		Name = options.title,
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 50,
	})
	local card = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(280, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = THEME.background,
		BorderSizePixel = 0,
		Parent = screen,
	}, {
		corner(12),
		create("UIStroke", { Color = THEME.accent, Transparency = 0.55 }),
		create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }),
	})

	local header = create("Frame", {
		Size = UDim2.new(1, 0, 0, 64),
		BackgroundColor3 = THEME.header,
		BorderSizePixel = 0,
		LayoutOrder = 0,
		Parent = card,
	}, {
		corner(12),
		-- Squares off the header's bottom corners so it joins the body.
		create("Frame", {
			Position = UDim2.new(0, 0, 1, -12),
			Size = UDim2.new(1, 0, 0, 12),
			BackgroundColor3 = THEME.header,
			BorderSizePixel = 0,
		}),
		create("Frame", {
			Position = UDim2.new(0, 0, 1, -1),
			Size = UDim2.new(1, 0, 0, 1),
			BackgroundColor3 = THEME.accent,
			BackgroundTransparency = 0.6,
			BorderSizePixel = 0,
			ZIndex = 2,
		}),
		create("ImageLabel", {
			Position = UDim2.fromOffset(14, 12),
			Size = UDim2.fromOffset(40, 40),
			BackgroundColor3 = THEME.field,
			ScaleType = Enum.ScaleType.Crop,
			Image = options.icon or "",
		}, { corner(8) }),
		label({
			Position = UDim2.fromOffset(64, 14),
			Size = UDim2.new(1, -78, 0, 20),
			Text = options.title,
			TextSize = 16,
			TextTruncate = Enum.TextTruncate.AtEnd,
		}),
		label({
			Position = UDim2.fromOffset(64, 34),
			Size = UDim2.new(1, -78, 0, 16),
			Text = options.subtitle or "",
			TextSize = 12,
			Font = Enum.Font.GothamMedium,
			TextColor3 = THEME.accent,
		}),
	})

	local body = create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		Parent = card,
	}, {
		create("UIPadding", {
			PaddingTop = UDim.new(0, 12),
			PaddingBottom = UDim.new(0, 14),
			PaddingLeft = UDim.new(0, 14),
			PaddingRight = UDim.new(0, 14),
		}),
		create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
	})

	for index, field in options.fields do
		local box = create("Frame", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundColor3 = THEME.field,
			BorderSizePixel = 0,
			LayoutOrder = index,
			Parent = body,
		}, {
			corner(8),
			create("UIPadding", {
				PaddingTop = UDim.new(0, 8),
				PaddingBottom = UDim.new(0, 10),
				PaddingLeft = UDim.new(0, 12),
				PaddingRight = UDim.new(0, 12),
			}),
			create("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }),
			label({
				Size = UDim2.new(1, 0, 0, 14),
				Text = field.label,
				TextSize = 11,
				TextColor3 = THEME.muted,
				LayoutOrder = 0,
			}),
		})
		self.values[field.name] = label({
			Size = UDim2.new(1, 0, 0, if field.large then 44 else 18),
			AutomaticSize = Enum.AutomaticSize.Y,
			Text = field.value or "-",
			TextSize = if field.large then 40 else 15,
			TextWrapped = true,
			LayoutOrder = 1,
			Parent = box,
		})
	end

	-- Drag by the header.
	local dragStart, startPosition
	table.insert(self.connections, header.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragStart, startPosition = input.Position, card.Position
		end
	end))
	table.insert(self.connections, userInputService.InputChanged:Connect(function(input)
		if dragStart and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			card.Position = startPosition + UDim2.fromOffset(delta.X, delta.Y)
		end
	end))
	table.insert(self.connections, userInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragStart = nil
		end
	end))

	screen.Parent = if gethui then gethui() else playersService.LocalPlayer:WaitForChild("PlayerGui")
	self.screen = screen
	return self
end

function KaitunUi:set(name, text)
	self.values[name].Text = tostring(text)
end

function KaitunUi:destroy()
	for _, connection in self.connections do
		connection:Disconnect()
	end
	self.screen:Destroy()
end

return KaitunUi
