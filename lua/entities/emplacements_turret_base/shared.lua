ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.Spawnable = false
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

ENT.Editable = false
ENT.TurretModelAngOffset = Angle( 0, -90, 0 )
ENT.DoCrosshair = true
ENT.FiresSingles = nil
ENT.EmplacementDisconnectRange = 110

ENT.spawnSetupTime = 8
ENT.angleInverse = 1
ENT.doneSetupTime = math.huge

local IsValid = IsValid

function ENT:SetupDataTables()
    self:NetworkVar( "Entity", 0, "Shooter" )
    self:NetworkVar( "Entity", 1, "ShootPos" )
    -- dont draw railgun crosshair on the projectile!
    self:NetworkVar( "Bool", 0, "Reloaded" )

    if SERVER then
        self:SetReloaded( true )
    end

    self:NetworkVarNotify( "Shooter", function( me, _, old, new )
        if IsValid( old ) then
            old.CurrentEmplacement = nil
        end
        if IsValid( new ) then
            new.CurrentEmplacement = me
        end
    end )
end

function ENT:EmplacementSetupCheck()
    if self.setup then return end
    self.setup = true

    -- we are inside of initialize, delay all this logic so the sounds can actually play!
    timer.Simple( 0.4, function()
        if not IsValid( self ) then return end

        --kinda spaghetti, setup time is based on the length of these sounds
        --defaults to short setup, used by the machinegun turret
        local finalizeSoundTime = 0.1
        local setupTime = 4

        if self.LongSpawnSetup then
            finalizeSoundTime = 4
            setupTime = 9
            if SERVER then
                self:EmitSound( "weapons/ar2/ar2_reload.wav", 70, 50 )
            end
        end

        self.doneSetupTime = CurTime() + setupTime

        timer.Simple( finalizeSoundTime, function()
            if not IsValid( self ) then return end
            if not SERVER then return end
            self:EmitSound( "weapons/ar2/npc_ar2_reload.wav", 70, 50 )
        end )

        timer.Simple( setupTime, function()
            if not IsValid( self ) then return end
            self.doneSetup = true
            if not SERVER then return end
            self:EmitSound( "weapons/ar2/ar2_reload_push.wav", 150, 100 )
        end )
    end )
end

function ENT:ShooterStillValid()
    local shooter = self:GetShooter()

    local shooterIsValid = IsValid( shooter ) and shooter:Alive()
    if not shooterIsValid then return false end

    local originPos = self:GetPos() + self.TurretModelOffset
    local maxDistanceSqr = self.EmplacementDisconnectRange * self.EmplacementDisconnectRange
    local distanceSqr = originPos:DistToSqr( shooter:GetShootPos() )

    return distanceSqr <= maxDistanceSqr
end

function ENT:EmplacementDisconnect()
    self.Firing = false
    self:SetShooter()
    self:FinishShooting()

end

function ENT:EmplacementConnect( plr )
    if self:ShooterStillValid() then return end

    local canConnect = hook.Run( "Emplacements_PlayerConnect", self, plr )
    if canConnect == false then return end

    self:SetShooter( plr )
    self:StartShooting()
    self.ShooterLast = plr
end

function ENT:EasyForwardAng()
    return self:LocalToWorldAngles( self.TurretModelAngOffset )
end

function ENT:Think()
    if not IsValid( self.turretBase ) then return end

    if SERVER then
        self.BasePos = self.turretBase:GetPos()
        self.OffsetPos = self.turretBase:GetAngles():Up()
    end

    local shooter = self:GetShooter()
    local keyDown = nil
    local pressKey = IN_BULLRUSH
    if CLIENT and game.SinglePlayer() then
        pressKey = IN_ATTACK
    end
    if IsValid( shooter ) then
        keyDown = shooter:KeyDown( pressKey )

        if not self.doneSetup and keyDown then
            local timeToDoneSetup = self.doneSetupTime - CurTime()
            timeToDoneSetup = math.Round( timeToDoneSetup, 1 )
            shooter:PrintMessage( HUD_PRINTCENTER, "The emplacement is setting up for " .. timeToDoneSetup .. " more seconds." )
            if not self.doneClick then
                self.doneClick = true
                self:EmitSound( "weapons/shotgun/shotgun_empty.wav", 70, math.Rand( 95, 105 ), 1, CHAN_WEAPON )
            end
        elseif not keyDown then
            self.doneClick = nil
        end
    end

    if self:ShooterStillValid() then
        if not self.doneSetup then
            self.OffsetAng = self.turretBase:GetAngles() -- makes emplacement not aim when its setting up
            return
        end

        if SERVER then
            local muzzlePos = self:GetAttachment( self.MuzzleAttachment ).Pos
            local offsetAng = ( muzzlePos - self:GetDesiredShootPos() ):GetNormal()
            local offsetDot = ( self.turretBase:GetAngles():Right() * self.angleInverse ):Dot( offsetAng )

            if offsetDot >= self.TurretTurnMax then
                self.OffsetAng = offsetAng:Angle()
                self.OffsetAng:RotateAroundAxis( self.OffsetAng:Up(), self.TurretModelAngOffset.y )
            end
        end

        if self.doneSetup then
            self.Firing = keyDown
        end

    else
        if not SERVER then return end
        self.OffsetAng = self.turretBase:GetAngles()
        if self:ShooterStillValid() then return end
        self:EmplacementDisconnect()
    end

    if self.Firing then
        local wasSuccessful = self:DoShot()
        -- do a reload sound & 'animation?'
        if wasSuccessful and self.FiresSingles then
            self:SetReloaded( false )
            -- reloaded indicator
            timer.Simple( self.ShotInterval + -0.5, function()
                if not IsValid( self ) then return end
                self:SetReloaded( true )
                self:EmitSound( "weapons/ar2/ar2_reload_rotate.wav", 65, 80, 1, CHAN_STATIC )
                self:ApplyRecoil( 0.2, 1, -1000 )
            end )
        end
    end

    self:NextThink( CurTime() )

    return true
end
