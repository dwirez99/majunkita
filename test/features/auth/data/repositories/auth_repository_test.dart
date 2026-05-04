import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:majunkita/features/auth/data/repositories/auth_repository.dart';

// --- Fakes Setup ---

// FakeFuture to easily mock Postgrest builder chains which return Futures
class FakeFuture<T> extends Fake implements Future<T> {
  final Future<T> _future;
  FakeFuture(T value, [Object? errorToThrow])
    : _future =
          errorToThrow != null
              ? Future.error(errorToThrow)
              : Future.value(value);

  @override
  Future<R> then<R>(
    FutureOr<R> Function(T value) onValue, {
    Function? onError,
  }) {
    return _future.then(onValue, onError: onError);
  }

  @override
  Future<T> catchError(Function onError, {bool Function(Object error)? test}) {
    return _future.catchError(onError, test: test);
  }

  @override
  Future<T> whenComplete(FutureOr<void> Function() action) {
    return _future.whenComplete(action);
  }

  @override
  Stream<T> asStream() {
    return _future.asStream();
  }

  @override
  Future<T> timeout(Duration timeLimit, {FutureOr<T> Function()? onTimeout}) {
    return _future.timeout(timeLimit, onTimeout: onTimeout);
  }
}

class FakePostgrestTransformBuilder extends FakeFuture<Map<String, dynamic>>
    implements PostgrestTransformBuilder<Map<String, dynamic>> {
  FakePostgrestTransformBuilder(super.value, [super.errorToThrow]);
}

class FakePostgrestFilterBuilder<T> extends FakeFuture<T>
    implements PostgrestFilterBuilder<T> {
  final Map<String, dynamic>? singleResult;

  FakePostgrestFilterBuilder(T value, {this.singleResult, Object? errorToThrow})
    : super(value, errorToThrow);

  @override
  PostgrestFilterBuilder<T> eq(String column, Object value) {
    return this;
  }

  @override
  PostgrestTransformBuilder<Map<String, dynamic>> single() {
    return FakePostgrestTransformBuilder(singleResult ?? {});
  }
}

class FakeSupabaseQueryBuilder extends Fake implements SupabaseQueryBuilder {
  final Map<String, dynamic>? singleResult;
  final Object? errorToThrow;

  FakeSupabaseQueryBuilder({this.singleResult, this.errorToThrow});

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> select([
    String columns = '*',
  ]) {
    return _FakeSelectFilterBuilder(
      [],
      singleResult: singleResult,
      error: errorToThrow,
    );
  }
}

class _FakeSelectFilterBuilder
    extends FakePostgrestFilterBuilder<List<Map<String, dynamic>>> {
  final Object? error;
  _FakeSelectFilterBuilder(
    List<Map<String, dynamic>> value, {
    super.singleResult,
    this.error,
  }) : super(value);

  @override
  PostgrestTransformBuilder<Map<String, dynamic>> single() {
    if (error != null) throw error!;
    return FakePostgrestTransformBuilder(singleResult ?? {});
  }
}

class FakeGoTrueClient extends Fake implements GoTrueClient {
  User? mockCurrentUser;
  Object? signInError;
  Object? signOutError;

  @override
  User? get currentUser => mockCurrentUser;

  @override
  Future<AuthResponse> signInWithPassword({
    String? email,
    String? phone,
    required String password,
    String? captchaToken,
  }) async {
    if (signInError != null) throw signInError!;
    return AuthResponse(
      session: Session(
        accessToken: 'token',
        refreshToken: 'refresh',
        expiresIn: 3600,
        tokenType: 'bearer',
        user: User(
          id: '1',
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          createdAt: '',
        ),
      ),
      user: User(
        id: '1',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: '',
      ),
    );
  }

  @override
  Future<void> signOut({SignOutScope scope = SignOutScope.global}) async {
    if (signOutError != null) throw signOutError!;
  }
}

class FakeFunctionsClient extends Fake implements FunctionsClient {
  Map<String, dynamic>? expectedData;
  Object? invokeError;
  Map<String, dynamic>? lastBody;

  @override
  Future<FunctionResponse> invoke(
    String functionName, {
    Map<String, String>? headers,
    Object? body,
    HttpMethod method = HttpMethod.post,
    Map<String, dynamic>? queryParameters,
    dynamic reqType,
    dynamic files,
    dynamic region,
  }) async {
    lastBody = body as Map<String, dynamic>?;
    if (invokeError != null) throw invokeError!;
    return FunctionResponse(data: expectedData, status: 200);
  }
}

class FakeSupabaseClient extends Fake implements SupabaseClient {
  @override
  final FakeGoTrueClient auth = FakeGoTrueClient();
  @override
  final FakeFunctionsClient functions = FakeFunctionsClient();

  String? expectedUsername;
  String? rpcEmailResult;
  Object? rpcError;

  Map<String, dynamic>? profileResult;
  Object? profileError;

  @override
  PostgrestFilterBuilder<T> rpc<T>(
    String fn, {
    Map<String, dynamic>? params,
    dynamic get = false,
  }) {
    if (fn == 'get_email_by_username') {
      if (rpcError != null) {
        return FakePostgrestFilterBuilder<T>(null as T, errorToThrow: rpcError);
      }
      if (params?['_username'] == expectedUsername) {
        return FakePostgrestFilterBuilder<T>(rpcEmailResult as T);
      }
      return FakePostgrestFilterBuilder<T>(null as T);
    }
    return FakePostgrestFilterBuilder<T>(null as T);
  }

  @override
  SupabaseQueryBuilder from(String table) {
    if (table == 'profiles') {
      return FakeSupabaseQueryBuilder(
        singleResult: profileResult,
        errorToThrow: profileError,
      );
    }
    throw UnimplementedError('Table $table not mocked');
  }
}

// --- Tests ---

void main() {
  late FakeSupabaseClient fakeClient;
  late AuthRepository repository;

  setUp(() {
    fakeClient = FakeSupabaseClient();
    repository = AuthRepository(fakeClient);
  });

  group('AuthRepository Tests', () {
    group('signIn', () {
      test('uses email directly if identifier contains @', () async {
        final response = await repository.signIn(
          identifier: 'test@example.com',
          password: 'password123',
        );
        expect(response.user, isNotNull);
        expect(response.user!.id, '1');
      });

      test('fetches email via RPC if identifier is username', () async {
        fakeClient.expectedUsername = 'johndoe';
        fakeClient.rpcEmailResult = 'john@example.com';

        final response = await repository.signIn(
          identifier: 'johndoe',
          password: 'password123',
        );
        expect(response.user, isNotNull);
      });

      test('throws exception if username not found', () async {
        fakeClient.expectedUsername = 'johndoe';
        fakeClient.rpcEmailResult = null; // simulate not found

        expect(
          () =>
              repository.signIn(identifier: 'johndoe', password: 'password123'),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Username tidak ditemukan'),
            ),
          ),
        );
      });

      test('maps AuthException for invalid credentials', () async {
        fakeClient.auth.signInError = const AuthException(
          'invalid login credentials',
        );

        expect(
          () => repository.signIn(
            identifier: 'test@example.com',
            password: 'password123',
          ),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Email atau Password salah'),
            ),
          ),
        );
      });

      test('maps AuthException for unconfirmed email', () async {
        fakeClient.auth.signInError = const AuthException(
          'email not confirmed',
        );

        expect(
          () => repository.signIn(
            identifier: 'test@example.com',
            password: 'password123',
          ),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Email belum diverifikasi'),
            ),
          ),
        );
      });

      test('returns original message for unknown AuthException', () async {
        fakeClient.auth.signInError = const AuthException('unknown auth error');

        expect(
          () => repository.signIn(
            identifier: 'test@example.com',
            password: 'password123',
          ),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('unknown auth error'),
            ),
          ),
        );
      });

      test('throws generic exception if something else fails', () async {
        fakeClient.auth.signInError = Exception('Network Error');

        expect(
          () => repository.signIn(
            identifier: 'test@example.com',
            password: 'password123',
          ),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Terjadi kesalahan saat login'),
            ),
          ),
        );
      });

      test(
        'rethrows Username tidak ditemukan exception from rpc error correctly',
        () async {
          fakeClient.expectedUsername = 'johndoe';
          fakeClient.rpcError = Exception('Username tidak ditemukan');

          expect(
            () => repository.signIn(
              identifier: 'johndoe',
              password: 'password123',
            ),
            throwsA(
              isA<Exception>().having(
                (e) => e.toString(),
                'message',
                contains('Username tidak ditemukan'),
              ),
            ),
          );
        },
      );

      test(
        'throws generic Username tidak ditemukan on other rpc errors',
        () async {
          fakeClient.expectedUsername = 'johndoe';
          fakeClient.rpcError = Exception('Some DB exception');

          expect(
            () => repository.signIn(
              identifier: 'johndoe',
              password: 'password123',
            ),
            throwsA(
              isA<Exception>().having(
                (e) => e.toString(),
                'message',
                contains('Username tidak ditemukan'),
              ),
            ),
          );
        },
      );
    });

    group('signOut', () {
      test('completes successfully', () async {
        await expectLater(repository.signOut(), completes);
      });

      test('throws exception on error', () async {
        fakeClient.auth.signOutError = Exception('Failed to sign out');

        expect(
          () => repository.signOut(),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Gagal logout'),
            ),
          ),
        );
      });
    });

    group('currentUserProfile', () {
      test('returns null if currentUser is null', () async {
        fakeClient.auth.mockCurrentUser = null;
        final profile = await repository.getCurrentUserProfile();
        expect(profile, isNull);
      });

      test('returns profile data if user exists', () async {
        fakeClient.auth.mockCurrentUser = User(
          id: '123',
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          createdAt: '',
        );
        fakeClient.profileResult = {'role': 'admin', 'name': 'John Doe'};

        final profile = await repository.getCurrentUserProfile();
        expect(profile, isNotNull);
        expect(profile!['role'], 'admin');
      });

      test('returns null if profile query fails', () async {
        fakeClient.auth.mockCurrentUser = User(
          id: '123',
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          createdAt: '',
        );
        fakeClient.profileError = Exception('DB Error');

        final profile = await repository.getCurrentUserProfile();
        expect(profile, isNull);
      });
    });

    group('createUserByAdmin', () {
      test('completes successfully', () async {
        fakeClient.functions.expectedData = {'message': 'User created'};

        await expectLater(
          repository.createUserByAdmin(
            email: 'new@example.com',
            password: 'password123',
            name: 'New User',
            role: 'driver',
            noTelp: '08123456789',
          ),
          completes,
        );

        expect(fakeClient.functions.lastBody, isNotNull);
        expect(fakeClient.functions.lastBody!['email'], 'new@example.com');
      });

      test('throws exception if response contains error in data map', () async {
        fakeClient.functions.expectedData = {'error': 'Email already exists'};

        expect(
          () => repository.createUserByAdmin(
            email: 'new@example.com',
            password: 'password123',
            name: 'New User',
            role: 'driver',
            noTelp: '08123456789',
          ),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Email already exists'),
            ),
          ),
        );
      });

      test('throws exception if invoke fails generically', () async {
        fakeClient.functions.invokeError = Exception('Server Error');

        expect(
          () => repository.createUserByAdmin(
            email: 'new@example.com',
            password: 'password123',
            name: 'New User',
            role: 'driver',
            noTelp: '08123456789',
          ),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Gagal membuat user'),
            ),
          ),
        );
      });
    });
  });
}
