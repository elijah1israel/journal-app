import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/api_client.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';
import 'auth_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String _experience = 'beginner';
  bool _obscure = true;
  bool _loading = false;

  static const _levels = ['beginner', 'intermediate', 'advanced', 'professional'];

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      await context.read<AppState>().register(
            email: _email.text.trim(),
            firstName: _firstName.text.trim(),
            lastName: _lastName.text.trim(),
            password: _password.text,
            confirmPassword: _confirm.text,
            experienceLevel: _experience,
          );
      if (mounted) Navigator.of(context).maybePop();
    } on ApiException catch (e) {
      if (mounted) showAppSnack(context, e.message, error: true);
    } catch (_) {
      if (mounted) {
        showAppSnack(context, 'Something went wrong. Please try again.',
            error: true);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      showBack: true,
      child: Form(
        key: _formKey,
        child: AuthCard(
          title: 'Create account',
          subtitle: 'A few details to get you logging trades.',
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const AuthFieldLabel('First name'),
                      TextFormField(
                        controller: _firstName,
                        textInputAction: TextInputAction.next,
                        decoration: authInput(Icons.person_outline),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const AuthFieldLabel('Last name'),
                      TextFormField(
                        controller: _lastName,
                        textInputAction: TextInputAction.next,
                        decoration: authInput(Icons.badge_outlined),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const AuthFieldLabel('Email'),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              decoration: authInput(Icons.alternate_email),
              validator: validateEmail,
            ),
            const SizedBox(height: 14),
            const AuthFieldLabel('Experience'),
            DropdownButtonFormField<String>(
              value: _experience,
              decoration: authInput(Icons.school_outlined),
              items: [
                for (final l in _levels)
                  DropdownMenuItem(
                      value: l,
                      child: Text(l[0].toUpperCase() + l.substring(1))),
              ],
              onChanged: (v) => setState(() => _experience = v ?? 'beginner'),
            ),
            const SizedBox(height: 14),
            const AuthFieldLabel('Password'),
            TextFormField(
              controller: _password,
              obscureText: _obscure,
              textInputAction: TextInputAction.next,
              decoration: authInput(
                Icons.lock_outline,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 19,
                    color: AppColors.gray400,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (v.length < 8) return 'At least 8 characters';
                return null;
              },
            ),
            const SizedBox(height: 14),
            const AuthFieldLabel('Confirm password'),
            TextFormField(
              controller: _confirm,
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              decoration: authInput(Icons.lock_outline),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (v != _password.text) return 'Passwords do not match';
                return null;
              },
            ),
            const SizedBox(height: 20),
            PrimaryButton(
                label: 'Create account',
                loading: _loading,
                onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
