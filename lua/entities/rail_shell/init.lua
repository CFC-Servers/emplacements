AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( "shared.lua" )

local IsValid = IsValid

function ENT:Initialize()
    self.flightvector = self:GetForward() * 300
    self.timeleft = CurTime() + 5
    self.AirburstTime = CurTime() + 5
    self:SetModel( "models/weapons/w_missile_closed.mdl" )
    self:PhysicsInit( SOLID_VPHYSICS ) -- Make us work with physics,
    self:SetMoveType( MOVETYPE_NONE ) --after all, gmod is a physics
    self:SetSolid( SOLID_VPHYSICS ) -- CHEESECAKE!	>:3
    Tracer = ents.Create( "env_spritetrail" )
    Tracer:SetKeyValue( "lifetime", "0.2" )
    Tracer:SetKeyValue( "startwidth", "90" )
    Tracer:SetKeyValue( "endwidth", "15" )
    Tracer:SetKeyValue( "spritename", "trails/laser.vmt" )
    Tracer:SetKeyValue( "rendermode", "5" )
    Tracer:SetKeyValue( "rendercolor", "37 138 210" )
    Tracer:SetPos( self:GetPos() )
    Tracer:SetParent( self )
    Tracer:Spawn()
    Tracer:Activate()
    Glow = ents.Create( "env_sprite" )
    Glow:SetKeyValue( "model", "orangecore2.vmt" )
    Glow:SetKeyValue( "rendercolor", "37 138 210" )
    Glow:SetKeyValue( "scale", "0.4" )
    Glow:SetPos( self:GetPos() )
    Glow:SetParent( self )
    Glow:Spawn()
    Glow:Activate()
end

function ENT:Think()
    if self.timeleft < CurTime() then
        self:Remove()
    end

    if self.AirburstTime < CurTime() then
        local owner = IsValid( self:GetOwner() ) and self:GetOwner()
        local inflictor = owner
        if not IsValid( owner ) then
            inflictor = self.Turret
            if IsValid( inflictor ) do
                inflictor = self
            end
        end

        util.BlastDamage( inflictor, self.Turret, self:GetPos(), 700, 100 )
        local effectdata = EffectData()
        effectdata:SetOrigin( self:GetPos() )
        effectdata:SetScale( 2 )
        effectdata:SetMagnitude( 20 )
        util.Effect( "gdca_airburst_t", effectdata )
        self:Remove()
    end

    local trace = {}
    trace.start = self:GetPos()
    trace.endpos = self:GetPos() + self.flightvector
    trace.filter = self
    trace.mask = MASK_SHOT + MASK_WATER -- Trace for stuff that bullets would normally hit
    local tr = util.TraceLine( trace )

    if tr.Hit then
        if tr.HitSky then
            self:Remove()

            return true
        end

        --83 is wata
        if tr.MatType == 83 then
            local effectdata = EffectData()
            effectdata:SetOrigin( tr.HitPos )
            effectdata:SetNormal( tr.HitNormal ) -- In case you hit sideways water?
            effectdata:SetScale( 60 ) -- Big splash for big bullets
            util.Effect( "watersplash", effectdata )
            self:Remove()

            return true
        end

        -- damage equals 400 multipled by a bit less than the firing interval
        local baseDamage = 1188
        local effectDir = -self:GetForward() --have the effect "point" towards the turret, makes it very clear where you are being shot from

        local tightDamage = baseDamage * 0.66 -- dividing up the damage into 2 components since we have 2 explosions w/ different distances
        local wideDamage  = baseDamage * 0.33

        local owner = IsValid( self:GetOwner() ) and self:GetOwner()
        local attacker = owner or self.Turret or self
        local inflictor = IsValid( self.Turret ) and self.Turret or self

        util.BlastDamage( inflictor, attacker, tr.HitPos, 500, wideDamage ) -- create two explosions so that damage scales wildly the closer you are to the center
        util.BlastDamage( inflictor, attacker, tr.HitPos, 200, tightDamage )

        local concrete = 67 -- has to be concrete else errors are spammed
        local effectdata = EffectData()
        effectdata:SetOrigin( tr.HitPos ) -- Position of Impact
        effectdata:SetNormal( effectDir ) -- Direction of Impact
        effectdata:SetStart( self.flightvector:GetNormalized() ) -- Direction of Round
        effectdata:SetEntity( self ) -- Who done it?
        effectdata:SetScale( 2.1 ) -- Size of explosion
        effectdata:SetRadius( concrete ) -- Texture of Impact
        effectdata:SetMagnitude( 16 ) -- Length of explosion trails
        util.Effect( "gdca_cinematicboom_t", effectdata )
        util.ScreenShake( tr.HitPos, 10, 5, 1, 1500 )
        util.Decal( "Scorch", tr.HitPos + tr.HitNormal, tr.HitPos - tr.HitNormal )
        self:Remove()
    end

    self:SetPos( self:GetPos() + self.flightvector )
    self.flightvector = self.flightvector + ( Vector( math.Rand( -0.1, 0.1 ), math.Rand( -0.1, 0.1 ), math.Rand( -0.1, 0.1 ) ) + Vector( 0, 0, -0.01 ) )
    self:SetAngles( self.flightvector:Angle() )
    self:NextThink( CurTime() )

    return true
end
