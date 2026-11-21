import 'package:latlong2/latlong.dart';

enum ActivityType {
  hospital,
  police,
  fire,
  sos,
}

enum ActivityStatus {
  completed,
  dispatched,
  connected,
}

class EmergencyActivity {
  const EmergencyActivity({
    required this.id,
    required this.type,
    required this.title,
    required this.stationName,
    required this.serviceCategory,
    required this.timestamp,
    required this.status,
    required this.duration,
    required this.distance,
    required this.callerAddress,
    required this.callerTime,
    required this.callerLatLng,
    required this.destinationAddress,
    required this.destinationTime,
    required this.destinationLatLng,
    required this.responderName,
    required this.responderRole,
    required this.responderBadge,
    required this.callMode,
    required this.priority,
    required this.profileName,
    this.rating = 5,
    required this.ratingNote,
  });

  final String id;
  final ActivityType type;
  final String title;
  final String stationName;
  final String serviceCategory;
  final String timestamp;
  final ActivityStatus status;
  final String duration;
  final String distance;
  final String callerAddress;
  final String callerTime;
  final LatLng callerLatLng;
  final String destinationAddress;
  final String destinationTime;
  final LatLng destinationLatLng;
  final String responderName;
  final String responderRole;
  final String responderBadge;
  final String callMode;
  final String priority;
  final String profileName;
  final int rating;
  final String ratingNote;
}

const kSampleActivities = <EmergencyActivity>[
  EmergencyActivity(
    id: 'SOS-2026-89124K',
    type: ActivityType.hospital,
    title: 'Calmette Hospital — Emergency Call',
    stationName: 'Calmette Hospital',
    serviceCategory: 'Hospital Dispatch',
    timestamp: '19 Nov 2026, 05:24 PM',
    status: ActivityStatus.completed,
    duration: '12 min',
    distance: '5.68 km',
    callerAddress: 'St. 598, Khan Tuol Kouk, Phnom Penh',
    callerTime: '05:24 PM',
    callerLatLng: LatLng(11.5813, 104.9158),
    destinationAddress: 'Calmette Hospital ER, Monivong Blvd',
    destinationTime: '05:36 PM',
    destinationLatLng: LatLng(11.5845, 104.9198),
    responderName: 'Calmette Emergency Unit #03',
    responderRole: 'Dr. Sokha (Lead Paramedic)',
    responderBadge: 'ER Paramedic',
    callMode: 'Voice Call + Live GPS',
    priority: 'High — Emergency SOS',
    profileName: 'Personal',
    rating: 5,
    ratingNote: 'Fast Response',
  ),
  EmergencyActivity(
    id: 'POL-2026-44219P',
    type: ActivityType.police,
    title: 'Central Police — Patrol Request',
    stationName: 'Phnom Penh Central Police',
    serviceCategory: 'Police Response',
    timestamp: '18 Nov 2026, 11:15 PM',
    status: ActivityStatus.completed,
    duration: '8 min',
    distance: '3.20 km',
    callerAddress: 'St. 214, Khan Daun Penh, Phnom Penh',
    callerTime: '11:15 PM',
    callerLatLng: LatLng(11.5621, 104.9282),
    destinationAddress: 'Daun Penh Police Station, St. 214',
    destinationTime: '11:23 PM',
    destinationLatLng: LatLng(11.5680, 104.9220),
    responderName: 'Patrol Unit #12',
    responderRole: 'Officer Chan (Division Lead)',
    responderBadge: 'Patrol Division',
    callMode: 'Direct Emergency Call',
    priority: 'High — Police Emergency',
    profileName: 'Personal',
    rating: 5,
    ratingNote: 'Arrived in 6 mins',
  ),
  EmergencyActivity(
    id: 'FIR-2026-10382F',
    type: ActivityType.fire,
    title: 'Fire Station — Rescue Call',
    stationName: 'Chamkarmon Fire Station',
    serviceCategory: 'Fire Rescue',
    timestamp: '15 Nov 2026, 02:40 PM',
    status: ActivityStatus.completed,
    duration: '15 min',
    distance: '4.10 km',
    callerAddress: 'Norodom Blvd, Boeung Keng Kang 1',
    callerTime: '02:40 PM',
    callerLatLng: LatLng(11.5450, 104.9280),
    destinationAddress: 'Chamkarmon Fire Rescue Depot',
    destinationTime: '02:55 PM',
    destinationLatLng: LatLng(11.5380, 104.9350),
    responderName: 'Fire Engine #02 — Team Bravo',
    responderRole: 'Capt. Vicheka (Chief Officer)',
    responderBadge: 'Fire Brigade',
    callMode: 'Voice Call + Live GPS',
    priority: 'Critical — Fire Emergency',
    profileName: 'Personal',
    rating: 5,
    ratingNote: 'Fire controlled swiftly',
  ),
  EmergencyActivity(
    id: 'SOS-2026-00412S',
    type: ActivityType.sos,
    title: 'Emergency SOS — Direct Alert',
    stationName: 'Emergency Operations Center',
    serviceCategory: 'SOS Dispatch',
    timestamp: '12 Nov 2026, 09:05 AM',
    status: ActivityStatus.dispatched,
    duration: '6 min',
    distance: '2.40 km',
    callerAddress: 'Russian Confederation Blvd, Tuol Kouk',
    callerTime: '09:05 AM',
    callerLatLng: LatLng(11.5680, 104.8900),
    destinationAddress: 'EOC Central Command, Phnom Penh',
    destinationTime: '09:11 AM',
    destinationLatLng: LatLng(11.5700, 104.9000),
    responderName: 'Dispatch Team #07',
    responderRole: 'Operator Bopha (EOC Supervisor)',
    responderBadge: 'Command Center',
    callMode: 'Live SOS Broadcast',
    priority: 'Critical — Panic Trigger',
    profileName: 'Personal',
    rating: 5,
    ratingNote: 'Help dispatched instantly',
  ),
];
