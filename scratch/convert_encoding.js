const fs = require('fs');
const path = require('path');

const filePath = 'd:\\DoAnTMDT\\PC_Store\\DATABASE_PC.sql';
try {
    // Read the file as UTF-16 LE (ucs2 in Node.js)
    const content = fs.readFileSync(filePath, 'binary');
    
    // Check if it is indeed UTF-16 LE (look for null bytes or BOM)
    let decoded = '';
    if (content.charCodeAt(0) === 0xFF && content.charCodeAt(1) === 0xFE) {
        console.log('Detected UTF-16 LE BOM. Decoding...');
        decoded = fs.readFileSync(filePath, 'utf16le');
    } else if (content.includes('\x00')) {
        console.log('Detected null bytes, assuming UTF-16 LE. Decoding...');
        decoded = fs.readFileSync(filePath, 'utf16le');
    } else {
        console.log('File does not seem to be UTF-16 LE. Trying UTF-8...');
        decoded = fs.readFileSync(filePath, 'utf8');
    }
    
    // Write back as UTF-8
    fs.writeFileSync(filePath, decoded, 'utf8');
    console.log('Successfully converted DATABASE_PC.sql to UTF-8!');
} catch (err) {
    console.error('Error converting file:', err);
}
