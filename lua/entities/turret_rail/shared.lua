ENT.Type = "anim"
ENT.Base = "emplacements_turret_base"
ENT.Category = "Emplacements"
ENT.PrintName = "Railcannon Turret"
ENT.Author = "Wolly/BOT_09"
ENT.Spawnable = true
ENT.AdminSpawnable = false
ENT.TurretFloatHeight = 3
ENT.TurretModelOffset = Vector( 0, 0, 44 )
ENT.TurretTurnMax = 0
ENT.LastShot = 0
ENT.ShotInterval = 10
ENT.longSpawnSetup = true

ENT.angleInverse = -1
ENT.angleRotateAroundAxis = -90

function ENT:easyForwardAng()
    if not IsValid( self.shootPos ) then return end
    if not IsValid( self.Shooter ) then return end
    return self.shootPos:GetAngles() + Angle( self.Shooter:EyeAngles().p, -90, 0 )

end

function ENT:DoShot()
    if self.LastShot + self.ShotInterval < CurTime() and self.doneSetup then
        if SERVER then
            local effectPosAng = self:GetAttachment( self.MuzzleAttachment )
            local vPoint = effectPosAng.Pos
            local effectdata = EffectData()
            effectdata:SetStart( vPoint )
            effectdata:SetOrigin( vPoint )
            effectdata:SetAngles( effectPosAng.Ang + Angle( 0, -90, 0 ) )
            effectdata:SetEntity( self )
            effectdata:SetScale( 2 )
            util.Effect( "MuzzleEffect", effectdata )
            self:EmitSound( self.ShotSound, 60, 100 ) -- hiss
            self:EmitSound( "npc/sniper/sniper1.wav", 155, 60 ) -- echo
            self:EmitSound( "weapons/ar2/npc_ar2_altfire.wav", 155, 60 ) -- deep thunk

            FireGlow = ents.Create( "env_sprite" ) -- bright flash
            FireGlow:SetKeyValue( "model", "orangecore2.vmt" )
            FireGlow:SetKeyValue( "rendercolor", "37 138 255" )
            FireGlow:SetKeyValue( "scale", "5" )
            FireGlow:SetPos( self:GetPos() + ( self:easyForwardAng():Forward() * 50 ) )
            SafeRemoveEntityDelayed( FireGlow, 0.05 )
            FireGlow:Spawn()
            FireGlow:Activate()

            util.ScreenShake( self:GetPos(), 10, 20, 0.1, 1000 ) -- strong shake when close
            util.ScreenShake( self:GetPos(), 1, 20, 0.8, 4000 ) -- weak shake when far

        end

        if IsValid( self.shootPos ) and SERVER then
            local nade = ents.Create( "rail_shell" )
            nade:SetPos( self.shootPos:GetPos() + self.shootPos:GetUp() * 30 )
            nade:SetAngles( self:easyForwardAng() )
            nade:Spawn()
            nade:SetOwner( self.Shooter )
            nade.Turret = self
            self:ApplyRecoil( 0.2, 1, -1500000 )
        end

        self.LastShot = CurTime()
    end
end
