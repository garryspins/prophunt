--
-- cl_init.lua
-- Prop Hunt
--	
-- Created by Andrew Theis on 2013-03-09.
-- Copyright (c) 2010-2013 Andrew Theis. All rights reserved.
--
 
 
-- Creating font
function surface.CreateLegacyFont(font, size, weight, antialias, additive, name, shadow, outline, blursize)
	surface.CreateFont(name, {font = font, size = size, weight = weight, antialias = antialias, additive = additive, shadow = shadow, outline = outline, blursize = blursize})
end
 

-- Include the needed files.
include("shared.lua")
include("cl_splashscreen.lua")
include("cl_skin.lua")
include("vgui/vgui_hudlayout.lua")
include("vgui/vgui_hudelement.lua")
include("vgui/vgui_hudbase.lua")
include("vgui/vgui_hudcommon.lua")
include("cl_hud.lua")
include("cl_scoreboard.lua")


-- Fonts!
surface.CreateLegacyFont( "Trebuchet MS", 69, 700, true, false, "FRETTA_HUGE" )
surface.CreateLegacyFont( "Trebuchet MS", 69, 700, true, false, "FRETTA_HUGE_SHADOW", true )
surface.CreateLegacyFont( "Trebuchet MS", 40, 700, true, false, "FRETTA_LARGE" )
surface.CreateLegacyFont( "Trebuchet MS", 40, 700, true, false, "FRETTA_LARGE_SHADOW", true )
surface.CreateLegacyFont( "Trebuchet MS", 19, 700, true, false, "FRETTA_MEDIUM" )
surface.CreateLegacyFont( "Trebuchet MS", 19, 700, true, false, "FRETTA_MEDIUM_SHADOW", true )
surface.CreateLegacyFont( "Trebuchet MS", 16, 700, true, false, "FRETTA_SMALL" )
surface.CreateLegacyFont( "Trebuchet MS", ScreenScale( 10 ), 700, true, false, "FRETTA_NOTIFY", true )


-- Decides where the player view should be.
function GM:CalcView(pl, origin, angles, fov)
	
	-- Create empty array to store view information in.
	local view = {} 
	
	-- If the player is supposed blind, set their view off the map.
	if blind then
	
		view.origin = Vector(20000, 0, 0)
		view.angles = Angle(0, 0, 0)
		view.fov 	= fov
		
		return view
		
	end
	
	-- Set view variables to given function arguements.
 	view.origin = origin 
 	view.angles	= angles 
 	view.fov 	= fov 
 	
 	-- If the player is a Prop, we know they won't have a weapon so just set their view to third person.
	if pl:Team() == TEAM_PROPS && pl:Alive() then
	
		view.origin = origin + Vector(0, 0, hull_z - 60) + (angles:Forward() * -80)
		
	else
	
		-- Give the active weapon a go at changing the viewmodel position.
	 	local wep = pl:GetActiveWeapon() 
		
	 	if wep && wep != NULL then 
		
			-- Try ViewModelPosition first.
	 		local func = wep.GetViewModelPosition 
			
	 		if func then 
			
	 			view.vm_origin, view.vm_angles = func(wep, origin * 1, angles * 1)

	 		end
	 		 
			-- But let the weapon's CalcView override.
	 		local func = wep.CalcView 
			
	 		if func then 

				view.origin, view.angles, view.fov = func(wep, pl, origin * 1, angles * 1, fov)
				
	 		end 
			
	 	end
		
	end
 	
 	return view
	
end


function GM:InitPostEntity()
	
	self.BaseClass:InitPostEntity();
	GAMEMODE:ShowSplash();

end

-- Draw round timeleft and hunter release timeleft.
function HUDPaint()

	-- If we aren't in a round, don't paint anything.
	if !GetGlobalBool("InRound") then 
		
		return 
	
	end
	
	-- Caculate the time left for blindlock.
	local blindlock_time_left = (HUNTER_BLINDLOCK_TIME - (CurTime() - GetGlobalFloat("RoundStartTime", 0))) + 1
	
	-- Decide what text to display on the hud based on the time left.
	if blindlock_time_left < 1 && blindlock_time_left > -6 then
	
		blindlock_time_left_msg = "Hunters have been released!"
		
	elseif blindlock_time_left > 0 then
	
		blindlock_time_left_msg = "Hunters will be unblinded and released in "..string.ToMinutesSeconds(blindlock_time_left)
		
	else
	
		blindlock_time_left_msg = nil
		
	end
	
	-- If there is text to display, display it.
	if blindlock_time_left_msg then
	
		surface.SetFont("ph_arial")
		local tw, th = surface.GetTextSize(blindlock_time_left_msg)
		
		draw.RoundedBox(8, 20, 20, tw + 20, 26, Color(0, 0, 0, 75))
		draw.DrawText(blindlock_time_left_msg, "ph_arial", 31, 26, Color(255, 255, 0, 255), TEXT_ALIGN_LEFT)
		
	end
	
end
hook.Add("HUDPaint", "PH_HUDPaint", HUDPaint)


-- Called immediately after starting the gamemode.
function Initialize()

	hull_z = 80
	surface.CreateFont("ph_arial", { 
		font = "Arial",
		size = 14, 
		weight = 1200, 
		antialias = true,
		shadow = false
	})
	
end
hook.Add("Initialize", "PH_Initialize", Initialize)


-- Resets the player hull.
function ResetHull(um)

	if LocalPlayer() && LocalPlayer():IsValid() then
	
		LocalPlayer():ResetHull()
		hull_z = 80
		
	end
	
end
usermessage.Hook("ResetHull", ResetHull)


-- Sets the local blind variable to be used in CalcView.
function SetBlind(um)

	blind = um:ReadBool()
	
end
usermessage.Hook("SetBlind", SetBlind)

-- hook.Add("HUDPaint", "DrawBlind", function()
-- 	if not blind then return end
-- 	surface.SetDrawColor(22, 22, 22)
-- 	surface.DrawRect(0, 0, ScrW(), ScrH())
-- end)


-- Sets the player hull and the health status.
function SetHull(um)

	hull_xy 	= um:ReadLong()
	hull_z 		= um:ReadLong()
	new_health 	= um:ReadLong()
	
	LocalPlayer():SetHull(Vector(hull_xy * -1, hull_xy * -1, 0), Vector(hull_xy, hull_xy, hull_z))
	LocalPlayer():SetHullDuck(Vector(hull_xy * -1, hull_xy * -1, 0), Vector(hull_xy, hull_xy, hull_z))
	LocalPlayer():SetHealth(new_health)
	
end
usermessage.Hook("SetHull", SetHull)