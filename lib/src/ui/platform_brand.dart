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
      icon: Icons.bookmark_outline,
      color: Color(0xFFFF2442),
      softColor: Color(0xFFFFEFF2),
      label: '小红书',
    ),
    '今日头条' => const PlatformStyle(
      icon: Icons.newspaper_outlined,
      color: Color(0xFFF04142),
      softColor: Color(0xFFFFEEEE),
      label: '头条',
    ),
    '抖音' || 'TikTok' => const PlatformStyle(
      icon: Icons.play_circle_outline,
      color: Color(0xFF161823),
      softColor: Color(0xFFF2F2F4),
      label: '抖音',
    ),
    '快手' => const PlatformStyle(
      icon: Icons.video_collection_outlined,
      color: Color(0xFFFF6600),
      softColor: Color(0xFFFFF1E8),
      label: '快手',
    ),
    '哔哩哔哩' => const PlatformStyle(
      icon: Icons.smart_display_outlined,
      color: Color(0xFF00A1D6),
      softColor: Color(0xFFEAF8FD),
      label: 'B站',
    ),
    'YouTube' => const PlatformStyle(
      icon: Icons.smart_display_outlined,
      color: Color(0xFFFF0033),
      softColor: Color(0xFFFFECEF),
      label: 'YouTube',
    ),
    '知乎' => const PlatformStyle(
      icon: Icons.question_answer_outlined,
      color: Color(0xFF1772F6),
      softColor: Color(0xFFEAF3FF),
      label: '知乎',
    ),
    '微博' => const PlatformStyle(
      icon: Icons.alternate_email,
      color: Color(0xFFE6162D),
      softColor: Color(0xFFFFF0E9),
      label: '微博',
    ),
    'X' || 'Twitter' => const PlatformStyle(
      icon: Icons.alternate_email,
      color: Color(0xFF111111),
      softColor: Color(0xFFF0F0F0),
      label: 'X',
    ),
    'Instagram' => const PlatformStyle(
      icon: Icons.camera_alt_outlined,
      color: Color(0xFFC13584),
      softColor: Color(0xFFF9EDF5),
      label: 'Instagram',
    ),
    '豆瓣' => const PlatformStyle(
      icon: Icons.local_movies_outlined,
      color: Color(0xFF2E963D),
      softColor: Color(0xFFEDF7EF),
      label: '豆瓣',
    ),
    '高德地图' => const PlatformStyle(
      icon: Icons.place_outlined,
      color: Color(0xFF3478F6),
      softColor: Color(0xFFEDF3FF),
      label: '高德',
    ),
    '百度地图' => const PlatformStyle(
      icon: Icons.map_outlined,
      color: Color(0xFF376DFF),
      softColor: Color(0xFFEDF2FF),
      label: '百度地图',
    ),
    '京东' => const PlatformStyle(
      icon: Icons.shopping_bag_outlined,
      color: Color(0xFFE1251B),
      softColor: Color(0xFFFFEEEC),
      label: '京东',
    ),
    '淘宝' => const PlatformStyle(
      icon: Icons.shopping_bag_outlined,
      color: Color(0xFFFF5000),
      softColor: Color(0xFFFFF0E8),
      label: '淘宝',
    ),
    '天猫' || '淘宝/天猫' => const PlatformStyle(
      icon: Icons.shopping_bag_outlined,
      color: Color(0xFFFF0036),
      softColor: Color(0xFFFFEDF1),
      label: '天猫',
    ),
    '微信读书' => const PlatformStyle(
      icon: Icons.menu_book_outlined,
      color: Color(0xFF1AAD19),
      softColor: Color(0xFFEDF8ED),
      label: '微信读书',
    ),
    '微信公众号' || '腾讯内容' => const PlatformStyle(
      icon: Icons.article_outlined,
      color: Color(0xFF07C160),
      softColor: Color(0xFFECF9F1),
      label: '微信',
    ),
    'GitHub' ||
    'GitLab' ||
    '掘金' ||
    'CSDN' ||
    '少数派' ||
    'IT之家' => const PlatformStyle(
      icon: Icons.code,
      color: Color(0xFF384152),
      softColor: Color(0xFFF0F2F5),
      label: '技术',
    ),
    'Apple Maps' || 'Google Maps' || '大众点评' || '美团' => const PlatformStyle(
      icon: Icons.place_outlined,
      color: Color(0xFF287CDA),
      softColor: Color(0xFFEDF4FC),
      label: '地点',
    ),
    '拼多多' || 'Amazon' || '什么值得买' => const PlatformStyle(
      icon: Icons.shopping_bag_outlined,
      color: Color(0xFFE58A16),
      softColor: Color(0xFFFFF5E5),
      label: '购物',
    ),
    _ => PlatformStyle(
      icon: Icons.link,
      color: _accent,
      softColor: const Color(0xFFEEF3F5),
      label: platform,
    ),
  };
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
    final asset = _platformAsset(platform);
    final brandIcon = _platformBrandIcon(platform);
    final radius = BorderRadius.circular(size * 0.28);
    final decoration = BoxDecoration(
      color: brandIcon == null ? style.softColor : style.color,
      borderRadius: radius,
      border: Border.all(color: Colors.white.withValues(alpha: 0.88)),
      boxShadow: flat
          ? null
          : [
              BoxShadow(
                color: style.color.withValues(alpha: 0.16),
                blurRadius: 12,
                spreadRadius: -4,
                offset: const Offset(0, 5),
              ),
            ],
    );
    if (asset != null) {
      return Container(
        width: size,
        height: size,
        decoration: decoration,
        clipBehavior: Clip.antiAlias,
        child: Image.asset(asset, fit: BoxFit.cover),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: decoration,
      child: Icon(
        brandIcon ?? style.icon,
        color: brandIcon == null ? style.color : Colors.white,
        size: size * 0.62,
      ),
    );
  }
}

String? _platformAsset(String platform) {
  return switch (platform) {
    '今日头条' => 'assets/platform_icons/toutiao.jpg',
    '京东' => 'assets/platform_icons/jd.jpg',
    '天猫' || '淘宝/天猫' => 'assets/platform_icons/tmall.jpg',
    '高德地图' => 'assets/platform_icons/amap.jpg',
    '百度地图' => 'assets/platform_icons/baidu-map.jpg',
    _ => null,
  };
}

IconData? _platformBrandIcon(String platform) {
  return switch (platform) {
    '小红书' => SimpleIcons.xiaohongshu,
    'YouTube' => SimpleIcons.youtube,
    '哔哩哔哩' => SimpleIcons.bilibili,
    '知乎' => SimpleIcons.zhihu,
    '微博' => SimpleIcons.sinaweibo,
    '抖音' || 'TikTok' => SimpleIcons.tiktok,
    '快手' => SimpleIcons.kuaishou,
    'X' || 'Twitter' => SimpleIcons.x,
    'Instagram' => SimpleIcons.instagram,
    '豆瓣' => SimpleIcons.douban,
    '淘宝' => SimpleIcons.taobao,
    '微信读书' => SimpleIcons.weread,
    '微信公众号' || '腾讯内容' => SimpleIcons.wechat,
    '百度' => SimpleIcons.baidu,
    _ => null,
  };
}
