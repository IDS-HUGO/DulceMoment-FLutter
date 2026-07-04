import 'package:flutter/material.dart';

/// Paleta de colores de Dulce Moment
class DulceColors {
  DulceColors._();

  // Primarios
  static const chocolateDark = Color(0xFF3E2723);
  static const chocolate = Color(0xFF5D4037);
  static const chocolateLight = Color(0xFF8D6E63);

  // Acentos
  static const rose = Color(0xFFE91E8C);
  static const roseSoft = Color(0xFFF48FB1);
  static const roseLight = Color(0xFFFCE4EC);

  // Neutros crema
  static const cream = Color(0xFFFFF8E7);
  static const creamDark = Color(0xFFFFF3E0);
  static const sand = Color(0xFFD7CCC8);

  // Estado
  static const success = Color(0xFF2E7D32);
  static const warning = Color(0xFFF57F17);
  static const error = Color(0xFFC62828);
  static const info = Color(0xFF1565C0);

  // Gradientes
  static const gradientPrimary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5D4037), Color(0xFF3E2723)],
  );

  static const gradientBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFF8E7), Color(0xFFFCE4EC)],
  );

  static const gradientRose = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE91E8C), Color(0xFFAD1457)],
  );

  static const gradientCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Colors.white, Color(0xFFFFF8E7)],
  );
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    const seed = Color(0xFF5D4037);

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Roboto',
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        brightness: Brightness.light,
        primary: DulceColors.chocolate,
        onPrimary: Colors.white,
        secondary: DulceColors.rose,
        onSecondary: Colors.white,
        tertiary: DulceColors.roseSoft,
        surface: DulceColors.cream,
        onSurface: DulceColors.chocolateDark,
        error: DulceColors.error,
      ),
      scaffoldBackgroundColor: DulceColors.cream,
      appBarTheme: AppBarTheme(
        backgroundColor: DulceColors.chocolate,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 3,
        shadowColor: DulceColors.chocolate.withValues(alpha: 0.15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.only(bottom: 12),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: DulceColors.sand, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: DulceColors.sand, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: DulceColors.chocolate, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: DulceColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: DulceColors.error, width: 2),
        ),
        labelStyle: TextStyle(color: DulceColors.chocolateLight),
        hintStyle: TextStyle(color: DulceColors.chocolateLight.withOpacity(0.6)),
        prefixIconColor: DulceColors.chocolateLight,
        suffixIconColor: DulceColors.chocolateLight,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DulceColors.chocolate,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: DulceColors.chocolate,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          minimumSize: const Size(double.infinity, 52),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: DulceColors.chocolate,
          side: const BorderSide(color: DulceColors.chocolate, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          minimumSize: const Size(double.infinity, 52),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: DulceColors.rose,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: DulceColors.creamDark,
        selectedColor: DulceColors.chocolate,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide(color: DulceColors.sand),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: DulceColors.roseLight,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: DulceColors.rose, size: 24);
          }
          return IconThemeData(color: DulceColors.chocolateLight, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: DulceColors.rose,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            );
          }
          return TextStyle(
            color: DulceColors.chocolateLight,
            fontWeight: FontWeight.w500,
            fontSize: 12,
          );
        }),
        elevation: 8,
        shadowColor: DulceColors.chocolate.withOpacity(0.1),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: DulceColors.rose,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFEEEEEE),
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: DulceColors.chocolateDark,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
        insetPadding: const EdgeInsets.all(16),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: DulceColors.rose,
      ),
    );
  }
}

/// Widgets de utilidad compartidos
class DulceWidgets {
  DulceWidgets._();

  /// SnackBar de éxito
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: DulceColors.success,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// SnackBar de error
  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: DulceColors.error,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// SnackBar informativo
  static void showInfo(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Estado de carga premium
  static Widget loadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            strokeWidth: 3,
            color: DulceColors.rose,
          ),
          const SizedBox(height: 16),
          Text(
            'Cargando...',
            style: TextStyle(
              color: DulceColors.chocolateLight,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Estado vacío premium
  static Widget emptyState(String message, {IconData icon = Icons.inbox_outlined}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: DulceColors.sand),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: DulceColors.chocolateLight,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Chip de estado de pedido
  static Widget statusChip(String status) {
    final config = _statusConfig(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: config.$1.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: config.$1.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: config.$1, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            config.$2,
            style: TextStyle(
              color: config.$1,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  static (Color, String) _statusConfig(String status) {
    switch (status) {
      case 'created':
        return (DulceColors.info, 'Confirmado');
      case 'in_oven':
        return (DulceColors.warning, 'En horno');
      case 'decorating':
        return (Color(0xFF9C27B0), 'Decorando');
      case 'on_the_way':
        return (Color(0xFF0288D1), 'En camino');
      case 'delivered':
        return (DulceColors.success, 'Entregado');
      case 'cancelled':
        return (DulceColors.error, 'Cancelado');
      default:
        return (DulceColors.chocolateLight, status);
    }
  }

  /// Gradiente AppBar
  static PreferredSizeWidget gradientAppBar({
    required String title,
    List<Widget>? actions,
    Widget? leading,
    bool centerTitle = true,
  }) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: Container(
        decoration: const BoxDecoration(
          gradient: DulceColors.gradientPrimary,
          boxShadow: [
            BoxShadow(
              color: Color(0x405D4037),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: AppBar(
          title: Text(title),
          backgroundColor: Colors.transparent,
          actions: actions,
          leading: leading,
          centerTitle: centerTitle,
        ),
      ),
    );
  }
}
