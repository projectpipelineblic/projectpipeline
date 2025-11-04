import 'package:equatable/equatable.dart';

abstract class DashboardEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadDashboardDataRequested extends DashboardEvent {
  LoadDashboardDataRequested({required this.userId});
  final String userId;

  @override
  List<Object?> get props => [userId];
}

