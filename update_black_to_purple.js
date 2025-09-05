const { google } = require('googleapis');
const fs = require('fs').promises;
const path = require('path');

const CARD_SHEET_ID = '1zoNrBnX2od6nrTL3G4wS_QMYig69laRn0XYH-KOUqTk';

async function updateSheetsBlackToPurple() {
    try {
        // Load credentials
        const credPath = path.join(__dirname, 'data', 'credentials.json');
        const credentials = JSON.parse(await fs.readFile(credPath, 'utf-8'));
        
        const auth = new google.auth.JWT(
            credentials.client_email,
            null,
            credentials.private_key,
            ['https://www.googleapis.com/auth/spreadsheets']
        );
        
        const sheets = google.sheets({ version: 'v4', auth });
        
        console.log('🟣 Updating Card Spreadsheet: Black → Purple...\n');
        
        // Get all data from the Cards sheet
        const cardsResponse = await sheets.spreadsheets.values.get({
            spreadsheetId: CARD_SHEET_ID,
            range: 'Cards!A:Z',
        });
        
        const rows = cardsResponse.data.values;
        if (!rows || rows.length === 0) {
            console.log('No data found.');
            return;
        }
        
        // Find all cells containing "Black" and replace with "Purple"
        const updates = [];
        for (let rowIndex = 0; rowIndex < rows.length; rowIndex++) {
            const row = rows[rowIndex];
            for (let colIndex = 0; colIndex < row.length; colIndex++) {
                const cellValue = row[colIndex];
                if (cellValue && typeof cellValue === 'string') {
                    // Replace Black with Purple (case-insensitive)
                    const newValue = cellValue
                        .replace(/\bBlack\b/g, 'Purple')
                        .replace(/\bblack\b/g, 'purple')
                        .replace(/\bBLACK\b/g, 'PURPLE')
                        .replace(/starter_black_gen/g, 'starter_purple_gen');
                    
                    if (newValue !== cellValue) {
                        // Convert column index to letter
                        const colLetter = String.fromCharCode(65 + colIndex);
                        const cellAddress = `${colLetter}${rowIndex + 1}`;
                        
                        updates.push({
                            range: `Cards!${cellAddress}`,
                            values: [[newValue]]
                        });
                        
                        console.log(`  📝 ${cellAddress}: "${cellValue}" → "${newValue}"`);
                    }
                }
            }
        }
        
        if (updates.length > 0) {
            // Batch update all cells
            await sheets.spreadsheets.values.batchUpdate({
                spreadsheetId: CARD_SHEET_ID,
                resource: {
                    data: updates,
                    valueInputOption: 'RAW'
                }
            });
            
            console.log(`\n✅ Updated ${updates.length} cells in Cards sheet`);
        } else {
            console.log('✅ No "Black" references found in Cards sheet');
        }
        
        console.log(`\n🔗 View at: https://docs.google.com/spreadsheets/d/${CARD_SHEET_ID}/edit`);
        
    } catch (error) {
        console.error('Error updating sheets:', error.message);
        if (error.response) {
            console.error('Response data:', error.response.data);
        }
    }
}

// Update local JSON files
async function updateLocalFiles() {
    console.log('\n📁 Updating local JSON files...\n');
    
    const filesToUpdate = [
        'elastic-app/app/src/scenes/data/card_data.json',
        'elastic-app/app/card_data.json',
        'card_data.json',
        'card_data_ascii.json'
    ];
    
    for (const filePath of filesToUpdate) {
        try {
            const fullPath = path.join(__dirname, filePath);
            const content = await fs.readFile(fullPath, 'utf-8');
            
            // Replace all variations of black with purple
            const updatedContent = content
                .replace(/\bBlack\b/g, 'Purple')
                .replace(/\bblack\b/g, 'purple')
                .replace(/\bBLACK\b/g, 'PURPLE')
                .replace(/starter_black_gen/g, 'starter_purple_gen');
            
            if (content !== updatedContent) {
                await fs.writeFile(fullPath, updatedContent, 'utf-8');
                console.log(`  ✅ Updated: ${filePath}`);
            } else {
                console.log(`  ⏭️  No changes needed: ${filePath}`);
            }
        } catch (error) {
            console.log(`  ⚠️  Could not update ${filePath}: ${error.message}`);
        }
    }
}

// Update documentation files
async function updateDocs() {
    console.log('\n📚 Updating documentation files...\n');
    
    const docsToUpdate = [
        'docs/game-design/FORCE_IDENTITY_SUMMARY.md',
        'docs/TOURBILLON_PRD.md',
        'docs/game-design/BUILD_ARCHETYPES.md',
        'docs/game-design/FORCE_SYSTEM_REDESIGN.md'
    ];
    
    for (const filePath of docsToUpdate) {
        try {
            const fullPath = path.join(__dirname, filePath);
            const content = await fs.readFile(fullPath, 'utf-8');
            
            // Replace Black with Purple in force/energy context
            // Keep "fade to black" and similar non-energy uses
            const updatedContent = content
                .replace(/💀 Entropy \(Black\)/g, '💜 Entropy (Purple)')
                .replace(/Black Energy/g, 'Purple Energy')
                .replace(/Black Mana/g, 'Purple Mana')
                .replace(/\bBlack Force\b/g, 'Purple Force')
                .replace(/White\/Black/g, 'White/Purple')
                .replace(/Black\/White/g, 'Purple/White')
                .replace(/\(Balance \+ Entropy\)/g, '(Balance + Entropy)')
                .replace(/produce.*Black/gi, (match) => match.replace(/Black/gi, 'Purple'))
                .replace(/consume.*Black/gi, (match) => match.replace(/Black/gi, 'Purple'));
            
            if (content !== updatedContent) {
                await fs.writeFile(fullPath, updatedContent, 'utf-8');
                console.log(`  ✅ Updated: ${filePath}`);
            } else {
                console.log(`  ⏭️  No changes needed: ${filePath}`);
            }
        } catch (error) {
            console.log(`  ⚠️  Could not update ${filePath}: ${error.message}`);
        }
    }
}

// Main execution
async function main() {
    console.log('🚀 Starting Black → Purple color update...\n');
    
    // Update Google Sheets
    await updateSheetsBlackToPurple();
    
    // Update local files
    await updateLocalFiles();
    
    // Update documentation
    await updateDocs();
    
    console.log('\n✨ Color update complete! Black has been replaced with Purple.');
    console.log('\nNext steps:');
    console.log('1. Run any import scripts to sync sheet changes');
    console.log('2. Test that card generation still works correctly');
    console.log('3. Update any UI elements that reference black energy');
}

main().catch(console.error);