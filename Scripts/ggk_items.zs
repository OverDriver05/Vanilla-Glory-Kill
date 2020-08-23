// Moves enemy to the player.
class ObjectMover : Inventory
{
	Actor to;
	int dist;
	
	override void DoEffect()
	{
		if(!Owner) return;
		
		double spd = 20.;
		vector3 delta = ( to.pos.x - Owner.pos.x, to.pos.y - Owner.pos.y, to.pos.z - Owner.pos.z );
		double angleto = Owner.AngleTo(to);
		double pitchto = VectorAngle( sqrt(delta.y * delta.y + delta.x * delta.x), delta.z );
		to.A_SetPitch(pitchto,SPF_INTERPOLATE);
		to.A_SetAngle(angleto+180,SPF_INTERPOLATE);
		if (to.Distance3D(Owner) > dist)
		{
			vector3 neworigin = Owner.Vec3Offset(cos(angleto) * spd,  sin(angleto) * spd, sin(pitchto) * spd);
			Owner.SetOrigin(neworigin,true);
		}
		else
		{
			RemoveInventory(self);
		}
		super.DoEffect();
	}
}

// Displays the stagger graphic.
class ShadedActor : Inventory
{
	Actor act;
	
	Default
	{
		+NOINTERACTION
	}
	override void BeginPlay()
	{
		A_SetRenderStyle(1.0,STYLE_Shaded);
		Color gloryshade = Color(242,60,14);
		SetShade(gloryshade);
		super.BeginPlay();
	}
	override void Tick(void)
	{
		if(!act || act.health <= 0) GoAwayAndDie();
		if(act)
		{
			if(radius != act.radius || height != act.height) A_SetSize(act.radius, act.height);
			if(scale.x != act.scale.x || scale.y != act.scale.y) A_SetScale(act.scale.x,act.scale.y);
			Sprite = act.sprite;
			frame = act.frame;
			angle = act.angle;
			vector3 correctedpos = (act.pos.x+cos(act.angle)*5,act.pos.y+sin(act.angle)*5,act.pos.z);
			SetOrigin(correctedpos,true);
			Spawn("ShadedActor_Light",act.pos);
		}
		super.Tick();
	}
}
class ShadedActor_Light : Actor
{
	Default
	{
		+NOINTERACTION
		+MOVEWITHSECTOR
	}
	States
	{
		Spawn:
			TNT1 A 1;
		SpawnDie:
			TNT1 A 1;
		stop;
	}
}

// Staggers enemies, utilizes graphic.
class IStagger : Inventory
{
	int ptics;
	int livetics;
	ShadedActor ashader;
	
    Default
    {
        Inventory.MaxAmount 1;
    }
	
	void ToggleShade()
	{
		if(!Owner) return;
		if(!ashader)
		{
			ashader = ShadedActor(Spawn("ShadedActor",Owner.pos));
			ashader.act = Owner;
		} 
		else if(ashader)
		{
			ashader.GoAwayAndDie();
			ashader = null;
		}
	}

    override void DoEffect()
    {
		if(!Owner || Owner.Health <= 0)
		{
			DepleteOrDestroy();
			return;
		}

		if(!ptics) ptics = Owner.tics;
		Owner.tics = -1;
		
		if(!livetics) 
		{
			ToggleShade();
			Owner.bInvulnerable = true;
		}
		
		if( livetics > 2) Owner.bInvulnerable = false;
		if( livetics >= sv_staggerlength*0.6 && !(level.maptime%10) ) ToggleShade(); 
		livetics ++;
		
		if(livetics > sv_staggerlength) DepleteOrDestroy();
        super.DoEffect();
    }
    
    override void DepleteOrDestroy()
    {
		if(ashader) ashader.GoAwayAndDie();
        if(Owner) 
        {
			if(Owner.health > 0) Owner.A_SetHealth(Owner.health + (1.0-(Owner.health*sv_staggerhealth))/2 );
            Owner.tics = ptics;
            Owner.RemoveInventory(self);
        }
    }
}

// Health drops
class SuperHealthBonus : HealthBonus
{
	int livetics;
	Actor plr;
	Default
	{
		Inventory.PickupMessage "Glory kill bonus";
		Inventory.Amount 1;
		Scale 0.5;
		Radius 2;
		Height 2;
	}
	
	override String PickupMessage()
	{
		plr.A_SetHealth(plr.health + sv_glorykillhealth-1);
		return "Glory kill bonus +"..sv_glorykillhealth.." hp";
	}
	
	override void Tick()
	{
		if(pos.z == floorz) bNOGRAVITY = true;
		livetics++;
		if(plr && Distance2D(plr) > radius && livetics > 10)
		{
			double spd = 40.;
			vector3 delta = ( plr.pos.x - pos.x, plr.pos.y - pos.y, (plr.pos.z+plr.player.viewheight/2) - pos.z );
			double angleto = AngleTo(plr);
			double pitchto = VectorAngle( sqrt(delta.y * delta.y + delta.x * delta.x), delta.z );
			vector3 neworigin = Vec3Offset(cos(angleto) * spd,  sin(angleto) * spd, sin(pitchto) * spd);
			SetOrigin(neworigin,true);
		}
		super.Tick();
	}
}
