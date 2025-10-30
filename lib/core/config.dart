class AppConfig {
  static const String appName = 'Agrifinity VSLA';
  // TODO: Replace with your backend base URL, e.g., https://api.example.com
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://digitalgroups.midhatechnologies.com/',
  );

  // Sanctum token header key
  static const String authHeader = 'Authorization';
}
