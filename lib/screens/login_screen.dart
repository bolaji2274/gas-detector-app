// ==================== LOGIN_SCREEN.DART ====================
// lib/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../utils/theme.dart';
import '../utils/helpers.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isLogin = true;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);

    bool success;

    if (_isLogin) {
      success = await authService.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );
    } else {
      success = await authService.signUpWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
      );
    }

    if (!mounted) return;

    if (success) {
      // Initialize Firebase service
      await firebaseService.initialize();

      if (!mounted) return;

      Helpers.showSnackBar(
        context,
        _isLogin ? 'Welcome back!' : 'Account created successfully!',
      );

      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Helpers.showSnackBar(
        context,
        authService.errorMessage ?? 'Authentication failed',
        isError: true,
      );
    }
  }

  // UPDATED: Google Sign In Handler
  Future<void> _handleGoogleSignIn() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);

    final success = await authService.signInWithGoogle();

    if (!mounted) return;

    if (success) {
      await firebaseService.initialize();

      if (!mounted) return;

      Helpers.showSnackBar(context, 'Welcome!');
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      if (authService.errorMessage != null) {
        Helpers.showSnackBar(
          context,
          authService.errorMessage!,
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.science,
                      size: 50,
                      color: AppTheme.primaryColor,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Title
                  Text(
                    _isLogin ? 'Welcome Back' : 'Create Account',
                    style: Theme.of(context).textTheme.displaySmall,
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 10),

                  Text(
                    _isLogin
                        ? 'Sign in to continue monitoring'
                        : 'Sign up to start protecting your home',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 40),

                  // Name Field (Sign Up only)
                  if (!_isLogin) ...[
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!Helpers.isValidEmail(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Remember Me / Forgot Password
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_isLogin)
                        Row(
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              onChanged: (value) {
                                setState(() {
                                  _rememberMe = value ?? false;
                                });
                              },
                            ),
                            const Text('Remember me'),
                          ],
                        ),
                      const Spacer(),
                      if (_isLogin)
                        TextButton(
                          onPressed: () {
                            _showForgotPasswordDialog();
                          },
                          child: const Text('Forgot Password?'),
                        ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Submit Button
                  ElevatedButton(
                    onPressed: authService.isLoading ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: authService.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            _isLogin ? 'Sign In' : 'Sign Up',
                            style: const TextStyle(fontSize: 16),
                          ),
                  ),

                  const SizedBox(height: 24),

                  // Toggle Login/Signup
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isLogin
                            ? "Don't have an account? "
                            : 'Already have an account? ',
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isLogin = !_isLogin;
                            _formKey.currentState?.reset();
                          });
                        },
                        child: Text(
                          _isLogin ? 'Sign Up' : 'Sign In',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Divider
                  const Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('OR'),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // UPDATED: Google Sign In Button
                  OutlinedButton.icon(
                    onPressed:
                        authService.isLoading ? null : _handleGoogleSignIn,
                    icon: Image.asset(
                      'assets/icons/google.png',
                      height: 24,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.g_mobiledata, size: 32);
                      },
                    ),
                    label: const Text('Continue with Google'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // UPDATED: Forgot Password Dialog with navigation back to login
  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter your email address and we\'ll send you a link to reset your password.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = emailController.text.trim();

              if (email.isEmpty) {
                Helpers.showSnackBar(
                  context,
                  'Please enter your email',
                  isError: true,
                );
                return;
              }

              if (!Helpers.isValidEmail(email)) {
                Helpers.showSnackBar(
                  context,
                  'Please enter a valid email',
                  isError: true,
                );
                return;
              }

              // Close dialog first
              Navigator.pop(context);

              final authService =
                  Provider.of<AuthService>(context, listen: false);
              final success = await authService.resetPassword(email);

              if (!mounted) return;

              if (success) {
                // Show success dialog with navigation back
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => AlertDialog(
                    title: const Row(
                      children: [
                        Icon(Icons.check_circle, color: AppTheme.successColor),
                        SizedBox(width: 8),
                        Text('Email Sent'),
                      ],
                    ),
                    content: Text(
                      'Password reset email sent to $email.\n\nPlease check your inbox and follow the instructions to reset your password.',
                    ),
                    actions: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context); // Close dialog
                          // Already on login screen, just show snackbar
                          Helpers.showSnackBar(
                            context,
                            'You can now sign in with your new password',
                          );
                        },
                        child: const Text('Back to Login'),
                      ),
                    ],
                  ),
                );
              } else {
                Helpers.showSnackBar(
                  context,
                  authService.errorMessage ?? 'Failed to send reset email',
                  isError: true,
                );
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}
