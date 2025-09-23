# Backend Setup

## Option A — Firebase
- Create project; enable Auth (Apple), Firestore, Storage, FCM.
- Add iOS app bundle ID; download `GoogleService-Info.plist`.
- Write Firestore Rules enforcing role-based access.
- Collections: users, assessments, exercises, conditions, guidance, threads, messages, assignments.

## Option B — Supabase
- Create project; enable Apple sign-in via GoTrue.
- Define tables with RLS policies.
- Storage bucket for exercise videos.
- Realtime for messaging.
