import 'package:equatable/equatable.dart';

class Stage extends Equatable {
  const Stage({
    required this.id,
    required this.name,
    required this.order,
    required this.branchId,
  });

  final String id;
  final String name;
  final int order;
  final String branchId;

  @override
  List<Object?> get props => [id, name, order, branchId];
}

class Grade extends Equatable {
  const Grade({
    required this.id,
    required this.stageId,
    required this.name,
    required this.order,
    required this.branchId,
  });

  final String id;
  final String stageId;
  final String name;
  final int order;
  final String branchId;

  @override
  List<Object?> get props => [id, stageId, name, order, branchId];
}

class Subject extends Equatable {
  const Subject({
    required this.id,
    required this.name,
    required this.branchId,
    this.stageId,
    this.gradeId,
  });

  final String id;
  final String name;
  final String branchId;
  final String? stageId;
  final String? gradeId;

  @override
  List<Object?> get props => [id, name, branchId, stageId, gradeId];
}

class Classroom extends Equatable {
  const Classroom({
    required this.id,
    required this.name,
    required this.capacity,
    required this.branchId,
    this.building,
    this.floor,
    this.status = 'active',
  });

  final String id;
  final String name;
  final int capacity;
  final String branchId;
  final String? building;
  final String? floor;
  final String status;

  @override
  List<Object?> get props =>
      [id, name, capacity, branchId, building, floor, status];
}
