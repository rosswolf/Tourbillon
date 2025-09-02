#!/usr/bin/env node

/**
 * Script to port the complete Gremlin Bestiary into Google Sheets
 * Based on GREMLIN_BESTIARY.md and ENCOUNTER_WAVES.md
 */

const { google } = require('googleapis');
const path = require('path');

// Configuration
const SHEET_ID = '1TlOn39AXlw0y2tlkE4kvIpvoZ9SpNQTkDGgOptvqSgM';
const SHEET_NAME = 'mob_data';
const SERVICE_KEY_PATH = path.join(__dirname, '..', 'google-sheets-mcp', 'service-account-key.json');

/**
 * Complete Gremlin Bestiary data based on design docs
 */
function getFullBestiaryData() {
    return [
        // === GNATS (Swarm Fodder) ===
        [
            'basic_gnat',
            'Pure fodder - clogs targeting, minimal threat',
            'Basic Gnat',
            'Pure fodder - clogs targeting, minimal threat',
            'fodder',
            'gnat',
            1, 0, 0, 0, 0, // 1 HP, no defenses
            false, 0, 0, 0, 0, // no special defenses
            true, '', 'bottom', 0, // standard targeting
            'single', 0,
            '', '', '', // no effects or transitions
            'Forces AOE damage to be efficient'
        ],
        
        [
            'barrier_gnat',
            'Protected fodder - tests multi-hit strategies',
            'Barrier Gnat',
            'Protected fodder - tests multi-hit strategies',
            'protected_fodder',
            'gnat',
            1, 0, 0, 0, 0, // 1 HP
            true, 1, 0, 0, 0, // 1 barrier
            true, '', 'bottom', 0,
            'single', 0,
            '', '', '',
            'Requires exactly 2 hits regardless of damage amounts'
        ],
        
        [
            'constricting_barrier_gnat',
            'Protected constraint - extremely annoying',
            'Constricting Barrier Gnat', 
            'Protected pest - limits your biggest resource while barrier protected',
            'protected_constraint',
            'gnat',
            1, 0, 0, 0, 0,
            true, 1, 0, 0, 0, // barrier protected
            true, '', 'bottom', 0,
            'single', 0,
            'max_resource_soft_cap:5', // Max any resource soft capped at 5
            '', '',
            'High priority for multi-hit removal'
        ],
        
        [
            'draining_barrier_gnat',
            'Protected disruption - persistent drain with barrier',
            'Draining Barrier Gnat',
            'Protected persistent annoyance that drains forces',
            'protected_disruption',
            'gnat',
            1, 0, 0, 0, 0,
            true, 1, 0, 0, 0,
            true, '', 'bottom', 0,
            'single', 0,
            '',
            'periodic_drain:every_6_ticks_drain_2_random_force',
            '',
            'Much more threatening than regular Drain Gnat due to barrier'
        ],
        
        [
            'toxic_barrier_gnat',
            'Protected constraint - devastates advanced strategies',
            'Toxic Barrier Gnat',
            'Barrier-protected gremlin that limits special resources',
            'protected_constraint',
            'gnat',
            1, 0, 0, 0, 0,
            true, 1, 0, 0, 0,
            true, '', 'bottom', 0,
            'single', 0,
            'special_resources_soft_cap:2', // All special resources capped at 2
            '', '',
            'Devastates HEAT, PRECISION, etc. strategies'
        ],
        
        [
            'breeding_barrier_gnat',
            'Protected multiplier - nightmare swarm source',
            'Breeding Barrier Gnat',
            'Self-replacing barrier-protected swarm source',
            'protected_multiplier',
            'gnat',
            1, 0, 0, 0, 0,
            true, 1, 0, 0, 0,
            true, '', 'bottom', 3, // summon cap of 3
            'single', 0,
            '',
            'breed_gnats:every_10_ticks_summon_basic_gnat',
            '',
            'Absolute priority target - requires multi-hit to stop breeding'
        ],
        
        [
            'drain_gnat',
            'Annoying fodder - small persistent disruption',
            'Drain Gnat',
            'Minimal disruption that becomes annoying in groups',
            'annoying_fodder',
            'gnat',
            1, 0, 0, 0, 0,
            false, 0, 0, 0, 0,
            true, '', 'bottom', 0,
            'single', 0,
            '',
            'weak_drain:every_8_ticks_drain_1_random_force',
            '',
            'Low priority unless swarming'
        ],
        
        [
            'breeding_gnat',
            'Self-replacing fodder - creates endless problems',
            'Breeding Gnat',
            'Self-sustaining annoyance that reproduces',
            'self_replacing_fodder',
            'gnat',
            1, 0, 0, 0, 0,
            false, 0, 0, 0, 0,
            true, '', 'bottom', 2, // summon cap of 2
            'single', 0,
            '',
            'breed_basic:every_12_ticks_summon_basic_gnat',
            '',
            'Priority target to stop reproduction'
        ],
        
        // === SMALL GREMLINS (Tutorial & Fodder) ===
        [
            'dust_mite',
            'Rush threat - forces immediate action',
            'Dust Mite',
            'A tiny gremlin that causes friction in Heat mechanisms',
            'rush_threat',
            'small',
            8, 0, 0, 0, 0,
            false, 0, 0, 0, 0,
            true, '', 'bottom', 0,
            'single', 0,
            'heat_soft_cap:4', // Heat soft capped at 4
            '', '',
            'Teaches players about soft caps and spending under pressure'
        ],
        
        [
            'gear_tick',
            'Disruption threat - makes everything harder',
            'Gear Tick',
            'A small gremlin that makes your clockwork sluggish',
            'disruption_threat',
            'small',
            12, 0, 0, 0, 0,
            false, 0, 0, 0, 0,
            true, '', 'bottom', 0,
            'single', 0,
            'card_cost_penalty:1', // All cards cost +1 tick
            '', '',
            'Teaches timing pressure and efficiency'
        ],
        
        [
            'rust_speck',
            'Turtle threat - tests sustained damage',
            'Rust Speck',
            'Small but tough gremlin with high armor',
            'turtle_threat',
            'small',
            6, 3, 0, 0, 0, // 6 HP, 3 armor
            false, 0, 0, 0, 0,
            true, '', 'bottom', 0,
            'single', 0,
            'precision_soft_cap:3', // Precision soft capped at 3
            '', '',
            'High armor relative to HP teaches armor penetration'
        ],
        
        // === MEDIUM GREMLINS (Core Encounters) ===
        [
            'spring_snapper',
            'Scaling threat - gets worse over time',
            'Spring Snapper',
            'A gremlin that increasingly disrupts Momentum generation',
            'scaling_threat',
            'medium',
            35, 1, 0, 0, 0, // 35 HP, 1 armor
            false, 0, 0, 0, 0,
            true, '', 'bottom', 0,
            'cycle', 0, // cycling moves
            '',
            'drain_phase_1:every_8_ticks_drain_2_momentum|drain_phase_2:every_6_ticks_drain_3_momentum|drain_phase_3:every_4_ticks_drain_4_momentum',
            'drain_phase_1>drain_phase_2:after_1_trigger|drain_phase_2>drain_phase_3:after_1_trigger|drain_phase_3>drain_phase_1:after_1_trigger',
            'Demonstrates escalating pressure - eliminate before unsustainable'
        ],
        
        [
            'oil_thief',
            'Resource vampire - turtle + rush combination',
            'Oil Thief',
            'A slippery gremlin that steals accumulated forces',
            'turtle_rush_combo',
            'medium',
            28, 0, 5, 1, 8, // 28 HP, 5 shields, 1 regen up to 8 max
            false, 0, 0, 0, 0,
            true, '', 'bottom', 0,
            'cycle', 0,
            '',
            'cap_phase:all_forces_hard_cap_6_for_10_ticks|drain_phase:every_3_ticks_drain_3_largest_force',
            'cap_phase>drain_phase:after_10_ticks|drain_phase>cap_phase:after_3_triggers',
            'Hard caps force immediate spending, then drains punish accumulation'
        ],
        
        [
            'chaos_imp',
            'Multi-target synergy - enhances other gremlins',
            'Chaos Imp',
            'A chaotic gremlin that amplifies other disruptions',
            'synergy_threat',
            'medium',
            25, 2, 0, 0, 0, // 25 HP, 2 armor
            false, 0, 0, 0, 0,
            true, '', 'bottom', 0,
            'cycle', 0,
            'drain_amplifier:other_gremlins_drain_plus_1_each_type', // passive boost
            'shield_all:every_5_ticks_all_gremlins_gain_3_shields',
            'shield_all>drain_amplifier:after_1_trigger',
            'Force multiplier - high priority in multi-gremlin fights'
        ],
        
        [
            'gnat_spawner',
            'Summoning threat - board control',
            'Gnat Spawner',
            'A bloated gremlin that births swarms of gnats',
            'summoning_threat',
            'medium',
            30, 0, 0, 0, 0,
            false, 0, 0, 0, 0,
            true, '', 'bottom', 4, // max 4 summoned gremlins
            'cycle', 0,
            '',
            'spawn_wave_1:every_6_ticks_summon_dust_mite|spawn_wave_2:every_8_ticks_summon_2_dust_mites|spawn_wave_3:every_10_ticks_summon_3_dust_mites',
            'spawn_wave_1>spawn_wave_2:automatic|spawn_wave_2>spawn_wave_3:automatic|spawn_wave_3>spawn_wave_1:automatic',
            'Tests Attack (Most HP) vs Attack (Basic) targeting strategies'
        ],
        
        // === LARGE GREMLINS (Advanced Encounters) ===
        [
            'gear_grinder',
            'Armored berserker - turtle with escalating offense',
            'Gear Grinder',
            'A massive gremlin that grows stronger and tougher over time',
            'turtle_berserker',
            'large',
            75, 6, 0, 0, 0, // 75 HP, 6 armor
            false, 0, 0, 0, 0,
            true, '', 'bottom', 0,
            'cycle', 0,
            '',
            'balance_limit:balance_soft_cap_2_for_12_ticks|armor_gain:every_4_ticks_drain_5_largest_plus_gain_2_armor|berserker_mode:every_3_ticks_drain_6_largest_plus_cards_cost_plus_2',
            'balance_limit>armor_gain:after_12_ticks|armor_gain>berserker_mode:automatic|berserker_mode>balance_limit:cycle',
            'Becomes more dangerous over time - heavy armor encourages pierce'
        ],
        
        [
            'time_nibbler',
            'Complex controller - disruption + turtle combination',
            'Time Nibbler',
            'An ethereal gremlin that devours temporal stability',
            'disruption_turtle',
            'large',
            65, 2, 10, 2, 15, // 65 HP, 2 armor, 10 shields, 2 regen up to 15
            false, 0, 8, 0, 0, // damage cap of 8 per hit
            true, '', 'bottom', 0,
            'cycle', 0,
            '',
            'decay_phase:all_forces_decay_1_every_3_ticks_for_15_ticks|hand_lock:hand_size_6_no_draw_for_10_ticks|discard_force:every_2_ticks_force_discard_1_card_for_4_triggers',
            'decay_phase>hand_lock:after_15_ticks|hand_lock>discard_force:after_10_ticks|discard_force>decay_phase:after_4_triggers',
            'Multi-layered disruption with strong defenses and damage cap'
        ],
        
        [
            'echo_chamber',
            'Position controller - protected synergy threat',
            'Echo Chamber',
            'A resonant cavity that amplifies other gremlin presence',
            'protected_synergy',
            'large',
            55, 0, 0, 0, 0,
            false, 0, 0, 0, 0,
            false, 'while_other_gremlins_exist', 'top', 3, // cannot be targeted while others exist
            'single', 0,
            '',
            'echo_summon:every_4_ticks_summon_random_medium_gremlin',
            '',
            'Forces clearing minions repeatedly - tests targeting variety'
        ],
        
        // === ELITE GREMLINS (Skill Gates) ===
        [
            'constraint_engine',
            'Multi-system controller - master of constraints',
            'The Constraint Engine',
            'A complex mechanism that imposes multiple constraint types',
            'multi_constraint_master',
            'elite',
            95, 3, 8, 1, 12, // 95 HP, 3 armor, 8 shields, 1 regen up to 12
            false, 0, 0, 25, 0, // 25% reflect damage
            true, '', 'bottom', 0,
            'cycle', 0,
            '',
            'total_cap:total_resources_hard_cap_10_for_8_ticks|max_cap:max_resource_hard_cap_4_for_6_ticks|drain_all:every_3_ticks_drain_2_each_force_type_for_3_triggers|ultimate:all_previous_constraints_active_for_5_ticks',
            'total_cap>max_cap:after_8_ticks|max_cap>drain_all:after_6_ticks|drain_all>ultimate:after_3_triggers|ultimate>total_cap:after_5_ticks',
            'Tests mastery of constraint management and resource efficiency'
        ],
        
        [
            'temporal_glutton',
            'Escalating summoner - protected threat with escalation',
            'Temporal Glutton',
            'A ravenous entity that devours time and spawns increasingly dangerous threats',
            'escalating_summoner',
            'elite',
            110, 4, 15, 3, 20, // 110 HP, 4 armor, 15 shields, 3 regen up to 20
            false, 0, 0, 0, 0,
            true, '', 'bottom', 5, // max 5 summoned gremlins
            'cycle', 0,
            '',
            'summon_small:every_8_ticks_summon_1_small_gremlin|summon_medium:every_6_ticks_summon_1_medium_gremlin|summon_large:every_8_ticks_summon_1_large_gremlin_60_percent_stats|summon_frenzy:every_6_ticks_summon_2_medium_gremlins',
            'summon_small>summon_medium:automatic|summon_medium>summon_large:automatic|summon_large>summon_frenzy:automatic|summon_frenzy>summon_small:cycle',
            'Ramp-up encounter that becomes overwhelming if not addressed quickly'
        ],
        
        [
            'balanced_paradox',
            'Execution counter - anti-execution specialist',
            'The Balanced Paradox',
            'A perfectly balanced mechanism that resists execution attempts',
            'anti_execution',
            'elite',
            85, 8, 0, 0, 0,
            false, 0, 0, 0, 25, // cannot execute above 25 HP
            true, '', 'bottom', 0,
            'cycle', 0,
            '',
            'execution_resist:entropy_hard_cap_1_balance_hard_cap_1|counter_drain:every_4_ticks_drain_4_balance_plus_4_entropy|armor_scaling:gain_3_armor_all_forces_soft_cap_8',
            'execution_resist>counter_drain:automatic|counter_drain>armor_scaling:automatic|armor_scaling>execution_resist:cycle',
            'Hard counter to Balance/Black execution strategies'
        ],
        
        // === BOSS GREMLINS (Mastery Tests) ===
        [
            'rust_king_phase_1',
            'Phase transition boss - The Spreading Corruption',
            'The Rust King',
            'Phase 1: The Spreading Corruption - master of decay and reinforcement',
            'phase_transition_boss',
            'boss',
            150, 10, 0, 0, 0, // 150 HP, 10 armor
            false, 0, 0, 0, 0,
            true, '', 'bottom', 0,
            'cycle', 0,
            'force_decay:all_forces_decay_2_every_5_ticks', // passive decay
            'corruption_cap:total_resources_hard_cap_15_for_10_ticks|armor_all:every_3_ticks_all_gremlins_gain_2_armor_for_4_triggers',
            'corruption_cap>armor_all:after_10_ticks|armor_all>corruption_cap:after_4_triggers',
            'Phase 1: Resource management under pressure - transitions at 0 HP'
        ],
        
        [
            'rust_king_phase_2',
            'Phase 2 boss - The Desperate Stand',
            'The Rust King (Phase 2)',
            'Phase 2: The Desperate Stand - reduced armor but massive shields',
            'phase_2_boss',
            'boss',
            100, 5, 20, 4, 25, // 100 HP, 5 armor, 20 shields, 4 regen up to 25
            false, 0, 0, 0, 0,
            true, '', 'bottom', 0,
            'cycle', 0,
            'hand_limit:hand_size_reduced_to_7', // passive hand reduction
            'drain_extremes:every_2_ticks_drain_3_largest_plus_3_smallest|force_discard:every_4_ticks_force_discard_2_cards_for_3_triggers',
            'drain_extremes>force_discard:automatic|force_discard>drain_extremes:after_3_triggers',
            'Phase 2: Tests burst damage and hand management'
        ],
        
        [
            'chronophage',
            'Ultimate time controller - master of temporal manipulation',
            'Chronophage',
            'The ultimate manifestation of temporal disruption',
            'ultimate_time_master',
            'boss',
            180, 12, 30, 5, 40, // 180 HP, 12 armor, 30 shields, 5 regen up to 40
            false, 0, 12, 0, 0, // damage cap of 12 per hit
            true, '', 'bottom', 0,
            'dynamic_hp', 0, // moves change based on HP
            '',
            'hp_100:cards_cost_plus_3_forces_decay_3_every_2_ticks|hp_75:every_2_ticks_drain_4_each_force_type|hp_50:no_draw_hand_shuffle_every_6_ticks|hp_25:all_previous_plus_every_tick_discard_1|hp_low:constraints_removed_gain_5_armor',
            'hp_100>hp_75:at_75_percent_hp|hp_75>hp_50:at_50_percent_hp|hp_50>hp_25:at_25_percent_hp|hp_25>hp_low:at_10_percent_hp',
            'Escalating constraint puzzle - final phase rewards survival'
        ],
        
        [
            'grand_saboteur',
            'Adaptive counter-boss - AI that learns patterns',
            'The Grand Saboteur',
            'The ultimate adaptive threat that counters player strategies',
            'adaptive_counter_ai',
            'boss',
            200, 8, 0, 0, 0,
            false, 0, 0, 0, 0,
            true, '', 'bottom', 0,
            'adaptive', 0, // adapts based on player strategy
            '',
            'anti_red:if_red_damage_gain_reflection_plus_aoe_immunity|anti_execution:if_execution_attempt_become_immune_drain_balance_entropy|anti_summoner:if_other_gremlins_kill_random_other_gain_their_hp|anti_engine:if_8_plus_complications_every_2_ticks_destroy_random_complication|base_random:random_force_hard_cap_3_changes_every_6_ticks|base_copy:every_4_ticks_copy_most_recent_card_effect',
            'dynamic_adaptation:changes_based_on_player_patterns',
            'Ultimate skill test - punishes over-reliance on single strategies'
        ]
    ];
}

async function updateWithFullBestiary() {
    try {
        console.log('🔄 Starting full Gremlin Bestiary import...');
        
        // Setup authentication
        const auth = new google.auth.GoogleAuth({
            keyFile: SERVICE_KEY_PATH,
            scopes: ['https://www.googleapis.com/auth/spreadsheets'],
        });
        
        const sheets = google.sheets({ version: 'v4', auth: await auth.getClient() });
        
        // Get existing schema (first row)
        const existingData = await sheets.spreadsheets.values.get({
            spreadsheetId: SHEET_ID,
            range: `${SHEET_NAME}!1:1`
        });
        
        const schema = existingData.data.values[0];
        console.log('✅ Retrieved existing schema');
        
        // Prepare full bestiary data
        const bestiaryData = getFullBestiaryData();
        
        // Combine headers and data
        const allData = [schema, ...bestiaryData];
        
        console.log(`📊 Prepared ${bestiaryData.length} gremlins from full bestiary`);
        
        // Clear existing content
        console.log('🧹 Clearing existing data...');
        await sheets.spreadsheets.values.clear({
            spreadsheetId: SHEET_ID,
            range: `${SHEET_NAME}!A:Z`
        });
        
        // Upload new data
        console.log('📤 Uploading full bestiary...');
        await sheets.spreadsheets.values.update({
            spreadsheetId: SHEET_ID,
            range: `${SHEET_NAME}!A1`,
            valueInputOption: 'USER_ENTERED',
            requestBody: {
                values: allData
            }
        });
        
        console.log('✅ Full Bestiary imported successfully!');
        console.log(`📋 Total gremlins: ${bestiaryData.length}`);
        
        // Summary by category
        const categories = {};
        bestiaryData.forEach(row => {
            const sizeCategory = row[5]; // size_category column
            categories[sizeCategory] = (categories[sizeCategory] || 0) + 1;
        });
        
        console.log('\\n📖 Bestiary Breakdown:');
        Object.entries(categories).forEach(([category, count]) => {
            console.log(`   ${category}: ${count} gremlins`);
        });
        
        console.log(`\\n🔗 View at: https://docs.google.com/spreadsheets/d/${SHEET_ID}/edit#gid=479849152`);
        
        return true;
        
    } catch (error) {
        console.error('❌ Error importing bestiary:', error.message);
        throw error;
    }
}

// Run the import if called directly
if (require.main === module) {
    updateWithFullBestiary()
        .then(() => {
            console.log('\\n🎉 Full Gremlin Bestiary import completed!');
            process.exit(0);
        })
        .catch((error) => {
            console.error('\\n💥 Import failed:', error.message);
            process.exit(1);
        });
}

module.exports = { updateWithFullBestiary, getFullBestiaryData };