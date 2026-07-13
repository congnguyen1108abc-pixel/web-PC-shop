const fs = require('fs');
const path = require('path');

const filePath = 'd:\\DoAnTMDT\\PC_Store\\DATABASE_PC.sql';
const content = fs.readFileSync(filePath, 'utf8');

const lines = content.split('\n');
lines.forEach((line, idx) => {
    if (line.includes('tối đa 5') || line.includes('Banner') && line.includes('trg_')) {
        console.log(`Line ${idx + 1}: ${line.trim()}`);
        // print surrounding lines
        for (let i = Math.max(0, idx - 15); i <= Math.min(lines.length - 1, idx + 15); i++) {
            console.log(`  [${i + 1}] ${lines[i]}`);
        }
        console.log('====================================');
    }
});
