import 'package:get/get.dart';
import 'en_us.dart';
import 'bn_bd.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'en_US': enUS,
    'bn_BD': bnBD,
  };
}
