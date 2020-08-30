// Glory kill fist
class GloryFist : Weapon
{	
	Default
	{
		AttackSound "*fist";
	}
	
	Weapon prevWeapon;
	Actor ptarget; 
	int ptics;
	float vbob;
	
	action void A_ResetWeapon()
	{
		PlayerInfo plr = PlayerPawn(self).player;

		if(invoker.ptarget) 
		{
			if(sv_glorykilldrops)
			{
				int drops = ceil((80-plr.health)/3)+1;
				if(drops <= 0) drops = random(1,6);
				for(int i = 0; i < drops; i++)
				{	
					float xoffs = cos(invoker.ptarget.angle)*frandom(-10,10);
					float yoffs = sin(invoker.ptarget.angle)*frandom(-10,10);
					float zoffs = frandom(5,invoker.ptarget.height);
					let hpup = SuperHealthBonus(Spawn("SuperHealthBonus",(invoker.ptarget.pos.x,invoker.ptarget.pos.y,invoker.ptarget.pos.z-zoffs)));
					if(hpup)
					{
						hpup.plr = plr.mo;
						hpup.vel.x = xoffs;
						hpup.vel.y = yoffs;
					}
				}
			}
			invoker.ptarget.tics = invoker.ptics;
		}
		plr.cheats &= ~(CF_TOTALLYFROZEN|CF_NOTARGET|CF_GODMODE|CF_GODMODE2|CF_INSTANTWEAPSWITCH|CF_DOUBLEFIRINGSPEED);
		plr.mo.ViewBob = invoker.vbob;
		
		if(plr) 
		{
			plr.PendingWeapon = invoker.prevWeapon;
			PSprite pweapon = plr.GetPSprite(PSP_WEAPON);
			pweapon.x -= 130;
			//pweapon.y = WEAPONTOP;
			pweapon.ResetInterpolation();
		}
		RemoveInventory(invoker); 
	}
	
	action void A_ToggleFlip()
	{
		PlayerInfo plr = PlayerPawn(self).player;
		PSprite pweapon = plr.GetPSprite(PSP_WEAPON);
		if(pweapon) 
		{
			pweapon.bFlip = !pweapon.bFlip;	
			pweapon.x -= 130 * (pweapon.bFlip*-1);
			pweapon.ResetInterpolation();
		}
	}
	
	override void DoEffect()
	{		
		if(!PlayerPawn(Owner)) 
		{
			super.DoEffect();
			return;
		}
		if(ptarget && ptarget.health >= 0) 
		{
			if(ptarget.tics != -1) 
			{
				ptics = ptarget.tics;
				ptarget.tics = -1;
			}
			PlayerInfo plr = PlayerPawn(Owner).player;
			plr.mo.vel *= 0;
			if(!vbob) 
			{	
				vbob = plr.mo.ViewBob;
				plr.mo.ViewBob *= 0;
			}
			plr.cheats |= CF_TOTALLYFROZEN|CF_NOTARGET|CF_GODMODE2|CF_GODMODE|CF_DOUBLEFIRINGSPEED|CF_INSTANTWEAPSWITCH;
			if(!prevWeapon) prevWeapon = plr.ReadyWeapon;
		}
		super.DoEffect();
	}
	
	static double GetPushWeight(double emass)
	{
		// Deviation from small weight, 0 means no deviation.
		double m = 200; // Base mass
		double d = 0.15; // Mass dropoff
		double x = (1. - (emass/m));
		double y = -d*(x**2) + 1;
		return clamp(y*0.75,0.1,1.0);
	}
	
	action void A_GloryPunch(bool kill = false)
	{	
		A_Quake(3,3,0,10,"");
		A_CustomPunch(1,true,0,"BulletPuff",64,0,0,"","none"); 
		if(invoker.ptarget && kill) 
		{
			invoker.ptarget.A_Die("GloryKill");
			double pwmass = invoker.GetPushWeight(invoker.ptarget.mass);
			invoker.ptarget.Thrust(20. * pwmass, angle);
			invoker.ptarget.vel.z += (12. * pwmass);
		}
	}
	

	action void A_GloryKick(bool kill = false)
	{	
		PlayerInfo plr = PlayerPawn(self).player;
		A_PlaySound("fht1",0);
		A_Quake(5,3,0,10,"");
		A_CustomPunch(1,true,0,"BulletPuff",64,0,0,"","none"); 
		if(invoker.ptarget && kill) invoker.ptarget.A_Die("GloryKill");
		//plr.mo.ViewBob *= 1;
	}	

	States
	{
		Ready:
			PONG A 1 A_WeaponReady();
		goto Fire;
		Done:
			PONG A 1 A_ResetWeapon();
		Deselect:
			PONG A 1 A_Lower(WEAPONBOTTOM);
		Loop;
		Select:
			PONG A 1 A_Raise(WEAPONTOP);
		Loop;
		Fire:
                        TNT1 A 0 A_Jump(64,"AltKill");
			TNT1 A 0 A_Jump(96,"AltKill2");
			TNT1 A 0 A_WeaponOffset(-20,60);
			PONG BCC 1;
			PONG D 2 A_GloryPunch();
			PONG DD 1 
			{	
				A_WeaponOffset(30/2,-32/2,WOF_ADD | WOF_INTERPOLATE);
				A_SetRoll(roll+1.25,SPF_INTERPOLATE);
			}
			PONG DDD 2 
			{
				A_WeaponOffset(-30/5,32/5,WOF_ADD | WOF_INTERPOLATE);
				A_SetRoll(roll-1.25,SPF_INTERPOLATE);
			}
			TNT1 A 0 A_WeaponOffset(-20,60);
			PONG CCB 2;
			TNT1 A 0 A_ToggleFlip();
			PONG BCC 1;
			PONG D 1 A_GloryPunch(true);
			PONG DD 1 
			{	
				A_WeaponOffset(-30/2,-32/2,WOF_ADD | WOF_INTERPOLATE);
				A_SetRoll(roll-1.25,SPF_INTERPOLATE);
			}
			PONG DDD 2 
			{
				A_WeaponOffset(30/5,32/5,WOF_ADD | WOF_INTERPOLATE);
				A_SetRoll(roll+1.25,SPF_INTERPOLATE);
			}
			PONG CCB 1;
		Goto Done;
	}
