ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.Spawnable = false
ENT.spawnSetupTime = 8
ENT.angleInverse = 1
ENT.angleRotateAroundAxis = -90
ENT.tracerSpeed = 12000

function ENT:EmplacementSetupCheck()
    if self.Setup then return end
    self.Setup = true

    timer.Simple( 0.2, function()
        if not IsValid( self ) then return end
        self.LastShot = CurTime() + self.spawnSetupTime

        -- Setup sounds
        if SERVER then
            self:EmitSound( "weapons/ar2/ar2_reload.wav", 70, 50 )

            timer.Simple( 3, function()
                if not IsValid( self ) then return end
                self:EmitSound( "weapons/ar2/npc_ar2_reload.wav", 70, 50 )
            end )
        end
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

    return IsValid( shooter ) and shooter:Alive() and ( ( self:GetPos() + self.TurretModelOffset ):Distance( shooter:GetShootPos() ) <= 110 )
end

function ENT:Use( plr )
    if not self:ShooterStillValid() then
        local call = hook.Run( "Emplacements_PlayerWillEnter", self, plr )
        if call == false then return end

        if IsValid( plr.CurrentEmplacement ) then
            if SERVER then
                -- plays sound on self to remind players this is an intended feature
                self:EmitSound( "common/wpn_denyselect.wav", 60 )
            end

            return
        end

        self:SetShooter( plr )
        self:StartShooting()
        self.ShooterLast = plr
    else
        if plr == self.Shooter then
            self:SetShooter( nil )
            self:FinishShooting()
        end
    end
end

function ENT:Think()
    if not IsValid( self.turretBase ) and SERVER then
        SafeRemoveEntity( self )
    else
        if IsValid( self ) then
            if SERVER then
                self.BasePos = self.turretBase:GetPos()
                self.OffsetPos = self.turretBase:GetAngles():Up() * 1
            end

            self:EmplacementSetupCheck()

            if self:ShooterStillValid() then
                if SERVER then
                    local offsetAng = ( self:GetAttachment( self.MuzzleAttachment ).Pos - self:GetDesiredShootPos() ):GetNormal()
                    local offsetDot = ( self.turretBase:GetAngles():Right() * self.angleInverse ):Dot( offsetAng )

                    if offsetDot >= self.TurretTurnMax then
                        local offsetAngNew = offsetAng:Angle()
                        offsetAngNew:RotateAroundAxis( offsetAngNew:Up(), self.angleRotateAroundAxis )
                        self.OffsetAng = offsetAngNew
                    end
                end

                local pressKey = IN_BULLRUSH

                if CLIENT and game.SinglePlayer() then
                    pressKey = IN_ATTACK
                end

                self.Firing = self:GetShooter():KeyDown( pressKey )
            else
                self.Firing = false

                if SERVER then
                    self.OffsetAng = self.turretBase:GetAngles()
                    self:SetShooter( nil )
                    self:FinishShooting()
                end
            end

            if self.Firing then
                self:DoShot()
            end

            self:NextThink( CurTime() )

            return true
        end
    end
end
