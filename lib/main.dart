import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/main_wrapper.dart';
import 'services/notification_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LoFiToDoApp());
}

class LoFiToDoApp extends StatelessWidget {
  const LoFiToDoApp({super.key});

  Future<Map<String, dynamic>> _loadSystemData() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    final prefs = await SharedPreferences.getInstance();
    final String? savedName = prefs.getString('user_name');
    final String? savedAvatar = prefs.getString('user_avatar');

    final Map<String, int> loadedAvatarXps = {};
    for (int i = 1; i <= 48; i++) {
      loadedAvatarXps['Icon$i'] = prefs.getInt('xp_Icon$i') ?? 0;
    }

    final notificationService = NotificationService();
    await notificationService.init();
    await notificationService.requestPermissions();

    return {
      'name': savedName,
      'avatar': savedAvatar ?? 'Icon1',
      'xps': loadedAvatarXps,
    };
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Retro Yapılacaklar Listesi',
      theme: ThemeData(
        fontFamily: 'Courier',
        scaffoldBackgroundColor: const Color(0xFF141526),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFE5A96A),
          surface: Color(0xFF282A45),
        ),
      ),
      home: FutureBuilder<Map<String, dynamic>>(
        future: _loadSystemData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFFE5A96A)),
                    SizedBox(height: 16),
                    Text(
                      "Retro Sistem Yükleniyor...",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
            );
          }

          if (snapshot.hasError) {
            return Scaffold(
              backgroundColor: Colors.red.shade900,
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    "BİR HATA OLUŞTU:\n\n${snapshot.error}",
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          }

          final data = snapshot.data!;
          if (data['name'] == null) {
            return NamePromptScreen(allAvatarXps: data['xps']);
          } else {
            return MainWrapper(
              userName: data['name'],
              userAvatar: data['avatar'],
              allAvatarXps: data['xps'],
            );
          }
        },
      ),
    );
  }
}

class NamePromptScreen extends StatefulWidget {
  final Map<String, int> allAvatarXps;
  const NamePromptScreen({super.key, required this.allAvatarXps});

  @override
  State<NamePromptScreen> createState() => _NamePromptScreenState();
}

class _NamePromptScreenState extends State<NamePromptScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;
  String _selectedAvatar = 'Icon1';

  OverlayEntry? _zoomOverlay;

  Future<void> _saveNameAndProceed() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    String name = _nameController.text.trim();
    if (name.isEmpty) name = "Gezgin";

    try {
      FocusScope.of(context).unfocus();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', name);
      await prefs.setString('user_avatar', _selectedAvatar);

      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MainWrapper(
            userName: name,
            userAvatar: _selectedAvatar,
            allAvatarXps: widget.allAvatarXps,
          ),
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAvatarZoom(BuildContext context, String iconName) {
    if (_zoomOverlay != null) return;
    FocusScope.of(context).unfocus();

    _zoomOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 200),
              builder: (context, val, child) =>
                  Container(color: Colors.black.withValues(alpha: 0.85 * val)),
            ),
          ),
          Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.5, end: 1.0),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              builder: (context, val, child) => Transform.scale(
                scale: val,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    'img/Icons/$iconName.png',
                    width: 280,
                    height: 280,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_zoomOverlay!);
  }

  void _hideAvatarZoom(BuildContext context) {
    _zoomOverlay?.remove();
    _zoomOverlay = null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'img/background.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Container(color: const Color(0xFF141526)),
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.65)),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF282A45).withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFE5A96A),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 20,
                          spreadRadius: 2,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          color: Color(0xFFE5A96A),
                          size: 36,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "Yeni Bir Başlangıç",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Sana nasıl hitap edelim?",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _nameController,
                          maxLength: 16,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                          decoration: const InputDecoration(
                            hintText: "en fazla 16 karakter",
                            hintStyle: TextStyle(
                              color: Colors.white38,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                            counterText: "",
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFF535882)),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: Color(0xFFE5A96A),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Karakterini Seç",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                "(daha sonra değiştirebilirsin)",
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 10,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 200,
                          child: GridView.builder(
                            physics: const BouncingScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 6,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              childAspectRatio: 1.0,
                            ),
                            itemCount: 48,
                            itemBuilder: (context, index) {
                              String iconName = 'Icon${index + 1}';
                              bool isSelected = _selectedAvatar == iconName;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedAvatar = iconName;
                                  });
                                },
                                onLongPressStart: (_) =>
                                    _showAvatarZoom(context, iconName),
                                onLongPressEnd: (_) => _hideAvatarZoom(context),
                                onLongPressCancel: () =>
                                    _hideAvatarZoom(context),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFFE5A96A)
                                        : const Color(0xFF141526),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.white
                                          : const Color(0xFF535882),
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Image.asset(
                                      'img/Icons/$iconName.png',
                                      fit: BoxFit.cover,
                                      gaplessPlayback: true,
                                      errorBuilder:
                                          (context, error, stackTrace) => Icon(
                                        Icons.person,
                                        color: isSelected
                                            ? const Color(0xFF282A45)
                                            : Colors.white54,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE5A96A),
                              foregroundColor: const Color(0xFF282A45),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              elevation: 5,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: _isLoading ? null : _saveNameAndProceed,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF282A45),
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Başlayalım",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Icon(Icons.arrow_forward_ios, size: 16),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Dikkatinize! Tüm verileriniz yalnızca bu cihazda (yerel olarak) saklanır. Uygulamayı silmeniz durumunda tüm kayıtlarınız kalıcı olarak silinebilir.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}