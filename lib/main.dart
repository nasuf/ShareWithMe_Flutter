import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_icons/simple_icons.dart';
import 'package:url_launcher/url_launcher.dart';

part 'src/app/share_with_me_app.dart';
part 'src/core/backend_config.dart';
part 'src/data/app_settings.dart';
part 'src/state/share_scope.dart';
part 'src/state/share_controller.dart';
part 'src/data/api_client.dart';
part 'src/models/models.dart';
part 'src/ui/home_shell.dart';
part 'src/ui/inbox_page.dart';
part 'src/ui/inbox_filters.dart';
part 'src/ui/inbox_cards.dart';
part 'src/ui/inbox_card_media.dart';
part 'src/ui/detail_page.dart';
part 'src/ui/detail_components.dart';
part 'src/ui/content_widgets.dart';
part 'src/ui/edit_item_sheet.dart';
part 'src/ui/insights_page.dart';
part 'src/ui/settings_page.dart';
part 'src/ui/settings_sheets.dart';
part 'src/ui/add_link_sheet.dart';
part 'src/ui/platform_brand.dart';
part 'src/ui/shared_widgets.dart';

void main() {
  runApp(const ShareWithMeApp());
}
