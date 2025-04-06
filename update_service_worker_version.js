#!/usr/bin/env node

/**
 * Service Worker Version Updater
 * 
 * This script updates both the cache name version and the application version
 * in the service worker file to ensure users get the latest version of the application.
 * 
 * Usage: node update_service_worker_version.js [cacheVersion] [appVersion]
 * If no versions are provided, it will increment the cache version and set app version to current date.
 */

const fs = require('fs');
const path = require('path');

// Path to the service worker file
const serviceWorkerPath = path.join(__dirname, 'web', 'service-worker.js');

// Function to update the service worker version
function updateServiceWorkerVersion(newVersion, newAppVersion) {
  try {
    // Check if the service worker file exists
    if (!fs.existsSync(serviceWorkerPath)) {
      console.error(`❌ Error: Service worker file not found at ${serviceWorkerPath}`);
      return false;
    }

    // Read the service worker file
    let content = fs.readFileSync(serviceWorkerPath, 'utf8');
    
    // Extract the current version
    const cacheNameRegex = /const CACHE_NAME = ['"]vanishing-tictactoe-cache-v(\d+)['"];/;
    const match = cacheNameRegex.exec(content);
    
    if (match) {
      const currentVersion = parseInt(match[1], 10);
      const nextVersion = newVersion || (currentVersion + 1);
      
      // Update the cache name with the new version
      content = content.replace(
        cacheNameRegex,
        `const CACHE_NAME = 'vanishing-tictactoe-cache-v${nextVersion}';`
      );
      
      // Check if CACHE_VERSION exists and update it
      const appVersionRegex = /const CACHE_VERSION = ['"](.*)['"];/;
      const appMatch = appVersionRegex.exec(content);
      
      if (appMatch && newAppVersion) {
        // Update existing CACHE_VERSION
        const currentAppVersion = appMatch[1];
        content = content.replace(
          appVersionRegex,
          `const CACHE_VERSION = '${newAppVersion}';`
        );
        console.log(`✅ App version updated from ${currentAppVersion} to ${newAppVersion}`);
      } else if (appMatch) {
        // CACHE_VERSION exists but no new version provided - use existing
        console.log(`ℹ️ App version unchanged: ${appMatch[1]}`);
      } else if (newAppVersion) {
        // CACHE_VERSION doesn't exist but we want to add it
        const cacheNameLineRegex = /const CACHE_NAME = .*;/;
        const cacheNameMatch = cacheNameLineRegex.exec(content);
        if (cacheNameMatch) {
          const insertionIndex = cacheNameMatch.index + cacheNameMatch[0].length;
          content = content.slice(0, insertionIndex) +
                   `\nconst CACHE_VERSION = '${newAppVersion}';` +
                   content.slice(insertionIndex);
          console.log(`✅ App version added: ${newAppVersion}`);
        } else {
          console.warn('⚠️ Could not find CACHE_NAME line to insert CACHE_VERSION after.');
        }
      }
      
      // Write the updated content back to the file
      fs.writeFileSync(serviceWorkerPath, content, 'utf8');
      
      console.log(`✅ Service worker version updated from v${currentVersion} to v${nextVersion}`);
      return true;
    } else {
      console.error('❌ Error: Could not find CACHE_NAME pattern in service worker file.');
      return false;
    }
  } catch (error) {
    console.error('❌ Error updating service worker version:', error.message);
    return false;
  }
}

// Generate a version string based on current date (YYYY.MM.DD.build)
function generateVersionString() {
  const now = new Date();
  const year = now.getFullYear();
  const month = String(now.getMonth() + 1).padStart(2, '0');
  const day = String(now.getDate()).padStart(2, '0');
  const build = Math.floor(now.getTime() / 1000) % 10000; // Last 4 digits of timestamp
  
  return `${year}.${month}.${day}.${build}`;
}

// Get versions from command line arguments if provided
const providedCacheVersion = process.argv[2] ? parseInt(process.argv[2], 10) : null;
const providedAppVersion = process.argv[3] || generateVersionString();

// Update the service worker version
if (!updateServiceWorkerVersion(providedCacheVersion, providedAppVersion)) {
  process.exit(1); // Exit with error code if update failed
}
