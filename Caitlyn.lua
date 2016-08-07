if myHero.charName ~= "Caitlyn" or not FileExist(LIB_PATH .. "FHPrediction.lua") then return end

require 'FHPrediction'
local version = 0.1
local shouldcombo = false
local lastwuse = 0
local rrange = {2000, 2500, 3000}
local MyESpell = {
	range = 750,
	speed = 2000,
	radius = 90,
	delay = 0.25,
	collision = {
	[CollisionObjectTypes.Champion] = false, 
	[CollisionObjectTypes.Minion] = true, 
	[CollisionObjectTypes.YasuoWall] = true
	},
	type = SkillShotType.SkillshotMissileLine,
}
local MyWSpell = {
	range = 800,
	speed = 2000,
	radius = 75,
	delay = 0.25,
	collision = {
	[CollisionObjectTypes.Champion] = false, 
	[CollisionObjectTypes.Minion] = false, 
	[CollisionObjectTypes.YasuoWall] = false
	},
	type = SkillShotType.SkillshotCircle,
}

function LoadOrbwalk()
	if _G.AutoCarry and _G.Reborn_Initialised then
		MenuCait.Orbwalker:addParam("Info", "SAC Detected", SCRIPT_PARAM_INFO, "")
	elseif _G.Reborn_Loaded then
		DelayAction(function() LoadOrbwalk() end, 1)
	elseif _G.MMA_IsLoaded then
		MenuCait.Orbwalker:addParam("Info", "MMA Detected", SCRIPT_PARAM_INFO, "")
	elseif _G._Pewalk then
		MenuCait.Orbwalker:addParam("Info", "Pewalk Detected", SCRIPT_PARAM_INFO, "")
	elseif FileExist(LIB_PATH .. "SxOrbWalk.lua") then
		require "SxOrbWalk"
		SxOrb:LoadToMenu(MenuCait.Orbwalker)
	end
end

function OnLoad()
	Updater()
	DelayAction(function()LoadOrbwalk() end, 2)
	MenuCait = scriptConfig("CaitlynCombo: Caitlyn", "Cait")
	EnemyMinions = minionManager(MINION_ENEMY, 1300, myHero, MINION_SORT_MAXHEALTH_DEC)
	TargetSelectorR = TargetSelector(TARGET_LESS_CAST_PRIORITY, 2000, DAMAGE_PHYSICAL, false)
	TargetSelectorR:SetConditional(function(h) return h.health <  myHero:CalcMagicDamage(h, (25 + (myHero:GetSpellData(SPELL_4).level * 225) + (myHero.addDamage * 2))) end)
	TargetSelector = TargetSelector(TARGET_LESS_CAST_PRIORITY, 1300, DAMAGE_PHYSICAL, false)
	TargetSelector.name = "CaitlynCombo"
	MenuCait:addSubMenu("[Cait]: Orbwalker", "Orbwalker")
	MenuCait.Orbwalker:addTS(TargetSelector)
	MenuCait:addSubMenu("[Cait]: Combo Settings", "combo")
	MenuCait.combo:addParam("ComboUseQ", "Use (Q)", SCRIPT_PARAM_ONOFF, true)
	MenuCait.combo:addParam("ComboUseW", "Use (W)", SCRIPT_PARAM_ONOFF, true)
	MenuCait.combo:addParam("ComboUseE", "Use (E)", SCRIPT_PARAM_ONOFF, true)
	MenuCait.combo:addParam("ComboUseR", "Use (R)", SCRIPT_PARAM_ONOFF, true)
	MenuCait:addSubMenu("[Cait]: Harass Settings", "harass")
	MenuCait.harass:addParam("HarassUseQ", "Use (Q)", SCRIPT_PARAM_ONOFF, true)
	MenuCait.harass:addParam("HarassQMana", "Min. Mana % To Use (Q)", SCRIPT_PARAM_SLICE, 45, 0, 100, 0)
	MenuCait:addSubMenu("[Cait]: Clear Settings", "clear")
	MenuCait.clear:addParam("ClearUseQ", "Use (Q)", SCRIPT_PARAM_ONOFF, true)
	MenuCait.clear:addParam("ClearQMana", "Min. Mana % To Use (Q)", SCRIPT_PARAM_SLICE, 60, 0, 100, 0)
	MenuCait:addSubMenu("[Cait]: Draw Settings", "draw")
	MenuCait.draw:addParam("DrawQ", "Draw (Q) Range", SCRIPT_PARAM_ONOFF, true)
	MenuCait.draw:addParam("DrawW", "Draw (W) Range", SCRIPT_PARAM_ONOFF, true)
	MenuCait.draw:addParam("DrawE", "Draw (E) Range", SCRIPT_PARAM_ONOFF, true)
	MenuCait.draw:addParam("DrawR", "Draw (R) Range", SCRIPT_PARAM_ONOFF, true)
end

function OnTick()
	TargetSelector:update()
	if TargetSelectorR.range ~= rrange[myHero:GetSpellData(_R).level] then
		TargetSelectorR.range = rrange[myHero:GetSpellData(_R).level]
	end
	if myHero:CanUseSpell(_R) == READY and MenuCait.combo.ComboUseR then
		TargetSelectorR:update()
		if ValidTarget(TargetSelectorR.target) and CountEnemyHeroInRange(myHero.range+350) == 0 then
			CastSpell(_R, TargetSelectorR.target)
		end
	end
	if myHero:CanUseSpell(_Q) == READY and myHero:CanUseSpell(_W) == READY and myHero:CanUseSpell(_E) == READY and not shouldcombo then
		shouldcombo = true
	end
	if (not ComboActive() or ComboActive()) and shouldcombo and (not myHero:CanUseSpell(_Q) == READY or not myHero:CanUseSpell(_W) == READY or not myHero:CanUseSpell(_E) == READY) then
		shouldcombo = false
	end
	if ComboActive() and ValidTarget(TargetSelector.target) then
		if shouldcombo and MenuCait.combo.ComboUseQ and MenuCait.combo.ComboUseW and MenuCait.combo.ComboUseE then
			local pos, hc, info = FHPrediction.GetPrediction(MyESpell, TargetSelector.target)
			local pos2, hc2, info2 = FHPrediction.GetPrediction(MyWSpell, TargetSelector.target)
			if pos and hc >= 1 and info.collision and info.collision.amount == 0 and pos2 and GetDistance(TargetSelector.target) <= MyESpell.range - 200 then
				if lastwuse + 3 < os.clock() then
					CastSpell(_W, pos2.x, pos2.z)
				end		
				CastSpell(_E, pos.x, pos.z)	
				DelayAction(function()
					if ValidTarget(TargetSelector.target) then
						CastSpell(_Q, TargetSelector.target.x, TargetSelector.target.z)
					end
				end, 0.1)
			elseif info.collision and info.collision.amount ~= 0 then
				if GetDistance(TargetSelector.target) > myHero.range + 65 and GetDistance(TargetSelector.target) <= 1300 then
					local pos, hc, info = FHPrediction.GetPrediction("Q", TargetSelector.target)
					if pos and hc >= 1.1 then
						CastSpell(_Q, pos.x, pos.z)
					end
				end
			end
		end
		if not shouldcombo and ValidTarget(TargetSelector.target) then
			if MenuCait.combo.ComboUseQ and myHero:CanUseSpell(_Q) == READY and GetDistance(TargetSelector.target) > myHero.range + 65 and GetDistance(TargetSelector.target) <= 1300 then
				local pos, hc, info = FHPrediction.GetPrediction("Q", TargetSelector.target)
				if pos and hc >= 1.1 then
					CastSpell(_Q, pos.x, pos.z)
				end
			end
			if MenuCait.combo.ComboUseW and GetDistance(TargetSelector.target) <= MyWSpell.range and myHero:CanUseSpell(_W) == READY and lastwuse + 3 < os.clock() then
				local pos, hc, info = FHPrediction.GetPrediction(MyWSpell, TargetSelector.target)
				if pos and hc >= 1 then
					CastSpell(_W, pos.x, pos.z)
				end
			end
			if MenuCait.combo.ComboUseE and GetDistance(TargetSelector.target) <= MyESpell.range and myHero:CanUseSpell(_E) == READY then
				local pos, hc, info = FHPrediction.GetPrediction(MyESpell, TargetSelector.target)
				if pos and hc >= 1.1 and info.collision and info.collision.amount == 0 then
					CastSpell(_E, pos.x, pos.z)
				end
			end
		end
	end
	if HarassActive() and ValidTarget(TargetSelector.target) and myHero:CanUseSpell(_Q) == READY and MenuCait.harass.HarassUseQ and ManaPC() >= MenuCait.harass.HarassQMana then
		local pos, hc, info = FHPrediction.GetPrediction("Q", TargetSelector.target)
		if pos and hc >= 1.1 and GetDistance(TargetSelector.target) > myHero.range + 65 and GetDistance(TargetSelector.target) <= 1300 then
			CastSpell(_Q, pos.x, pos.z)
		end
	end
	if FarmActive() and MenuCait.clear.ClearUseQ and myHero:CanUseSpell(_Q) == READY and ManaPC() >= MenuCait.clear.ClearQMana then
		EnemyMinions:update()
		local Pos, Hit = GetBestLineFarmPosition(1300, 65, EnemyMinions.objects)
		if Pos ~= nil and Hit >= 4 then		
			CastSpell(_Q, Pos.x, Pos.z)
		end
	end
end

function OnDraw()
	if MenuCait.draw.DrawQ and myHero:CanUseSpell(_Q) == READY then
		DrawCircle3D(myHero.x, myHero.y, myHero.z, 1300, 1, ARGB(105,255,255,255), 50)
	end
	if MenuCait.draw.DrawW and myHero:CanUseSpell(_W) == READY then
		DrawCircle3D(myHero.x, myHero.y, myHero.z, MyWSpell.range, 1, ARGB(105,255,255,255), 50)
	end
	if MenuCait.draw.DrawE and myHero:CanUseSpell(_E) == READY then
		DrawCircle3D(myHero.x, myHero.y, myHero.z, MyESpell.range, 1, ARGB(105,255,255,255), 50)
	end
	if MenuCait.draw.DrawR and myHero:CanUseSpell(_R) == READY then
		DrawCircleMinimap(myHero.x, myHero.y, myHero.z, TargetSelectorR.range)
	end
end

function OnProcessSpell(unit, spell)
	if unit and unit.isMe and spell and spell.name == 'CaitlynYordleTrap' then
		lastwuse = os.clock()
	end
end

function OnApplyBuff(unit, source, buff)
	if unit and source and buff and unit.isMe and source.type == myHero.type and source.team ~= myHero.team and (buff.name == 'caitlynyordletrapinternal' or buff.name == 'caitlynyordletrapsight') then
		ResetAA()
	end
end

function ManaPC()
	return ((myHero.mana/myHero.maxMana)*100)
end

function GetBestLineFarmPosition(range, width, objects)
    local BestPos 
    local BestHit = 0
    for i, object in ipairs(objects) do
        local EndPos = Vector(myHero) + range * (Vector(object) - Vector(myHero)):normalized()
        local hit = CountObjectsOnLineSegment(myHero, EndPos, width, objects)
        if hit > BestHit then
            BestHit = hit
            BestPos = object
            if BestHit == #objects then
               break
            end
         end
    end
    return BestPos, BestHit
end

function CountObjectsOnLineSegment(StartPos, EndPos, width, objects)
    local n = 0
    for i, object in ipairs(objects) do
        local pointSegment, pointLine, isOnSegment = VectorPointProjectionOnLineSegment(StartPos, EndPos, object)
        if isOnSegment and GetDistanceSqr(pointSegment, object) < width * width and GetDistanceSqr(StartPos, EndPos) > GetDistanceSqr(StartPos, object) then
            n = n + 1
        end
    end
    return n
end

function ComboActive()
	if _G.SxOrb and SxOrb:GetMode() == 1 then
		return true
	elseif _G.AutoCarry and _G.AutoCarry.Keys.AutoCarry then
		return true
	elseif _G.MMA_IsLoaded and _G.MMA_IsOrbwalking() then
		return true
	elseif _Pewalk and _Pewalk.GetActiveMode()["Carry"] then
		return true
	end
end

function HarassActive()
	if _G.SxOrb and SxOrb:GetMode() == 2 then
		return true
	elseif _G.AutoCarry and _G.AutoCarry.Keys.MixedMode then
		return true
	elseif _G.MMA_IsLoaded and _G.MMA_IsDualCarrying() then
		return true
	elseif _Pewalk and _Pewalk.GetActiveMode()["Mixed"] then
		return true
	end
end

function FarmActive()
	if _G.SxOrb and SxOrb:GetMode() == 3 then
		return true
	elseif _G.AutoCarry and _G.AutoCarry.Keys.LaneClear then
		return true
	elseif _G.MMA_IsLoaded and _G.MMA_IsLaneClearing() then
		return true
	elseif _Pewalk and _Pewalk.GetActiveMode()["LaneClear"] then
		return true
	end
end

function ResetAA()
	if _G.SxOrb then
		SxOrb:ResetAA()
	elseif _G.AutoCarry then
		_G.AutoCarry.Orbwalker:ResetAttackTimer()
	elseif _G.MMA_IsLoaded then
		_G.MMA_ResetAutoAttack()
	end
end


local function AutoupdaterMsg(msg) print("<font color=\"#6699ff\"><b>CaitlynCombo:</b></font> <font color=\"#FFFFFF\">"..msg..".</font>") end
class "UpdaterClas"
function UpdaterClas:__init(LocalVersion,UseHttps, Host, VersionPath, ScriptPath, SavePath, CallbackUpdate, CallbackNoUpdate, CallbackNewVersion,CallbackError)
    self.LocalVersion = LocalVersion
    self.Host = Host
    self.VersionPath = '/BoL/TCPUpdater/GetScript'..(UseHttps and '5' or '6')..'.php?script='..self:Base64Encode(self.Host..VersionPath)..'&rand='..math.random(99999999)
    self.ScriptPath = '/BoL/TCPUpdater/GetScript'..(UseHttps and '5' or '6')..'.php?script='..self:Base64Encode(self.Host..ScriptPath)..'&rand='..math.random(99999999)
    self.SavePath = SavePath
    self.CallbackUpdate = CallbackUpdate
    self.CallbackNoUpdate = CallbackNoUpdate
    self.CallbackNewVersion = CallbackNewVersion
    self.CallbackError = CallbackError
    self:CreateSocket(self.VersionPath)
    self.DownloadStatus = 'Connect to Server for VersionInfo'
    AddTickCallback(function() self:GetOnlineVersion() end)
end

function UpdaterClas:print(str)
    print('<font color="#FFFFFF">'..clock()..': '..str)
end

function UpdaterClas:OnDraw()
    if self.DownloadStatus ~= 'Downloading Script (100%)' and self.DownloadStatus ~= 'Downloading VersionInfo (100%)'then
        DrawText('Download Status: '..(self.DownloadStatus or 'Unknown'),50,10,50,ARGB(0xFF,0xFF,0xFF,0xFF))
    end
end

function UpdaterClas:CreateSocket(url)
    if not self.LuaSocket then
        self.LuaSocket = require("socket")
    else
        self.Socket:close()
        self.Socket = nil
        self.Size = nil
        self.RecvStarted = false
    end
    self.LuaSocket = require("socket")
    self.Socket = self.LuaSocket.tcp()
    self.Socket:settimeout(0, 'b')
    self.Socket:settimeout(99999999, 't')
    self.Socket:connect('sx-bol.eu', 80)
    self.Url = url
    self.Started = false
    self.LastPrint = ""
    self.File = ""
end

function UpdaterClas:Base64Encode(data)
    local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    return ((data:gsub('.', function(x)
        local r,b='',x:byte()
        for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
        return r;
    end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if (#x < 6) then return '' end
        local c=0
        for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
        return b:sub(c+1,c+1)
    end)..({ '', '==', '=' })[#data%3+1])
end

function UpdaterClas:GetOnlineVersion()
    if self.GotScriptVersion then return end

    self.Receive, self.Status, self.Snipped = self.Socket:receive(1024)
    if self.Status == 'timeout' and not self.Started then
        self.Started = true
        self.Socket:send("GET "..self.Url.." HTTP/1.1\r\nHost: sx-bol.eu\r\n\r\n")
    end
    if (self.Receive or (#self.Snipped > 0)) and not self.RecvStarted then
        self.RecvStarted = true
        self.DownloadStatus = 'Downloading VersionInfo (0%)'
    end

    self.File = self.File .. (self.Receive or self.Snipped)
    if self.File:find('</s'..'ize>') then
        if not self.Size then
            self.Size = tonumber(self.File:sub(self.File:find('<si'..'ze>')+6,self.File:find('</si'..'ze>')-1))
        end
        if self.File:find('<scr'..'ipt>') then
            local _,ScriptFind = self.File:find('<scr'..'ipt>')
            local ScriptEnd = self.File:find('</scr'..'ipt>')
            if ScriptEnd then ScriptEnd = ScriptEnd - 1 end
            local DownloadedSize = self.File:sub(ScriptFind+1,ScriptEnd or -1):len()
            self.DownloadStatus = 'Downloading VersionInfo ('..math.round(100/self.Size*DownloadedSize,2)..'%)'
        end
    end
    if self.File:find('</scr'..'ipt>') then
        self.DownloadStatus = 'Downloading VersionInfo (100%)'
        local a,b = self.File:find('\r\n\r\n')
        self.File = self.File:sub(a,-1)
        self.NewFile = ''
        for line,content in ipairs(self.File:split('\n')) do
            if content:len() > 5 then
                self.NewFile = self.NewFile .. content
            end
        end
        local HeaderEnd, ContentStart = self.File:find('<scr'..'ipt>')
        local ContentEnd, _ = self.File:find('</sc'..'ript>')
        if not ContentStart or not ContentEnd then
            if self.CallbackError and type(self.CallbackError) == 'function' then
                self.CallbackError()
            end
        else
            self.OnlineVersion = (Base64Decode(self.File:sub(ContentStart + 1,ContentEnd-1)))
            self.OnlineVersion = tonumber(self.OnlineVersion)
            if (self.OnlineVersion or 0) > self.LocalVersion then
                if self.CallbackNewVersion and type(self.CallbackNewVersion) == 'function' then
                    self.CallbackNewVersion(self.OnlineVersion,self.LocalVersion)
                end
                self:CreateSocket(self.ScriptPath)
                self.DownloadStatus = 'Connect to Server for ScriptDownload'
                AddTickCallback(function() self:DownloadUpdate() end)
            else
                if self.CallbackNoUpdate and type(self.CallbackNoUpdate) == 'function' then
                    self.CallbackNoUpdate(self.LocalVersion)
                end
            end
        end
        self.GotScriptVersion = true
    end
end

function UpdaterClas:DownloadUpdate()
    if self.GotUp then return end
    self.Receive, self.Status, self.Snipped = self.Socket:receive(1024)
    if self.Status == 'timeout' and not self.Started then
        self.Started = true
        self.Socket:send("GET "..self.Url.." HTTP/1.1\r\nHost: sx-bol.eu\r\n\r\n")
    end
    if (self.Receive or (#self.Snipped > 0)) and not self.RecvStarted then
        self.RecvStarted = true
        self.DownloadStatus = 'Downloading Script (0%)'
    end

    self.File = self.File .. (self.Receive or self.Snipped)
    if self.File:find('</si'..'ze>') then
        if not self.Size then
            self.Size = tonumber(self.File:sub(self.File:find('<si'..'ze>')+6,self.File:find('</si'..'ze>')-1))
        end
        if self.File:find('<scr'..'ipt>') then
            local _,ScriptFind = self.File:find('<scr'..'ipt>')
            local ScriptEnd = self.File:find('</scr'..'ipt>')
            if ScriptEnd then ScriptEnd = ScriptEnd - 1 end
            local DownloadedSize = self.File:sub(ScriptFind+1,ScriptEnd or -1):len()
            self.DownloadStatus = 'Downloading Script ('..math.round(100/self.Size*DownloadedSize,2)..'%)'
        end
    end
    if self.File:find('</scr'..'ipt>') then
        self.DownloadStatus = 'Downloading Script (100%)'
        local a,b = self.File:find('\r\n\r\n')
        self.File = self.File:sub(a,-1)
        self.NewFile = ''
        for line,content in ipairs(self.File:split('\n')) do
            if content:len() > 5 then
                self.NewFile = self.NewFile .. content
            end
        end
        local HeaderEnd, ContentStart = self.NewFile:find('<sc'..'ript>')
        local ContentEnd, _ = self.NewFile:find('</scr'..'ipt>')
        if not ContentStart or not ContentEnd then
            if self.CallbackError and type(self.CallbackError) == 'function' then
                self.CallbackError()
            end
        else
            local newf = self.NewFile:sub(ContentStart+1,ContentEnd-1)
            local newf = newf:gsub('\r','')
            if newf:len() ~= self.Size then
                if self.CallbackError and type(self.CallbackError) == 'function' then
                    self.CallbackError()
                end
                return
            end
            local newf = Base64Decode(newf)
            if type(load(newf)) ~= 'function' then
                if self.CallbackError and type(self.CallbackError) == 'function' then
                    self.CallbackError()
                end
            else
                local f = io.open(self.SavePath,"w+b")
                f:write(newf)
                f:close()
                if self.CallbackUpdate and type(self.CallbackUpdate) == 'function' then
                    self.CallbackUpdate(self.OnlineVersion,self.LocalVersion)
                end
            end
        end
        self.GotUp = true
    end
end
function Updater()
    local ToUpdate = {}
    ToUpdate.Version = version
    ToUpdate.UseHttps = true
    ToUpdate.Host = "raw.githubusercontent.com"
    ToUpdate.VersionPath = "/kokosik1221/BOL-/master/Caitlyn.version"
    ToUpdate.ScriptPath =  "/kokosik1221/BOL-/master/Caitlyn.lua"
    ToUpdate.SavePath = SCRIPT_PATH..GetCurrentEnv().FILE_NAME
    ToUpdate.CallbackUpdate = function(NewVersion,OldVersion) AutoupdaterMsg("CaitlynCombo succesfully updated! Restart to use new version.") end
    ToUpdate.CallbackNoUpdate = function(OldVersion) AutoupdaterMsg(" v"..version.." loaded") end
    ToUpdate.CallbackNewVersion = function(NewVersion) AutoupdaterMsg("New version found. Downloading now.") end
    ToUpdate.CallbackError = function(NewVersion) AutoupdaterMsg("Error updating your CaitlynCombo download it manually.") end
    UpdaterClas(ToUpdate.Version,ToUpdate.UseHttps, ToUpdate.Host, ToUpdate.VersionPath, ToUpdate.ScriptPath, ToUpdate.SavePath, ToUpdate.CallbackUpdate,ToUpdate.CallbackNoUpdate, ToUpdate.CallbackNewVersion,ToUpdate.CallbackError)
end
