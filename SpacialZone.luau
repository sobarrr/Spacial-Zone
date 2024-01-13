--------------------------------------------------------------------------------
--              		 Spacial Zone Module System                               --
-- This is a zone class which can be used for hitboxes, safezones, and more   --
-- This module uses spacial queries to detect when a obj enters or exits      -- 
--                                                                            --
-- API:                                                                       --
--   local SpacialZone = require(MODULE PATH)                                 --
--   local NewZone = SpacialZone.new()                                        --
--   NewZone.Touched:Connect(function(hit)                                    --
--   	 print(hit.Name)                                                        --
--   end)                                                                     --
--                                                                            --
--   Hitbox.PlayerExited:Connect(function(plr)                                --
--		 print(plr.Name)                                                        --
--	 end)                                  							     	                --
--                                                    						            --
--                                      									                    --
--                                                                            --
-- Authors:                                                                   --
--   bolzpy | 11/01/2024                        	      					            --
--------------------------------------------------------------------------------

--!nonstrict
local module = {}
module.__index = module

local Janitor = require(script.Janitor)
local FastSignal  = require(script.FastSignal)


local PlayerService = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local Zones = {}

export type Zone = {
	_Janitor		: any,
	Container		: BasePart,
	_Bounds			: BasePart | nil,
	Locked			: boolean,
	Touched			: RBXScriptSignal,
	PartEntered		: RBXScriptSignal,
	PartExited		: RBXScriptSignal,
	PlayerEntered	: RBXScriptSignal,
	PlayerExited	: RBXScriptSignal,
	ZoneID			: string
}

function module:GetZones()
	return Zones
end


function module.new(container: BasePart)
	local Zone : Zone = {}
	local Players = {}
	
	setmetatable(Zone, module)
	
	local Janitor = Janitor.new()
	
	
	local Touched: any = 		FastSignal.new()
	local PartEntered: any = 	FastSignal.new()
	local PartExited: any = 	FastSignal.new()
	local PlayerEntered: any =	FastSignal.new()
	local PlayerExited: any = 	FastSignal.new()
	
	Zone.Container = container
	Zone.Touched = Touched
	Zone.PartEntered = PartEntered
	Zone.PartExited = PartExited
	Zone.PlayerEntered = PlayerEntered
	Zone.PlayerExited = PlayerExited
	Zone.Locked = false
	Zone.ZoneID = HttpService:GenerateGUID()
	Zone._Janitor = Janitor
	Zone._Bounds = nil
	
	local updated = Janitor:Add(
		FastSignal.new()
	)
	
	local triggerTypes = {
		"Touched",
		"Player"
	}
	
	local triggerEvents = {
		"",
		"Entered",
		"Exited"
	}
	
	table.insert(Zones, Zone)
	local lastLookup = {}
	local lastIter = {}
	
	local partLastLookup = {}
	local partLastIter = {}
	RunService.Heartbeat:Connect(function()
		if Zone.Locked then return end
		local playersIter = {}
		local playersLookup = {}
		local partLookup = {}
		local partIter = {}
		
		local parts = workspace:GetPartsInPart(Zone.Container, OverlapParams.new())
		
		for _, part in parts do
			local player = PlayerService:GetPlayerFromCharacter(part.Parent)

			if not player then continue end
			
			if not partLastLookup[part] then
				PartEntered:Fire(part)
			end
			
			if not lastLookup[player] then
				PlayerEntered:Fire(player)
			end
			
			table.insert(playersIter, player)
			table.insert(partIter, part)
			
			playersLookup[player] = true
			partLookup[part] = true
		end
		
		for _, player in lastIter do
			if playersLookup[player] then continue end
			PlayerExited:Fire(player)
		end
		
		for _, part in partLastIter do
			if partLookup[part] then continue end
			PartExited:Fire(part)
		end

		lastLookup, lastIter = playersLookup, playersIter
		partLastLookup, partLastIter = partLookup, partIter
	end)
	
	return Zone
end

function module.fromRegion(cframe, size)
	local container = Instance.new("Part")
	container.CFrame = cframe
	container.Size = size

	return module.new(container)
end

function module:Lock()
	self.Locked = true
end

function module:Unlock()
	self.Locked = false
end

function module:DisplayBounds()
	local NewBox: BasePart = Instance.new("Part")
	NewBox.Transparency = 0.5
	NewBox.Color = Color3.new(1)
	NewBox.Anchored = true
	NewBox.CanCollide = false
	NewBox.CFrame = self.Container.CFrame
	NewBox.Size = self.Container.Size
	NewBox.Name = `BoundDisplay[{self.ZoneID}]`
	NewBox.TopSurface, NewBox.BottomSurface=Enum.SurfaceType.Smooth,Enum.SurfaceType.Smooth
	NewBox.Parent = workspace
	self._Bounds = NewBox
	
	self._Janitor:Add(NewBox)
end

function module:UndisplayBounds()
	self._Bounds:Destroy()
end

function module:findPlayer(player: Player)
	for _, v in pairs(workspace:GetPartsInPart(self.Container)) do
		local Player = PlayerService:GetPlayerFromCharacter(v.Parent)
		
		if Player then
			return Player
		else
			return nil
		end
	end
end

function module:GetPlayers()
	local Players = {}
	for _, part in pairs(workspace:GetPartsInPart(self.Container)) do
		local Player = PlayerService:GetPlayerFromCharacter(part.Parent)
		
		if not Player then return end
		Players[Player] = Player
	end
end

function module:GetCharacters()
	local Characters = {}
	for _, part in pairs(workspace:GetPartsInPart(self.Container)) do
		local Humanoid = part.Parent:FindFirstChild("Humanoid")
		local Character = part.Parent
		if Humanoid then 
			Characters[Character] = Character
		end
	end
end

function module:GetZoneFromID(GUID: string)
	for _, zone in pairs(Zones) do
		if zone.ZoneID == GUID then
			return zone
		end
	end
end

function module:GetID(zone: Zone | nil)
	if zone then
		return zone.ZoneID
	else
		return self.ZoneID
	end
end

function module:Delete()
	self._Janitor:Destroy()
end

return module
