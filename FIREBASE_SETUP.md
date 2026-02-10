# Firebase Setup Guide for Wearit App

This guide will help you configure Firebase to save planned outfits data.

## Required Firebase Services

1. **Firestore Database** - Stores outfit data
2. **Firebase Storage** - Stores outfit images
3. **Firebase Authentication** - Already configured ✅

## Step 1: Configure Firestore Security Rules

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project: **wearit-9b76f**
3. Navigate to **Firestore Database** → **Rules** tab
4. Replace the default rules with the following:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
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
  }
}
```

5. Click **Publish** to save the rules

## Step 2: Configure Firebase Storage Rules

1. Navigate to **Storage** → **Rules** tab
2. Replace the default rules with the following:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Allow users to upload/read/delete their own outfit images
    match /{userId}/outfits/{allPaths=**} {
      // Allow read if user is authenticated
      allow read: if request.auth != null;
      
      // Allow write (upload/delete) only if user owns the folder
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Allow users to upload/read/delete their own wardrobe images
    match /{userId}/wardrobe/{allPaths=**} {
      // Allow read if user is authenticated
      allow read: if request.auth != null;
      
      // Allow write (upload/delete) only if user owns the folder
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

3. Click **Publish** to save the rules

## Step 3: Verify Database Mode

1. In **Firestore Database**, check that you're in **Native mode** (not Datastore mode)
2. If you see "Start collection" button, the database is ready ✅

## Step 4: Test the Setup

After configuring the rules, test by:

1. **Run your app** and sign in with a user account
2. **Create a planned outfit** with images
3. **Check Firestore Console**:
   - Go to **Firestore Database** → **Data** tab
   - You should see a collection named `planned_outfits`
   - Each document should have:
     - `userId` (string)
     - `date` (timestamp)
     - `timeHour` (number)
     - `timeMinute` (number)
     - `imageUrls` (array of strings)
     - `notificationId` (number)
     - `createdAt` (timestamp)
     - `updatedAt` (timestamp)

4. **Check Firebase Storage**:
   - Go to **Storage** → **Files** tab
   - You should see folders like: `{userId}/outfits/`
   - Images should be stored inside these folders

## Data Structure

### Firestore Collections

#### `planned_outfits`

Each document structure:
```json
{
  "userId": "user123",
  "date": Timestamp(2026, 2, 7),
  "timeHour": 14,
  "timeMinute": 30,
  "imageUrls": [
    "https://firebasestorage.googleapis.com/...",
    "https://firebasestorage.googleapis.com/..."
  ],
  "notificationId": 1234567890,
  "createdAt": Timestamp(...),
  "updatedAt": Timestamp(...)
}
```

#### `wardrobe_items`

Each document structure:
```json
{
  "userId": "user123",
  "imageUrl": "https://firebasestorage.googleapis.com/...",
  "category": "clothes",
  "price": 49.99,
  "createdAt": Timestamp(...),
  "updatedAt": Timestamp(...)
}
```

### Storage Paths

#### Outfits: `{userId}/outfits/{timestamp}_{filename}`
Example:
```
user123/outfits/1707321600000_image.jpg
```

#### Wardrobe: `{userId}/wardrobe/{timestamp}_{filename}`
Example:
```
user123/wardrobe/1707321600000_item.jpg
```

## Troubleshooting

### Error: "Missing or insufficient permissions"
- **Solution**: Check that Firestore rules are published and user is authenticated
- Verify the user ID matches in the document

### Error: "Permission denied" in Storage
- **Solution**: Check Storage rules are published
- Verify the folder path matches `{userId}/outfits/`

### Data not appearing in Firestore
- Check that user is signed in
- Verify rules allow create operations
- Check console logs for errors

### Images not uploading
- Check Storage rules allow write operations
- Verify user has write permissions
- Check network connectivity

## Security Notes

⚠️ **Important**: The rules above allow users to:
- ✅ Read/write only their own data
- ✅ Upload/delete only their own images
- ❌ Cannot access other users' data
- ❌ Cannot modify other users' images

This ensures data privacy and security.

## Next Steps

Once configured, your app will automatically:
1. Save outfits to Firestore when created
2. Upload images to Firebase Storage
3. Sync data across devices when user signs in
4. Load historical outfits from Firebase

No additional code changes needed! 🎉
