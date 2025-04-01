// Service Worker for Vanishing Tic Tac Toe
const CACHE_NAME = 'vanishing-tictactoe-cache-v6';
const OFFLINE_URL = 'index.html';

// Files to cache for offline use
const RESOURCES_TO_CACHE = [
  'index.html',
  'flutter.js',
  'main.dart.js',
  'manifest.json',
  'assets/fonts/MaterialIcons-Regular.ttf',
  'assets/AssetManifest.json',
  'assets/FontManifest.json',
  'favicon.png',
  'favicon_io/apple-touch-icon.png',
  'favicon_io/favicon.ico',
  'icons/icons.css'
];

// Install event - cache resources
self.addEventListener('install', (event) => {
  console.log('[Service Worker] Install');
  
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      console.log('[Service Worker] Caching resources');
      return cache.addAll(RESOURCES_TO_CACHE);
    })
  );
  
  // Activate the service worker immediately
  self.skipWaiting();
});

// Activate event - clean up old caches
self.addEventListener('activate', (event) => {
  console.log('[Service Worker] Activate');
  
  event.waitUntil(
    caches.keys().then((keyList) => {
      return Promise.all(keyList.map((key) => {
        if (key !== CACHE_NAME) {
          console.log('[Service Worker] Removing old cache', key);
          return caches.delete(key);
        }
      }));
    })
  );
  
  // Ensure the service worker takes control immediately
  self.clients.claim();
});

// Fetch event - serve from cache if available, otherwise fetch from network
self.addEventListener('fetch', (event) => {
  // Skip cross-origin requests
  if (!event.request.url.startsWith(self.location.origin)) {
    return;
  }
  
  event.respondWith(
    caches.match(event.request).then((cachedResponse) => {
      if (cachedResponse) {
        return cachedResponse;
      }
      
      return fetch(event.request).then((response) => {
        // Don't cache responses that aren't successful
        if (!response || response.status !== 200 || response.type !== 'basic') {
          return response;
        }
        
        // Clone the response since it can only be consumed once
        const responseToCache = response.clone();
        
        caches.open(CACHE_NAME).then((cache) => {
          cache.put(event.request, responseToCache);
        });
        
        return response;
      }).catch(() => {
        // If fetch fails (e.g., offline), return the offline page
        if (event.request.mode === 'navigate') {
          return caches.match(OFFLINE_URL);
        }
      });
    })
  );
});

// Listen for messages from the main thread
self.addEventListener('message', (event) => {
  if (event.data && event.data.type === 'SKIP_WAITING') {
    self.skipWaiting();
  }
  
  if (event.data && event.data.type === 'CHECK_VERSION') {
    // Send the current version back to the client
    const currentVersion = self.CACHE_VERSION || '1.0.0';
    event.ports[0].postMessage({
      version: currentVersion
    });
  }
});

// Handle update found event
self.addEventListener('updatefound', () => {
  console.log('[Service Worker] Update found');
});
