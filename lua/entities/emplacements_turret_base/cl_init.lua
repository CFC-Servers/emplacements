include( "shared.lua" )

function ENT:Initialize()
    self.MuzzleAttachment = self:LookupAttachment( "muzzle" )
    self.shootPos = self:GetDTEntity( 1 )

    self:EmplacementSetupCheck()
end

local CurTime = CurTime
local tostring = tostring
local LocalPlayer = LocalPlayer

local up = Vector( 0, 0, 1 )
local tooFar = 250^2

function ENT:Draw()
    self:DrawModel()
    local cur = CurTime()
    if cur > self.doneSetupTime then return end

    local timeLeft = self.doneSetupTime - cur
    timeLeft = math.Round( timeLeft, 1 )

    local drawPos = self:GetPos()

    if drawPos:DistToSqr( LocalPlayer():GetShootPos() ) > tooFar then return end

    drawPos = drawPos + up * 10
    local toScreen = drawPos:ToScreen()

    local text = "setting up"

    for _ = 0, ( cur % 3 ) do
        text = text .. "."
    end

    local newline = tostring( timeLeft )

    cam.Start2D()
        surface.SetFont( "Default" )
        surface.SetTextColor( 255, 255, 255 )

        local width, height = surface.GetTextSize( text )
        surface.SetTextPos( toScreen.x - width / 2, toScreen.y )
        surface.DrawText( text )

        local newlineWidth = surface.GetTextSize( newline )
        surface.SetTextPos( toScreen.x - newlineWidth / 2, toScreen.y + height )
        surface.DrawText( newline )
    cam.End2D()
end
