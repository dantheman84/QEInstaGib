//Decompiled code. Please respect the original copyright.

void(entity Head) BreakChain =
{
	local entity link;

	link = Head.goalentity;
	while ((link != world))
	{
		Head = link.goalentity;
		remove(link);
		link = Head;
	}
};

void() LinkPos =
{
	makevectors(self.enemy.angles);
	setorigin(self, (self.owner.origin + ((((self.enemy.origin + ((v_up * FL_INWATER) * !self.enemy.button2)) + (v_forward * FL_INWATER)) - self.owner.origin) * self.weapon)));
	self.nextthink = (time + 0.1);
};

entity(entity head, entity tail, float num) MakeChain =
{
	local entity link;
	local entity prevlink;
	local float linknum;

	linknum = num;
	num = (num + TRUE);
	prevlink = world;
	while ((linknum > FALSE))
	{
		link = spawn();
		link.goalentity = prevlink;
		prevlink = link;
		link.owner = head;
		link.enemy = tail;
		link.weapon = (linknum / num);
		link.movetype = MOVETYPE_NOCLIP;
		link.solid = SOLID_NOT;
		link.angles_z = (51 * linknum);
		link.angles_y = (41 * linknum);
		link.angles_x = (SVC_FINALE * linknum);
		link.avelocity = '310 410 510';
		setmodel (link, "progs/s_spike.mdl");
		setsize(link, VEC_ORIGIN, VEC_ORIGIN);
		makevectors(tail.angles);
		setorigin(link, (head.origin + ((((tail.origin + ((v_up * FL_INWATER) * !tail.button2)) + (v_forward * FL_INWATER)) - head.origin) * link.weapon)));
		link.nextthink = (time + 0.1);
		link.think = LinkPos;
		linknum = (linknum - TRUE);
	}
	return (link);
};

void() HookVanish =
{
	self.owner.hook_out = FALSE;
	BreakChain(self);
	remove(self);
};

void() UnHookPlayer =
{
	local entity oself;

	if (self.hook_out)
	{
		oself = self;
		self = self.goalentity;
		HookVanish();
		self = oself;
	}
};

void() HookPull =
{
	local vector vel;
	local vector spray;
	local float v;
	local float dorg;

	if ((((!self.owner.button0 && (self.owner.weapon == IT_AXE)) || (self.owner.teleport_time > time)) || self.owner.deadflag))
	{
		HookVanish();
		return;
	}
	else
	{
		if (self.enemy.takedamage)
		{
			if ((((self.enemy.classname != "player") || !teamplay)))
			{
				if (!CanDamage(self.enemy, self.owner))
				{
					HookVanish();
					return;
				}
				sound(self, CHAN_WEAPON, "shambler/smack.wav", TRUE, ATTN_NORM);
				T_Damage(self.enemy, self, self.owner, 15);
				makevectors(self.v_angle);
				spray_x = (100 * crandom());
				spray_y = (100 * crandom());
				spray_z = ((100 * crandom()) + 50);
				SpawnBlood(self.origin, spray, 20);
			}
			if ((self.enemy.solid == SOLID_SLIDEBOX))
			{
				self.velocity = VEC_ORIGIN;
				setorigin(self, ((self.enemy.origin + self.enemy.mins) + (self.enemy.size * 0.5)));
			}
			else
			{
				self.velocity = self.enemy.velocity;
			}
		}
		else
		{
			self.velocity = self.enemy.velocity;
		}
		if ((self.enemy.solid == SOLID_NOT))
		{
			HookVanish();
			return;
		}
		makevectors(self.owner.angles);
		vel = (self.origin - ((self.owner.origin + ((v_up * FL_INWATER) * !self.owner.button2)) + (v_forward * FL_INWATER)));
		v = vlen(vel);
		if ((v <= 100))
		{
			vel = ((normalize(vel) * v) * MOVETYPE_BOUNCE);
		}
		if ((v > 100))
		{
			vel = (normalize(vel) * 1000);
		}/*
		if ((teamplay & TEAM_CAPTURE_CUSTOM))
		{
			dorg = vlen((self.owner.origin - self.dest));
			if (((dorg > MOVETYPE_BOUNCE) && (self.style == MOVETYPE_WALK)))
			{
				sound(self.owner, CHAN_WEAPON, ((void())0x21d5i), TRUE, ATTN_NORM);
				self.style = FL_SWIM;
			}
			if (((dorg < MOVETYPE_BOUNCE) && (self.style == FL_SWIM)))
			{
				sound(self.owner, CHAN_WEAPON, ((void())0x21e8i), TRUE, ATTN_NORM);
				self.style = MOVETYPE_WALK;
			}
		}*/
		self.owner.velocity = vel;
		self.dest = self.owner.origin;
		self.nextthink = (time + 0.1);
	}
};

void() T_ChainTouch =
{
	if ((other == self.owner))
	{
		return;
	}
	if ((pointcontents(self.origin) == CONTENT_SKY))
	{
		HookVanish();
		return;
	}
	/*
	if ((((other.classname == "player") && teamplay) && (other.team == self.owner.lastteam)))
	{
		return;
	}*/
	if (other.takedamage)
	{
		if ((other.classname == "player"))
		{
			other.axhitme = TRUE;
		}
		else
		{
			sound(self, CHAN_WEAPON, "weapons/ax1.wav", TRUE, ATTN_NORM);
		}
		T_Damage(other, self, self.owner, MOVETYPE_BOUNCE);
		SpawnBlood(self.origin, self.velocity, MOVETYPE_BOUNCE);
	}
	else
	{
		sound(self, CHAN_WEAPON, "weapons/ax1.wav", TRUE, ATTN_NORM);
		self.avelocity = VEC_ORIGIN;
	}
	if (!self.owner.button0)
	{
		HookVanish();
		return;
	}
	else
	{
		if ((other.solid == SOLID_SLIDEBOX))
		{
			setorigin(self, ((other.origin + other.mins) + (other.size * 0.5)));
			self.velocity = VEC_ORIGIN;
		}
		else
		{
			self.velocity = other.velocity;
		}
		self.weapon = (other.nextthink - time);
		/*
		if ((teamplay & TEAM_CAPTURE_CUSTOM))
		{
			sound(self.owner, CHAN_WEAPON, "weapons/ax1.wav", TRUE, ATTN_NORM);
		}
		*/
		self.style = FL_SWIM;
		self.enemy = other;
		self.nextthink = (time + 0.1);
		self.think = HookPull;
		self.touch = SUB_Null;
	}
};

void() W_FireChain =
{
	local entity hook;

	self.hook_out = TRUE;
	hook = spawn();
	hook.owner = self;
	self.goalentity = hook;
	hook.movetype = MOVETYPE_FLY;
	hook.solid = SOLID_BBOX;
	makevectors(self.v_angle);
	hook.velocity = aim(self, 1000);
	hook.velocity = (hook.velocity * 1500);
	hook.angles = vectoangles(hook.velocity);
	hook.avelocity = '0 0 -500';
	hook.touch = T_ChainTouch;
	hook.nextthink = (time + MOVETYPE_FLY);
	hook.think = HookVanish;
	/*
	if ((teamplay & TEAM_CAPTURE_CUSTOM))
	{
		setmodel(hook, ((void())0x314bi));
	}
	else
	{*/
		setmodel(hook, "progs/s_spike.mdl");
	//}
	setsize(hook, VEC_ORIGIN, VEC_ORIGIN);
	setorigin(hook, ((self.origin + (v_forward * FL_INWATER)) + '0 0 16'));
	/*if ((teamplay & TEAM_CAPTURE_CUSTOM))
	{
		sound(self, CHAN_WEAPON, ((void())0x21c2i), TRUE, ATTN_NORM);
	}*/

		sound(self, CHAN_WEAPON, "weapons/ax1.wav", TRUE, ATTN_NORM);

	hook.goalentity = MakeChain(hook, self, MOVETYPE_WALK);
};
