import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Generate mocks for SupabaseClient and related classes
@GenerateMocks([
  SupabaseClient,
  PostgrestQueryBuilder,
  PostgrestFilterBuilder,
  PostgrestBuilder,
])
void main() {}