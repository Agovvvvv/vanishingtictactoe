// Service Worker Registration and Update Management
// This script handles service worker registration, updates, and user notifications

// Configuration
const SERVICE_WORKER_URL = 'service-worker.js';
const CHECK_INTERVAL = 60 * 60 * 1000; // Check for updates every hour (consider if needed alongside updatefound)
const UPDATE_TIMEOUT = 10000; // Increased timeout (10 seconds) - consider removing forced reload

// State
let updateAvailable = false;
let registration = null;
let updateLoadingIndicator = null; // Reference to loading indicator
let currentVersion = null; // Track the current version

// Get the version of a service worker
async function getServiceWorkerVersion(worker) {
  return new Promise((resolve) => {
    const messageChannel = new MessageChannel();
    messageChannel.port1.onmessage = (event) => {
      resolve(event.data.version);
    };
    worker.postMessage({ type: 'CHECK_VERSION' }, [messageChannel.port2]);
    
    // Timeout in case the service worker doesn't respond
    setTimeout(() => resolve(null), 1000);
  });
}

// Check if a service worker is newer than the current version
async function isNewerVersion(worker) {
  if (!worker) return false;
  
  const workerVersion = await getServiceWorkerVersion(worker);
  
  if (!workerVersion) return false;
  if (!currentVersion) {
    // If we don't know the current version, assume it's newer
    currentVersion = workerVersion;
    return false;
  }
  
  console.log(`[SW Registration] Comparing versions - Current: ${currentVersion}, New: ${workerVersion}`);
  
  // Simple string comparison - assumes versions are comparable strings
  // For more complex version comparison, implement a proper semver comparison
  return workerVersion !== currentVersion;
}

// Register the service worker
function registerServiceWorker() {
  if ('serviceWorker' in navigator) {
    // Delay registration until after the page has loaded
    window.addEventListener('load', () => {
      // Add a timestamp to bypass browser HTTP cache for the service worker script itself
      const swUrl = `${SERVICE_WORKER_URL}?v=${new Date().getTime()}`;

      navigator.serviceWorker.register(swUrl)
        .then(async (reg) => {
          console.log('[SW Registration] Service Worker registered with scope:', reg.scope);
          registration = reg;
          
          // Get the current version from the active service worker if available
          if (navigator.serviceWorker.controller) {
            currentVersion = await getServiceWorkerVersion(navigator.serviceWorker.controller);
            console.log('[SW Registration] Current service worker version:', currentVersion);
          }

          // Check if there's a waiting service worker
          if (reg.waiting) {
            console.log('[SW Registration] Service Worker waiting on initial load.');
            // Only show update if the waiting worker is newer
            const isNewer = await isNewerVersion(reg.waiting);
            if (isNewer) {
              updateReady(reg.waiting);
            } else {
              console.log('[SW Registration] Waiting service worker is not newer than current version.');
            }
            return;
          }

          // Check if there's an installing service worker
          if (reg.installing) {
            console.log('[SW Registration] Service Worker installing on initial load.');
            trackInstallation(reg.installing);
            return;
          }

          // Listen for new service workers installing
          reg.addEventListener('updatefound', () => {
            console.log('[SW Registration] Service Worker update found event triggered.');
            trackInstallation(reg.installing);
          });

          // Set up periodic update checks (optional fallback)
          // setInterval(() => checkForUpdates(), CHECK_INTERVAL);
          // console.log('[SW Registration] Periodic update check interval set (currently commented out).');

        })
        .catch((error) => {
          console.error('[SW Registration] Registration failed:', error);
        });

      // Detect controller change
      let refreshing = false;
      let initialInstall = !navigator.serviceWorker.controller;
      
      navigator.serviceWorker.addEventListener('controllerchange', () => {
        if (refreshing) return;
        // Ensure the loading indicator is removed if present during a controller change reload
        hideUpdateLoadingIndicator();
        refreshing = true;

        console.log('[SW Registration] New Service Worker controller activated.');
        
        // If this is the initial installation, don't reload
        if (initialInstall) {
          console.log('[SW Registration] Initial installation, no reload needed.');
          initialInstall = false; // Reset after first run
          refreshing = false; // Allow future controller changes to be processed
          return;
        }
        
        // Reload the page *only* if an update was intentionally applied by the user
        if (updateAvailable) {
          console.log('[SW Registration] Reloading page for new version.');
          updateAvailable = false; // Reset the flag BEFORE reloading
          window.location.reload();
        } else {
          console.log('[SW Registration] Controller changed, but not due to user-triggered update. No reload enforced.');
          refreshing = false; // Allow future controller changes to be processed
        }
      });
    });
  } else {
    console.log('[SW Registration] Service Workers not supported in this browser.');
  }
}

// Track the installation state of a service worker
function trackInstallation(worker) {
  worker.addEventListener('statechange', async () => {
    if (worker.state === 'installed') {
      if (navigator.serviceWorker.controller) {
        // This is an update, a new worker is installed and waiting
        console.log('[SW Registration] New worker installed and waiting.');
        
        // Only show update notification if the worker is newer
        const isNewer = await isNewerVersion(worker);
        if (isNewer) {
          console.log('[SW Registration] New version detected, showing update notification.');
          // Update the current version to the new one
          const newVersion = await getServiceWorkerVersion(worker);
          if (newVersion) currentVersion = newVersion;
          updateReady(worker);
        } else {
          console.log('[SW Registration] Worker installed but not newer than current version.');
        }
      } else {
        // This is a new installation, the SW takes control after activation
        console.log('[SW Registration] Service Worker installed for the first time.');
        // Store the version for future comparisons
        const version = await getServiceWorkerVersion(worker);
        if (version) currentVersion = version;
      }
    }
  });
}

// Handle an update-ready service worker
function updateReady(worker) {
  console.log('[SW Registration] Update is ready.');
  updateAvailable = true;
  // Notify the user about the update
  showUpdateNotification();
}

// Show a notification to the user about the available update
function showUpdateNotification() {
  // Suggestion: Use CSS classes and potentially a pre-defined HTML element
  // For brevity, keeping dynamic creation but recommend changing this.
  let notification = document.getElementById('sw-update-notification');

  if (!notification) {
    notification = document.createElement('div');
    notification.id = 'sw-update-notification';
    notification.style.position = 'fixed';
    notification.style.bottom = '20px';
    notification.style.right = '20px';
    notification.style.backgroundColor = '#4CAF50';
    notification.style.color = 'white';
    notification.style.padding = '16px';
    notification.style.borderRadius = '8px';
    notification.style.boxShadow = '0 4px 8px rgba(0,0,0,0.2)';
    notification.style.zIndex = '9999';
    notification.style.display = 'flex';
    notification.style.alignItems = 'center';
    notification.style.justifyContent = 'space-between';
    notification.style.maxWidth = '400px';

    const message = document.createElement('div');
    message.textContent = 'A new version is available!';
    message.style.marginRight = '16px';

    const buttonContainer = document.createElement('div');

    const updateButton = document.createElement('button');
    updateButton.textContent = 'Update Now';
    updateButton.style.backgroundColor = 'white';
    updateButton.style.color = '#4CAF50';
    updateButton.style.border = 'none';
    updateButton.style.padding = '8px 16px';
    updateButton.style.borderRadius = '4px';
    updateButton.style.cursor = 'pointer';
    updateButton.style.marginRight = '8px';
    updateButton.onclick = applyUpdate;

    const closeButton = document.createElement('button');
    closeButton.textContent = 'Later';
    closeButton.style.backgroundColor = 'transparent';
    closeButton.style.color = 'white';
    closeButton.style.border = '1px solid white';
    closeButton.style.padding = '8px 16px';
    closeButton.style.borderRadius = '4px';
    closeButton.style.cursor = 'pointer';
    closeButton.onclick = () => {
      notification.style.display = 'none';
    };

    buttonContainer.appendChild(updateButton);
    buttonContainer.appendChild(closeButton);

    notification.appendChild(message);
    notification.appendChild(buttonContainer);

    document.body.appendChild(notification);
  } else {
    notification.style.display = 'flex';
  }
}

// Apply the update by telling the service worker to skip waiting
function applyUpdate() {
  if (!registration || !registration.waiting) {
    console.warn('[SW Registration] ApplyUpdate called, but no waiting service worker found.');
    hideUpdateLoadingIndicator(); // Ensure loading is hidden if somehow shown
    // Optionally re-show notification or inform user
    return;
  }

  console.log('[SW Registration] Applying update - sending SKIP_WAITING message.');

  // Hide the notification
  const notification = document.getElementById('sw-update-notification');
  if (notification) {
    notification.style.display = 'none';
  }

  // Show loading indicator
  showUpdateLoadingIndicator();

  // Send message to service worker to skip waiting
  registration.waiting.postMessage({ type: 'SKIP_WAITING' });

  // Instead of a hard timeout/reload, let the 'controllerchange' event handle the reload.
  // Add a failsafe timeout just to hide the loading indicator if 'controllerchange' never fires.
  setTimeout(() => {
    if (updateLoadingIndicator) { // Check if indicator is still displayed
       console.warn(`[SW Registration] Update process seems stalled after ${UPDATE_TIMEOUT}ms. Hiding loading indicator.`);
       hideUpdateLoadingIndicator();
       // Optionally: Show notification again or display a message like "Update failed to apply automatically. Please refresh."
       showUpdateNotification(); // Re-show prompt
    }
  }, UPDATE_TIMEOUT);
}

// Check for updates manually
function checkForUpdates() {
  if (!registration) {
    console.log('[SW Registration] Manual update check skipped: No registration.');
    return;
  }

  console.log('[SW Registration] Checking for Service Worker updates manually...');
  registration.update()
    .then((reg) => {
      console.log('[SW Registration] Manual update check completed.');
      // Note: 'updatefound' event should handle the rest if an update is found.
      // We could check reg.waiting here too as a backup, but 'updatefound' is preferred.
    })
    .catch((error) => {
      console.error('[SW Registration] Error checking for Service Worker updates:', error);
    });
}

// Show a loading indicator during update
function showUpdateLoadingIndicator() {
  if (updateLoadingIndicator) return; // Already shown

  ensureSpinnerStyle(); // Make sure the CSS animation is present

  updateLoadingIndicator = document.createElement('div');
  updateLoadingIndicator.id = 'sw-update-loading';
  updateLoadingIndicator.style.position = 'fixed';
  updateLoadingIndicator.style.top = '0';
  updateLoadingIndicator.style.left = '0';
  updateLoadingIndicator.style.width = '100%';
  updateLoadingIndicator.style.height = '100%';
  updateLoadingIndicator.style.backgroundColor = 'rgba(0, 0, 0, 0.7)';
  updateLoadingIndicator.style.display = 'flex';
  updateLoadingIndicator.style.flexDirection = 'column';
  updateLoadingIndicator.style.alignItems = 'center';
  updateLoadingIndicator.style.justifyContent = 'center';
  updateLoadingIndicator.style.zIndex = '10000';

  const spinner = document.createElement('div');
  spinner.style.width = '50px';
  spinner.style.height = '50px';
  spinner.style.border = '5px solid #f3f3f3';
  spinner.style.borderTop = '5px solid #4CAF50';
  spinner.style.borderRadius = '50%';
  spinner.style.animation = 'spin 1s linear infinite';

  const text = document.createElement('div');
  text.textContent = 'Updating application...';
  text.style.color = 'white';
  text.style.marginTop = '20px';
  text.style.fontFamily = 'Arial, sans-serif';

  updateLoadingIndicator.appendChild(spinner);
  updateLoadingIndicator.appendChild(text);
  document.body.appendChild(updateLoadingIndicator);
}

// Hide and remove the loading indicator
function hideUpdateLoadingIndicator() {
    if (updateLoadingIndicator) {
        updateLoadingIndicator.remove();
        updateLoadingIndicator = null;
    }
    // Clean up the style tag if it exists and no other spinners are needed
    // (Assuming this is the only place using this specific animation) 
    const styleTag = document.head.querySelector('style[data-spin-animation]');
    if (styleTag) {
         // styleTag.remove(); // Keep the style tag for now, maybe other things use it?
    }
}

// Helper to add the spinner animation style only once
function ensureSpinnerStyle() {
    if (!document.head.querySelector('style[data-spin-animation]')) {
        const style = document.createElement('style');
        style.setAttribute('data-spin-animation', 'true'); // Mark the style tag
        style.textContent = '@keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }';
        document.head.appendChild(style);
    }
}

// Expose functions to Flutter (or globally) if needed
window.serviceWorkerManager = {
  checkForUpdates: checkForUpdates,
  applyUpdate: applyUpdate
};

// Initialize
registerServiceWorker();
