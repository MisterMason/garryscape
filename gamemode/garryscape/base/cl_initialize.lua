
DefaultAngles = Angle( 0, 0, 0 ) --Whatever the default camera angles would be
DefaultDistance = 200 --Or whatever you like
MinimumDistance = 128
MaximumDistance = 512
--How much the camera can be adjusted, in units / degrees per second
ZoomSpeed = 500
PanSpeed = 200
PitchSpeed = 100

MinPitch = 0
MaxPitch = 76

CameraAngles = DefaultAngles * 1 --Initialize it
CameraDistance = DefaultDistance

LocalPoint = Vector( 0, 0, 50 )  --The local point on the model

	
////MOUSE WHEEL STUFF
/*
local  overlayingpanel = vgui.Create('DFrame')
local wheeldirection, wheeldelay = 0,0
overlayingpanel:SetSize(ScrW()+100,ScrH()+100)
overlayingpanel:SetPos(-50,-50)
overlayingpanel:SetAlpha(0)
function overlayingpanel:OnMouseWheeled(mc)
	wheeldirection = mc
	wheeldelay = 1
end
timer.Create('mousewheeloverlay',1/5,0,function()
	if wheeldirection == 0 then return end
	wheeldelay = wheeldelay - 1
	if wheeldelay < 0 then wheeldelay = 0 end
	if wheeldelay == 0 then wheeldirection = 0 end
end)

local oldinputismousedown = input.IsMouseDown 

function input.IsMouseDown(enum)
	if enum == MOUSE_WHEEL_DOWN || enum == MOUSE_WHEEL_UP then
		if enum == MOUSE_WHEEL_DOWN then
			if wheeldirection < 0 then return true end
		else
			if wheeldirection > 0 then return true end
		end
		return false
	else
		return oldinputismousedown(enum)
	end
end
*/
//////////////////////


function GM:Initialize()
	moba = {};
		moba.character = "";
		moba.target	= nil;
		moba.viewoffset = Vector( 0, 0, 0 );
		moba.campos = Vector( 0, 0, 0 );
		moba.camIncriment = FrameTime() * 8;
		moba.camZoom = 400;
		moba.bot = nil
		moba.waypoint = nil;
		moba.waypointDelay = CurTime();
		moba.spells = {};
		moba.equipment = {};
		
	gui.EnableScreenClicker( true );
end

function GM:HUDPaint()
	local x, y = ScrW() / 2, ScrH() / 2;
	local mx, my = gui.MouseX(), gui.MouseY();
	
	for i = 1, 4 do
		local dist = i * 100;
		dist = dist + (x * 0.60);
		draw.RoundedBox( 0, dist, y * 1.79, x * 0.12, y * 0.20, Color( 60, 60, 60, 120 ) );
		
		local txt = MOBA.Characters[ moba.character ].Spells[i] or i;
		local col = Color( 255, 255, 255, 255 );
		
		if ( moba.spells[ i ].cooldown > RealTime() ) then
			col = Color( 60, 60, 60, 255 );
		end
		
		draw.DrawText( txt, "Default", dist + (x * 0.06), y * 1.88, col, TEXT_ALIGN_CENTER );
	end
end

function GM:CalcView( ply, pos, ang, fov )

	view = {}
	view.origin = moba.bot:LocalToWorld( LocalPoint ) - CameraAngles:Forward( ) * CameraDistance
	view.angles = CameraAngles

	return view

end

//Mouse Movements
function GM:Think()
	if ( CurTime() > moba.waypointDelay ) then
		if ( input.IsMouseDown( MOUSE_LEFT ) ) then //Moving
			local vector = gui.ScreenToVector( gui.MouseX(), gui.MouseY() ) * 99;
			local tr = util.QuickTrace( moba.campos, moba.campos + (vector * 10000), LocalPlayer() );
			
			net.Start( "mb_GoPos" );
				net.WriteVector( tr.HitPos );
			net.SendToServer();
			
			moba.waypointDelay = CurTime() + 0.4; //Stops them from spamming, also max age of bot path
		elseif ( input.IsMouseDown( MOUSE_RIGHT ) ) then //Attacking
			local vector = gui.ScreenToVector( gui.MouseX(), gui.MouseY() ) * 99;
			local tr = util.QuickTrace( moba.campos, moba.campos + (vector * 10000), LocalPlayer() );
	
			if ( tr.Hit && IsValid(tr.Entity) && tr.Entity != moba.bot ) then
				net.Start( "mb_Attak" );
					net.WriteEntity( tr.Entity );
				net.SendToServer();
				
				moba.target = tr.Entity; 
			end
			 
			moba.waypointDelay = CurTime() + 0.4; //Stops them from spamming, also max age of bot path
		end
	end 
	
	if ( input.IsKeyDown( KEY_W ) ) then
		if CameraAngles.p >= MaxPitch then CameraAngles.p = MaxPitch end
		CameraAngles:RotateAroundAxis( CameraAngles:Right( ), -PitchSpeed * RealFrameTime( ) )
	elseif ( input.IsKeyDown( KEY_S ) ) then
		if CameraAngles.p <= MinPitch then CameraAngles.p = MinPitch end
		CameraAngles:RotateAroundAxis( CameraAngles:Right( ), PitchSpeed * RealFrameTime( ) )
	end
	
	if ( input.IsKeyDown( KEY_D ) ) then
		CameraAngles:RotateAroundAxis( vector_up, PanSpeed * RealFrameTime( ) )
	elseif ( input.IsKeyDown( KEY_A ) ) then
		CameraAngles:RotateAroundAxis( Vector( 0, 0, -1 ), PanSpeed * RealFrameTime( ) )
	end

	if ( input.IsKeyDown( KEY_N ) ) then
		CameraAngles = DefaultAngles
	end
		
	if ( input.IsMouseDown( MOUSE_WHEEL_UP ) ) then
		CameraDistance = math.Clamp( CameraDistance - RealFrameTime( ) * ZoomSpeed, MinimumDistance, MaximumDistance )
	elseif ( input.IsMouseDown( MOUSE_WHEEL_DOWN ) ) then
		CameraDistance = math.Clamp( CameraDistance + RealFrameTime( ) * ZoomSpeed, MinimumDistance, MaximumDistance )
	end
	
	local spells = moba.spells;
	
	if ( input.IsKeyDown( KEY_1 ) ) then
		if ( !spells[1] || spells[1].spell == "" || RealTime() < spells[1].cooldown ) then return; end
		
		RunConsoleCommand( "mb_cast", "1" );
		spells[1].cooldown = RealTime() + MOBA.Spells[ spells[1].spell ].Cooldown;
	elseif ( input.IsKeyDown( KEY_2 ) ) then
		if ( !spells[2] || spells[2].spell == "" || RealTime() < spells[2].cooldown ) then return; end
		
		PrintTable( spells[2] );
		local time = MOBA.Spells[ spells[2] ].Cooldown;
		if ( !time ) then return; end
		
		RunConsoleCommand( "mb_cast", "2" );
		spells[2].cooldown = RealTime() + time;
	elseif ( input.IsKeyDown( KEY_3 ) ) then
		if ( !spells[3] || spells[3].spell == "" || RealTime() < spells[3].cooldown ) then return; end
		
		RunConsoleCommand( "mb_cast", "3" );
		spells[3].cooldown = RealTime() + MOBA.Spells[ spells[3].spell ].Cooldown;
	elseif ( input.IsKeyDown( KEY_4 ) ) then
		if ( !spells[4] || spells[4].spell == "" || RealTime() < spells[4].cooldown ) then return; end
		
		RunConsoleCommand( "mb_cast", "4" );
		spells[4].cooldown = RealTime() + MOBA.Spells[ spells[4].spell ].Cooldown;
	end
end

function GM:PlayerBindPress( ply, bind )
end

local function HideHUD( name )
	local Tbl = { 
	[ "CHudHealth" ] = true, 
	[ "CHudAmmo" ]   = true, 
	[ "CHudAmmoSecondary" ] = true, 
	[ "CHudBattery" ] = true,
	[ "CHudWeaponSelection" ] = true,
	[ "CHudCrosshair" ] = true
	}; 
	
	if ( Tbl[ name ] ) then
		return false;
	end
end
hook.Add( "HUDShouldDraw", "HeistHidHUD", HideHUD );

function GM:ShouldDrawLocalPlayer( ply )
	return true;
end