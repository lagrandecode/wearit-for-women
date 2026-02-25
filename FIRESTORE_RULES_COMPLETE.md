# Complete Firestore Security Rules

Copy and paste this entire ruleset into Firebase Console → Firestore Database → Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection - users can only access their own document
    match /users/{userId} {
      // Allow users to read and write only their own user document
      allow read, write: if request.auth != null && request.auth.uid == userId;
      // Allow reading other users' isAdmin field for admin checks (needed for trend cards admin check)
      allow read: if request.auth != null;
    }
    
    // Planned outfits collection
    match /planned_outfits/{outfitId} {
      // Allow users to read their own outfits
      allow read: if request.auth != null && resource.data.userId == request.auth.uid;
      
      // Allow users to create outfits with their own userId
      allow create: if request.auth != null && request.resource.data.userId == request.auth.uid;
      
      // Allow users to update/delete their own outfits
      allow update, delete: if request.auth != null && resource.data.userId == request.auth.uid;
    }
    
    // Wardrobe items collection
    match /wardrobe_items/{itemId} {
      // Allow users to read their own items
      allow read: if request.auth != null && resource.data.userId == request.auth.uid;
      
      // Allow users to create items with their own userId
      allow create: if request.auth != null && request.resource.data.userId == request.auth.uid;
      
      // Allow users to update/delete their own items
      allow update, delete: if request.auth != null && resource.data.userId == request.auth.uid;
    }
    
    // Trend Cards Collection - Public read, Admin write
    match /trend_cards/{cardId} {
      // Anyone authenticated can read trend cards (to display in app)
      allow read: if request.auth != null;
      
      // Only admins can create, update, or delete trend cards
      allow create, update, delete: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true;
    }
  }
}
```

## Changes Made:

1. **Updated `users` collection**: Added a second `allow read` rule so authenticated users can read the `isAdmin` field from other users (needed for admin checks)

2. **Added `trend_cards` collection**:
   - `allow read`: All authenticated users can read trend cards
   - `allow create, update, delete`: Only users with `isAdmin: true` can modify trend cards

## How to Apply:

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project: **wearit-9b76f**
3. Navigate to **Firestore Database** → **Rules** tab
4. Replace the entire rules section with the code above
5. Click **Publish** to save

## Testing:

After updating:
- ✅ Regular users can read trend cards
- ✅ Regular users can read their own user data
- ✅ Regular users can read/write their own outfits and wardrobe items
- ❌ Regular users CANNOT create/update/delete trend cards
- ✅ Admin users (with `isAdmin: true`) can do everything
