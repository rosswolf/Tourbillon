#!/usr/bin/env node

const { google } = require('googleapis');
const fs = require('fs');
const path = require('path');

// Google Sheets configuration - This is the mob data spreadsheet
const SPREADSHEET_ID = '1TlOn39AXlw0y2tlkE4kvIpvoZ9SpNQTkDGgOptvqSgM';
const MOB_SHEET_NAME = 'mob_data';
const SERVICE_ACCOUNT_KEY = path.join(process.env.HOME, 'Code/google-sheets-mcp/service-account-key.json');

async function authenticateSheets() {
    const auth = new google.auth.GoogleAuth({
        keyFile: SERVICE_ACCOUNT_KEY,
        scopes: ['https://www.googleapis.com/auth/spreadsheets'],
    });
    
    const client = await auth.getClient();
    const sheets = google.sheets({ version: 'v4', auth: client });
    
    return sheets;
}

async function createMobSheet(sheets) {
    try {
        // Add a new sheet
        const addSheetResponse = await sheets.spreadsheets.batchUpdate({
            spreadsheetId: SPREADSHEET_ID,
            requestBody: {
                requests: [{
                    addSheet: {
                        properties: {
                            title: MOB_SHEET_NAME,
                            index: 1,
                            gridProperties: {
                                rowCount: 100,
                                columnCount: 50
                            }
                        }
                    }
                }]
            }
        });
        
        console.log(`✅ Created sheet '${MOB_SHEET_NAME}'`);
        return addSheetResponse.data.replies[0].addSheet.properties.sheetId;
        
    } catch (error) {
        if (error.message.includes('already exists')) {
            console.log(`Sheet '${MOB_SHEET_NAME}' already exists`);
            // Get the sheet ID
            const sheetInfo = await sheets.spreadsheets.get({
                spreadsheetId: SPREADSHEET_ID,
            });
            const mobSheet = sheetInfo.data.sheets.find(s => s.properties.title === MOB_SHEET_NAME);
            return mobSheet ? mobSheet.properties.sheetId : null;
        }
        throw error;
    }
}

async function populateMobSheet(sheets) {
    // Load the mob data
    const mobData = JSON.parse(fs.readFileSync('mob_data.json', 'utf8'));
    console.log(`Loading ${mobData.length} mob entries...`);
    
    // Define headers based on the first mob entry + our new move columns
    const standardHeaders = [
        'template_id',
        'display_name',
        'description',
        'archetype',
        'size_category',
        'max_health',
        'max_armor',
        'max_shields',
        'shield_regen',
        'shield_regen_max',
        'has_barrier',
        'barrier_count',
        'damage_cap',
        'reflect_percent',
        'execute_immunity_threshold',
        'can_be_targeted',
        'summon_position',
        'summon_cap',
        'move_pattern'
    ];
    
    // Add the new move columns
    const moveHeaders = [];
    for (let i = 1; i <= 6; i++) {
        moveHeaders.push(`move_${i}`, `move_${i}_ticks`);
    }
    
    const headers = [...standardHeaders, ...moveHeaders];
    
    // Add any NOEX columns
    headers.push('NOEX developer_notes', 'NOEX schema_notes');
    
    // Prepare the data rows
    const dataRows = [headers]; // Start with header row
    
    // Process each mob
    for (const mob of mobData) {
        const row = [];
        
        // Skip any fields we don't want to export
        const skipFields = ['__old_moves', 'moves_dict'];
        
        // Add standard fields
        for (const header of standardHeaders) {
            if (skipFields.includes(header)) {
                row.push('');
                continue;
            }
            
            let value = mob[header];
            if (value === undefined) {
                value = '';
            } else if (typeof value === 'boolean') {
                value = value ? 'TRUE' : 'FALSE';
            } else if (Array.isArray(value)) {
                value = value.join('|'); // Use pipe separator for arrays
            } else if (value !== null && typeof value === 'object') {
                value = JSON.stringify(value);
            } else {
                value = String(value);
            }
            row.push(value);
        }
        
        // Add move fields
        for (let i = 1; i <= 6; i++) {
            row.push(mob[`move_${i}`] || '');
            row.push(mob[`move_${i}_ticks`] !== undefined ? String(mob[`move_${i}_ticks`]) : '');
        }
        
        // Add NOEX fields - handle complex objects
        let devNotes = mob['__NOEX developer_notes'] || '';
        if (typeof devNotes === 'object') {
            devNotes = JSON.stringify(devNotes);
        }
        row.push(devNotes);
        
        let schemaNotes = mob['__NOEX schema_notes'] || '';
        if (typeof schemaNotes === 'object') {
            schemaNotes = JSON.stringify(schemaNotes);
        }
        row.push(schemaNotes);
        
        dataRows.push(row);
    }
    
    console.log(`Prepared ${dataRows.length} rows (including header)`);
    
    // Write to sheet
    const updateResponse = await sheets.spreadsheets.values.update({
        spreadsheetId: SPREADSHEET_ID,
        range: `${MOB_SHEET_NAME}!A1`,
        valueInputOption: 'RAW',
        requestBody: {
            values: dataRows
        }
    });
    
    console.log(`✅ Populated sheet with ${updateResponse.data.updatedRows} rows`);
    
    // Format the header row
    await formatHeaders(sheets);
}

async function formatHeaders(sheets) {
    // Get sheet ID
    const sheetInfo = await sheets.spreadsheets.get({
        spreadsheetId: SPREADSHEET_ID,
    });
    const mobSheet = sheetInfo.data.sheets.find(s => s.properties.title === MOB_SHEET_NAME);
    const sheetId = mobSheet.properties.sheetId;
    
    // Format header row
    await sheets.spreadsheets.batchUpdate({
        spreadsheetId: SPREADSHEET_ID,
        requestBody: {
            requests: [
                {
                    // Bold header row
                    repeatCell: {
                        range: {
                            sheetId: sheetId,
                            startRowIndex: 0,
                            endRowIndex: 1
                        },
                        cell: {
                            userEnteredFormat: {
                                textFormat: {
                                    bold: true
                                },
                                backgroundColor: {
                                    red: 0.9,
                                    green: 0.9,
                                    blue: 0.9
                                }
                            }
                        },
                        fields: 'userEnteredFormat(textFormat,backgroundColor)'
                    }
                },
                {
                    // Freeze header row
                    updateSheetProperties: {
                        properties: {
                            sheetId: sheetId,
                            gridProperties: {
                                frozenRowCount: 1
                            }
                        },
                        fields: 'gridProperties.frozenRowCount'
                    }
                },
                {
                    // Auto-resize columns
                    autoResizeDimensions: {
                        dimensions: {
                            sheetId: sheetId,
                            dimension: 'COLUMNS',
                            startIndex: 0,
                            endIndex: 35
                        }
                    }
                }
            ]
        }
    });
    
    console.log('✅ Formatted headers and columns');
}

async function main() {
    console.log('📝 Creating and populating mob_data sheet...\n');
    
    try {
        const sheets = await authenticateSheets();
        console.log('✅ Authenticated with Google Sheets\n');
        
        // Create the sheet
        await createMobSheet(sheets);
        
        // Populate with data
        await populateMobSheet(sheets);
        
        console.log('\n✨ Done! The mob_data sheet has been created and populated.');
        console.log(`\n📊 View the sheet: https://docs.google.com/spreadsheets/d/${SPREADSHEET_ID}/edit#gid=0`);
        console.log('\nThe sheet now contains:');
        console.log('  - All mob data from mob_data.json');
        console.log('  - New multi-move columns (move_1 through move_6 with ticks)');
        console.log('  - Formatted headers with freeze and auto-sizing');
        
    } catch (error) {
        console.error('\n❌ Error:', error.message);
        if (error.response) {
            console.error('Response data:', error.response.data);
        }
        process.exit(1);
    }
}

main();