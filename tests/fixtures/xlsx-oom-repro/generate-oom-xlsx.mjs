#!/usr/bin/env node
/**
 * Generates an xlsx file that triggers OOM in @kreuzberg/node
 *
 * ROOT CAUSE: Excel Solver add-in stores data in cells at extreme positions
 * (XFD1048550-1048575 = column 16384, rows near max). The sheet's dimension
 * is set to "A1:XFD1048575", and Kreuzberg allocates memory for this range.
 *
 * Usage: node tests/fixtures/xlsx-oom-repro/generate-oom-xlsx.mjs
 * Test:  node --max-old-space-size=512 -e "import { extractFile } from '@kreuzberg/node'; await extractFile('tests/fixtures/xlsx-oom-repro/kreuzberg-oom-repro.xlsx');"
 */

import ExcelJS from 'exceljs';
import AdmZip from 'adm-zip';
import { unlinkSync, statSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const workbook = new ExcelJS.Workbook();
const sheet = workbook.addWorksheet('Data');

// Normal data
sheet.getCell('A1').value = 'Test';
sheet.getCell('B1').value = 123;

const tempFile = join(__dirname, 'temp-base.xlsx');
const outputFile = join(__dirname, 'kreuzberg-oom-repro.xlsx');

await workbook.xlsx.writeFile(tempFile);

const zip = new AdmZip(tempFile);
let sheetXml = zip.readAsText('xl/worksheets/sheet1.xml');

// Replace dimension with extreme range (this is the key!)
sheetXml = sheetXml.replace(/dimension ref="[^"]*"/, 'dimension ref="A1:XFD1048575"');

// Add Solver-style data cells at extreme positions
const solverCells = `
<row r="1048550" spans="16384:16384"><c r="XFD1048550"><f>solver_pre</f><v>0.000001</v></c></row>
<row r="1048551" spans="16384:16384"><c r="XFD1048551"><f>solver_scl</f><v>1</v></c></row>
<row r="1048552" spans="16384:16384"><c r="XFD1048552"><f>solver_rlx</f><v>2</v></c></row>
<row r="1048553" spans="16384:16384"><c r="XFD1048553"><f>solver_tol</f><v>0.01</v></c></row>
<row r="1048554" spans="16384:16384"><c r="XFD1048554"><f>solver_cvg</f><v>0.0001</v></c></row>
<row r="1048555" spans="16384:16384"><c r="XFD1048555" t="e" cm="1"><f t="array" aca="1" ref="XFD1048555" ca="1">_xludf.Areas(solver_adj1)</f><v>#NAME?</v></c></row>
<row r="1048556" spans="16384:16384"><c r="XFD1048556"><f>solver_ssz</f><v>100</v></c></row>
<row r="1048557" spans="16384:16384"><c r="XFD1048557"><f>solver_rsd</f><v>0</v></c></row>
<row r="1048558" spans="16384:16384"><c r="XFD1048558"><f>solver_mrt</f><v>0.075</v></c></row>
<row r="1048559" spans="16384:16384"><c r="XFD1048559"><f>solver_mni</f><v>30</v></c></row>
<row r="1048560" spans="16384:16384"><c r="XFD1048560"><f>solver_rbv</f><v>1</v></c></row>
<row r="1048561" spans="16384:16384"><c r="XFD1048561"><f>solver_neg</f><v>1</v></c></row>
<row r="1048562" spans="16384:16384"><c r="XFD1048562" t="e" cm="1"><f t="array" ref="XFD1048562">solver_ntr</f><v>#NAME?</v></c></row>
<row r="1048563" spans="16384:16384"><c r="XFD1048563" t="e" cm="1"><f t="array" ref="XFD1048563">solver_acc</f><v>#NAME?</v></c></row>
<row r="1048564" spans="16384:16384"><c r="XFD1048564" t="e" cm="1"><f t="array" ref="XFD1048564">solver_res</f><v>#NAME?</v></c></row>
<row r="1048565" spans="16384:16384"><c r="XFD1048565" t="e" cm="1"><f t="array" ref="XFD1048565">solver_ars</f><v>#NAME?</v></c></row>
<row r="1048566" spans="16384:16384"><c r="XFD1048566" t="e" cm="1"><f t="array" ref="XFD1048566">solver_sta</f><v>#NAME?</v></c></row>
<row r="1048567" spans="16384:16384"><c r="XFD1048567" t="e" cm="1"><f t="array" ref="XFD1048567">solver_met</f><v>#NAME?</v></c></row>
<row r="1048568" spans="16384:16384"><c r="XFD1048568" t="e" cm="1"><f t="array" ref="XFD1048568">solver_soc</f><v>#NAME?</v></c></row>
<row r="1048569" spans="16384:16384"><c r="XFD1048569" t="e" cm="1"><f t="array" ref="XFD1048569">solver_lpt</f><v>#NAME?</v></c></row>
<row r="1048570" spans="16384:16384"><c r="XFD1048570" t="e" cm="1"><f t="array" ref="XFD1048570">solver_lpp</f><v>#NAME?</v></c></row>
<row r="1048571" spans="16384:16384"><c r="XFD1048571" t="e" cm="1"><f t="array" ref="XFD1048571">solver_gap</f><v>#NAME?</v></c></row>
<row r="1048572" spans="16384:16384"><c r="XFD1048572" t="e" cm="1"><f t="array" ref="XFD1048572">solver_ips</f><v>#NAME?</v></c></row>
<row r="1048573" spans="16384:16384"><c r="XFD1048573" t="e" cm="1"><f t="array" ref="XFD1048573">solver_fea</f><v>#NAME?</v></c></row>
<row r="1048574" spans="16384:16384"><c r="XFD1048574" t="e" cm="1"><f t="array" ref="XFD1048574">solver_ipi</f><v>#NAME?</v></c></row>
<row r="1048575" spans="16384:16384"><c r="XFD1048575" t="e" cm="1"><f t="array" ref="XFD1048575">solver_ipd</f><v>#NAME?</v></c></row>`;

sheetXml = sheetXml.replace('</sheetData>', solverCells + '</sheetData>');

zip.updateFile('xl/worksheets/sheet1.xml', Buffer.from(sheetXml));
zip.writeZip(outputFile);
unlinkSync(tempFile);

const stats = statSync(outputFile);
console.log(`Created ${outputFile} (${stats.size} bytes)`);
console.log('');
console.log('This file simulates an Excel file with Solver add-in data.');
console.log('Solver stores config in cells XFD1048550-1048575 (max column, near max row).');
console.log('The sheet dimension "A1:XFD1048575" may cause Kreuzberg to allocate');
console.log('memory for ~17 trillion cells (16384 × 1048575).');
