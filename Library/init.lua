local Library = {}

local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")

type TimeOptions = {
	ShowMetrics: boolean?,
	HideZeroes: boolean?,
	ClampMetrics: number?,
	ClampDays: boolean?,
	VisibleMetrics: { string }?,
}

-- Add commas to break up number length (example 10000 to 10,000)
function Library:BreakNumber(number: number): string
	local Formatted = number

	while true do
		local i
		Formatted, i = string.gsub(Formatted, "^(-?%d+)(%d%d%d)", "%1,%2")

		if i == 0 then
			break
		end
	end

	return Formatted
end

-- Return a number (example 123456789 to 123.5M)
function Library:SuffixNumber(number: number): string
	if number < 1000 then
		return tostring(number)
	end

	local Suffixes =
		{ "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc", "Ud", "Dd", "Td", "Qad", "Qu", "Sd", "St" }

	local i = math.floor(math.log(number, 1e3))
	local v = 10 ^ (i * 3)

	local Divided = number / v
	local Shortened = tostring(math.floor(Divided * 100) / 100) -- keep up to 2 decimals, no extra 0s

	return Shortened .. Suffixes[i]
end

-- Return a suffixed number (example 123.5M to 123500000)
function Library:ParseSuffixNumber(input)
	input = string.lower(input)
	input = string.gsub(input, ",", "")
	input = string.gsub(input, "%s+", "")

	local NumberPart, SuffixPart = string.match(input, "([%d%.]+)(%a*)")
	if not NumberPart then
		return
	end

	local Number = tonumber(NumberPart)
	if not Number then
		return
	end

	local Suffixes = {
		["k"] = 1e3,
		["m"] = 1e6,
		["b"] = 1e9,
		["t"] = 1e12,
		["qa"] = 1e15,
		["qi"] = 1e18,
		["sx"] = 1e21,
		["sp"] = 1e24,
		["oc"] = 1e27,
		["no"] = 1e30,
		["dc"] = 1e33,
		["ud"] = 1e36,
		["dd"] = 1e39,
		["td"] = 1e42,
		["qad"] = 1e45,
		["qu"] = 1e48,
		["sd"] = 1e51,
		["st"] = 1e54,
	}

	local Multiplier = Suffixes[SuffixPart] or 1

	return Number * Multiplier
end

-- Convert number to roman numerals (example 56 to LVI)
function Library:NumberToRomanNumeral(number: number): string
	local Numerals = {
		{ 1000, "M" },
		{ 900, "CM" },
		{ 500, "D" },
		{ 400, "CD" },
		{ 100, "C" },
		{ 90, "XC" },
		{ 50, "L" },
		{ 40, "XL" },
		{ 10, "X" },
		{ 9, "IX" },
		{ 5, "V" },
		{ 4, "IV" },
		{ 1, "I" },
	}

	local Roman = ""

	while number > 0 do
		for _, v in Numerals do
			local RomanChar = v[2]
			local Int = v[1]

			while number >= Int do
				Roman ..= RomanChar
				number -= Int
			end
		end
	end

	return Roman
end

-- Convert roman numerals to number (example LVI to 56)
function Library:RomanNumeralToNumber(romanNumeral: string): number
	local Values = {
		I = 1,
		V = 5,
		X = 10,
		L = 50,
		C = 100,
		D = 500,
		M = 1000,
	}

	local Total = 0
	local PreviousValue = 0

	-- Iterate through each character in the Roman numeral string
	for i = #romanNumeral, 1, -1 do
		local Character = string.sub(romanNumeral, i, i)
		local Value = Values[Character]

		-- If the value is smaller than the previous one, subtract it (like IV = 4)
		if Value < PreviousValue then
			Total -= Value
		else
			Total += Value
		end

		PreviousValue = Value -- Update the previous value to the current one
	end

	return Total
end

-- Get basic article for words (not perfect, but good enough)
function Library:Article(text: string): string
	local Subbed = string.sub(string.split(string.lower(text), " ")[1], 1, 1)
	local Vowels = { "a", "e", "i", "o", "u" }
	local Prefix = "a"

	if table.find(Vowels, Subbed) then
		Prefix = "an"
	end

	return Prefix
end

-- Basic lerp
function Library:Lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end

-- Check if table is empty
function Library:TableEmpty(tab): boolean
	return next(tab) == nil
end

-- Weld parts in a model to a base part
function Library:Weld(part: BasePart, base: BasePart)
	if part:IsA("BasePart") then -- Part
		local WeldConstraint = Instance.new("WeldConstraint")
		WeldConstraint.Part0 = base
		WeldConstraint.Part1 = part
		WeldConstraint.Parent = base
	else -- Model
		for _, child in part:GetChildren() do
			Library:Weld(child, base)
		end
	end
end

-- Truncate long text
function Library:Truncate(text: string, length: number): string
	if string.len(text) <= length then
		return text -- Not long enough to need truncating
	end

	local String = ""
	for i = 1, string.len(text) - 3 do
		if i == length - 3 then
			break
		end

		String ..= string.sub(text, i, i)
	end

	String ..= "..."

	return String
end

-- Convert time (ex. 12:34)
function Library:ConvertTime(number: number, options: TimeOptions?): string
	options = options or {}

	local ShowMetrics = if options and options.ShowMetrics ~= nil then options.ShowMetrics else false
	local HideZeroes = if options and options.HideZeroes ~= nil then options.HideZeroes else true
	local ClampMetrics = options and options.ClampMetrics
	local ClampDays = options and options.ClampDays
	local VisibleMetrics = options and options.VisibleMetrics

	local Units = {
		d = math.floor(number / 86400),
		h = math.floor(number / 3600) % 24,
		m = math.floor(number / 60) % 60,
		s = number % 60,
	}

	-- Dynamically set VisibleMetrics for colon format if not provided
	if not ShowMetrics and not VisibleMetrics then
		if number >= 86400 then
			VisibleMetrics = { "d", "h", "m", "s" }
		elseif number >= 3600 then
			VisibleMetrics = { "h", "m", "s" }
		else
			VisibleMetrics = { "m", "s" }
		end
	end

	-- Default to all units
	VisibleMetrics = VisibleMetrics or { "d", "h", "m", "s" }

	-- Handle ClampDays: if ShowMetrics + ClampDays + days > 0 → just show "X Day(s)"
	if ShowMetrics and ClampDays and Units.d > 0 then
		local Label = Units.d == 1 and "Day" or "Days"

		return string.format("%d %s", Units.d, Label)
	end

	local Parts = {}
	for _, unit in VisibleMetrics do
		local Value = Units[unit]
		if ShowMetrics then
			if not HideZeroes or Value > 0 then
				table.insert(Parts, string.format("%d%s", Value, unit))
			end
		else
			table.insert(Parts, string.format("%02d", Value))
		end
	end

	-- Apply ClampMetrics in ShowMetrics mode
	if ShowMetrics and ClampMetrics then
		local ClampedParts = {}
		for _, part in Parts do
			if #ClampedParts < ClampMetrics then
				table.insert(ClampedParts, part)
			else
				break
			end
		end
		Parts = ClampedParts
	end

	-- Optionally trim leading zero parts for colon format + hideZeroes
	if not ShowMetrics and HideZeroes then
		while #Parts > 1 and Parts[1] == "00" do
			table.remove(Parts, 1)
		end
	end

	if ShowMetrics then
		return table.concat(Parts, " ")
	else
		return table.concat(Parts, ":")
	end
end

-- Get how much time has passed
function Library:GetTimeAgo(givenTime)
	local TimeDifference = os.time() - givenTime

	if TimeDifference < 60 then -- Less than a minute
		return TimeDifference .. " seconds ago"
	elseif TimeDifference < 3600 then -- Less than an hour
		local MinutesAgo = math.floor(TimeDifference / 60)

		return MinutesAgo .. (MinutesAgo == 1 and " minute ago" or " minutes ago")
	elseif TimeDifference < 86400 then -- Less than a day
		local HoursAgo = math.floor(TimeDifference / 3600)

		return HoursAgo .. (HoursAgo == 1 and " hour ago" or " hours ago")
	elseif TimeDifference < 604800 then -- Less than a week
		local DaysAgo = math.floor(TimeDifference / 86400)

		return DaysAgo .. (DaysAgo == 1 and " day ago" or " days ago")
	else -- More than a week
		local WeeksAgo = math.floor(TimeDifference / 604800)

		return WeeksAgo .. (WeeksAgo == 1 and " week ago" or " weeks ago")
	end
end

-- Make a given Color3 become slightly darker
function Library:MakeDarker(color: Color3, amount: number?): Color3
	local Darkness = amount or 0.25

	local H, S, V = color:ToHSV()

	V = math.clamp(V - Darkness, 0, 1)

	return Color3.fromHSV(H, S, V)
end

-- Make a given Color3 become slightly lighter
function Library:MakeLighter(color: Color3, amount: number?): Color3
	local Lightness = amount or 0.25

	local H, S, V = color:ToHSV()

	S = math.clamp(S * Lightness, 0, 1)

	return Color3.fromHSV(H, S, V)
end

-- Get length of a table (dictionary)
function Library:TableLength(tab: { any })
	local Length = 0

	for _, _ in tab do
		Length += 1
	end

	return Length
end

function Library:FilterString(player: Player, text: string): (boolean, string)
	if RunService:IsClient() then
		return false, "Unable to filter text on client"
	end

	local Success, TextObject = pcall(function()
		return TextService:FilterStringAsync(text, player.UserId)
	end)
	if not Success then
		return false, "Failed to get text object for filtering"
	end

	local SecondSuccess, FilteredMessage = pcall(function()
		return TextObject:GetNonChatStringForBroadcastAsync()
	end)
	if not SecondSuccess then
		return false, "Failed to filter string " .. FilteredMessage
	end

	return true, FilteredMessage
end

function Library:GetModelMass(model: Model): number
	local Mass = 0
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") or part:IsA("UnionOperation") then
			Mass += part:GetMass()
		end
	end

	return Mass
end

-- Return Color3 as an RGB string
function Library:GetRichTextColor(color: Color3): string
	local R = math.floor(color.R * 255)
	local G = math.floor(color.G * 255)
	local B = math.floor(color.B * 255)

	return R .. "," .. G .. "," .. B
end

-- Converts a string back into a Color3 (reverses above string back to Color3)
function Library:StringToColor3(color3String: string): Color3
	local ColorSplit = string.split(color3String, ",")
	local R = tonumber(ColorSplit[1])
	local G = tonumber(ColorSplit[2])
	local B = tonumber(ColorSplit[3])

	return Color3.fromRGB(R, G, B)
end

-- Get a random color within a set variation
function Library:GetRandomColor(color: Color3, variation: number): Color3
	local R = color.R * 255
	local G = color.G * 255
	local B = color.B * 255

	-- Generate random values within the range of -variation to +variation
	local rVariation = math.random(-variation, variation)
	local gVariation = math.random(-variation, variation)
	local bVariation = math.random(-variation, variation)

	-- Apply the variations
	R = math.clamp(R + rVariation, 0, 255)
	G = math.clamp(G + gVariation, 0, 255)
	B = math.clamp(B + bVariation, 0, 255)

	return Color3.fromRGB(R, G, B)
end

function Library:CalculateLuminance(color3: Color3): number
	return 0.299 * color3.R + 0.587 * color3.G + 0.114 * color3.B
end

function Library:IsColorDark(color3: Color3, threshold: number?): boolean
	local Luminance = self:CalculateLuminance(color3)

	threshold = threshold and threshold or 0.5

	return Luminance < threshold
end

function Library:GetRandomNumber(min: number, max: number): number
	return min + math.random() * (max - min)
end

-- Convert table to CFrame
function Library:TableToCFrame(tab): CFrame
	return CFrame.new(table.unpack(tab))
end

-- Convert CFrame to table
function Library:CFrameToTable(cFrame: CFrame, round: number?)
	local CFrameData = { cFrame:GetComponents() }

	if round then -- Round position values to a relatively low number
		for i, v in CFrameData do
			if i > 3 then
				break -- Only round positional values
			end

			local SetNumber = math.floor((v * 100) + 0.05) / 100

			CFrameData[i] = (Library:RoundTo((SetNumber * (round * 10)), round)) / (round * 10)
		end
	end

	return CFrameData
end

-- Gets angle between 2 vectors
function Library:GetAngleBetween(vectorA: Vector3, vectorB: Vector3): number
	return math.atan2(vectorA:Cross(vectorB).Magnitude, vectorA:Dot(vectorB))
end

-- Generates an shortened version of GUID
function Library:GenerateId(): string
	local GUID = string.gsub(string.upper(HttpService:GenerateGUID(false)), "[^%dA-F]", "")

	return GUID
end

-- Splits a string with capitals up
function Library:SplitTitleCaps(text: string): string
	text = string.gsub(text, "(%u)", " %1")

	return string.gsub(text, "^%s", "")
end

-- Round to nearest number
function Library:RoundTo(number: number, nearest: number): number
	return math.floor(number / nearest) * nearest
end

return Library
