enum AppointmentStatus { upcoming, completed, cancelled }

class Appointment {
  String service;
  String stylist;
  DateTime date;
  String time;
  AppointmentStatus status;

  Appointment({
    required this.service,
    required this.stylist,
    required this.date,
    required this.time,
    this.status = AppointmentStatus.upcoming,
  });
}
