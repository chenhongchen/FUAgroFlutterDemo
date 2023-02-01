import 'package:faceunity_ui/Mix/CharacterProperty.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BaseModel extends Object with CharacterProperty {
  late String title;
  late final String imagePath;
  late double value;

  BaseModel(this.imagePath, this.title, this.value) {
    ratio = 1.0;
    showSlider = false;
    midSlider = false;
    strValue = "";
    defaultValue = this.value;
  }

  @override
  String toString() {
    return 'title:$title, imagePath: $imagePath, value: $value, ratio: $ratio, showSlider: $showSlider, midSlider: $midSlider, strValue: $strValue, defaultValue: $defaultValue';
  }

  cacheValue() async {
    if (title.isEmpty) return;
    SharedPreferences sp = await SharedPreferences.getInstance();
    return await sp.setString(title, value.toString());
  }

  readCachedValue() async {
    if (title.isEmpty) return;
    SharedPreferences sp = await SharedPreferences.getInstance();
    String? valueStr = sp.getString(title);
    if (valueStr == null) return;
    value = double.parse(valueStr);
  }
}
