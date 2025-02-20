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
    local tracer = ents.Create( "env_spritetrail" )
    tracer:SetKeyValue( "lifetime", "1.5" )
    tracer:SetKeyValue( "startwidth", "100" )
    tracer:SetKeyValue( "endwidth", "30" )
    tracer:SetKeyValue( "spritename", "trails/laser.vmt" )
    tracer:SetKeyValue( "rendermode", "5" )
    tracer:SetKeyValue( "rendercolor", "37 138 210" )
    tracer:SetPos( self:GetPos() )
    tracer:Spawn()
    tracer:Activate()

    self.Tracer = tracer

    local glow = ents.Create( "env_sprite" )
    glow:SetKeyValue( "model", "orangecore2.vmt" )
    glow:SetKeyValue( "rendercolor", "37 138 210" )
    glow:SetKeyValue( "scale", "0.4" )
    glow:SetPos( self:GetPos() )
    glow:SetParent( self )
    glow:Spawn()
    glow:Activate()
end

local baseDamage = 600
local tightRad = 200
local wideRad = 600
local damageGivenToTight = 0.65
local damageGivenToWide = 1 - damageGivenToTight

function ENT:Explode( tr )
    local effectDir = -self:GetForward() --have the effect "point" towards the turret, makes it very clear where you are being shot from

    local tightDamage = baseDamage * damageGivenToTight -- dividing up the damage into 2 components since we have 2 explosions w/ different distances
    local wideDamage  = baseDamage * damageGivenToWide

    local owner = IsValid( self:GetOwner() ) and self:GetOwner()
    local attacker = owner or self.Turret or self
    local inflictor = self or owner

    util.BlastDamage( inflictor, attacker, tr.HitPos, wideRad, wideDamage ) -- create two explosions so that damage scales wildly the closer you are to the center
    util.BlastDamage( inflictor, attacker, tr.HitPos, tightRad, tightDamage )

    if IsValid( tr.Entity ) then
        local directDamage = 100
        if tr.Entity:IsVehicle() then -- reward anyone insane enough to hit some lfs, or vehicle
            directDamage = 400
        end

        local damage = DamageInfo()
        damage:SetDamageType( DMG_BLAST )
        damage:SetDamage( directDamage )
        damage:SetDamageForce( self:GetForward() * 70000 )
        damage:SetAttacker( attacker )
        damage:SetInflictor( inflictor )
        tr.Entity:TakeDamageInfo( damage )
    end

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

    if not IsValid( self.Tracer ) then return end
    self.Tracer:SetPos( self:GetPos() )
    SafeRemoveEntityDelayed( self.Tracer, 5 )
end

function ENT:Think()
    if self.timeleft < CurTime() then
        self:Remove()
    end

    local trace = {}
    trace.start = self:GetPos()
    trace.endpos = self:GetPos() + self.flightvector
    trace.filter = self
    trace.mask = bit.bxor( MASK_SHOT, MASK_WATER ) -- Trace for stuff that bullets would normally hit
    local tr = util.TraceLine( trace )

    if self.AirburstTime < CurTime() then

        local owner = IsValid( self:GetOwner() ) and self:GetOwner()
        local inflictor = owner
        if not IsValid( owner ) then
            inflictor = self.Turret
            if IsValid( inflictor ) then
                inflictor = self
            end
        end

        self:Explode( tr )
    end

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

        self:Explode( tr )

    end
    self:SetPos( self:GetPos() + self.flightvector )
    self.flightvector = self.flightvector + ( Vector( math.Rand( -0.1, 0.1 ), math.Rand( -0.1, 0.1 ), math.Rand( -0.1, 0.1 ) ) + Vector( 0, 0, -0.01 ) )
    self:SetAngles( self.flightvector:Angle() )
    self:NextThink( CurTime() )

    if not IsValid( self.Tracer ) then return true end

    self.Tracer:SetPos( self:GetPos() ) -- use SetPos in think to prevent stupid bug where tracer jumps up to origin when unparented

    return true
end
