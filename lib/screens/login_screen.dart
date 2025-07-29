import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController srCodeController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  bool showPassword = false;
  String? errorMsg;

  late AnimationController _animController;
  late Animation<Offset> _formSlide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _formSlide = Tween<Offset>(begin: Offset(0, 0.3), end: Offset(0, 0)).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOutBack));
    _fade = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    Future.delayed(Duration(milliseconds: 250), () {
      if (mounted) _animController.forward();
    });
  }

  @override
  void dispose() {
    srCodeController.dispose();
    passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    setState(() {
      isLoading = true;
      errorMsg = null;
    });

    try {
      final url = Uri.parse('http://192.168.1.19:5000/login');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': srCodeController.text.trim(),
          'password': passwordController.text.trim(),
        }),
      );

      if (!mounted) return;

      final json = jsonDecode(response.body);
      if (response.statusCode == 200 && json['success'] == true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      } else {
        setState(() {
          errorMsg = json['message'] ?? 'Login failed. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        errorMsg = 'Login failed. Please try again.';
      });
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Container(
              color: Colors.grey[50],
            ),
          ),
          // Centered content
          Center(
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _formSlide,
                child: SingleChildScrollView(
                  child: Card(
                    margin: EdgeInsets.symmetric(horizontal: 24),
                    color: Colors.white.withOpacity(0.98),
                    elevation: 10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Logo
                          ClipOval(
                            child: Image.asset(
                              'assets/images/winyfi_logo.png',
                              height: 80,
                              width: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Welcome Back",
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.red[700],
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Log in to your WinyFi account",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Username field
                          TextField(
                            controller: srCodeController,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.person, color: Colors.red[600]),
                              labelText: 'Username',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              filled: true,
                              fillColor: Colors.grey[100],
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Password field with toggle
                          TextField(
                            controller: passwordController,
                            obscureText: !showPassword,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => !isLoading ? login() : null,
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.lock, color: Colors.red[600]),
                              labelText: 'Password',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              filled: true,
                              fillColor: Colors.grey[100],
                              suffixIcon: IconButton(
                                icon: Icon(
                                  showPassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: Colors.grey[700],
                                ),
                                onPressed: () {
                                  setState(() {
                                    showPassword = !showPassword;
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Error message
                          if (errorMsg != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10.0),
                              child: Text(
                                errorMsg!,
                                style: TextStyle(color: Colors.red[800], fontWeight: FontWeight.w500),
                              ),
                            ),

                          // Login button
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red[700],
                                foregroundColor: Colors.white,
                                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                elevation: 6,
                              ),
                              onPressed: isLoading ? null : login,
                              child: isLoading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.3,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text("Login"),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: isLoading ? null : () {
                              setState(() {
                                srCodeController.clear();
                                passwordController.clear();
                                errorMsg = null;
                              });
                            },
                            child: const Text("Clear", style: TextStyle(fontSize: 15)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Footer
          Positioned(
            left: 0,
            right: 0,
            bottom: 18,
            child: Center(
              child: Text(
                "Powered by WinyFi • ${DateTime.now().year}",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          // Loading overlay
          if (isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.05),
                child: Center(
                  child: CircularProgressIndicator(color: Colors.red[700]),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
