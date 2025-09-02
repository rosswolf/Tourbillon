#!/usr/bin/env node

/**
 * Script to fetch the latest gremlin data from Google Sheets and update the codebase
 * 
 * This script:
 * 1. Fetches data from the Google Sheets mob_data sheet
 * 2. Converts it to the new Tourbillon gremlin schema format
 * 3. Updates the mob_data.json file in the elastic-app
 */

const { google } = require('googleapis');
const fs = require('fs');
const path = require('path');

// Configuration
const SHEET_ID = '1TlOn39AXlw0y2tlkE4kvIpvoZ9SpNQTkDGgOptvqSgM';
const SHEET_NAME = 'mob_data';
const SERVICE_KEY_PATH = path.join(__dirname, '..', 'google-sheets-mcp', 'service-account-key.json');
const OUTPUT_PATH = path.join(__dirname, 'elastic-app', 'app', 'src', 'scenes', 'data', 'mob_data.json');

/**
 * Convert old goblin format to new gremlin format
 */
function convertToGremlinFormat(oldData) {
    // For now, create basic conversions of the existing data
    // In the future, this should be replaced with proper gremlin definitions
    
    const converted = oldData.map(mob => {
        // Basic conversion - this is temporary until proper gremlin data is added
        return {
            template_id: mob.template_id || mob.mob_template_id,
            display_name: mob.display_name,
            description: `A clockwork parasite that disrupts your mechanism`,
            archetype: "disruption_threat", // Default archetype
            size_category: mob.max_health > 50 ? "medium" : "small",
            
            // Core Stats
            max_health: parseInt(mob.max_health) || 10,
            max_armor: parseInt(mob.max_armor) || 0,
            max_shields: 0,
            shield_regen: 0,
            shield_regen_max: 0,
            
            // Special Defenses
            has_barrier: false,
            barrier_count: 0,
            damage_cap: 0,
            reflect_percent: 0,
            execute_immunity_threshold: 0,
            
            // Targeting
            can_be_targeted: true,
            target_protection_condition: "",
            summon_position: "bottom",
            summon_cap: 0,
            
            // Simple move cycle - convert first range behavior to a basic disruption
            move_timing_type: "single",
            move_starting_index: 0,
            move_cycle: [{
                move_id: "basic_disruption",
                move_name: "Basic Disruption", 
                duration_ticks: 0,
                trigger_interval: 0,
                max_triggers: 0,
                next_move: "",
                transition_condition: "",
                transition_value: 0,
                passive_effects: [{
                    effect_type: "force_soft_cap",
                    targets: "player",
                    value: 5,
                    force_types: ["heat"],
                    condition: "",
                    description: "Heat soft capped at 5"
                }],
                trigger_effects: [],
                on_enter_effects: [],
                on_exit_effects: []
            }],
            
            // Legacy data for reference during transition
            _legacy_data: {
                movement: mob.movement,
                sweet_spot: mob.sweet_spot,
                is_flying: mob.is_flying,
                range_behaviors: {
                    in_range_1: mob.in_range_1,
                    in_range_2: mob.in_range_2, 
                    in_range_3: mob.in_range_3,
                    in_range_4: mob.in_range_4,
                    out_of_range_1: mob.out_of_range_1,
                    out_of_range_2: mob.out_of_range_2,
                    out_of_range_3: mob.out_of_range_3
                }
            }
        };
    });
    
    return converted;
}

/**
 * Add proper Tourbillon gremlins based on the design documents
 */
function addProperGremlins() {
    return [
        // Basic Gnat
        {
            template_id: "basic_gnat",
            display_name: "Basic Gnat", 
            description: "Pure fodder - clogs targeting, minimal threat",
            archetype: "fodder",
            size_category: "gnat",
            
            max_health: 1,
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
            target_protection_condition: "",
            summon_position: "bottom",
            summon_cap: 0,
            
            move_timing_type: "single",
            move_starting_index: 0,
            move_cycle: [{
                move_id: "pure_blocker",
                move_name: "Pure Blocker",
                duration_ticks: 0,
                trigger_interval: 0,
                max_triggers: 0,
                passive_effects: [],
                trigger_effects: [],
                on_enter_effects: [],
                on_exit_effects: []
            }]
        },
        
        // Dust Mite
        {
            template_id: "dust_mite",
            display_name: "Dust Mite",
            description: "A tiny gremlin that causes friction in Heat mechanisms",
            archetype: "rush_threat",
            size_category: "small",
            
            max_health: 8,
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
            target_protection_condition: "",
            summon_position: "bottom",
            summon_cap: 0,
            
            move_timing_type: "single", 
            move_starting_index: 0,
            move_cycle: [{
                move_id: "heat_disruption",
                move_name: "Heat Disruption",
                duration_ticks: 0,
                trigger_interval: 0,
                max_triggers: 0,
                passive_effects: [{
                    effect_type: "force_soft_cap",
                    targets: "player",
                    value: 4,
                    force_types: ["heat"],
                    condition: "",
                    description: "Heat soft capped at 4"
                }],
                trigger_effects: [],
                on_enter_effects: [],
                on_exit_effects: []
            }]
        },
        
        // Barrier Gnat
        {
            template_id: "barrier_gnat",
            display_name: "Barrier Gnat",
            description: "Protected fodder - tests multi-hit strategies",
            archetype: "protected_fodder",
            size_category: "gnat",
            
            max_health: 1,
            max_armor: 0,
            max_shields: 0,
            shield_regen: 0,
            shield_regen_max: 0,
            
            has_barrier: true,
            barrier_count: 1,
            damage_cap: 0,
            reflect_percent: 0,
            execute_immunity_threshold: 0,
            
            can_be_targeted: true,
            target_protection_condition: "",
            summon_position: "bottom",
            summon_cap: 0,
            
            move_timing_type: "single",
            move_starting_index: 0,
            move_cycle: [{
                move_id: "barrier_block",
                move_name: "Barrier Block", 
                duration_ticks: 0,
                trigger_interval: 0,
                max_triggers: 0,
                passive_effects: [],
                trigger_effects: [],
                on_enter_effects: [],
                on_exit_effects: []
            }]
        },
        
        // Spring Snapper
        {
            template_id: "spring_snapper",
            display_name: "Spring Snapper",
            description: "A gremlin that increasingly disrupts Momentum generation",
            archetype: "scaling_threat",
            size_category: "medium",
            
            max_health: 35,
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
            target_protection_condition: "",
            summon_position: "bottom",
            summon_cap: 0,
            
            move_timing_type: "cycle",
            move_starting_index: 0,
            move_cycle: [
                {
                    move_id: "drain_phase_1",
                    move_name: "Initial Drain",
                    duration_ticks: 0,
                    trigger_interval: 8,
                    max_triggers: 1,
                    next_move: "drain_phase_2",
                    trigger_effects: [{
                        effect_type: "force_drain",
                        targets: "player",
                        value: 2,
                        force_types: ["momentum"],
                        description: "Drain 2 Momentum"
                    }],
                    passive_effects: [],
                    on_enter_effects: [],
                    on_exit_effects: []
                },
                {
                    move_id: "drain_phase_2",
                    move_name: "Moderate Drain", 
                    duration_ticks: 0,
                    trigger_interval: 6,
                    max_triggers: 1,
                    next_move: "drain_phase_3",
                    trigger_effects: [{
                        effect_type: "force_drain",
                        targets: "player",
                        value: 3,
                        force_types: ["momentum"],
                        description: "Drain 3 Momentum"
                    }],
                    passive_effects: [],
                    on_enter_effects: [],
                    on_exit_effects: []
                },
                {
                    move_id: "drain_phase_3",
                    move_name: "Heavy Drain",
                    duration_ticks: 0,
                    trigger_interval: 4,
                    max_triggers: 1,
                    next_move: "drain_phase_1",
                    trigger_effects: [{
                        effect_type: "force_drain",
                        targets: "player", 
                        value: 4,
                        force_types: ["momentum"],
                        description: "Drain 4 Momentum"
                    }],
                    passive_effects: [],
                    on_enter_effects: [],
                    on_exit_effects: []
                }
            ]
        }
    ];
}

async function fetchGoogleSheetsData() {
    try {
        console.log('Setting up Google Sheets authentication...');
        
        const auth = new google.auth.GoogleAuth({
            keyFile: SERVICE_KEY_PATH,
            scopes: ['https://www.googleapis.com/auth/spreadsheets.readonly'],
        });
        
        const sheets = google.sheets({ version: 'v4', auth: await auth.getClient() });
        
        console.log('Fetching data from Google Sheets...');
        const range = `${SHEET_NAME}!A:Z`;
        const response = await sheets.spreadsheets.values.get({
            spreadsheetId: SHEET_ID,
            range: range
        });
        
        const rows = response.data.values;
        if (!rows || rows.length < 2) {
            console.log('No data found in sheet or only headers present');
            return [];
        }
        
        // Convert rows to objects
        const headers = rows[0];
        const data = [];
        
        for (let i = 1; i < rows.length; i++) {
            const row = rows[i];
            const obj = {};
            
            headers.forEach((header, index) => {
                obj[header] = row[index] || '';
            });
            
            data.push(obj);
        }
        
        console.log(`Found ${data.length} mob entries in Google Sheets`);
        return data;
        
    } catch (error) {
        console.error('Error fetching Google Sheets data:', error.message);
        throw error;
    }
}

async function updateMobDataFile() {
    try {
        console.log('Starting gremlin data update...');
        
        // Fetch current data from Google Sheets
        const sheetsData = await fetchGoogleSheetsData();
        
        // Convert legacy format to new schema
        const convertedLegacy = convertToGremlinFormat(sheetsData);
        
        // Add proper Tourbillon gremlins
        const properGremlins = addProperGremlins();
        
        // Combine all data
        const allGremlins = [
            ...properGremlins,
            ...convertedLegacy
        ];
        
        // Add metadata
        const finalData = {
            version: "1.0.0",
            schema_version: "tourbillon_gremlin_v1",
            last_updated: new Date().toISOString(),
            description: "Gremlin data for Tourbillon - clockwork parasites that disrupt the player's mechanism",
            total_gremlins: allGremlins.length,
            gremlins: allGremlins
        };
        
        // Ensure output directory exists
        const outputDir = path.dirname(OUTPUT_PATH);
        if (!fs.existsSync(outputDir)) {
            fs.mkdirSync(outputDir, { recursive: true });
        }
        
        // Write the updated file
        console.log(`Writing ${allGremlins.length} gremlins to ${OUTPUT_PATH}...`);
        fs.writeFileSync(OUTPUT_PATH, JSON.stringify(finalData, null, 2));
        
        console.log('✅ Gremlin data update completed successfully!');
        console.log(`📊 Added ${properGremlins.length} proper Tourbillon gremlins`);
        console.log(`🔄 Converted ${convertedLegacy.length} legacy entries`); 
        console.log(`📁 Output written to: ${OUTPUT_PATH}`);
        
    } catch (error) {
        console.error('❌ Error updating gremlin data:', error.message);
        process.exit(1);
    }
}

// Run the update
if (require.main === module) {
    updateMobDataFile();
}

module.exports = { updateMobDataFile, fetchGoogleSheetsData, convertToGremlinFormat, addProperGremlins };