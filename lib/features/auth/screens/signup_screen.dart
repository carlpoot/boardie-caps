import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_router.dart';
import '../providers/auth_notifier.dart';
import '../providers/auth_state.dart';

/// Role choices offered at sign-up. Administrator accounts are
/// seeded/assigned manually and are never self-registered, so they're not
/// offered here.
enum _SignupRole { student, landlord }

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _contactNoController = TextEditingController();
  final _passwordController = TextEditingController();
  _SignupRole _role = _SignupRole.student;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _contactNoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final notifier = ref.read(authNotifierProvider.notifier);
    switch (_role) {
      case _SignupRole.student:
        await notifier.signUpStudent(
          name: _nameController.text,
          email: _emailController.text,
          contactNo: _contactNoController.text,
          password: _passwordController.text,
        );
      case _SignupRole.landlord:
        await notifier.signUpLandlord(
          name: _nameController.text,
          email: _emailController.text,
          contactNo: _contactNoController.text,
          password: _passwordController.text,
        );
    }
    final state = ref.read(authNotifierProvider);
    if (state.status == AuthStatus.authenticated && mounted) {
      context.go(homeForRole(state.role));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next.errorMessage != null && next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(next.errorMessage!)));
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'I am a...',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<_SignupRole>(
                      key: const Key('signup_role_picker'),
                      segments: const [
                        ButtonSegment(
                          value: _SignupRole.student,
                          label: Text('Student'),
                          icon: Icon(Icons.school_outlined),
                        ),
                        ButtonSegment(
                          value: _SignupRole.landlord,
                          label: Text('Landlord'),
                          icon: Icon(Icons.home_work_outlined),
                        ),
                      ],
                      selected: {_role},
                      onSelectionChanged: (selection) =>
                          setState(() => _role = selection.first),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      key: const Key('signup_name_field'),
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Full name'),
                      validator: (value) => (value == null || value.trim().isEmpty)
                          ? 'Name is required'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('signup_email_field'),
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Email is required';
                        }
                        if (!value.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('signup_contact_no_field'),
                      controller: _contactNoController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Contact number'),
                      validator: (value) => (value == null || value.trim().isEmpty)
                          ? 'Contact number is required'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('signup_password_field'),
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        helperText: 'At least 6 characters',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password is required';
                        }
                        if (value.length < 6) return 'At least 6 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      key: const Key('signup_submit_button'),
                      onPressed: authState.isLoading ? null : _submit,
                      child: authState.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Create Account'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: authState.isLoading ? null : () => context.go('/login'),
                      child: const Text('Already have an account? Log in'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
