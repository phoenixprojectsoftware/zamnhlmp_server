/* AMX Mod X script
*   Lambda Core: Half-Life ingame stats
*
* by KORD_12.7
*
*
*  This program is free software; you can redistribute it and/or modify it
*  under the terms of the GNU General Public License as published by the
*  Free Software Foundation.
*
*  This program is distributed in the hope that it will be useful, but
*  WITHOUT ANY WARRANTY; without even the implied warranty of
*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
*  General Public License for more details.
*
*  You should have received a copy of the GNU General Public License
*  along with this program; if not, write to the Free Software Foundation, 
*  Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
*/

/*
* More information: 
*
*  http://aghl.ru/forum/viewtopic.php?f=19&t=23 - Russian HL and AG Community
*  http://amx-x.ru/viewtopic.php?f=12&t=109 - Russian AMXX Community
*  http://forums.alliedmods.net/showthread.php?p=1097488 - Official AMXX forum
*/

//--------------------------------
#include <amxmodx>
#include <amxmisc>
#include <fakemeta_util>
#include <hamsandwich>
//--------------------------------

#define PLUGIN	"Lambda Core"
#define VERSION "0.6"
#define LASTUPDATE "30, December (12), 2010"
#define AUTHOR "KORD_12.7" // icq 563668196

#define MAX_PLAYERS		32
#define MAX_BUFFER_LENGTH	2047

#define PING_TASK_ID		14586
#define CHANGE_LEVEL_TASK_ID	62148 
#define SHOW_ADV_TASK_ID	89551

#define OP4_GRAPPLE		16
#define OP4_EAGLE		17
#define OP4_WRENCH		18
#define OP4_M249		19
#define OP4_DISPLACER		20
#define HLW_BOLT		21
#define OP4_SHOCKBEAM		22
#define OP4_SPORE		23
#define OP4_M40A1		24
#define OP4_KNIFE		25
#define HLW_TANK		26

#define EXTRAOFFSET		5
#define EXTRAOFFSET_WEAPONS	4

#define PPL_MENU_OPTIONS        7
#define HUD_DURATION		20.0

#define PREFIX	"[Lambda Core]"

#define BOT_TEST

enum _:MODS
{
	INVALID,
	HL,
	OP4,
	AG,
	MINIAG,
	PHOENIX
}

enum _:MOD_OFFSETS
{
	WEAPONCLIP,
	LAST_HIT_GROUP,
	ACTIVEITEM,
	AMMO_SHOTGUN,
	AMMO_9MM,	// MP5, GLOCK
	AMMO_ARGRENADE,	// M-203
	AMMO_PYTHON,
	AMMO_URANIUM,	// GAUSS, EGON
	AMMO_RPG,
	AMMO_CROSSBOW,
	AMMO_TRIPMINE,
	AMMO_SATCHEL,
	AMMO_HEGRENADE,	// HAND GRENADE
	AMMO_SNARK,
	AMMO_HORNET,
	AMMO_M249,
	AMMO_SPORE,
	AMMO_SHOCKBEAM,
	AMMO_M40A1
}

enum _:STATS
{
	STATS_KILLS,
	STATS_DEATHS,
	STATS_HEADSHOTS,
	STATS_TEAMKILLS,
	STATS_SHOTS,
	STATS_HITS,
	STATS_DAMAGE,
	
	STATS_END
}

enum _:KILL_EVENT
{
	NORMAL,
	SUICIDE,
	WORLD,
	WORLDSPAWN
}

new const BODY_PART[][] =
{
	"WHOLEBODY", 
	"HEAD", 
	"CHEST", 
	"STOMACH", 
	"LEFTARM", 
	"RIGHTARM", 
	"LEFTLEG", 
	"RIGHTLEG"
}

new const g_guns_events[][] = 
{
	"events/glock1.sc",
	"events/glock2.sc",
	"events/crossbow1.sc",
	"events/crossbow2.sc",
	"events/rpg.sc",
	"events/crowbar.sc",
	"events/firehornet.sc",
	"events/gauss.sc",
	"events/gaussspin.sc",
	"events/mp5.sc",
	"events/mp52.sc",
	"events/python.sc",
	"events/shotgun1.sc",
	"events/shotgun2.sc",
	"events/snarkfire.sc",
	"events/tripfire.sc",
	"events/penguinfire.sc",
	"events/eagle.sc",
	"events/displacer.sc",
	"events/knife.sc",
	"events/m249.sc",
	"events/pipewrench.sc",
	"events/shock.sc",
	"events/sniper.sc",
	"events/spore.sc",
	"events/egon_effect.sc"
}

new const 	
stats_dir[] =		"/lc/",
stats_name[] =		"lc_stats.dat"

new
g_MapWeaponsStats[MAX_PLAYERS + 1][HLW_TANK + 1][STATS],
g_MapWeaponsBodyhits[MAX_PLAYERS + 1][HLW_TANK + 1][HIT_RIGHTLEG + 1],
g_MapPlayersStats[MAX_PLAYERS + 1][STATS],
g_RespawnWeaponsStats[MAX_PLAYERS + 1][HLW_TANK + 1][STATS],
g_RespawnWeaponsBodyhits[MAX_PLAYERS + 1][HLW_TANK + 1][HIT_RIGHTLEG + 1],
g_RespawnPlayersStats[MAX_PLAYERS + 1][STATS],
g_VictimsStats[MAX_PLAYERS + 1][MAX_PLAYERS + 1][STATS],
g_VictimsBodyhits[MAX_PLAYERS + 1][MAX_PLAYERS + 1][HIT_RIGHTLEG + 1],
g_VictimsWeapon[MAX_PLAYERS + 1][MAX_PLAYERS + 1][1],
g_AttackersStats[MAX_PLAYERS + 1][MAX_PLAYERS + 1][STATS],
g_AttackersBodyhits[MAX_PLAYERS + 1][MAX_PLAYERS + 1][HIT_RIGHTLEG + 1],
g_AttackersWeapon[MAX_PLAYERS + 1][MAX_PLAYERS + 1][1],
g_VictimDistance[MAX_PLAYERS + 1][MAX_PLAYERS + 1],
g_AttackerDistance[MAX_PLAYERS + 1],   
g_hpAnnounce[MAX_PLAYERS + 1][256],
g_IsOnServer[MAX_PLAYERS + 1],
Float: g_egon_delay[MAX_PLAYERS + 1],
g_pingCount[MAX_PLAYERS + 1],
g_pingSum[MAX_PLAYERS + 1],
g_StatsSwitch[MAX_PLAYERS + 1],
g_userPosition[MAX_PLAYERS + 1],
g_userState[MAX_PLAYERS + 1],
g_userPlayers[MAX_PLAYERS + 1][32]

new
g_MOD, g_fwid, g_guns_eventids_bitsum, g_maxPlayers, g_Offsets[MOD_OFFSETS],
g_cvarTeamPlay, g_cvarTeamlist, g_DataFile[512], g_spriteTexture, g_info_sync, 
g_at_sync, g_vic_sync, g_kill_sync, g_Cmds[128], g_logmessage_ignore[128]

new
g_enableRanksCvar,
g_StatsTrackMode,
g_RankBotCvar, 
g_PruneTime,
g_ShowInfoCvar, 
g_show_adv, 
g_logCvar, 
g_adv_freq

new
Array: g_ArrayAuth,
Trie: g_TrieNames,
Trie: g_TrieStats,
Trie: g_TrieBodyhits,
Trie: g_TrieTimestamps,
Trie: g_WeaponNames,
Trie: g_EntAttackList,
Trie: g_MinesOwners

// For statscfg menu
public KillerChat	// displays killer info to victim console and screen
public ShowAttackers	// shows attackers
public ShowVictims	// shows victims
public ShowKiller	// shows killer
public ShowBeam		// shows death beam

public ShowHP_AP	// display killer hp&ap in hud and chat
public ShowDistHS 	// show distance and HS in attackers and victims HUD lists

public SayRank		// displays user's rank
public SayTop		// displays first 15 players
public SayStats		// displays all players stats and rank
public SayRankStats	// displays user's rank stats
public SayStatsMe	// displays user's stats and rank
public SayHP		// displays information about user killer
public SayMe		// displays user's stats
public SayReport	// report user's weapon status to team

public EndPlayer	// displays player stats at the end of map
public EndTop15		// displays top15 at the end of map
public EndWinner	// displays winner at the end of map

new 
g_KillForward,
g_KillForwardReturn,
g_DamageForward,
g_DamageForwardReturn

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_cvar("lambda_version", VERSION, FCVAR_SERVER)
	
	register_dictionary("lambda_core.txt")
	register_dictionary("statsx.txt")
	
	register_clcmd("say", "handle_say")
	register_clcmd("say_team", "handle_say")
	
	register_concmd("lc_reset", "CmdReset", ADMIN_CFG, "Reset stats")

	register_event("30", "change_level_event", "a")
	
	RegisterHam(Ham_Spawn, "crossbow_bolt", "fw_ExplosiveSpawn")
	RegisterHam(Ham_Spawn, "rpg_rocket", "fw_ExplosiveSpawn")
	RegisterHam(Ham_Spawn, "grenade", "fw_ExplosiveSpawn")
	RegisterHam(Ham_Spawn, "monster_tripmine", "fw_TripmineSpawn")
	RegisterHam(Ham_Spawn, "monster_snark", "fw_SnarkSpawn")
	RegisterHam(Ham_Spawn, "monster_satchel", "fw_SatchelSpawn")
	RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn", 1)
	RegisterHam(Ham_TakeDamage, "player", "fw_PlayerTakeDamage")
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")
	RegisterHam(Ham_Weapon_PrimaryAttack,"weapon_gauss", "fw_GaussPrimaryAttack", 1)
	RegisterHam(Ham_Weapon_PrimaryAttack,"weapon_egon", "fw_EgonPrimaryAttack", 1)
	RegisterHam(Ham_Weapon_SendWeaponAnim,"weapon_gauss", "fw_GaussSecondaryAttack", 1)
	RegisterHam(Ham_Weapon_SendWeaponAnim,"weapon_handgrenade", "fw_HandgrenadeAttack", 1)
	
	register_forward(FM_ClientUserInfoChanged, "fwClientUserInfoChanged")
	register_forward(FM_PlaybackEvent, "fwPlaybackEvent")
	register_forward(FM_AlertMessage, "fw_AlertMessage")
	register_forward(FM_Sys_Error, "fnForwardSysError")
	unregister_forward(FM_PrecacheEvent, g_fwid, 1)
	
	g_KillForward = CreateMultiForward("lc_client_death", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL, FP_CELL, FP_CELL)
	g_DamageForward = CreateMultiForward("lc_client_damage", ET_IGNORE, FP_CELL, FP_CELL, FP_FLOAT, FP_CELL, FP_CELL, FP_CELL)
	
	g_enableRanksCvar = register_cvar("lc_rank_system", "1")
	g_StatsTrackMode = register_cvar("lc_track_mode", "1")
	g_RankBotCvar = register_cvar("lc_rank_bots", "1")
	g_PruneTime = register_cvar("lc_prune_days", "0")
	g_logCvar = register_cvar("lc_stats_loging", "1")
	g_ShowInfoCvar =  register_cvar("lc_show_info", "1")
	g_show_adv =  register_cvar("lc_show_adv", "1")
	g_adv_freq = register_cvar("lc_adv_freq", "300")
	
	register_menucmd(register_menuid("Server Stats"), 1023, "actionStatsMenu")
	
	g_maxPlayers = get_maxplayers()
	g_info_sync = CreateHudSyncObj()
	g_at_sync = CreateHudSyncObj()
	g_vic_sync = CreateHudSyncObj()
	g_kill_sync = CreateHudSyncObj()
}

public plugin_cfg()
{
	if(is_plugin_loaded("statscfg.amxx", true) == -1) 
		set_fail_state("Enable statscfg.amxx in plugins.ini")
	
	new addstats[] = "amx_statscfg add ^"%s^" %s"
		
	server_cmd(addstats, "ST_SHOW_KILLER_CHAT", "KillerChat")
	server_cmd(addstats, "ST_SHOW_ATTACKERS", "ShowAttackers")
	server_cmd(addstats, "ST_SHOW_VICTIMS", "ShowVictims")
	server_cmd(addstats, "ST_SHOW_KILLER", "ShowKiller")
	server_cmd(addstats, "Show Death Beam", "ShowBeam")
	server_cmd(addstats, "Killer HP&AP in chat&HUD", "ShowHP_AP")
	server_cmd(addstats, "ST_SHOW_DIST_HS_HUD", "ShowDistHS")
	server_cmd(addstats, "ST_SAY_RANK", "SayRank")
	server_cmd(addstats, "ST_SAY_TOP15", "SayTop")
	server_cmd(addstats, "ST_SAY_STATS", "SayStats")
	server_cmd(addstats, "ST_SAY_RANKSTATS", "SayRankStats")
	server_cmd(addstats, "ST_SAY_STATSME", "SayStatsMe")
	server_cmd(addstats, "ST_SAY_HP", "SayHP")
	server_cmd(addstats, "ST_SAY_ME", "SayMe")
	server_cmd(addstats, "ST_SAY_REPORT", "SayReport")
	server_cmd(addstats, "ST_STATS_PLAYER_MAP_END", "EndPlayer")
	server_cmd(addstats, "ST_STATS_TOP15_MAP_END", "EndTop15")
	server_cmd(addstats, "Winner at the end of map", "EndWinner")
	
	server_print("")
	server_print("   Lambda Core: Half-Life ingame stats Copyright (c) 2009-2010 KORD_12.7")
	server_print("   Version %s build on %s", VERSION, LASTUPDATE)
	server_print("   This plugin comes with ABSOLUTELY NO WARRANTY!")
	server_print("")
	
	if(is_running("valve"))
		get_cvar_pointer("sv_ag_version") ? set_mod_offsets(MINIAG) : set_mod_offsets(HL)
	
	else if(is_running("ag"))
		set_mod_offsets(AG)
		
	else if(is_running("gearbox"))
		set_mod_offsets(OP4)
		
	else if(is_running("zamnhlmp"))
		set_mod_offsets(OP4)
		
	else
	{
		new error[64], mod[32]
		get_modname(mod, charsmax(mod))
		formatex(error, charsmax(error), "Unsupported mod - %s", mod)
		
		register_cvar("lambda_status", "failed", FCVAR_SERVER)
		set_fail_state(error)
	}
	
	config_load()
	
	if(get_pcvar_num(g_enableRanksCvar))
	{
		new temp[512]
		get_localinfo("amxx_datadir", temp, charsmax(temp))
		format(temp, charsmax(temp), "%s%s", temp, stats_dir)
			
		if(!dir_exists(temp)) 
			mkdir(temp)
			
		formatex(g_DataFile, charsmax(g_DataFile), "%s%s", temp, stats_name)
		
		g_ArrayAuth = ArrayCreate(32, 1)
		g_TrieNames = TrieCreate()
		g_TrieStats = TrieCreate()
		g_TrieBodyhits = TrieCreate()
		g_TrieTimestamps = TrieCreate()
		
		RANKS_LOAD_FROM_FILE()
	}
	
	g_EntAttackList = TrieCreate()
	g_MinesOwners = TrieCreate()
	g_WeaponNames = TrieCreate()
	
	g_cvarTeamPlay = get_cvar_pointer("mp_teamplay")
	g_cvarTeamlist = get_cvar_pointer("mp_teamlist")
	
	set_weapon_names()
	
	register_cvar("lambda_ranks",  get_pcvar_num(g_enableRanksCvar) ? "enabled" : "disabled", FCVAR_SERVER)
	register_cvar("lambda_status","loaded", FCVAR_SERVER)
	
	get_available_cmds(g_Cmds, charsmax(g_Cmds))
	
	if(get_pcvar_num(g_show_adv))
		set_task(float(get_pcvar_num(g_adv_freq)), "show_adv", SHOW_ADV_TASK_ID)	
}

native lc_get_user_wstats(index, wpnindex, stats[8], bodyhits[8])
native lc_get_user_wrstats(index, wpnindex, stats[8], bodyhits[8])
native lc_get_user_stats(index, stats[8], bodyhits[8])
native lc_get_user_vstats(index, victim, stats[8], bodyhits[8], wpnname[] = "", len = 0)
native lc_get_user_astats(index, killer, stats[8], bodyhits[8], wpnname[] = "", len = 0)
native lc_get_stats(index, stats[8], bodyhits[8], name[], len, authid[] = "", authidlen = 0)
native lc_get_statsnum()

public plugin_precache() 
{
	g_fwid = register_forward(FM_PrecacheEvent, "fwPrecacheEvent", 1)
	g_spriteTexture = precache_model("sprites/dot.spr")
}

public fwPrecacheEvent(type, const name[]) 
{
	for(new i = 0; i < sizeof g_guns_events; ++i) 
	{
		if(equal(g_guns_events[i], name)) 
		{
			g_guns_eventids_bitsum |= (1 << get_orig_retval())
			return FMRES_HANDLED
		}
	}

	return FMRES_IGNORED
}

public fnForwardSysError()
{
	DestroyForward(g_KillForward)
	DestroyForward(g_DamageForward)
}

public plugin_end()
{
	// Уничтожаем массив и деревья для освобождения памяти
	if(get_pcvar_num(g_enableRanksCvar))
	{
		ArraySort(g_ArrayAuth, "RANKS_SORTING")
		
		//if(!g_ResetCvar)
		RANKS_SAVE_TO_FILE()
		
		ArrayDestroy(g_ArrayAuth)
		TrieDestroy(g_TrieNames)
		HashDestroy(g_TrieStats)
		HashDestroy(g_TrieBodyhits)
		TrieDestroy(g_TrieTimestamps)
	}
	
	TrieDestroy(g_WeaponNames)
	TrieDestroy(g_EntAttackList)
	TrieDestroy(g_MinesOwners)
	
	DestroyForward(g_KillForward)
	DestroyForward(g_DamageForward)
}

public CmdReset(id, level, cid) // Сброс статы
{
	if(!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED
	
	delete_file(g_DataFile)
	
	for(new i = 0; i < g_maxPlayers + 1; i++)
		reset_stats(i)
	
	ArrayClear(g_ArrayAuth)
	TrieClear(g_TrieNames)
	TrieClear(g_TrieStats)
	TrieClear(g_TrieBodyhits)
	TrieClear(g_TrieTimestamps)
	
	new name[32]; get_user_name(id, name, charsmax(name))
	show_activity(id, name, "All stats reseted")
	
	return PLUGIN_HANDLED	
}

public client_connect(id)
{
	g_IsOnServer[id] = 0
}

public client_putinserver(id)
{
	formatex(g_hpAnnounce[id], charsmax(g_hpAnnounce[]), "%L", id, "YOU_NO_KILLER")	
	
	new value[2]
	get_user_info(id, "lc", value, charsmax(value))
	g_StatsSwitch[id] = (value[0]) ? str_to_num(value) : 1
	
	g_IsOnServer[id] = 1
	
	if(!is_user_bot(id))
	{
		g_pingSum[id] = g_pingCount[id] = 0
		set_task(19.5 , "getPing", id + PING_TASK_ID, "", 0, "b")
	}
	
	if(get_pcvar_num(g_enableRanksCvar))
		RANK_UPDATE_PLAYER(id)
}

public client_disconnect(id)
{
	remove_task(id + PING_TASK_ID)	
	RANK_UPDATE_PLAYER(id)
	stats_loging(id, 1)
	reset_stats(id)
}

stats_loging(id, type)
{
	if(!get_pcvar_num(g_logCvar)) 
		return
	
	if(is_user_bot(id) && !get_pcvar_num(g_RankBotCvar))
		return
	
	new szTeam[16],szName[32],szAuthid[32], szWeapon[32], stats[8], bodyhits[8]
	new iUserid = get_user_userid(id)

	get_user_name(id, szName ,charsmax(szName))
	get_user_authid(id, szAuthid , charsmax(szAuthid))
	get_user_info(id,"model", szTeam, charsmax(szTeam))
  
	for(new i = 1 ; i < HLW_TANK; ++i) 
	{
		if(type == 2 ? lc_get_user_wrstats(id, i, stats, bodyhits) : lc_get_user_wstats(id, i, stats, bodyhits))
		{
			switch(i)
			{
				case OP4_DISPLACER: szWeapon = "displacer_ball"
				case OP4_SPORE: szWeapon = "spore"
				case OP4_SHOCKBEAM: szWeapon = "shock_beam"
				
				default: hl_get_wpnlogname(i, szWeapon, charsmax(szWeapon))
			}
		
			log_message("^"%s<%d><%s><%s>^" triggered ^"weaponstats^" (weapon ^"%s^") (shots ^"%d^") (hits ^"%d^") (kills ^"%d^") \
				(headshots ^"%d^") (tks ^"%d^") (damage ^"%d^") (deaths ^"%d^")", 
				szName, iUserid, szAuthid, szTeam, szWeapon, stats[4], stats[5], 
				stats[0], stats[2], stats[3], stats[6], stats[1])
	
			log_message("^"%s<%d><%s><%s>^" triggered ^"weaponstats2^" (weapon ^"%s^") (head ^"%d^") (chest ^"%d^") (stomach ^"%d^") \
				(leftarm ^"%d^") (rightarm ^"%d^") (leftleg ^"%d^") (rightleg ^"%d^")",
				szName, iUserid, szAuthid, szTeam, szWeapon, bodyhits[1], bodyhits[2], 
				bodyhits[3], bodyhits[4], bodyhits[5], bodyhits[6], bodyhits[7])
		}
	}
	
	if(type == 2)
		return
	
	new iTime = get_user_time(id , 1)
	log_message("^"%s<%d><%s><%s>^" triggered ^"time^" (time ^"%d:%02d^")", szName,iUserid,szAuthid,szTeam, (iTime / 60),  (iTime % 60))
	log_message("^"%s<%d><%s><%s>^" triggered ^"latency^" (ping ^"%d^")", szName,iUserid,szAuthid,szTeam, (g_pingSum[id] / (g_pingCount[id] ? g_pingCount[id] : 1)))
}

HLXCE_log(killer, victim, suicide, headshot, wpnid, killer_origin[3], victim_origin[3])
{
	if(suicide != NORMAL)
		return

	static killer_name[32], killer_authid[32]
	static victim_name[32], victim_authid[32]
	
	new killer_userid = get_user_userid(killer)
	new victim_userid = get_user_userid(victim)
	
	get_user_name(killer, killer_name, charsmax(killer_name))
	get_user_authid(killer, killer_authid, charsmax(killer_authid))
	
	get_user_name(victim, victim_name, charsmax(victim_name))
	get_user_authid(victim, victim_authid, charsmax(victim_authid))
	
	new weapon[32], headshot_logentry[16] 
	
	switch(wpnid)
	{
		case OP4_DISPLACER: weapon = "displacer_ball"
		case OP4_SPORE: weapon = "spore"
		case OP4_SHOCKBEAM: weapon = "shock_beam"
				
		default: hl_get_wpnlogname(wpnid, weapon, charsmax(weapon))
	}
		
	if(headshot == HIT_HEAD)
		headshot_logentry = " (headshot)"
	
	formatex(g_logmessage_ignore, charsmax(g_logmessage_ignore), " killed ^"%s", victim_name)
			
	log_message("^"%s<%d><%s><%d>^" killed ^"%s<%d><%s><%d>^" with ^"%s^"%s (attacker_position ^"%d %d %d^") (victim_position ^"%d %d %d^")",
		killer_name, killer_userid, killer_authid, killer_userid, 
		victim_name, victim_userid, victim_authid, victim_userid, 
		weapon, headshot_logentry,
		killer_origin[0], killer_origin[1], killer_origin[2],
		victim_origin[0], victim_origin[1], victim_origin[2])

}

public fwClientUserInfoChanged(id, buffer) 
{
	if(!is_user_connected(id))
		return FMRES_IGNORED

	static name[32], val[32]
	get_user_name(id, name, charsmax(name))
	engfunc(EngFunc_InfoKeyValue, buffer, "name", val, charsmax(val))
	
	if(equal(val, name))
		return FMRES_IGNORED
	else
	{	
		RANK_UPDATE_PLAYER(id)
		stats_loging(id, get_pcvar_num(g_logCvar))
		reset_stats(id)	
	}

	return FMRES_IGNORED
}

public handle_say(id) 
{
	static args[64]
	read_args(args, charsmax(args))
	remove_quotes(args)
	trim(args)
	
	if(args[0] != '/')
		return PLUGIN_CONTINUE
	
	if(equali(args, "/rank")) 
		return handle_rank(id)
		
	else if(contain(args, "/top") != -1) 
	{
		replace(args, charsmax(args), "/top", "")
		
		return handle_top(id, str_to_num(args))
	}	
	
	else if(equali(args, "/stats"))
		return handle_stats(id)
	
	else if(equali(args, "/rankstats"))
		return handle_rankstats(id, id)
		
	else if(equali(args, "/statsme"))
		return handle_statsme(id, id)
		
	else if(equali(args, "/hp"))
		return handle_hp(id)
		
	else if(equali(args, "/me"))
		return handle_me(id)
		
	else if(equali(args, "/report"))
		return handle_report(id)
		
	else if(equali(args, "/lcinfo"))
		handle_info(id)
	
	else if(equali(args, "/switch"))
		handle_switch(id)
		
	return PLUGIN_CONTINUE	
}

public handle_rank(id)
{
	if(!get_pcvar_num(g_enableRanksCvar))
		return PLUGIN_CONTINUE
		
	if(!SayRank)
	{
		client_print(id, print_chat, "%s %L", PREFIX, id, "DISABLED_MSG")
		return PLUGIN_HANDLED_MAIN
	}	

	new stats[8], bodyhits[8]
	new rank, rankmax
	new Float:Eff, Float:Acc
	
	rank = lc_get_user_stats(id, stats, bodyhits)
	rankmax = lc_get_statsnum()
	
	Eff = effec(stats)
	Acc = accuracy(stats)
	
	rank ? client_print(id, print_chat, "%s %L", PREFIX, id, "FILERANK", 
			rank, 
			rankmax, 
			stats[STATS_KILLS], 
			stats[STATS_DEATHS],
			stats[STATS_HITS], 
			Eff,
			"%",
			Acc,
			"%")
		: client_print(id, print_chat, "%s %L", PREFIX,id, "NORANK")	
	
	return PLUGIN_CONTINUE
}

handle_top(id, topnum = 15)
{
	if(!get_pcvar_num(g_enableRanksCvar))
		return PLUGIN_CONTINUE
		
	if(!SayTop)
	{
		client_print(id, print_chat, "%s %L", PREFIX, id, "DISABLED_MSG")
		return PLUGIN_HANDLED_MAIN
	}	
	
	new buffer[MAX_BUFFER_LENGTH], buf[32]
	topnum = format_top(buffer, topnum)
	
	formatex(buf, charsmax(buf), "Lambda Core - Top %d", topnum)
	show_motd(id, buffer, buf)
	
	return PLUGIN_CONTINUE
}

format_top(buffer[MAX_BUFFER_LENGTH], topnum)
{
	new size = min(ArraySize(g_ArrayAuth)/*lc_get_statsnum()*/, topnum)
	new stats[8]/*, bodyhits[8]*/, name[32], len, i
	
	new uniqueid[32]	
	
	len = format(buffer[len], charsmax(buffer) - len, "%5s  %22s %18s %10s %8s^n", "Rank", "Name" ,"Kills/Deaths", "Eff.%", "Acc.%")
	
	for(i = size - 15 < 0 ? 0 : size - 15; i < size && charsmax(buffer) - len > 0; i++)
	{
		//lc_get_stats(i, stats, bodyhits, name, charsmax(name))
		
		ArrayGetString(g_ArrayAuth, i, uniqueid, charsmax(uniqueid))
		TrieGetString(g_TrieNames, uniqueid, name, charsmax(name))
		HashGetArray(g_TrieStats, uniqueid, stats, sizeof stats)
		
		len += formatex(buffer[len], charsmax(buffer) - len, "^n%5d   %22s %6.0d/%d %6s %.2f% %6s %.2f%", 
				i + 1, 
				name, 
				stats[STATS_KILLS], 
				stats[STATS_DEATHS], 
				" ", 
				effec(stats), 
				" ", 
				accuracy(stats))
	}
	
	return size
}

public handle_stats(id)
{
	if(!SayStats)
	{
		client_print(id, print_chat, "%s %L", PREFIX, id, "DISABLED_MSG")
		return PLUGIN_HANDLED_MAIN
	}
	
	showStatsMenu(id, g_userPosition[id] = 0)
	
	return PLUGIN_CONTINUE
}

showStatsMenu(id, pos)
{
	if(pos < 0) 
		return PLUGIN_HANDLED
  
	new max_menupos = PPL_MENU_OPTIONS
	new menu_body[512], inum, k = 0, start = pos * max_menupos 
	
	get_players(g_userPlayers[id], inum)
	
	if(start >= inum) 
		start = pos = g_userPosition[id] = 0

	new len = formatex(menu_body, charsmax(menu_body), "Lambda Core - %L %d/%d^n^n", id, "SERVER_STATS", pos + 1, ((inum / max_menupos) + ((inum % max_menupos) ? 1 : 0)))
	new name[32], end = start + max_menupos, keys = (1<<9) | (1<<7)
  
	if(end > inum) 
		end = inum

	for(new a = start; a < end; ++a)
	{
		hl_get_user_name(g_userPlayers[id][a], name, charsmax(name))
		keys |= (1<<k)
		len += formatex(menu_body[len], charsmax(menu_body) - len, "%d. %s^n", ++k, name)
	}
	
	len += formatex(menu_body[len], charsmax(menu_body) - len, "^n8. %s^n", g_userState[id] ? "Show rank stats" : "Show stats" )
	
	if(end != inum)
	{
		if(pos)
			len += formatex(menu_body[len], charsmax(menu_body) - len, "^n9. %L^n0. %L", id, "MORE", id, "BACK")
		else	
			len += formatex(menu_body[len], charsmax(menu_body) - len, "^n9. %L^n0. %L", id, "MORE", id, "EXIT")
		
		keys |= (1<<8)
	}
	else
	{
		if(pos)
			len += formatex(menu_body[len], charsmax(menu_body) - len, "^n0. %L", id, "BACK")
		else	
			len += formatex(menu_body[len], charsmax(menu_body) - len, "^n0. %L", id, "EXIT")
	}
	
	show_menu(id,keys,menu_body)
	
	return PLUGIN_HANDLED
}

public actionStatsMenu(id, key)
{
	switch(key)
	{
		case 7: 
		{
			g_userState[id] = 1 - g_userState[id]
			showStatsMenu(id, g_userPosition[id])
		}
		
		case 8: showStatsMenu(id, ++g_userPosition[id])
		case 9: showStatsMenu(id, --g_userPosition[id])
		
		default:
		{
			new option = g_userPosition[id] * PPL_MENU_OPTIONS + key
			new index = g_userPlayers[id][option]
			
			if(is_user_connected(index))
			{
				if(g_userState[id])
					handle_rankstats(index, id)
				else
					handle_statsme(index, id)
			}
			
			showStatsMenu(id, g_userPosition[id])
		}
	}
	
	return PLUGIN_HANDLED
}

handle_rankstats(id, index)
{
	if(!get_pcvar_num(g_enableRanksCvar))
		return PLUGIN_CONTINUE
		
	if(!SayRankStats)
	{
		client_print(id, print_chat, "%s %L", PREFIX, id, "DISABLED_MSG")
		return PLUGIN_HANDLED_MAIN
	}	
	
	new motd[MAX_BUFFER_LENGTH], iName[32], len
	hl_get_user_name(id, iName, charsmax(iName))
	
	new rank, stats[8], bodyhits[8]
	rank = lc_get_user_stats(id, stats, bodyhits)
	
	if(rank)
		len = formatex(motd[len], charsmax(motd) - len, "%L^n^n", id, "RANKSTATS", rank, lc_get_statsnum())
	else	
		len = formatex(motd[len], charsmax(motd) - len, "%L^n^n", id, "NORANK2")
		
	len += formatex(motd[len], charsmax(motd) - len, "%L: %d (%d with hs)^n", id, "KILLS", stats[STATS_KILLS], stats[STATS_HEADSHOTS])
	len += formatex(motd[len], charsmax(motd) - len, "%L: %d^n", id, "DEATHS", stats[STATS_DEATHS])
	len += formatex(motd[len], charsmax(motd) - len, "%L: %d^n", id, "HITS", stats[STATS_HITS])
	len += formatex(motd[len], charsmax(motd) - len, "%L: %d^n", id, "SHOTS", stats[STATS_SHOTS])
	len += formatex(motd[len], charsmax(motd) - len, "%L: %d^n", id, "DAMAGE", stats[STATS_DAMAGE])
	len += formatex(motd[len], charsmax(motd) - len, "%L: %.2f%%^n",  id, "EFF", effec(stats))
	len += formatex(motd[len], charsmax(motd) - len, "%L: %.2f%%^n^n", id, "ACC", accuracy(stats))
	len += formatex(motd[len], charsmax(motd) - len, "%L:^n", id, "HITS")
	len += formatex(motd[len], charsmax(motd) - len, "%L: %d^n", id, "WHOLEBODY", bodyhits[HIT_GENERIC])
	len += formatex(motd[len], charsmax(motd) - len, "%L: %d^n", id, "HEAD", bodyhits[HIT_HEAD])
	len += formatex(motd[len], charsmax(motd) - len, "%L: %d^n", id, "CHEST", bodyhits[HIT_CHEST])
	len += formatex(motd[len], charsmax(motd) - len, "%L: %d^n", id, "STOMACH", bodyhits[HIT_STOMACH])
	len += formatex(motd[len], charsmax(motd) - len, "%L: %d^n", id, "LEFTARM", bodyhits[HIT_LEFTARM])
	len += formatex(motd[len], charsmax(motd) - len, "%L: %d^n", id, "RIGHTARM", bodyhits[HIT_RIGHTARM])
	len += formatex(motd[len], charsmax(motd) - len, "%L: %d^n", id, "LEFTLEG", bodyhits[HIT_LEFTLEG])
	len += formatex(motd[len], charsmax(motd) - len, "%L: %d", id, "RIGHTLEG", bodyhits[HIT_RIGHTLEG])
			
	show_motd(index, motd, iName)
		
	return PLUGIN_CONTINUE	
}

handle_statsme(id, index)
{
	if(!SayStatsMe)
	{
		client_print(id, print_chat, "%s %L", PREFIX, id, "DISABLED_MSG")
		return PLUGIN_HANDLED_MAIN
	}
	
	new name[32], buffer[MAX_BUFFER_LENGTH]
	
	hl_get_user_name(id, name, charsmax(name))
	format_statsme(id, buffer)
	
	show_motd(index, buffer, name)
	
	return PLUGIN_CONTINUE
}

format_statsme(id, motd[MAX_BUFFER_LENGTH])
{
	new wpn[32], stats[8], bodyhits[8], len, i, k, t
	
	stats[STATS_KILLS] = g_MapPlayersStats[id][STATS_KILLS]
	stats[STATS_DEATHS] = g_MapPlayersStats[id][STATS_DEATHS]
	stats[STATS_TEAMKILLS] = g_MapPlayersStats[id][STATS_TEAMKILLS]
		
	for(new i = 1; i < HLW_TANK + 1; ++i)
	{
		stats[STATS_HEADSHOTS] += g_MapWeaponsStats[id][i][STATS_HEADSHOTS]
		stats[STATS_SHOTS] += g_MapWeaponsStats[id][i][STATS_SHOTS]
		stats[STATS_HITS] += g_MapWeaponsStats[id][i][STATS_HITS]
		stats[STATS_DAMAGE] += g_MapWeaponsStats[id][i][STATS_DAMAGE]
	}
	
	len = formatex(motd[len], charsmax(motd) - len, "%L: %d (%d with hs)^n", id, "KILLS", stats[STATS_KILLS], stats[STATS_HEADSHOTS])
	len += formatex(motd[len], charsmax(motd) - len, "%L: %d^n", id, "DEATHS", stats[STATS_DEATHS]) 
	len += formatex(motd[len], charsmax(motd) - len,	"%L: %d^n", id, "HITS", stats[STATS_HITS])
	len += formatex(motd[len], charsmax(motd) - len,	"%L: %d^n", id, "SHOTS", stats[STATS_SHOTS])
	len += formatex(motd[len], charsmax(motd) - len, "%L: %d^n", id, "DAMAGE", stats[STATS_DAMAGE]) 
	len += formatex(motd[len], charsmax(motd) - len, "%L: %.2f%%^n", id, "EFF", effec(stats))
	len += formatex(motd[len], charsmax(motd) - len, "%L: %.2f%%^n^n", id, "ACC", accuracy(stats))
	
	len += formatex(motd[len], charsmax(motd) - len,"%L           %L  %L  %L  %L  %L  %L^n", 
		id, "WEAPON", id, "KILLS", id, "DEATHS", id, "HITS", id, "SHOTS", id, "DAMAGE", id, "ACC")
	
	for(i = 1 ; i < HLW_TANK; ++i) 
	{
		if(lc_get_user_wstats(id, i, stats, bodyhits))
		{
			hl_get_wpnname(i, wpn, charsmax(wpn)) // Название оружия
			
			switch(i) // Для лучшей смотрибельности выбираем отступ (кол-во пробелов после названия оружия)
			{
				case HLW_CROWBAR: t = 12
				case OP4_WRENCH: t = 8
				case OP4_KNIFE: t = 15
				case OP4_GRAPPLE: t = 13
				case HLW_GLOCK: t = 7
				case HLW_PYTHON: t = 17
				case OP4_EAGLE: t = 15
				case HLW_MP5: t = 13
				case HLW_SHOTGUN: t = 12
				case HLW_CROSSBOW: t = 11
				case HLW_BOLT: t = 17
				case HLW_RPG: t = 17
				case HLW_GAUSS: t = 15
				case HLW_EGON: t = 16
				case HLW_HORNETGUN: t = 10
				
				case HLW_HANDGRENADE: 
				{
					t = 12
					wpn = "grenade"
				}
				
				case HLW_SATCHEL: t = 13
				case HLW_TRIPMINE: t = 12
				case HLW_SNARK: t = 15
				case OP4_M249: t = 15
				case OP4_DISPLACER: t = 11
				case OP4_M40A1: t = 10
				case OP4_SPORE: t = 5
				case OP4_SHOCKBEAM: t = 10
			}
			
			// Собственно сам отступ
			for(k = 0; k < t - 1; k++)
				add(wpn, charsmax(wpn), " ")
				
			// Стата по использованому оружию
			len += formatex(motd[len], charsmax(motd) - len, "%s %d %8d %5d %7d %8d %8.2f%%^n", 
				wpn, stats[0], stats[1], stats[5], stats[4], stats[6], accuracy(stats))	
		}
	}
}

handle_hp(id)
{
	if(!SayHP)
	{
		client_print(id, print_chat, "%s %L", PREFIX, id, "DISABLED_MSG")
		return PLUGIN_HANDLED_MAIN
	}
	
	client_print(id, print_chat, "%s %s", PREFIX, g_hpAnnounce[id])
	
	return PLUGIN_CONTINUE
}

handle_me(id)
{
	if(!SayMe)
	{
		client_print(id, print_chat, "%s %L", PREFIX, id, "DISABLED_MSG")
		return PLUGIN_HANDLED_MAIN
	}
	
	new stats[8], bodyhits[8], buffer[256], len
	
	lc_get_user_vstats(id, 0, stats, bodyhits)
	
	stats[STATS_HITS] = 0
	
	for(new i = 0; i < STATS; i++)
		stats[STATS_HITS] += bodyhits[i]
	
	len = formatex(buffer, charsmax(buffer), "%L >>", id, "LAST_RES", stats[STATS_HITS], stats[STATS_DAMAGE])

	if(stats[STATS_HITS])
	{
		for(new i = 0; i < STATS; i++)
		{
			if(!bodyhits[i])
				continue
			
			len += formatex(buffer[len], charsmax(buffer) - len, " %L: %d", id, BODY_PART[i], bodyhits[i])
		}
	}
	else
		len += formatex(buffer[len], charsmax(buffer) - len, " %L", id, "NO_HITS")
		
	client_print(id, print_chat, "%s %s", PREFIX, buffer)	
	
	return PLUGIN_CONTINUE
}

handle_report(id) // Репорт о состоянии игрока
{
	if(!SayReport)
	{
		client_print(id, print_chat, "%s %L", PREFIX, id, "DISABLED_MSG")
		return PLUGIN_HANDLED_MAIN
	}
	
	if(hl_is_user_spectator(id)) // Юзер в режиме спектатора
	{
		engclient_cmd(id, "say_team", "SPECTATOR")
		return PLUGIN_CONTINUE
	}
	
	new sBuffer[200]
	if(is_user_alive(id)) // Игрок жив
	{
		// Узнаем кол-во хелсов и брони, ид оружия и его ентити ид
		new iHealth = get_user_health(id) 
		new iArmor = get_user_armor(id)
		new iWeapon = get_user_weapon(id)
		new weapent = hl_get_user_weapon_ent(id)
		new LGstr[11]; if(fm_get_user_longjump(id)) LGstr = "- Longjump"
		new iClip, iAmmo, sWeapon[24]; hl_get_wpnname(iWeapon, sWeapon, charsmax(sWeapon))
		
		// У игрока в руках оружие, получаем кол-во патронов в обойме и запасе
		if(weapent > 0) 
		{
			iClip = hl_get_weapon_ammo(weapent)
			iAmmo = hl_get_user_bpammo(id, iWeapon)
		}
		
		if(iClip >= 0) // Оружие имеет обойму (пистолеты и т.п)
		{
			switch(iWeapon)
			{
				case HLW_MP5: formatex(sBuffer, charsmax(sBuffer), 
						"weapon: %s, ammo: %d/%d/%d, health: %d, armor: %d %s", 
					sWeapon, iClip, iAmmo, hl_get_user_bpammo(id, HLW_CHAINGUN), iHealth, iArmor, LGstr)
				
				default: formatex(sBuffer, charsmax(sBuffer), 
						"weapon: %s, ammo: %d/%d, health: %d, armor: %d %s", 
					sWeapon, iClip, iAmmo, iHealth, iArmor, LGstr)
			}
		}
		else // Оружие без обоймы (лом и т.п.)
		{
			switch(iWeapon)
			{
				case HLW_CROWBAR, OP4_WRENCH, OP4_KNIFE, OP4_GRAPPLE: formatex(sBuffer, charsmax(sBuffer), 
						"weapon: %s, health: %d, armor: %d %s", 
					sWeapon, iHealth, iArmor,  LGstr)
						
				default: formatex(sBuffer, charsmax(sBuffer), 
						"weapon: %s, ammo: %d, health: %d, armor: %d %s", 
					sWeapon, iAmmo, iHealth, iArmor, LGstr)		
			}
		}
	}
	else
		formatex(sBuffer, charsmax(sBuffer), "DEAD")
	
	engclient_cmd(id, "say_team", sBuffer)
	
	return PLUGIN_CONTINUE
}

handle_switch(id)
{	
	g_StatsSwitch[id] = (g_StatsSwitch[id]) ? 0 : 1
	
	new value[2], buffer[32]
	num_to_str(g_StatsSwitch[id], value, charsmax(value))
	client_cmd(id, "setinfo lc %s", value)
	
	format(buffer, charsmax(buffer), "%L", id, g_StatsSwitch[id] ? "ENABLED" : "DISABLED")
	client_print(id, print_chat, "%s %L", PREFIX, id, "STATS_ANNOUNCE", buffer)
	
	return PLUGIN_CONTINUE	
}	
#if defined BOT_TEST
	#include <fun>
#endif
public fw_PlayerSpawn(id) 
{
	for(new i = 0; i < HLW_TANK + 1; i++)
	{
		for(new k = 0; k < HIT_RIGHTLEG + 1; k++)
		{
			g_RespawnWeaponsStats[id][i][k] = 0
			g_RespawnWeaponsBodyhits[id][i][k] = 0
		}

	}
		
	for(new i = 0; i < STATS; i++)	
		g_RespawnPlayersStats[id][i] =0 
			
	for(new i = 1; i < g_maxPlayers + 1; ++i)
		g_VictimDistance[id][i] = 0 
	
	g_AttackerDistance[id] = 0	
		
	reset_player_victims(id)
	reset_player_attackers(id)
#if defined BOT_TEST
	if(is_user_bot(id))
	{
		strip_user_weapons(id)
		set_user_maxspeed(id, -1.0)
	}
#endif
	return HAM_IGNORED
}

public fw_PlayerTakeDamage(victim, inflictor, agressor, Float: damage)
{
	if(g_maxPlayers < agressor ||  agressor <= 0 || damage < 1.0)
		return HAM_IGNORED
	
	if(victim == agressor)
		return HAM_IGNORED
		
	if(!ExecuteHam(Ham_IsAlive, victim))
		return HAM_IGNORED
	
	static dmg, hitplace, wpn_id; wpn_id = 0
	
	dmg = floatround(damage, floatround_floor)
	hitplace = get_pdata_int(victim, g_Offsets[LAST_HIT_GROUP])
	
	if(inflictor == agressor)
		wpn_id = get_user_weapon(agressor)
	else
	{
		if(inflictor < g_maxPlayers) 
			return HAM_IGNORED
			
		static classname[32]
		pev(inflictor, pev_classname, classname, charsmax(classname))
		TrieGetCell(g_WeaponNames, classname, wpn_id)
	}
	
	g_VictimsStats[agressor][victim][STATS_HITS] ++
	g_VictimsStats[agressor][victim][STATS_DAMAGE] += dmg
	g_VictimsBodyhits[agressor][victim][hitplace] ++
			
	g_AttackersStats[victim][agressor][STATS_HITS] ++
	g_AttackersStats[victim][agressor][STATS_DAMAGE] += dmg
	g_AttackersBodyhits[victim][agressor][hitplace] ++
	
	switch(wpn_id)
	{
		case HLW_CROWBAR, HLW_CROSSBOW, HLW_HORNETGUN,  OP4_WRENCH, OP4_KNIFE, OP4_GRAPPLE, 
			OP4_SHOCKBEAM, HLW_GLOCK, HLW_PYTHON, HLW_MP5, OP4_EAGLE, OP4_M249, OP4_M40A1:
		{
			g_MapWeaponsStats[agressor][wpn_id][STATS_HITS] ++
			g_MapWeaponsStats[agressor][wpn_id][STATS_DAMAGE] += dmg
			g_MapWeaponsBodyhits[agressor][wpn_id][hitplace] ++
			
			g_RespawnWeaponsStats[agressor][wpn_id][STATS_HITS] ++
			g_RespawnWeaponsStats[agressor][wpn_id][STATS_DAMAGE] += dmg
			g_RespawnWeaponsBodyhits[agressor][wpn_id][hitplace] ++
		}
		
		case HLW_SHOTGUN:
		{
			inflictor = hl_get_user_weapon_ent(agressor)
				
			if(!get_ent_attack(inflictor))
			{
				set_ent_attack(inflictor, 1)
				
				g_MapWeaponsStats[agressor][wpn_id][STATS_HITS] ++
				g_MapWeaponsBodyhits[agressor][wpn_id][hitplace] ++
				
				g_RespawnWeaponsStats[agressor][wpn_id][STATS_HITS] ++
				g_RespawnWeaponsBodyhits[agressor][wpn_id][hitplace] ++
			}
					
			g_MapWeaponsStats[agressor][wpn_id][STATS_DAMAGE] += dmg
			g_RespawnWeaponsStats[agressor][wpn_id][STATS_DAMAGE] += dmg
		}
		
		case HLW_SATCHEL, HLW_BOLT, HLW_RPG, HLW_HANDGRENADE, HLW_SNARK, OP4_DISPLACER, OP4_SPORE:
		{
			if(!get_ent_attack(inflictor))
			{
				set_ent_attack(inflictor, 1)
				
				g_MapWeaponsStats[agressor][wpn_id][STATS_HITS] ++
				g_MapWeaponsBodyhits[agressor][wpn_id][hitplace] ++
				
				g_RespawnWeaponsStats[agressor][wpn_id][STATS_HITS] ++
				g_RespawnWeaponsBodyhits[agressor][wpn_id][hitplace] ++
			}
	
			g_MapWeaponsStats[agressor][wpn_id][STATS_DAMAGE] += dmg
			g_RespawnWeaponsStats[agressor][wpn_id][STATS_DAMAGE] += dmg
		}
		
		case HLW_GAUSS, HLW_EGON:
		{
			if(inflictor == agressor)
				inflictor = hl_get_user_weapon_ent(agressor)
					
			if(!get_ent_attack(inflictor))
			{
				set_ent_attack(inflictor, 1)
				
				g_MapWeaponsStats[agressor][wpn_id][STATS_HITS] ++
				g_MapWeaponsBodyhits[agressor][wpn_id][hitplace] ++
				
				g_RespawnWeaponsStats[agressor][wpn_id][STATS_HITS] ++
				g_RespawnWeaponsBodyhits[agressor][wpn_id][hitplace] ++
			}
					
			g_MapWeaponsStats[agressor][wpn_id][STATS_DAMAGE] += dmg
			g_RespawnWeaponsStats[agressor][wpn_id][STATS_DAMAGE] += dmg
		}
		
		case HLW_TRIPMINE:
		{
			if(!get_ent_attack(inflictor))
			{
				set_ent_attack(inflictor, 1)
				
				g_MapWeaponsStats[agressor][wpn_id][STATS_HITS] ++
				g_MapWeaponsBodyhits[agressor][wpn_id][hitplace] ++
				
				g_RespawnWeaponsStats[agressor][wpn_id][STATS_HITS] ++
				g_RespawnWeaponsBodyhits[agressor][wpn_id][hitplace] ++
							
				if(agressor != get_mine_owner(inflictor))
				{
					g_MapWeaponsStats[agressor][wpn_id][STATS_SHOTS] ++
					g_RespawnWeaponsStats[agressor][wpn_id][STATS_SHOTS] ++
				}
			}
	
			g_MapWeaponsStats[agressor][wpn_id][STATS_DAMAGE] += dmg
			g_RespawnWeaponsStats[agressor][wpn_id][STATS_DAMAGE] += dmg
		}
	}

	if(!ExecuteForward(g_DamageForward, g_DamageForwardReturn, agressor, victim, damage, wpn_id, hitplace, getFragByRules(agressor, victim) < -1.0 ? 1 : 0))
		log_amx("Could not execute forward")
	
	return HAM_IGNORED
}

show_killer_chat(id, killer, status)
{
	static buffer[256]
	static stats[8], bodyhits[8]
	static len, name[32], wpn[32]
	
	buffer[0] = 0
	len = 0
	name[0] = 0
	wpn[0] = 0
	
	if(status != NORMAL)
	{
		switch(status)
		{
			case SUICIDE: formatex(buffer, charsmax(buffer), "%L", id, "SUICIDE")
			case WORLDSPAWN: formatex(buffer, charsmax(buffer), "%L (worldspawn)", id, "SUICIDE")
			
			case WORLD: 
			{
				pev(killer, pev_classname, wpn, charsmax(wpn))
				formatex(buffer, charsmax(buffer), "%L ^"%s^" (world)", id, "SUICIDE", wpn)
			}
		}	
	}
	else
	{
		get_user_name(killer, name, charsmax(name))
		lc_get_user_astats(id, killer, stats, bodyhits, wpn, charsmax(wpn))

		if(ShowHP_AP)
		{
			len += formatex(buffer[len], charsmax(buffer) - len, "%L (%dhp, %dap) >>", id, "KILLED_BY_WITH", 
				name, wpn, distance(g_AttackerDistance[id]), hl_get_user_health(killer), hl_get_user_armor(killer))
		}
		else
		{
			len += formatex(buffer[len], charsmax(buffer) - len, "%L >>", id, "KILLED_BY_WITH", 
				name, wpn, distance(g_AttackerDistance[id]))
		}
		
		if(stats[STATS_HITS])
		{
			for (new i = 0; i < 8; i++)
			{
				if (!bodyhits[i])
					continue
				
				len += formatex(buffer[len], charsmax(buffer) - len, " %L: %d", id, BODY_PART[i], bodyhits[i])
			}
		}
		else
			len += formatex(buffer[len], charsmax(buffer) - len, " %L", id, "NO_HITS")
	}
	
	copy(g_hpAnnounce[id], charsmax(g_hpAnnounce[]), buffer)
	
	if(!KillerChat)
		return
	
	client_print(id, print_chat, "%s %s", PREFIX, buffer)	
			
	if(status == NORMAL && lc_get_user_vstats(id, killer, stats, bodyhits))
	{
		len = formatex(buffer, charsmax(buffer), "%L >>", id, "YOU_HIT", name, stats[STATS_HITS], stats[STATS_DAMAGE])
	
		for (new i = 0; i < 8; i++)
		{
			if (!bodyhits[i])
				continue
					
			len += formatex(buffer[len], charsmax(buffer) - len, " %L: %d", id, BODY_PART[i], bodyhits[i])
		}
			
		client_print(id, print_chat, "%s %s", PREFIX, buffer)
	}
	
}

show_killer_hud(id, killer)
{
	if(!ShowKiller)
		return
	
	static len, buffer[479], name[32], wpn[32]
	static VStats[8], VBodyhits[8], stats[8], bodyhits[8]
	
	buffer[0] = 0
	len = 0
	name[0] = 0
	wpn[0] = 0

	if(0 < killer <= g_maxPlayers && killer != id)
	{
		hl_get_user_name(killer, name, charsmax(name))
		lc_get_user_vstats(id, killer, VStats, VBodyhits)
		lc_get_user_astats(id, killer, stats, bodyhits, wpn, charsmax(wpn))

		len = format(buffer, charsmax(buffer), "%L^n", id, "KILLED_YOU_DIST", name, wpn, distance(g_AttackerDistance[id]))
		
		if(ShowHP_AP)
			len += format(buffer[len], charsmax(buffer) - len, "%L^n", id, "DID_DMG_HITS", stats[STATS_DAMAGE], stats[STATS_HITS], hl_get_user_health(killer), hl_get_user_armor(killer))
		else
			len += format(buffer[len], charsmax(buffer) - len, "He did %d damage to you with %d hit(s).^n", stats[STATS_DAMAGE], stats[STATS_HITS])
			
		len += format(buffer[len], charsmax(buffer) - len, "%L^n", id, "YOU_DID_DMG", VStats[STATS_DAMAGE], VStats[STATS_HITS])

		if(stats[STATS_HITS])
		{
			len = strlen(buffer)
			hl_get_user_name(killer, name, charsmax(name))
			
			len += format(buffer[len], charsmax(buffer) - len, "%L:^n", id, "HITS_YOU_IN", name)
			
			for (new i = 0; i < 8; i++)
			{
				if (!bodyhits[i])
					continue
				
				len += format(buffer[len], charsmax(buffer) - len, "%L: %d^n", id, BODY_PART[i], bodyhits[i])
			}
		}
	}
	
	set_hudmessage(220, 80, 0, 0.05, 0.15, 0, 6.0, HUD_DURATION, 1.0, 1.0, -1)
	ShowSyncHudMsg(id, g_kill_sync , "%s", buffer)
}

show_victims(id)
{
	if(!ShowVictims)
		return
	
	static found, buffer[479]
	static stats[8], bodyhits[8]
	static len, name[32], wpn[32]
	
	buffer[0] = 0
	found = 0
	len = 0
	name[0] = 0
	wpn[0] = 0

	lc_get_user_vstats(id, 0, stats, bodyhits)
	
	if(stats[STATS_SHOTS])
		len = formatex(buffer, charsmax(buffer), "%L -- %0.2f%% %L:^n", id, "VICTIMS", accuracy(stats), id, "ACC")
	else
		len = formatex(buffer, charsmax(buffer), "%L:^n", id, "VICTIMS")

	for(new i = 1; i <= g_maxPlayers; i++)
	{
		if (lc_get_user_vstats(id, i, stats, bodyhits, wpn, charsmax(wpn)))
		{
			found = 1
			hl_get_user_name(i, name, charsmax(name))
			
			if(stats[STATS_DEATHS])
			{
				if(!ShowDistHS)
					len += format(buffer[len], charsmax(buffer) - len, "%s -- %d %L / %d %L / %s^n", name, stats[STATS_HITS], id, "HIT_S", 
									stats[STATS_DAMAGE], id, "DMG", wpn)
				else if (stats[STATS_HEADSHOTS])
					len += formatex(buffer[len], charsmax(buffer) - len, "%s -- %d %L / %d %L / %s / %0.0f m / HS^n", name, stats[STATS_HITS], id, "HIT_S", 
									stats[STATS_DAMAGE], id, "DMG", wpn, distance(g_VictimDistance[id][i]))
				else
					len += formatex(buffer[len], charsmax(buffer) - len, "%s -- %d %L / %d %L / %s / %0.0f m^n", name, stats[STATS_HITS], id, "HIT_S", 
									stats[STATS_DAMAGE], id, "DMG", wpn, distance(g_VictimDistance[id][i]))
			}
			else
				len += formatex(buffer[len], charsmax(buffer) - len, "%s -- %d %L / %d %L^n", name, stats[STATS_HITS], id, "HIT_S", stats[STATS_DAMAGE], id, "DMG")
		}
	}
	
	if(!found)
		buffer[0] = 0

	set_hudmessage(0, 80, 220, 0.55, 0.60, 0, 6.0, HUD_DURATION, 1.0, 1.0, -1)
	ShowSyncHudMsg(id, g_vic_sync, "%s", buffer)
}

public show_attackers(id)
{
	if(!ShowAttackers)
		return
	
	static found, buffer[479]
	static stats[8], bodyhits[8]
	static len, name[32], wpn[32]
	
	buffer[0] = 0
	found = 0
	len = 0
	name[0] = 0
	wpn[0] = 0
	
	len = formatex(buffer, charsmax(buffer), "%L:^n", id, "ATTACKERS")

	for(new i = 1; i <= g_maxPlayers; i++)
	{
		if(lc_get_user_astats(id, i, stats, bodyhits, wpn, charsmax(wpn)))
		{
			found = 1
			hl_get_user_name(i, name, charsmax(name))
			
			if(stats[STATS_KILLS])
			{
				if(!ShowDistHS)
					len += format(buffer[len], charsmax(buffer) - len, "%s -- %d %L / %d %L / %s^n", name, stats[STATS_HITS], id, "HIT_S", 
									stats[STATS_DAMAGE], id, "DMG", wpn)
				else if(stats[STATS_HEADSHOTS])
					len += formatex(buffer[len], charsmax(buffer) - len, "%s -- %d %L / %d %L / %s / %0.0f m / HS^n", name, stats[STATS_HITS], id, "HIT_S", 
									stats[STATS_DAMAGE], id, "DMG", wpn, distance(g_AttackerDistance[id]))
				else
					len += formatex(buffer[len], charsmax(buffer) - len, "%s -- %d %L / %d %L / %s / %0.0f m^n", name, stats[STATS_HITS], id, "HIT_S", 
									stats[STATS_DAMAGE], id, "DMG", wpn, distance(g_AttackerDistance[id]))
			}
			else
				len += formatex(buffer[len], charsmax(buffer) - len, "%s -- %d %L / %d %L^n", name, stats[STATS_HITS], id, "HIT_S", stats[STATS_DAMAGE], id, "DMG")
		}
	}
	
	if(!found)
		buffer[0] = 0
	
	set_hudmessage(220, 80, 0, 0.55, 0.35, 0, 6.0, HUD_DURATION, 1.0, 1.0, -1)
	ShowSyncHudMsg(id, g_at_sync, "%s", buffer)
}

show_stats(victim, killer, status)
{
	show_killer_chat(victim, killer, status)
	
	if(!g_StatsSwitch[victim]) 
		return
	
	show_killer_hud(victim, killer)
	show_attackers(victim)
	show_victims(victim)
}

public fw_PlayerKilled(victim, killer, shouldgib)
{
	if(victim <= 0 || victim > g_maxPlayers)
		return HAM_IGNORED
	
	static status, inflictor, weaponId, iHitPlace
	static origin1[3], origin2[3], dist
	
	if(victim == killer) 
		status = SUICIDE
	
	else if(!killer) 
		status = WORLDSPAWN
	
	else if(killer > g_maxPlayers) 
		status = WORLD
	
	else status = NORMAL
		
	if(0 < killer <= g_maxPlayers)
	{
		get_user_origin(victim, origin1)
		get_user_origin(killer, origin2)
		
		if(ShowBeam && g_StatsSwitch[victim])
			show_beam(victim, origin1, origin2, 255, 0, 0)
		
		dist = get_distance(origin1, origin2)
		g_AttackerDistance[victim] = dist
		g_VictimDistance[killer][victim] = dist
	}

	if(status == NORMAL)
	{
		inflictor = pev(victim, pev_dmg_inflictor); weaponId = 0
		
		if(killer == inflictor) // Вычисляем ID оружия
			weaponId = get_user_weapon(killer)
		else
		{
			if(inflictor < g_maxPlayers)
				return HAM_IGNORED
			
			static classname[32]
			pev(inflictor, pev_classname, classname, charsmax(classname))
			TrieGetCell(g_WeaponNames, classname, weaponId)
		}
		
		// Узнаем место попадания
		iHitPlace = get_pdata_int(victim, g_Offsets[LAST_HIT_GROUP])
		
		if(get_pcvar_num(g_logCvar) == 2)
			HLXCE_log(killer, victim, status, iHitPlace, weaponId, origin2, origin1)
	}	
	else //суицид
	{
		g_MapPlayersStats[victim][STATS_DEATHS] ++
		g_RespawnPlayersStats[victim][STATS_DEATHS] ++
		
		show_stats(victim, killer, status)
		show_info(victim)
		
		if(get_pcvar_num(g_logCvar) == 2)
			stats_loging(victim, 2)
			
		if(!ExecuteForward(g_KillForward, g_KillForwardReturn, status == SUICIDE ? victim : 0, victim, 0, 0, 0))
			log_amx("Could not execute forward")	
		
		return HAM_IGNORED
	}
	
	switch(weaponId) // Обновляем статистику оружия
	{
		//case HLW_TANK: { }
		
		default :
		{
			if(getFragByRules(killer, victim) < -1.0)
			{
				g_MapWeaponsStats[killer][weaponId][STATS_TEAMKILLS] ++
				g_RespawnWeaponsStats[killer][weaponId][STATS_TEAMKILLS] ++
			}

			g_MapWeaponsStats[killer][weaponId][STATS_KILLS] ++
			g_MapWeaponsStats[victim][weaponId][STATS_DEATHS] ++
			
			g_RespawnWeaponsStats[killer][weaponId][STATS_KILLS] ++
			g_RespawnWeaponsStats[victim][weaponId][STATS_DEATHS] ++
		}
	}
	
	g_VictimsWeapon[killer][victim][0] = weaponId
	g_AttackersWeapon[victim][killer][0] = weaponId

	if(iHitPlace == HIT_HEAD) // Хэдшот
	{
		g_MapWeaponsStats[killer][weaponId][STATS_HEADSHOTS] ++
		g_RespawnWeaponsStats[killer][weaponId][STATS_HEADSHOTS] ++
		
		g_VictimsStats[killer][victim][STATS_HEADSHOTS] ++
		g_AttackersStats[victim][killer][STATS_HEADSHOTS] ++
	}
	
	g_MapPlayersStats[killer][STATS_KILLS] ++
	g_RespawnPlayersStats[killer][STATS_KILLS] ++
	
	g_MapPlayersStats[victim][STATS_DEATHS] ++
	g_RespawnPlayersStats[victim][STATS_DEATHS] ++
	
	g_VictimsStats[killer][victim][STATS_DEATHS] ++
	g_AttackersStats[victim][killer][STATS_KILLS] ++
	
	static tk; tk = 0
	
	if(getFragByRules(killer, victim) < -1.0)
	{
		g_MapPlayersStats[killer][STATS_TEAMKILLS] ++
		g_RespawnPlayersStats[killer][STATS_TEAMKILLS] ++
		
		g_VictimsStats[killer][victim][STATS_TEAMKILLS] ++
		g_AttackersStats[victim][killer][STATS_TEAMKILLS] ++
		
		tk = 1
	}
	
	if(get_pcvar_num(g_logCvar) == 2)
		stats_loging(victim, 2)
	
	show_stats(victim, killer, status)
	show_info(victim)
	
	if(!ExecuteForward(g_KillForward, g_KillForwardReturn, killer, victim, weaponId, iHitPlace, tk))
		log_amx("Could not execute forward")
	
	return HAM_IGNORED
}

public change_level_event()
{
	set_task (1.0, "stats_on_mapend", CHANGE_LEVEL_TASK_ID, _, _, "a", 1)
	
	if(!EndWinner)
		return PLUGIN_CONTINUE
	
	new wName[32], winner_id, winner_skill, skill, found
	new iNum, iTemp[32], iPlayer
	get_players(iTemp, iNum, "h")
	
	for(new i; i < iNum; i++) 
	{
		iPlayer = iTemp[i]
		
		skill = g_MapPlayersStats[iPlayer][STATS_KILLS] - g_MapPlayersStats[iPlayer][STATS_DEATHS]
		
		if(skill > winner_skill)
		{
			winner_skill = skill
			winner_id = iPlayer
			found = 1
		}
	}
	
	if(found)
	{
		hl_get_user_name(winner_id, wName, charsmax(wName))
		client_print(0, print_chat, "%s %L", PREFIX, LANG_PLAYER, "WIN", wName, winner_skill, g_MapPlayersStats[winner_id][STATS_KILLS], g_MapPlayersStats[winner_id][STATS_DEATHS])
	}
	else
		client_print(0, print_chat, "%s %L", PREFIX, LANG_PLAYER, "NOWIN")	
	
	return PLUGIN_CONTINUE	
}

public stats_on_mapend(id)
{
	new iNum, iTemp[32], iPlayer
	get_players(iTemp, iNum, "h")

	if(EndPlayer)
	{
		new name[32], buffer[MAX_BUFFER_LENGTH]
	
		for(new i; i < iNum; i++) 
		{
			iPlayer = iTemp[i]
				
			if(!g_StatsSwitch[iPlayer]) 
				continue
					
			hl_get_user_name(iPlayer, name, charsmax(name))
			format_statsme(iPlayer, buffer)
			show_motd(iPlayer, buffer, name)
		}
	}
	else if(EndTop15)
	{
		new buffer[MAX_BUFFER_LENGTH], buf[32]
		new topnum = format_top(buffer, 15)
		formatex(buf, charsmax(buf), "Lambda Core - Top %d", topnum)
			
		for(new i; i < iNum; i++) 
		{
			iPlayer = iTemp[i]
				
			if(!g_StatsSwitch[iPlayer]) 
				continue
				
			show_motd(iPlayer, buffer, buf)
		}
	}	
	
	return PLUGIN_CONTINUE	
}

public fw_ExplosiveSpawn(ent)
{
	set_ent_attack(ent, 0)
	
	return HAM_IGNORED
}

public fw_TripmineSpawn(ent)
{
	set_ent_attack(ent, 0)
	set_mine_owner(ent)
	
	return HAM_IGNORED
}

public fw_SnarkSpawn(ent)
{	
	if(!pev_valid(ent))
		return HAM_IGNORED
	
	set_ent_attack(ent, 0)
	ent = pev(ent, pev_owner)
	
	g_MapWeaponsStats[ent][HLW_SNARK][STATS_SHOTS] ++
	g_RespawnWeaponsStats[ent][HLW_SNARK][STATS_SHOTS] ++
	
	return HAM_IGNORED
}

public fw_SatchelSpawn(ent)
{	
	if(!pev_valid(ent))
		return HAM_IGNORED
		
	set_ent_attack(ent, 0)
	ent = pev(ent, pev_owner)
	
	g_MapWeaponsStats[ent][HLW_SATCHEL][STATS_SHOTS] ++
	g_RespawnWeaponsStats[ent][HLW_SATCHEL][STATS_SHOTS] ++
	
	return HAM_IGNORED
}

public fw_GaussPrimaryAttack(id)
{
	if(!pev_valid(id))
		return HAM_IGNORED
	
	id = pev(id, pev_owner)

	if(hl_get_user_bpammo(id, HLW_GAUSS))
	{
		set_ent_attack(hl_get_user_weapon_ent(id), 0)
		g_MapWeaponsStats[id][HLW_GAUSS][STATS_SHOTS] ++
		g_RespawnWeaponsStats[id][HLW_GAUSS][STATS_SHOTS] ++
	}
	
	return HAM_IGNORED
}

public fw_EgonPrimaryAttack(ent) 
{
	if(!pev_valid(ent))
		return HAM_IGNORED

	static id; id = pev(ent, pev_owner)
	static Float:gametime; gametime = get_gametime()
	
	if(ExecuteHam(Ham_IsAlive, id))
	{
		if((gametime - g_egon_delay[id]) > 0.21 )
		{
			g_egon_delay[id] = gametime
			
			set_ent_attack(ent, 0)
			g_MapWeaponsStats[id][HLW_EGON][STATS_SHOTS] ++
			g_RespawnWeaponsStats[id][HLW_EGON][STATS_SHOTS] ++
		}
	}
	
	return HAM_IGNORED
}

public fw_GaussSecondaryAttack(id, iAnim)
{
	if(!pev_valid(id))
		return HAM_IGNORED
	
	if(iAnim == 3)
	{
		set_ent_attack(id, 0)
		
		id = pev(id, pev_owner)
		g_MapWeaponsStats[id][HLW_GAUSS][STATS_SHOTS] ++
		g_RespawnWeaponsStats[id][HLW_GAUSS][STATS_SHOTS] ++
	}
	
	return HAM_IGNORED
}

public fw_HandgrenadeAttack(ent, iAnim)
{
	if(!pev_valid(ent))
		return HAM_IGNORED
	
	if(iAnim == 3)
	{
		ent = pev(ent, pev_owner)
		g_MapWeaponsStats[ent][HLW_HANDGRENADE][STATS_SHOTS] ++
		g_RespawnWeaponsStats[ent][HLW_HANDGRENADE][STATS_SHOTS] ++
	}
	
	return HAM_IGNORED
}

public fw_GrappleAttack(id, iAnim)
{
	if(!pev_valid(id))
		return HAM_IGNORED
	
	if(iAnim == 7)
	{
		id = pev(id, pev_owner)
		g_MapWeaponsStats[id][OP4_GRAPPLE][STATS_SHOTS] ++ 
		g_RespawnWeaponsStats[id][OP4_GRAPPLE][STATS_SHOTS] ++ 
	}
	
	return HAM_IGNORED
}

public fw_DisplacerAttack(ent)
{
	if(!pev_valid(ent))
		return HAM_IGNORED
	
	set_ent_attack(ent, 0)
	ent = pev(ent, pev_owner)
	
	g_MapWeaponsStats[ent][OP4_DISPLACER][STATS_SHOTS] ++ 
	g_RespawnWeaponsStats[ent][OP4_DISPLACER][STATS_SHOTS] ++ 
	
	return HAM_IGNORED
}

public fw_AlertMessage(AlertType: type, message[])
{
	if(type != at_logged || get_pcvar_num(g_logCvar) != 2)
		return FMRES_IGNORED
		
	if((strcmp("", g_logmessage_ignore) != 0) && (contain(message, g_logmessage_ignore) != -1)) 
	{
		if(contain(message, "position") == -1) 
		{
			g_logmessage_ignore = ""
			return FMRES_SUPERCEDE
		}
	}
	
	return FMRES_IGNORED
}

public fwPlaybackEvent(flags, invoker, eventid) // Считаем выстрелы
{
	if (!(g_guns_eventids_bitsum & (1<<eventid)) || !(1 <= invoker <= g_maxPlayers))
		return FMRES_IGNORED	
	
	switch(eventid) // Эвенты общие для всех модов
	{
		case 1..2:
		{
			set_ent_attack(hl_get_user_weapon_ent(invoker), 0)
			g_MapWeaponsStats[invoker][HLW_SHOTGUN][STATS_SHOTS] ++
			g_RespawnWeaponsStats[invoker][HLW_SHOTGUN][STATS_SHOTS] ++
		}
		
		case 3:
		{
			g_MapWeaponsStats[invoker][HLW_CROWBAR][STATS_SHOTS] ++
			g_RespawnWeaponsStats[invoker][HLW_CROWBAR][STATS_SHOTS] ++
		}
		
		case 4..5:
		{
			g_MapWeaponsStats[invoker][HLW_GLOCK][STATS_SHOTS] ++
			g_RespawnWeaponsStats[invoker][HLW_GLOCK][STATS_SHOTS] ++
		}
		
		case 6:
		{
			g_MapWeaponsStats[invoker][HLW_MP5][STATS_SHOTS] ++
			g_RespawnWeaponsStats[invoker][HLW_MP5][STATS_SHOTS] ++
		}
		
		case 7:
		{
			g_MapWeaponsStats[invoker][HLW_HANDGRENADE][STATS_SHOTS] ++
			g_RespawnWeaponsStats[invoker][HLW_HANDGRENADE][STATS_SHOTS] ++
		}
		
		case 8:
		{
			g_MapWeaponsStats[invoker][HLW_PYTHON][STATS_SHOTS] ++
			g_RespawnWeaponsStats[invoker][HLW_PYTHON][STATS_SHOTS] ++
		}
	
		case 11:
		{
			g_MapWeaponsStats[invoker][HLW_RPG][STATS_SHOTS] ++
			g_RespawnWeaponsStats[invoker][HLW_RPG][STATS_SHOTS] ++
		}
		
		case 12:
		{
			g_MapWeaponsStats[invoker][HLW_BOLT][STATS_SHOTS] ++
			g_RespawnWeaponsStats[invoker][HLW_BOLT][STATS_SHOTS] ++
		}
		
		case 13:
		{
			g_MapWeaponsStats[invoker][HLW_CROSSBOW][STATS_SHOTS] ++
			g_RespawnWeaponsStats[invoker][HLW_CROSSBOW][STATS_SHOTS] ++
		}
		
		case 16:
		{
			g_MapWeaponsStats[invoker][HLW_TRIPMINE][STATS_SHOTS] ++
			g_RespawnWeaponsStats[invoker][HLW_TRIPMINE][STATS_SHOTS] ++
		}
	}
	
	switch(g_MOD) // Спец эвенты
	{
		case OP4:
		{
			switch(eventid)
			{
				case 17:
				{
					g_MapWeaponsStats[invoker][HLW_TRIPMINE][STATS_SHOTS] ++
					g_RespawnWeaponsStats[invoker][HLW_TRIPMINE][STATS_SHOTS] ++
				}
				
				case 19:
				{
					g_MapWeaponsStats[invoker][HLW_HORNETGUN][STATS_SHOTS] ++
					g_RespawnWeaponsStats[invoker][HLW_HORNETGUN][STATS_SHOTS] ++
				}
				
				case 20:
				{
					g_MapWeaponsStats[invoker][OP4_EAGLE][STATS_SHOTS] ++
					g_RespawnWeaponsStats[invoker][OP4_EAGLE][STATS_SHOTS] ++
				}
				
				case 21:
				{
					g_MapWeaponsStats[invoker][OP4_WRENCH][STATS_SHOTS] ++
					g_RespawnWeaponsStats[invoker][OP4_WRENCH][STATS_SHOTS] ++
				}
				
				case 22:
				{
					g_MapWeaponsStats[invoker][OP4_M249][STATS_SHOTS] ++
					g_RespawnWeaponsStats[invoker][OP4_M249][STATS_SHOTS] ++
				}
				
				case 23:
				{
					g_MapWeaponsStats[invoker][OP4_SPORE][STATS_SHOTS] ++
					g_RespawnWeaponsStats[invoker][OP4_SPORE][STATS_SHOTS] ++
				}
				
				case 24:
				{
					g_MapWeaponsStats[invoker][OP4_SHOCKBEAM][STATS_SHOTS] ++
					g_RespawnWeaponsStats[invoker][OP4_SHOCKBEAM][STATS_SHOTS] ++
				}
				
				case 25:
				{
					g_MapWeaponsStats[invoker][OP4_M40A1][STATS_SHOTS] ++
					g_RespawnWeaponsStats[invoker][OP4_M40A1][STATS_SHOTS] ++
				}
				
				case 26:
				{
					g_MapWeaponsStats[invoker][OP4_KNIFE][STATS_SHOTS] ++
					g_RespawnWeaponsStats[invoker][OP4_KNIFE][STATS_SHOTS] ++
				}
			}
		}
		
		case HL, AG, MINIAG:
		{
			switch(eventid)
			{
				case 18:
				{
					g_MapWeaponsStats[invoker][HLW_HORNETGUN][STATS_SHOTS] ++
					g_RespawnWeaponsStats[invoker][HLW_HORNETGUN][STATS_SHOTS] ++
				}
			}
		}
	}

	return FMRES_HANDLED
}

Float:getFragByRules(attacker, victim)
{
	if(attacker == victim)
		return -1.0
	
	if(g_cvarTeamPlay && !get_pcvar_num(g_cvarTeamPlay))
		return 1.0

	if(hl_get_user_team(attacker) == hl_get_user_team(victim))
		return -2.0
	
	return 1.0
}

set_ent_attack(ent, mode)
{
	static _ent[5]
	num_to_str(ent, _ent, charsmax(_ent))
	TrieSetCell(g_EntAttackList, _ent, mode)
}

get_ent_attack(ent)
{
	static _ent[5], mode; mode = 0
	num_to_str(ent, _ent, charsmax(_ent))
	TrieGetCell(g_EntAttackList, _ent, mode)
	
	return mode
}

set_mine_owner(ent)
{
	static _ent[5]
	num_to_str(ent, _ent, charsmax(_ent))
	TrieSetCell(g_MinesOwners, _ent, pev(ent, pev_owner))
}

get_mine_owner(ent)
{
	static _ent[5]
	num_to_str(ent, _ent, charsmax(_ent))
	TrieGetCell(g_MinesOwners, _ent, ent)
	
	return ent
}

hl_get_user_weapon_ent(client) // Возвращает ИД энтити (weapon entityid) оружия, которое в данный момент у игрока
{
	return get_pdata_cbase(client, g_Offsets[ACTIVEITEM], EXTRAOFFSET)
}

hl_get_weapon_ammo(entity) // Возвращает кол-во патронов в обойме у оружия (на входе weapon entityid)
{
	return get_pdata_int(entity, g_Offsets[WEAPONCLIP], EXTRAOFFSET_WEAPONS)
}

hl_get_user_bpammo(client, weapon) // Возвращает кол-во патронов в запасе у игрока по ИД оружия (HLW_*)
{
	return get_pdata_int(client, _HLW_to_offset(weapon), EXTRAOFFSET)
}

hl_get_wpnname(weapid, name[], len)
{
	switch(weapid)
	{
		case HLW_NONE: 	copy(name, len, "none")
		case HLW_BOLT: 	copy(name, len, "bolt")
		case HLW_HANDGRENADE: 	copy(name, len, "grenade")
		case HLW_TANK: 	copy(name, len, "tank")
		
		default: 
		{
			get_weaponname(weapid, name, len)
			replace(name, len, "weapon_", "")
		}
	}
}

hl_get_wpnlogname(weapid, name[], len)
{
	switch(weapid)
	{
		case HLW_NONE: 	copy(name, len, "none")
		case HLW_BOLT: 	copy(name, len, "bolt")
		case HLW_HANDGRENADE: 	copy(name, len, "grenade")
		case HLW_RPG: copy(name, len, "rpg_rocket")
		case HLW_HORNETGUN: copy(name, len, "hornet")
		case HLW_GAUSS: copy(name, len, "tau_cannon")
		case HLW_EGON: copy(name, len, "gluon gun")
		case HLW_TANK: 	copy(name, len, "tank")
		
		
		default: 
		{
			get_weaponname(weapid, name, len)
			replace(name, len, "weapon_", "")
		}
	}
}

bool:hl_is_user_spectator(client) // Игрок спектатор?
{
	if(pev(client, pev_iuser1) || pev(client, pev_iuser2))
		return true
		
	return false	
}

hl_get_user_team(client, team[] = "", len = 0)
{
	if(hl_is_user_spectator(client))
		return -1
		
	static Float: tdm; global_get(glb_teamplay, tdm)
	if(tdm < 1.0) return -1
	
	if(!len) len = 16
	engfunc(EngFunc_InfoKeyValue, engfunc(EngFunc_GetInfoKeyBuffer, client), "model", team, len)
	
	static teams[10][16], i, teamid, nIdx
	
	if(!teams[0][0])
	{
		new teamlist[50], nLen, l
		get_pcvar_string(g_cvarTeamlist, teamlist, charsmax(teamlist)); trim(teamlist)
		
		nIdx = 0, l = strlen(teamlist)  
		nLen = (1 + copyc(teams[nIdx], charsmax(teamlist), teamlist, ';')) 
	
		while((nLen < l) && (++nIdx < 10)) 
			nLen += (1 + copyc(teams[nIdx], charsmax(teamlist), teamlist[nLen], ';')) 
	}
	
	teamid = 0
	for(i = 0 ; i < nIdx + 1 ; i++)
	{
		teamid++
		if(equali(teams[i][0], team))
			break
	}

	return teamid
}

hl_get_user_name(id, name[], len)
{
	get_user_name(id, name, len)
	
	if(g_MOD == AG)
	{
		static i, buf[5]
		for(i = 0; i <= 9; ++i)
		{
			formatex(buf, charsmax(buf), "^^%d", i)
			replace_all(name, len, buf, "")
		}
	}
	
	replace_all(name, len, "'", "")
	replace_all(name, len, "^"", "")
}

hl_get_user_health(client)
{
	static Float:healthvalue
	pev(client, pev_health, healthvalue)
	return floatround(healthvalue)
}

hl_get_user_armor(client)
{
	static Float:armorvalue
	pev(client, pev_armorvalue, armorvalue)
	return floatround(armorvalue)
}

_HLW_to_offset(HLW_) // или OP4_
{
	switch(HLW_)
	{
		case HLW_SHOTGUN:				return g_Offsets[AMMO_SHOTGUN]
		case HLW_GLOCK, HLW_MP5:			return g_Offsets[AMMO_9MM]
		case HLW_CHAINGUN:				return g_Offsets[AMMO_ARGRENADE]
		case HLW_PYTHON, OP4_EAGLE:			return g_Offsets[AMMO_PYTHON]
		case HLW_GAUSS, HLW_EGON, OP4_DISPLACER:		return g_Offsets[AMMO_URANIUM]
		case HLW_RPG:					return g_Offsets[AMMO_RPG]
		case HLW_CROSSBOW:				return g_Offsets[AMMO_CROSSBOW]
		case HLW_TRIPMINE:				return g_Offsets[AMMO_TRIPMINE]
		case HLW_SATCHEL:				return g_Offsets[AMMO_SATCHEL]
		case HLW_HANDGRENADE:				return g_Offsets[AMMO_HEGRENADE]
		case HLW_SNARK:					return g_Offsets[AMMO_SNARK]
		case HLW_HORNETGUN:				return g_Offsets[AMMO_HORNET]
		case OP4_M249:					return g_Offsets[AMMO_M249]
		case OP4_SHOCKBEAM:				return g_Offsets[AMMO_SHOCKBEAM]
		case OP4_SPORE:					return g_Offsets[AMMO_SPORE]
		case OP4_M40A1:					return g_Offsets[AMMO_M40A1]
	}
	
	return 0
}

set_mod_offsets(MOD) // Загружаем нужные оффсеты
{
	new offset, i
	switch(MOD)
	{
		case HL:
		{
			g_MOD = HL; offset = 310
			
			g_Offsets[WEAPONCLIP] = 40
			g_Offsets[LAST_HIT_GROUP] = 90
			g_Offsets[ACTIVEITEM] = 306
		
			for(i = AMMO_SHOTGUN; i <= AMMO_HORNET; i++)
				g_Offsets[i] = offset++

			server_print("[lambda_core] Offsets for Half-Life loaded")
		}
		
		case OP4:
		{	
			RegisterHam(Ham_Weapon_SendWeaponAnim,"weapon_grapple", "fw_GrappleAttack", 1)
			RegisterHam(Ham_Spawn, "displacer_ball", "fw_DisplacerAttack")
			RegisterHam(Ham_Spawn, "spore", "fw_ExplosiveSpawn")
			
			g_MOD = OP4; offset = 354
			
			g_Offsets[WEAPONCLIP] = 43
			g_Offsets[LAST_HIT_GROUP] = 93
			g_Offsets[ACTIVEITEM] = 350 // или 351 xD
			
			for(i = AMMO_SHOTGUN; i <= AMMO_M40A1; i++)
				g_Offsets[i] = offset++
			
			server_print("[lambda_core] Offsets for Opposing Force loaded")
		}
		
		case AG:
		{
			g_MOD = AG; offset = 305
			
			g_Offsets[WEAPONCLIP] = 40
			g_Offsets[LAST_HIT_GROUP] = 90
			g_Offsets[ACTIVEITEM] = 302
			
			for(i = AMMO_SHOTGUN; i <= AMMO_HORNET; i++)
				g_Offsets[i] = offset++
			
			server_print("[lambda_core] Offsets for Adrenaline Gamer loaded")
		}
		
		case MINIAG: // у АГ и миниАГ одинаковые оффсеты =D
		{
			g_MOD = MINIAG; offset = 305
			
			g_Offsets[WEAPONCLIP] = 40
			g_Offsets[LAST_HIT_GROUP] = 90
			g_Offsets[ACTIVEITEM] = 302
			
			for(i = AMMO_SHOTGUN; i <= AMMO_HORNET; i++)
				g_Offsets[i] = offset++
			
			server_print("[lambda_core] Offsets for AG mini loaded")
		}
	}
}

reset_stats(id)
{
	reset_player_stats(id)
	reset_player_weapons(id)
	reset_player_victims(id)
	reset_player_attackers(id)
	
	for(new i = 0; i < g_maxPlayers + 1; i++)
	{
		for(new k = 0; k < HIT_RIGHTLEG + 1; k++)
		{
			g_VictimsStats[i][id][k] =0
			g_VictimsBodyhits[i][id][k] =0
		}

		g_VictimsWeapon[i][id][0] = 0
	}
	
	for(new i = 0; i < g_maxPlayers + 1; i++)
	{
		for(new k = 0; k < HIT_RIGHTLEG + 1; k++)
		{
			g_AttackersStats[i][id][k] =0
			g_AttackersBodyhits[i][id][k] =0
		}

		g_AttackersWeapon[i][id][0] = 0
	}
	
	for(new i = 1; i < g_maxPlayers + 1; ++i)
	{
		g_VictimDistance[id][i] = 0 
		g_VictimDistance[i][id] = 0 
	}
	
	g_AttackerDistance[id] = 0
}

reset_player_stats(id)
{
	for(new i = 0; i < STATS; i++)
	{
		g_MapPlayersStats[id][i] =0 	
		g_RespawnPlayersStats[id][i] =0 
	}
}

reset_player_weapons(id)
{
	for(new i = 0; i < HLW_TANK + 1; i++)
	{
		for(new k = 0; k < HIT_RIGHTLEG + 1; k++)
		{
			g_MapWeaponsStats[id][i][k] = 0
			g_MapWeaponsBodyhits[id][i][k] = 0
			g_RespawnWeaponsStats[id][i][k] = 0
			g_RespawnWeaponsBodyhits[id][i][k] = 0
		}
	}
}

reset_player_victims(id) // reset all victims for player
{
	for(new i = 0; i < g_maxPlayers + 1; i++)
	{
		for(new k = 0; k < HIT_RIGHTLEG + 1; k++)
		{
			g_VictimsStats[id][i][k] =0
			g_VictimsBodyhits[id][i][k] =0
		}

		g_VictimsWeapon[id][i][0] = 0
	}
}

reset_player_attackers(id) // reset all attackers for player
{
	for(new i = 0; i < g_maxPlayers + 1; i++)
	{
		for(new k = 0; k < HIT_RIGHTLEG + 1; k++)
		{
			g_AttackersStats[id][i][k] =0
			g_AttackersBodyhits[id][i][k] =0
		}

		g_AttackersWeapon[id][i][0] = 0
	}
}

set_weapon_names()
{
	TrieSetCell(g_WeaponNames, "weapon_crowbar", HLW_CROWBAR)
	TrieSetCell(g_WeaponNames, "weapon_9mmhandgun", HLW_GLOCK)
	TrieSetCell(g_WeaponNames, "weapon_357", HLW_PYTHON)
	TrieSetCell(g_WeaponNames, "weapon_9mmAR", HLW_MP5)
	TrieSetCell(g_WeaponNames, "weapon_shotgun", HLW_SHOTGUN)
	TrieSetCell(g_WeaponNames, "weapon_crossbow", HLW_CROSSBOW)
	TrieSetCell(g_WeaponNames, "rpg_rocket", HLW_RPG)
	TrieSetCell(g_WeaponNames, "weapon_gauss", HLW_GAUSS)
	TrieSetCell(g_WeaponNames, "weapon_egon", HLW_EGON)
	TrieSetCell(g_WeaponNames, "hornet", HLW_HORNETGUN)
	TrieSetCell(g_WeaponNames, "grenade", HLW_HANDGRENADE)
	TrieSetCell(g_WeaponNames, "monster_satchel", HLW_SATCHEL)
	TrieSetCell(g_WeaponNames, "monster_tripmine", HLW_TRIPMINE)
	TrieSetCell(g_WeaponNames, "monster_snark", HLW_SNARK)
	TrieSetCell(g_WeaponNames, "bolt", HLW_BOLT)
	TrieSetCell(g_WeaponNames, "tank", HLW_TANK)
	TrieSetCell(g_WeaponNames, "weapon_grapple", OP4_GRAPPLE)
	TrieSetCell(g_WeaponNames, "weapon_eagle", OP4_EAGLE)
	TrieSetCell(g_WeaponNames, "weapon_pipewrench", OP4_WRENCH)
	TrieSetCell(g_WeaponNames, "weapon_m249", OP4_M249)
	TrieSetCell(g_WeaponNames, "weapon_displacer", OP4_DISPLACER)
	TrieSetCell(g_WeaponNames, "weapon_shockrifle", OP4_SHOCKBEAM)
	TrieSetCell(g_WeaponNames, "weapon_sporelauncher", OP4_SPORE)
	TrieSetCell(g_WeaponNames, "weapon_sniperrifle", OP4_M40A1)
	TrieSetCell(g_WeaponNames, "weapon_knife", OP4_KNIFE)
	TrieSetCell(g_WeaponNames, "displacer_ball", OP4_DISPLACER)
	TrieSetCell(g_WeaponNames, "spore", OP4_SPORE)
	TrieSetCell(g_WeaponNames, "shock_beam", OP4_SHOCKBEAM)
	TrieSetCell(g_WeaponNames, "ARgrenade", HLW_HANDGRENADE)
	TrieSetCell(g_WeaponNames, "func_tank", HLW_TANK)
	TrieSetCell(g_WeaponNames, "func_tankmortar", HLW_TANK)
	TrieSetCell(g_WeaponNames, "func_tankrocket", HLW_TANK)
	TrieSetCell(g_WeaponNames, "func_tanklaser", HLW_TANK)
}

show_beam(id, origin1[], origin2[], r, g, b)
{
	message_begin(MSG_ONE, SVC_TEMPENTITY, {0,0,0}, id) 
	write_byte(0)
	write_coord(origin1[0]) 
	write_coord(origin1[1]) 
	write_coord(origin1[2]) 
	write_coord(origin2[0]) 
	write_coord(origin2[1]) 
	write_coord(origin2[2]) 
	write_short(g_spriteTexture) 
	write_byte(1)
	write_byte(1)
	write_byte(100)
	write_byte(5)
	write_byte(0) 	
	write_byte(r) 
	write_byte(g)
	write_byte(b)
	write_byte(100)
	write_byte(0)
	message_end() 
	
}

RANK_UPDATE_PLAYER(id)
{
	if(is_user_bot(id) && !get_pcvar_num(g_RankBotCvar))
		return
	
	if(!get_pcvar_num(g_enableRanksCvar) || !g_IsOnServer[id])
		return
	
	new _uniqueid[32], uniqueid[32], name[32], stats[8], bodyhits[8], found
	hl_get_user_name(id, name, charsmax(name))
	
	switch(get_pcvar_num(g_StatsTrackMode))
	{ 
		case 1: copy(uniqueid, charsmax(uniqueid), name)
		case 2: get_user_ip(id, uniqueid, charsmax(uniqueid), 1)
		case 3: get_user_authid(id, uniqueid, charsmax(uniqueid))
	}
	
	for(new t = 0; t < ArraySize(g_ArrayAuth); t++)
	{
		ArrayGetString(g_ArrayAuth, t, _uniqueid, charsmax(_uniqueid))
		
		if(equal(_uniqueid, uniqueid))
		{
		
			HashGetArray(g_TrieStats, uniqueid, stats, sizeof stats)
			HashGetArray(g_TrieBodyhits, uniqueid, bodyhits, sizeof bodyhits)
			
			stats[STATS_KILLS] += g_MapPlayersStats[id][STATS_KILLS]
			stats[STATS_DEATHS] += g_MapPlayersStats[id][STATS_DEATHS]
			stats[STATS_TEAMKILLS] += g_MapPlayersStats[id][STATS_TEAMKILLS]
			
			for(new i = 1; i < HLW_TANK + 1; ++i)
			{
				stats[STATS_HEADSHOTS] += g_MapWeaponsStats[id][i][STATS_HEADSHOTS]
				stats[STATS_SHOTS] += g_MapWeaponsStats[id][i][STATS_SHOTS]
				stats[STATS_HITS] += g_MapWeaponsStats[id][i][STATS_HITS]
				stats[STATS_DAMAGE] += g_MapWeaponsStats[id][i][STATS_DAMAGE]
				
				for(new k = 0; k < STATS; k++)
					bodyhits[k] += g_MapWeaponsBodyhits[id][i][k]
			}
			
			TrieSetString(g_TrieNames, uniqueid, name)
			HashSetArray(g_TrieStats, uniqueid, stats, sizeof stats)
			HashSetArray(g_TrieBodyhits, uniqueid, bodyhits, sizeof bodyhits)
			TrieSetCell(g_TrieTimestamps, uniqueid, get_systime())
			
			found = 1
			break
		}
	}
	
	if(!found)
	{
		stats[STATS_KILLS] = g_MapPlayersStats[id][STATS_KILLS]
		stats[STATS_DEATHS] = g_MapPlayersStats[id][STATS_DEATHS]
		stats[STATS_TEAMKILLS] = g_MapPlayersStats[id][STATS_TEAMKILLS]
		
		for(new i = 1; i < HLW_TANK + 1; ++i)
		{
			stats[STATS_HEADSHOTS] += g_MapWeaponsStats[id][i][STATS_HEADSHOTS]
			stats[STATS_SHOTS] += g_MapWeaponsStats[id][i][STATS_SHOTS]
			stats[STATS_HITS] += g_MapWeaponsStats[id][i][STATS_HITS]
			stats[STATS_DAMAGE] += g_MapWeaponsStats[id][i][STATS_DAMAGE]
			
			for(new k = 0; k < STATS; k++)
				bodyhits[k] += g_MapWeaponsBodyhits[id][i][k]
		}
		
		ArrayPushString(g_ArrayAuth, uniqueid)
		TrieSetString(g_TrieNames, uniqueid, name)
		HashSetArray(g_TrieStats, uniqueid, stats, sizeof stats)
		HashSetArray(g_TrieBodyhits, uniqueid, bodyhits, sizeof bodyhits)
		TrieSetCell(g_TrieTimestamps, uniqueid, get_systime())
	}
}

RANKS_LOAD_FROM_FILE()
{
	new vault = fopen(g_DataFile, "r")
	if(!vault) return
	
	new stats[STATS], bodyhits[HIT_RIGHTLEG + 1], i_timestamp, deleted_keys, prunetime = get_pcvar_num(g_PruneTime), curtime = get_systime()
	new _data[1024], uniqueid[32], name[32], rankdata[512], timestamp[32], conv
	new _kills[20], _deaths[20], _tkills[20], _shots[20], _hits[20], _dmg[32], _hs[20], _scd[20]
	new _h_all[20], _h_hd[20], _h_ch[20], _h_st[20], _h_la[20], _h_ra[20], _h_ll[20], _h_rl[20]
	
	while(!feof(vault))
	{
		fgets(vault, _data, charsmax(_data))
		
		if(!strlen(_data))
			continue
		
		parse(_data, uniqueid, charsmax(uniqueid), name, charsmax(name), rankdata, charsmax(rankdata))
		
		if(equal(uniqueid, "lambda_core") /*&& equal(name, VERSION)*/ && !conv)
		{
			conv ++
			continue
		}
		
		if(_data[0])
		{
			timestamp[0] = 0
			
			for(new i = strlen(_data) - 1; i >= 0; i--)
			{
				if(_data[i] == '"')
					break
				
				if(_data[i] == ' ')
				{
					copy(timestamp, charsmax(timestamp), _data[i + 1])
					break
				}
			}
			
			i_timestamp = str_to_num(timestamp)
			
			TrieSetCell(g_TrieTimestamps, uniqueid, i_timestamp)
		}	
		
		if(prunetime && (curtime - i_timestamp > prunetime * 24 * 60 * 60))
		{
			deleted_keys ++
			continue
		}
		
		if(conv)
		{
			parse(rankdata, _kills, charsmax(_kills), _deaths, charsmax(_deaths), _tkills, charsmax(_tkills),
				_shots, charsmax(_shots), _hits, charsmax(_hits), _dmg, charsmax(_dmg), _hs, charsmax(_hs),
				_scd, charsmax(_scd), _h_all, charsmax(_h_all), _h_hd, charsmax(_h_hd), _h_ch, charsmax(_h_ch),
				_h_st, charsmax(_h_st), _h_la, charsmax(_h_la), _h_ra, charsmax(_h_ra),
				_h_ll, charsmax(_h_ll), _h_rl, charsmax(_h_rl))
		
			ArrayPushString(g_ArrayAuth, uniqueid)
			TrieSetString(g_TrieNames, uniqueid, name)
			
			stats[STATS_KILLS] = str_to_num(_kills)
			stats[STATS_DEATHS] = str_to_num(_deaths)
			stats[STATS_TEAMKILLS] = str_to_num(_tkills)
			stats[STATS_SHOTS] = str_to_num(_shots)
			stats[STATS_HITS] = str_to_num(_hits)
			stats[STATS_DAMAGE] = str_to_num(_dmg)
			stats[STATS_HEADSHOTS] = str_to_num(_hs)
			
			bodyhits[HIT_GENERIC] = str_to_num(_h_all)
			bodyhits[HIT_HEAD] = str_to_num(_h_hd)
			bodyhits[HIT_CHEST] = str_to_num(_h_ch)
			bodyhits[HIT_STOMACH] = str_to_num(_h_st)
			bodyhits[HIT_LEFTARM] = str_to_num(_h_la)
			bodyhits[HIT_RIGHTARM] = str_to_num(_h_ra)
			bodyhits[HIT_LEFTLEG] = str_to_num(_h_ll)
			bodyhits[HIT_RIGHTLEG] = str_to_num(_h_rl)
			
			HashSetArray(g_TrieStats, uniqueid, stats, sizeof stats)
			HashSetArray(g_TrieBodyhits, uniqueid, bodyhits, sizeof bodyhits)
		}
		else // Если файл статы от старой версии плагина, то читаем его чуток по другому
		{
			parse(_data, uniqueid, charsmax(uniqueid), rankdata, charsmax(rankdata))
			
			parse(rankdata,  name, charsmax(name), _kills, charsmax(_kills), _deaths, charsmax(_deaths), _tkills, charsmax(_tkills),
				_shots, charsmax(_shots), _hits, charsmax(_hits), _dmg, charsmax(_dmg), _hs, charsmax(_hs),
				_scd, charsmax(_scd), _h_all, charsmax(_h_all), _h_hd, charsmax(_h_hd), _h_ch, charsmax(_h_ch),
				_h_st, charsmax(_h_st), _h_la, charsmax(_h_la), _h_ra, charsmax(_h_ra),
				_h_ll, charsmax(_h_ll), _h_rl, charsmax(_h_rl))
			
			replace_all(name, charsmax(name), "%", " ")
			
			ArrayPushString(g_ArrayAuth, uniqueid)
			TrieSetString(g_TrieNames, uniqueid, name)
			
			stats[STATS_KILLS] = str_to_num(_kills)
			stats[STATS_DEATHS] = str_to_num(_deaths)
			stats[STATS_TEAMKILLS] = str_to_num(_tkills)
			stats[STATS_SHOTS] = str_to_num(_shots)
			stats[STATS_HITS] = str_to_num(_hits)
			stats[STATS_DAMAGE] = str_to_num(_dmg)
			stats[STATS_HEADSHOTS] = str_to_num(_hs)
			
			bodyhits[HIT_GENERIC] = str_to_num(_h_all)
			bodyhits[HIT_HEAD] = str_to_num(_h_hd)
			bodyhits[HIT_CHEST] = str_to_num(_h_ch)
			bodyhits[HIT_STOMACH] = str_to_num(_h_st)
			bodyhits[HIT_LEFTARM] = str_to_num(_h_la)
			bodyhits[HIT_RIGHTARM] = str_to_num(_h_ra)
			bodyhits[HIT_LEFTLEG] = str_to_num(_h_ll)
			bodyhits[HIT_RIGHTLEG] = str_to_num(_h_rl)
			
			HashSetArray(g_TrieStats, uniqueid, stats, sizeof stats)
			HashSetArray(g_TrieBodyhits, uniqueid, bodyhits, sizeof bodyhits)
		}
	}
	
	fclose(vault)
	
	if(deleted_keys)
		log_amx("%d ranks pruned", deleted_keys)
	
	server_print("[lambda_core] Loaded %d ranks", ArraySize(g_ArrayAuth))
}		

RANKS_SAVE_TO_FILE() // Сохраняем ранки в файл
{
	new vault = fopen(g_DataFile, "w+")
	if(!vault) return	
	
	new _uniqueid[32],_name[32], timestamp
	new stats[STATS], bodyhits[HIT_RIGHTLEG + 1]
	
	fprintf(vault, "^"%s^" ^"%s^"^n", "lambda_core", VERSION)
	
	for(new i; i < ArraySize(g_ArrayAuth); i++)
	{
		ArrayGetString(g_ArrayAuth, i, _uniqueid, charsmax(_uniqueid))
		TrieGetString(g_TrieNames, _uniqueid, _name, charsmax(_name))
		HashGetArray(g_TrieStats, _uniqueid, stats, sizeof stats)
		HashGetArray(g_TrieBodyhits, _uniqueid, bodyhits, sizeof bodyhits)
		TrieGetCell(g_TrieTimestamps, _uniqueid, timestamp)
		
		fprintf(vault, "^"%s^" ^"%s^" ^"%d %d %d %d %d %d %d %s %d %d %d %d %d %d %d %d^" %i^n", 
				_uniqueid, 
				_name, 
				stats[STATS_KILLS], 
				stats[STATS_DEATHS],
				stats[STATS_TEAMKILLS],
				stats[STATS_SHOTS],
				stats[STATS_HITS],
				stats[STATS_DAMAGE],
				stats[STATS_HEADSHOTS],
				"NULL",
				bodyhits[HIT_GENERIC],
				bodyhits[HIT_HEAD],
				bodyhits[HIT_CHEST],
				bodyhits[HIT_STOMACH],
				bodyhits[HIT_LEFTARM],
				bodyhits[HIT_RIGHTARM],
				bodyhits[HIT_LEFTLEG],
				bodyhits[HIT_RIGHTLEG], 
				timestamp
			)
	}
	
	fclose(vault)
}

public RANKS_SORTING(Array:Uniqueid, Item1, Item2) // Сортировка ранков
{
	new uID[32], stats[STATS], kpd1, kpd2
	
	ArrayGetString(g_ArrayAuth, Item1, uID, charsmax(uID))
	HashGetArray(g_TrieStats, uID, stats, sizeof stats)
	kpd1 = stats[STATS_KILLS] - stats[STATS_DEATHS]
	
	ArrayGetString(g_ArrayAuth, Item2, uID, charsmax(uID))
	HashGetArray(g_TrieStats, uID, stats, sizeof stats)
	kpd2 = stats[STATS_KILLS] - stats[STATS_DEATHS]
	
	if(kpd1 < kpd2)
		return 1
	
	else if(kpd1 > kpd2)
		return -1

	return 0
}

// Thanks to Brad and ConnorMcLeod for config loading code
config_load()
{
	new configFilename[256]
	
	get_localinfo("amxx_configsdir", configFilename, charsmax(configFilename))
	format(configFilename, charsmax(configFilename), "%s/lambda_core.ini", configFilename)

	new file = fopen(configFilename, "rt")
	
	if(file)
	{
		new buffer[512], cvar[32], value[480]
		
		while(!feof(file))
		{
			fgets(file, buffer, charsmax(buffer))
			trim(buffer)
            
			if(buffer[0] && !equal(buffer, "//", 2) && !equal(buffer, ";", 1))
			{
				strbreak(buffer, cvar, charsmax(cvar), value, charsmax(value))

				if(value[0] == 0 || isalpha(value[0]))
					set_cvar_string(cvar, value)
				
				else if(contain(value, "."))
					set_cvar_float(cvar, floatstr(value))
				
				else
					set_cvar_num(cvar, str_to_num(value))
			}
		}
		
		fclose(file)
	}
	else
	{
		file = fopen(configFilename, "wt")
		
		if(!file)
			return
			
		new szPluginFileName[96], szPluginName[64], szAuthor[32], szVersion[32], szStatus[2] 
		
		new iPlugin = get_plugin(-1, szPluginFileName, charsmax(szPluginFileName), szPluginName, charsmax(szPluginName),  
			szVersion, charsmax(szVersion), szAuthor, charsmax(szAuthor), szStatus, charsmax(szStatus)) 

		server_print("%s Config file is missing. Creating...", PREFIX)
		
		fprintf(file, "; ^"%s^" configuration file^n", szPluginName) 
		fprintf(file, "; Author : ^"%s^"^n", szAuthor) 
		fprintf(file, "; Version : ^"%s^"^n", szVersion) 
		fprintf(file, "; File : ^"%s^"^n", szPluginFileName)
		
		fprintf(file, "^n; Cvars :^n")
		
		new iMax = get_plugins_cvarsnum() 
		new iTempId, iPcvar, szCvarName[256], szCvarValue[128] 
	
		for(new i; i<iMax; i++) 
		{ 
			get_plugins_cvar(i, szCvarName, charsmax(szCvarName), _, iTempId, iPcvar) 
			
			if(contain(szCvarName, "lambda_") != -1)
				continue
			
			if(iTempId == iPlugin ) 
			{ 
				get_pcvar_string(iPcvar, szCvarValue, charsmax(szCvarValue)) 	
				fprintf(file, "%s %s^n", szCvarName, szCvarValue) 
			} 
		} 

		fclose(file)	
	}
}

show_info(id)
{
	if(get_pcvar_num(g_ShowInfoCvar))
	{
		set_hudmessage(149, 5, 5, 0.01, 0.01, 2, 0.02, 600.0, 0.01, 0.1, -1)
		ShowSyncHudMsg(id, g_info_sync, "%L", id, "INFO", VERSION, AUTHOR, g_Cmds)
	}
}

get_available_cmds(str[], len)
{
	new lenA
	
	if(SayRank)
		lenA += formatex(str[lenA], len - lenA, " /rank")
			
	if(SayTop)
		lenA += formatex(str[lenA], len - lenA, " /top15")
		
	if(SayStats)
		lenA += formatex(str[lenA], len - lenA, " /stats")
		
	if(SayRankStats)
		lenA += formatex(str[lenA], len - lenA, " /rankstats")
		
	if(SayStatsMe)
		lenA += formatex(str[lenA], len - lenA, " /statsme")
		
	if(SayHP)
		lenA += formatex(str[lenA], len - lenA, " /hp")
		
	if(SayMe)
		lenA += formatex(str[lenA], len - lenA, " /me")	
		
	if(SayReport)
		lenA += formatex(str[lenA], len - lenA, " /report")	
}

public show_adv()
{
	new cmds[128]; get_available_cmds(cmds, charsmax(cmds))
	add(cmds, charsmax(cmds), " /switch /lcinfo")
	
	client_print(0, print_chat, "%s %L", PREFIX, LANG_SERVER, "ADV", cmds)
	set_task(float(get_pcvar_num(g_adv_freq)), "show_adv", SHOW_ADV_TASK_ID)
}

public getPing(id) 
{
	id -= PING_TASK_ID
	new iPing, iLoss
	get_user_ping(id, iPing, iLoss)
	g_pingSum[id] += iPing
	++g_pingCount[id]
}

handle_info(id) // Информация о плагине
{
	new motd[MAX_BUFFER_LENGTH], len
	
	len = formatex(motd[len], charsmax(motd) - len, 
		"Version: %s^n\
		Last Update: %s^n\
		Author: KORD_12.7^n^n\
		URL:^n\
		http://hl.levshi.ru/forum/ - Russian HL and AG Community^n\
		http://amx-x.ru/ - Russian AMXX Community^n\
		http://forums.alliedmods.net/ - Official AMXX forum^n^n", VERSION, LASTUPDATE)
		
	len += formatex(motd[len], charsmax(motd) - len, 
		"Say commands:^n \
		/rank - display your rank (chat)^n \
		/top15 - display top 15 players (MOTD)^n \
		/stats - display players stats (menu/MOTD)^n \
		/rankstats - display your server stats (MOTD)^n \
		/statsme - display your stats (MOTD) for current session^n \
		/hp - display info. about your killer (chat)^n \
		/me - display current stats (chat)^n \
		/report - display weapon status (say_team)^n \
		/switch - switch client's stats on or off (stored in user info field 'lc')^n^n")
	
	show_motd(id, motd, "Lambda Core: HL ingame Stats")
}

Float:accuracy(stats[8])
{
	if(!stats[STATS_SHOTS])
		return (0.0)
	
	return (100.0 * float(stats[STATS_HITS]) / float(stats[STATS_SHOTS]))
}

Float:effec(stats[8])
{
	if(!stats[STATS_KILLS])
		return (0.0)
	
	return (100.0 * float(stats[STATS_KILLS]) / float(stats[STATS_KILLS] + stats[STATS_DEATHS]))
}

Float:distance(distance)
{
	return float(distance) * 0.0254
}

//--------------------------------
// Trie (Hash) abstraction layer 
// by Zefir <zefir-cs@ukr.net> 
//--------------------------------

stock HashDestroy(&Trie:handle) 
{
	__HashDeleteAllKeys(handle)

	return TrieDestroy(handle)
}

stock __HashDeleteAllKeys(Trie:handle) 
{
	if(!handle) 
		return

	new Array:keys, Trie:pos
	if(TrieGetCell(handle, {10, 30, 'k', 0}, keys) && TrieGetCell(handle, {10, 30, 'p', 0}, pos)) 
	{
		TrieDestroy(pos)

		new array_key[64], size = ArraySize(keys), Array:arr
		for(new i = 0; i < size; i++) 
		{
			ArrayGetString(keys, i, array_key, charsmax(array_key))
			TrieGetCell(handle, array_key, arr)
			ArrayDestroy(arr)
		}

		ArrayDestroy(keys)
	}
}

stock HashSetArray(Trie:handle, const key[], const any:buffer[], size) 
{
	if(!handle) 
		return false

	new Array:arr
	if(!TrieGetCell(handle, key, arr)) 
	{
		arr = ArrayCreate(size, 1)
		ArrayPushArray(arr, buffer)

		new Array:keys, Trie:pos
		if(!TrieGetCell(handle, {10, 30, 'k', 0}, keys)) 
		{
			keys = ArrayCreate(64)
			TrieSetCell(handle, {10, 30, 'k', 0}, keys)
		}
		if(!TrieGetCell(handle, {10, 30, 'p', 0}, pos)) 
		{
			pos = TrieCreate()
			TrieSetCell(handle, {10, 30, 'p', 0}, pos)
		}

		new size = ArraySize(keys)
		ArrayPushString(keys, key)
		TrieSetCell(pos, key, size)
	} 
	else
		ArraySetArray(arr, 0, buffer)

	return TrieSetCell(handle, key, arr)
}

stock bool:HashGetArray(Trie:handle, const key[], any:output[], outputsize) 
{ 
	outputsize++
	new Array:arr

	if(!handle || !TrieGetCell(handle, key, arr))
		return false

	ArrayGetArray(arr, 0, output)

	return true
}

//--------------------------------
// Plugin natives <lambda_core.inc>  
//--------------------------------

#define IsPlayer(%1)	(1 <= %1 <= g_maxPlayers)

#define CHECK_PLAYER(%1) \
	if(!IsPlayer(%1)) \
	{ \
		log_error(AMX_ERR_NATIVE, "Player out of range (%d)", %1); \
		return 0; \
	}

public plugin_natives()
{
	register_library("lambda_core")
	
	register_native("lc_get_user_wstats", "_lc_get_user_wstats")
	register_native("lc_get_user_wrstats", "_lc_get_user_wrstats")
	register_native("lc_get_user_stats", "_lc_get_user_stats")
	register_native("lc_get_user_rstats", "_lc_get_user_rstats")
	register_native("lc_get_user_vstats", "_lc_get_user_vstats")
	register_native("lc_get_user_astats", "_lc_get_user_astats")
	register_native("lc_reset_user_wstats", "_lc_reset_user_wstats")
	register_native("lc_get_stats", "_lc_get_stats")
	register_native("lc_get_statsnum", "_lc_get_statsnum")
}

// native lc_get_user_wstats(index, wpnindex, stats[8], bodyhits[8])
public _lc_get_user_wstats(plugin, params)
{
	if(params != 4)
	{
		log_error(AMX_ERR_NATIVE, "Bad arguments num, expected 4, passed %d", params)
		return 0
	}
	
	new stats[8], bodyhits[8]
	
	new id = get_param(1)
	new wpnid = get_param(2)
	
	CHECK_PLAYER(id)
			
	switch(wpnid)
	{
		case HLW_NONE:
		{
			for(new i = 1 ; i < HLW_TANK; ++i) 
			{
				for(new k =0; k < STATS; k++)
				{
					stats[k] += g_MapWeaponsStats[id][i][k]
					bodyhits[k] += g_MapWeaponsBodyhits[id][i][k]
				}
			}
		}
			
		case HLW_CROWBAR..OP4_KNIFE:
		{
			for(new k =0; k < STATS; k++)
			{
				stats[k] = g_MapWeaponsStats[id][wpnid][k]
				bodyhits[k] = g_MapWeaponsBodyhits[id][wpnid][k]
			}	
		}
		
		default:
		{
			log_error(AMX_ERR_NATIVE, "Invalid weapon id %d", wpnid)
			return 0
		}
	}
	
	set_array(3, stats, sizeof(stats))
	set_array(4, bodyhits, sizeof(bodyhits))
	
	if(stats[STATS_SHOTS] || stats[STATS_DEATHS])
		return 1
	
	return 0	
}

// native lc_get_user_wrstats(index, wpnindex, stats[8], bodyhits[8])
public _lc_get_user_wrstats(plugin, params)
{
	if(params != 4)
	{
		log_error(AMX_ERR_NATIVE, "Bad arguments num, expected 4, passed %d", params)
		return 0
	}
	
	new stats[8], bodyhits[8]
	
	new id = get_param(1)
	new wpnid = get_param(2)
	
	CHECK_PLAYER(id)
		
	switch(wpnid)
	{
		case HLW_NONE:
		{
			for(new i = 1 ; i < HLW_TANK; ++i) 
			{
				for(new k =0; k < STATS; k++)
				{
					stats[k] += g_RespawnWeaponsStats[id][i][k]
					bodyhits[k] += g_RespawnWeaponsBodyhits[id][i][k]
				}
			}
		}
			
		case HLW_CROWBAR..OP4_KNIFE:
		{
			for(new k =0; k < STATS; k++)
			{
				stats[k] = g_RespawnWeaponsStats[id][wpnid][k]
				bodyhits[k] = g_RespawnWeaponsBodyhits[id][wpnid][k]
			}	
		}
		
		default:
		{
			log_error(AMX_ERR_NATIVE, "Invalid weapon id %d", wpnid)
			return 0
		}
	}
	
	set_array(3, stats, sizeof(stats))
	set_array(4, bodyhits, sizeof(bodyhits))
	
	if(stats[STATS_SHOTS] || stats[STATS_DEATHS])
		return 1
	
	return 0	
}

// native lc_get_user_stats(index, stats[8], bodyhits[8])
public _lc_get_user_stats(plugin, params)
{
	if(params != 3)
	{
		log_error(AMX_ERR_NATIVE, "Bad arguments num, expected 3, passed %d", params)
		return 0
	}
	
	new stats[8], bodyhits[8], result
	new key[32], _uniqueid[32]
	
	new id = get_param(1)
	CHECK_PLAYER(id)
	
	switch(get_pcvar_num(g_StatsTrackMode))
	{
		case 1: hl_get_user_name(id, key, charsmax(key))
		case 2: get_user_ip(id, key, charsmax(key), 1)
		case 3: get_user_authid(id, key, charsmax(key))
	}
		
	for(new i = 0; i < ArraySize(g_ArrayAuth); i++)
	{
		ArrayGetString(g_ArrayAuth, i, _uniqueid, charsmax(_uniqueid))
			
		if(equal(_uniqueid, key))
		{
			HashGetArray(g_TrieStats, _uniqueid, stats, sizeof stats)
			HashGetArray(g_TrieBodyhits, _uniqueid, bodyhits, sizeof bodyhits)
				
			result = i + 1
				
			break
		}
	}
	
	set_array(2, stats, sizeof(stats))
	set_array(3, bodyhits, sizeof(bodyhits))
	
	if(result)
		return result
	
	return 0
}

// native lc_get_user_rstats(index, stats[8], bodyhits[8])
public _lc_get_user_rstats(plugin, params)
{
	if(params != 3)
	{
		log_error(AMX_ERR_NATIVE, "Bad arguments num, expected 3, passed %d", params)
		return 0
	}
	
	new stats[8], bodyhits[8]
	
	new id = get_param(1)
	CHECK_PLAYER(id)
	
	stats[STATS_KILLS] = g_RespawnPlayersStats[id][STATS_KILLS]
	stats[STATS_DEATHS] = g_RespawnPlayersStats[id][STATS_DEATHS]
	stats[STATS_TEAMKILLS] = g_RespawnPlayersStats[id][STATS_TEAMKILLS]
		
	for(new i = 1; i < HLW_TANK + 1; ++i)
	{
		stats[STATS_HEADSHOTS] += g_RespawnWeaponsStats[id][i][STATS_HEADSHOTS]
		stats[STATS_SHOTS] += g_RespawnWeaponsStats[id][i][STATS_SHOTS]
		stats[STATS_HITS] += g_RespawnWeaponsStats[id][i][STATS_HITS]
		stats[STATS_DAMAGE] += g_RespawnWeaponsStats[id][i][STATS_DAMAGE]
			
		for(new k = 0; k < STATS; k++)
			bodyhits[k] += g_RespawnWeaponsBodyhits[id][i][k]
	}
	
	set_array(2, stats, sizeof(stats))
	set_array(3, bodyhits, sizeof(bodyhits))
	
	return 1
}

// native lc_get_user_vstats(index, victim, stats[8], bodyhits[8], wpnname[] = "", len = 0)
public _lc_get_user_vstats(plugin, params)
{
	if(params < 4 || params > 6)
	{
		log_error(AMX_ERR_NATIVE, "Bad arguments num, expected 6, passed %d", params)
		return 0
	}
	
	new id = get_param(1)
	new victim = get_param(2)
	
	CHECK_PLAYER(id)
		
	new stats[STATS], bodyhits[HIT_RIGHTLEG + 1], wpnname[32]
		
	if(victim == 0)
	{
		for(new i = 1; i < g_maxPlayers + 1; ++i)
		{
			if(g_VictimsStats[id][i][STATS_HITS])
			{
				for(new k = 0; k < STATS; k++)
				{
					if(k != STATS_HITS)
						stats[k] += g_VictimsStats[id][i][k]
					
					bodyhits[k] += g_VictimsBodyhits[id][i][k]
				}
			}
		}
		
		for(new i = 1; i < HLW_TANK + 1; ++i)
		{
			stats[STATS_SHOTS] += g_RespawnWeaponsStats[id][i][STATS_SHOTS]
			stats[STATS_HITS] += g_RespawnWeaponsStats[id][i][STATS_HITS]
		}
		
		if(stats[STATS_HITS])
		{
			set_array(3, stats, sizeof(stats))
			set_array(4, bodyhits, sizeof(bodyhits))
			set_string(5, "", 0)
			
			return 1
		}
	}
	else
	{
		CHECK_PLAYER(victim)
		
		if(g_VictimsStats[id][victim][STATS_HITS])
		{
			for(new i = 0; i < STATS; i++)
			{
				stats[i] = g_VictimsStats[id][victim][i]
				bodyhits[i] = g_VictimsBodyhits[id][victim][i]
			}
			
			set_array(3, stats, sizeof(stats))
			set_array(4, bodyhits, sizeof(bodyhits))
			
			if(g_VictimsWeapon[id][victim][0])
				hl_get_wpnname(g_VictimsWeapon[id][victim][0], wpnname, charsmax(wpnname))
					
			set_string(5, wpnname, get_param(6))
				
			return 1
		}
	}
	
	set_array(3, stats, sizeof(stats))
	set_array(4, bodyhits, sizeof(bodyhits))
	set_string(5, "", 0)
	
	return 0
}

// native lc_get_user_astats(index, killer, stats[8], bodyhits[8], wpnname[] = "", len = 0)
public _lc_get_user_astats(plugin, params)
{
	if(params < 4 || params > 6)
	{
		log_error(AMX_ERR_NATIVE, "Bad arguments num, expected 6, passed %d", params)
		return 0
	}
	
	new id = get_param(1)
	new killer = get_param(2)
	
	CHECK_PLAYER(id)
		
	new stats[STATS], bodyhits[HIT_RIGHTLEG + 1], wpnname[32]
		
	if(killer == 0)
	{
		for(new i = 1; i < g_maxPlayers + 1; ++i)
		{
			if(g_AttackersStats[id][i][STATS_HITS])
			{
				for(new k = 0; k < STATS; k++)
				{
					stats[k] += g_AttackersStats[id][i][k]
					bodyhits[k] += g_AttackersBodyhits[id][i][k]
				}
			}
		}
				
		if(stats[STATS_HITS])
		{
			set_array(3, stats, sizeof(stats))
			set_array(4, bodyhits, sizeof(bodyhits))
			set_string(5, "", 0)
			
			return 1
		}
	}
	else
	{
		CHECK_PLAYER(killer)
		
		if(g_AttackersStats[id][killer][STATS_HITS])
		{
			for(new i = 0; i < STATS; i++)
			{
				stats[i] = g_AttackersStats[id][killer][i]
				bodyhits[i] = g_AttackersBodyhits[id][killer][i]
			}
			
			set_array(3, stats, sizeof(stats))
			set_array(4, bodyhits, sizeof(bodyhits))
			
			if(g_AttackersWeapon[id][killer][0])
				hl_get_wpnname(g_AttackersWeapon[id][killer][0], wpnname, charsmax(wpnname))
				
			set_string(5, wpnname, get_param(6))
				
			return 1
		}
	}
	
	set_array(3, stats, sizeof(stats))
	set_array(4, bodyhits, sizeof(bodyhits))
	set_string(5, "", 0)
	
	return 0
}

// native lc_reset_user_wstats(index)
public _lc_reset_user_wstats(plugin, params)
{
	if(params != 1)
	{
		log_error(AMX_ERR_NATIVE, "Bad arguments num, expected 1, passed %d", params)
		return 0
	}
	
	new id = get_param(1)
	CHECK_PLAYER(id)	
		
	reset_player_stats(id)
	reset_player_weapons(id)
	reset_player_victims(id)
	reset_player_attackers(id)
		
	for(new i = 1; i < g_maxPlayers + 1; ++i)
	{
		g_VictimDistance[id][i] = 0 
		g_VictimDistance[i][id] = 0 
	}
		
	g_AttackerDistance[id] = 0	

	return 1
}

// native lc_get_stats(index, stats[8], bodyhits[8], name[], len, authid[] = "", authidlen = 0)
public _lc_get_stats(plugin, params)
{
	if(params < 5 || params > 7)
	{
		log_error(AMX_ERR_NATIVE, "Bad arguments num, expected 7, passed %d", params)
		return 0
	}
	
	new position = get_param(1)
	new stats[8], bodyhits[8], _uniqueid[32], name[32]
	new size = ArraySize(g_ArrayAuth)
		
	if(position < size)
	{
		ArrayGetString(g_ArrayAuth, position, _uniqueid, charsmax(_uniqueid))
		TrieGetString(g_TrieNames, _uniqueid, name, charsmax(name))
			
		HashGetArray(g_TrieStats, _uniqueid, stats, sizeof stats)
		HashGetArray(g_TrieBodyhits, _uniqueid, bodyhits, sizeof bodyhits)		
	}
	
	set_array(2, stats, sizeof(stats))
	set_array(3, bodyhits, sizeof(bodyhits))
	set_string(4, name, get_param(5))
	set_string(6, _uniqueid, get_param(7))
	
	if(position < size - 1)
		return position + 1
		
	return 0	
}

// native lc_get_statsnum()
public _lc_get_statsnum(plugin)
{
	return ArraySize(g_ArrayAuth)
}
