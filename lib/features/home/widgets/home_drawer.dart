import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/features/profile/models/profile.dart';
import 'package:glow/features/profile/widgets/profile_avatar.dart';
import 'package:glow/features/profile/widgets/profile_editor_dialog.dart';
import 'package:glow/features/wallet/models/wallet_metadata.dart';
import 'package:glow/features/wallet_onboarding/widgets/breez_sdk_footer.dart';
import 'package:glow/features/wallet/providers/wallet_provider.dart';
import 'package:glow/routing/app_routes.dart';
import 'package:glow/theme/colors.dart';

class HomeDrawer extends StatelessWidget {
  const HomeDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: Theme.of(context).appBarTheme.systemOverlayStyle!.copyWith(
        systemNavigationBarColor: themeData.colorScheme.surfaceContainer,
      ),
      child: Drawer(
        child: Column(
          children: <Widget>[
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: <Widget>[
                  _DrawerHeader(),
                  const SizedBox(height: 16),
                  _DrawerItem(
                    title: 'Balance',
                    icon: Icons.account_balance_wallet_outlined,
                    isSelected: true,
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  const Divider(indent: 16, endIndent: 16),
                  _DrawerSection(
                    title: 'Preferences',
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0),
                        child: _DrawerImageItem(
                          title: 'Fiat Currency',
                          imagePath: 'assets/icon/fiat_currencies.png',
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, AppRoutes.fiatCurrencies);
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0),
                        child: _DrawerItem(
                          title: 'Security & Backup',
                          icon: Icons.lock_outline,
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, AppRoutes.appSettings);
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0),
                        child: _DrawerItem(
                          title: 'Developers',
                          icon: Icons.code,
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, AppRoutes.developersScreen);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const _DrawerFooter(),
          ],
        ),
      ),
    );
  }
}

class _DrawerHeader extends ConsumerWidget {
  static const double _kBreezDrawerHeaderHeight = 160.0 + 1.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    final AsyncValue<WalletMetadata?> activeWallet = ref.watch(activeWalletProvider);

    return Container(
      height: statusBarHeight + _kBreezDrawerHeaderHeight,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      color: BreezColors.darkBackground,
      child: GestureDetector(
        onTap: () {
          showDialog<void>(
            context: context,
            builder: (BuildContext context) => const ProfileEditorDialog(),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 42),
            ProfileAvatar(
              profile: activeWallet.value?.profile ?? Profile.anonymous(),
              avatarSize: AvatarSize.medium,
              backgroundColor: theme.primaryColor,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                activeWallet.when(
                  data: (WalletMetadata? wallet) => wallet != null
                      ? Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            wallet.displayName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: BreezColors.grey600,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback? onTap;

  const _DrawerItem({required this.title, required this.icon, this.isSelected = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Ink(
        decoration: BoxDecoration(
          color: isSelected ? theme.primaryColorLight : Colors.transparent,
          borderRadius: const BorderRadius.horizontal(right: Radius.circular(32)),
        ),
        child: ListTile(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.horizontal(right: Radius.circular(32)),
          ),
          leading: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(icon, size: 26),
          ),
          title: Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text(title)),
          onTap: onTap,
        ),
      ),
    );
  }
}

class _DrawerImageItem extends StatelessWidget {
  final String title;
  final String imagePath;
  final VoidCallback? onTap;

  const _DrawerImageItem({
    required this.title,
    required this.imagePath,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: ListTile(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(32)),
        ),
        leading: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Image.asset(
            imagePath,
            width: 26,
            height: 26,
            color: IconTheme.of(context).color,
          ),
        ),
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(title),
        ),
        onTap: onTap,
      ),
    );
  }
}

class _DrawerSection extends StatefulWidget {
  final String title;
  final List<Widget> children;

  const _DrawerSection({required this.title, required this.children});

  @override
  State<_DrawerSection> createState() => _DrawerSectionState();
}

class _DrawerSectionState extends State<_DrawerSection> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = true;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Text(
            widget.title,
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
          ),
        ),
        title: const SizedBox.shrink(),
        initiallyExpanded: _isExpanded,
        onExpansionChanged: (bool expanded) {
          setState(() {
            _isExpanded = expanded;
          });
        },
        children: widget.children,
      ),
    );
  }
}

class _DrawerFooter extends StatelessWidget {
  const _DrawerFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60 + MediaQuery.of(context).padding.bottom,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      child: const BreezSdkFooter(),
    );
  }
}
