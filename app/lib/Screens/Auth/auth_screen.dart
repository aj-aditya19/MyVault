import 'package:app/core/services/storage_service.dart';
import 'package:app/core/services/sync_manager.dart';
import 'package:flutter/material.dart';

class AuthScreen extends StatefulWidget {
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final bool allowSkip;
  final Future<void> Function()? onAuthSuccess;
  final Future<void> Function()? onSkip;

  const AuthScreen({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
    this.allowSkip = false,
    this.onAuthSuccess,
    this.onSkip,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isCreateAccount = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid || _isLoading) return;

    setState(() => _isLoading = true);

    bool success = false;
    if (_isCreateAccount) {
      success = await SyncManager.createUserWithEmailAndPassword(
        _emailController.text,
        _passwordController.text,
        name: _nameController.text,
        phoneNumber: _phoneController.text,
      );
    } else {
      success = await SyncManager.signInWithEmailAndPassword(
        _emailController.text,
        _passwordController.text,
      );
    }

    if (success) {
  await StorageService.syncAllBoxes();

  if (widget.onAuthSuccess != null) {
    await widget.onAuthSuccess!();
  }
}

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isCreateAccount
                ? 'Account created and data sync started.'
                : 'Login successful. Data sync started.',
          ),
        ),
      );
      if (widget.onAuthSuccess == null && mounted) {
        Navigator.of(context).maybePop(true);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Authentication failed. Check credentials or Firebase setup, then try again.',
          ),
        ),
      );
    }
  }

  Future<void> _skipForNow() async {
    if (widget.onSkip != null) {
      await widget.onSkip!();
      return;
    }
    if (!mounted) return;
    Navigator.of(context).maybePop(false);
  }

  ThemeMode _nextThemeMode() {
    return widget.themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isCreateAccount ? 'Create Account' : 'Login'),
        actions: [
          IconButton(
            tooltip: 'Switch Theme',
            onPressed: () => widget.onThemeModeChanged(_nextThemeMode()),
            icon: Icon(
              widget.themeMode == ThemeMode.dark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
            ),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _isCreateAccount
                            ? 'Create your MyVault account'
                            : 'Login to MyVault',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      if (_isCreateAccount) ...[
                        TextFormField(
                          controller: _nameController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Name',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (value) {
                            if (!_isCreateAccount) return null;
                            if (value == null || value.trim().isEmpty) {
                              return 'Name is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                          validator: (value) {
                            if (!_isCreateAccount) return null;
                            if (value == null || value.trim().isEmpty) {
                              return 'Phone number is required';
                            }
                            if (value.trim().length < 8) {
                              return 'Phone number looks too short';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (value) {
                          final email = value?.trim() ?? '';
                          if (email.isEmpty) return 'Email is required';
                          if (!email.contains('@') || !email.contains('.')) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        textInputAction: _isCreateAccount
                            ? TextInputAction.next
                            : TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password is required';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      if (_isCreateAccount) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          decoration: const InputDecoration(
                            labelText: 'Confirm Password',
                            prefixIcon: Icon(Icons.lock_reset_outlined),
                          ),
                          validator: (value) {
                            if (!_isCreateAccount) return null;
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your password';
                            }
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                      ],
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _isLoading ? null : _submit,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _isCreateAccount ? 'Create Account' : 'Login',
                              ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                setState(() {
                                  _isCreateAccount = !_isCreateAccount;
                                });
                              },
                        child: Text(
                          _isCreateAccount
                              ? 'Already have an account? Login'
                              : 'New user? Create account',
                        ),
                      ),
                      if (widget.allowSkip) ...[
                        const SizedBox(height: 2),
                        TextButton.icon(
                          onPressed: _isLoading ? null : _skipForNow,
                          icon: const Icon(Icons.skip_next_rounded),
                          label: const Text('Use without account (Skip)'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
