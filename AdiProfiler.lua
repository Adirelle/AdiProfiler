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
local usage = {}
local calls = {}
local totalUsage = {}
local totalCalls = {}

local function Sort(a, b)
	return (usage[b] / calls[b]) < (usage[a] / calls[a])
end

local function AddData(tooltip, items, fetchFunc, total)
	wipe(names)
	wipe(usage)
	wipe(totalUsage)
	wipe(calls)
	wipe(totalCalls)
	for ref, name in pairs(items) do
		local refUsage, numCalls = fetchFunc(ref, false)
		local refTotalUsage, totatNumCalls = fetchFunc(ref, true)
		if numCalls > 0 or totatNumCalls > 0 then
			if not usage[name] then
				tinsert(names, name)
				usage[name] = refUsage
				totalUsage[name] = refTotalUsage
				calls[name] = numCalls
				totalCalls[name] = totatNumCalls
			else
				usage[name] = usage[name] + refUsage
				totalUsage[name] = totalUsage[name] + refTotalUsage
				calls[name] = calls[name] + numCalls
				totalCalls[name] = totalCalls[name] + totatNumCalls
			end
		end
	end
	table.sort(names, Sort)
	for i = 1, min(#names, 15) do
		local name = names[i]
		local calls, usage = calls[name], usage[name]
		tooltip:AddDoubleLine(name, format("%d || %.1f || %.3f",  calls, usage, usage / calls))
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
	
	--[[
	if next(frames) then
		local total = GetFrameCPUUsage(UIParent, "true")
		tooltip:AddLine("Frames", 1, 1, 1)
		AddData(tooltip, frames, GetFrameCPUUsage, total)
	end
	--]]

	tooltip:Show()
end