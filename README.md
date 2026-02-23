# 💇‍♀️ TressUp — Production-Ready Salon Booking System

*TressUp* is a full-stack mobile application built for *Fiqah Beauty & Salon* to digitise appointment management, staff scheduling, and customer loyalty. The system replaces manual WhatsApp-based bookings with a structured, scalable solution powered by Flutter and Firebase.

This project demonstrates real-world software engineering practices including role-based access control, cloud database design, asynchronous workflows, and push notification systems.

---

📱 Customer Mobile App
<table> <tr> <td><img src="https://github.com/user-attachments/assets/21e2c799-15f2-4045-884c-f79c912d1acc" width="200"></td> <td><img src="https://github.com/user-attachments/assets/bac8ad4a-5819-4bdb-b26e-79e392434ddb" width="200"></td> <td><img src="https://github.com/user-attachments/assets/065cee47-bd8c-4ad1-aadf-1a6d2a919c7e" width="200"></td> <td><img src="https://github.com/user-attachments/assets/68910a72-2e37-4699-affc-a2df51e32e1f" width="200"></td> </tr> </table>




🛠 Admin Management Dashboard
<table> <tr> <td><img src="https://github.com/user-attachments/assets/8c8c9bc7-d686-43f7-bb2e-a694ecd906da" width="200"></td> <td><img src="https://github.com/user-attachments/assets/b25737ea-f618-41a1-b79e-e881532043e0" width="200"></td> <td><img src="https://github.com/user-attachments/assets/32016d1b-5872-4cdd-bfb1-c7268b071928" width="200"></td> <td><img src="https://github.com/user-attachments/assets/caeb7fdf-c80a-4e92-a926-e4c6ed74714f" width="200"></td> </tr> <tr> <td><img src="https://github.com/user-attachments/assets/69338c47-1130-4923-9010-1d397278c420" width="200"></td> <td><img src="https://github.com/user-attachments/assets/684a1edf-29b6-4ba7-9287-2bff1697a002" width="200"></td> <td><img src="https://github.com/user-attachments/assets/fb32fd04-54a0-48e8-bb36-5228b75d4aa3" width="200"></td> <td></td> </tr> </table>





✂️ Staff Operations Portal
<table> <tr> <td><img src="https://github.com/user-attachments/assets/0cbdf360-3f6d-442d-96dd-e4d2481b9e47" width="200"></td> <td><img src="https://github.com/user-attachments/assets/1fd987cf-1116-4356-a722-8b2dc4dda01b" width="200"></td> <td><img src="https://github.com/user-attachments/assets/332c1c6e-0cca-40b2-85b6-d685ea3a2cda" width="200"></td> <td><img src="https://github.com/user-attachments/assets/8a513d06-f971-4922-a0fd-3ccb017a5dfe" width="200"></td> </tr> <tr> <td><img src="https://github.com/user-attachments/assets/3ff1b53d-8aac-44c7-80f1-6a5423e1a7e6" width="200"></td> <td></td> <td></td> <td></td> </tr> </table>




All connected to a central Firebase backend.

---

## 🚀 Key Features

### 👤 Customer Application

* Book appointments with real-time availability
* Select services, staff, and preferred timeslots
* Track appointment status: Pending, Approved, Completed, Cancelled
* Earn loyalty points based on spending
* Redeem points for discounts
* Receive real-time push notifications
* Manage profile and appointment history

---

### 🛠 Admin Dashboard

* Approve, reject, or reschedule bookings
* Finalise payments and apply loyalty discounts
* Manage customer records and internal notes
* Manage staff accounts and permissions
* Monitor appointment activity and revenue trends

---

### ✂️ Staff Portal

* View daily schedules and assigned appointments
* Access client history and service notes
* Mark jobs as completed
* Calculate billing totals

---

## 🧠 Engineering Highlights

This project demonstrates practical implementation of:

* Role-based access control using Firestore
* Real-time database synchronisation
* Cloud-based authentication system
* Event-driven push notification architecture (FCM HTTP v1)
* Scalable NoSQL database design
* Multi-role system architecture (admin, staff, customer)
* Production-style project structure and state handling

---

## 🏗 Architecture

**Frontend:**
Flutter (Dart)

**Backend:**
Firebase

* Firestore Database
* Firebase Authentication
* Cloud Storage

**Notifications:**
Firebase Cloud Messaging (FCM)

---

## 🔒 Security Implementation

Role-based permissions enforced via Firestore:

* admin → full system access
* staff → appointment and schedule access
* customer → booking access only

Prevents unauthorised access to sensitive business data.

---

## 🎯 Real-World Impact

This system solves real operational problems:

Before:

* Manual booking via WhatsApp
* Double bookings possible
* No centralised records
* No loyalty tracking

After:

* Structured booking system
* Centralised database
* Automated tracking
* Improved operational efficiency

---

## 👨‍💻 Author

Muhammad Arif bin Saji
Software Engineering Student 
Universiti Malaysia Sarawak (UNIMAS)

Built as part of a real client-based Software Engineering project.
