# 💇‍♀️ TressUp - Smart Salon Booking App

*TressUp* is a comprehensive mobile application designed for *Fiqah Beauty & Salon* to streamline appointment bookings, manage staff schedules, and enhance customer loyalty through a digital rewards system. Built with *Flutter* and *Firebase*.

## 🚀 Features

### 👤 Customer App
* *Easy Booking:* Browse services, choose stylists, select dates/times, and book appointments instantly.
* *Appointment History:* View Upcoming, Completed, and Cancelled bookings.
* *Loyalty System:* Earn points for every RM spent and redeem them for discounts.
* *Notifications:* Receive real-time updates on booking status (Approved, Rejected, Completed).
* *Profile Management:* Edit personal details and view earned loyalty points.

### 🛠 Admin Dashboard
* *Manage Appointments:* Approve, Reject, or Reschedule bookings.
* *Finalize Payments:* Calculate totals, apply point discounts, and mark jobs as completed.
* *Customer Database:* View customer profiles, booking history, and add private staff notes.
* *Staff Management:* Manage staff accounts and roles.
* *Business Insights:* View appointment trends and revenue.

### ✂️ Staff Portal
* *Schedule View:* See daily assigned tasks and upcoming appointments.
* *Job Completion:* Mark services as done and calculate bills.
* *Client Info:* View client preferences and notes before the appointment.

---

## 📱 Tech Stack

* *Framework:* Flutter (Dart)
* *Backend:* Firebase (Firestore Database, Authentication, Cloud Storage)
* *Notifications:* Firebase Cloud Messaging (FCM) & HTTP v1 API

---

## 🛠️ Installation & Setup

This project uses Flutter. Ensure you have the Flutter SDK installed.

1.  **Clone the repository**
    ```bash
    git clone [https://github.com/arippp02/tressup-fiqah-salon-booking-app.git](https://github.com/arippp02/tressup-fiqah-salon-booking-app.git)
    cd tressup-fiqah-salon-booking-app
    ```

2.  **Install Dependencies**
    ```bash
    flutter pub get
    ```

3.  **Firebase Configuration (Important)**
    > ⚠️ **Note:** For security reasons, the Firebase configuration files and Service Account keys are **not** included in this public repository.
    
    To run this app, you must:
    * Create a Firebase Project.
    * Add `google-services.json` to `android/app/`.
    * Add `GoogleService-Info.plist` to `ios/Runner/`.
    * Add `assets/service_account.json` for notification capabilities.

4.  **Run the App**
    ```bash
    flutter run
    ```

---

## 📸 Screenshots

| Customer Booking | Admin Dashboard | Appointment History |
|:---:|:---:|:---:|
| *(Add Screenshot)* | *(Add Screenshot)* | *(Add Screenshot)* |

---

## 🔒 Security & Roles

The app uses role-based access control stored in Firestore:
* **`role: 'admin'`**: Full access to database and management tools.
* **`role: 'staff'`**: Access to schedule and completion tools.
* **`role: 'customer'`**: Access to booking interface only.

---

## 👤 Author

*Arif* *Universiti Malaysia Sarawak (UNIMAS)* Developed for TMA3084 Sem 1 25/26: Software Engineering Lab project.
