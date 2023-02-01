import 'package:faceunity_ui/Models/BaseModel.dart';
import 'package:faceunity_ui/Models/FaceUnityModel.dart';
import 'package:faceunity_ui/Tools/FUImageTool.dart';
import 'package:faceunity_ui/ViewModels/BaseViewModel.dart';
import 'package:faceunity_plugin/FUMakeupPlugin.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FUMakeupViewModel extends BaseViewModel {
  FUMakeupViewModel(FaceUnityModel dataModel) : super(dataModel) {
    List<String> imageName = ["noitem", "chaoA", "dousha", "naicha"];
    Map<String, dynamic> imageNameAndTitle = {
      "noitem": "卸妆",
      "chaoA": "超A",
      "dousha": "豆沙",
      "naicha": "奶茶",
    };

    String commonPre =
        FUImageTool.getImagePathWithRelativePathPre("Asserts/makeup/3.0x/");
    List<String> imagePaths = List.generate(imageName.length, (index) {
      String title = imageName[index];
      if (index == 0) {
        title = "Asserts/common/3.0x/" + title;
      } else {
        title = commonPre + title;
      }
      return title;
    });

    List<BaseModel> uiList = [];
    for (var i = 0; i < imageName.length; i++) {
      String key = imageName[i];
      BaseModel model = BaseModel(imagePaths[i], imageNameAndTitle[key], 0.7);
      model.ratio = 1.0;
      uiList.add(model);
    }
    this.dataModel.dataList = uiList;
    this.selectedIndex = 0;
    this.selectedModel = this.dataModel.dataList[this.selectedIndex];

    FUMakeupPlugin.config();

    _initSelectedItem();
  }

  _initSelectedItem() {
    super.selectedItem(selectedIndex);
    //native plugin
    FUMakeupPlugin.selectedItem(selectedIndex);
  }

  @override
  showBoard() {
    return true;
  }

  //是否展示Sider
  @override
  showSlider() {
    if (selectedIndex == 0) {
      return false;
    }
    return true;
  }

  @override
  void selectedItem(int index) async {
    super.selectedItem(index);
    //native plugin
    FUMakeupPlugin.selectedItem(index);

    // 缓存选择索引
    SharedPreferences sp = await SharedPreferences.getInstance();
    sp.setString('fuMakeupIndex', index.toString());
  }

  @override
  void sliderValueChange(double value) {
    super.sliderValueChange(value);
    FUMakeupPlugin.sliderValueChange(selectedIndex, value);
  }

  @override
  Future sliderValueChangeAtIndex(int index, double value) async {
    if (index >= dataModel.dataList.length) return;
    BaseModel model = dataModel.dataList[index];
    FUMakeupPlugin.sliderValueChange(index, model.value);
  }

  @override
  readCachedValues() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    String? indexStr = sp.getString('fuMakeupIndex');
    if (indexStr == null) return;
    int index = int.parse(indexStr);
    await FUMakeupPlugin.selectedItem(index);
    BaseModel model = dataModel.dataList[index];
    await model.readCachedValue();
    await sliderValueChangeAtIndex(index, model.value);
    this.selectedIndex = index;
    this.selectedModel = this.dataModel.dataList[this.selectedIndex];
  }

  @override
  init() {}

  @override
  dealloc() {
    //先设置卸妆
    if (selectedIndex != 0) {
      //美妆业务dispose 不保留，所以要卸妆
      FUMakeupPlugin.selectedItem(0);
      selectedIndex = 0;
    }
    FUMakeupPlugin.dispose();
    super.dealloc();
  }
}
