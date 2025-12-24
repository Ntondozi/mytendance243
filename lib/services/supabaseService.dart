import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static Future<void> init() async {
    await Supabase.initialize(
      url: 'https://yaftgmijrrvvkjdoavol.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlhZnRnbWlqcnJ2dmtqZG9hdm9sIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkxNTYwMjUsImV4cCI6MjA3NDczMjAyNX0.Ykr9lJIpMKfjVzhdnLO9CLw6XgJFh-OJMy3j2lUA258',
  );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
