import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vanishingtictactoe/core/exceptions/friend_service_exception.dart';
import 'dart:developer' as developer;

class FriendService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Getters to access Firebase instances
  FirebaseFirestore get firestore => _firestore;
  FirebaseAuth get auth => _auth;

  // Helper method to get user data
  Future<Map<String, dynamic>?> _getUserData(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists) return null;
    return doc.data();
  }

  // Cache for friend data to improve performance
  final Map<String, Map<String, dynamic>> _friendsCache = {};
  final Map<String, DateTime> _friendsCacheTimestamp = {};
  final Duration _cacheExpiration = Duration(minutes: 5);
  
  // Get current user's friends with optimized loading
  Stream<List<Map<String, dynamic>>> getFriends() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('friends')
        .snapshots()
        .handleError((error) {
          developer.log('Error fetching friends: $error', error: error);
          return [];
        })
        .asyncMap((snapshot) async {
          final friendsList = <Map<String, dynamic>>[];
          final friendIds = snapshot.docs.map((doc) => doc.id).toList();
          
          // Batch fetch user data for all friends at once
          final userDataMap = await _batchGetUserData(friendIds);
          
          // Batch fetch online status for all friends
          final statusMap = await _batchCheckFriendOnlineStatus(friendIds);
          
          for (final doc in snapshot.docs) {
            final friendId = doc.id;
            final userData = userDataMap[friendId];
            final status = statusMap[friendId];
            
            if (userData != null) {
              final friendData = {
                'id': friendId,
                ...doc.data(),
                ...userData,  // Include all user data including userLevel
                'isOnline': status?['isOnline'] ?? false,
                'lastOnline': status?['lastOnline'],
              };
              
              // Update cache
              _friendsCache[friendId] = friendData;
              _friendsCacheTimestamp[friendId] = DateTime.now();
              
              friendsList.add(friendData);
            }
          }
          
          return friendsList;
        });
  }

  // Batch get user data for multiple friends at once
  Future<Map<String, Map<String, dynamic>>> _batchGetUserData(List<String> userIds) async {
    final result = <String, Map<String, dynamic>>{};
    final idsToFetch = <String>[];
    
    // Check cache first
    for (final userId in userIds) {
      if (_friendsCache.containsKey(userId) && 
          _friendsCacheTimestamp.containsKey(userId) &&
          DateTime.now().difference(_friendsCacheTimestamp[userId]!) < _cacheExpiration) {
        // Use cached data if it's not expired
        result[userId] = _friendsCache[userId]!;
      } else {
        idsToFetch.add(userId);
      }
    }
    
    if (idsToFetch.isEmpty) return result;
    
    try {
      // Fetch data in batches of 10 to avoid overloading Firestore
      for (int i = 0; i < idsToFetch.length; i += 10) {
        final batchIds = idsToFetch.sublist(
          i, i + 10 > idsToFetch.length ? idsToFetch.length : i + 10);
        
        final batchDocs = await Future.wait(
          batchIds.map((id) => _firestore.collection('users').doc(id).get())
        );
        
        for (final doc in batchDocs) {
          if (doc.exists && doc.data() != null) {
            result[doc.id] = doc.data()!;
          }
        }
      }
      
      return result;
    } catch (e) {
      developer.log('Error batch fetching user data: $e', error: e);
      return result;
    }
  }
  
  // Check a friend's online status
  Future<Map<String, dynamic>> _checkFriendOnlineStatus(String friendId) async {
    try {
      final presenceDoc = await _firestore
          .collection('users')
          .doc(friendId)
          .collection('presence')
          .doc('status')
          .get();
      
      if (presenceDoc.exists) {
        final presenceData = presenceDoc.data();
        if (presenceData != null) {
          final lastOnline = presenceData['lastOnline'] as Timestamp?;
          final isOnline = presenceData['isOnline'] as bool? ?? false;
          final timestamp = presenceData['timestamp'] as int?;
          
          // Check if the timestamp is recent (within last 60 seconds)
          final isRecent = timestamp != null && 
              DateTime.now().millisecondsSinceEpoch - timestamp < 60000;
          
          return {
            'isOnline': isOnline && isRecent,
            'lastOnline': lastOnline,
          };
        }
      }
      
      return {
        'isOnline': false,
        'lastOnline': null,
      };
    } catch (e) {
      developer.log('Error checking friend status: $e', error: e);
      return {
        'isOnline': false,
        'lastOnline': null,
      };
    }
  }
  
  // Batch check online status for multiple friends at once
  Future<Map<String, Map<String, dynamic>>> _batchCheckFriendOnlineStatus(List<String> friendIds) async {
    final result = <String, Map<String, dynamic>>{};
    
    try {
      // Fetch status in batches of 10 to avoid overloading Firestore
      for (int i = 0; i < friendIds.length; i += 10) {
        final batchIds = friendIds.sublist(
          i, i + 10 > friendIds.length ? friendIds.length : i + 10);
        
        final batchDocs = await Future.wait(
          batchIds.map((id) => _firestore
              .collection('users')
              .doc(id)
              .collection('presence')
              .doc('status')
              .get())
        );
        
        for (int j = 0; j < batchDocs.length; j++) {
          final doc = batchDocs[j];
          final friendId = batchIds[j];
          
          if (doc.exists && doc.data() != null) {
            final presenceData = doc.data()!;
            final lastOnline = presenceData['lastOnline'] as Timestamp?;
            final isOnline = presenceData['isOnline'] as bool? ?? false;
            final timestamp = presenceData['timestamp'] as int?;
            
            // Check if the timestamp is recent (within last 60 seconds)
            final isRecent = timestamp != null && 
                DateTime.now().millisecondsSinceEpoch - timestamp < 60000;
            
            result[friendId] = {
              'isOnline': isOnline && isRecent,
              'lastOnline': lastOnline,
            };
          } else {
            result[friendId] = {
              'isOnline': false,
              'lastOnline': null,
            };
          }
        }
      }
      
      return result;
    } catch (e) {
      developer.log('Error batch checking friend status: $e', error: e);
      return result;
    }
  }
  
  // Refresh online status for a list of friends
  Future<List<Map<String, dynamic>>> refreshFriendsStatus(List<Map<String, dynamic>> friends) async {
    final updatedFriends = <Map<String, dynamic>>[];
    
    for (final friend in friends) {
      final friendId = friend['id'] as String;
      final status = await _checkFriendOnlineStatus(friendId);
      
      updatedFriends.add({
        ...friend,
        'isOnline': status['isOnline'],
        'lastOnline': status['lastOnline'],
      });
    }
    
    return updatedFriends;
  }

  Future<List<Map<String, dynamic>>> searchUsers(String username) async {
  if (username.isEmpty) return [];

  final currentUserId = _auth.currentUser?.uid;
  if (currentUserId == null) return [];

  try {
    // Step 1: Search for users whose username starts with the search term
    final querySnapshot = await _firestore
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: username)
        .where('username', isLessThan: '${username}z')
        .get();

    // Step 2: Get the current user's friends list
    final friendsSnapshot = await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('friends')
        .get();

    // Extract friend IDs from the friends list
    final friendIds = friendsSnapshot.docs.map((doc) => doc.id).toList();

    // Step 3: Filter out users who are already friends
    return querySnapshot.docs
        .where((doc) => doc.id != currentUserId) // Exclude current user
        .where((doc) => !friendIds.contains(doc.id)) // Exclude friends
        .map((doc) => {
              'id': doc.id,
              'username': doc.data()['username'],
            })
        .toList();
  } catch (e) {
    developer.log('Error searching users: $e', error: e);
    throw FriendServiceException('Failed to search users: ${e.toString()}');
  }
}

  // Send friend request
  Future<void> sendFriendRequest(String targetUserId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) throw FriendServiceException('Not authenticated');
    if (targetUserId == currentUserId) throw FriendServiceException('Cannot send friend request to yourself');

    try {
      // Get current user's data
      final currentUserData = await _getUserData(currentUserId);
      if (currentUserData == null || currentUserData['username'] == null) {
        throw FriendServiceException('Current user data not found');
      }

      // Check if target user exists
      final targetUserDoc = await _firestore.collection('users').doc(targetUserId).get();
      if (!targetUserDoc.exists) {
        throw FriendServiceException('Target user not found');
      }

      // Check if a friend request already exists
      final existingRequest = await _firestore
          .collection('users')
          .doc(targetUserId)
          .collection('friendRequests')
          .doc(currentUserId)
          .get();

      if (existingRequest.exists) {
        throw FriendServiceException('Friend request already sent');
      }

      // Check if they are already friends
      final existingFriend = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('friends')
          .doc(targetUserId)
          .get();

      if (existingFriend.exists) {
        throw FriendServiceException('Already friends with this user');
      }

      // Add to target user's friend requests
      await _firestore
          .collection('users')
          .doc(targetUserId)
          .collection('friendRequests')
          .doc(currentUserId)
          .set({
        'username': currentUserData['username'],
        'senderId': currentUserId,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending'
      });

      developer.log('Friend request sent to $targetUserId');
    } catch (e) {
      developer.log('Failed to send friend request: $e', error: e);
      throw FriendServiceException('Failed to send friend request: ${e.toString()}');
    }
  }

  // Get friend requests
  Stream<List<Map<String, dynamic>>> getFriendRequests() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('friendRequests')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .handleError((error) {
          developer.log('Error fetching friend requests: $error', error: error);
          return [];
        })
        .map((snapshot) => snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  'senderId': doc.id,  // Ensure senderId is always present
                  ...doc.data()
                })
            .toList());
  }

  // Accept friend request
  Future<void> acceptFriendRequest(String senderId) async {
    if (senderId.isEmpty) throw FriendServiceException('Invalid sender ID');

    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) throw FriendServiceException('Not authenticated');

    try {
      // Get both users' data
      final senderData = await _getUserData(senderId);
      final currentUserData = await _getUserData(currentUserId);
      
      // Store usernames in separate variables for clarity
      final senderUsername = senderData?['username'];
      final currentUsername = currentUserData?['username'];

      if (senderData == null || currentUserData == null ||
          senderUsername == null || currentUsername == null) {
        throw FriendServiceException('Invalid user data');
      }

      // Verify the friend request exists
      final requestDoc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('friendRequests')
          .doc(senderId)
          .get();

      if (!requestDoc.exists) {
        throw FriendServiceException('Friend request not found');
      }

      final requestData = requestDoc.data();
      if (requestData == null || requestData['status'] != 'pending') {
        throw FriendServiceException('Invalid friend request status');
      }

      // Check if users have friendIds fields
      final currentUserDoc = await _firestore.collection('users').doc(currentUserId).get();
      final currentUserDocData = currentUserDoc.data() ?? {};
      
      final senderDoc = await _firestore.collection('users').doc(senderId).get();
      final senderDocData = senderDoc.data() ?? {};
      
      // Use a batch for better performance
      final batch = _firestore.batch();
      
      // 1. Delete the friend request
      final friendRequestRef = _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('friendRequests')
          .doc(senderId);
      batch.delete(friendRequestRef);
      
      // 2. Add the friend to current user's friends collection
      final currentUserFriendRef = _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('friends')
          .doc(senderId);
      batch.set(currentUserFriendRef, {
        'username': senderUsername,
        'addedAt': FieldValue.serverTimestamp(),
        'id': senderId,
      });
      
      // 3. Update current user's friendIds array
      final currentUserRef = _firestore.collection('users').doc(currentUserId);
      if (currentUserDocData.containsKey('friendIds')) {
        batch.update(currentUserRef, {
          'friendIds': FieldValue.arrayUnion([senderId]),
        });
      } else {
        batch.set(currentUserRef, {
          'friendIds': [senderId],
        }, SetOptions(merge: true));
      }
      
      // 4. Add current user to sender's friends collection
      final senderFriendRef = _firestore
          .collection('users')
          .doc(senderId)
          .collection('friends')
          .doc(currentUserId);
      batch.set(senderFriendRef, {
        'username': currentUsername,
        'addedAt': FieldValue.serverTimestamp(),
        'id': currentUserId,
      });
      
      // 5. Update sender's friendIds array
      final senderRef = _firestore.collection('users').doc(senderId);
      if (senderDocData.containsKey('friendIds')) {
        batch.update(senderRef, {
          'friendIds': FieldValue.arrayUnion([currentUserId]),
        });
      } else {
        batch.set(senderRef, {
          'friendIds': [currentUserId],
        }, SetOptions(merge: true));
      }
      
      // Commit the batch with a timeout
      await batch.commit().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw FriendServiceException('Friend request acceptance timed out. Please try again.');
        },
      );

      developer.log('Friend request accepted from $senderId');
    } catch (e) {
      developer.log('Failed to accept friend request: $e', error: e);
      
      // If the batch fails, try a fallback approach that focuses on the current user
      try {
        // Delete the friend request
        await _firestore
            .collection('users')
            .doc(currentUserId)
            .collection('friendRequests')
            .doc(senderId)
            .delete();
        
        // Get sender username - try multiple approaches to ensure we get it
        String? senderUsername;
        
        // First, try to get it from the friend request document
        try {
          final requestDoc = await _firestore
              .collection('users')
              .doc(currentUserId)
              .collection('friendRequests')
              .doc(senderId)
              .get();
              
          if (requestDoc.exists) {
            final data = requestDoc.data();
            senderUsername = data?['username'] as String?;
            developer.log('Got username from friend request: $senderUsername');
          }
        } catch (usernameError) {
          developer.log('Error getting username from friend request: $usernameError');
          // Continue to next approach
        }
        
        // If that fails, try to get it directly from the sender's user document
        if (senderUsername == null) {
          try {
            final senderDoc = await _firestore.collection('users').doc(senderId).get();
            if (senderDoc.exists) {
              senderUsername = senderDoc.data()?['username'] as String?;
              developer.log('Got username from user document: $senderUsername');
            }
          } catch (usernameError) {
            developer.log('Error getting username from user document: $usernameError');
            // Continue with null username
          }
        }
        
        // If we still don't have a username, use a placeholder but log the issue
        if (senderUsername == null) {
          developer.log('WARNING: Could not retrieve username for user $senderId');
          senderUsername = 'User $senderId';
        }
        
        // Add to current user's friends collection
        await _firestore
            .collection('users')
            .doc(currentUserId)
            .collection('friends')
            .doc(senderId)
            .set({
              'username': senderUsername,
              'addedAt': FieldValue.serverTimestamp(),
              'id': senderId,
            });
        
        // Update current user's friendIds
        await _firestore.collection('users').doc(currentUserId).update({
          'friendIds': FieldValue.arrayUnion([senderId]),
        });
        
        // Now also update the friend's lists
        
        // Get current user's username
        String? currentUsername;
        try {
          final currentUserDoc = await _firestore.collection('users').doc(currentUserId).get();
          if (currentUserDoc.exists) {
            currentUsername = currentUserDoc.data()?['username'] as String?;
          }
          
          if (currentUsername == null) {
            // Try to get it from the friend request
            final requestDoc = await _firestore
                .collection('users')
                .doc(senderId)
                .collection('friendRequests')
                .doc(currentUserId)
                .get();
                
            if (requestDoc.exists) {
              currentUsername = requestDoc.data()?['username'] as String?;
            }
          }
          
          // If we still don't have a username, use a placeholder
          currentUsername ??= 'User $currentUserId';
          
          // Add current user to friend's friends collection
          await _firestore
              .collection('users')
              .doc(senderId)
              .collection('friends')
              .doc(currentUserId)
              .set({
                'username': currentUsername,
                'addedAt': FieldValue.serverTimestamp(),
                'id': currentUserId,
              });
          
          // Update friend's friendIds array
          await _firestore.collection('users').doc(senderId).update({
            'friendIds': FieldValue.arrayUnion([currentUserId]),
          });
          
          developer.log('Fallback: Successfully updated both users\'s friend lists');
        } catch (friendUpdateError) {
          developer.log('Fallback: Could not update friend\'s lists: $friendUpdateError');
          developer.log('Fallback: Added friend to current user\'s lists only');
        }
      } catch (fallbackError) {
        // If even the fallback fails, throw the original error
        throw FriendServiceException('Failed to accept friend request: ${e.toString()}');
      }
    }
  }

  // Reject friend request
  Future<void> rejectFriendRequest(String senderId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) throw FriendServiceException('Not authenticated');

    try {
      // Since this is a simple operation, we don't need a full batch
      // But we'll add a timeout for consistency
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('friendRequests')
          .doc(senderId)
          .delete()
          .timeout(
            const Duration(seconds: 3),
            onTimeout: () {
              throw FriendServiceException('Friend request rejection timed out. Please try again.');
            },
          );

      developer.log('Friend request rejected and deleted from $senderId');
    } catch (e) {
      developer.log('Failed to reject friend request: $e', error: e);
      throw FriendServiceException('Failed to reject friend request: ${e.toString()}');
    }
  }

  // Delete friend
  Future<void> deleteFriend(String friendId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) throw FriendServiceException('Not authenticated');

    try {
      // Use a batch for better performance now that permissions are working
      final batch = _firestore.batch();

      // 1. Remove friend from current user's friends list
      final currentUserFriendRef = _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('friends')
          .doc(friendId);
      batch.delete(currentUserFriendRef);

      // 2. Update current user's friendIds array
      final currentUserRef = _firestore.collection('users').doc(currentUserId);
      batch.update(currentUserRef, {
        'friendIds': FieldValue.arrayRemove([friendId]),
      });

      // 3. Remove current user from friend's friends list
      final friendUserRef = _firestore
          .collection('users')
          .doc(friendId)
          .collection('friends')
          .doc(currentUserId);
      batch.delete(friendUserRef);

      // 4. Update friend's friendIds array
      final friendRef = _firestore.collection('users').doc(friendId);
      batch.update(friendRef, {
        'friendIds': FieldValue.arrayRemove([currentUserId]),
      });

      // Commit the batch with a timeout to prevent hanging
      await batch.commit().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw FriendServiceException('Friend deletion timed out. Please try again.');
        },
      );

      developer.log('Friend $friendId deleted successfully');
    } catch (e) {
      developer.log('Failed to delete friend: $e', error: e);
      
      // If the batch fails, try a fallback approach
      try {
        // First update current user's data
        await _firestore
            .collection('users')
            .doc(currentUserId)
            .collection('friends')
            .doc(friendId)
            .delete();
        
        await _firestore.collection('users').doc(currentUserId).update({
          'friendIds': FieldValue.arrayRemove([friendId]),
        });
        
        developer.log('Fallback: Removed friend from current user\'s lists');
        
        // Now also try to update the friend's lists
        try {
          // Remove current user from friend's friends list
          await _firestore
              .collection('users')
              .doc(friendId)
              .collection('friends')
              .doc(currentUserId)
              .delete();
          
          // Update friend's friendIds array
          await _firestore.collection('users').doc(friendId).update({
            'friendIds': FieldValue.arrayRemove([currentUserId]),
          });
          
          developer.log('Fallback: Successfully removed current user from friend\'s lists');
        } catch (friendUpdateError) {
          developer.log('Fallback: Could not update friend\'s lists: $friendUpdateError');
          developer.log('Fallback: Removed friend from current user\'s lists only');
        }
      } catch (fallbackError) {
        // If even the fallback fails, throw the original error
        throw FriendServiceException('Failed to delete friend: ${e.toString()}');
      }
    }
  }


  // Refresh friend statuses periodically with batch operations
  Future<void> refreshFriendStatuses() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;
      
      final friendsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('friends')
          .get();
      
      if (friendsSnapshot.docs.isEmpty) return;
      
      final friendIds = friendsSnapshot.docs.map((doc) => doc.id).toList();
      
      // Batch check online status for all friends at once
      final statusMap = await _batchCheckFriendOnlineStatus(friendIds);
      
      // Use batched writes to update friend statuses
      final batch = _firestore.batch();
      int batchCount = 0;
      
      for (final friendId in friendIds) {
        final status = statusMap[friendId];
        if (status != null) {
          // Update the friend document with latest status
          final friendRef = _firestore
              .collection('users')
              .doc(userId)
              .collection('friends')
              .doc(friendId);
              
          batch.update(friendRef, {
            'isOnline': status['isOnline'],
            'lastOnline': status['lastOnline'],
          });
          
          // Also update the cache
          if (_friendsCache.containsKey(friendId)) {
            _friendsCache[friendId]!['isOnline'] = status['isOnline'];
            _friendsCache[friendId]!['lastOnline'] = status['lastOnline'];
            _friendsCacheTimestamp[friendId] = DateTime.now();
          }
          
          batchCount++;
          
          // Firestore batches are limited to 500 operations
          if (batchCount >= 450) {
            await batch.commit();
            batchCount = 0;
          }
        }
      }
      
      // Commit any remaining operations
      if (batchCount > 0) {
        await batch.commit();
      }
      
      developer.log('Friend statuses refreshed successfully in batch');
    } catch (e) {
      developer.log('Error refreshing friend statuses: $e', error: e);
      // Don't throw here as this is a background operation
    }
  }
  
  // Get friend profile data with caching
  Future<Map<String, dynamic>> getFriendProfile(String friendId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      throw FriendServiceException('Not authenticated');
    }
    
    try {
      // Check cache first
      if (_friendsCache.containsKey(friendId) && 
          _friendsCacheTimestamp.containsKey(friendId) &&
          DateTime.now().difference(_friendsCacheTimestamp[friendId]!) < _cacheExpiration) {
        // Use cached data if it's not expired, but refresh status in background
        final cachedData = _friendsCache[friendId]!;
        
        // Refresh status in background without waiting
        _checkFriendOnlineStatus(friendId).then((status) {
          if (_friendsCache.containsKey(friendId)) {
            _friendsCache[friendId]!['isOnline'] = status['isOnline'];
            _friendsCache[friendId]!['lastOnline'] = status['lastOnline'];
          }
        }).catchError((e) {
          // Ignore errors in background refresh
          developer.log('Background status refresh error: $e', error: e);
        });
        
        return cachedData;
      }
      
      // First check if they are actually friends
      final friendDoc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('friends')
          .doc(friendId)
          .get();
          
      if (!friendDoc.exists) {
        throw FriendServiceException('User is not in your friends list');
      }
      
      // Get the friend's user data
      final userData = await _getUserData(friendId);
      if (userData == null) {
        throw FriendServiceException('Friend data not found');
      }
      
      // Get online status
      final status = await _checkFriendOnlineStatus(friendId);
      
      // Combine all data
      final friendData = {
        'id': friendId,
        ...friendDoc.data() ?? {},
        ...userData,
        'isOnline': status['isOnline'],
        'lastOnline': status['lastOnline'],
      };
      
      // Update cache
      _friendsCache[friendId] = friendData;
      _friendsCacheTimestamp[friendId] = DateTime.now();
      
      return friendData;
    } catch (e) {
      developer.log('Error getting friend profile: $e', error: e);
      throw FriendServiceException('Failed to get friend profile: ${e.toString()}');
    }
  }
  
}
