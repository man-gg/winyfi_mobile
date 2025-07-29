import 'package:flutter/material.dart';
import 'dart:async';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;

  late final AnimationController _textController;
  late final Animation<double> _textFade;

  late final AnimationController _buttonController;
  late final Animation<Offset> _buttonSlide;

  bool showSpinner = false; // Set to true if you want to show a loading spinner

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _logoScale = CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOutBack,
    );
    _logoFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeIn),
    );

    _textController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _textFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeIn),
    );

    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _buttonSlide = Tween<Offset>(begin: Offset(0, 1), end: Offset(0, 0)).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeOutBack),
    );

    // Sequence the animations
    _logoController.forward().then((_) {
      _textController.forward().then((_) {
        _buttonController.forward();
      });
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  void _onLoginPressed() async {
    setState(() {
      showSpinner = true;
    });
    // Simulate a network request delay (optional)
    await Future.delayed(Duration(milliseconds: 900));
    setState(() {
      showSpinner = false;
    });
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/batangas_state.jpg',
            fit: BoxFit.cover,
          ),
          Container(
            color: Colors.black.withOpacity(0.35),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 90),
                // Logo
                FadeTransition(
                  opacity: _logoFade,
                  child: ScaleTransition(
                    scale: _logoScale,
                    child: ClipOval(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.93),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 16,
                              offset: Offset(0, 6),
                            )
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/winyfi_logo.png',
                          height: 140,
                          width: 140,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                // Welcome text
                FadeTransition(
                  opacity: _textFade,
                  child: Text(
                    "Welcome to WinyFi",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                            color: Colors.black45,
                            blurRadius: 6,
                            offset: Offset(1, 2))
                      ],
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                FadeTransition(
                  opacity: _textFade,
                  child: Text(
                    "Your smart network monitor",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.95),
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.5,
                      shadows: [
                        Shadow(
                            color: Colors.black38,
                            blurRadius: 4,
                            offset: Offset(1, 2))
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 45),
                // Login button with animation
                SlideTransition(
                  position: _buttonSlide,
                  child: showSpinner
                      ? const CircularProgressIndicator(
                          color: Colors.redAccent,
                        )
                      : ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[700],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                vertical: 15, horizontal: 38),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            elevation: 7,
                          ),
                          icon: const Icon(Icons.login),
                          label: const Text(
                            "Login",
                            style: TextStyle(fontSize: 19),
                          ),
                          onPressed: _onLoginPressed,
                        ),
                ),
                const Spacer(),
                // Powered by footer
                Padding(
                  padding: const EdgeInsets.only(bottom: 30),
                  child: AnimatedOpacity(
                    opacity: 1,
                    duration: Duration(seconds: 2),
                    child: Text(
                      "Powered by WinyFi • ${DateTime.now().year}",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
