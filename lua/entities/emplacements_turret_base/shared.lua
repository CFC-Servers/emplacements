ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.Spawnable = false
ENT.spawnSetupTime = 8
ENT.angleInverse = 1
ENT.angleRotateAroundAxis = -90

function ENT:EmplacementSetupCheck()
    if not IsValid( self ) then return end
    if self.setup then return end
    self.setup = true

    timer.Simple( 0.2, function()
        if not IsValid( self ) then return end

        --setup variable
        local finalizeSoundTime = 0.1
        local setupTime = 4

        if self.longSpawnSetup then
            finalizeSoundTime = 4
            setupTime = 9
            if not SERVER then return end
            self:EmitSound( "weapons/ar2/ar2_reload.wav", 70, 50 ) -- this sound plays before the final sound so that the gun isn't just sitting there doing nothing
        end

        timer.Simple( finalizeSoundTime, function()
            if not IsValid( self ) then return end
            if not SERVER then return end
            self:EmitSound( "weapons/ar2/npc_ar2_reload.wav", 70, 50 )
        end )

        timer.Simple( setupTime, function()
            if not IsValid( self ) then return end
            self.doneSetup = true
        end )
    end )
end

function ENT:SetupDataTables()
    self:DTVar( "Entity", 0, "Shooter" )
    self:DTVar( "Entity", 1, "ShootPos" )
end

function ENT:SetShooter( plr )
    if IsValid( plr ) then
        plr.CurrentEmplacement = self
    elseif IsValid( self.Shooter ) then
        self.Shooter.CurrentEmplacement = nil
    end

    self.Shooter = plr
    self:SetDTEntity( 0, plr )
end

function ENT:GetShooter()
    if SERVER then
        return self.Shooter
    elseif CLIENT then
        return self:GetDTEntity( 0 )
    end
end

function ENT:ShooterStillValid()
    local shooter = nil

    if SERVER then
        shooter = self.Shooter
    elseif CLIENT then
        shooter = self:GetDTEntity( 0 )
    end
    local shooterIsValid = IsValid( shooter ) and shooter:Alive()
    if not shooterIsValid then return false end

    local originPos = self:GetPos() + self.TurretModelOffset
    local maxDistanceSqr = self.emplacementDisconnectRange * self.emplacementDisconnectRange
    local distanceSqr = originPos:DistToSqr( shooter:GetShootPos() )

    return distanceSqr <= maxDistanceSqr
end

function ENT:EmplacementDisconnect()
    self.Firing = false
    self:SetShooter()
    self:FinishShooting()

end

function ENT:EmplacementConnect( plr )
    if self.Shooter then return end

    local canConnect = hook.Run( "Emplacements_PlayerConnect", self, ply )
    if canConnect == false then return end

    self:SetShooter( plr )
    self:StartShooting()
    self.ShooterLast = plr
end

function ENT:Use( plr )
    if not self:ShooterStillValid() then
        local call = hook.Run( "Emplacements_PlayerWillEnter", self, plr )
        if call == false then return end

        if IsValid( plr.CurrentEmplacement ) then
            plr.CurrentEmplacement:EmplacementDisconnect() -- hotswap emplacements! feels much better than being denied
        end
        self:EmplacementConnect( plr )
    else
        if plr == self.Shooter then
            self:EmplacementDisconnect()
        end
    end
end

function ENT:Think()
    if not IsValid( self.turretBase ) then
        if SERVER then SafeRemoveEntity( self ) end
        return nil
    else
        if not IsValid( self ) and IsValid( self.turretBase ) then return end
        if SERVER then
            self.BasePos = self.turretBase:GetPos()
            self.OffsetPos = self.turretBase:GetAngles():Up()
        end

        self:EmplacementSetupCheck()

        if self:ShooterStillValid() then
            if not self.doneSetup then
                self.OffsetAng = self.turretBase:GetAngles() -- makes emplacement not aim when its setting up
                -- TODO: replace this with slower aiming instead
                return
            end

            if SERVER then
                local muzzlePos = self:GetAttachment( self.MuzzleAttachment ).Pos
                local offsetAng = ( muzzlePos - self:GetDesiredShootPos() ):GetNormal()
                local offsetDot = ( self.turretBase:GetAngles():Right() * self.angleInverse ):Dot( offsetAng )

                if offsetDot >= self.TurretTurnMax then
                    self.OffsetAng = offsetAng:Angle()
                    self.OffsetAng:RotateAroundAxis( self.OffsetAng:Up(), self.angleRotateAroundAxis )
                end
            end

            local pressKey = IN_BULLRUSH

            if CLIENT and game.SinglePlayer() then
                pressKey = IN_ATTACK
            end

            self.Firing = self:GetShooter():KeyDown( pressKey )
        else
            if not SERVER then return end
            self.OffsetAng = self.turretBase:GetAngles()
            if not self.Shooter then return end -- run this function once
            self:EmplacementDisconnect()
        end

        if self.Firing then
            self:DoShot()
        end

        self:NextThink( CurTime() )

        return true
    end
end
