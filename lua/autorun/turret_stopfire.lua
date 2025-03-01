if CLIENT then
    list.Set( "ContentCategoryIcons", "Emplacements", "materials/icon16/gun.png" )
end

if SERVER then
    util.AddNetworkString( "TurretBlockAttackToggle" )
    resource.AddWorkshop( "3188888751" )
elseif CLIENT then
    local shouldBlockAttack = false

    net.Receive( "TurretBlockAttackToggle", function()
        local blockBit = net.ReadBit()

        if blockBit == 1 then
            shouldBlockAttack = true
        elseif blockBit == 0 then
            shouldBlockAttack = false
        end
    end )

    hook.Add( "CreateMove", "RedirectTurretAttack", function( cmd )
        local lp = LocalPlayer()

        if shouldBlockAttack and IsValid( lp ) and bit.band( cmd:GetButtons(), IN_ATTACK ) > 0 then
            cmd:SetButtons( bit.bor( cmd:GetButtons() - IN_ATTACK, IN_BULLRUSH ) )
        end
    end )
end
