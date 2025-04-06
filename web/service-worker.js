// Service Worker for Vanishing Tic Tac Toe
const CACHE_NAME = 'vanishing-tictactoe-cache-v18';
const CACHE_VERSION = '2025.04.06.5989';
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
  'assets/packages/cupertino_icons/assets/CupertinoIcons.ttf',
  'favicon.png',
  'favicon_io/apple-touch-icon.png',
  'favicon_io/favicon.ico',
  'icons/icons.css',
  './' // Cache the root/entry point
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
  
  // Don't skipWaiting here - let the user control when to update
  // self.skipWaiting();
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
  
  // Only claim clients when it's an update, not on initial installation
  // This prevents the controllerchange event from firing on first load
  if (self.registration?.active) {
    console.log('[Service Worker] Claiming clients as this appears to be an update');
    self.clients.claim();
  } else {
    console.log('[Service Worker] Not claiming clients on initial installation');
  }
});

// Fetch event - serve from cache if available, otherwise fetch from network
self.addEventListener('fetch', (event) => {
  // Skip cross-origin requests, like those for Google Fonts or other CDNs
  if (!event.request.url.startsWith(self.location.origin)) {
    // Let the browser handle non-origin requests normally
    return;
  }
  
  // For HTML navigation requests (like clicking on a link), always go to network first
  // This ensures users always get the latest version of the app shell
  if (event.request.mode === 'navigate') {
    event.respondWith(
      fetch(event.request).catch(() => {
        return caches.match(OFFLINE_URL);
      })
    );
    return;
  }
  
  // For all other requests, try the cache first, then fall back to the network
  event.respondWith(
    caches.match(event.request).then((cachedResponse) => {
      if (cachedResponse) {
        // Return the cached response
        return cachedResponse;
      }
      
      // If not in cache, fetch from network
      return fetch(event.request).then((response) => {
        // Don't cache responses that aren't successful
        if (!response || response.status !== 200 || response.type !== 'basic') {
          return response;
        }
        
        // Clone the response since it can only be consumed once
        const responseToCache = response.clone();
        
        // Cache the fetched resource
        caches.open(CACHE_NAME).then((cache) => {
          cache.put(event.request, responseToCache);
        }).catch(error => {
          console.error('[Service Worker] Cache put error:', error, 'Request:', event.request.url);
        });
        
        return response;
      }).catch((error) => {
        console.warn('[Service Worker] Network fetch failed:', error, 'Request:', event.request.url);
        // If fetch fails (e.g., offline), return the offline page for navigation requests
        if (event.request.mode === 'navigate') {
          return caches.match(OFFLINE_URL);
        }
        // For other failed requests, let the browser handle the error
        // Returning undefined here allows the browser's default fetch failure handling
        // Linter warning (redundant jump) ignored as this explicit return clarifies intent.
        return; // Explicitly return undefined for non-navigation fetch errors
      });
    })
  );
});

// Listen for messages from the main thread
self.addEventListener('message', (event) => {
  // Verify the origin of the message for security
  if (event.origin !== self.location.origin) {
    console.warn(`[Service Worker] Message ignored from unexpected origin: ${event.origin}`);
    return;
  }

  if (event.data && event.data.type === 'SKIP_WAITING') {
    console.log('[Service Worker] Received SKIP_WAITING message');
    self.skipWaiting();
  }
  
  if (event.data && event.data.type === 'CHECK_VERSION') {
    // Send the current version back to the client
    event.ports[0].postMessage({
      version: CACHE_VERSION,
      cacheName: CACHE_NAME
    });
  }
});

// Handle update found event
self.addEventListener('updatefound', () => {
  console.log('[Service Worker] Update found');
});
