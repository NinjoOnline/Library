local Library = {}

-- Add commas to break up number length (example 10000 to 10,000)
function Library:BreakNumber(num)
	local Formatted = num

	while true do
		local v
		Formatted, v = string.gsub(Formatted, "^(-?%d+)(%d%d%d)", "%1,%2")

		if v == 0 then
			break
		end
	end

	return Formatted
end

-- Return a number (example 123456789 to 123.5M)
function Library:SuffixNumber(number)
	if number == 0 then
		return 0
	end

	local Suffixes = { "K", "M", "B", "T", "Q" }

	local i = math.floor(math.log(number, 1e3))

	local v = math.pow(10, i * 3)

	return string.gsub(string.format("%.1f", number / v), "%.?0+$", "") .. (Suffixes[i] or "")
end

-- Convert number to roman numerals (example 56 to LVI)
function Library:RomanNumerals(number)
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

-- Basic lerp
function Library:Lerp(a, b, t)
	return a + (b - a) * t
end

-- Weld parts in a model to a base part
function Library:Weld(part, base)
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
function Library:Truncate(text, length)
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
function Library:ConvertTime(number, sections)
	if sections == 2 then -- M:S
		return string.format("%02i:%02i", number / 60 % 60, number % 60)
	elseif sections == 3 then -- H:M:S
		return string.format("%02i:%02i:%02i", number / 60 ^ 2, number / 60 % 60, number % 60)
	elseif sections == 4 then -- D:H:M:S
		return string.format("%d:%02d:%02d:%02d", number / 86400 % 7, number / 3600 % 24, number / 60 % 60, number % 60)
	end
end

-- Make a given Color3 become slightly darker
function Library:MakeDarker(color, amount)
	local Darkness = amount or 0.25

	local H, S, V = color:ToHSV()

	V = math.clamp(V - Darkness, 0, 1)

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

-- Return Color3 as an RGB string
function Library:GetRichTextColor(color)
	local R = math.floor(color.R * 255)
	local G = math.floor(color.G * 255)
	local B = math.floor(color.B * 255)

	return R .. "," .. G .. "," .. B
end

function Library:GetRandomNumber(min, max)
	return min + math.random() * (max - min)
end

-- Convert table to CFrame
function Library:TableToCFrame(tab)
	return CFrame.new(table.unpack(tab))
end

-- Convert CFrame to table
function Library:CFrameToTable(cFrame)
	return { select(4, cFrame:GetComponents()) }
end

-- Round to nearest number
function Library:RoundTo(number, nearest)
	return math.floor(number / nearest + 0.5) * nearest
end

return Library
