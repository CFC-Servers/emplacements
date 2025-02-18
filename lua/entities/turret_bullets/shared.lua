ENT.Type = "anim"
ENT.Base = "emplacements_turret_base"
ENT.Category = "Emplacements"
ENT.PrintName = "Machinegun Turret"
ENT.Author = "Wolly/BOT_09"
ENT.Spawnable = true
ENT.AdminSpawnable = false
ENT.TurretFloatHeight = 3
ENT.TurretModelOffset = Vector( 0, 0, 40 )
ENT.TurretModelAngOffset = Angle( 0, 90, 0 )
ENT.TurretTurnMax = 0
ENT.ShotInterval = 0.1
ENT.LongSpawnSetup = false

ENT.angleInverse = 1

ENT.PropDamageMultiplier = 0.5


DEFINE_BASECLASS( "emplacements_turret_base" )



-- The rate heat generates per second at peak firerate
local OVERHEAT_TIME = 14
local COOLING_TIME = 7

-- How long it takes to spin up
local SPINUP_TIME = 3
local SPINDOWN_TIME = 6

local MIN_SHOT_INTERVAL = 0.15
local MAX_SHOT_INTERVAL = 0.02


function ENT:Initialize()
    BaseClass.Initialize( self )
    if not SERVER then return end
    
    self.Heat = 0
    self.SpinUp = 0
    self.ShotInterval = MIN_SHOT_INTERVAL
    self.RampUpSound = CreateSound( self, "vehicles/airboat/fan_motor_fullthrottle_loop1.wav" )
    self.RampUpSound:PlayEx( 0, 0 )
end


function ENT:RunHeatHandler()
    if self.Firing then
        self.Heat = math.min( self.Heat + FrameTime() / OVERHEAT_TIME, 1 )
        self.SpinUp = math.min( self.SpinUp + FrameTime() / SPINUP_TIME, 1 )
    else
        self.Heat = math.max( self.Heat - FrameTime() / COOLING_TIME, 0 )
        self.SpinUp = math.max( self.SpinUp - FrameTime() / SPINDOWN_TIME, 0 )
    end

    local heatPenalty = math.max( (self.Heat - 0.75) / 0.25 * 0.75, 0 )

    if heatPenalty > 0 then
        local smokeEffect = EffectData()
        smokeEffect:SetOrigin( self:LocalToWorld( Vector( 0,35,22 ) ) )
        smokeEffect:SetNormal( self:GetRight() )
        smokeEffect:SetScale( 20 * (heatPenalty+1) )

        util.Effect( "ElectricSpark", smokeEffect )
    end

    local totalSpinUp = self.SpinUp - heatPenalty
    self.RampUpSound:ChangeVolume( self.SpinUp*3 )
    self.RampUpSound:ChangePitch( 50 + self.SpinUp*100 )

    self.ShotInterval = Lerp( totalSpinUp, MIN_SHOT_INTERVAL, MAX_SHOT_INTERVAL )
end


function ENT:Think()
    local r = BaseClass.Think( self )
    
    if SERVER then
        self:RunHeatHandler()
    end

    return r
end


function ENT:OnRemove()
    if SERVER then
        self.RampUpSound:Stop()
        self.RampUpSound = nil
    end

    BaseClass.OnRemove( self )
end


function ENT:DoShot()
    if self.lastShot + self.ShotInterval < CurTime() and self.doneSetup then
        if SERVER then
            local effectPosAng = self:GetAttachment( self.MuzzleAttachment )
            local vPoint = effectPosAng.Pos
            local effectdata = EffectData()
            effectdata:SetStart( vPoint )
            effectdata:SetOrigin( vPoint )
            effectdata:SetAngles( self:EasyForwardAng() )
            effectdata:SetEntity( self )
            effectdata:SetScale( 1 )
            util.Effect( "MuzzleEffect", effectdata )
            --elseif SERVER then
            self:EmitSound( self.ShotSound, 50, 100 )
        end

        if IsValid( self.shootPos ) and SERVER then
            local bulletDamage = 40
            self:GetShooter():LagCompensation(true)

            self.shootPos:FireBullets( {
                Num = 1,
                Src = self.shootPos:GetPos() + self.shootPos:GetAngles():Forward() * 10,
                Dir = self:EasyForwardAng():Forward(),
                Spread = Vector( 0.03, 0.03, 0 ),
                Tracer = 0,
                Force = bulletDamage,
                Damage = bulletDamage,
                Attacker = self:GetShooter(),
                Callback = function( _, trace )

                local tracerEffect = EffectData()
                tracerEffect:SetStart( self.shootPos:GetPos() )
                tracerEffect:SetOrigin( trace.HitPos )
                tracerEffect:SetScale( 6000 ) --pretty fast

                util.Effect( "StriderTracer", tracerEffect ) -- big but not too big effect

                end
            } )

            self:GetShooter():LagCompensation(false)
            
            --end
            self:ApplyRecoil( 0.1, 1, 1000 )
        end

        self.lastShot = CurTime()
        return true
    end
end



