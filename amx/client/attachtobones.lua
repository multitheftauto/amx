local AttachementsTable = {}

local m_sin = math.sin
local m_cos = math.cos
local m_rad = math.rad
local elm = isElement
local tonr = tonumber
local _getElementBoneMatrix = getElementBoneMatrix
local _setElementMatrix = setElementMatrix
local _isElementOnScreen = isElementOnScreen
local _setElementPosition = setElementPosition
local boneMat, rotMat, finalMatrix = {}, {}, {}
local notOnScrenElements = {}

local boneMatOne = false
local boneMatTwo = false
local boneMatTree = false
local boneMatFor = false
local boneMatOneOne = false
local boneMatOneTwo = false
local boneMatOneTree = false
local boneMatTwoOne = false
local boneMatTwoTwo = false
local boneMatTwoTree = false
local boneMatTreeOne = false
local boneMatTreeTwo = false
local boneMatTreeTree = false
local boneMatForOne = false
local boneMatForTwo = false
local boneMatForTree = false
local rotMatOne = false
local rotMatTwo = false
local rotMatTree = false
local rotMatOneOne = false
local rotMatOneTwo = false
local rotMatOneTree = false
local rotMatTwoOne = false
local rotMatTwoTwo = false
local rotMatTwoTree = false
local rotMatTreeOne = false
local rotMatTreeTwo = false
local rotMatTreeTree = false
local TREE = false
local FOR = false
local FIVE = false

addEvent('sync_attachements', true)
addEvent('sync_detachements', true)
addEvent('sync_newcomeattachements', true)
addEvent('sync_pos_attachements', true)

local function calculateMatrix(orx, ory, orz)
	if tonr(orx) and tonr(ory) and tonr(orz) then
		local sroll, croll, spitch, cpitch, syaw, cyaw = m_sin(m_rad(orz)), m_cos(m_rad(orz)), m_sin(m_rad(ory)), m_cos(m_rad(ory)), m_sin(m_rad(orx)), m_cos(m_rad(orx))
		return {
			{ cpitch * croll - spitch * syaw * sroll, cpitch * sroll + spitch * syaw * croll, -spitch * cyaw },
			{ -cyaw * sroll, cyaw * croll, syaw },
			{ spitch * croll + cpitch * syaw * sroll, spitch * sroll - cpitch * syaw * croll, cpitch * cyaw }
		}
	end
	return false
end

addEventHandler('sync_attachements', root, function(element, data)
	if elm(element) and data then
		AttachementsTable[element] = data
	end
end)

addEventHandler('sync_detachements', root, function(element)
	if AttachementsTable[element] then
		AttachementsTable[element] = nil
		notOnScrenElements[element] = nil
	end
end)

addEventHandler('onClientResourceStart', resourceRoot, function()
	triggerServerEvent('sync_newcomeplayer', localPlayer)
end)

addEventHandler('sync_newcomeattachements', resourceRoot, function(theTable)
	if type(theTable) == 'table' then
		AttachementsTable = theTable
	end
end)

addEventHandler('sync_pos_attachements', resourceRoot, function(element, theTable)
	if type(theTable) == 'table' then
		AttachementsTable[element] = theTable
	end
end)

addEventHandler('onClientPedsProcessed', root, function()
	for element, data in next, AttachementsTable do
		local ped = data[1]
		if not elm(ped) then
			AttachementsTable[element] = nil
			notOnScrenElements[element] = nil
		elseif _isElementOnScreen(ped) then
			notOnScrenElements[element] = false
			boneMat = _getElementBoneMatrix(ped, data[2])
			rotMat = data[6]
			boneMatOne = boneMat[1]
			boneMatTwo = boneMat[2]
			boneMatTree = boneMat[3]
			boneMatFor = boneMat[4]
			boneMatOneOne = boneMatOne[1]
			boneMatOneTwo = boneMatOne[2]
			boneMatOneTree = boneMatOne[3]
			boneMatTwoOne = boneMatTwo[1]
			boneMatTwoTwo = boneMatTwo[2]
			boneMatTwoTree = boneMatTwo[3]
			boneMatTreeOne = boneMatTree[1]
			boneMatTreeTwo = boneMatTree[2]
			boneMatTreeTree = boneMatTree[3]
			boneMatForOne = boneMatFor[1]
			boneMatForTwo = boneMatFor[2]
			boneMatForTree = boneMatFor[3]
			rotMatOne = rotMat[1]
			rotMatTwo = rotMat[2]
			rotMatTree = rotMat[3]
			rotMatOneOne = rotMatOne[1]
			rotMatOneTwo = rotMatOne[2]
			rotMatOneTree = rotMatOne[3]
			rotMatTwoOne = rotMatTwo[1]
			rotMatTwoTwo = rotMatTwo[2]
			rotMatTwoTree = rotMatTwo[3]
			rotMatTreeOne = rotMatTree[1]
			rotMatTreeTwo = rotMatTree[2]
			rotMatTreeTree = rotMatTree[3]
			TREE = data[3]
			FOR = data[4]
			FIVE = data[5]
			finalMatrix = {
				{ rotMatOneOne * boneMatOneOne + rotMatOneTwo * boneMatTwoOne + rotMatOneTree * boneMatTreeOne,
				rotMatOneOne * boneMatOneTwo + rotMatOneTwo * boneMatTwoTwo + rotMatOneTree * boneMatTreeTwo,
				rotMatOneOne * boneMatOneTree + rotMatOneTwo * boneMatTwoTree + rotMatOneTree * boneMatTreeTree, 0 },
				{ rotMatTwoOne * boneMatOneOne + rotMatTwoTwo * boneMatTwoOne + rotMatTwoTree * boneMatTreeOne,
				rotMatTwoOne * boneMatOneTwo + rotMatTwoTwo * boneMatTwoTwo + rotMatTwoTree * boneMatTreeTwo,
				rotMatTwoOne * boneMatOneTree + rotMatTwoTwo * boneMatTwoTree + rotMatTwoTree * boneMatTreeTree, 0 },
				{ rotMatTreeOne * boneMatOneOne + rotMatTreeTwo * boneMatTwoOne + rotMatTreeTree * boneMatTreeOne,
				rotMatTreeOne * boneMatOneTwo + rotMatTreeTwo * boneMatTwoTwo + rotMatTreeTree * boneMatTreeTwo,
				rotMatTreeOne * boneMatOneTree + rotMatTreeTwo * boneMatTwoTree + rotMatTreeTree * boneMatTreeTree, 0 },
				{ boneMatForOne + TREE * boneMatOneOne + FOR * boneMatTwoOne + FIVE * boneMatTreeOne,
				boneMatForTwo + TREE * boneMatOneTwo + FOR * boneMatTwoTwo + FIVE * boneMatTreeTwo,
				boneMatForTree + TREE * boneMatOneTree + FOR * boneMatTwoTree + FIVE * boneMatTreeTree, 1 }
			}
			_setElementMatrix(element, finalMatrix)
		else
			if not notOnScrenElements[element] then
				_setElementPosition(element, 0, 0, -10000)
				notOnScrenElements[element] = true
			end
		end
	end
end)

addEventHandler('onClientElementDestroy', root, function()
	if AttachementsTable[source] then
		AttachementsTable[source] = nil
		notOnScrenElements[source] = nil
	end
end)

function attachElementToBone(element, ped, bone, offx, offy, offz, offrx, offry, offrz)
	if elm(element) and elm(ped) and tonr(bone) then
		if AttachementsTable[element] then return false end
		offrx = tonr(offrx) or 0
		offry = tonr(offry) or 0
		offrz = tonr(offrz) or 0
		local rotm = calculateMatrix(offrx, offry, offrz)
		AttachementsTable[element] = { ped, bone, tonr(offx) or 0, tonr(offy) or 0, tonr(offz) or 0, rotm }
		setElementCollisionsEnabled(element, false)
		return true
	end
	return false
end

function detachElementFromBone(element)
	if elm(element) then
		if AttachementsTable[element] then
			AttachementsTable[element] = nil
			notOnScrenElements[element] = nil
			return true
		end
	end
	return false
end

function isElementAttachedToBone(element)
	if elm(element) then
		if AttachementsTable[element] then
			return true
		end
	end
	return false
end

function getElementBoneAttachmentDetails(element)
	if elm(element) then
		if AttachementsTable[element] then
			return AttachementsTable[element]
		end
	end
	return false
end

function setElementBonePositionOffset(element, offsetx, offsety, offsetz)
	if elm(element) then
		local elmT = AttachementsTable[element] or nil
		if elmT then
			local ped, bone, rotM = elmT[1], elmT[2], elmT[6]
			AttachementsTable[element] = { ped, bone, offsetx, offsety, offsetz, rotM }
			return true
		end
	end
	return false
end

function setElementBoneRotationOffset(element, offsetrx, offsetry, offsetrz)
	if elm(element) then
		local elmT = AttachementsTable[element] or nil
		if elmT then
			local ped, bone = elmT[1], elmT[2]
			local ox, oy, oz = elmT[3], elmT[4], elmT[5]
			local rotm = calculateMatrix(offsetrx, offsetry, offsetrz)
			AttachementsTable[element] = { ped, bone, ox, oy, oz, rotm }
			return true
		end
	end
	return false
end
