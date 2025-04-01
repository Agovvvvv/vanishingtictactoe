const fs = require('fs');
const path = require('path');
const dotenv = require('dotenv');

// Load environment variables from .env file
dotenv.config();

// Path to the firebase-config.js template
const configPath = path.join(__dirname, '../web/firebase-config.js');

// Read the template file
let configContent = fs.readFileSync(configPath, 'utf8');

// Replace placeholders with actual values from environment variables
configContent = configContent
  .replace('FIREBASE_WEB_API_KEY', process.env.FIREBASE_WEB_API_KEY || '')
  .replace('FIREBASE_WEB_AUTH_DOMAIN', process.env.FIREBASE_WEB_AUTH_DOMAIN || '')
  .replace('FIREBASE_WEB_PROJECT_ID', process.env.FIREBASE_WEB_PROJECT_ID || '')
  .replace('FIREBASE_WEB_STORAGE_BUCKET', process.env.FIREBASE_WEB_STORAGE_BUCKET || '')
  .replace('FIREBASE_WEB_MESSAGING_SENDER_ID', process.env.FIREBASE_WEB_MESSAGING_SENDER_ID || '')
  .replace('FIREBASE_WEB_APP_ID', process.env.FIREBASE_WEB_APP_ID || '')
  .replace('FIREBASE_WEB_MEASUREMENT_ID', process.env.FIREBASE_WEB_MEASUREMENT_ID || '')
  .replace('FIREBASE_WEB_DATABASE_URL', process.env.FIREBASE_WEB_DATABASE_URL || '');

// Write the updated content back to the file
fs.writeFileSync(configPath, configContent);

console.log('Firebase config updated with environment variables');
