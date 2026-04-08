class AppConfig {
  static const supabaseUrl = String.fromEnvironment("SUPABASE_URL");
  static const supabaseAnonKey = String.fromEnvironment("SUPABASE_ANON_KEY");
  static const reviewerApiKey = String.fromEnvironment("REVIEWER_API_KEY");
  static const closedBetaManualCodeEnabled = bool.fromEnvironment(
    "CLOSED_BETA_MANUAL_CODE",
    defaultValue: false,
  );

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
  static bool get reviewerOpsEnabled => reviewerApiKey.isNotEmpty;
}
