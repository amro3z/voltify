# 📱 Voltify – Smart Charging Alarm & Overlay App  

Voltify is a Flutter-powered mobile application that helps you **monitor your device’s charging state** and notifies you when the power comes back.  
It combines **beautiful UI animations**, **real-time battery monitoring**, and **custom background services** to ensure you never miss a charging event again.  
It’s especially useful during **power outages** – you’ll instantly know when the electricity is restored so you can plug in your device.  


---

## ✨ Features  
- 🔋 **Battery Monitoring** – Live updates of your device’s charging level & status.  
- ⏰ **Smart Alarm** – Loud ringtone + vibration notification when power is restored.  
- 🪟 **System Overlay** – Floating overlay window that shows charging alerts even outside the app.  
- 📊 **Visual Dashboard** – Modern UI with Lottie animations and circular battery indicators.  
- ⚡ **Background Service** – Works even when the app is closed (using WorkManager).  

---

## 📷 Screenshots  
<p align="center">  
  <img src="https://github.com/user-attachments/assets/e53b7350-2fc5-4947-904c-8b1b007a021c" width="140"/>  
  <img src="https://github.com/user-attachments/assets/444cb35d-4e02-4116-928e-1af959048ce2" width="140"/>  
  <img src="https://github.com/user-attachments/assets/32b83bc6-5995-4efb-b6ac-0d4dbdc31c14" width="140"/>  
  <img src="https://github.com/user-attachments/assets/9cf63a93-013d-4855-8bb8-07646755d8c9" width="200"/>  
</p>  

---

## 🛠️ Tech Stack  
- **Flutter & Dart**  
- [`awesome_notifications`](https://pub.dev/packages/awesome_notifications) – For rich notifications with sound & vibration  
- [`just_audio`](https://pub.dev/packages/just_audio) + [`audio_session`](https://pub.dev/packages/audio_session) – For continuous alarm sounds  
- [`flutter_overlay_window`](https://pub.dev/packages/flutter_overlay_window) – To display overlays outside the app  
- [`workmanager`](https://pub.dev/packages/workmanager) – To run tasks in the background  
- [`battery_plus`](https://pub.dev/packages/battery_plus) – For battery info and charging events  
- [`shared_preferences`](https://pub.dev/packages/shared_preferences) – To persist user settings  

---

## 🚀 Getting Started  

1. Clone the repository:  
   ```bash
   git clone https://github.com/your-username/voltify.git
   cd voltify
2. Install dependencies:
   ```bash
   flutter pub get
3. Run on your device:
   ```bash
   flutter run

---

## 📖 Usage

1. Open the Voltify app.

2. Press Start to enable monitoring.

3. Unplug your device from the charger.

4. Plug it back in – you'll get a notification with sound + vibration and an optional overlay.

5. Tap Stop inside the app or from the notification to silence the alarm.

---
## 🤝 Contributing

Contributions are welcome! Feel free to open issues and submit pull requests.
