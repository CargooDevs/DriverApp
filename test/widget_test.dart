import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cargoo_driver/main.dart';
import 'package:cargoo_driver/screens/auth/driver_login_screen.dart';

void main() {
  testWidgets('exibe a tela inicial do app motorista', (tester) async {
    await tester.pumpWidget(const CargooDriverApp());

    expect(find.text('Cargoo'), findsOneWidget);
    expect(find.text('MOTORISTA'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1400));
    await tester.pumpAndSettle();
  });

  testWidgets('exibe o formulário de login do motorista', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: DriverLoginScreen()));

    expect(find.text('Bem-vindo de volta'), findsOneWidget);
    expect(find.text('E-mail'), findsOneWidget);
    expect(find.text('Senha'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });
}
