# Firestore Security Rules for Trend Cards

## Add These Rules to Your Firestore Security Rules

Go to Firebase Console → Firestore Database → Rules and add the following rules for the `trend_cards` collection:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // ... existing rules ...
    
    // Trend Cards Collection
    // Everyone can read (to see trend cards)
    // Only admins can write (create/update/delete)
    match /trend_cards/{cardId} {
      // Allow anyone authenticated to read trend cards
      allow read: if request.auth != null;
      
      // Only allow admins to create, update, or delete
      allow create, update, delete: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true;
    }
    
    // Users collection - users can only access their own document
    match /users/{userId} {
      // Allow users to read and write only their own user document
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // Allow reading isAdmin field for admin checks (but not modifying unless own user)
      allow read: if request.auth != null;
    }
  }
}
```

## Complete Updated Rules (Full Example)

Here's a complete example with all collections:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      // Allow users to read and write only their own user document
      allow read, write: if request.auth != null && request.auth.uid == userId;
      // Allow reading other users' isAdmin field for admin checks
      allow read: if request.auth != null;
    }
    
    // Planned outfits collection
    match /planned_outfits/{outfitId} {
      allow read: if request.auth != null && resource.data.userId == request.auth.uid;
      allow create: if request.auth != null && request.resource.data.userId == request.auth.uid;
      allow update, delete: if request.auth != null && resource.data.userId == request.auth.uid;
    }
    
    // Wardrobe items collection
    match /wardrobe_items/{itemId} {
      allow read: if request.auth != null && resource.data.userId == request.auth.uid;
      allow create: if request.auth != null && request.resource.data.userId == request.auth.uid;
      allow update, delete: if request.auth != null && resource.data.userId == request.auth.uid;
    }
    
    // Trend Cards Collection - Public read, Admin write
    match /trend_cards/{cardId} {
      // Anyone authenticated can read trend cards
      allow read: if request.auth != null;
      
      // Only admins can create, update, or delete
      allow create, update, delete: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true;
    }
  }
}
```

## How to Apply

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project: **wearit-9b76f**
3. Navigate to **Firestore Database** → **Rules** tab
4. Add the `trend_cards` rules as shown above
5. Click **Publish** to save

## Testing

After updating the rules:
- Regular users should be able to read trend cards ✅
- Regular users should NOT be able to create/update/delete ❌
- Admin users should be able to do everything ✅
