const { google } = require('googleapis');
const fs = require('fs');
const path = require('path');

// ASCII replacement mappings
const ASCII_REPLACEMENTS = {
  '→': '->',
  '←': '<-',
  '↑': '^',
  '↓': 'v',
  'â': '->', // Alternative arrow character
  '–': '-',  // en dash
  '—': '--', // em dash
  '\u201C': '"',  // left smart quote
  '\u201D': '"',  // right smart quote
  '\u2018': "'",  // left smart single quote
  '\u2019': "'",  // right smart single quote
  '…': '...', // ellipsis
  '×': 'x',  // multiplication
  '÷': '/',  // division
  '±': '+/-', // plus minus
  '°': 'deg', // degree
  '•': '*',  // bullet point
  '™': 'TM', // trademark
  '©': '(c)', // copyright
  '®': '(R)', // registered
  '≤': '<=', // less than or equal
  '≥': '>=', // greater than or equal
  '≠': '!=', // not equal
  '∞': 'INF', // infinity
  '√': 'sqrt', // square root
  '²': '^2', // superscript 2
  '³': '^3', // superscript 3
};

// Function to convert text to ASCII
function toASCII(text) {
  if (!text) return text;
  
  let result = text;
  for (const [nonASCII, ascii] of Object.entries(ASCII_REPLACEMENTS)) {
    result = result.split(nonASCII).join(ascii);
  }
  
  // Also remove any other non-ASCII characters that might have been missed
  // This regex keeps only ASCII printable characters (32-126)
  result = result.replace(/[^\x20-\x7E\n\r\t]/g, '');
  
  return result;
}

async function updateSheetsToASCII() {
  try {
    // Setup authentication
    const keyFilePath = path.join(process.env.HOME, 'Code/google-sheets-mcp/service-account-key.json');
    
    if (!fs.existsSync(keyFilePath)) {
      throw new Error(`Service account key not found at: ${keyFilePath}`);
    }
    
    const auth = new google.auth.GoogleAuth({
      keyFile: keyFilePath,
      scopes: ['https://www.googleapis.com/auth/spreadsheets'],
    });
    
    const sheets = google.sheets({ version: 'v4', auth: await auth.getClient() });
    const spreadsheetId = '1zoNrBnX2od6nrTL3G4wS_QMYig69laRn0XYH-KOUqTk';
    
    console.log('Fetching current card data from Google Sheets...');
    
    // Fetch current data
    const response = await sheets.spreadsheets.values.get({
      spreadsheetId: spreadsheetId,
      range: 'card_data!A1:Z1000', // Get all columns to ensure we don't miss any
    });
    
    const rows = response.data.values || [];
    
    if (rows.length === 0) {
      console.log('No data found in sheet');
      return;
    }
    
    console.log(`Found ${rows.length} rows in sheet`);
    
    // Track changes
    let changesFound = false;
    const updatedRows = [];
    const changeLog = [];
    
    // Process each row
    rows.forEach((row, rowIndex) => {
      const updatedRow = row.map((cell, colIndex) => {
        if (typeof cell !== 'string') return cell;
        
        const original = cell;
        const converted = toASCII(cell);
        
        if (original !== converted) {
          changesFound = true;
          const colLetter = String.fromCharCode(65 + colIndex); // A, B, C, etc.
          changeLog.push({
            row: rowIndex + 1,
            column: colLetter,
            original: original.substring(0, 50) + (original.length > 50 ? '...' : ''),
            converted: converted.substring(0, 50) + (converted.length > 50 ? '...' : '')
          });
        }
        
        return converted;
      });
      updatedRows.push(updatedRow);
    });
    
    if (!changesFound) {
      console.log('No non-ASCII characters found. Sheet is already ASCII-friendly!');
      return;
    }
    
    // Log changes
    console.log(`\nFound ${changeLog.length} cells with non-ASCII characters:`);
    console.log('Sample of changes (first 10):');
    changeLog.slice(0, 10).forEach(change => {
      console.log(`  Row ${change.row}, Column ${change.column}:`);
      console.log(`    Original: "${change.original}"`);
      console.log(`    Converted: "${change.converted}"`);
    });
    
    // Ask for confirmation
    console.log(`\nTotal changes to make: ${changeLog.length}`);
    console.log('Updating Google Sheets...');
    
    // Update the sheet
    const updateResponse = await sheets.spreadsheets.values.update({
      spreadsheetId: spreadsheetId,
      range: 'card_data!A1',
      valueInputOption: 'RAW',
      requestBody: {
        values: updatedRows
      }
    });
    
    console.log(`Successfully updated ${updateResponse.data.updatedRows} rows`);
    console.log(`Updated ${updateResponse.data.updatedCells} cells`);
    
    // Save a backup of changes
    const backupFile = `card_data_ascii_changes_${Date.now()}.json`;
    fs.writeFileSync(backupFile, JSON.stringify({
      timestamp: new Date().toISOString(),
      totalChanges: changeLog.length,
      changes: changeLog
    }, null, 2));
    
    console.log(`\nBackup of changes saved to: ${backupFile}`);
    console.log('\nGoogle Sheets has been updated with ASCII-friendly text!');
    console.log('You can view the updated sheet at:');
    console.log('https://docs.google.com/spreadsheets/d/1zoNrBnX2od6nrTL3G4wS_QMYig69laRn0XYH-KOUqTk/edit');
    
  } catch (error) {
    console.error('Error updating sheets:', error.message);
    if (error.code === 403) {
      console.error('\nAuthentication error. Please ensure:');
      console.error('1. The service account key file exists at ~/Code/google-sheets-mcp/service-account-key.json');
      console.error('2. The service account has Editor access to the spreadsheet');
    }
  }
}

// Run the update
updateSheetsToASCII();