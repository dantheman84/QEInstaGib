/*
	spectate.qc

	spectator functions

	This program is free software; you can redistribute it and/or
	modify it under the terms of the GNU General Public License
	as published by the Free Software Foundation; either version 2
	of the License, or (at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

	See the GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program; if not, write to:

		Free Software Foundation, Inc.
		59 Temple Place - Suite 330
		Boston, MA  02111-1307, USA
*/

/*
===========
SpectatorConnect

called when a spectator connects to the server
============
*/
void() SpectatorConnect =
{
	bprint("Spectator ");
	bprint(self.netname);
	bprint(" entered the server\n");

	self.goalentity = world;
};

/*
===========
SpectatorDisconnect

called when a spectator disconnects from the server
============
*/
void() SpectatorDisconnect =
{
	self.goalentity = world; // used for player entity tracking
	self.spectator = self.spectator - (self.spectator & (SPEC_FREEMOVE|SPEC_EYECAM));
	self.flags = (self.flags - (self.flags & FL_NOTARGET));
};

//Use this when going out of spec mode and joining the game
void() SpectatorEnd =
{
	self.goalentity = world;
	self.spectator = self.spectator - (self.spectator & (SPEC_FREEMOVE|SPEC_EYECAM));
	self.flags = (self.flags - (self.flags & FL_NOTARGET));//coop
	//reset the viewport
	msg_entity = self;
	WriteByte(MSG_ONE, SVC_SETVIEWPORT);
	WriteEntity(MSG_ONE, self);
	PutClientInServer ();
};

void() SpectatorImpulseCommand =
{
	switch (self.impulse)
	{
		case IMPULSE_SPECTATOREND:
		SpectatorEnd();
		break;
	}
	self.impulse = 0;//this must always be here!
};

void() SpectatorFreeMoveSetup =
{
	//reset the viewport
	msg_entity = self;
	WriteByte(MSG_ONE, SVC_SETVIEWPORT);
	WriteEntity(MSG_ONE, self);
	
	//reset the hud
	self.health = 1000;
	self.items = self.items - (self.items & (IT_AXE | IT_SHOTGUN | IT_SUPER_SHOTGUN | IT_NAILGUN | IT_SUPER_NAILGUN | IT_GRENADE_LAUNCHER | IT_ROCKET_LAUNCHER | IT_LIGHTNING | IT_ARMOR1 | IT_ARMOR2 | IT_ARMOR3));
	self.armorvalue = 0;
	self.ammo_shells = 0;
	self.ammo_nails = 0;
	self.ammo_rockets = 0;
	self.ammo_cells = 0;
	self.currentammo = 0;
	self.movetype = MOVETYPE_NOCLIP;
	self.weaponmodel = string_null;
	self.spectator = self.spectator - (self.spectator & SPEC_EYECAM);
	self.spectator = (self.spectator | SPEC_FREEMOVE);
	sprint(self,"Freecam mode.\n");
	//should we reset self.goalentity to world??
};

entity(entity p) SpectatorFindPlayer =
{
	local entity newguy;

	if ((p.classname != "player") || (p.classname == "spectator"))	//they disconnected or went into spectator mode.
	{
		p = world;
	}

	newguy = find(p, classname, "player");							//start looking from p (goalentity) for the next player.

	//Find an entity, starting at our current position on the link list; loops back around to world(0) then stops.
	while (((newguy == p) && (newguy != world)) || (p.classname == "spectator"))
		  newguy = find(newguy, classname, "player");

	return newguy;
};

void() SpectatorUpdateEyeCam =
{
	msg_entity = self;
	WriteByte(MSG_ONE, SVC_SETVIEWPORT);
	WriteEntity(MSG_ONE, self.goalentity);

	self.weaponmodel	= self.goalentity.weaponmodel;
	self.weaponframe	= self.goalentity.weaponframe;
	//R00k: Let's update the HUD
	self.health			= self.goalentity.health;
	self.items			= self.goalentity.items;
	self.armorvalue		= self.goalentity.armorvalue;
	self.ammo_shells	= self.goalentity.ammo_shells;
	self.ammo_nails		= self.goalentity.ammo_nails;
	self.ammo_rockets	= self.goalentity.ammo_rockets;
	self.ammo_cells		= self.goalentity.ammo_cells;
	self.currentammo	= self.goalentity.currentammo;

	setorigin(self, self.goalentity.origin);

	self.view_ofs		= self.goalentity.view_ofs;
	self.v_angle		= self.angles = self.goalentity.v_angle;
	self.fixangle		= TRUE;
};

void() SpectatorEyeCamSetup =
{
	if ((self.goalentity == world) || (self.goalentity.classname == "spectator"))
	{
		self.goalentity = SpectatorFindPlayer(self.goalentity);

		if (self.goalentity == world)
		{
			SpectatorFreeMoveSetup();
			return;
		}
	}

	sprint(self, "Eyecam mode.\n");

	self.view_ofs = '0 0 22';
	setmodel(self, "progs/eyes.mdl");//todo create a null sprite and use that instead
	setsize(self, VEC_HULL_MIN, VEC_HULL_MAX);
	//self.alpha 		= 1;
	self.model		= string_null;
	self.mdl		= string_null;
	self.movetype	= MOVETYPE_FLY;
	self.spectator	= self.spectator - (self.spectator & SPEC_FREEMOVE);
	self.spectator	= (self.spectator | SPEC_EYECAM);

	centerprint(self, self.goalentity.netname);
};

/*
================
SpectatorThink

Called every frame after physics are run
================
*/

void() SpectatorThink =
{
	if (self.spectator & SPEC_EYECAM)
	{
		if (self.button2)	//Use JUMP to switch between players
		{
			if (self.flags & FL_JUMPRELEASED)
			{
				self.flags = self.flags - (self.flags & FL_JUMPRELEASED);
				self.goalentity = SpectatorFindPlayer(self.goalentity);
				
				if (self.goalentity != world)
					centerprint(self, self.goalentity.netname);

				if (self.goalentity == world)
				{
					self.flags = (self.flags | FL_JUMPRELEASED);
					return;
				}
			}
		}
		else
		{
			self.flags = (self.flags | FL_JUMPRELEASED);
		}

		if (self.goalentity != world)
		{
			SpectatorUpdateEyeCam();
		}
	}

	//Use the fire button to switch between freemove and eyecam
	if ((self.button0) && (time > self.attack_finished))
	{
		if (self.spectator & SPEC_FREEMOVE)
		{
			SpectatorEyeCamSetup();
		}	
		else
		{
			SpectatorFreeMoveSetup();
		}					

		self.button0 = FALSE;
		self.attack_finished = time + 0.8;
	}
	//TODO add a condition for intermission
}
/*
	ItsLonelyOutHere

	Check if all CoOp players are dead; if so then restart the map.
*/
void(void) ItsLonelyOutHere =
{
	local entity anyonehome;

	anyonehome = find(world, classname, "player");					// start at world and go thru all entities to find the 1st player

	while (anyonehome != world) 							// if we found a player then...
	{
		if ((anyonehome.classname != "spectator") && (anyonehome.health > 0))   // check to see if they are not a spectator, and alive
			return;								// if they are then go back to StartFrame and update the last_client_check
		else									// otherwise
			anyonehome = find(anyonehome, classname, "player");		// look for any more players, then go back thru the loop ^^^
	}
	// if we didnt find any more players, anyonehome looped back to world..
	bprint("\nRestarting Map...Please Wait.\n");//R00k				// Notify all players...
	changelevel(mapname);								// Restart the current map; but keep our weapons/stats
};

/*
===========
 SpectatorStart

 Initializes the player spectator mode.
===========
*/
void () SpectatorStart =
{
	self.spectator 		= (self.spectator | SPEC_FREEMOVE);		// Default
	self.goalentity		= world;					// used for player entity tracking
	self.takedamage 	= DAMAGE_NO;                                    // cannot be hurt
	self.classname		= "spectator";
	self.solid 			= SOLID_NOT;                                    // no collision with the map and objects
	self.effects 		= 0;                                            // no glowing from powerups etc.
	self.flags 			= (self.flags | FL_NOTARGET);                   // in coop we dont want monsters attacking spectators.
	self.flags 			= self.flags - (self.flags & FL_ONGROUND);	// no bobbing.
	self.movetype		= MOVETYPE_NOCLIP;
	self.view_ofs 		= '0 0 22';					// position our pov at eye-level.
	self.health			= 1000;						//the hud only has 3 digits for health so, specators will see 000 by default.
	self.items 			= self.items - (self.items & (IT_AXE | IT_SHOTGUN | IT_SUPER_SHOTGUN | IT_NAILGUN | IT_SUPER_NAILGUN | IT_GRENADE_LAUNCHER | IT_ROCKET_LAUNCHER | IT_LIGHTNING | IT_ARMOR1 | IT_ARMOR2 | IT_ARMOR3));
	self.armorvalue 	= 0;
	self.ammo_shells 	= 0;
	self.ammo_nails 	= 0;
	self.ammo_rockets 	= 0;
	self.ammo_cells 	= 0;
	self.currentammo 	= 0;
	self.show_hostile 	= 0;
	self.waterlevel 	= 0;
		
	//The server needs to assign our entity a model or else we won't be updated on the server-side.	
	setmodel(self, "progs/spike.mdl");//testing: giving the specator a valid model to make sure the server doesnt skip us on updated packets...
	setsize (self, VEC_HULL_MIN, VEC_HULL_MAX);
	//But, send the other clients a null model so they can't see us.
	self.model			= "progs/spike.mdl";
	self.mdl			= "progs/spike.mdl";
	//self.alpha			= 1;//just barely visible
	self.nextthink		= -1;
	self.think 			= SUB_Null;
	//self.modelindex 	= self.modelindex;
	self.weaponmodel	= string_null;
	self.weapon 		= 0;	
	self.flags			= self.flags - (self.flags & FL_INWATER);
	self.wait 			= time + 1;
	self.delay 			= 0;

	if (coop)
		ItsLonelyOutHere();//check if we need to restart the map
};
