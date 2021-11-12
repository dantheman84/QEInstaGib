

// Maximum length of the hook's chain.

float HOOK_MAX_CHAIN_LEN	= 1600;

// Various other hook constants.

float HOOK_TRAVEL_SPEED		= 2500;
float HOOK_LINK_COUNT		= 6;


void () DrawBeam = 
{
   local vector org;
   org = (self.origin) + '0 0 16';
   WriteByte(MSG_BROADCAST, SVC_TEMPENTITY);
   WriteByte(MSG_BROADCAST, TE_LIGHTNING1);
   WriteEntity(MSG_BROADCAST, world);
   WriteCoord(MSG_BROADCAST, org_x);
   WriteCoord(MSG_BROADCAST, org_y);
   WriteCoord(MSG_BROADCAST, org_z);
   WriteCoord(MSG_BROADCAST, self.hook.origin_x);
   WriteCoord(MSG_BROADCAST, self.hook.origin_y);
   WriteCoord(MSG_BROADCAST, self.hook.origin_z);	
};


// Updated calculation of link positions

void ()
LinkPos =
{
	setorigin (self, self.owner.origin
			+ (self.enemy.origin + PLAYER_WEAPON_OFFSET - self.owner.origin)
			* self.weapon);
	self.angles = vectoangles (self.owner.origin - self.enemy.origin);
	self.nextthink = time + 0.01;
};



// Creates chain

entity (entity head, entity tail, float num)
CreateChain =
{
	local entity link, prevlink;
	local float linknum;

	linknum = num;
	num = num + 1;
	prevlink = world;
	while (linknum > 0)
	{
		link = spawn ();
		link.goalentity = prevlink;
		prevlink = link;
		link.owner = head;
		link.enemy = tail;
		link.weapon = linknum / num;
		link.movetype = MOVETYPE_NOCLIP;
		link.solid = SOLID_NOT;
		link.effects = EF_MAYBE_DRAW;
		setmodel (link, "progs/s_bubble.spr");
		setsize (link, VEC_ORIGIN, VEC_ORIGIN);
		link.think = LinkPos;
		link.nextthink = time;
		linknum = linknum - 1;
	}
	return link;
};

void() pull =
{
		if (self.owner.hooking == 1)
		{
		self.owner.velocity = normalize(self.origin - self.owner.origin);
		self.owner.velocity = self.owner.velocity * 500;
		self.think = pull;
		self.nextthink = time + 0.1;
		}
		else
		{
		self.owner.hooking = 0;
		remove(self);
		sound (self.owner, CHAN_WEAPON, "weapons/ax1.wav", 1, ATTN_NORM);
		}	
};

void() hookdamage =
{
if (self.enemy.health > 0)
{
	self.owner.velocity = normalize(self.origin - self.owner.origin);
	self.owner.velocity = self.owner.velocity * 500;
	
	T_Damage(self.enemy, self, self.owner, 2);

	self.origin = self.enemy.origin;
	self.think = hookdamage;
	self.nextthink = time + 0.1;
}
else
{
	self.owner.hooking = 0;
	remove(self);
	sound (self.owner, CHAN_WEAPON, "weapons/ax1.wav", 1, ATTN_NORM);	
}
};

void() BreakHook =
{
	if( self.hooking == 1)
	{
	remove(self.hook);
	self.hooking = 0;
	sound (self, CHAN_WEAPON, "shalrath/attack2.wav", 1, ATTN_NORM);	
	}
};


void() PullHook =
{
	
       // player died
	if (self.owner.health <= 0)
	{
		BreakHook();
	}
	// target died
	else if (self.enemy != world && ((self.enemy.solid == SOLID_NOT) || (self.enemy.takedamage && self.enemy.health <=0)))
	{
		BreakHook();
	}
	
	if (other == self.owner)
		return;
 


    if (other == world) // Pull
    {
            self.solid = SOLID_NOT;
            self.movetype = MOVETYPE_NONE;
            self.think = pull;
            self.nextthink = time;
      }
    
    if (other.takedamage && other.health)
    {
            self.think = hookdamage;
            self.enemy = other;
            self.solid = SOLID_NOT;
            self.nextthink = time;

    }

    sound (self.owner, CHAN_WEAPON, "weapons/ax1.wav", 1, ATTN_NORM);

};


void () FireHook =
{
	local entity hooky;
	hooky = spawn();
	setorigin(hooky, self.origin + self.view_ofs);
	setmodel(hooky, "progs/s_spike.mdl");
	setsize (hooky, '0 0 0', '0 0 0');
	hooky.solid = SOLID_BBOX;
	hooky.movetype = MOVETYPE_FLYMISSILE;
	makevectors(self.v_angle);
	self.aiment = hooky;
	hooky.velocity = v_forward * 2500;
	hooky.owner = self;
	self.hook = hooky;
	hooky.classname = "hookend";
	self.hooking = 1;
	hooky.touch = PullHook;
	//hooky.cansplash = 1; // If my splash tutorial is installed, uncomment this line
	sound (self, CHAN_WEAPON, "weapons/ax1.wav", 1, ATTN_NORM);	
	//hooky.goalentity = CreateChain(hooky,self,HOOK_LINK_COUNT);
	
};

void() CheckRope =
{
	
	if (self.hooking == 1 && self.hook.classname == "hookend")
	{
		DrawBeam();
	}

};