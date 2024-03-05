ENT.Type = "anim"
ENT.Base = "emplacements_turret_base"
ENT.Category = "Emplacements"
ENT.PrintName = "7.62x39mm Turret"
ENT.Author = "Wolly/BOT_09"
ENT.Spawnable = true
ENT.AdminSpawnable = false
ENT.TurretFloatHeight = 3
ENT.TurretModelOffset = Vector( 0, 0, 40 )
ENT.TurretTurnMax = 0
ENT.LastShot = 0
ENT.ShotInterval = 0.03
ENT.longSpawnSetup = false

ENT.angleInverse = 1
ENT.angleRotateAroundAxis = 90

function ENT:DoShot()
    if self.LastShot + self.ShotInterval < CurTime() and self.doneSetup then
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
            local bulletDamage = 1250 * self.ShotInterval -- ensuring dps of var
            self.shootPos:FireBullets( {
                Num = 1,
                Src = self.shootPos:GetPos() + self.shootPos:GetAngles():Forward() * 10,
                Dir = self.shootPos:GetAngles():Forward() * 1,
                Spread = Vector( 0.03, 0.03, 0 ),
                Tracer = 0,
                Force = bulletDamage,
                Damage = bulletDamage,
                Attacker = self.Shooter,
                Callback = function( _, trace )

                local tracerEffect = EffectData()
                tracerEffect:SetStart( self.shootPos:GetPos() )
                tracerEffect:SetOrigin( trace.HitPos )
                tracerEffect:SetScale( 20000 ) --pretty fast

                util.Effect( "StriderTracer", tracerEffect ) -- big but not too big effect

                end
            } )

            --end
            self:ApplyRecoil( 0.1, 1, 1000 )
        end

        self.LastShot = CurTime()
        return true
    end
end
