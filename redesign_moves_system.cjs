#!/usr/bin/env node

/**
 * Redesign gremlin system to use concrete moves list
 * Format: moves as "ticks=4,startup|ticks=2,cap_red=3|ticks=3,drain_red=3"
 */

const { google } = require('googleapis');
const path = require('path');

// Configuration
const SHEET_ID = '1TlOn39AXlw0y2tlkE4kvIpvoZ9SpNQTkDGgOptvqSgM';
const SHEET_NAME = 'mob_data';
const SERVICE_KEY_PATH = path.join(__dirname, '..', 'google-sheets-mcp', 'service-account-key.json');

/**
 * New schema with concrete moves list
 */
function getNewGremlinSchema() {
    return [
        // Core identification
        'template_id',
        '__NOEX schema_notes',
        'display_name',
        'description',
        'archetype',
        'size_category',
        
        // Core Stats  
        'max_health',
        'max_armor',
        'max_shields',
        'shield_regen',
        'shield_regen_max',
        
        // Special Defenses
        'has_barrier',
        'barrier_count',
        'damage_cap',
        'reflect_percent',
        'execute_immunity_threshold',
        
        // Targeting
        'can_be_targeted',
        'target_protection_condition',
        'summon_position',
        'summon_cap',
        
        // Moves System - concrete list format
        'moves', // "ticks=X,effect=Y|ticks=A,effect=B" format
        'move_pattern', // "sequence", "cycle", "random", "hp_based"
        
        '__NOEX developer_notes'
    ];
}

/**
 * Redesigned gremlin data with concrete moves
 */
function getConcreteGremlinData() {
    return [
        // === GNATS ===
        [
            'basic_gnat',
            'Pure fodder - no moves, just HP',
            'Basic Gnat',
            'Pure fodder - clogs targeting, minimal threat',
            'fodder',
            'gnat',
            1, 0, 0, 0, 0,
            false, 0, 0, 0, 0,
            true, '', 'bottom', 0,
            '', // No moves - pure blocker
            'none',
            'Forces AOE damage to be efficient'
        ],
        
        [
            'barrier_gnat',
            'Protected fodder with barrier',
            'Barrier Gnat',
            'Barrier-protected fodder that requires 2 hits',
            'protected_fodder',
            'gnat',
            1, 0, 0, 0, 0,
            true, 1, 0, 0, 0, // 1 barrier
            true, '', 'bottom', 0,
            '', // No active moves - barrier is the mechanic
            'none',
            'Requires exactly 2 hits regardless of damage amounts'
        ],
        
        [
            'dust_mite',
            'Rush threat with Heat soft cap',
            'Dust Mite',
            'Tutorial enemy that teaches soft caps and spending pressure',
            'rush_threat',
            'small',
            8, 0, 0, 0, 0,
            false, 0, 0, 0, 0,
            true, '', 'bottom', 0,
            'ticks=0,heat_soft_cap=4', // Immediate passive effect
            'passive',
            'Forces immediate Heat spending'
        ],
        
        [
            'drain_gnat',
            'Periodic weak drain',
            'Drain Gnat',
            'Minimal disruption that becomes annoying in groups',
            'annoying_fodder',
            'gnat',
            1, 0, 0, 0, 0,
            false, 0, 0, 0, 0,
            true, '', 'bottom', 0,
            'ticks=8,drain_random=1', // Every 8 ticks drain 1 random
            'cycle',
            'Low priority unless swarming'
        ],
        
        [
            'constricting_barrier_gnat',
            'Barrier + resource cap combo',
            'Constricting Barrier Gnat',
            'Barrier-protected resource constraint',
            'protected_constraint',
            'gnat',
            1, 0, 0, 0, 0,
            true, 1, 0, 0, 0,
            true, '', 'bottom', 0,
            'ticks=0,max_resource_soft_cap=5', // Immediate passive
            'passive',
            'High priority for multi-hit removal'
        ],
        
        [
            'breeding_gnat',
            'Self-replacing swarm source',
            'Breeding Gnat', 
            'Self-sustaining annoyance that reproduces',
            'self_replacing_fodder',
            'gnat',
            1, 0, 0, 0, 0,
            false, 0, 0, 0, 0,
            true, '', 'bottom', 2, // summon cap 2
            'ticks=12,summon=basic_gnat', // Every 12 ticks summon
            'cycle',
            'Priority target to stop reproduction'
        ],
        
        // === SMALL GREMLINS ===
        [
            'gear_tick',
            'Timing disruption threat',
            'Gear Tick',
            'Makes your clockwork sluggish with timing penalties',
            'disruption_threat',
            'small',
            12, 0, 0, 0, 0,
            false, 0, 0, 0, 0,
            true, '', 'bottom', 0,
            'ticks=0,card_cost_penalty=1', // Immediate passive
            'passive',
            'Teaches timing pressure and efficiency'
        ],
        
        [
            'rust_speck',
            'Armored turtle threat',
            'Rust Speck',
            'Small but tough gremlin with high armor',
            'turtle_threat',
            'small',
            6, 3, 0, 0, 0, // 6 HP, 3 armor
            false, 0, 0, 0, 0,
            true, '', 'bottom', 0,
            'ticks=0,precision_soft_cap=3', // Immediate passive
            'passive',
            'High armor relative to HP teaches armor penetration'
        ],
        
        // === MEDIUM GREMLINS ===
        [
            'spring_snapper',
            'Escalating Momentum drainer',
            'Spring Snapper',
            'Increasingly disrupts Momentum with escalating drains',
            'scaling_threat',
            'medium',
            35, 1, 0, 0, 0,
            false, 0, 0, 0, 0,
            true, '', 'bottom', 0,
            'ticks=8,drain_momentum=2|ticks=6,drain_momentum=3|ticks=4,drain_momentum=4', // Escalating sequence
            'sequence',
            'Must eliminate before drains become unsustainable'
        ],
        
        [
            'oil_thief',
            'Dual-phase resource vampire',
            'Oil Thief',
            'Alternates between hard caps and draining largest forces',
            'turtle_rush_combo',
            'medium',
            28, 0, 5, 1, 8, // shields with regen
            false, 0, 0, 0, 0,
            true, '', 'bottom', 0,
            'ticks=10,all_forces_hard_cap=6|ticks=3,drain_largest=3|ticks=3,drain_largest=3|ticks=3,drain_largest=3', // Cap phase then 3 drain cycles
            'sequence',
            'Hard caps force spending, then drains punish accumulation'
        ],
        
        [
            'chaos_imp',
            'Synergy amplifier',
            'Chaos Imp',
            'Amplifies other gremlin disruptions and grants shields',
            'synergy_threat',
            'medium',
            25, 2, 0, 0, 0,
            false, 0, 0, 0, 0,
            true, '', 'bottom', 0,
            'ticks=0,amplify_drains=1|ticks=5,all_gremlins_gain_shields=3', // Passive amplify + periodic shields
            'cycle',
            'High priority in multi-gremlin encounters'
        ],
        
        [
            'gnat_spawner',
            'Escalating summoner',
            'Gnat Spawner',
            'Spawns increasing waves of Dust Mites',
            'summoning_threat',
            'medium',
            30, 0, 0, 0, 0,
            false, 0, 0, 0, 0,
            true, '', 'bottom', 4, // max 4 summons
            'ticks=6,summon=dust_mite|ticks=8,summon=dust_mite,summon=dust_mite|ticks=10,summon=dust_mite,summon=dust_mite,summon=dust_mite', // 1, 2, 3 sequence
            'cycle',
            'Tests targeting priorities and AOE strategies'
        ],
        
        // === LARGE GREMLINS ===
        [
            'gear_grinder',
            'Berserker that gains armor',
            'Gear Grinder',
            'Massive gremlin that becomes stronger and tougher over time',
            'turtle_berserker',
            'large',
            75, 6, 0, 0, 0,
            false, 0, 0, 0, 0,
            true, '', 'bottom', 0,
            'ticks=12,balance_soft_cap=2|ticks=4,drain_largest=5,self_gain_armor=2|ticks=3,drain_largest=6,card_cost_penalty=2', // 3 escalating phases
            'sequence',
            'Heavy armor encourages pierce damage strategies'
        ],
        
        [
            'time_nibbler',
            'Multi-layered controller',
            'Time Nibbler',
            'Ethereal gremlin with layered temporal disruptions',
            'disruption_turtle',
            'large',
            65, 2, 10, 2, 15, // armor + shields with regen
            false, 0, 8, 0, 0, // damage cap 8
            true, '', 'bottom', 0,
            'ticks=15,all_forces_decay=1|ticks=10,hand_size_limit=6,no_card_draw|ticks=2,force_discard=1|ticks=2,force_discard=1|ticks=2,force_discard=1|ticks=2,force_discard=1', // Decay->Hand lock->4 discards
            'sequence',
            'Damage cap prevents burst strategies, tests adaptation'
        ],
        
        [
            'echo_chamber',
            'Protected summoner',
            'Echo Chamber',
            'Cannot be targeted while other gremlins exist',
            'protected_synergy',
            'large',
            55, 0, 0, 0, 0,
            false, 0, 0, 0, 0,
            false, 'while_other_gremlins_exist', 'top', 3, // untargetable, summons at top
            'ticks=4,summon=random_medium', // Every 4 ticks
            'cycle',
            'Forces clearing minions to expose the real threat'
        ],
        
        // === ELITE GREMLINS ===
        [
            'constraint_engine',
            'Master of all constraint types',
            'The Constraint Engine',
            'Complex mechanism imposing multiple constraint types',
            'multi_constraint_master',
            'elite',
            95, 3, 8, 1, 12,
            false, 0, 0, 25, 0, // 25% reflect
            true, '', 'bottom', 0,
            'ticks=8,total_resources_hard_cap=10|ticks=6,max_resource_hard_cap=4|ticks=3,drain_all_types=2|ticks=3,drain_all_types=2|ticks=3,drain_all_types=2|ticks=5,all_previous_constraints', // Complex sequence
            'sequence',
            'Tests mastery of constraint management and efficiency'
        ],
        
        [
            'temporal_glutton',
            'Escalating threat summoner',
            'Temporal Glutton',
            'Spawns increasingly dangerous threats over time',
            'escalating_summoner',
            'elite',
            110, 4, 15, 3, 20,
            false, 0, 0, 0, 0,
            true, '', 'bottom', 5, // max 5 summons
            'ticks=8,summon=random_small|ticks=6,summon=random_medium|ticks=8,summon=scaled_large|ticks=6,summon=random_medium,summon=random_medium', // Escalating sequence
            'cycle',
            'Becomes overwhelming if not addressed quickly'
        ],
        
        [
            'balanced_paradox',
            'Anti-execution specialist',
            'The Balanced Paradox',
            'Perfectly balanced mechanism that resists execution',
            'anti_execution',
            'elite',
            85, 8, 0, 0, 0,
            false, 0, 0, 0, 25, // execute immunity above 25 HP
            true, '', 'bottom', 0,
            'ticks=0,entropy_hard_cap=1,balance_hard_cap=1|ticks=4,drain_balance=4,drain_entropy=4|ticks=0,self_gain_armor=3,all_forces_soft_cap=8', // Anti-execution sequence
            'cycle',
            'Hard counter to Balance/Entropy execution strategies'
        ],
        
        // === BOSS GREMLINS ===
        [
            'rust_king_phase_1',
            'Phase 1: The Spreading Corruption',
            'The Rust King',
            'Master of decay and reinforcement - Phase 1',
            'phase_transition_boss',
            'boss',
            150, 10, 0, 0, 0,
            false, 0, 0, 0, 0,
            true, '', 'bottom', 0,
            'ticks=0,all_forces_decay=2|ticks=10,total_resources_hard_cap=15|ticks=3,all_gremlins_gain_armor=2|ticks=3,all_gremlins_gain_armor=2|ticks=3,all_gremlins_gain_armor=2|ticks=3,all_gremlins_gain_armor=2', // Passive decay + cap + 4 armor boosts
            'cycle',
            'Phase 1: Resource management under pressure'
        ],
        
        [
            'chronophage',
            'Ultimate temporal controller',
            'Chronophage',
            'Ultimate manifestation of temporal disruption with HP-based moves',
            'ultimate_time_master',
            'boss',
            180, 12, 30, 5, 40,
            false, 0, 12, 0, 0, // damage cap 12
            true, '', 'bottom', 0,
            'ticks=2,card_cost_penalty=3,all_forces_decay=3|ticks=2,drain_all_types=4|ticks=6,no_draw,shuffle_hand|ticks=1,force_discard=1|ticks=0,remove_constraints,self_gain_armor=5', // HP-based progression
            'hp_based', // Special pattern type
            'Escalating constraint puzzle with final survival reward'
        ],
        
        [
            'grand_saboteur',
            'Adaptive AI that counters strategies',
            'The Grand Saboteur',
            'Ultimate adaptive threat that learns player patterns',
            'adaptive_counter_ai',
            'boss',
            200, 8, 0, 0, 0,
            false, 0, 0, 0, 0,
            true, '', 'bottom', 0,
            'ticks=6,random_force_hard_cap=3|ticks=4,copy_recent_card_effect', // Base pattern, adapts based on player
            'adaptive', // Special AI pattern
            'Punishes over-reliance on single strategies'
        ]
    ];
}

async function updateWithConcreteMoves() {
    try {
        console.log('🔄 Updating gremlins with concrete moves system...');
        
        // Setup authentication
        const auth = new google.auth.GoogleAuth({
            keyFile: SERVICE_KEY_PATH,
            scopes: ['https://www.googleapis.com/auth/spreadsheets'],
        });
        
        const sheets = google.sheets({ version: 'v4', auth: await auth.getClient() });
        
        // Prepare data
        const schema = getNewGremlinSchema();
        const gremlinData = getConcreteGremlinData();
        const allData = [schema, ...gremlinData];
        
        console.log(`📊 Prepared ${gremlinData.length} gremlins with concrete moves`);
        console.log(`📋 New schema: ${schema.length} columns`);
        
        // Clear and upload
        await sheets.spreadsheets.values.clear({
            spreadsheetId: SHEET_ID,
            range: `${SHEET_NAME}!A:Z`
        });
        
        await sheets.spreadsheets.values.update({
            spreadsheetId: SHEET_ID,
            range: `${SHEET_NAME}!A1`,
            valueInputOption: 'USER_ENTERED',
            requestBody: { values: allData }
        });
        
        console.log('✅ Updated with concrete moves system!');
        
        // Show example moves
        console.log('\\n📝 Example move formats:');
        console.log('   Simple: "ticks=8,drain_random=1"');
        console.log('   Sequence: "ticks=8,drain_momentum=2|ticks=6,drain_momentum=3|ticks=4,drain_momentum=4"');
        console.log('   Multi-effect: "ticks=0,entropy_hard_cap=1,balance_hard_cap=1"');
        console.log('   Summoning: "ticks=6,summon=dust_mite"');
        
        console.log(`\\n🔗 View at: https://docs.google.com/spreadsheets/d/${SHEET_ID}/edit#gid=479849152`);
        
        return true;
        
    } catch (error) {
        console.error('❌ Error updating moves system:', error.message);
        throw error;
    }
}

// Run the update
if (require.main === module) {
    updateWithConcreteMoves()
        .then(() => {
            console.log('\\n🎉 Concrete moves system update completed!');
            process.exit(0);
        })
        .catch((error) => {
            console.error('\\n💥 Update failed:', error.message);
            process.exit(1);
        });
}

module.exports = { updateWithConcreteMoves, getNewGremlinSchema, getConcreteGremlinData };