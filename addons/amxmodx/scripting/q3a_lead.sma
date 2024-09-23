// Dieses Script macht eine Ansage, wie wir sie aus Quake III kennen:
// "You have taken the lead!"
// "You were tied for the lead!"
// "You have lost the lead!"
// Der say-Befehl /lead zeigt den aktuellen Leader an.
//
// Die CVars amx_lead_minkills gibt an, ab wieviel Kills das Script aktiv wird, um eine uebermaessige
// Ausgabe von Sounds am Rundenbeginn zu vermeiden.
//
// Die CVars amx_lead_leadername, amx_lead_leaderuid und amx_lead_leaderkills speichern Namen, UID und Kills des besten.
// Wenn es keinen Leader gibt, ist amx_lead_leadername = 0.
// Wenn es mehrere gibt, gibt amx_lead_leadername die Anzahl wieder.
// Diese CVars sind dazu gedacht, anderen Scripts den Leader anzugeben.
// Wenn man sie per Konsolenbefehl aendert, wird dies auf dieses Script keinerlei Auswirkung haben!!!
//
// Idea & Scripting by [SWz]MistaGee
// http://www.mistagee.de
// Have fun with it!

#include <amxmodx>
#include <amxmisc>

new PLUGIN[] = "Q3A Lead Announcement"
new VERSION[] = "2.5"
new AUTHOR[] = "[SWz]MistaGee"

// LANGUAGES: 0=English, 1=Deutsch
// Der hier eingestellte Wert wird der Default-Wert für die entsprechende CVar.
// The value you set here will become default for the cvar amx_lead_language.
#define LANG 1
#define MAX_LANGUAGES 2

// Nachrichten definieren, um sie spaeter sprachabhaengig auszugeben
new msg_takenlead[MAX_LANGUAGES][] = {
	"%s has taken the lead with %d kills!",
	"%s hat mit %d Kills die Fuehrung uebernommen!"
}

new msg_catchup_single[MAX_LANGUAGES][] = {
	"You caught up with %s!",
	"Du hast %s eingeholt!"
}
	
new msg_catchup_multi[MAX_LANGUAGES][] = {
	"You caught up with the other leaders!",
	"Du hast die anderen Leader eingeholt!"
}

new msg_catchup_by[MAX_LANGUAGES][] = {
	"You were tied for the lead by %s!",
	"Du wurdest von %s eingeholt!"
}

new msg_tied_after_dsc[MAX_LANGUAGES][] = {
	"After the leader disconnected you are about to become the new one!!!^nGO GO GO!!!",
	"Der bisherige Leader hat disconnectet, sodass du jetzt Leader werden kannst!!!^nHOL DIR DEN TITEL!!!"
}

new msg_plnum_tied[MAX_LANGUAGES][] = {
	"Atm there are %d Players running for leadership with %d Kills!",
	"Im Moment liegen %d Spieler gleichauf mit %d Kills!"
}

new msg_tie_with[MAX_LANGUAGES][] = {
	"You are running for leadership with %s at %d kills!",
	"Du stehst gleichauf mit %s bei %d Kills!"
}

new msg_ulead[MAX_LANGUAGES][] = {
	"Atm you are the leader yourself with %d kills!",
	"Im Moment liegst du selbst mit %d Kills in Fuehrung!"
}

new msg_onelead[MAX_LANGUAGES][] = {
	"Atm %s is leading with %d kills!",
	"Im Moment liegt %s mit %d Kills in Fuehrung!"
}

new msg_nolead[MAX_LANGUAGES][] = {
	"There is no leader yet!",
	"Im Moment liegt niemand in Fuehrung!"
}

// Standardsprache definieren
new language = LANG

public plugin_init(){
	register_plugin(PLUGIN, VERSION, AUTHOR)

	register_cvar("amx_lead_minkills", "3")
	register_cvar("amx_lead_leadername", "0")
	register_cvar("amx_lead_leaderkills", "0")
	register_cvar("amx_lead_leaderuid", "0")
	
	new langnummer[3]
	num_to_str(LANG, langnummer, 2)
	register_cvar("amx_lead_language", langnummer)

	register_concmd("say /lead", "cmd_saylead", -1, "Say /lead to see who's the leader in the moment")
	
	register_event("DeathMsg", "cmd_lead_check", "a")
	register_event("TextMsg", "cmd_restartgame", "a", "2=#Game_Commencing", "2=#Game_will_restart_in")
	}

public plugin_precache(){
	// Sounds precachen, damit Clients, die sie nicht haben, sie (hopefully) saugen
	precache_sound("misc/takenlead.wav")	// Nur wegen Saugen geprechachet
	precache_sound("misc/tiedlead.wav")		// Nur wegen Saugen geprechachet
	precache_sound("misc/lostlead.wav")		// Nur wegen Saugen geprechachet
	precache_sound("misc/theone.wav")		// Wird wirklich gebraucht! NICHT ENTFERNEN!!!
	}
	
new playerkills, maxkills, maxkills_uid[32], zero_target = 0, kID = 0, vID = 0, kTeam = 0, vTeam = 0



public cmd_lead_check(some_strange_id){
	// Sprache fuer moegliche Ausgaben setzen!!!
	language = get_cvar_num("amx_lead_language")
	
	// User-ID & Kills des Killers auslesen
	kID = read_data(1)
	kTeam = get_user_team(kID)
	playerkills = get_user_frags(kID) + 1

	vID = read_data(2)
	vTeam = get_user_team(vID)
	
	// Abbruchbedingungen
	if((playerkills < get_cvar_num("amx_lead_minkills")) ||	// Minkills nicht erreicht
		(playerkills < maxkills) ||							// Maxkills der anderen unterschritten
		(kTeam == vTeam)){									// TK oder selbst angegriffen
		return PLUGIN_CONTINUE;}//if
	
	if(playerkills > maxkills){ // Unser Mann ist der neue Chief
		// Wenn der Mensch schonmal die Fuehrung geholt hat, is alles m'kaaaaaaaaaaaaaaaaaaaaaaaay
		// dann muessen nur noch die Maxkills angepasst werden, und schon sind wir gluecklich!
		if((maxkills_uid[0] == kID) && (array_count(maxkills_uid, 32) == 1)){
			maxkills = playerkills
			return PLUGIN_CONTINUE
			}//if
		
		// Allen bisherigen Usern sagen, dass sie die Fuehrung vergessen koennen - abgesehen vom neuen Leader
		for(new p = 0; p < 32; p++){
			if((maxkills_uid[p] > 0) && (maxkills_uid[p] != kID)){
				client_cmd(maxkills_uid[p], "spk misc/lostlead.wav")
				}//if
			}//for


		// Dem Spieler sagen, dass er Big Daddy ist
		if(kID > 0){ // Sound darf nicht an alle gehen - das nervt
			client_cmd(kID, "spk misc/takenlead.wav")
		}//if
		
		// HUD-Msg an alle
		set_hudmessage(255, 0, 0, -1.0, 0.8, 1, 6.0, 6.0, 1.0, 1.0, 2)
		new hudmsg_username[32]
		get_user_name(kID, hudmsg_username, 31)
		show_hudmessage(zero_target, msg_takenlead[language], hudmsg_username, playerkills)
		
		// Neuen Leader als einzigen ins Leader-Array schreiben, Rest mit 0en fuellen
		maxkills = playerkills
		maxkills_uid[0] = kID
		array_fillzero(maxkills_uid, 32, 1)
		
		// CVars setzen
		set_cvar_string("amx_lead_leadername", hudmsg_username)	// Nick des Leaders
		set_cvar_num("amx_lead_leaderuid", kID)					// UID
		set_cvar_num("amx_lead_leaderkills", playerkills)		// Kills
		}//if
	
	else if(playerkills == maxkills){
		// Unser Mann muss ins Leader-Array aufgenommen werden
		add_to_array(maxkills_uid, 32, kID)
		new test_uid = 0
		for(new i = 0; i < 32; i++){
			test_uid = maxkills_uid[i]
			if(test_uid > 0){
				client_cmd(test_uid, "spk misc/tiedlead.wav")
				if(test_uid == kID){ // Killer kriegt eine eigene Nachricht
					if(array_count(maxkills_uid, 32) == 2){ // Wenn jetz nur 2 Leutz drinstehn, muss Nr0 der bisherige Leader sein, da unser Mann jetzt als Nr1 drinsteht!
						new leader_name[32]
						get_user_name(maxkills_uid[0], leader_name, 31)
						set_hudmessage(255, 0, 0, -1.0, 0.8, 1, 6.0, 6.0, 1.0, 1.0, 2)
						show_hudmessage(test_uid, msg_catchup_single[language], leader_name)
						}//if
					else{ // Schade, es gibt mehr als 2 Leutz im Array
						set_hudmessage(255, 0, 0, -1.0, 0.8, 1, 6.0, 6.0, 1.0, 1.0, 2)
						show_hudmessage(test_uid, msg_catchup_multi[language])
						}//else
					}//if
				else{ // Bisherige Leader werden ueber die Konkurrenz informiert
					set_hudmessage(255, 0, 0, -1.0, 0.8, 1, 6.0, 6.0, 1.0, 1.0, 2)
					new hudmsg_username[32]
					get_user_name(kID, hudmsg_username, 31)
					show_hudmessage(test_uid, msg_catchup_by[language], hudmsg_username)
					}//else
				}//if
			}//for
		
		// CVars setzen
		set_cvar_num("amx_lead_leadername", array_count(maxkills_uid, 32))	// Anzahl der Leader
		set_cvar_num("amx_lead_leaderuid", kID)								// UID des letzten
		set_cvar_num("amx_lead_leaderkills", playerkills)					// Kills

		}//else if
	return PLUGIN_CONTINUE
	} // Funktion cmd_lead_check

public client_disconnect(id){
	// Init
	new bool:pl_leader = false
	new bool:pl_onlyleader = false
	language = get_cvar_num("amx_lead_language")
	
	// Pruefen, ob der disconnectende Player (einer) der Leader war
	if(array_in(maxkills_uid, id, 32)){ // Fuer noch keine Leader ist das Array leer, also steht auch der Spieler net drin!
		// Wenn der Typ im Array steht, war er einer
		pl_leader = true
		// Bleibt noch festzustellen, ob er der einzige war
		if(array_count(maxkills_uid,32) == 1){	// Jap
			pl_onlyleader = true
			}//if
		else{									// Nope
			pl_onlyleader = false
			}//else
		}//if
	
	// Spieler-IDs auslesen
	new players[32], num, plmaxkills, j, plkills
	get_players(players, num)
	
	// Maxkills-UID-Array neu fuellen
	for(j = 0; j < num; j++){
		if(!(players[j] == id)){ // Sicherheit, das wir den Disconnecter nicht wieder mit eintragen!
			plkills = get_user_frags(players[j])
			if(plkills > plmaxkills){
				plmaxkills = plkills
				maxkills_uid[0] = players[j]
				array_fillzero(maxkills_uid, 32, 1)
				}//if
			else if(plkills == plmaxkills){
				add_to_array(maxkills_uid, 32, players[j])
				}//else if
			}//if
		}//for
	
	if(pl_leader){
		// Der disconnectende Player war Leader. Was ist zu tun?
		// Anzahl der neuen Leader pruefen, wenn's nur einer ist, erhaelt dieser "Taken the lead"
		// Wenn's mehere sind und der Discer HIGHLANDER war, erhalten alle "Tied for the lead"
		// Wenn der Discer KEIN Highlander war, passiert nix, weil sich fuer die anderen nichts geaendert hat!
		
		if(array_count(maxkills_uid, 32) == 1){
			client_cmd(maxkills_uid[0], "spk misc/takenlead")
			// HUD-Msg an alle
			set_hudmessage(255, 0, 0, -1.0, 0.8, 1, 6.0, 6.0, 1.0, 1.0, 2)
			new hudmsg_username[32]
			get_user_name(maxkills_uid[0], hudmsg_username, 31)
			show_hudmessage(zero_target, msg_takenlead[language], hudmsg_username, get_user_frags(maxkills_uid[0]))
			}//if
		else if(pl_onlyleader){
			for(j = 0; j < array_count(maxkills_uid, 32); j++){
				client_cmd(maxkills_uid[j], "spk misc/tiedlead")
				// HUD-Msg an alle Tied-Leader
				set_hudmessage(255, 0, 0, -1.0, 0.8, 1, 6.0, 6.0, 1.0, 1.0, 2)
				show_hudmessage(maxkills_uid[j], msg_tied_after_dsc[language])
				}//for
			}//else if
		}//if
			
	return PLUGIN_CONTINUE
	} // Funktion client_disconnect


public cmd_saylead(userID, userlevel, cID){
	// Sprache fuer Ausgaben setzen!!!
	language = get_cvar_num("amx_lead_language")

	new plmax_num = array_count(maxkills_uid, 32)
	if(plmax_num > 1){ // Mehrere kaempfen ums Lead
		if((plmax_num == 2) && (array_in(maxkills_uid, userID, 32))){ // Wenn 2 ums Lead kaempfen und unser Mann dabei ist, Ausgeben!
			// Wir haben zwei Leutz im Array - Nr0 und Nr1. Ich brauche die, die unser Mann NICHT ist, also
			// 1 - array_in_pos(Unser_Mann)
			new competitorSlot = 1 - array_in_pos(maxkills_uid, userID, 32)
			new competitorUID = maxkills_uid[competitorSlot]
			new competitorName[32]
			get_user_name(competitorUID, competitorName, 31)
			set_hudmessage(255, 0, 0, -1.0, 0.8, 1, 6.0, 6.0, 1.0, 1.0, 2)
			show_hudmessage(userID, msg_tie_with[language], competitorName, maxkills)
			}//if
		else{
			set_hudmessage(255, 0, 0, -1.0, 0.8, 1, 6.0, 6.0, 1.0, 1.0, 2)
			show_hudmessage(userID, msg_plnum_tied[language], plmax_num, maxkills)
			}//else
		}//if
	else if(plmax_num == 1){ // Genau ein Leader = Highlander!
		if(maxkills_uid[0] == userID){ // wenn unser Cheffe der Leader ist:
			set_hudmessage(255, 0, 0, -1.0, 0.8, 1, 6.0, 6.0, 1.0, 1.0, 2)
			show_hudmessage(userID, msg_ulead[language], get_user_frags(maxkills_uid[0]))
			// Client singt laut "I am the one and only"
			client_cmd(userID, "spk misc/theone.wav")
			if(is_user_alive(userID)){ // Wenn der Spieler nicht lebt, nichts machen --> sonst verraeterisch!!!
				emit_sound(userID, CHAN_AUTO, "misc/theone.wav", 1.0, ATTN_NORM, 0, PITCH_HIGH);} // Alle sollen es hoeren!
			}//if
		else{ // Wenn er nicht der Leader ist, dessen Name anzeigen
			set_hudmessage(255, 0, 0, -1.0, 0.8, 1, 6.0, 6.0, 1.0, 1.0, 2)
			new hudmsg_username[32]
			get_user_name(maxkills_uid[0], hudmsg_username, 31)
			show_hudmessage(userID, msg_onelead[language], hudmsg_username, get_user_frags(maxkills_uid[0]))
			}//else
		}//else if
	else{ // Schade -  noch kein leader vorhanden
		set_hudmessage(255, 0, 0, -1.0, 0.8, 1, 6.0, 6.0, 1.0, 1.0, 2)
		show_hudmessage(userID, msg_nolead[language])
		}//else
	return PLUGIN_CONTINUE
	} // Funktion cmd_saylead

public cmd_restartgame(){
	// Alle Einstellungen zuruecksetzen
	maxkills = 0
	array_fillzero(maxkills_uid, 32, 0)
	return PLUGIN_CONTINUE
	} // Funktion cmd_restartgame


bool:array_fillzero(array[], const len, const val){
	for(new z = val; z < len; z++){
		array[z] = 0
		}//for
	return true
	} // Funktion array_fillzero

add_to_array(array[], const len, const val){
	for(new w = 0; w < len; w++){
		if(array[w] == 0){
			array[w] = val
			return w
			}//if
		}//for
	return -1 // Array ist voll!
	} // Funktion add_to_array

array_count(const array[], const len){
	new array_num = 0
	for(new c = 0; c < len; c++){
		if(array[c] > 0){
			array_num++
			}//if
		}//for
	return array_num
	} // array_count

bool:array_in(const array[], const val, const len){
	new l = 0
	for(l = 0; l < len; l++){
		// Wenn val im Array gefunden wird, true zurueckgeben und Funktion beenden
		if(array[l] == val){return true;}//if
		}//for
	// Val wurde nicht im Array gefunden, also false zurueckgeben
	return false
	} // array_in

array_in_pos(const array[], const val, const len){
	new l = 0
	for(l = 0; l < len; l++){
		// Wenn val im Array gefunden wird, Stelle zurueckgeben und Funktion beenden
		if(array[l] == val){return l;}//if
		}//for
	// Val wurde nicht im Array gefunden, also -1 zurueckgeben
	return -1
	} // array_in_pos

//	new msg[128]
//	format(msg,127,"%s hat mit %d Kills die Fuehrung uebernommen!", get_user_name(maxkills_uid), maxkills)
//	set_hudmessage(255, 255, 255, -1.0, 0.30, 0, 6.0, 6.0, 0.5, 0.15, 3)
//	show_hudmessage(0, msg) // ID=0 shows message to everyone
