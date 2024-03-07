include( "shared.lua" )

ENT.doneSettingUp = nil

function ENT:Initialize()
    self.MuzzleAttachment = self:LookupAttachment( "muzzle" )
    self.shootPos = self:GetDTEntity( 1 )

    self:EmplacementSetupCheck()
end

local CurTime = CurTime
local tostring = tostring
local math_Round = math.Round
local LocalPlayer = LocalPlayer
local ScrW = ScrW

local up = Vector( 0, 0, 1 )
local tooFar = 250^2
local color_hud = Color( 255, 210, 0 )

local function drawSettingUp( turret )
    local cur = CurTime()
    if cur > turret.doneSetupTime then turret.doneSettingUp = true return end

    local timeLeft = turret.doneSetupTime - cur
    timeLeft = math_Round( timeLeft, 1 )

    local drawPos = turret:GetPos()

    if drawPos:DistToSqr( LocalPlayer():GetShootPos() ) > tooFar then return end

    drawPos = drawPos + up * 10
    local toScreen = drawPos:ToScreen()

    local countdown = tostring( timeLeft )

    cam.Start2D()
        surface.SetFont( "CreditsText" )
        surface.SetTextColor( color_hud )

        local width = surface.GetTextSize( countdown )
        surface.SetTextPos( toScreen.x - width / 2, toScreen.y )
        surface.DrawText( countdown )
    cam.End2D()
end

local crosshairMat = Material( "sprites/hud/v_crosshair1" )

local function drawAimCrosshair( turret )
    if not turret.DoCrosshair then return end
    -- dont draw the crosshair ON the projectile...
    if turret.FiresSingles and not turret:GetReloaded() then return end

    local shooter = turret:GetShooter()
    if not IsValid( shooter ) then return end
    if shooter ~= LocalPlayer() then return end

    local shootPosEnt = turret:GetShootPos()
    local trStart = shootPosEnt:GetPos()

    local aimAng = turret:EasyForwardAng()
    local aimDir = aimAng:Forward()

    local traceStruc = {
        start = trStart,
        endpos = trStart + aimDir * 48000,
        filter = { turret, shootPosEnt }

    }
    local trResult = util.TraceLine( traceStruc )

    local spritePos = trResult.HitPos

    local screened = spritePos:ToScreen()
    -- same size for all resolutions
    local width = 30 * ( ScrW() / 1920 )

    cam.Start2D()
        surface.SetMaterial( crosshairMat )
        surface.SetDrawColor( color_hud )
        surface.DrawTexturedRect( screened.x - width / 2, screened.y - width / 2, width, width )
    cam.End2D()
end

function ENT:DrawTranslucent()
    self:DrawModel()

    if not self.doneSettingUp then
        drawSettingUp( self )
    else
        drawAimCrosshair( self )
    end
end
