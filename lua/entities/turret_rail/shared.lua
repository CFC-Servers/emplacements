ENT.Type = "anim"
ENT.Base = "emplacements_turret_base"
ENT.Category = "Emplacements"
ENT.PrintName = "Railcannon Turret"
ENT.Author = "Wolly/BOT_09"
ENT.Spawnable = true
ENT.AdminSpawnable = false
ENT.TurretFloatHeight = 3
ENT.TurretModelOffset = Vector( 0, 0, 44 )
ENT.TurretTurnMax = 0.7
ENT.LastShot = 0
ENT.ShotInterval = 4.5
ENT.spawnSetupTime = 8

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
            self:EmitSound( self.ShotSound, 50, 100 )
            self:EmitSound( "npc/sniper/sniper1.wav", 100, 60 )
        end

        if IsValid( self.shootPos ) and SERVER then
            local nade = ents.Create( "rail_shell" )
            nade:SetPos( self.shootPos:GetPos() + self.shootPos:GetUp() * 30 )
            nade:SetAngles( self.shootPos:GetAngles() + Angle( self.Shooter:EyeAngles().p, -90, 0 ) )
            nade:Spawn()
            nade:SetOwner( self.Shooter )
            nade.Turret = self
            self:GetPhysicsObject():ApplyForceCenter( self:GetRight() * -10000 )
        end

        self.LastShot = CurTime()
    end
end
