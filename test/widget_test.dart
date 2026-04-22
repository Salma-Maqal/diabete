import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:diabete_app1/main.dart';

void main() {
  testWidgets('App loads without crash', (WidgetTester tester) async {
    await tester.pumpWidget(const CalmSugarApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  group('WelcomeScreen', () {
    testWidgets('Both buttons are visible', (WidgetTester tester) async {
      await tester.pumpWidget(const CalmSugarApp());
      await tester.pumpAndSettle(const Duration(seconds: 4));

      expect(find.text('Sign Up to page'), findsOneWidget);
      expect(find.text('Déjà un compte ? Se connecter'), findsOneWidget);
    });

    testWidgets('Sign Up navigates to SignUpScreen', (WidgetTester tester) async {
      await tester.pumpWidget(const CalmSugarApp());
      await tester.pumpAndSettle(const Duration(seconds: 4));

      await tester.tap(find.text('Sign Up to page'));
      await tester.pumpAndSettle();

      expect(find.text("S'inscrire"), findsWidgets);
    });

    testWidgets('Se connecter navigates to LoginScreen', (WidgetTester tester) async {
      await tester.pumpWidget(const CalmSugarApp());
      await tester.pumpAndSettle(const Duration(seconds: 4));

      await tester.tap(find.text('Déjà un compte ? Se connecter'));
      await tester.pumpAndSettle();

      expect(find.text('Se Connecter'), findsWidgets);
    });
  });

  group('LoginScreen', () {
    Future<void> goToLogin(WidgetTester tester) async {
      await tester.pumpWidget(const CalmSugarApp());
      await tester.pumpAndSettle(const Duration(seconds: 4));
      await tester.tap(find.text('Déjà un compte ? Se connecter'));
      await tester.pumpAndSettle();
    }

    testWidgets('Email and password fields are visible', (WidgetTester tester) async {
      await goToLogin(tester);
      expect(find.text('E-mail'), findsOneWidget);
      expect(find.text('Mot de passe'), findsOneWidget);
    });

    testWidgets('Shows error message without data', (WidgetTester tester) async {
      await goToLogin(tester);

      await tester.tap(find.text('Se connecter').last);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('Veuillez remplir tous les champs.'), findsOneWidget);
    });

    testWidgets('With email and password navigates to Dashboard', (WidgetTester tester) async {
      await goToLogin(tester);

      await tester.enterText(
        find.widgetWithText(TextField, 'exemple@gmail.com'),
        'test@gmail.com',
      );
      await tester.enterText(
        find.widgetWithText(TextField, '••••••••').first,
        'password123',
      );

      await tester.tap(find.text('Se connecter').last);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.text('CalmSugar'), findsWidgets);
    });

    testWidgets('Forgot password navigates to ForgotPassword', (WidgetTester tester) async {
      await goToLogin(tester);

      await tester.tap(find.text('Mot de passe oublié ?'));
      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('SignUpScreen', () {
    Future<void> goToSignup(WidgetTester tester) async {
      await tester.pumpWidget(const CalmSugarApp());
      await tester.pumpAndSettle(const Duration(seconds: 4));
      await tester.tap(find.text('Sign Up to page'));
      await tester.pumpAndSettle();
    }

    testWidgets('Name fields are visible', (WidgetTester tester) async {
      await goToSignup(tester);
      expect(find.text('Nom'), findsOneWidget);
      expect(find.text('Prénom'), findsOneWidget);
      expect(find.text('E-mail'), findsOneWidget);
    });

    testWidgets('Shows error without data', (WidgetTester tester) async {
      await goToSignup(tester);

      await tester.tap(find.text("J'accepte les "));
      await tester.pumpAndSettle();

      await tester.tap(find.text("S'inscrire").last);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('Veuillez remplir tous les champs.'), findsOneWidget);
    });

    testWidgets('Shows error without conditions accepted', (WidgetTester tester) async {
      await goToSignup(tester);

      await tester.tap(find.text("S'inscrire").last);
      await tester.pumpAndSettle();

      expect(
        find.text("Veuillez accepter les conditions d'utilisation."),
        findsOneWidget,
      );
    });

    testWidgets('Both roles are visible — Diabétique and Accompagnant', (WidgetTester tester) async {
      await goToSignup(tester);
      expect(find.text('Diabétique'), findsOneWidget);
      expect(find.text('Accompagnant'), findsOneWidget);
    });

    testWidgets('Mismatched passwords shows error', (WidgetTester tester) async {
      await goToSignup(tester);

      await tester.enterText(find.widgetWithText(TextField, 'Benali'), 'Benali');
      await tester.enterText(find.widgetWithText(TextField, 'Sara'), 'Sara');
      await tester.enterText(
          find.widgetWithText(TextField, 'exemple@gmail.com'), 'test@gmail.com');

      final passFields = find.widgetWithText(TextField, '••••••••');
      await tester.enterText(passFields.first, 'pass1234');
      await tester.enterText(passFields.last, 'different');

      await tester.tap(find.byType(AnimatedContainer).first);
      await tester.pumpAndSettle();

      await tester.tap(find.text("S'inscrire").last);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(
        find.text('Les mots de passe ne correspondent pas.'),
        findsOneWidget,
      );
    });
  });

  group('DashboardScreen', () {
    Future<void> goToDashboard(WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('test')),
        ),
      ));
      await tester.pumpWidget(const CalmSugarApp());
      await tester.pumpAndSettle(const Duration(seconds: 4));
      await tester.tap(find.text('Déjà un compte ? Se connecter'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.widgetWithText(TextField, 'exemple@gmail.com'), 'a@a.com');
      await tester.enterText(
          find.widgetWithText(TextField, '••••••••').first, '123456');
      await tester.tap(find.text('Se connecter').last);
      await tester.pumpAndSettle(const Duration(seconds: 3));
    }

    testWidgets('Dashboard shows CalmSugar in AppBar', (WidgetTester tester) async {
      await goToDashboard(tester);
      expect(find.text('CalmSugar'), findsWidgets);
    });

    testWidgets('Quick actions are visible', (WidgetTester tester) async {
      await goToDashboard(tester);
      expect(find.text('Actions rapides'), findsOneWidget);
      expect(find.text('Ajouter un accompagnant'), findsOneWidget);
      expect(find.text('Saisir ma glycémie'), findsOneWidget);
    });

    testWidgets('Logout navigates back to Welcome', (WidgetTester tester) async {
      await goToDashboard(tester);
      await tester.tap(find.byIcon(Icons.logout));
      await tester.pumpAndSettle();
      expect(find.text('Welcome'), findsOneWidget);
    });
  });
}