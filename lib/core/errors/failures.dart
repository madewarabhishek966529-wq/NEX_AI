abstract class Failure {
  final String message;
  final int? code;

  const Failure(this.message, [this.code]);

  @override
  String toString() => message;
}

class ServerFailure extends Failure {
  const ServerFailure(super.message, [super.code]);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Unable to connect to the companion server. Please check your network or server status.']);
}

class SpeechRecognitionFailure extends Failure {
  const SpeechRecognitionFailure([super.message = 'Microphone or speech recognition failure.']);
}

class TtsFailure extends Failure {
  const TtsFailure([super.message = 'Text-to-speech synthesis failed.']);
}

class StorageFailure extends Failure {
  const StorageFailure([super.message = 'Local cache storage error.']);
}

class GeneralFailure extends Failure {
  const GeneralFailure([super.message = 'An unexpected error occurred.']);
}
