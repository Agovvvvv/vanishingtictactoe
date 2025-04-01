#!/usr/bin/env node

/**
 * Service Worker Version Updater
 * 
 * This script updates the version number in the service worker file
 * to ensure users get the latest version of the application.
 * 
 * Usage: node update_service_worker_version.js [version]
 * If no version is provided, it will increment the patch version.
 */

const fs = require('fs');
const path = require('path');

// Path to the service worker file
const serviceWorkerPath = path.join(__dirname, 'web', 'service-worker.js');

// Function to update the service worker version
function updateServiceWorkerVersion(newVersion) {
  try {
    // Read the service worker file
    let content = fs.readFileSync(serviceWorkerPath, 'utf8');
    
    // Extract the current version
    const cacheNameRegex = /const CACHE_NAME = ['"]vanishing-tictactoe-cache-v(\d+)['"];/;
    const match = content.match(cacheNameRegex);
    
    if (match) {
      const currentVersion = parseInt(match[1], 10);
      const nextVersion = newVersion || (currentVersion + 1);
      
      // Update the cache name with the new version
      content = content.replace(
        cacheNameRegex,
        `const CACHE_NAME = 'vanishing-tictactoe-cache-v${nextVersion}';`
      );
      
      // Write the updated content back to the file
      fs.writeFileSync(serviceWorkerPath, content, 'utf8');
      
      console.log(`✅ Service worker version updated from v${currentVersion} to v${nextVersion}`);
      return true;
    } else {
      console.error('❌ Could not find CACHE_NAME in service worker file');
      return false;
    }
  } catch (error) {
    console.error('❌ Error updating service worker version:', error.message);
    return false;
  }
}

// Get the version from command line arguments if provided
const providedVersion = process.argv[2] ? parseInt(process.argv[2], 10) : null;

// Update the service worker version
updateServiceWorkerVersion(providedVersion);
