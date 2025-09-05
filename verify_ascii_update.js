const { google } = require('googleapis');
const fs = require('fs');
const path = require('path');

async function verifyASCIIUpdate() {
  try {
    // Setup authentication
    const keyFilePath = path.join(process.env.HOME, 'Code/google-sheets-mcp/service-account-key.json');
    
    const auth = new google.auth.GoogleAuth({
      keyFile: keyFilePath,
      scopes: ['https://www.googleapis.com/auth/spreadsheets.readonly'],
    });
    
    const sheets = google.sheets({ version: 'v4', auth: await auth.getClient() });
    const spreadsheetId = '1zoNrBnX2od6nrTL3G4wS_QMYig69laRn0XYH-KOUqTk';
    
    console.log('Fetching updated card data from Google Sheets...');
    
    // Fetch current data
    const response = await sheets.spreadsheets.values.get({
      spreadsheetId: spreadsheetId,
      range: 'card_data!A1:Z1000',
    });
    
    const rows = response.data.values || [];
    console.log(`Fetched ${rows.length} rows`);
    
    // Check for non-ASCII characters
    let nonASCIIFound = false;
    const nonASCIIInstances = [];
    
    rows.forEach((row, rowIndex) => {
      row.forEach((cell, colIndex) => {
        if (typeof cell === 'string') {
          // Check for non-ASCII characters
          const nonASCII = cell.match(/[^\x20-\x7E\n\r\t]/g);
          if (nonASCII && nonASCII.length > 0) {
            nonASCIIFound = true;
            const colLetter = String.fromCharCode(65 + colIndex);
            nonASCIIInstances.push({
              row: rowIndex + 1,
              column: colLetter,
              characters: [...new Set(nonASCII)].join(', '),
              text: cell.substring(0, 50) + (cell.length > 50 ? '...' : '')
            });
          }
        }
      });
    });
    
    if (!nonASCIIFound) {
      console.log('\n✅ SUCCESS: All data is now ASCII-friendly!');
      console.log('No non-ASCII characters found in the spreadsheet.');
      
      // Export to JSON for game use
      console.log('\nExporting to card_data_ascii.json...');
      const cardData = rows.slice(1).map(row => ({
        card_template_id: row[0] || '',
        time_cost: row[1] || '',
        display_name: row[2] || '',
        tags: row[3] || '',
        rules_text: row[4] || '',
        notes: row[5] || ''
      }));
      
      fs.writeFileSync('card_data_ascii.json', JSON.stringify(cardData, null, 2));
      console.log('Exported ASCII-friendly card data to card_data_ascii.json');
      
    } else {
      console.log(`\n⚠️ WARNING: Found ${nonASCIIInstances.length} cells with non-ASCII characters:`);
      console.log('These may have been added after the conversion or were missed:');
      nonASCIIInstances.slice(0, 10).forEach(instance => {
        console.log(`  Row ${instance.row}, Column ${instance.column}:`);
        console.log(`    Characters: ${instance.characters}`);
        console.log(`    Text: "${instance.text}"`);
      });
    }
    
    // Show sample of converted data
    console.log('\nSample of ASCII-friendly rules text:');
    rows.slice(1, 11).forEach((row, index) => {
      if (row[4]) { // rules_text column
        console.log(`  ${index + 1}. ${row[4].substring(0, 60)}${row[4].length > 60 ? '...' : ''}`);
      }
    });
    
  } catch (error) {
    console.error('Error verifying sheets:', error.message);
  }
}

// Run verification
verifyASCIIUpdate();