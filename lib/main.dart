import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'controllers/config_controller.dart';
import 'screens/main_shell.dart';

void main() {
  Get.put(ConfigController());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  ThemeData _buildLightTheme(String style) {
    final isClassic = style == "Classic";
    return ThemeData(
      fontFamily: "Segoe UI",
      brightness: Brightness.light,
      scaffoldBackgroundColor: isClassic
          ? const Color(0xFFF1F5F9)
          : const Color(0xFFF8FAFC),
      colorScheme: ColorScheme.light(
        primary: isClassic
            ? const Color(0xFF1565C0)
            : const Color(0xFF4F46E5), // Classic Blue vs Indigo
        secondary: isClassic
            ? const Color(0xFF00796B)
            : const Color(0xFF10B981), // Classic Teal vs Emerald
        surface: Colors.white,
        error: Colors.redAccent,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: isClassic
            ? const Color(0xFF1E293B)
            : const Color(0xFF0F172A),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isClassic ? 6 : 16),
          side: BorderSide(
            color: isClassic
                ? const Color(0xFFCBD5E1)
                : const Color(0xFFE2E8F0),
          ),
        ),
        elevation: isClassic ? 2 : 1,
      ),
      dividerTheme: DividerThemeData(
        color: isClassic ? const Color(0xFFE2E8F0) : const Color(0xFFE2E8F0),
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isClassic ? 6 : 12),
          borderSide: BorderSide(
            color: isClassic
                ? const Color(0xFFCBD5E1)
                : const Color(0xFFE2E8F0),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isClassic ? 6 : 12),
          borderSide: BorderSide(
            color: isClassic
                ? const Color(0xFFCBD5E1)
                : const Color(0xFFE2E8F0),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isClassic ? 6 : 12),
          borderSide: BorderSide(
            color: isClassic
                ? const Color(0xFF1565C0)
                : const Color(0xFF4F46E5),
            width: 2,
          ),
        ),
        labelStyle: TextStyle(
          color: isClassic ? const Color(0xFF475569) : const Color(0xFF64748B),
        ),
        hintStyle: TextStyle(
          color: isClassic ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8),
        ),
      ),
    );
  }

  ThemeData _buildDarkTheme(String style) {
    final isClassic = style == "Classic";
    return ThemeData(
      fontFamily: "Segoe UI",
      brightness: Brightness.dark,
      scaffoldBackgroundColor: isClassic
          ? const Color(0xFF121212)
          : const Color(0xFF0F172A),
      colorScheme: ColorScheme.dark(
        primary: isClassic
            ? const Color(0xFF90CAF9)
            : const Color(0xFF6366F1), // Classic Light Blue vs Indigo 500
        secondary: isClassic
            ? const Color(0xFF80CBC4)
            : const Color(0xFF10B981), // Classic Teal 200 vs Emerald 500
        surface: isClassic ? const Color(0xFF1E1E1E) : const Color(0xFF1E293B),
        error: Colors.redAccent,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: isClassic ? const Color(0xFF1E1E1E) : const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isClassic ? 6 : 16),
          side: BorderSide(color: isClassic ? Colors.white24 : Colors.white10),
        ),
        elevation: isClassic ? 4 : 4,
      ),
      dividerTheme: DividerThemeData(
        color: isClassic ? Colors.white24 : Colors.white10,
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.03),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isClassic ? 6 : 12),
          borderSide: BorderSide(
            color: isClassic ? Colors.white24 : Colors.white10,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isClassic ? 6 : 12),
          borderSide: BorderSide(
            color: isClassic ? Colors.white24 : Colors.white10,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isClassic ? 6 : 12),
          borderSide: BorderSide(
            color: isClassic
                ? const Color(0xFF90CAF9)
                : const Color(0xFF6366F1),
          ),
        ),
        labelStyle: const TextStyle(color: Colors.white60),
        hintStyle: const TextStyle(color: Colors.white30),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ConfigController controller = Get.find<ConfigController>();
    return Obx(() {
      final currentStyle = controller.themeStyle.value;
      return GetMaterialApp(
        title: 'ConfigEditor',
        debugShowCheckedModeBanner: false,
        themeMode: controller.themeMode.value,
        theme: _buildLightTheme(currentStyle),
        darkTheme: _buildDarkTheme(currentStyle),
        builder: (context, child) {
          final scale = controller.fontSize.value == "Reduced" ? 0.9 : 1.05;
          return MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          );
        },
        home: const MainShell(),
      );
    });
  }
}
