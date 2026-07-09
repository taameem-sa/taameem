# Taameem Cloud Functions

This folder contains server-side logic for geographic push notifications.

## Implemented function
- notifyUsersByScope
  - Trigger: Firestore document create on taameems/{taameemId}
  - Region: me-central1
  - Behavior:
    - If allKingdom is true: notify all users with valid fcm tokens.
    - Else: notify only users whose stored default location falls inside the taameem scope.

## Expected user document shape
The function reads users collection with these optional fields:
- fcmTokens: string[]
- fcmToken: string
- defaultLocationLat: number
- defaultLocationLng: number
- lastKnownLat: number
- lastKnownLng: number

## Deploy
1. Install dependencies:
   npm install
2. Deploy only functions:
   npm run deploy

## Notes
- For production scale, move to geohash-indexed query instead of scanning all users.
- Keep fcmTokens updated from the mobile app on login/refresh.
