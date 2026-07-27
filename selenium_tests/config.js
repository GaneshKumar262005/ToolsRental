/**
 * Global Configuration for Selenium Web Test Suite
 */
module.exports = {
  baseUrl: 'http://localhost:8080',
  adminCredentials: {
    email: 'admin.control@constructpro-secure.com',
    password: 'BuildMaster@2026#'
  },
  shopOwnerCredentials: {
    email: 'ganesh26200507@gmail.com',
    password: 'shop.owner.pass2026'
  },
  customerCredentials: {
    email: 'customer@constructhub.com',
    password: 'CustomerPass@2026'
  },
  reportFilename: 'ConstructHub_Selenium_Test_Analysis_Report.xlsx',
  categories: [
    'Functional Testing',
    'UI/UX Testing',
    'Compatibility Testing',
    'Performance Testing',
    'Security Testing',
    'API Testing',
    'Database Testing',
    'Accessibility Testing',
    'Mobile-Specific Testing',
    'Regression Testing',
    'End-to-End (E2E) Testing'
  ]
};
