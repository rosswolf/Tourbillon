const { google } = require('googleapis');
const path = require('path');

async function addMoreGremlins() {
    // Service account authentication
    const auth = new google.auth.GoogleAuth({
        keyFile: '/home/rosswolf/Code/google-sheets-mcp/service-account-key.json',
        scopes: ['https://www.googleapis.com/auth/spreadsheets'],
    });

    const sheets = google.sheets({ version: 'v4', auth: await auth.getClient() });
    const spreadsheetId = '1TlOn39AXlw0y2tlkE4kvIpvoZ9SpNQTkDGgOptvqSgM';

    // New Small gremlins (3 additions)
    const newSmallGremlins = [
        {
            template_id: 'spark_flea',
            'NOEX schema_notes': 'Hand disruption threat',
            display_name: 'Spark Flea',
            description: 'Forces card discards with electrical interference',
            archetype: 'hand_disruption',
            size_category: 'small',
            max_health: 10,
            max_armor: 0,
            max_shields: 0,
            shield_regen: 0,
            shield_regen_max: 0,
            has_barrier: false,
            barrier_count: 0,
            damage_cap: 0,
            reflect_percent: 0,
            execute_immunity_threshold: 0,
            can_be_targeted: true,
            summon_position: 'bottom',
            summon_cap: 0,
            moves: 'ticks=6,force_discard=1',
            move_pattern: 'cycle',
            'NOEX developer_notes': 'Teaches hand management under pressure'
        },
        {
            template_id: 'precision_mite',
            'NOEX schema_notes': 'Anti-precision specialist',
            display_name: 'Precision Mite',
            description: 'Tiny gremlin that makes precision attacks ineffective',
            archetype: 'precision_counter',
            size_category: 'small',
            max_health: 14,
            max_armor: 0,
            max_shields: 0,
            shield_regen: 0,
            shield_regen_max: 0,
            has_barrier: false,
            barrier_count: 0,
            damage_cap: 0,
            reflect_percent: 0,
            execute_immunity_threshold: 0,
            can_be_targeted: true,
            summon_position: 'bottom',
            summon_cap: 0,
            moves: 'ticks=0,precision_hard_cap=2',
            move_pattern: 'passive',
            'NOEX developer_notes': 'Forces diversification away from pure precision builds'
        },
        {
            template_id: 'siphon_tick',
            'NOEX schema_notes': 'Gradual resource vampire',
            display_name: 'Siphon Tick',
            description: 'Slowly drains all force types equally',
            archetype: 'gradual_drain',
            size_category: 'small',
            max_health: 16,
            max_armor: 1,
            max_shields: 0,
            shield_regen: 0,
            shield_regen_max: 0,
            has_barrier: false,
            barrier_count: 0,
            damage_cap: 0,
            reflect_percent: 0,
            execute_immunity_threshold: 0,
            can_be_targeted: true,
            summon_position: 'bottom',
            summon_cap: 0,
            moves: 'ticks=10,drain_all_types=1',
            move_pattern: 'cycle',
            'NOEX developer_notes': 'Steady pressure that adds up in long encounters'
        }
    ];

    // New Medium gremlins (3 additions)
    const newMediumGremlins = [
        {
            template_id: 'phase_shifter',
            'NOEX schema_notes': 'Alternating defense phases',
            display_name: 'Phase Shifter',
            description: 'Alternates between high armor and high shields',
            archetype: 'phase_defense',
            size_category: 'medium',
            max_health: 32,
            max_armor: 8,
            max_shields: 8,
            shield_regen: 0,
            shield_regen_max: 0,
            has_barrier: false,
            barrier_count: 0,
            damage_cap: 0,
            reflect_percent: 0,
            execute_immunity_threshold: 0,
            can_be_targeted: true,
            summon_position: 'bottom',
            summon_cap: 0,
            moves: 'ticks=8,switch_armor_shields|ticks=8,switch_shields_armor',
            move_pattern: 'cycle',
            'NOEX developer_notes': 'Tests adaptability between pierce and direct damage'
        },
        {
            template_id: 'momentum_thief',
            'NOEX schema_notes': 'Momentum specialist drainer',
            display_name: 'Momentum Thief',
            description: 'Specializes in stealing and using your momentum',
            archetype: 'momentum_specialist',
            size_category: 'medium',
            max_health: 28,
            max_armor: 2,
            max_shields: 0,
            shield_regen: 0,
            shield_regen_max: 0,
            has_barrier: false,
            barrier_count: 0,
            damage_cap: 0,
            reflect_percent: 0,
            execute_immunity_threshold: 0,
            can_be_targeted: true,
            summon_position: 'bottom',
            summon_cap: 0,
            moves: 'ticks=4,drain_momentum=3,self_gain_shields=3|ticks=6,momentum_soft_cap=5',
            move_pattern: 'cycle',
            'NOEX developer_notes': 'Punishes momentum hoarding, rewards efficient spending'
        },
        {
            template_id: 'feedback_loop',
            'NOEX schema_notes': 'Escalating card cost penalty',
            display_name: 'Feedback Loop',
            description: 'Makes cards more expensive each turn',
            archetype: 'escalating_cost',
            size_category: 'medium',
            max_health: 36,
            max_armor: 0,
            max_shields: 6,
            shield_regen: 1,
            shield_regen_max: 10,
            has_barrier: false,
            barrier_count: 0,
            damage_cap: 0,
            reflect_percent: 0,
            execute_immunity_threshold: 0,
            can_be_targeted: true,
            summon_position: 'bottom',
            summon_cap: 0,
            moves: 'ticks=6,card_cost_penalty=1|ticks=5,card_cost_penalty=2|ticks=4,card_cost_penalty=3',
            move_pattern: 'sequence',
            'NOEX developer_notes': 'Clock pressure - must eliminate before costs become unmanageable'
        }
    ];

    // New Large gremlins (3 additions)  
    const newLargeGremlins = [
        {
            template_id: 'resource_tyrant',
            'NOEX schema_notes': 'Adaptive hard caps based on player resources',
            display_name: 'Resource Tyrant',
            description: 'Imposes hard caps that adapt to your current resources',
            archetype: 'adaptive_constrainer',
            size_category: 'large',
            max_health: 70,
            max_armor: 4,
            max_shields: 0,
            shield_regen: 0,
            shield_regen_max: 0,
            has_barrier: false,
            barrier_count: 0,
            damage_cap: 0,
            reflect_percent: 0,
            execute_immunity_threshold: 0,
            can_be_targeted: true,
            summon_position: 'bottom',
            summon_cap: 0,
            moves: 'ticks=10,adaptive_hard_caps_all=6|ticks=5,drain_highest=4|ticks=5,drain_highest=4',
            move_pattern: 'sequence',
            'NOEX developer_notes': 'Punishes resource imbalance, forces balanced play'
        },
        {
            template_id: 'mirror_warden',
            'NOEX schema_notes': 'High reflect damage with summoning',
            display_name: 'Mirror Warden',
            description: 'Reflects damage while spawning protective minions',
            archetype: 'reflect_summoner',
            size_category: 'large',
            max_health: 60,
            max_armor: 0,
            max_shields: 12,
            shield_regen: 2,
            shield_regen_max: 18,
            has_barrier: false,
            barrier_count: 0,
            damage_cap: 0,
            reflect_percent: 50,
            execute_immunity_threshold: 0,
            can_be_targeted: true,
            summon_position: 'bottom',
            summon_cap: 3,
            moves: 'ticks=8,summon=barrier_gnat|ticks=6,all_gremlins_gain_shields=4|ticks=4,reflect_increase=25',
            move_pattern: 'cycle',
            'NOEX developer_notes': 'High reflect makes direct damage dangerous'
        },
        {
            template_id: 'entropic_mass',
            'NOEX schema_notes': 'Entropy force specialist with decay',
            display_name: 'Entropic Mass',
            description: 'Massive gremlin that spreads entropy and decay',
            archetype: 'entropy_specialist',  
            size_category: 'large',
            max_health: 85,
            max_armor: 6,
            max_shields: 0,
            shield_regen: 0,
            shield_regen_max: 0,
            has_barrier: false,
            barrier_count: 0,
            damage_cap: 0,
            reflect_percent: 0,
            execute_immunity_threshold: 0,
            can_be_targeted: true,
            summon_position: 'bottom',
            summon_cap: 0,
            moves: 'ticks=12,entropy_hard_cap=2|ticks=4,all_forces_decay=1,drain_entropy=3|ticks=2,all_forces_decay=2',
            move_pattern: 'sequence',
            'NOEX developer_notes': 'Anti-entropy strategy, forces diversification'
        }
    ];

    // Combine all new gremlins
    const allNewGremlins = [...newSmallGremlins, ...newMediumGremlins, ...newLargeGremlins];

    console.log(`Adding ${allNewGremlins.length} new gremlins to the sheet...`);

    // First, get current data to find the next empty row
    const currentData = await sheets.spreadsheets.values.get({
        spreadsheetId,
        range: 'A:Z',
    });

    const nextRow = currentData.data.values ? currentData.data.values.length + 1 : 2;
    console.log(`Starting at row ${nextRow}`);

    // Get headers to match column order
    const headers = currentData.data.values[0];
    
    // Convert each gremlin to a row array matching the headers
    const newRows = allNewGremlins.map(gremlin => {
        return headers.map(header => {
            const key = header.replace('__NOEX ', '').replace(' ', '_').toLowerCase();
            return gremlin[key] || gremlin[header] || '';
        });
    });

    // Append the new data
    await sheets.spreadsheets.values.append({
        spreadsheetId,
        range: 'A:Z',
        valueInputOption: 'USER_ENTERED',
        insertDataOption: 'INSERT_ROWS',
        requestBody: {
            values: newRows,
        },
    });

    console.log(`Successfully added ${allNewGremlins.length} new gremlins!`);
    console.log('New gremlins added:');
    allNewGremlins.forEach(g => console.log(`- ${g.display_name} (${g.size_category})`));
}

addMoreGremlins().catch(console.error);