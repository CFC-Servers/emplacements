ENT.Type = "anim"
ENT.Base = "emplacements_turret_base"
ENT.Category = "Emplacements"
ENT.PrintName = "40MM HE Turret"
ENT.Author = "Wolly/BOT_09"
ENT.Spawnable = true
ENT.AdminSpawnable = false
ENT.TurretFloatHeight = 3
ENT.TurretModelOffset = Vector( 0, 0, 44 )
ENT.TurretTurnMax = 0
ENT.LastShot = 0
ENT.ShotInterval = 0.7
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
            --elseif SERVER then
            self:EmitSound( self.ShotSound, 50, 100 )
        end

        if IsValid( self.shootPos ) and SERVER then
            local nade = ents.Create( "turret_40mm_frag" )
            self:DeleteOnRemove( nade )
            nade:SetPos( self.shootPos:GetPos() )
            nade:SetAngles( self:GetAngles() + Angle( self:GetAngles().p, -90, 0 ) )
            nade:Spawn()
            nade:SetOwner( self.Shooter )
            nade.flightvector = self:GetRight() * 35
            nade.Turret = self
            self:ApplyRecoil( 0.1, 1, -5000 )
        end

        self.LastShot = CurTime()
    end
end
