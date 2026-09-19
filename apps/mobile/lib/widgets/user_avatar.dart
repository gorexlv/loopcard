import 'package:flutter/material.dart';

import '../auth/auth_service.dart';
import '../theme/loop_theme.dart';

/// The bundled portrait remains visible while a remote avatar loads or fails.
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.user, this.size = 72});

  static const defaultAsset = 'assets/avatars/default-owl.png';
  final AppUser user;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = user.avatarUrl?.trim();
    final uri = url == null ? null : Uri.tryParse(url);
    final hasRemoteImage =
        uri != null &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host.isNotEmpty;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: context.loopColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            defaultAsset,
            fit: BoxFit.cover,
            excludeFromSemantics: true,
          ),
          if (hasRemoteImage)
            Image.network(
              url!,
              key: ValueKey(url),
              fit: BoxFit.cover,
              excludeFromSemantics: true,
              errorBuilder: (_, error, stackTrace) => const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }
}
