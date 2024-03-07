ENT.Type = "anim"
ENT.Base = "emplacements_turret_base"
ENT.Category = "Emplacements"
ENT.PrintName = "Railcannon Turret"
ENT.Author = "Wolly/BOT_09"
ENT.Spawnable = true
ENT.AdminSpawnable = false
ENT.TurretFloatHeight = 3
ENT.TurretModelOffset = Vector( 0, 0, 44 )
ENT.TurretModelAngOffset = Angle( 0, -90, 0 )
ENT.TurretTurnMax = 0
ENT.ShotInterval = 8
ENT.LongSpawnSetup = true
ENT.FiresSingles = true

ENT.angleInverse = -1

function ENT:DoShot()
    if self.lastShot + self.ShotInterval < CurTime() and self.doneSetup then
        if SERVER then
            local effectPosAng = self:GetAttachment( self.MuzzleAttachment )
            local vPoint = effectPosAng.Pos
            local effectdata = EffectData()
            effectdata:SetStart( vPoint )
            effectdata:SetOrigin( vPoint )
            effectdata:SetAttachment( self.MuzzleAttachment )
            effectdata:SetEntity( self )
            effectdata:SetScale( 1 )
            effectdata:SetRadius( 100 )
            util.Effect( "GunshipMuzzleFlash", effectdata )
            self:EmitSound( self.ShotSound, 60, 100 ) -- hiss
            self:EmitSound( "npc/sniper/sniper1.wav", 155, 60 ) -- echo
            self:EmitSound( "weapons/ar2/npc_ar2_altfire.wav", 155, 60 ) -- deep thunk

            local fireGlow = ents.Create( "env_sprite" ) -- bright flash
            fireGlow:SetKeyValue( "model", "orangecore2.vmt" )
            fireGlow:SetKeyValue( "rendercolor", "37 138 255" )
            fireGlow:SetKeyValue( "scale", "5" )
            fireGlow:SetPos( self:GetPos() + ( self:EasyForwardAng():Forward() * 50 ) )
            SafeRemoveEntityDelayed( fireGlow, 0.05 )
            fireGlow:Spawn()
            fireGlow:Activate()

            util.ScreenShake( self:GetPos(), 10, 20, 0.1, 1000 ) -- strong shake when close
            util.ScreenShake( self:GetPos(), 1, 20, 0.8, 4000 ) -- weak shake when far

        end

        if IsValid( self.shootPos ) and SERVER then
            local nade = ents.Create( "rail_shell" )
            nade:SetPos( self.shootPos:GetPos() + self.shootPos:GetUp() * 30 )
            nade:SetAngles( self:EasyForwardAng() )
            nade:Spawn()
            nade:SetOwner( self:GetShooter() )
            nade.Turret = self
            self:ApplyRecoil( 0.2, 1, -45000 )
        end

        self.lastShot = CurTime()
        return true
    end
end
