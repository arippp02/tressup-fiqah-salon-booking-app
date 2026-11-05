# TressUp – Smart Beauty & Salon Booking Application

TressUp is a full-stack mobile application developed for **Fiqah Beauty & Salon** to streamline appointment booking, staff scheduling and customer loyalty management. It replaces manual WhatsApp bookings with a centralised system built using Flutter and Firebase.

The system consists of three interfaces: a customer mobile application, an admin dashboard and a staff portal. All three are connected to a shared Firebase backend.

## Customer Mobile Application

Customers can:
- Book appointments based on available timeslots.
- Select services, preferred staff and appointment times.
- Track booking status (Pending, Approved, Completed and Cancelled).
- Earn and redeem loyalty points.
- Receive appointment notifications.
- Manage profiles and view booking history.

## Admin Management Dashboard

Administrators can:
- Approve, reject and reschedule appointments.
- Manage payments and apply loyalty discounts.
- Manage customer records and internal notes.
- Create and manage staff accounts and permissions.
- Monitor appointments and revenue.

## Staff Operations Portal

Staff can:
- View daily schedules and assigned appointments.
- Access customer history and service notes.
- Update appointment status.
- Mark services as completed.
- Calculate billing totals.

## Technical Implementation

**Frontend**
- Flutter
- Dart

**Backend and Database**
- Firebase Authentication
- Cloud Firestore
- Firebase Cloud Storage

**Notifications**
- Firebase Cloud Messaging (FCM HTTP v1)

## Key Technical Features

- Role-based access control for administrators, staff and customers.
- Real-time data synchronisation using Cloud Firestore.
- Firebase-based user authentication.
- Push notification integration using FCM.
- NoSQL database design.
- Multi-role application architecture.
- Structured state management and asynchronous operations.

## Security and Access Control

The system implements role-based permissions to control access to application features and business data.

- **Admin:** Full management access.
- **Staff:** Access to assigned appointments, schedules and customer service information.
- **Customer:** Access to personal profiles, bookings and loyalty records.

## Project Impact

TressUp addresses several limitations of manual salon management, including booking conflicts, scattered customer records and the absence of a structured loyalty programme.

By centralising these operations, the system provides a more organised booking process and improves appointment and customer management.

## Author

**Muhammad Arif bin Saji**  
Bachelor of Software Engineering with Honours  
Universiti Malaysia Sarawak (UNIMAS)

Developed as part of a client-based Software Engineering project.
