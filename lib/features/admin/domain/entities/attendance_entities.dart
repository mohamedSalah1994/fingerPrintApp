import 'package:equatable/equatable.dart';
import 'package:fingerprint_app/features/auth/domain/entities/app_user.dart';

enum AttendanceStatus { present, late, absent, excused }

extension AttendanceStatusX on AttendanceStatus {
  String get value => name;

  static AttendanceStatus fromString(String? v) {
    return AttendanceStatus.values.firstWhere(
      (e) => e.name == v,
      orElse: () => AttendanceStatus.present,
    );
  }
}

enum AttendanceSource { manual, fingerprint, device }

extension AttendanceSourceX on AttendanceSource {
  String get value => name;

  static AttendanceSource fromString(String? v) {
    return AttendanceSource.values.firstWhere(
      (e) => e.name == v,
      orElse: () => AttendanceSource.manual,
    );
  }
}

/// Device-ready attendance record (manual now, ZKTeco/fingerprint later).
class AttendanceRecord extends Equatable {
  const AttendanceRecord({
    required this.id,
    required this.studentId,
    required this.branchId,
    required this.date,
    required this.status,
    required this.source,
    this.groupId,
    this.checkInAt,
    this.checkOutAt,
    this.deviceId,
    this.deviceUserId,
    this.note,
    this.recordedBy,
  });

  final String id;
  final String studentId;
  final String branchId;

  /// Calendar day as `yyyy-MM-dd` for easy filtering.
  final String date;
  final AttendanceStatus status;
  final AttendanceSource source;
  final String? groupId;
  final DateTime? checkInAt;
  final DateTime? checkOutAt;
  final String? deviceId;

  /// External finger/device user id (ZKTeco UID).
  final String? deviceUserId;
  final String? note;
  final String? recordedBy;

  @override
  List<Object?> get props => [
        id,
        studentId,
        branchId,
        date,
        status,
        source,
        groupId,
        checkInAt,
        checkOutAt,
        deviceId,
        deviceUserId,
        note,
        recordedBy,
      ];
}

class FingerprintDevice extends Equatable {
  const FingerprintDevice({
    required this.id,
    required this.name,
    required this.branchId,
    required this.serialNumber,
    this.vendor = 'zkteco',
    this.model = 'K50 Pro',
    this.status = 'active',
    this.location,
    this.lastSyncAt,
    this.ipAddress,
    this.port = 4370,
    this.commKey = 0,
    this.forceUdp = false,
  });

  final String id;
  final String name;
  final String branchId;
  final String serialNumber;
  final String vendor;
  final String model;
  final String status;
  final String? location;
  final DateTime? lastSyncAt;
  final String? ipAddress;
  final int port;

  /// ZKTeco communication key (device Menu → Comm. → Security).
  final int commKey;
  final bool forceUdp;

  @override
  List<Object?> get props => [
        id,
        name,
        branchId,
        serialNumber,
        vendor,
        model,
        status,
        location,
        lastSyncAt,
        ipAddress,
        port,
        commKey,
        forceUdp,
      ];
}

class BiometricMapping extends Equatable {
  const BiometricMapping({
    required this.id,
    required this.studentId,
    required this.deviceId,
    required this.deviceUserId,
    required this.branchId,
    this.fingerIndex,
    this.status = 'active',
  });

  final String id;
  final String studentId;
  final String deviceId;

  /// ID on the fingerprint device (ZKTeco user id).
  final String deviceUserId;
  final String branchId;
  final int? fingerIndex;
  final String status;

  @override
  List<Object?> get props =>
      [id, studentId, deviceId, deviceUserId, branchId, fingerIndex, status];
}

class StaffUser extends Equatable {
  const StaffUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    this.phone,
    this.branchId,
  });

  final String id;
  final String email;
  final String displayName;
  final UserRole role;
  final String? phone;
  final String? branchId;

  @override
  List<Object?> get props => [id, email, displayName, role, phone, branchId];
}
