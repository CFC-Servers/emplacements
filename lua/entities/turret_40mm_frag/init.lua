AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( "shared.lua" )

function ENT:Initialize()
    self.flightvector = self:GetForward() * 35 -- valid default flight vector incase shell is spawned standalone
    self.timeleft = CurTime() + 15
    self:SetModel( "models/items/ar2_grenade.mdl" )
    self:PhysicsInit( SOLID_VPHYSICS ) -- Make us work with physics,
    self:SetMoveType( MOVETYPE_NONE ) --after all, gmod is a physics
    self:SetSolid( SOLID_VPHYSICS ) -- CHEESECAKE!	>:3

    local tracer = ents.Create( "env_spritetrail" )
    tracer:SetKeyValue( "lifetime", "0.3" )
    tracer:SetKeyValue( "startwidth", "32" )
    tracer:SetKeyValue( "endwidth", "0" )
    tracer:SetKeyValue( "spritename", "trails/laser.vmt" )
    tracer:SetKeyValue( "rendermode", "5" )
    tracer:SetKeyValue( "rendercolor", "255 255 255" )
    tracer:SetPos( self:GetPos() )
    tracer:Spawn()
    tracer:Activate()

    self.tracer = tracer

    local glow = ents.Create( "env_sprite" )
    glow:SetKeyValue( "model", "orangecore2.vmt" )
    glow:SetKeyValue( "rendercolor", "37 138 210" )
    glow:SetKeyValue( "scale", "0.1" )
    glow:SetPos( self:GetPos() )
    glow:SetParent( self )
    glow:Spawn()
    glow:Activate()
end

function ENT:Explode()

    -- damage equals 400 multiplied by two thirds of this turret's firing speed
    local baseDamage = 120
    local origin = self:GetPos()
    local normal = self.flightvector:GetNormalized()

    local owner = IsValid( self:GetOwner() ) and self:GetOwner()
    local attacker = owner or self.Turret or self
    local inflictor = self

    util.BlastDamage( inflictor, attacker, self:GetPos(), 400, baseDamage )

    local concrete = 67 -- has to be concrete else errors are spammed
    local effectdata = EffectData()
    effectdata:SetOrigin( origin ) -- Position of Impact
    effectdata:SetNormal( -normal ) -- Direction of Impact
    effectdata:SetStart( normal ) -- Direction of Round
    effectdata:SetEntity( self ) -- Who done it?
    effectdata:SetScale( 0.8 ) -- Size of explosion
    effectdata:SetRadius( concrete ) -- Texture of Impact
    effectdata:SetMagnitude( 16 ) -- Length of explosion trails
    util.Effect( "gdca_airburst_t", effectdata )
    util.ScreenShake( origin, 10, 5, 1, 1300 )
    util.Decal( "Scorch", origin + normal, origin - normal )

    self:Remove()

    if not IsValid( self.tracer ) then return end
    self.tracer:SetPos( self:GetPos() )
    SafeRemoveEntityDelayed( self.tracer, 5 )

end

function ENT:Think()
    if self.timeleft < CurTime() then
        self:Explode()
    end

    local trace = {}
    trace.start = self:GetPos()
    trace.endpos = self:GetPos() + self.flightvector
    trace.filter = self
    trace.mask = bit.bxor( MASK_SHOT, MASK_WATER ) -- Trace for stuff that bullets would normally hit
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

        return self:Explode()
    end

    self:SetPos( self:GetPos() + self.flightvector )
    self.flightvector = self.flightvector + ( Vector( math.Rand( -0.1, 0.1 ), math.Rand( -0.1, 0.1 ), math.Rand( -0.1, 0.1 ) ) + Vector( 0, 0, math.Rand( 0, -0.32 ) ) )
    self:SetAngles( self.flightvector:Angle() )
    self:NextThink( CurTime() )

    if not IsValid( self.tracer ) then return true end

    self.tracer:SetPos( self:GetPos() ) -- use SetPos in think to prevent stupid bug where tracer jumps up to origin when unparented

    return true
end
