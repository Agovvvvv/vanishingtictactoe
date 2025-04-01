// challenge_service_exception.dart
class ChallengeServiceException implements Exception {
  final String message;
  ChallengeServiceException(this.message);

  @override
  String toString() => 'ChallengeServiceException: $message';
}