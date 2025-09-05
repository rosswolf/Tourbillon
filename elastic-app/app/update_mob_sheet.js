#!/usr/bin/env node

const { google } = require('googleapis');
const fs = require('fs');
const path = require('path');

// Google Sheets configuration
const SPREADSHEET_ID = '1zoNrBnX2od6nrTL3G4wS_QMYig69laRn0XYH-KOUqTk';
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

async function getSheetData(sheets) {
    try {
        // First, get the sheet metadata to find the mob_data sheet
        const sheetInfo = await sheets.spreadsheets.get({
            spreadsheetId: SPREADSHEET_ID,
        });
        
        console.log('Available sheets:');
        sheetInfo.data.sheets.forEach(sheet => {
            console.log(`  - ${sheet.properties.title} (ID: ${sheet.properties.sheetId})`);
        });
        
        // Try to fetch mob_data sheet
        const response = await sheets.spreadsheets.values.get({
            spreadsheetId: SPREADSHEET_ID,
            range: `${MOB_SHEET_NAME}!A1:ZZ1000`,
        });
        
        return response.data;
    } catch (error) {
        if (error.message.includes('Unable to parse range')) {
            console.log(`Sheet '${MOB_SHEET_NAME}' not found. Will need to create it.`);
            return null;
        }
        throw error;
    }
}

async function updateMobDataSchema(sheets) {
    try {
        // First check if mob_data sheet exists
        const existingData = await getSheetData(sheets);
        
        if (!existingData) {
            console.log('\nNo mob_data sheet found. Please create it first in Google Sheets.');
            console.log(`URL: https://docs.google.com/spreadsheets/d/${SPREADSHEET_ID}/edit`);
            return;
        }
        
        const headers = existingData.values ? existingData.values[0] : [];
        console.log('\nCurrent headers:', headers);
        
        // Find the index of the 'moves' column
        const movesIndex = headers.indexOf('moves');
        
        if (movesIndex === -1) {
            console.log('No "moves" column found. Adding new move columns at the end...');
        } else {
            console.log(`Found "moves" column at index ${movesIndex} (column ${String.fromCharCode(65 + movesIndex)})`);
        }
        
        // Prepare the new headers
        const newMoveHeaders = [
            'move_1', 'move_1_ticks',
            'move_2', 'move_2_ticks',
            'move_3', 'move_3_ticks',
            'move_4', 'move_4_ticks',
            'move_5', 'move_5_ticks',
            'move_6', 'move_6_ticks'
        ];
        
        // Create new header row
        let newHeaders = [...headers];
        
        if (movesIndex !== -1) {
            // Remove the old 'moves' column and insert new columns
            newHeaders.splice(movesIndex, 1, ...newMoveHeaders);
        } else {
            // Just add new columns at the end
            newHeaders.push(...newMoveHeaders);
        }
        
        console.log('\nNew headers will be:', newHeaders);
        
        // Prepare data for update
        const updateData = [];
        
        // Add header row
        updateData.push(newHeaders);
        
        // Process existing data rows
        if (existingData.values && existingData.values.length > 1) {
            console.log(`\nProcessing ${existingData.values.length - 1} data rows...`);
            
            // Load our converted mob_data.json to get the new values
            const mobData = JSON.parse(fs.readFileSync('mob_data.json', 'utf8'));
            const mobDataMap = {};
            mobData.forEach(mob => {
                mobDataMap[mob.template_id] = mob;
            });
            
            for (let i = 1; i < existingData.values.length; i++) {
                const row = existingData.values[i];
                const templateId = row[0]; // Assuming template_id is first column
                
                let newRow = [...row];
                
                // If we have converted data for this mob, use it
                const mobInfo = mobDataMap[templateId];
                
                if (mobInfo && movesIndex !== -1) {
                    // Remove old moves value and add new move values
                    const beforeMoves = newRow.slice(0, movesIndex);
                    const afterMoves = newRow.slice(movesIndex + 1);
                    
                    const moveValues = [];
                    for (let j = 1; j <= 6; j++) {
                        moveValues.push(mobInfo[`move_${j}`] || '');
                        moveValues.push(mobInfo[`move_${j}_ticks`] !== undefined ? mobInfo[`move_${j}_ticks`].toString() : '');
                    }
                    
                    newRow = [...beforeMoves, ...moveValues, ...afterMoves];
                } else if (!mobInfo && movesIndex !== -1) {
                    // No converted data, just expand the old moves column to empty new columns
                    const beforeMoves = newRow.slice(0, movesIndex);
                    const afterMoves = newRow.slice(movesIndex + 1);
                    const emptyMoves = new Array(12).fill('');
                    newRow = [...beforeMoves, ...emptyMoves, ...afterMoves];
                }
                
                updateData.push(newRow);
            }
        }
        
        // Update the sheet
        console.log('\nUpdating Google Sheet...');
        const updateResponse = await sheets.spreadsheets.values.update({
            spreadsheetId: SPREADSHEET_ID,
            range: `${MOB_SHEET_NAME}!A1`,
            valueInputOption: 'RAW',
            requestBody: {
                values: updateData
            }
        });
        
        console.log('✅ Sheet updated successfully!');
        console.log(`Updated ${updateResponse.data.updatedRows} rows and ${updateResponse.data.updatedColumns} columns`);
        
    } catch (error) {
        console.error('Error updating sheet:', error.message);
        throw error;
    }
}

async function main() {
    console.log('🔄 Updating mob_data sheet schema for multi-move system...\n');
    
    try {
        const sheets = await authenticateSheets();
        console.log('✅ Authenticated with Google Sheets\n');
        
        await updateMobDataSchema(sheets);
        
        console.log('\n✨ Done! The mob_data sheet has been updated with the new multi-move schema.');
        console.log(`\n📝 View the sheet: https://docs.google.com/spreadsheets/d/${SPREADSHEET_ID}/edit#gid=0`);
        
    } catch (error) {
        console.error('\n❌ Error:', error.message);
        process.exit(1);
    }
}

main();