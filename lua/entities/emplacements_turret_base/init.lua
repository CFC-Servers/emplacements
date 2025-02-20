AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( "shared.lua" )

ENT.BasePos = Vector( 0, 0, 0 )
ENT.BaseAng = Angle( 0, 0, 0 )
ENT.BaseMass = 150
ENT.OffsetPos = Vector( 0, 0, 0 )
ENT.OffsetAng = Angle( 0, 0, 0 )
ENT.TurretHeadMass = 100
ENT.ShooterLast = nil

ENT.lastShot = 0

ENT.turretModel = "models/hunter/blocks/cube025x025x025.mdl"
ENT.turretBaseModel = "models/hunter/blocks/cube025x025x025.mdl"
ENT.turretPos = 0
ENT.turretInitialAngle = 0

ENT.soundName = "sound_name"
ENT.soundPath = "soundfile.wav"

function ENT:Initialize()
    self:SetModel( self.turretModel )
    self:PhysicsInit( SOLID_VPHYSICS )
    self:SetMoveType( MOVETYPE_VPHYSICS )
    self:SetSolid( SOLID_VPHYSICS )
    self:SetCollisionGroup( COLLISION_GROUP_WEAPON )
    local phys = self:GetPhysicsObject()

    if IsValid( phys ) then
        phys:Wake()
        phys:SetVelocity( Vector( 0, 0, 0 ) )
        phys:SetMass( self.TurretHeadMass )
    end

    self.ShadowParams = {}
    self:StartMotionController()

    self:CreateEmplacement()

    self.ShotSound = Sound( self.soundName )
    self:SetUseType( SIMPLE_USE )
    self.MuzzleAttachment = self:LookupAttachment( "muzzle" )
    self.HookupAttachment = self:LookupAttachment( "hookup" )
    self:DropToFloor()
    self.shootPos:SetRenderMode( RENDERMODE_TRANSCOLOR )
    self.shootPos:SetColor( Color( 255, 255, 255, 1 ) )

    sound.Add( {
        name = self.soundName,
        channel = CHAN_WEAPON,
        volume = 0.7,
        soundlevel = "SNDLVL_GUNFIRE",
        pitchstart = 98,
        pitchend = 110,
        sound = self.soundPath
    } )

    self:EmplacementSetupCheck()
end

function ENT:CreateEmplacement()
    local turretBase = ents.Create( "prop_physics" )
    turretBase.DoNotDuplicate = true

    self:DeleteOnRemove( turretBase )
    turretBase:DeleteOnRemove( self )

    turretBase:SetModel( self.turretBaseModel )
    turretBase:SetAngles( self:GetAngles() + Angle( 0, self.turretInitialAngle, 0 ) )
    turretBase:SetPos( self:GetPos() - Vector( 0, 0, 0 ) )
    turretBase:Spawn()

    local obj = turretBase:GetPhysicsObject()
    if IsValid( obj ) then
        obj:SetMass( self.BaseMass )
    end

    if CPPI then
        turretBase:CPPISetOwner( self:CPPIGetOwner() )
    end

    self.turretBase = turretBase
    constraint.NoCollide( self.turretBase, self, 0, 0 )

    local shootPos = ents.Create( "prop_dynamic" )
    shootPos:SetModel( "models/hunter/blocks/cube025x025x025.mdl" )
    shootPos:SetAngles( self:GetAngles() )
    shootPos:SetPos( self:GetPos() - Vector( 0, 0, 0 ) )
    shootPos:Spawn()
    shootPos:SetCollisionGroup( COLLISION_GROUP_WORLD )
    self.shootPos = shootPos
    shootPos:SetParent( self )
    shootPos:Fire( "setparentattachment", "muzzle" )
    shootPos:SetNoDraw( false )
    shootPos:DrawShadow( false )
    shootPos.EmplacementTurret = self
    shootPos.PropDamageMultiplier = self.PropDamageMultiplier
    --shootPos:SetColor(Color(0,0,0,0))
    self:SetDTEntity( 1, shootPos )
end

function ENT:OnRemove()
    if not self:ShooterStillValid() then return end
    net.Start( "TurretBlockAttackToggle" )
        net.WriteBit( false )
    net.Send( self:GetShooter() )
    self:SetShooter( nil )
    self:FinishShooting()
end

hook.Add( "PlayerSwitchWeapon", "Emplacements_DisonnectOnWepSwitch", function( ply )
    if not IsValid( ply.CurrentEmplacement ) then return end
    ply.CurrentEmplacement:EmplacementDisconnect()

end )

function ENT:StartShooting()
    local shooter = self:GetShooter()
    shooter:DrawViewModel( false )
    self:EmitSound( "Func_Tank.BeginUse" )
    net.Start( "TurretBlockAttackToggle" )
        net.WriteBit( true )
    net.Send( shooter )
end

function ENT:FinishShooting()
    if not IsValid( self.ShooterLast ) then return end
    self.ShooterLast:DrawViewModel( true )
    net.Start( "TurretBlockAttackToggle" )
        net.WriteBit( false )
    net.Send( self.ShooterLast )
    self.ShooterLast = nil
end

function ENT:GetDesiredShootPos()
    local shooter = self:GetShooter()
    local playerTrace = util.GetPlayerTrace( shooter )

    playerTrace.filter = { shooter, self, self.turretBase }

    local shootTrace = util.TraceLine( playerTrace )

    return shootTrace.HitPos
end

function ENT:ApplyRecoil( randomMul, recoilMul, finalMul )
    if not self:IsValid() then return end
    local obj = self:GetPhysicsObject()

    local randomComponent = VectorRand( -1, 1 ) * randomMul
    local recoilComponent = self:GetRight() * recoilMul
    local finalForce      = ( randomComponent + recoilComponent ) * finalMul
    finalForce = finalForce * obj:GetMass()

    obj:ApplyForceCenter( finalForce )
end

function ENT:PhysicsSimulate( phys, deltatime )
    phys:Wake()
    if not IsValid( self.turretBase ) then return end
    self.ShadowParams.secondstoarrive = 0.01
    self.ShadowParams.pos = self.BasePos + self.turretBase:GetUp() * self.turretPos
    self.ShadowParams.angle = self.BaseAng + self.OffsetAng + Angle( 0, 0, 0 )
    self.ShadowParams.maxangular = 5000
    self.ShadowParams.maxangulardamp = 10000
    self.ShadowParams.maxspeed = 1000000
    self.ShadowParams.maxspeeddamp = 10000
    self.ShadowParams.dampfactor = 0.8
    self.ShadowParams.teleportdistance = 200
    self.ShadowParams.deltatime = deltatime
    phys:ComputeShadowControl( self.ShadowParams )
end

function ENT:GravGunPickupAllowed()
    return false
end

function ENT:Use( plr )
    if not plr:IsPlayer() then return end -- terms
    if not self:ShooterStillValid() then
        local call = hook.Run( "Emplacements_PlayerWillEnter", self, plr )
        if call == false then return end

        if IsValid( plr.CurrentEmplacement ) then
            plr.CurrentEmplacement:EmplacementDisconnect() -- hotswap emplacements! feels much better than being denied
        end
        self:EmplacementConnect( plr )
    else
        if plr == self:GetShooter() then
            self:EmplacementDisconnect()
        end
    end
end


local toSafeKeep = {
    ShadowParams = true,
    shootPos = true,
    turretBase = true,
}
local safeKeeping

function ENT:PreEntityCopy() -- fix hydra emplacement bug
    safeKeeping = {}

    for name, _ in pairs( toSafeKeep ) do
        safeKeeping[name] = self[name]
        self[name] = nil
    end
end

function ENT:PostEntityCopy()
    for name, _ in pairs( toSafeKeep ) do
        self[name] = safeKeeping[name]

    end

    safeKeeping = nil
end
