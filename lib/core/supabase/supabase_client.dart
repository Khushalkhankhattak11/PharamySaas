import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  try {
    return Supabase.instance.client;
  } catch (_) {
    final client = SupabaseClient(
      'https://mock.supabase.co',
      'mock-anon-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    ref.onDispose(() => client.dispose());
    return client;
  }
});

final currentAuthUserProvider = StreamProvider<User?>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return supabase.auth.onAuthStateChange.map((event) => event.session?.user);
});
