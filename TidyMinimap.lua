--[[
  TidyMinimap 0.8 - Tidy up the buttons around the minimap!

  Copyright (c) 2007-2010 Christopher Rosell
  All rights reserved.

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are
  met:

      * Redistributions of source code must retain the above copyright
        notice, this list of conditions and the following disclaimer.
      * Redistributions in binary form must reproduce the above
        copyright notice, this list of conditions and the following
        disclaimer in the documentation and/or other materials provided
        with the distribution.
      * Neither the name of Christopher Rosell nor the names of its
        contributors may be used to endorse or promote products derived
        from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
  A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
  OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--]]

local g = getfenv(0)

local strfind = strfind
local strlower = strlower
local strsplit = strsplit

local anchors = {
	topleft	 = 'TOPLEFT#TOPLEFT#3#0',
	topright = 'TOPRIGHT#TOPRIGHT#-3#0',
	left	 = 'RIGHT#LEFT#5#0',
	right	 = 'LEFT#RIGHT#5#0',
	down	 = 'TOP#BOTTOM#0#4',
	up		 = 'BOTTOM#TOP#0#4',
}

local notbuttons = {
	['TimeManagerClockButton'] = true,
	['MinimapZoomIn'] = true,
	['MinimapZoomOut'] = true,
	['GameTimeFrame'] = true,
	['MiniMapTrackingButton'] = true,
	['MiniMapTracking'] = true,
}

local addon = CreateFrame('Frame', 'TidyMinimap', UIParent)

local isMinimapButton = function(frame)
	if frame and frame:GetObjectType() == 'Button' and frame:GetNumRegions() >= 3 then
		return true
	end
end

local hideBorder = function(...)
	for i = 1, select('#', ...) do
		local region = select(i, ...)
		if region.GetTexture then
			local texture = region:GetTexture()
			if texture and strfind(strlower(texture), 'border') then
				region:Hide()
			end
		end
	end
end

function addon:findButtons(frame)
	for i, child in ipairs({frame:GetChildren()}) do
		local name = child:GetName()
		if isMinimapButton(child) and not self.settings.skip[name] and not notbuttons[name] then
			self:addButton(child)
		else
			self:findButtons(child)
		end
	end
end

function addon:findSpecialButtons()
	for button, get in pairs(self.settings.special) do
		if g[button] and get == true then
			self:addButton(g[button])
		end
	end
end

function addon:addButton(button)
	if button:GetParent() ~= self then
		button:SetParent(self)
	end
end

function addon:scan()
	self:findButtons(Minimap)
	self:findSpecialButtons()
	self:updatePositions()
end

-- Delay the scan call with a onupdate handler
local time = 0
local onUpdate = function(self, elapsed)
	time = time + elapsed
	if time > 5 then
		time = 0
		self:scan()
		self:SetScript('OnUpdate', nil)
	end
end

function addon:delayedScan()
	self:SetScript('OnUpdate', onUpdate)
end

function addon:nudgeMinimap()
	if MinimapCluster:IsVisible() then
		-- Only nudge if the minimap is in it's default pos
		local p1, parent, p2, x, y = MinimapCluster:GetPoint(0)
		if p1 == 'TOPRIGHT' and parent == UIParent and p2 == 'TOPRIGHT' and x == 0 and y == 0 then
			MinimapCluster:ClearAllPoints()
			MinimapCluster:SetPoint(p1, parent, p2, x, y-(self:GetHeight()*self.settings.layout.scale))
		end
	end
end

function addon:updatePositions()
	local layout = self.settings.layout
	self:ClearAllPoints()
	self:SetPoint(strsplit('#', layout.pos))
	self:SetWidth(0)
	self:SetHeight(0)
	self:SetScale(layout.scale)

	local prev = self
	for i, button in ipairs({self:GetChildren()}) do
		if button:IsVisible() then

			-- Position the button
			local p1, p2, x, y = strsplit('#', (prev == self and anchors[layout.anchor]) or anchors[layout.grow])
			button:ClearAllPoints()
			button:SetPoint(p1, prev, p2, x, y)

			-- Stop it from being draggable
			button:SetScript('OnDragStart', nil)
			button:SetScript('OnDragStop', nil)

			-- Hide the border
			if not layout.borders then
				hideBorder(button:GetRegions())
			end

			-- Update width and height
			self:SetWidth(self:GetWidth() + button:GetWidth())
			self:SetHeight(((button:GetHeight() > self:GetHeight()) and button:GetHeight()) or self:GetHeight())

			prev = button
		end
	end

	if layout.nudgeminimap then self:nudgeMinimap() end
end

local printtm = function(...)
	print('|cFF33FF99TidyMinimap|r: '..string.format(...))
end

function addon:enable(settings)
	g['SLASH_TIDY1'] = '/tidy'
	function SlashCmdList.TIDY(cmdstr)
		if #cmdstr > 0 then
			local cmd = cmdstr:match'^(%w+)'
			if cmd == 'scan' then
				printtm'Scanning for minimap buttons'
				self:scan()
			elseif cmd == 'name' then
				local f = GetMouseFocus():GetName()
				if f then
					printtm('You are hovering: %s', f)
				else
					printtm'The frame you are hovering does not have a name'
				end
			elseif cmd == 'help' then
				printtm'Valid commands are:'
				printtm'scan: Force TidyMinimap to look for minimap buttons'
				printtm'name: Prints the name of the frame you\'re currently hovering'
				printtm'help: This help message'
			else
				SlashCmdList.TIDY'help'
			end
		else
			SlashCmdList.TIDY'name'
		end
	end

	self.settings = settings
	self:SetScript('OnEvent', self.delayedScan)
	self:RegisterEvent'PLAYER_LOGIN'
	self:RegisterEvent'ADDON_LOADED'
	self:RegisterEvent'UPDATE_BATTLEFIELD_STATUS'
end
