#!/usr/bin/env node

/**
 * Script to update Google Sheets with proper Tourbillon gremlin data
 * 
 * This script:
 * 1. Defines a new schema compatible with StaticData.gd and json_exporter.py
 * 2. Creates proper Tourbillon gremlins based on the design documents
 * 3. Updates the Google Sheets with the new schema and data
 */

const { google } = require('googleapis');
const path = require('path');

// Configuration
const SHEET_ID = '1TlOn39AXlw0y2tlkE4kvIpvoZ9SpNQTkDGgOptvqSgM';
const SHEET_NAME = 'mob_data';
const SERVICE_KEY_PATH = path.join(__dirname, '..', 'google-sheets-mcp', 'service-account-key.json');

/**
 * Define the new Tourbillon gremlin schema compatible with StaticData.gd
 */
function getGremlinSchema() {
    return [
        // Core identification
        'template_id',                  // Primary key for StaticData.gd
        '__NOEX schema_notes',         // Documentation column (excluded from JSON)
        'display_name',                // Human-readable name
        'description',                 // Flavor text
        'archetype',                   // Combat archetype classification
        'size_category',               // Size tier for balancing
        
        // Core Stats  
        'max_health',                  // HP when gremlin enters combat
        'max_armor',                   // Damage reduction amount
        'max_shields',                 // Absorbs damage before HP
        'shield_regen',                // Shields restored per tick (if any)
        'shield_regen_max',            // Maximum shields from regeneration
        
        // Special Defenses
        'has_barrier',                 // Absorbs one complete hit
        'barrier_count',               // Number of barriers (default 1)
        'damage_cap',                  // Maximum damage per hit (0 = no cap)
        'reflect_percent',             // Percentage of damage reflected (0-100)
        'execute_immunity_threshold',  // Cannot be executed above this HP
        
        // Targeting and Positioning
        'can_be_targeted',             // Whether direct attacks can target this gremlin
        'target_protection_condition', // Condition for untargetable
        'summon_position',             // Where summoned gremlins appear
        'summon_cap',                  // Maximum gremlins this can summon
        
        // Move System - use key:value format for complex data
        'move_timing_type',            // "single", "cycle", "escalating", "conditional"
        'move_starting_index',         // Which move to start with (default 0)
        'passive_disruptions',         // Always-active effects (key:value pairs)
        'trigger_effects',             // Timed trigger effects (key:value pairs)
        'move_transitions',            // Move cycle definitions (key:value pairs)
        
        '__NOEX developer_notes'       // Additional notes (excluded from JSON)
    ];
}

/**
 * Create proper Tourbillon gremlin data
 */
function getGremlinData() {
    return [
        // Basic Gnat - Pure fodder
        [
            'basic_gnat',
            'Pure fodder unit for swarm encounters',
            'Basic Gnat',
            'Pure fodder - clogs targeting, minimal threat',
            'fodder',
            'gnat',
            1, 0, 0, 0, 0, // stats: 1 HP, no defenses
            false, 0, 0, 0, 0, // no special defenses
            true, '', 'bottom', 0, // targeting: can target, appears at bottom
            'single', 0, // single move, start at 0
            '', // no passive disruptions
            '', // no trigger effects  
            '', // no move transitions
            'Serves as targeting blocker and AOE test'
        ],
        
        // Dust Mite - Rush threat with Heat disruption
        [
            'dust_mite',
            'Tutorial enemy that teaches soft caps',
            'Dust Mite', 
            'A tiny gremlin that causes friction in Heat mechanisms',
            'rush_threat',
            'small',
            8, 0, 0, 0, 0, // 8 HP, no defenses
            false, 0, 0, 0, 0, // no special defenses
            true, '', 'bottom', 0, // standard targeting
            'single', 0, // single move
            'force_soft_cap_heat:4', // Heat soft capped at 4
            '', // no trigger effects
            '', // no transitions
            'Forces immediate Heat spending, teaches resource pressure'
        ],
        
        // Barrier Gnat - Protected fodder
        [
            'barrier_gnat',
            'Tests multi-hit strategies and barrier mechanics',
            'Barrier Gnat',
            'Protected fodder - tests multi-hit strategies', 
            'protected_fodder',
            'gnat',
            1, 0, 0, 0, 0, // 1 HP, no regen
            true, 1, 0, 0, 0, // has 1 barrier
            true, '', 'bottom', 0, // standard targeting
            'single', 0, // single move
            '', // no disruptions (barrier is the defense)
            '', // no triggers
            '', // no transitions
            'Requires exactly 2 hits to kill regardless of damage amounts'
        ],
        
        // Spring Snapper - Escalating Momentum drainer  
        [
            'spring_snapper',
            'Demonstrates escalating pressure over time',
            'Spring Snapper',
            'A gremlin that increasingly disrupts Momentum generation',
            'scaling_threat', 
            'medium',
            35, 1, 0, 0, 0, // 35 HP, 1 armor
            false, 0, 0, 0, 0, // no special defenses
            true, '', 'bottom', 0, // standard targeting
            'cycle', 0, // cycling moves, start at 0
            '', // no passive effects
            'drain_phase_1:every_8_ticks_drain_2_momentum|drain_phase_2:every_6_ticks_drain_3_momentum|drain_phase_3:every_4_ticks_drain_4_momentum',
            'drain_phase_1>drain_phase_2:after_1_trigger|drain_phase_2>drain_phase_3:after_1_trigger|drain_phase_3>drain_phase_1:after_1_trigger',
            'Each phase drains more Momentum faster - must kill before overwhelming'
        ],
        
        // Gear Tick - Timing disruption
        [
            'gear_tick',
            'Teaches timing efficiency and card sequencing',
            'Gear Tick',
            'A small gremlin that makes your clockwork sluggish',
            'disruption_threat',
            'small', 
            12, 0, 0, 0, 0, // 12 HP, no defenses
            false, 0, 0, 0, 0, // no special defenses
            true, '', 'bottom', 0, // standard targeting
            'single', 0, // single move
            'card_cost_penalty:1', // All cards cost +1 tick
            '', // no triggers
            '', // no transitions
            'Forces efficient play and proper card sequencing'
        ],
        
        // Constricting Barrier Gnat - Protected constraint
        [
            'constricting_barrier_gnat',
            'Extremely annoying combination of protection and constraint',
            'Constricting Barrier Gnat', 
            'Protected pest - limits your biggest resource while protected by barrier',
            'protected_constraint',
            'gnat',
            1, 0, 0, 0, 0, // 1 HP
            true, 1, 0, 0, 0, // barrier protected  
            true, '', 'bottom', 0, // standard targeting
            'single', 0, // single move
            'max_resource_soft_cap:5', // Max any resource soft capped at 5
            '', // no triggers
            '', // no transitions
            'High priority target - barrier + constraint is very frustrating'
        ],
        
        // Oil Thief - Resource vampire with shields
        [
            'oil_thief',
            'Dual threat: hard caps + drains with regenerating shields',
            'Oil Thief',
            'A slippery gremlin that steals your accumulated forces',
            'turtle_rush_combo',
            'medium',
            28, 0, 5, 1, 8, // 28 HP, 5 shields, 1 regen up to 8 max
            false, 0, 0, 0, 0, // no special defenses
            true, '', 'bottom', 0, // standard targeting  
            'cycle', 0, // cycling moves
            '', // no passive effects
            'cap_phase:all_forces_hard_cap_6_for_10_ticks|drain_phase:every_3_ticks_drain_3_largest_force',
            'cap_phase>drain_phase:after_10_ticks|drain_phase>cap_phase:after_3_triggers',
            'Hard caps force spending, then drains punish accumulation'
        ],
        
        // Echo Chamber - Protected summoner
        [
            'echo_chamber',
            'Cannot be targeted while other gremlins exist',
            'Echo Chamber',
            'A resonant cavity that amplifies other gremlin presence',
            'protected_summoner', 
            'large',
            55, 0, 0, 0, 0, // 55 HP, no defenses
            false, 0, 0, 0, 0, // no special defenses
            false, 'while_other_gremlins_exist', 'top', 3, // protected, summons at top, max 3
            'single', 0, // single move
            '', // no passive effects
            'summon_medium:every_4_ticks_summon_random_medium_gremlin', // summon every 4 ticks
            '', // no transitions
            'Forces players to clear minions repeatedly to reach the real threat'
        ]
    ];
}

async function updateGoogleSheets() {
    try {
        console.log('🔄 Starting Google Sheets gremlin data update...');
        
        // Setup authentication
        const auth = new google.auth.GoogleAuth({
            keyFile: SERVICE_KEY_PATH,
            scopes: ['https://www.googleapis.com/auth/spreadsheets'],
        });
        
        const sheets = google.sheets({ version: 'v4', auth: await auth.getClient() });
        
        console.log('✅ Authentication successful');
        
        // Prepare data for upload
        const schema = getGremlinSchema();
        const gremlinData = getGremlinData();
        
        // Combine headers and data
        const allData = [schema, ...gremlinData];
        
        console.log(`📊 Prepared ${gremlinData.length} gremlins with ${schema.length} columns`);
        
        // Clear existing content
        console.log('🧹 Clearing existing data...');
        await sheets.spreadsheets.values.clear({
            spreadsheetId: SHEET_ID,
            range: `${SHEET_NAME}!A:Z`
        });
        
        // Upload new data
        console.log('📤 Uploading new gremlin data...');
        await sheets.spreadsheets.values.update({
            spreadsheetId: SHEET_ID,
            range: `${SHEET_NAME}!A1`,
            valueInputOption: 'USER_ENTERED',
            requestBody: {
                values: allData
            }
        });
        
        console.log('✅ Google Sheets updated successfully!');
        console.log(`📋 Schema: ${schema.length} columns`);
        console.log(`🎯 Data: ${gremlinData.length} gremlin entries`);
        console.log(`🔗 View at: https://docs.google.com/spreadsheets/d/${SHEET_ID}/edit#gid=479849152`);
        
        // Display summary of what was uploaded
        console.log('\\n📖 Uploaded Gremlins:');
        gremlinData.forEach((row, idx) => {
            console.log(`   ${idx + 1}. ${row[2]} (${row[0]}) - ${row[4]} ${row[5]}`);
        });
        
        return true;
        
    } catch (error) {
        console.error('❌ Error updating Google Sheets:', error.message);
        if (error.code === 403) {
            console.error('🔒 Permission denied. Make sure the service account has edit access to the sheet.');
        }
        throw error;
    }
}

// Run the update if called directly
if (require.main === module) {
    updateGoogleSheets()
        .then(() => {
            console.log('\\n🎉 Gremlin data update completed successfully!');
            process.exit(0);
        })
        .catch((error) => {
            console.error('\\n💥 Update failed:', error.message);
            process.exit(1);
        });
}

module.exports = { updateGoogleSheets, getGremlinSchema, getGremlinData };