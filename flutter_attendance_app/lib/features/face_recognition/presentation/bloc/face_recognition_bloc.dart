import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/usecases/recognize_face_usecase.dart';

// Events
abstract class FaceRecognitionEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class FaceRecognitionStarted extends FaceRecognitionEvent {}

class FaceRecognitionStopped extends FaceRecognitionEvent {}

class FaceRecognized extends FaceRecognitionEvent {
  final Uint8List imageBytes;

  FaceRecognized({required this.imageBytes});

  @override
  List<Object?> get props => [imageBytes];
}

// States
abstract class FaceRecognitionState extends Equatable {
  @override
  List<Object?> get props => [];
}

class FaceRecognitionInitial extends FaceRecognitionState {}

class FaceRecognitionActive extends FaceRecognitionState {}

class FaceRecognitionProcessing extends FaceRecognitionState {}

class FaceRecognitionSuccess extends FaceRecognitionState {
  final int studentId;

  FaceRecognitionSuccess({required this.studentId});

  @override
  List<Object?> get props => [studentId];
}

class FaceRecognitionNotFound extends FaceRecognitionState {}

class FaceRecognitionError extends FaceRecognitionState {
  final String message;

  FaceRecognitionError({required this.message});

  @override
  List<Object?> get props => [message];
}

// Bloc
class FaceRecognitionBloc extends Bloc<FaceRecognitionEvent, FaceRecognitionState> {
  final RecognizeFaceUseCase recognizeFaceUseCase;

  FaceRecognitionBloc(this.recognizeFaceUseCase) : super(FaceRecognitionInitial()) {
    on<FaceRecognitionStarted>(_onStarted);
    on<FaceRecognitionStopped>(_onStopped);
    on<FaceRecognized>(_onFaceRecognized);
  }

  void _onStarted(
    FaceRecognitionStarted event,
    Emitter<FaceRecognitionState> emit,
  ) {
    emit(FaceRecognitionActive());
  }

  void _onStopped(
    FaceRecognitionStopped event,
    Emitter<FaceRecognitionState> emit,
  ) {
    emit(FaceRecognitionInitial());
  }

  Future<void> _onFaceRecognized(
    FaceRecognized event,
    Emitter<FaceRecognitionState> emit,
  ) async {
    emit(FaceRecognitionProcessing());
    
    try {
      final studentId = await recognizeFaceUseCase(event.imageBytes);
      
      if (studentId != null) {
        emit(FaceRecognitionSuccess(studentId: studentId));
      } else {
        emit(FaceRecognitionNotFound());
      }
    } catch (e) {
      emit(FaceRecognitionError(message: e.toString()));
    }
  }
}