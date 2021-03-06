-- enumerations in pure Luau
-- @docs https://roblox.github.io/enumerate/

local t = require(script.t)

local ALREADY_USED_NAME_ERROR = "Already used %q as a value name in enum %q."
local ALREADY_USED_VALUE_ERROR = "Already used %q as a value in enum %q."
local INVALID_MEMBER_ERROR = "%q (%s) is not a valid member of %s"

local enumeratorTuple = t.tuple(
	t.string,
	t.union(
		t.array(t.string),
		t.keys(t.string)
	)
)

local function lockTable(tab, name)
	local function protectedFunction(_, key)
		error(string.format(
			INVALID_MEMBER_ERROR,
			tostring(key),
			typeof(key),
			name
		))
	end

	return setmetatable(tab, {
		__index = protectedFunction,
		__newindex = protectedFunction,
	})
end

--[[**
	Creates a new enumeration.
	@param [t:string] enumName The unique name of the enumeration.
	@param [t:union(t:array<t:string>, t:keys<t:string>)] enumValues The values of the enumeration.
	@returns [t:userdata] a new enumeration
**--]]
local function enumerator(enumName, enumValues)
	assert(enumeratorTuple(enumName, enumValues))

	local internal = {}
	local rawValues = {}

	function internal.fromRawValue(rawValue)
		return rawValues[rawValue]
	end

	function internal.isEnumValue(value)
		if typeof(value) ~= "userdata" then
			return false
		end

		for _, enumValue in pairs(internal) do
			if enumValue == value then
				return true
			end
		end

		return false
	end

	if enumValues[1] then
		for _, valueName in ipairs(enumValues) do
			assert(valueName ~= "fromRawValue", "Cannot use 'fromRawValue' as a value")
			assert(valueName ~= "isEnumValue", "Cannot use 'isEnumValue' as a value")
			assert(internal[valueName] == nil, string.format(ALREADY_USED_NAME_ERROR, valueName, enumName))
			assert(rawValues[valueName] == nil, string.format(ALREADY_USED_VALUE_ERROR, valueName, enumName))

			local value = newproxy(true)
			local metatable = getmetatable(value)
			local valueString = string.format("%s.%s", enumName, valueName)

			function metatable.__tostring()
				return valueString
			end

			metatable.__index = lockTable({
				value = valueName,
				rawValue = function()
					return valueName
				end,
			})

			internal[valueName] = value
			rawValues[valueName] = value
		end
	else
		for valueName, rawValue in pairs(enumValues) do
			assert(valueName ~= "fromRawValue", "Cannot use 'fromRawValue' as a value")
			assert(valueName ~= "isEnumValue", "Cannot use 'isEnumValue' as a value")
			assert(internal[valueName] == nil, string.format(ALREADY_USED_NAME_ERROR, valueName, enumName))
			assert(rawValues[valueName] == nil, string.format(ALREADY_USED_VALUE_ERROR, valueName, enumName))

			local value = newproxy(true)
			local metatable = getmetatable(value)
			local valueString = string.format("%s.%s", enumName, valueName)

			function metatable.__tostring()
				return valueString
			end

			metatable.__index = lockTable({
				value = rawValue,
				rawValue = function()
					return rawValue
				end,
			})

			internal[valueName] = value
			rawValues[rawValue] = value
		end
	end

	local enum = newproxy(true)
	local metatable = getmetatable(enum)
	metatable.__index = lockTable(internal, enumName)

	function metatable.__tostring()
		return enumName
	end

	return enum
end

return enumerator