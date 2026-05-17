import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/app_colors.dart';
import '../../providers/settings_provider.dart';
import '../auth/pin_lock_screen.dart';
import '../accounts/add_account_screen.dart';
import '../accounts/accounts_list_screen.dart';
import '../../main.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'સેટિંગ્સ',
          style: TextStyle(
            fontFamily: 'NotoSansGujarati',
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Consumer<SettingsProvider>(
        builder: (ctx, settP, _) {
          final user = supabase.auth.currentUser;
          final userName = _getUserName(user, settP);
          final userEmail = _getUserEmail(user, settP);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildProfileCard(ctx, settP, userName, userEmail),
              const SizedBox(height: 20),
              const _SectionHeader(title: 'રંગરૂપ'),
              _SettingsTile(
                icon: Icons.dark_mode_rounded,
                title: 'ઘાટો દેખાવ',
                subtitle: 'એપનો દેખાવ બદલો',
                trailing: Switch(
                  value: settP.isDarkMode,
                  activeThumbColor: AppColors.primary,
                  onChanged: (v) => settP.setDarkMode(v),
                ),
              ),
              const SizedBox(height: 16),
              const _SectionHeader(title: 'ખાતાં'),
              _SettingsTile(
                icon: Icons.add_card_rounded,
                title: 'નવું ખાતું ઉમેરો',
                subtitle: 'બેંક, રોકડ અને યુપીઆઈ વોલેટ ઉમેરો',
                onTap: () {
                  Navigator.push(
                    ctx,
                    MaterialPageRoute(
                      builder: (_) => const AddAccountScreen(),
                    ),
                  );
                },
              ),
              _SettingsTile(
                icon: Icons.account_balance_rounded,
                title: 'બધાં ખાતાં જુઓ',
                subtitle: 'જુઓ, સુધારો અને કાઢી નાખો',
                onTap: () {
                  Navigator.push(
                    ctx,
                    MaterialPageRoute(
                      builder: (_) => const AccountsListScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              const _SectionHeader(title: 'સુરક્ષા'),
              _SettingsTile(
                icon: Icons.fingerprint_rounded,
                title: 'બાયોમેટ્રિક તાળું',
                subtitle: 'ફિંગરપ્રિન્ટ અથવા ચહેરાથી સુરક્ષા',
                trailing: Switch(
                  value: settP.biometricLock,
                  activeThumbColor: AppColors.primary,
                  onChanged: (v) => settP.setBiometricLock(v),
                ),
              ),
              _SettingsTile(
                icon: Icons.pin_rounded,
                title: settP.hasPin ? 'પિન બદલો અથવા હટાવો' : 'પિન સેટ કરો',
                subtitle:
                    settP.hasPin ? 'પિન હાલ ચાલુ છે' : 'એપ માટે પિન સેટ કરો',
                iconColor: settP.hasPin ? AppColors.income : AppColors.primary,
                onTap: () => _showPinSheet(ctx, settP),
              ),
              const SizedBox(height: 16),
              const _SectionHeader(title: 'ખાતું'),
              _SettingsTile(
                icon: Icons.logout_rounded,
                title: 'લોગઆઉટ',
                subtitle: 'હાલના ખાતામાંથી બહાર નીકળો',
                iconColor: AppColors.expense,
                onTap: () => _showLogoutDialog(ctx),
              ),
              const SizedBox(height: 16),
              const _SectionHeader(title: 'માહિતી'),
              const _SettingsTile(
                icon: Icons.info_rounded,
                title: 'એપ આવૃત્તિ',
                subtitle: '૧.૦.૦ • હિસાબ કિતાબ',
              ),
              _SettingsTile(
                icon: Icons.star_rounded,
                title: 'એપને ગુણ આપો',
                subtitle: 'પ્લે સ્ટોર પર અભિપ્રાય આપો',
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.share_rounded,
                title: 'એપ શેર કરો',
                subtitle: 'મિત્રો સાથે વહેંચો',
                onTap: () {},
              ),
              const SizedBox(height: 32),
              Center(
                child: Text(
                  'ગુજરાત માટે પ્રેમથી બનાવેલું',
                  style: TextStyle(
                    fontFamily: 'NotoSansGujarati',
                    color: Colors.grey.shade400,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  String _getUserName(User? user, SettingsProvider settP) {
    final name = user?.userMetadata?['name'] ??
        user?.userMetadata?['full_name'] ??
        settP.userName;

    if (name == null || name.toString().trim().isEmpty) {
      return 'તમારું નામ';
    }
    return name.toString().trim();
  }

  String _getUserEmail(User? user, SettingsProvider settP) {
    final email = user?.email ?? settP.userEmail;

    if (email.isEmpty) {
      return 'ઈમેલ ઉમેરો';
    }
    return email.trim();
  }

  Widget _buildProfileCard(
    BuildContext context,
    SettingsProvider settP,
    String userName,
    String userEmail,
  ) {
    return GestureDetector(
      onTap: () => _editProfile(context, settP),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : '👤',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontFamily: 'NotoSansGujarati',
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'NotoSansGujarati',
                    ),
                  ),
                  Text(
                    userEmail,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontFamily: 'NotoSansGujarati',
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.edit_rounded, color: Colors.white70, size: 18),
          ],
        ),
      ),
    );
  }

  void _editProfile(BuildContext context, SettingsProvider settP) {
    final user = supabase.auth.currentUser;

    final currentName = user?.userMetadata?['name'] ??
        user?.userMetadata?['full_name'] ??
        settP.userName;

    final currentEmail = user?.email ?? settP.userEmail;

    final nameCtrl = TextEditingController(
      text: currentName != null ? currentName.toString() : '',
    );

    final emailCtrl = TextEditingController(
      text: currentEmail,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            const Text(
              'માહિતી સુધારો',
              style: TextStyle(
                fontFamily: 'NotoSansGujarati',
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'નામ',
                labelStyle: TextStyle(fontFamily: 'NotoSansGujarati'),
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: emailCtrl,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'ઈમેલ',
                labelStyle: TextStyle(fontFamily: 'NotoSansGujarati'),
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final updatedName = nameCtrl.text.trim();

                await supabase.auth.updateUser(
                  UserAttributes(
                    data: {'name': updatedName},
                  ),
                );

                settP.setUserName(updatedName);
                settP.setUserEmail(emailCtrl.text.trim());

                if (context.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'માહિતી સફળતાપૂર્વક સુધારાઈ ગઈ',
                        style: TextStyle(fontFamily: 'NotoSansGujarati'),
                      ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text(
                'સાચવો',
                style: TextStyle(
                  fontFamily: 'NotoSansGujarati',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showPinSheet(BuildContext context, SettingsProvider settP) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            const Text(
              'પિન સુરક્ષા',
              style: TextStyle(
                fontFamily: 'NotoSansGujarati',
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            _ActionCard(
              icon:
                  settP.hasPin ? Icons.lock_reset_rounded : Icons.lock_rounded,
              title: settP.hasPin ? 'પિન બદલો' : 'પિન સેટ કરો',
              subtitle: settP.hasPin
                  ? 'નવી ૪ અંકની પિન સેટ કરો'
                  : '૪ અંકની પિનથી સુરક્ષા ચાલુ કરો',
              color: AppColors.primary,
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PinLockScreen(
                      mode: settP.hasPin ? PinMode.change : PinMode.setup,
                      correctPin: settP.pin,
                      onSuccess: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'પિન સફળતાપૂર્વક સેટ થઈ ગઈ',
                              style: TextStyle(fontFamily: 'NotoSansGujarati'),
                            ),
                            backgroundColor: AppColors.income,
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
            if (settP.hasPin) ...[
              const SizedBox(height: 10),
              _ActionCard(
                icon: Icons.lock_open_rounded,
                title: 'પિન હટાવો',
                subtitle: 'એપની પિન સુરક્ષા બંધ કરો',
                color: AppColors.expense,
                onTap: () async {
                  Navigator.pop(ctx);
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (dCtx) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      title: const Text(
                        'પિન હટાવવી છે?',
                        style: TextStyle(
                          fontFamily: 'NotoSansGujarati',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      content: const Text(
                        'પિન સુરક્ષા બંધ થઈ જશે.\nએપ સીધી ખૂલશે.',
                        style: TextStyle(
                          fontFamily: 'NotoSansGujarati',
                          height: 1.5,
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dCtx, false),
                          child: const Text(
                            'ના',
                            style: TextStyle(fontFamily: 'NotoSansGujarati'),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(dCtx, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.expense,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'હા, હટાવો',
                            style: TextStyle(fontFamily: 'NotoSansGujarati'),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true && context.mounted) {
                    await context.read<SettingsProvider>().removePin();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'પિન હટાઈ ગઈ',
                            style: TextStyle(fontFamily: 'NotoSansGujarati'),
                          ),
                          backgroundColor: AppColors.income,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'લોગઆઉટ કરવું છે?',
          style: TextStyle(
            fontFamily: 'NotoSansGujarati',
            fontWeight: FontWeight.w700,
          ),
        ),
        content: const Text(
          'તમે હાલના ખાતામાંથી બહાર નીકળી જશો.',
          style: TextStyle(
            fontFamily: 'NotoSansGujarati',
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'ના',
              style: TextStyle(fontFamily: 'NotoSansGujarati'),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expense,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'હા, લોગઆઉટ',
              style: TextStyle(fontFamily: 'NotoSansGujarati'),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await supabase.auth.signOut();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'તમે સફળતાપૂર્વક લોગઆઉટ થયા',
              style: TextStyle(fontFamily: 'NotoSansGujarati'),
            ),
          ),
        );
      }
    }
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color iconColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    this.iconColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'NotoSansGujarati',
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'NotoSansGujarati',
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            trailing ??
                (onTap != null
                    ? Icon(
                        Icons.chevron_right,
                        color: Colors.grey.shade400,
                        size: 18,
                      )
                    : const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 2),
        child: Text(
          title,
          style: const TextStyle(
            fontFamily: 'NotoSansGujarati',
            fontWeight: FontWeight.w800,
            fontSize: 13,
            color: AppColors.primary,
          ),
        ),
      );
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'NotoSansGujarati',
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: color.withValues(alpha: 0.7),
                      fontSize: 11,
                      fontFamily: 'NotoSansGujarati',
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: color.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}
