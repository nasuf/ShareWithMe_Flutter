part of '../../main.dart';

class PlatformStyle {
  const PlatformStyle({
    required this.icon,
    required this.color,
    required this.softColor,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final Color softColor;
  final String label;
}

PlatformStyle platformStyle(String platform) {
  return switch (platform) {
    '小红书' => const PlatformStyle(
      icon: Icons.bookmark,
      color: Color(0xFFE64B5D),
      softColor: Color(0xFFFFE9EC),
      label: '小红书',
    ),
    '今日头条' => const PlatformStyle(
      icon: Icons.newspaper,
      color: Color(0xFFE65236),
      softColor: Color(0xFFFFEDE7),
      label: '今日头条',
    ),
    '抖音' || 'TikTok' => const PlatformStyle(
      icon: Icons.music_video,
      color: Color(0xFF111111),
      softColor: Color(0xFFEFEFF1),
      label: '短视频',
    ),
    '快手' => const PlatformStyle(
      icon: Icons.video_collection,
      color: Color(0xFFFF6A00),
      softColor: Color(0xFFFFF0DF),
      label: '快手',
    ),
    '哔哩哔哩' || 'YouTube' => const PlatformStyle(
      icon: Icons.smart_display,
      color: Color(0xFF2188C9),
      softColor: Color(0xFFE3F3FF),
      label: '视频',
    ),
    'GitHub' ||
    'GitLab' ||
    '掘金' ||
    'CSDN' ||
    '少数派' ||
    'IT之家' => const PlatformStyle(
      icon: Icons.code,
      color: Color(0xFF374151),
      softColor: Color(0xFFEDEFF2),
      label: '技术',
    ),
    '淘宝/天猫' || '京东' || '拼多多' || 'Amazon' || '什么值得买' => const PlatformStyle(
      icon: Icons.shopping_bag,
      color: Color(0xFFE58A16),
      softColor: Color(0xFFFFF1D9),
      label: '购物',
    ),
    '高德地图' ||
    'Apple Maps' ||
    'Google Maps' ||
    '大众点评' ||
    '美团' => const PlatformStyle(
      icon: Icons.place,
      color: Color(0xFF287CDA),
      softColor: Color(0xFFE8F2FF),
      label: '地点',
    ),
    'Spotify' ||
    'Apple Music' ||
    '网易云音乐' ||
    'QQ音乐' ||
    '喜马拉雅' ||
    '小宇宙' => const PlatformStyle(
      icon: Icons.headphones,
      color: Color(0xFF7C58D3),
      softColor: Color(0xFFF0EAFE),
      label: '音频',
    ),
    'Notion' ||
    '语雀' ||
    '飞书' ||
    'Google Docs/Drive' ||
    'Dropbox' ||
    'iCloud' ||
    '百度网盘' => const PlatformStyle(
      icon: Icons.description,
      color: Color(0xFF4B5F59),
      softColor: Color(0xFFEAF0ED),
      label: '文档',
    ),
    '知乎' => const PlatformStyle(
      icon: Icons.question_answer,
      color: Color(0xFF1772F6),
      softColor: Color(0xFFE8F3FF),
      label: '知乎',
    ),
    '微博' => const PlatformStyle(
      icon: Icons.rss_feed,
      color: Color(0xFFE6162D),
      softColor: Color(0xFFFFECE8),
      label: '微博',
    ),
    '微信公众号' || '36氪' => const PlatformStyle(
      icon: Icons.article,
      color: Color(0xFF0D7F67),
      softColor: Color(0xFFE3F3EC),
      label: '文章',
    ),
    _ => PlatformStyle(
      icon: Icons.link,
      color: _mint,
      softColor: Color(0xFFE3F3EC),
      label: platform,
    ),
  };
}

class _PlatformIcon extends StatelessWidget {
  const _PlatformIcon({required this.platform});

  final String platform;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: _creamSurface.withValues(alpha: 0.9),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: _warmShadow.withValues(alpha: 0.14),
            blurRadius: 12,
            offset: const Offset(4, 7),
          ),
        ],
      ),
      child: Center(child: PlatformBrandMark(platform: platform, size: 25)),
    );
  }
}

class PlatformBrandMark extends StatelessWidget {
  const PlatformBrandMark({
    super.key,
    required this.platform,
    this.size = 22,
    this.flat = false,
  });

  final String platform;
  final double size;
  final bool flat;

  @override
  Widget build(BuildContext context) {
    final style = platformStyle(platform);
    final radius = BorderRadius.circular(size * 0.32);
    final shadows = flat
        ? <BoxShadow>[]
        : [
            BoxShadow(
              color: style.color.withValues(alpha: 0.28),
              blurRadius: 10,
              offset: const Offset(2, 4),
            ),
          ];
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: _brandGradient(platform, style),
        borderRadius: radius,
        border: Border.all(color: Colors.white.withValues(alpha: 0.38)),
        boxShadow: shadows,
      ),
      child: Center(
        child: _BrandGlyph(platform: platform, size: size),
      ),
    );
  }
}

LinearGradient _brandGradient(String platform, PlatformStyle style) {
  return switch (platform) {
    '小红书' => const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFF5A68), Color(0xFFD71938)],
    ),
    '今日头条' => const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFF6B4A), Color(0xFFD8261C)],
    ),
    '哔哩哔哩' || 'YouTube' => const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF5EC6F2), Color(0xFF1B8CCB)],
    ),
    '抖音' || 'TikTok' => const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF111111), Color(0xFF34363A)],
    ),
    '快手' => const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFF8A2A), Color(0xFFFF5D00)],
    ),
    '知乎' => const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF2F8BFF), Color(0xFF0A5CDB)],
    ),
    '微博' => const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFF9933), Color(0xFFE6162D)],
    ),
    _ => LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [style.color.withValues(alpha: 0.92), style.color],
    ),
  };
}

class _BrandGlyph extends StatelessWidget {
  const _BrandGlyph({required this.platform, required this.size});

  final String platform;
  final double size;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: Colors.white,
      fontSize: size <= 22 ? 7.2 : 8.6,
      fontWeight: FontWeight.w900,
      height: 1,
      letterSpacing: 0,
    );
    if (platform == '小红书') {
      return Text('RED', style: textStyle);
    }
    if (platform == '今日头条') {
      return Text('头条', style: textStyle?.copyWith(fontSize: size * 0.34));
    }
    if (platform == '知乎') {
      return Text(
        '知',
        style: textStyle?.copyWith(
          fontSize: size * 0.58,
          fontWeight: FontWeight.w900,
        ),
      );
    }
    if (platform == '微博') {
      return CustomPaint(
        size: Size.square(size * 0.72),
        painter: _WeiboGlyphPainter(color: Colors.white),
      );
    }
    if (platform == '哔哩哔哩' || platform == 'YouTube') {
      return Icon(Icons.smart_display, color: Colors.white, size: size * 0.66);
    }
    if (platform == '抖音' || platform == 'TikTok') {
      return Stack(
        alignment: Alignment.center,
        children: [
          Transform.translate(
            offset: Offset(-size * 0.05, size * 0.04),
            child: Icon(
              Icons.music_note,
              color: const Color(0xFF25F4EE),
              size: size * 0.62,
            ),
          ),
          Transform.translate(
            offset: Offset(size * 0.05, -size * 0.04),
            child: Icon(
              Icons.music_note,
              color: const Color(0xFFFF2C55),
              size: size * 0.62,
            ),
          ),
          Icon(Icons.music_note, color: Colors.white, size: size * 0.6),
        ],
      );
    }
    return Icon(
      platformStyle(platform).icon,
      color: Colors.white,
      size: size * 0.58,
    );
  }
}

class _WeiboGlyphPainter extends CustomPainter {
  const _WeiboGlyphPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = size.width * 0.12;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final pupil = Paint()
      ..color = const Color(0xFFE6162D)
      ..style = PaintingStyle.fill;

    final eye = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.08,
        size.height * 0.42,
        size.width * 0.68,
        size.height * 0.36,
      ),
      Radius.circular(size.width * 0.22),
    );
    canvas.save();
    canvas.rotate(-math.pi * 0.03);
    canvas.drawRRect(eye, fill);
    canvas.drawCircle(
      Offset(size.width * 0.42, size.height * 0.6),
      size.width * 0.08,
      pupil,
    );
    canvas.restore();

    canvas.drawArc(
      Rect.fromLTWH(
        size.width * 0.52,
        size.height * 0.18,
        size.width * 0.36,
        size.height * 0.28,
      ),
      -math.pi * 0.96,
      math.pi * 0.48,
      false,
      stroke,
    );
    canvas.drawArc(
      Rect.fromLTWH(
        size.width * 0.62,
        size.height * 0.02,
        size.width * 0.42,
        size.height * 0.38,
      ),
      -math.pi * 0.98,
      math.pi * 0.5,
      false,
      stroke..strokeWidth = size.width * 0.1,
    );
    canvas.drawCircle(
      Offset(size.width * 0.18, size.height * 0.34),
      size.width * 0.09,
      fill,
    );
  }

  @override
  bool shouldRepaint(covariant _WeiboGlyphPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
