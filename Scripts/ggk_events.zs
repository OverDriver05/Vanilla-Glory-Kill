class GGKDamageScaler : Inventory
{
	int prevtic;
	Default
	{
		Inventory.MaxAmount 1;
	}
	
	override void ModifyDamage(int damage, Name damagetype, out int newdamage, bool passive, Actor inflictor, Actor source, int flags)
	{
		float dmg_mod = passive ? sv_indamagemod : sv_outdamagemod;
		
		/*
			Do all the stagger logic, random chance an otherwise gibbed enemy to stagger instead
			Invuln is set because this function gets called multiple times per tic.
			Invuln should be inactive after 2 tics of stagger, if it isn't forcefully disable it.
		*/
		
		// Prevtic is used so that weapons that make multiple damage calls per-tic do not have a MUCH higher
		// chance to stagger enemies.
		
		if(!passive && !source.FindInventory("IStagger") && GetAge() != prevtic)
		{	
			prevtic = GetAge();
			if( lk_GGKHandler.CheckStagger(source, damage*dmg_mod) || 
				(health-(damage*dmg_mod) <= 0 && lk_GGKHandler.DoStagger()) ) 
			{
				newdamage = source.health/2;
				source.A_GiveInventory("IStagger",1);
				source.bInvulnerable = true;
				return;
			}
		}
		else if(!passive && source.bInvulnerable) 
			source.bInvulnerable = false;
		
		// Apply damage scale out and in.
		newdamage = max(1, ApplyDamageFactors(GetClass(), damageType, damage, float(damage) * dmg_mod));
	}
}

class lk_GGKHandler : StaticEventHandler
{
	Actor pendingkill;
	GloryFist pfist;
	IStagger estagger;
	
	static bool DoStagger()
	{
		return ( (100-sv_glorystunchance)-random[StaggerRNG](0,100) <= 0 );
	}
	
	static bool CheckStagger(Actor thing, float dmgtaken)
	{
		// Basically uses the same percent change algo as pokemon red/blue but with = comparison not just <.
		bool randstagger = DoStagger();
		// Check stagger health
		return ( thing.health > 0 && (thing.health-dmgtaken <= thing.SpawnHealth()*sv_staggerhealth) && randstagger );
	}

	override void WorldTick()
	{
		PlayerPawn plr = PlayerPawn(players[consoleplayer].mo);
		if(!plr) return;
		
		// Mainly used to keep readability clean.
		bool dokill = pendingkill && pendingkill.health >  0;
		bool isdead = pendingkill && pendingkill.health <= 0;
		
		// Setup Damage Scaling
		if(!plr.FindInventory("GGKDamageScaler")) plr.GiveInventory("GGKDamageScaler", 1);
		
		// Grab items.
		pfist = GloryFist(plr.FindInventory("GloryFist"));
		if(dokill) estagger = IStagger(pendingkill.FindInventory("IStagger"));
		
		// If the player is ready to glory kill, set the target to kill.
		if(pfist && !pfist.ptarget) pfist.ptarget = pendingkill;
			
		// If the target is dead and the player just killed them, remove stagger from corpse.
		if(isdead && pfist) pendingkill.TakeInventory("IStagger",1);
		
		// If the target needs to die and they're close enough, setup glory kill.
		// Reset the enemy stagger timeout.
		if(dokill && plr.Distance3D(pendingkill) <= 64 && !pfist) 
		{	
			plr.A_GiveInventory("GloryFist",1);
			plr.A_SelectWeapon("GloryFist");
		}
	}

	override void NetworkProcess(ConsoleEvent ev)
	{
		/* 
			Check for glory kill button event, find actor with-in range.
			If the actor is staggered, make them our target we need to kill.
			If the actor is out of our punch range, move them to us.
		*/
	
		PlayerPawn plr = PlayerPawn(players[ev.Player].mo);
		if(!plr) return;
		if(pendingkill && pendingkill.health > 0) return;
		
		if(ev.Name == "glory_kill")
		{
			FLineTraceData lt_data;
			plr.LineTrace(plr.angle,sv_glorykillrange,plr.pitch,0,plr.viewheight,0,0,lt_data);
			if(lt_data.HitType == TRACE_HitActor)
			{
				Actor thinghit = lt_data.HitActor;
				let staggered = IStagger(thinghit.FindInventory("IStagger"));
				if(!staggered) return;				
				// Object is viable.
				pendingkill = thinghit;
				pendingkill.GiveInventory("ObjectMover",1);
				// Doomguy is a Jedi now, i guess.
				let omover = ObjectMover(pendingkill.FindInventory("ObjectMover"));
				if(omover) 
				{
					omover.to = plr;
					omover.dist = 64;
				}
			}
		}
	}
}
