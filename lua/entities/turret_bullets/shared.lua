ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.Category = "Emplacements"
ENT.PrintName = "7.62x39mm Turret"
ENT.Author = "Wolly/BOT_09"
ENT.Spawnable = true
ENT.AdminSpawnable = false
ENT.TurretFloatHeight = 3
ENT.TurretModelOffset = Vector( 0, 0, 40 )
ENT.TurretTurnMax = 0.7
ENT.LastShot = 0
ENT.ShotInterval = 0.07

function ENT:EmplacementSetupCheck()
    if self.Setup then return end
    self.Setup = true

    timer.Simple( 0.2, function()
        if not IsValid( self ) then return end
        self.LastShot = CurTime() + 5

        -- Setup sounds
        if SERVER then
            self:EmitSound( "weapons/ar2/npc_ar2_reload.wav", 70, 50 )
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

function ENT:GetShooter( plr )
    if SERVER then
        return self.Shooter
    elseif CLIENT then
        return self:GetDTEntity( 0 )
    end
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

function ENT:ShooterStillValid()
    local shooter = nil

    if SERVER then
        shooter = self.Shooter
    elseif CLIENT then
        shooter = self:GetDTEntity( 0 )
    end

    return IsValid( shooter ) and shooter:Alive() and ( ( self:GetPos() + self.TurretModelOffset ):Distance( shooter:GetShootPos() ) <= 60 )
end

function ENT:DoShot()
    if self.LastShot + self.ShotInterval < CurTime() then
        if SERVER then
            local effectPosAng = self:GetAttachment( self.MuzzleAttachment )
            local vPoint = effectPosAng.Pos
            local effectdata = EffectData()
            effectdata:SetStart( vPoint )
            effectdata:SetOrigin( vPoint )
            effectdata:SetAngles( effectPosAng.Ang )
            effectdata:SetEntity( self )
            effectdata:SetScale( 1 )
            util.Effect( "MuzzleEffect", effectdata )
            --elseif SERVER then
            self:EmitSound( self.ShotSound, 50, 100 )
        end

        if IsValid( self.shootPos ) and SERVER then
            self.shootPos:FireBullets( {
                Num = 1,
                Src = self.shootPos:GetPos() + self.shootPos:GetAngles():Forward() * 10,
                Dir = self.shootPos:GetAngles():Forward() * 1,
                Spread = Vector( 0.015, 0.015, 0 ),
                Tracer = 0,
                Force = 2,
                Damage = 25,
                Attacker = self.Shooter,
                Callback = function( attacker, trace, dmginfo )
                    --if CLIENT then
                    local tracerEffect = EffectData()
                    tracerEffect:SetStart( self.shootPos:GetPos() )
                    tracerEffect:SetOrigin( trace.HitPos )
                    tracerEffect:SetScale( 6000 )
                    util.Effect( "GunshipTracer", tracerEffect )
                end
            } )

            --end
            self:GetPhysicsObject():ApplyForceCenter( self:GetRight() * 50000 )
        end

        self.LastShot = CurTime()
    end
end

function ENT:Think()
    if not IsValid( self.turretBase ) and SERVER then
        SafeRemoveEntity( self )
    else
        --[[if IsValid(self.shootPos) or self.shootPos==NULL then
			if CLIENT then
				
				self.shootPos=self:GetDTEntity(1)
			elseif SERVER then
				
				self:SetDTEntity(1,self.shootPos)
			end
		end]]
        if IsValid( self ) then
            self:EmplacementSetupCheck()

            if SERVER then
                self.BasePos = self.turretBase:GetPos()
                self.OffsetPos = self.turretBase:GetAngles():Up() * 1
            end

            if self:ShooterStillValid() then
                if SERVER then
                    local offsetAng = ( self:GetAttachment( self.MuzzleAttachment ).Pos - self:GetDesiredShootPos() ):GetNormal()
                    local offsetDot = self.turretBase:GetAngles():Right():DotProduct( offsetAng )
                    local HookupPos = self:GetAttachment( self.HookupAttachment ).Pos

                    if offsetDot >= self.TurretTurnMax then
                        local offsetAngNew = offsetAng:Angle()
                        offsetAngNew:RotateAroundAxis( offsetAngNew:Up(), 90 )
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
