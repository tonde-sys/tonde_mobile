import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tonde/features/auth/presentation/controllers/auth_controller.dart';
import 'package:tonde/features/profile/presentation/widgets/profile_avatar.dart';
import 'package:tonde/l10n/generated/app_localizations.dart';

/// Page d'édition des informations du profil connecté.
class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _roleController = TextEditingController();
  final _organizationController = TextEditingController();

  bool _isSaving = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    final user = ref.read(authControllerProvider).value;
    if (user != null) {
      _nameController.text = user.name;
      _emailController.text = user.email ?? '';
      _phoneController.text = user.phone ?? '';
      _roleController.text = user.role ?? '';
      _organizationController.text = user.organization ?? '';
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _roleController.dispose();
    _organizationController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isSaving = true);

    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);

    await ref
        .read(authControllerProvider.notifier)
        .updateProfile(
          name: _nameController.text,
          email: _emailController.text,
          phone: _phoneController.text,
          role: _roleController.text,
          organization: _organizationController.text,
        );

    if (!mounted) {
      return;
    }
    setState(() => _isSaving = false);

    final hasError = ref.read(authControllerProvider).hasError;
    if (hasError) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.profileUpdateFailed),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    // Le routeur ne rafraîchit plus la pile sur une mise à jour de profil,
    // donc le pop n'est plus annulé. On affiche le snackbar avant de quitter.
    messenger.showSnackBar(SnackBar(content: Text(l10n.profileUpdated)));
    if (context.canPop()) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.editProfileTitle),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.save),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ---- Photo de profil ----
              Center(child: ProfileAvatar(radius: 44, editable: true)),
              const SizedBox(height: 8),
              Text(
                l10n.profilePhotoHint,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),

              // ---- Nom complet ----
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: l10n.nameLabel,
                  prefixIcon: const Icon(Icons.person_outline),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? l10n.fieldRequired
                    : null,
              ),
              const SizedBox(height: 16),

              // ---- Adresse e-mail ----
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                inputFormatters: [
                  FilteringTextInputFormatter.deny(RegExp(r'\s')),
                ],
                decoration: InputDecoration(
                  labelText: l10n.profileEmail,
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: const OutlineInputBorder(),
                ),
                validator: _validateEmail,
              ),
              const SizedBox(height: 16),

              // ---- Téléphone ----
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: l10n.profilePhone,
                  prefixIcon: const Icon(Icons.phone_outlined),
                  border: const OutlineInputBorder(),
                ),
                validator: _validatePhone,
              ),
              const SizedBox(height: 16),

              // ---- Rôle ----
              TextFormField(
                controller: _roleController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: l10n.profileRole,
                  prefixIcon: const Icon(Icons.badge_outlined),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // ---- Organisation ----
              TextFormField(
                controller: _organizationController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: l10n.profileOrganization,
                  prefixIcon: const Icon(Icons.business_outlined),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 28),

              // ---- Boutons ----
              FilledButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: const Icon(Icons.save_outlined),
                label: Text(l10n.save),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                child: Text(l10n.cancel),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Valide un format d'e-mail simple.
  String? _validateEmail(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return null; // Champ optionnel : vide est accepté.
    }
    final pattern = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
    if (!pattern.hasMatch(text)) {
      return AppLocalizations.of(context).invalidEmail;
    }
    return null;
  }

  /// Valide un numéro de téléphone (chiffres, espaces, +, -, parenthèses).
  String? _validatePhone(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return null; // Champ optionnel : vide est accepté.
    }
    if (!RegExp(r'^\+?[\d\s().-]{6,}$').hasMatch(text)) {
      return AppLocalizations.of(context).invalidPhone;
    }
    return null;
  }
}
