import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../utils/app_colors.dart';
import 'main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.grisClair, // Light Grey Background
      body: Stack(
        children: [
          // 1. Header: Curved Blue Section
          ClipPath(
            clipper: HeaderClipper(),
            child: Container(
              height: size.height * 0.45,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF153E6A), // Slightly darker for gradient depth
                    AppColors.bleuStock, // #1B4F8B
                  ],
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo Integration
                    Container(
                      height: 80,
                      width: 120, // Rectangular width
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16), // Rounded rectangle
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Image.asset(
                        'assets/logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback icon if asset is missing
                          return const Icon(Icons.inventory_2, size: 40, color: Colors.white);
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "StockMaster",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Inventory Management System",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 40), // Space for the curve
                  ],
                ),
              ),
            ),
          ),

          // 2. Center: White Card
          Align(
            alignment: Alignment.bottomCenter,
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                top: size.height * 0.35, // Push down to overlap curve slightly
                left: 24,
                right: 24,
                bottom: 24,
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            "Welcome Back",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.grisFonce,
                            ),
                          ),
                          const SizedBox(height: 30),

                          // Username Field
                          _buildModernTextField(
                            controller: _usernameController,
                            label: "Username",
                            icon: Icons.person_outline,
                          ),
                          const SizedBox(height: 20),

                          // Password Field
                          _buildModernTextField(
                            controller: _passwordController,
                            label: "Password",
                            icon: Icons.lock_outline,
                            isPassword: true,
                          ),
                          
                          const SizedBox(height: 12),
                          // Forgot Password
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                // TODO: Implement forgot password
                              },
                              child: const Text(
                                "Forgot Password?",
                                style: TextStyle(
                                  color: AppColors.grisMaster,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Login Button
                          SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.bleuStock,
                                foregroundColor: Colors.white,
                                elevation: 4,
                                shadowColor: AppColors.bleuStock.withOpacity(0.4),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: authViewModel.isLoading
                                  ? null
                                  : () async {
                                      if (_formKey.currentState!.validate()) {
                                        final success = await authViewModel.login(
                                          _usernameController.text,
                                          _passwordController.text,
                                        );
                                        if (success && mounted) {
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(builder: (_) => const MainScreen()),
                                          );
                                        } else if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: const Text("Invalid Credentials"),
                                              backgroundColor: AppColors.rougeErreur,
                                              behavior: SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            ),
                                          );
                                        }
                                      }
                                    },
                              child: authViewModel.isLoading
                                  ? const SizedBox(
                                      height: 24, width: 24,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : const Text(
                                      "Log In",
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Create Account Button
                          SizedBox(
                            height: 56,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.bleuStock, width: 1.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                foregroundColor: AppColors.bleuStock,
                              ),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Account creation disabled in demo mode.")),
                                );
                              },
                              child: const Text(
                                "Create Account",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  const Text(
                    "© 2025 StockMaster Inc.",
                    style: TextStyle(color: AppColors.grisMaster, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.grisMaster),
        filled: true,
        fillColor: AppColors.grisClair,
        prefixIcon: Icon(icon, color: AppColors.bleuStock),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.bleuStock, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.rougeErreur, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.rougeErreur, width: 2),
        ),
      ),
      validator: (value) => value!.isEmpty ? "Required" : null,
    );
  }
}

// Custom Clipper for the curved header
class HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 60); // Start slightly above bottom left
    
    // Create a quadratic bezier curve
    // Control point is at the bottom center, End point is at bottom right - 60
    final controlPoint = Offset(size.width / 2, size.height + 20);
    final endPoint = Offset(size.width, size.height - 60);
    
    path.quadraticBezierTo(
      controlPoint.dx, 
      controlPoint.dy, 
      endPoint.dx, 
      endPoint.dy
    );
    
    path.lineTo(size.width, 0); // Line to top right
    path.close(); // Close back to top left
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}