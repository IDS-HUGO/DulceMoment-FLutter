import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/app_theme.dart';
import 'core/supabase_config.dart';
import 'screens/root_router.dart';
import 'services/dulce_repository.dart';
import 'state/alerts_provider.dart';
import 'state/catalog_provider.dart';
import 'state/orders_provider.dart';
import 'state/session_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.init();
  runApp(const DulceMomentApp());
}

class DulceMomentApp extends StatelessWidget {
  const DulceMomentApp({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = DulceRepository();

    return MultiProvider(
      providers: [
        Provider<DulceRepository>.value(value: repository),
        ChangeNotifierProvider(create: (_) => SessionProvider(repository)),
        ChangeNotifierProvider(create: (_) => CatalogProvider(repository)),
        ChangeNotifierProvider(create: (_) => OrdersProvider(repository)),
        ChangeNotifierProvider(create: (_) => AlertsProvider(repository)),
      ],
      child: MaterialApp(
        title: 'Dulce Moment',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const RootRouter(),
      ),
    );
  }
}
