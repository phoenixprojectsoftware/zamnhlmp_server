#if defined _lambda_core_included
	#endinput
#endif

#define _lambda_core_included

/*
 * Natives
 */

/* Gets stats from given weapon index. If wpnindex is 0
* then the stats are from all weapons. If weapon has not been used function
* returns 0 in other case 1. 

* Fields in stats are:
* 0 - kills
* 1 - deaths
* 2 - headshots
* 3 - teamkilling
* 4 - shots
* 5 - hits
* 6 - damage

* Fields in bodyhits are:
* 0 - generic (none) 
* 1 - head 
* 2 - chest 
* 3 - stomach 
* 4 - leftarm 
* 5 - rightarm 
* 6 - leftleg 
* 7 - rightleg */
native lc_get_user_wstats(index, wpnindex, stats[8], bodyhits[8]);

/* Gets respawn stats from given weapon index.*/
native lc_get_user_wrstats(index, wpnindex, stats[8], bodyhits[8]);

/* Gets overall stats which are stored in file on server
* and updated on user disconnect.
* Function returns the position in stats by diff. kills to deaths. */
native lc_get_user_stats(index, stats[8], bodyhits[8]);

/* Gets respawn stats of player. */
native lc_get_user_rstats(index, stats[8], bodyhits[8]);

/* Gets stats with which user have killed/hurt his victim. If victim is 0
* then stats are from all victims. If victim has not been hurt, function
* returns 0 in other case 1. User stats are reset on his respawn. */
native lc_get_user_vstats(index, victim, stats[8], bodyhits[8], wpnname[] = "", len = 0);

/* Gets stats with which user have been killed/hurt. If killer is 0
* then stats are from all attacks. If killer has not hurt user, function
* returns 0 in other case 1. User stats are reset on his respawn. */
native lc_get_user_astats(index, killer, stats[8], bodyhits[8], wpnname[] = "", len = 0);

/* Resets life, weapon, victims and attackers user stats. */
native lc_reset_user_wstats(index);

/* Gets overall stats which stored in lc_stats.dat file in amx folder
* and updated on every mapchange or user disconnect.
* Function returns next index of stats entry or 0 if no more exists. */
native lc_get_stats(index, stats[8], bodyhits[8], name[], len, authid[] = "", authidlen = 0);

/* Returns number of all entries in stats. */
native lc_get_statsnum();

/*
 * Forwards
 */

/* Function is called after player to player attacks ,
* if players were damaged by teammate TA is set to 1 */
forward lc_client_damage(attacker, victim, damage, wpnindex, hitplace, TA);

/* Function is called after player death ,
* if player was killed by teammate TK is set to 1 */
forward lc_client_death(killer, victim, wpnindex, hitplace, TK);