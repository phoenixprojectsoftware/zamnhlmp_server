#include <amxmod>
#include <VexdUM>

new g_type, g_enabled, g_received, g_maxplayers, bool:g_showreceived

public plugin_init() {
  register_plugin("Advanced Bullet Damage", "1.1", "Sn!ff3r")
  
  register_event("Damage", "on_damage", "b", "2!0", "3=0", "4!0")
  register_logevent("on_new_round", 2, "0=World triggered", "1=Round_Start")
  
  g_type = register_cvar("amx_bulletdamage","1")
  g_received = register_cvar("amx_bulletdamage_received","1")

  g_maxplayers = get_maxplayers()
}

public on_new_round() {
  g_enabled = get_cvarptr_num(g_type)
  g_showreceived = get_cvarptr_num(g_received) ? true : false
}

public on_damage(id) {
  if(g_enabled > 0) {    
    static attacker; attacker = get_user_attacker(id)
    static damage; damage = read_data(2)    

    if(g_showreceived) {      
      set_hudmessage(255, 0, 0, 0.45, 0.50, 2, 0.1, 4.0, 0.1, 0.1, -1)
      show_hudmessage(id, "%i^n", damage)    
    }

    if((1 <= attacker <= g_maxplayers) && is_user_connected(attacker)) {
      switch(g_enabled) {
        case 1: {
          set_hudmessage(0, 100, 200, -1.0, 0.55, 2, 0.1, 4.0, 0.02, 0.02, -1)
          show_hudmessage(attacker, "%i^n", damage)        
        }
        default: {
          if(can_see(attacker, id)) {
            set_hudmessage(0, 100, 200, -1.0, 0.55, 2, 0.1, 4.0, 0.02, 0.02, -1)
            show_hudmessage(attacker, "%i^n", damage)        
          }
        }
      }
    }
  }
}
