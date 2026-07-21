import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/widgets/widgets.dart';
import 'auth_form_cubit.dart';

/// `/auth` — email + password sign in / sign up, with a magic-link option.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit(AuthFormCubit cubit) {
    if (_formKey.currentState?.validate() ?? false) {
      cubit.submit(email: _email.text, password: _password.text);
    }
  }

  void _magicLink(AuthFormCubit cubit) {
    if (_isValidEmail(_email.text)) {
      cubit.sendMagicLink(_email.text);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid email first.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return GlPageScaffold(
      title: 'Sign in',
      body: BlocConsumer<AuthFormCubit, AuthFormState>(
        listener: (context, state) {
          if (state.status == FormStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage ?? 'Sign-in failed.')),
            );
          } else if (state.status == FormStatus.magicLinkSent) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Magic link sent — check your email.'),
              ),
            );
          }
        },
        builder: (context, state) {
          final AuthFormCubit cubit = context.read<AuthFormCubit>();
          return GlFormLayout(
            formKey: _formKey,
            maxWidth: 420,
            children: [
              Text(
                state.isSignIn ? 'Welcome back' : 'Create your account',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) =>
                    _isValidEmail(value ?? '') ? null : 'Enter a valid email.',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _password,
                obscureText: true,
                autofillHints: const [AutofillHints.password],
                decoration: const InputDecoration(labelText: 'Password'),
                onFieldSubmitted: (_) => _submit(cubit),
                validator: (value) =>
                    (value ?? '').length < 6 ? 'At least 6 characters.' : null,
              ),
              const SizedBox(height: 24),
              GlBusyButton(
                label: state.isSignIn ? 'Sign in' : 'Sign up',
                busy: state.isSubmitting,
                onPressed: () => _submit(cubit),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: state.isSubmitting ? null : () => _magicLink(cubit),
                child: const Text('Email me a magic link'),
              ),
              const Divider(height: 32),
              TextButton(
                onPressed: state.isSubmitting ? null : cubit.toggleMode,
                child: Text(
                  state.isSignIn
                      ? 'No account? Sign up'
                      : 'Have an account? Sign in',
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

bool _isValidEmail(String value) {
  final String trimmed = value.trim();
  return trimmed.contains('@') &&
      trimmed.contains('.') &&
      !trimmed.contains(' ');
}
