import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:streetbite/core/constants/app_constants.dart';
import 'package:streetbite/providers/auth_provider.dart';
import 'package:streetbite/providers/vendor_provider.dart';
import 'package:streetbite/widgets/streetbite_logo.dart';

/// User & Vendor account screen with Sign In, Registration, Demo/Live info, and Theme switcher.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final statusLabel = auth.isDemoMode
        ? 'Demo Mode Active'
        : auth.isLocalSession
            ? 'Quick Session Active'
            : 'Live Firebase Connected';

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: <Widget>[
            StreetBiteLogo(size: 28.0),
            SizedBox(width: AppSpacing.sm),
            Text(
              'Profile & Settings',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720.0),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: <Widget>[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: <Widget>[
                      CircleAvatar(
                        radius: 28.0,
                        backgroundColor: colorScheme.primaryContainer,
                        foregroundColor: colorScheme.onPrimaryContainer,
                        child: const Icon(Icons.person_rounded, size: 30.0),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              auth.displayName,
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (auth.email.isNotEmpty)
                              Text(
                                auth.email,
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            const SizedBox(height: 6.0),
                            Chip(
                              visualDensity: VisualDensity.compact,
                              avatar: Icon(
                                auth.isDemoMode || auth.isLocalSession
                                    ? Icons.offline_bolt_rounded
                                    : Icons.cloud_done_rounded,
                                size: 16.0,
                              ),
                              label: Text(statusLabel),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Appearance',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<ThemeMode>(
                          segments: const <ButtonSegment<ThemeMode>>[
                            ButtonSegment<ThemeMode>(
                              value: ThemeMode.system,
                              icon: Icon(Icons.brightness_auto_rounded),
                              label: Text('System'),
                            ),
                            ButtonSegment<ThemeMode>(
                              value: ThemeMode.light,
                              icon: Icon(Icons.light_mode_rounded),
                              label: Text('Light'),
                            ),
                            ButtonSegment<ThemeMode>(
                              value: ThemeMode.dark,
                              icon: Icon(Icons.dark_mode_rounded),
                              label: Text('Dark'),
                            ),
                          ],
                          selected: <ThemeMode>{auth.themeMode},
                          onSelectionChanged: (modes) {
                            auth.setThemeMode(modes.first);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (!auth.isDemoMode)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: !auth.isAuthenticated
                        ? AuthFormCard(
                            onAuthenticated: () {
                              final vendorId = context
                                  .read<AuthProvider>()
                                  .effectiveVendorId;
                              if (vendorId.isNotEmpty) {
                                context
                                    .read<VendorProvider>()
                                    .loadVendorStalls(vendorId);
                              }
                            },
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Account Controls',
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              OutlinedButton.icon(
                                onPressed: auth.isLoading ? null : auth.signOut,
                                icon: const Icon(Icons.logout_rounded),
                                label: const Text('Sign Out'),
                              ),
                            ],
                          ),
                  ),
                )
              else
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'About Demo Mode',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        const Text(
                          'StreetBite is running in Demo Mode with preloaded street food '
                          'stalls and full in-memory Vendor Portal editing.',
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Reusable Sign In / Register form supporting email-password and Guest Vendor mode.
class AuthFormCard extends StatefulWidget {
  const AuthFormCard({
    super.key,
    this.initialRegisterMode = false,
    this.onAuthenticated,
  });

  final bool initialRegisterMode;
  final VoidCallback? onAuthenticated;

  @override
  State<AuthFormCard> createState() => _AuthFormCardState();
}

class _AuthFormCardState extends State<AuthFormCard> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late bool _isRegisterMode;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _isRegisterMode = widget.initialRegisterMode;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    final bool ok;
    if (_isRegisterMode) {
      ok = await auth.registerWithEmailPassword(
        email: _emailController.text,
        password: _passwordController.text,
        displayName: _nameController.text,
      );
    } else {
      ok = await auth.signInWithEmailPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
    }
    if (!mounted) return;
    if (ok) {
      widget.onAuthenticated?.call();
    }
  }

  Future<void> _continueAsGuest() async {
    final ok = await context.read<AuthProvider>().signInAnonymously();
    if (!mounted) return;
    if (ok) {
      widget.onAuthenticated?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          _isRegisterMode ? 'Create StreetBite Account' : 'Welcome Back',
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: AppSpacing.sm),
        SegmentedButton<bool>(
          segments: const <ButtonSegment<bool>>[
            ButtonSegment<bool>(
              value: false,
              icon: Icon(Icons.login_rounded, size: 18.0),
              label: Text('Sign In'),
            ),
            ButtonSegment<bool>(
              value: true,
              icon: Icon(Icons.person_add_alt_1_rounded, size: 18.0),
              label: Text('Register'),
            ),
          ],
          selected: <bool>{_isRegisterMode},
          onSelectionChanged: (selection) {
            auth.clearError();
            setState(() => _isRegisterMode = selection.first);
          },
        ),
        const SizedBox(height: AppSpacing.md),
        if (auth.errorMessage != null) ...<Widget>[
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Text(
              auth.errorMessage!,
              style: TextStyle(color: colorScheme.onErrorContainer),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (_isRegisterMode) ...<Widget>[
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Full Name / Stall Owner Name',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: 'Password',
            helperText: _isRegisterMode ? 'Minimum 6 characters' : null,
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              tooltip: _obscurePassword ? 'Show password' : 'Hide password',
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
              onPressed: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton.icon(
          onPressed: auth.isLoading ? null : _submit,
          icon: auth.isLoading
              ? const SizedBox(
                  width: 18.0,
                  height: 18.0,
                  child: CircularProgressIndicator(strokeWidth: 2.0),
                )
              : Icon(
                  _isRegisterMode
                      ? Icons.person_add_rounded
                      : Icons.login_rounded,
                ),
          label: Text(_isRegisterMode ? 'Create Account' : 'Sign In'),
        ),
        TextButton(
          onPressed: auth.isLoading
              ? null
              : () {
                  auth.clearError();
                  setState(() => _isRegisterMode = !_isRegisterMode);
                },
          child: Text(
            _isRegisterMode
                ? 'Already have an account? Sign In'
                : 'New to StreetBite? Create Account',
          ),
        ),
        const Divider(height: AppSpacing.md),
        OutlinedButton.icon(
          onPressed: auth.isLoading ? null : _continueAsGuest,
          icon: const Icon(Icons.storefront_outlined),
          label: const Text('Continue as Guest Vendor'),
        ),
      ],
    );
  }
}
