// Service Worker Registration and Update Management
// This script handles service worker registration, updates, and user notifications

// Configuration
const SERVICE_WORKER_URL = 'service-worker.js';
const CHECK_INTERVAL = 60 * 60 * 1000; // Check for updates every hour

// State
let updateAvailable = false;
let registration = null;

// Register the service worker
function registerServiceWorker() {
  if ('serviceWorker' in navigator) {
    window.addEventListener('load', () => {
      navigator.serviceWorker.register(SERVICE_WORKER_URL)
        .then((reg) => {
          console.log('Service Worker registered with scope:', reg.scope);
          registration = reg;
          
          // Check if there's a waiting service worker
          if (reg.waiting) {
            updateReady(reg.waiting);
            return;
          }
          
          // Check if there's an installing service worker
          if (reg.installing) {
            trackInstallation(reg.installing);
            return;
          }
          
          // Listen for new service workers
          reg.addEventListener('updatefound', () => {
            trackInstallation(reg.installing);
          });
          
          // Set up periodic update checks
          setInterval(() => checkForUpdates(), CHECK_INTERVAL);
        })
        .catch((error) => {
          console.error('Service Worker registration failed:', error);
        });
        
      // Detect controller change
      navigator.serviceWorker.addEventListener('controllerchange', () => {
        if (updateAvailable) {
          console.log('New version activated!');
          // Reload the page to ensure the new version is used
          window.location.reload();
        }
      });
    });
  } else {
    console.log('Service Workers not supported in this browser');
  }
}

// Track the installation state of a service worker
function trackInstallation(worker) {
  worker.addEventListener('statechange', () => {
    if (worker.state === 'installed') {
      if (navigator.serviceWorker.controller) {
        // There is an existing controller, so this is an update
        updateReady(worker);
      } else {
        // This is a new installation
        console.log('Service Worker installed for the first time');
      }
    }
  });
}

// Handle an update-ready service worker
function updateReady(worker) {
  updateAvailable = true;
  
  // Notify the user about the update
  showUpdateNotification();
}

// Show a notification to the user about the available update
function showUpdateNotification() {
  // Create notification element if it doesn't exist
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
    return;
  }
  
  // Send message to service worker to skip waiting
  registration.waiting.postMessage({ type: 'SKIP_WAITING' });
}

// Check for updates manually
function checkForUpdates() {
  if (!registration) {
    return;
  }
  
  registration.update()
    .then(() => {
      console.log('Checked for Service Worker updates');
    })
    .catch((error) => {
      console.error('Error checking for Service Worker updates:', error);
    });
}

// Expose functions to Flutter
window.serviceWorkerManager = {
  checkForUpdates: checkForUpdates,
  applyUpdate: applyUpdate
};

// Initialize
registerServiceWorker();
