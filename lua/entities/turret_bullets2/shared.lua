ENT.Type = "anim"
ENT.Base = "emplacements_turret_base"
ENT.Category = "Emplacements"
ENT.PrintName = "Anti-Material Turret"
ENT.Author = "Wolly/BOT_09"
ENT.Spawnable = true
ENT.AdminSpawnable = false
ENT.TurretFloatHeight = 3
ENT.TurretModelOffset = Vector( 0, 0, 44 )
ENT.TurretModelAngOffset = Angle( 0, -90, 0 )
ENT.TurretTurnMax = 0
ENT.ShotInterval = 0.4
ENT.LongSpawnSetup = true

ENT.angleInverse = -1

function ENT:DoShot()
    if self.lastShot + self.ShotInterval < CurTime() and self.doneSetup then
        if SERVER then
            local effectPosAng = self:GetAttachment( self.MuzzleAttachment )
            local vPoint = effectPosAng.Pos
            local angle = effectPosAng.Ang
            angle:RotateAroundAxis( self:GetUp(), -90 )

            local effectdata = EffectData()
            effectdata:SetStart( vPoint )
            effectdata:SetOrigin( vPoint )
            effectdata:SetAngles( self:EasyForwardAng() )
            effectdata:SetEntity( self )
            effectdata:SetScale( 1.6 )
            util.Effect( "MuzzleEffect", effectdata )
            local variance = math.random( -3, 3 )
            self:EmitSound( self.ShotSound, 50, 100 + variance )
            self:EmitSound( "weapons/ar2/fire1.wav", 70, 60 + variance )
        end

        if IsValid( self.shootPos ) and SERVER then
            local fullDamage = 140
            local bulletDamage = fullDamage * 0.67 --cutting up damage into two components
            local explosiveDamage = fullDamage * 0.33

            self:GetShooter():LagCompensation( true )

            self.shootPos:FireBullets( {
                Num = 1,
                Src = self.shootPos:GetPos() + self.shootPos:GetAngles():Up() * 10,
                Dir = self:EasyForwardAng():Forward() * 1,
                Spread = Vector( 0.01, 0.01, 0 ),
                Tracer = 0,
                Force = bulletDamage,
                Damage = bulletDamage,
                Attacker = self:GetShooter(),
                Callback = function( _, trace, dmgInfo )
                    local concrete = 67 -- has to be concrete else errors are spammed
                    local tracerEffect = EffectData()
                    tracerEffect:SetStart( self.shootPos:GetPos() )
                    tracerEffect:SetOrigin( trace.HitPos )
                    tracerEffect:SetScale( 40000 ) -- usain bolt speed

                    util.Effect( "AirboatGunHeavyTracer", tracerEffect ) -- BIG effect
                    if trace.HitSky then return end

                    if IsValid(trace.Entity) and trace.Entity:IsVehicle() then
                        dmgInfo:ScaleDamage( 0.35 )
                        explosiveDamage = explosiveDamage * 0.35
                    end

                    local inflictor = self:GetShooter() or self
                    util.BlastDamage( self, inflictor, trace.HitPos, 100, explosiveDamage ) -- explosion for anti armour power

                    local effectdata = EffectData()
                    effectdata:SetOrigin( trace.HitPos )
                    effectdata:SetScale( 1.25 )
                    effectdata:SetRadius( concrete )
                    effectdata:SetNormal( trace.HitNormal )
                    util.Effect( "gdcw_universal_impact_t", effectdata )
                    util.Decal( "SmallScorch", trace.HitPos + trace.HitNormal, trace.HitPos - trace.HitNormal ) -- decal to communicate that yes, this goes boom

                end
            } )
            
            self:GetShooter():LagCompensation( false )
            
            self:ApplyRecoil( 0.05, 1, -7000 )
        end

        self.lastShot = CurTime()
        return true
    end
end
