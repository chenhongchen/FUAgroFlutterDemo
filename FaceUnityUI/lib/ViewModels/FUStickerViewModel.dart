import 'package:faceunity_ui/Models/BaseModel.dart';
import 'package:faceunity_ui/Models/FaceUnityModel.dart';
import 'package:faceunity_ui/Tools/FUImageTool.dart';
import 'package:faceunity_ui/ViewModels/BaseViewModel.dart';
import 'package:faceunity_plugin/FUStickerPlugin.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FUStickerViewModel extends BaseViewModel {
  FUStickerViewModel(FaceUnityModel dataModel) : super(dataModel) {
    List<BaseModel> uiList = [];
    List<String> titles = ["noitem", "sdlu", "fashi"];
    String commonPre =
        FUImageTool.getImagePathWithRelativePathPre("Asserts/sticker/3.0x/");
    List<String> imagePaths = List.generate(titles.length, (index) {
      String title = "";
      if (index == 0) {
        title = "Asserts/common/3.0x/" + titles[index];
      } else {
        title = commonPre + titles[index];
      }
      return title;
    });

    for (var i = 0; i < titles.length; i++) {
      BaseModel model = BaseModel(imagePaths[i], '', 0.0);
      uiList.add(model);
    }

    this.dataModel.dataList = uiList;
    this.selectedIndex = 0;
    this.selectedModel = this.dataModel.dataList[this.selectedIndex];

    FUStickerPlugin.config();

    _initSelectedItem();
  }

  _initSelectedItem() {
    super.selectedItem(selectedIndex);
    //native plugin
    FUStickerPlugin.selectedItem(selectedIndex);
  }

  @override
  showBoard() {
    return true;
  }

  @override
  void selectedItem(int index) async {
    super.selectedItem(index);
    //native plugin
    FUStickerPlugin.selectedItem(index);

    // 缓存选择索引
    SharedPreferences sp = await SharedPreferences.getInstance();
    sp.setString('fuStickerIndex', index.toString());
  }

  @override
  void sliderValueChange(double value) {
    //没有slider 不处理
  }

  @override
  Future sliderValueChangeAtIndex(int index, double value) async {
    return;
  }

  @override
  readCachedValues() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    String? indexStr = sp.getString('fuStickerIndex');
    if (indexStr == null) return;
    int index = int.parse(indexStr);
    FUStickerPlugin.selectedItem(index);
    this.selectedIndex = index;
    this.selectedModel = this.dataModel.dataList[this.selectedIndex];
  }

  @override
  init() {}

  @override
  dealloc() {
    FUStickerPlugin.dispose();
    super.dealloc();
  }
}
