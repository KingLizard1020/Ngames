# Firestore Security Rules

- Only authenticated users can read/write their own user data.
- High scores are readable by anyone, but only the user can write their own score.
- Messages are only readable/writable by the sender.
- All other access is denied by default.

**To deploy these rules:**

1. Install the Firebase CLI if you haven't already:
   ```sh
   npm install -g firebase-tools
   ```
2. Log in to Firebase:
   ```sh
   firebase login
   ```
3. Deploy the rules:
   ```sh
   firebase deploy --only firestore:rules
   ```

**Review and adjust rules as needed for your app's requirements.**
