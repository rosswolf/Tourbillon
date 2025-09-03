#!/usr/bin/env node

const { google } = require('googleapis');
const fs = require('fs');
const path = require('path');

// Wave data to populate
const waveData = [
  ["wave_id", "display_name", "act", "difficulty", "difficulty_tier", "archetype", "strategy_hint", "gremlins", "is_boss"],
  ["wave_1a", "First Contact", "1", "13", "Trivial", "Rush Threat - Single Constraint", "Teaches soft caps and resource spending pressure", "dust_mite", ""],
  ["wave_1b", "Mechanical Disruption", "1", "17", "Easy", "Disruption Threat - Timing Penalty", "Teaches timing efficiency and card sequencing", "gear_tick", ""],
  ["wave_1c", "Armored Introduction", "1", "17", "Easy", "Turtle Threat - Armor Tutorial", "Teaches armor mechanics and sustained damage", "rust_speck", ""],
  ["wave_1d", "Swarm Basics", "1", "3", "Trivial", "Pure Swarm - AOE Tutorial", "Teaches AOE vs single-target efficiency", "basic_gnat|basic_gnat|basic_gnat", ""],
  ["wave_1e", "Protected Pest", "1", "14", "Trivial", "Protected Constraint - Multi-Hit Tutorial", "Teaches multi-hit strategies vs barriers", "constricting_barrier_gnat", ""],
  ["wave_1f", "Escalating Pressure", "1", "42", "Medium", "Scaling Threat - Time Pressure", "Teaches elimination priority and timing", "spring_snapper", ""],
  ["wave_2a", "Turtle and Rush", "2", "69", "Hard", "Turtle + Rush Combination", "Tests priority targeting - rush vs turtle elimination", "oil_thief|dust_mite|dust_mite", ""],
  ["wave_2b", "Synergistic Chaos", "2", "86", "Hard", "Synergy + Scaling Threat", "Tests understanding of force multiplication", "chaos_imp|spring_snapper", ""],
  ["wave_2c", "The Gnat Problem", "2", "57", "Medium", "Summoning + Protection", "Tests Green (Attack Most HP) vs multi-hit strategies", "gnat_spawner|barrier_gnat|barrier_gnat|barrier_gnat", ""],
  ["wave_2d", "Resource Stranglehold", "2", "42", "Medium", "Multi-Constraint Swarm", "Tests multi-hit efficiency vs protected constraints", "constricting_barrier_gnat|draining_barrier_gnat|toxic_barrier_gnat", ""],
  ["wave_2e", "Armored Assault", "2", "121", "Nightmare", "Heavy Turtle + Support", "Tests pierce strategies and sustained damage", "gear_grinder|rust_speck|rust_speck", ""],
  ["wave_2f", "The Spawning Nightmare", "2", "171", "Nightmare", "Elite Summoner + Protected Support", "Ultimate summoning challenge with protection", "temporal_glutton|breeding_barrier_gnat", ""],
  ["wave_3a", "The Constraint Engine", "3", "170", "Nightmare", "Multi-System Controller + Protection", "Tests mastery of all constraint types", "the_constraint_engine|constricting_barrier_gnat|constricting_barrier_gnat", ""],
  ["wave_3b", "Echoing Madness", "3", "172", "Nightmare", "Protected Summoner + Synergy + Turtle", "Complex priority puzzle with protection mechanics", "echo_chamber|chaos_imp|oil_thief", ""],
  ["boss_1", "The Rust King's Domain", "3", "399", "Nightmare+", "Phase Transition + Scaling Support", "Ultimate resource management + adaptation test", "rust_king_phase_1|spring_snapper|spring_snapper", "TRUE"],
  ["boss_2", "Temporal Collapse", "3", "414", "Nightmare+", "Ultimate Time Control + Support", "Tests all timing and constraint management skills", "chronophage|time_nibbler", "TRUE"]
];

async function updateWaveSheet() {
  try {
    // Load the service account key
    const keyFilePath = path.join(process.env.HOME, 'Code', 'google-sheets-mcp', 'service-account-key.json');
    
    if (!fs.existsSync(keyFilePath)) {
      console.error(`Service account key not found at: ${keyFilePath}`);
      return;
    }
    
    const auth = new google.auth.GoogleAuth({
      keyFile: keyFilePath,
      scopes: ['https://www.googleapis.com/auth/spreadsheets']
    });

    const sheets = google.sheets({ version: 'v4', auth });
    
    // The spreadsheet ID for wave data
    const spreadsheetId = '1Bv6R-AZtzmG_ycwudZ5Om6dKrJgl6Ut9INw7GTJFUlw';
    const range = 'A1:I17'; // Covers all our data including headers
    
    // Clear existing content first
    console.log('Clearing existing sheet content...');
    await sheets.spreadsheets.values.clear({
      spreadsheetId,
      range: 'A:Z', // Clear everything
    });
    
    // Update with new wave data
    console.log('Updating sheet with wave data...');
    const response = await sheets.spreadsheets.values.update({
      spreadsheetId,
      range,
      valueInputOption: 'RAW',
      resource: {
        values: waveData
      }
    });
    
    console.log(`✅ Successfully updated ${response.data.updatedCells} cells`);
    console.log(`📊 Sheet URL: https://docs.google.com/spreadsheets/d/${spreadsheetId}/edit`);
    
  } catch (error) {
    console.error('Error updating sheet:', error.message);
    if (error.code === 403) {
      console.error('Permission denied. Make sure the service account has edit access to the spreadsheet.');
    }
  }
}

// Run the update
updateWaveSheet();