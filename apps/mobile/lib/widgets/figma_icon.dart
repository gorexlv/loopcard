import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

class FigmaIcon extends StatelessWidget {
  const FigmaIcon(this.name, {super.key, required this.size, this.color});

  final String name;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: SvgPicture.asset(
        'assets/icons/$name.svg',
        fit: BoxFit.contain,
        colorFilter: color == null
            ? null
            : ColorFilter.mode(color!, BlendMode.srcIn),
      ),
    );
  }
}
