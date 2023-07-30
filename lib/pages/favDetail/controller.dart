import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:pilipala/http/user.dart';
import 'package:pilipala/http/video.dart';
import 'package:pilipala/models/user/fav_detail.dart';
import 'package:pilipala/models/user/fav_folder.dart';

class FavDetailController extends GetxController {
  FavFolderItemData? item;
  Rx<FavDetailData> favDetailData = FavDetailData().obs;

  int? mediaId;
  late String heroTag;
  int currentPage = 1;
  bool isLoadingMore = false;
  RxMap favInfo = {}.obs;
  RxList<FavDetailItemData> favList = [FavDetailItemData()].obs;

  @override
  void onInit() {
    item = Get.arguments;
    if (Get.parameters.keys.isNotEmpty) {
      mediaId = int.parse(Get.parameters['mediaId']!);
      heroTag = Get.parameters['heroTag']!;
    }
    super.onInit();
  }

  Future<dynamic> queryUserFavFolderDetail({type = 'init'}) async {
    var res = await await UserHttp.userFavFolderDetail(
      pn: currentPage,
      ps: 20,
      mediaId: mediaId!,
    );
    if (res['status']) {
      favInfo.value = res['data'].info;
      if (currentPage == 1 && type == 'init') {
        favList.value = res['data'].medias;
      } else if (type == 'onload') {
        favList.addAll(res['data'].medias);
      }
    }
    currentPage += 1;
    return res;
  }

  onCancelFav(int id) async {
    var result = await VideoHttp.favVideo(
        aid: id, addIds: '', delIds: mediaId.toString());
    if (result['status']) {
      if (result['data']['prompt']) {
        List<FavDetailItemData> dataList = favDetailData.value.medias!;
        for (var i in dataList) {
          if (i.id == id) {
            dataList.remove(i);
            break;
          }
        }
        favDetailData.value.medias = dataList;
        favDetailData.refresh();
        SmartDialog.showToast('取消收藏');
      }
    }
  }

  onLoad() {
    queryUserFavFolderDetail(type: 'onload');
  }
}
