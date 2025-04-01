import 'package:vanishingtictactoe/core/utils/app_logger.dart';

class ErrorHandler {
  static void handleError(String message, {Function(String)? onError}) {
    AppLogger.error(message);
    onError?.call(message);
  }
}