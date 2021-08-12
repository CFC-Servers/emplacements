ENT.Type = "anim"
ENT.Base = "emplacements_turret_base"
ENT.Category = "Emplacements"
ENT.PrintName = "14mm Turret"
ENT.Author = "Wolly/BOT_09"
ENT.Spawnable = true
ENT.AdminSpawnable = false
ENT.TurretFloatHeight = 3
ENT.TurretModelOffset = Vector( 0, 0, 44 )
ENT.TurretTurnMax = 0.7
ENT.LastShot = 0
ENT.ShotInterval = 0.4

ENT.angleInverse = -1
ENT.angleRotateAroundAxis = -90

function ENT:DoShot()
    if self.LastShot + self.ShotInterval < CurTime() then
        if SERVER then
            local effectPosAng = self:GetAttachment( self.MuzzleAttachment )
            local vPoint = effectPosAng.Pos
            local effectdata = EffectData()
            effectdata:SetStart( vPoint )
            effectdata:SetOrigin( vPoint )
            effectdata:SetAngles( effectPosAng.Ang + Angle( 0, -90, 0 ) )
            effectdata:SetEntity( self )
            effectdata:SetScale( 1 )
            util.Effect( "MuzzleEffect", effectdata )
            local variance = math.random( -5, 5 )
            self:EmitSound( self.ShotSound, 50, 100 + variance )
            self:EmitSound( "weapons/ar2/fire1.wav", 70, 60 )
        end

        if IsValid( self.shootPos ) and SERVER then
            self.shootPos:FireBullets( {
                Num = 1,
                Src = self.shootPos:GetPos() + self.shootPos:GetAngles():Up() * 10,
                Dir = self.shootPos:GetAngles():Up() * 1,
                Spread = Vector( 0.005, 0.005, 0 ),
                Tracer = 0,
                Force = 90,
                Damage = 70,
                Attacker = self.Shooter,
                Callback = function( _, trace )
                    local concrete = 67 -- has to be concrete else errors are spammed
                    local tracerEffect = EffectData()
                    tracerEffect:SetStart( self.shootPos:GetPos() )
                    tracerEffect:SetOrigin( trace.HitPos )
                    tracerEffect:SetScale( 6000 )
                    util.Effect( "Tracer", tracerEffect )
                    if trace.HitSky then return end
                    local inflictor = self.Shooter or self
                    util.BlastDamage( self, inflictor, trace.HitPos, 90, 20 ) -- explosion for anti armour power
                    local effectdata = EffectData()
                    effectdata:SetOrigin( trace.HitPos )
                    effectdata:SetScale( 1.25 )
                    effectdata:SetRadius( concrete )
                    effectdata:SetNormal( trace.HitNormal )
                    util.Effect( "gdcw_universal_impact_t", effectdata )
                    util.Decal( "SmallScorch", trace.HitPos + trace.HitNormal, trace.HitPos - trace.HitNormal ) -- decal to communicate that yes, this goes boom
                end
            } )

            self:GetPhysicsObject():ApplyForceCenter( self:GetRight() * -10000 )
        end

        self.LastShot = CurTime()
    end
end
