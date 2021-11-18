float last_leader;
float current_leader;

float	intermission_running;
float	intermission_exittime;

void StartItem();

entity findPlayer(entity start) {
    return find(start,classname,"player");
}

entity findPlayerSpawn(entity start,float findTeam) {
    local entity ent = start;

    while(1) {
        ent = find(ent,classname,"info_player_deathmatch");

        if(!ent)
            return findPlayerSpawn(world,findTeam);

        if(ent.team != TEAM_ALL || ent.team != findTeam)
            continue;

        return ent;
    }
    
    return FALSE;
}


//===============================================================

//ONE HIT KILLS

//===============================================================


//========= One Hit Kills Deathmatch connection message

.float		ohkd_count;
.float		ohkd_time;

void() OneHitKillsMessage =
{
    if ((self.ohkd_count < 4) && (self.ohkd_time < time)) // 6 == seconds MOTD will display
    {
        self.ohkd_time = time + 1;
        self.ohkd_count = self.ohkd_count + 1;
        centerprint(self, "Unofficial === InstaGib === Version 2.0\nWelcome to InstaGib. Use the Axe to grapple and release."); 
        return;
    }
};


//========= One Hit Kills Deathmatch timer

void() OneHitKillsTimer =
{
	local	float		timelim;
	local float		remaining;
	local float 		x;
	local float		y;

	if (!deathmatch)return; 

	if (gameover) return;	

	timelim = cvar("timelimit") * 60;
	if (!timelim) return;			

	remaining = ceil(timelim - time);	
	x = floor(remaining / 60);	
	y = remaining - (x * 60);	

	if ((x == 60) && (y == 0)) centerprint (self,"An Hour Left\n");
	if ((x == 30) && (y == 0)) centerprint (self, "30 Minutes left\n");
	else if ((x == 20) && (y == 0)) centerprint (self, "20 Minutes left\n");
	else if ((x == 10) && (y == 0)) centerprint (self, "10 Minutes left\n");
	else if ((x == 5) && (y == 0)) centerprint (self, "5 Minutes Left\n");
	else if ((x == 4) && (y == 0)) centerprint (self, "4 Minutes Left\n");	
	else if ((x == 3) && (y == 0)) centerprint (self, "3 Minutes Left\n");
	else if ((x == 2) && (y == 0)) centerprint (self, "2 Minutes Left\n");	
	else if ((x == 1) && (y == 0)) centerprint (self, "1 Minute Left\n");	
	else if ((y == 30) && (x == 0)) centerprint (self, "30 Seconds Left\n");
	else if ((y == 20) && (x == 0)) centerprint (self, "20 Seconds Left\n");
	else if ((y == 10) && (x == 0)) centerprint (self, "10 Seconds Left\n");
	else if ((y == 5) && (x == 0)) centerprint (self, "5 Seconds Left\n");
};


//GIB STATS


.float prev_frags;  
.float is_on_spree;

void(entity client, string s, string s) announce_start_spree = #73;
void(entity client, string s, string s, string s, string s) announce_end_spree = #73;
void(entity client, string s, string s) announce_end_spree2 = #73;

entity(entity start) find_player =
{
    return find(start,classname,"player");
}

void(entity attacker, entity targ) announce_end_killspree =
{
    local entity p = world;
    while((p = find_player(p))) 
    {
        
        if (attacker.netname == targ.netname) { announce_end_spree2(p,attacker.netname, "ended their own killing spree!"); }
        else
        {
            // sometimes this seems to be empty, so lets check?
            if (attacker.netname) { announce_end_spree(p,attacker.netname," ended ", targ.netname,"'s killing spree!\n"); }
            else { announce_end_spree2(p,targ.netname,"'s killing spree was ended.\n"); }  
        }
    }
}


void(entity player) check_if_killspree =
{
    local entity p = world;
	local float current_streak;
	current_streak = player.frags - player.prev_frags;

    if (current_streak == 3 && player.is_on_spree != 1)
    { 
		player.is_on_spree = 1;
        while((p = find_player(p))) { announce_start_spree(p,player.netname,"\n is on a killing spree!\n"); }  
    }	
    else if (current_streak == 6 && player.is_on_spree == 1)
    {	
        player.is_on_spree = 2;
        while((p = find_player(p))) { announce_start_spree(p,player.netname,"\n is on a killing frenzy!\n"); }  
	}	
    else if (current_streak == 9 && player.is_on_spree == 2)
    {
        player.is_on_spree = 3;
        while((p = find_player(p))) { announce_start_spree(p,player.netname,"\n is on a killing rampage!\n"); }  
	}
    else if (current_streak == 12 && player.is_on_spree == 3)
    {
        player.is_on_spree = 4;
        while((p = find_player(p))) { announce_start_spree(p,player.netname,"\n is unstoppable!\n"); }  
	}
}


void(entity player) reset_killspree =
{
    player.is_on_spree = 0;
    player.prev_frags = player.frags;
}

void (entity attacker, entity targ) check_if_end_killspree =
{
    if (targ.is_on_spree != 0) { announce_end_killspree(attacker, targ); }
    reset_killspree(targ);
}


/*

float() tdm_game_getFragsLeft =
{
      local entity p = world;
      local float team_score = 0;
	local float enemy_score = 0;
	local float otherTeam = self.team == TEAM_BLUE ? TEAM_RED : TEAM_BLUE;

	team_score = tdm_game_getTeamScore(self.team);
	enemy_score = tdm_game_getTeamScore(otherTeam);
		
	local float is_leading = 0;
	if (team_score >= enemy_score) { is_leading = 1; }
	else { is_leading = 0; }

	if (is_leading == 1){ return (tdm_fraglimit - team_score);}
	else {return (tdm_fraglimit - enemy_score);}
}
*/

/*
float() tdm_player_highScoreOnLeadingTeam =
{

        local entity p = world;
	local float otherTeam = self.team == TEAM_BLUE ? TEAM_RED : TEAM_BLUE;

	local float high_score = 0;

	enemy_score = tdm_game_getTeamScore(otherTeam);

	while((p = findPlayer(p))) {
      	if (p.frags > high_score)
            {
              	high_score = p.frags;
          	}
      }

	return high_score;
}
*/

float() tdm_player_highScore =
{

      local entity p = world;

	local float high_score = 0;

	while((p = findPlayer(p))) {
      	if (p.frags > high_score)
            {
              	high_score = p.frags;
          	}
      }

	return high_score;
}