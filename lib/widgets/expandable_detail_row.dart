import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/services/share_service.dart';
import 'package:url_launcher/url_launcher.dart';

/// Expandable row for displaying details with copy and share actions
///
/// Shows a title that expands to reveal the full value with action buttons
class ExpandableDetailRow extends ConsumerWidget {
  final String title;
  final String value;
  final String? linkUrl;
  final bool isExpanded;
  final AutoSizeGroup? labelAutoSizeGroup;
  final String? copyTooltip;
  final String? linkTooltip;

  const ExpandableDetailRow({
    required this.title,
    required this.value,
    super.key,
    this.linkUrl,
    this.isExpanded = false,
    this.labelAutoSizeGroup,
    this.copyTooltip,
    this.linkTooltip,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Theme(
      data: theme.copyWith(dividerColor: colorScheme.surfaceContainer),
      child: ExpansionTile(
        dense: true,
        iconColor: isExpanded ? Colors.transparent : Colors.white,
        collapsedIconColor: Colors.white,
        initiallyExpanded: isExpanded,
        tilePadding: EdgeInsets.zero,
        title: AutoSizeText(
          title,
          style: theme.textTheme.titleMedium?.copyWith(fontSize: 18.0, fontWeight: FontWeight.w500),
          maxLines: 1,
          group: labelAutoSizeGroup,
        ),
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: GestureDetector(
                      onTap: linkUrl != null ? () => _launchUrl(linkUrl!) : null,
                      child: Tooltip(
                        message: linkUrl != null ? linkTooltip ?? 'Open link' : null,
                        child: Text(
                          value,
                          textAlign: TextAlign.left,
                          overflow: TextOverflow.clip,
                          maxLines: 4,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 12.0,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                            height: 1.156,
                            letterSpacing: 0.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                  tooltip: copyTooltip ?? 'Copy $title',
                  iconSize: 20.0,
                  icon: const Icon(Icons.copy),
                  onPressed: () => _handleCopy(context),
                ),
                IconButton(
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                  tooltip: 'Share $title',
                  iconSize: 20.0,
                  icon: const Icon(Icons.share),
                  onPressed: () => _handleShare(ref),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCopy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$title copied'), duration: const Duration(seconds: 2)),
      );
    }
  }

  void _handleShare(WidgetRef ref) {
    ref.read(shareServiceProvider).share(title: title, text: value);
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
