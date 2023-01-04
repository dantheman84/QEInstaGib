void() rail_fade = {
	
	local float rand;
	rand = random();
	
		
	self.think = rail_fade;
	self.nextthink = time + 0.1;

	if (self.cnt == 6)
		self.alpha = self.alpha - 0.19;
		if(self.alpha <= 0) self.alpha = 0.01;
	else if (self.cnt == 5)
	{
		
		if (rand < 0.20)          //randomly deleting segments
			{
				self.think = SUB_Remove;
				self.nextthink = time + 0.05;
				self.cnt = self.cnt - 1;
				return;
			}
		
		
		self.alpha = self.alpha - 0.19;
		if(self.alpha <= 0) self.alpha = 0.01;
	}	
	else if (self.cnt == 4)
	{
		
			if (rand < 0.10)          //randomly deleting segments
			{
				self.think = SUB_Remove;
				self.nextthink = time + 0.05;
				self.cnt = self.cnt - 1;
				return;
			}
		
		self.alpha = self.alpha - 0.19;
		if(self.alpha <= 0) self.alpha = 0.01;
	}
	else if (self.cnt == 3)
	{
		
			if (rand < 0.08)          //randomly deleting segments
			{
				self.think = SUB_Remove;
				self.nextthink = time + 0.05;
				self.cnt = self.cnt - 1;
				return;
			}
		if(self.alpha == 0.01) self.alpha = 0.01;
		else
		self.alpha = 0.08;
		
	}
	else if (self.cnt == 2)
	{	
		
			if (rand < 0.08)          //randomly deleting segments
			{
				self.think = SUB_Remove;
				self.nextthink = time + 0.05;
				self.cnt = self.cnt - 1;
				return;
			}
		if(self.alpha == 0.01) self.alpha = 0.01;
		else
		self.alpha = 0.05;
	}
	else if (self.cnt == 1) {
		self.alpha = 0.02;
		self.think = SUB_Remove;
		self.nextthink = time + 0.05;
		
	}	
	self.cnt = self.cnt - 1;
};

void(vector start, vector end, vector myAngles, entity shooter) W_FireRail =
{
	local vector vec,  loopsrc,  destination;
	local vector drawsrc;
	local entity thedude;
	local float traillen, segments, old_segments;
	entity prj;
	local float rotation_amount;
	local float alpha_rand;
	local float spacing_long;
	
	local vector shootDir = end-start;
	shootDir = normalize(shootDir);
	local vector forwardAngles = vectoangles(shootDir);
	makevectors(forwardAngles);

	drawsrc = start;

	destination = end ;
	
	loopsrc = drawsrc;
	thedude = self;
	


	// now using drawsrc instead of src now, so we trace damage from eye position and trail from gun position
	traceline(drawsrc, destination, TRUE, self);
	traillen = vlen(trace_endpos - drawsrc);
	if (traillen > 2500 && (pointcontents(trace_endpos) == CONTENT_SKY)) traillen = traillen - 1300;       // 1800 -> 2800 , 900 -> 1300   // RAIL DRAW ISSUE RAIL NOT DRAWING explore this
	segments = floor(traillen / 50);
	
	//sprint(self, ftos(segments));
	if(segments>50) segments = 50;
	old_segments = segments;

	

	if (segments <= 50 && shooter == self)
	{
		//if (traillen > 1800 && (pointcontents(trace_endpos) == CONTENT_SKY)) traillen = traillen - 800;
		//segments = floor(traillen / 50);
		
		//sprint(self, ftos(segments));
		//sprint(self, ftos(traillen), " ");
	while (segments)
	{
		vec = normalize(trace_endpos - drawsrc);
		prj = spawn ();
		
		prj.owner = self;
		prj.movetype = MOVETYPE_NOCLIP;
		prj.solid = SOLID_NOT;
		  prj.angles = vectoangles(shootDir);
		
		prj.touch = SUB_Null;
		prj.classname = "railtrail";
		setmodel (prj, "progs/laser.mdl");
				
		setsize (prj, 0, 0);	
		
		
		
		setorigin (prj, drawsrc + vec * 50 * segments);
		prj.velocity = '0 0 0';	
		
	
		
			alpha_rand = random();
			if (alpha_rand < 0.5) prj.alpha = 0.60;
			else prj.alpha = 1;
		
		//teamred's magic
		
			
			
			prj.avelocity_x = random()-0.5;
			prj.avelocity_y = random()-0.5;
			prj.avelocity_z = random()-0.5;
		
			prj.avelocity = normalize(prj.avelocity);
			rotation_amount = 18.0;
			prj.avelocity = prj.avelocity*rotation_amount;
			

		prj.frame = 4;	
		prj.think = rail_fade;
		prj.nextthink = time + 0.2 + (segments*0.002); //fade delay
		segments = segments - 1;
		prj.cnt = 5;	
	
	}
}}