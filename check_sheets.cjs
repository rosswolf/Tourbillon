const { google } = require('googleapis');
const keyPath = '../google-sheets-mcp/service-account-key.json';

async function checkSheets() {
  try {
    const auth = new google.auth.GoogleAuth({
      keyFile: keyPath,
      scopes: ['https://www.googleapis.com/auth/spreadsheets.readonly'],
    });
    
    const sheets = google.sheets({ version: 'v4', auth: await auth.getClient() });
    const sheetId = '1TlOn39AXlw0y2tlkE4kvIpvoZ9SpNQTkDGgOptvqSgM';
    
    console.log('=== CHECKING GOOGLE SHEETS CONTENT ===');
    
    // First, check what sheets exist
    const metadata = await sheets.spreadsheets.get({ spreadsheetId: sheetId });
    console.log('Available sheets:');
    metadata.data.sheets.forEach(sheet => {
      console.log(`- "${sheet.properties.title}" (ID: ${sheet.properties.sheetId})`);
    });
    
    // Try to read from mob_data sheet
    const range = 'mob_data!A1:Z100';
    const res = await sheets.spreadsheets.values.get({ spreadsheetId: sheetId, range });
    const rows = res.data.values;
    
    console.log('\n=== MOB_DATA SHEET CONTENT ===');
    if (!rows || rows.length === 0) {
      console.log('❌ Sheet appears to be completely empty');
      return;
    }
    
    console.log('Total rows found:', rows.length);
    
    if (rows.length >= 1) {
      console.log('Headers (row 1):', rows[0]);
    }
    
    if (rows.length <= 1) {
      console.log('❌ Only headers found - no actual data rows');
    } else {
      console.log(`✅ Found ${rows.length - 1} data rows`);
      console.log('\nFirst few rows:');
      rows.slice(0, Math.min(3, rows.length)).forEach((row, idx) => {
        console.log(`Row ${idx}:`, row);
      });
    }
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  }
}

checkSheets();