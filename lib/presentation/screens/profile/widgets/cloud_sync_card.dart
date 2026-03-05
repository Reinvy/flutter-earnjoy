import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:earnjoy/core/theme.dart';
import 'package:earnjoy/core/supabase_config.dart';
import 'package:earnjoy/presentation/providers/auth_provider.dart';
import 'package:earnjoy/presentation/providers/sync_provider.dart';

/// Card shown in ProfileScreen for cloud sync status, sign-in and sync controls.
class CloudSyncCard extends StatefulWidget {
  const CloudSyncCard({super.key});

  @override
  State<CloudSyncCard> createState() => _CloudSyncCardState();
}

class _CloudSyncCardState extends State<CloudSyncCard> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _showForm = false;
  bool _isSignUp = false;
  bool _obscurePass = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _toggleForm({required bool signUp}) {
    setState(() {
      _showForm = !_showForm || _isSignUp != signUp;
      _isSignUp = signUp;
    });
  }

  Future<void> _submit(AuthProvider auth) async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();
    if (email.isEmpty || pass.isEmpty) return;

    bool success;
    if (_isSignUp) {
      success = await auth.signUpWithEmail(email, pass);
    } else {
      success = await auth.signInWithEmail(email, pass);
    }

    if (success && mounted) {
      setState(() => _showForm = false);
      context.read<SyncProvider>().triggerSync();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final sync = context.watch<SyncProvider>();
    final configured = SupabaseConfig.isConfigured;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        children: [
          // ─── Header row ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _statusColor(auth, sync, configured).withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _statusIcon(auth, sync, configured),
                    color: _statusColor(auth, sync, configured),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _statusLabel(auth, sync, configured),
                        style: AppText.caption.copyWith(
                          color: _statusColor(auth, sync, configured),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _statusSubtitle(auth, sync, configured),
                        style: AppText.caption,
                      ),
                    ],
                  ),
                ),
                if (auth.isSignedIn && configured)
                  _SyncNowButton(sync: sync),
              ],
            ),
          ),

          // ─── Auth error banner ────────────────────────────────────────
          if (auth.error != null)
            _ErrorBanner(message: auth.error!),
          if (sync.hasError && auth.isSignedIn)
            _ErrorBanner(message: 'Sync error: ${sync.error}'),

          // ─── Signed-in user info ──────────────────────────────────────
          if (auth.isSignedIn && !auth.isAnonymous)
            _SignedInRow(
              email: auth.email ?? '',
              onSignOut: () async {
                await auth.signOut();
              },
            ),

          // ─── Not configured warning ───────────────────────────────────
          if (!configured)
            const _ConfigWarning(),

          // ─── Sign-in / sign-up form ────────────────────────────────────
          if (configured && !auth.isSignedIn) ...[
            const Divider(height: 1, color: AppColors.glassBorder),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Masuk untuk aktifkan cloud sync',
                    style: AppText.body.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _AuthButton(
                          label: 'Daftar',
                          active: _showForm && _isSignUp,
                          onTap: () => _toggleForm(signUp: true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _AuthButton(
                          label: 'Masuk',
                          active: _showForm && !_isSignUp,
                          onTap: () => _toggleForm(signUp: false),
                        ),
                      ),
                    ],
                  ),
                  if (_showForm) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: _inputDecoration('Email'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passCtrl,
                      obscureText: _obscurePass,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: _inputDecoration('Password').copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePass ? Icons.visibility_off : Icons.visibility,
                            color: AppColors.textSecondary,
                            size: 18,
                          ),
                          onPressed: () => setState(() => _obscurePass = !_obscurePass),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: auth.isLoading ? null : () => _submit(auth),
                        child: auth.isLoading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _isSignUp ? 'Buat Akun' : 'Masuk',
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Status helpers ────────────────────────────────────────────────────────

  Color _statusColor(AuthProvider auth, SyncProvider sync, bool configured) {
    if (!configured) return AppColors.textSecondary;
    if (!auth.isSignedIn) return AppColors.textSecondary;
    if (sync.hasError) return AppColors.error;
    if (sync.isSyncing) return AppColors.primary;
    if (sync.hasSynced) return AppColors.success;
    return AppColors.primary;
  }

  IconData _statusIcon(AuthProvider auth, SyncProvider sync, bool configured) {
    if (!configured) return Icons.settings_outlined;
    if (!auth.isSignedIn) return Icons.cloud_off_outlined;
    if (sync.hasError) return Icons.sync_problem_outlined;
    if (sync.isSyncing) return Icons.sync;
    if (sync.hasSynced) return Icons.cloud_done_outlined;
    return Icons.cloud_outlined;
  }

  String _statusLabel(AuthProvider auth, SyncProvider sync, bool configured) {
    if (!configured) return 'Belum Dikonfigurasi';
    if (!auth.isSignedIn) return 'Cloud Sync Nonaktif';
    if (sync.hasError) return 'Sync Gagal';
    if (sync.isSyncing) return 'Menyinkronkan...';
    if (sync.hasSynced) return 'Tersinkronkan ✓';
    return 'Siap Sync';
  }

  String _statusSubtitle(AuthProvider auth, SyncProvider sync, bool configured) {
    if (!configured) return 'Isi URL & key Supabase di supabase_config.dart';
    if (!auth.isSignedIn) return 'Daftar/masuk untuk menyimpan data di cloud';
    if (sync.hasSynced) {
      final t = sync.lastSyncAt!;
      final diff = DateTime.now().difference(t);
      final ago = diff.inMinutes < 1
          ? 'baru saja'
          : diff.inHours < 1
              ? '${diff.inMinutes} menit lalu'
              : '${diff.inHours} jam lalu';
      return 'Terakhir sync: $ago';
    }
    return 'Tap "Sync" untuk menyimpan data ke cloud';
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      );
}

// ─── Sub-widgets ───────────────────────────────────────────────────────────────

class _SyncNowButton extends StatelessWidget {
  final SyncProvider sync;
  const _SyncNowButton({required this.sync});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: sync.isSyncing
          ? const SizedBox(
              key: ValueKey('loading'),
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            )
          : TextButton(
              key: const ValueKey('button'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () => context.read<SyncProvider>().triggerSync(),
              child: const Text('Sync', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
    );
  }
}

class _SignedInRow extends StatelessWidget {
  final String email;
  final VoidCallback onSignOut;
  const _SignedInRow({required this.email, required this.onSignOut});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(15),
        border: const Border(
          top: BorderSide(color: AppColors.glassBorder),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.account_circle, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              email.isNotEmpty ? email : 'Akun Aktif',
              style: AppText.caption.copyWith(color: AppColors.textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            onPressed: onSignOut,
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0x22FF6B6B),
        border: Border(top: BorderSide(color: Color(0x44FF6B6B))),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 14, color: AppColors.error),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.error, fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfigWarning extends StatelessWidget {
  const _ConfigWarning();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0x22F59E0B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x44F59E0B)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 14, color: Color(0xFFF59E0B)),
              SizedBox(width: 6),
              Text(
                'Setup Diperlukan',
                style: TextStyle(
                  color: Color(0xFFF59E0B),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          Text(
            '1. Buat project di supabase.com (gratis)\n'
            '2. Isi SUPABASE_URL & SUPABASE_ANON_KEY di lib/core/supabase_config.dart\n'
            '3. Jalankan SQL schema dari docs/supabase_schema.sql',
            style: TextStyle(color: Color(0xFFF59E0B), fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _AuthButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _AuthButton({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? AppColors.primary : AppColors.glassBorder),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : AppColors.textSecondary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
