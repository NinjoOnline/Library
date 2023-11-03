local Library = {}

local HttpService = game:GetService("HttpService")

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
		return number
	end

	local Suffixes =
		{ "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc", "Ud", "Dd", "Td", "Qad", "Qu", "Sd", "St" }

	local i = math.floor(math.log(number, 1e3))
	local v = 10 ^ (i * 3)

	local FormatNumber = string.format("%." .. (3 * i) .. "f", number / v)
	local Shortened = string.sub(FormatNumber, 1, #FormatNumber - (3 * i - 2))
	local DecimalPlace = string.find(Shortened, "%p")
	if DecimalPlace and tonumber(string.sub(Shortened, DecimalPlace + 1)) == 0 then -- 0, round down
		Shortened = string.sub(Shortened, 1, DecimalPlace - 1)
	end

	return Shortened .. Suffixes[i], Suffixes
end

-- Convert number to roman numerals (example 56 to LVI)
function Library:RomanNumerals(number: number): string
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
function Library:ConvertTime(number: number, showTimeMetrics: boolean?): string
	local Seconds = number % 60
	local Minutes = math.floor(number / 60) % 60
	local Hours = math.floor(number / 3600) % 24
	local Days = math.floor(number / 86400)

	local SECONDS_IN_DAY = 24 * 60 * 60
	local SECONDS_IN_HOUR = 60 * 60

	if showTimeMetrics then -- Display time as Dd Hh Mm Ss
		if number >= SECONDS_IN_DAY then
			return string.format("%dd %dh %dm %ds", Days, Hours, Minutes, Seconds)
		elseif number >= SECONDS_IN_HOUR then
			return string.format("%dh %dm %ds", Hours, Minutes, Seconds)
		elseif number >= 60 then
			return string.format("%dm %ds", Minutes, Seconds)
		else
			return string.format("%ds", Seconds)
		end
	else -- Display time as D:H:M:S
		if number >= SECONDS_IN_DAY then
			return string.format("%02d:%02d:%02d:%02d", Days, Hours, Minutes, Seconds)
		elseif number >= SECONDS_IN_HOUR then
			return string.format("%02d:%02d:%02d", Hours, Minutes, Seconds)
		else
			return string.format("%02d:%02d", Minutes, Seconds)
		end
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
function Library:TableLength(tab)
	local Length = 0

	for _, _ in tab do
		Length += 1
	end

	return Length
end

function Library:GetModelMass(model: Model): number
	local Mass = 0
	for _, part in model:GetChildren() do
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
