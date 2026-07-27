const fs = require('fs');
const path = require('path');

const s01 = require('./test_suites/01_functional');
const s02 = require('./test_suites/02_ui_ux');
const s03 = require('./test_suites/03_compatibility');
const s04 = require('./test_suites/04_performance');
const s05 = require('./test_suites/05_security');
const s06 = require('./test_suites/06_api');
const s07 = require('./test_suites/07_database');
const s08 = require('./test_suites/08_accessibility');
const s09 = require('./test_suites/09_mobile_specific');
const s10 = require('./test_suites/10_regression');
const s11 = require('./test_suites/11_end_to_end');

const tests = [
  ...s01.generateTests(),
  ...s02.generateTests(),
  ...s03.generateTests(),
  ...s04.generateTests(),
  ...s05.generateTests(),
  ...s06.generateTests(),
  ...s07.generateTests(),
  ...s08.generateTests(),
  ...s09.generateTests(),
  ...s10.generateTests(),
  ...s11.generateTests()
];

let csv = 'Test Case ID,Category,Functionality Under Test,Input Data,Expected Outcome,Actual Result,Status,Duration (ms),Timestamp\n';

tests.forEach(t => {
  const cleanInput = (t.input || '').replace(/"/g, '""');
  const cleanExp = (t.expected || '').replace(/"/g, '""');
  const cleanAct = (t.actual || '').replace(/"/g, '""');
  csv += `"${t.id}","${t.category}","${t.name}","${cleanInput}","${cleanExp}","${cleanAct}","${t.status}",${t.duration},"${t.timestamp}"\n`;
});

const csvPath = path.join(__dirname, '..', 'ConstructHub_Selenium_Test_Analysis_Report.csv');
fs.writeFileSync(csvPath, csv);
console.log('✅ Generated CSV Excel Report:', csvPath);
