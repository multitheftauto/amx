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
		if Attachemenets[element] then return false end
		offrx = tonr(offrx) or 0
		offry = tonr(offry) or 0
		offrz = tonr(offrz) or 0
		local rotMat = calculateMatrix(offrx, offry, offrz)
		local tableSynch = { ped, bone, tonr(offx) or 0, tonr(offy) or 0, tonr(offz) or 0, rotMat }
		setElementCollisionsEnabled(element, false)
		Attachemenets[element] = tableSynch
		triggerClientEvent(root, 'sync_attachements', resourceRoot, element, tableSynch)
		return true
	end
	return false
end

function detachElementFromBone(element)
	if elm(element) then
		if Attachemenets[element] then
			Attachemenets[element] = nil
			triggerClientEvent(root, 'sync_detachements', resourceRoot, element)
			return true
		end
	end
	return false
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
			local ped, bone, mat = elmT[1], elmT[2], elmT[6]
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
			local ped, bone = elmT[1], elmT[2]
			local ox, oy, oz = elmT[3], elmT[4], elmT[5]
			local rotMat = calculateMatrix(offsetrx, offsetry, offsetrz)
			local tableSynch = { ped, bone, ox, oy, oz, rotMat }
			Attachemenets[element] = tableSynch
			triggerClientEvent(root, 'sync_pos_attachements', resourceRoot, element, tableSynch)
			return true
		end
	end
	return false
end
