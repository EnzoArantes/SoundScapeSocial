# SoundScapeSocial

> A SwiftUI iOS app that lets you share and react to friends’ music in real time.

![SoundScapeSocial Screenshot](docs/screenshot.png)

---

## 🚀 Overview

SoundScapeSocial connects your Spotify account and Firebase backend so you can:
- **Login** with email/password (Firebase Auth) or Spotify (Spotify iOS SDK).
- **Fetch & share** what you’re currently listening to.
- **Discover** new tracks via a Tinder-style swipe deck (Spotify Search API).
- **Follow friends** to see their shared tracks live.
- **React** to friends’ songs with 👍, 👎 or 🔥 emojis (and see their reactions in your feed).
- **Save favorites** both locally and to your Spotify “Liked Songs” library.

---

## 🎯 Key Features

| Feature                  | Tech                                 |
| ------------------------ | ------------------------------------ |
| Authentication           | Firebase Auth (Email + Spotify SSO) |
| Real-time data sync      | Cloud Firestore                      |
| Spotify integration      | Spotify iOS SDK + Web API            |
| Declarative UI           | SwiftUI + MVVM + Combine             |
| Gesture-driven discovery | Custom `SwipeCardView`               |
| Reactions system         | Firestore sub-collections            |
| Favorites syncing        | Firestore + Spotify “Save Track” API |

---

## 🛠️ Tech Stack

- **Language:** Swift 5, SwiftUI  
- **State:** Combine, `@StateObject`/`@EnvironmentObject`  
- **Backend:** Firebase (Auth, Firestore)  
- **Music API:** Spotify iOS SDK (Authentication) + Web API (Playback endpoints)  

---

## 📂 Project Structure

