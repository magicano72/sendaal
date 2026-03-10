import 'package:flutter_dotenv/flutter_dotenv.dart';

class Environment {
  static String get baseUrl {
    final url = dotenv.env['BASE_URL'];
    if (url == null || url.isEmpty) {
      throw Exception('BASE_URL not defined in .env');
    }
    return url;
  }

  static int get apiTimeout {
    final timeout = dotenv.env['API_TIMEOUT'];
    if (timeout == null || timeout.isEmpty) {
      return 30000; // Default timeout in milliseconds
    }
    return int.tryParse(timeout) ?? 30000;
  }

  static String get appEnv {
    return dotenv.env['APP_ENV'] ?? 'development';
  }

  static bool get isDevelopment => appEnv == 'development';
  static bool get isProduction => appEnv == 'production';
}
