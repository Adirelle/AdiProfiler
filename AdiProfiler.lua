--[[
AdiProfiler - Adirelle's CPU profiler broker.
Copyright 2011 Adirelle (adirelle@tagada-team.net)
All rights reserved.
--]]

local addonName, ns = ...

local addon = ns
_G[addonName] = ns

local dataobj = {
	type = 'data source',
	label = addonName,
	text = addonName,
	tocname = addonName,
}
LibStub('LibDataBroker-1.1'):NewDataObject(addonName, dataobj)

if not GetCVarBool("scriptProfile") then
	function addon:RegisterFunction() end
	function addon:RegisterFrame() end
	return
end

local functions = {}
local frames = {}

function addon:RegisterFunction(func, name)
	assert(type(func) == "function")
	assert(type(name) == "string")
	functions[func] = name
end

function addon:RegisterFrame(frame, name)
	assert(type(frame) == "table" and type(frame[0]) == "userdata")
	name = name or frame:GetName()
	assert(type(name) == "string")
	frames[frame] = name
end

local names = {}
local usages = {}
local totalUsages = {}
local calls = {}
local totalCalls = {}

local function SortByTotalUsage(a, b)
	return totalUsages[b] < totalUsages[a]
end

local function AddData(tooltip, items, fetchFunc, total)
	wipe(names)
	wipe(usages)
	wipe(totalUsages)
	wipe(calls)
	wipe(totalCalls)
	for ref, name in pairs(items) do
		local usage, numCalls = fetchFunc(ref, false)
		local totalUsage, totatNumCalls = fetchFunc(ref, true)
		if not usages[name] then
			tinsert(names, name)
			usages[name] = usage
			totalUsages[name] = totalUsage
			calls[name] = numCalls
			totalCalls[name] = totatNumCalls
		else
			usages[name] = usages[name] + usage
			totalUsages[name] = totalUsages[name] + totalUsage
			calls[name] = calls[name] + numCalls
			totalCalls[name] = totalCalls[name] + totatNumCalls
		end
	end
	table.sort(names, SortByTotalUsage)
	for i, name in ipairs(names) do
		tooltip:AddDoubleLine(name, format("|cffffffff%d:|r %.3f%% (|cffffffff%d:|r %.3f%%)", 
			totalCalls[name],
			totalUsages[name] / total * 100,
			calls[name],
			usages[name] / total * 100
		))
	end
end

function dataobj.OnTooltipShow(tooltip)
	tooltip = tooltip or GameTooltip
	tooltip:ClearLines()
	
	UpdateAddOnCPUUsage()

	if next(functions) then
		tooltip:AddLine("Functions", 1, 1, 1)
		AddData(tooltip, functions, GetFunctionCPUUsage, GetScriptCPUUsage())
	end
	
	if next(frames) then
		local total = GetFrameCPUUsage(UIParent, "true")
		tooltip:AddLine("Frames", 1, 1, 1)
		AddData(tooltip, frames, GetFrameCPUUsage, total)
	end
	
	tooltip:Show()
end
