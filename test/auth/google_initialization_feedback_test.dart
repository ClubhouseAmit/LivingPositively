import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mazilon/features/auth/data/auth_repository.dart';
import 'package:mazilon/features/auth/data/google_auth_models.dart';
import 'package:mazilon/features/auth/ui/auth_error_reporting.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/pages/auth_page.dart';

import '../helpers/widget_test_scaffold.dart';

void main() {
  group('Google initialization feedback', () {
    tearDown(() async {
      AuthService.debugGoogleSignInStarterOverride = null;
      AuthService.debugGoogleSignInServerClientIdOverride = null;
      debugDefaultTargetPlatformOverride = null;
      await GetIt.instance.reset();
    });

    for (final language in ['en', 'he', 'ar']) {
      testWidgets('should explain restart in $language and report once', (
        tester,
      ) async {
        final services = registerTestServices(locale: language);
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        try {
          AuthService.debugGoogleSignInServerClientIdOverride = 'server-client';
          const cause = GoogleSignInException(
            code: GoogleSignInExceptionCode.clientConfigurationError,
          );
          final failure = GoogleSignInInitializationFailure(
            cause,
            StackTrace.current,
          );
          AuthService.debugGoogleSignInStarterOverride = ({
            required serverClientId,
            clientId,
          }) async => throw failure;
          final locale = Locale(language);
          final strings = await AppLocalizations.delegate.load(locale);
          await pumpWithProviders(tester, const AuthPage(), locale: locale);

          for (var attempt = 0; attempt < 2; attempt++) {
            await tester.tap(find.text(strings.authGoogleButton));
            await tester.pumpAndSettle();
            expect(find.text(strings.authErrorGoogleRestart), findsOneWidget);
            expect(find.text(strings.authErrorGeneric), findsNothing);
          }
          expect(services.logger.captured, [same(cause)]);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      });
    }

    test('should share the incident claim across form instances', () async {
      final services = registerTestServices();
      final cause = StateError('initialization failed');
      final failure = GoogleSignInInitializationFailure(
        cause,
        StackTrace.current,
      );
      await reportAuthenticationError(failure, StackTrace.current);
      await reportAuthenticationError(failure, StackTrace.current);
      expect(services.logger.captured, [same(cause)]);
    });
  });
}
