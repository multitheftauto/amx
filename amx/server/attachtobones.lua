local Attachemenets = {}

local elm = isElement
local m_rad = math.rad
local tonr = tonumber
local m_sin = math.sin
local m_cos = math.cos

addEvent('sync_newcomeplayer', true)

local function calculateMatrix(orx, ory, orz)
	if tonr(orx) and tonr(ory) and tonr(orz) then
		local sroll, croll, spitch, cpitch, syaw, cyaw = m_sin(m_rad(orz)), m_cos(m_rad(orz)), m_sin(m_rad(ory)), m_cos(m_rad(ory)), m_sin(m_rad(orx)), m_cos(m_rad(orx))
		local rotMat = {
			{ sroll * spitch * syaw + croll * cyaw, sroll * cpitch, sroll * spitch * cyaw - croll * syaw },
			{ croll * spitch * syaw - sroll * cyaw, croll * cpitch, croll * spitch * cyaw + sroll * syaw },
			{ cpitch * syaw, -spitch, cpitch * cyaw }
		}
		return rotMat
	end
	return false
end

function attachElementToBone(element, ped, bone, offx, offy, offz, offrx, offry, offrz)
	if elm(element) and elm(ped) and tonr(bone) then
		if isElementAttachedToBone(element) then return false end
		local offrx = offrx or 0
		local offry = offry or 0
		local offrz = offrz or 0
		local rotMat = calculateMatrix(offrx, offry, offrz)
		local table = { ped, bone, tonr(offx) or 0, tonr(offy) or 0, tonr(offz) or 0, rotMat }
		setElementCollisionsEnabled(element, false)
		Attachemenets[element] = table
		triggerClientEvent(root, 'sync_attachements', resourceRoot, element, table)
	end
end

function detachElementFromBone(element)
	if elm(element) then
		if Attachemenets[element] then
			Attachemenets[element] = nil
			triggerClientEvent(root, 'sync_detachements', resourceRoot, element)
		end
	end
end

addEventHandler('onElementDestroy', root, function()
	if Attachemenets[source] and getResourceState(resource) ~= 'stopping' then
		Attachemenets[source] = nil
		triggerClientEvent(root, 'sync_detachements', resourceRoot, source)
	end
end)

addEventHandler('sync_newcomeplayer', root, function()
	if client then
		triggerClientEvent(client, 'sync_newcomeattachements', resourceRoot, Attachemenets)
	end
end)

function isElementAttachedToBone(element)
	if elm(element) then
		if Attachemenets[element] then
			return true
		end
	end
	return false
end

function getElementBoneAttachmentDetails(element)
	if elm(element) then
		if Attachemenets[element] then
			return Attachemenets[element]
		end
	end
	return false
end

function setElementBonePositionOffset(element, offsetx, offsety, offsetz)
	if elm(element) then
		local elmT = Attachemenets[element] or nil
		if elmT then
			local ped = elmT[1]
			local bone = elmT[2]
			local mat = elmT[6]
			local tableSynch = { ped, bone, offsetx, offsety, offsetz, mat }
			Attachemenets[element] = tableSynch
			triggerClientEvent(root, 'sync_pos_attachements', resourceRoot, element, tableSynch)
			return true
		end
	end
	return false
end

function setElementBoneRotationOffset(element, offsetrx, offsetry, offsetrz)
	if elm(element) then
		local elmT = Attachemenets[element] or nil
		if elmT then
			local ped = elmT[1]
			local bone = elmT[2]
			local ox = elmT[3]
			local oy = elmT[4]
			local oz = elmT[5]
			local rotMat = calculateMatrix(offsetrx, offsetry, offsetrz)
			local tableSynch = { ped, bone, ox, oy, oz, rotMat }
			Attachemenets[element] = tableSynch
			triggerClientEvent(root, 'sync_pos_attachements', resourceRoot, element, tableSynch)
			return true
		end
	end
	return false
end