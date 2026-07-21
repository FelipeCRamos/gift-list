import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/widgets/widgets.dart';
import '../../../data/models/models.dart';
import '../../auth/presentation/auth_cubit.dart';
import 'profile_cubit.dart';

/// `/dashboard/profile` — edit display name, default Pix key + type, and the
/// merchant city used on the Pix BR Code.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _displayName = TextEditingController();
  final TextEditingController _pixKey = TextEditingController();
  final TextEditingController _merchantCity = TextEditingController();
  PixKeyType? _pixKeyType;
  bool _populated = false;

  @override
  void dispose() {
    _displayName.dispose();
    _pixKey.dispose();
    _merchantCity.dispose();
    super.dispose();
  }

  void _populate(Profile profile) {
    _displayName.text = profile.displayName;
    _pixKey.text = profile.defaultPixKey ?? '';
    _merchantCity.text = profile.merchantCity ?? '';
    _pixKeyType = profile.pixKeyType;
    _populated = true;
  }

  void _save(BuildContext context) {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final Profile? current = context.read<ProfileCubit>().state.profile;
    if (current == null) {
      return;
    }
    final Profile draft = current.copyWith(
      displayName: _displayName.text.trim(),
      defaultPixKey: _pixKey.text.trim().isEmpty ? null : _pixKey.text.trim(),
      pixKeyType: _pixKeyType,
      merchantCity: _merchantCity.text.trim().isEmpty
          ? null
          : _merchantCity.text.trim(),
    );
    context.read<ProfileCubit>().save(draft);
  }

  @override
  Widget build(BuildContext context) {
    return GlPageScaffold(
      title: 'Profile',
      actions: [
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Sign out',
          onPressed: () => context.read<AuthCubit>().signOut(),
        ),
      ],
      body: BlocConsumer<ProfileCubit, ProfileState>(
        listener: (context, state) {
          if (state.status == ProfileStatus.ready && !_populated) {
            _populate(state.profile!);
          }
          if (state.status == ProfileStatus.saved) {
            _populate(state.profile!);
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Profile saved.')));
          }
          if (state.status == ProfileStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage ?? 'Save failed.')),
            );
          }
        },
        builder: (context, state) {
          return GlAsyncView(
            loading:
                state.status == ProfileStatus.loading ||
                state.status == ProfileStatus.initial,
            builder: (context) => GlFormLayout(
              formKey: _formKey,
              children: [
                TextFormField(
                  controller: _displayName,
                  decoration: const InputDecoration(labelText: 'Display name'),
                  validator: (value) =>
                      (value ?? '').trim().isEmpty ? 'Required.' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _pixKey,
                  decoration: const InputDecoration(
                    labelText: 'Default Pix key',
                    helperText: 'Prefilled when creating a list.',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<PixKeyType>(
                  initialValue: _pixKeyType,
                  decoration: const InputDecoration(labelText: 'Pix key type'),
                  items: [
                    for (final type in PixKeyType.values)
                      DropdownMenuItem(
                        value: type,
                        child: Text(type.name.toUpperCase()),
                      ),
                  ],
                  onChanged: (value) => setState(() => _pixKeyType = value),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _merchantCity,
                  maxLength: 15,
                  decoration: const InputDecoration(
                    labelText: 'Merchant city',
                    helperText: 'ASCII, shown on the Pix code.',
                  ),
                ),
                const SizedBox(height: 24),
                GlBusyButton(
                  label: 'Save',
                  busy: state.status == ProfileStatus.saving,
                  onPressed: () => _save(context),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
