import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/usecases/get_attendance_records_usecase.dart';
import '../../domain/usecases/mark_attendance_usecase.dart';

// Events
abstract class AttendanceEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AttendanceRecordsRequested extends AttendanceEvent {
  final String? subject;
  final DateTime? date;

  AttendanceRecordsRequested({this.subject, this.date});

  @override
  List<Object?> get props => [subject, date];
}

class AttendanceMarked extends AttendanceEvent {
  final int studentId;
  final String subject;
  final String status;

  AttendanceMarked({
    required this.studentId,
    required this.subject,
    this.status = 'Present',
  });

  @override
  List<Object?> get props => [studentId, subject, status];
}

// States
abstract class AttendanceState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AttendanceInitial extends AttendanceState {}

class AttendanceLoading extends AttendanceState {}

class AttendanceRecordsLoaded extends AttendanceState {
  final List<AttendanceRecord> records;

  AttendanceRecordsLoaded({required this.records});

  @override
  List<Object?> get props => [records];
}

class AttendanceMarkingSuccess extends AttendanceState {
  final String studentName;

  AttendanceMarkingSuccess({required this.studentName});

  @override
  List<Object?> get props => [studentName];
}

class AttendanceError extends AttendanceState {
  final String message;

  AttendanceError({required this.message});

  @override
  List<Object?> get props => [message];
}

// Bloc
class AttendanceBloc extends Bloc<AttendanceEvent, AttendanceState> {
  final GetAttendanceRecordsUseCase getAttendanceRecordsUseCase;
  final MarkAttendanceUseCase markAttendanceUseCase;

  AttendanceBloc(
    this.getAttendanceRecordsUseCase,
    this.markAttendanceUseCase,
  ) : super(AttendanceInitial()) {
    on<AttendanceRecordsRequested>(_onRecordsRequested);
    on<AttendanceMarked>(_onAttendanceMarked);
  }

  Future<void> _onRecordsRequested(
    AttendanceRecordsRequested event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(AttendanceLoading());
    
    try {
      final records = await getAttendanceRecordsUseCase(
        subject: event.subject,
        date: event.date,
      );
      emit(AttendanceRecordsLoaded(records: records));
    } catch (e) {
      emit(AttendanceError(message: e.toString()));
    }
  }

  Future<void> _onAttendanceMarked(
    AttendanceMarked event,
    Emitter<AttendanceState> emit,
  ) async {
    try {
      await markAttendanceUseCase(
        studentId: event.studentId,
        subject: event.subject,
        status: event.status,
      );
      
      // Mock student name - in production, this would come from the API
      emit(AttendanceMarkingSuccess(studentName: 'Student ${event.studentId}'));
      
      // Refresh records
      add(AttendanceRecordsRequested());
    } catch (e) {
      emit(AttendanceError(message: e.toString()));
    }
  }
}