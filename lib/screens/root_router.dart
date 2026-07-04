import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/alerts_provider.dart';
import '../state/session_provider.dart';
import 'auth/login_screen.dart';
import 'customer/customer_home_screen.dart';
import 'seller/seller_dashboard_screen.dart';

class RootRouter extends StatelessWidget {
  const RootRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();

    switch (session.status) {
      case SessionStatus.loading:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case SessionStatus.loggedOut:
        return const LoginScreen();
      case SessionStatus.loggedIn:
        final user = session.currentUser!;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<AlertsProvider>().start(user.id);
        });
        return user.isStore ? const SellerDashboardScreen() : const CustomerHomeScreen();
    }
  }
}
