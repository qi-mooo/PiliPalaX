import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:PiliPalaX/common/constants.dart';
import 'package:PiliPalaX/common/widgets/animated_dialog.dart';
import 'package:PiliPalaX/common/skeleton/video_card_h.dart';
import 'package:PiliPalaX/common/widgets/http_error.dart';
import 'package:PiliPalaX/common/widgets/video_card_h.dart';
import 'package:PiliPalaX/pages/home/index.dart';
import 'package:PiliPalaX/pages/main/index.dart';
import 'package:PiliPalaX/pages/rank/zone/index.dart';

import '../../../utils/grid.dart';

class ZonePage extends StatefulWidget {
  const ZonePage({Key? key, required this.rid}) : super(key: key);

  final int rid;

  @override
  State<ZonePage> createState() => _ZonePageState();
}

class _ZonePageState extends State<ZonePage>
    with AutomaticKeepAliveClientMixin {
  late ZoneController _zoneController;
  Future? _futureBuilderFuture;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _zoneController = Get.put(ZoneController(), tag: widget.rid.toString());
    _futureBuilderFuture = _zoneController.queryRankFeed('init', widget.rid);
    StreamController<bool> mainStream =
        Get.find<MainController>().bottomBarStream;
    StreamController<bool> searchBarStream =
        Get.find<HomeController>().searchBarStream;
    _zoneController.scrollController.addListener(
      () {
        if (_zoneController.scrollController.position.pixels >=
            _zoneController.scrollController.position.maxScrollExtent - 200) {
          if (!_zoneController.isLoadingMore) {
            _zoneController.isLoadingMore = true;
            _zoneController.onLoad();
          }
        }

        final ScrollDirection direction =
            _zoneController.scrollController.position.userScrollDirection;
        if (direction == ScrollDirection.forward) {
          mainStream.add(true);
          searchBarStream.add(true);
        } else if (direction == ScrollDirection.reverse) {
          mainStream.add(false);
          searchBarStream.add(false);
        }
      },
    );
  }

  @override
  void dispose() {
    _zoneController.scrollController.removeListener(() {});
    _zoneController.scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return RefreshIndicator(
      onRefresh: () async {
        return await _zoneController.onRefresh();
      },
      child: CustomScrollView(
        controller: _zoneController.scrollController,
        slivers: [
          SliverPadding(
            // 单列布局 EdgeInsets.zero
            padding: const EdgeInsets.fromLTRB(
                StyleString.cardSpace, StyleString.safeSpace, 0, 0),
            sliver: FutureBuilder(
              future: _futureBuilderFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  Map data = snapshot.data as Map;
                  if (data['status']) {
                    return Obx(
                      () => SliverGrid(
                        gridDelegate: SliverGridDelegateWithExtentAndRatio(
                            mainAxisSpacing: StyleString.safeSpace,
                            crossAxisSpacing: StyleString.safeSpace,
                            maxCrossAxisExtent: Grid.maxRowWidth * 2,
                            childAspectRatio: StyleString.aspectRatio * 2.4,
                            mainAxisExtent: 13),
                        delegate: SliverChildBuilderDelegate((context, index) {
                          return VideoCardH(
                            videoItem: _zoneController.videoList[index],
                            showPubdate: true,
                            longPress: () {
                              _zoneController.popupDialog.add(
                                  _createPopupDialog(
                                      _zoneController.videoList[index]));
                              Overlay.of(context)
                                  .insert(_zoneController.popupDialog.last!);
                            },
                            longPressEnd: _removePopupDialog,
                          );
                        }, childCount: _zoneController.videoList.length),
                      ),
                    );
                  } else {
                    return HttpError(
                      errMsg: data['msg'],
                      fn: () {
                        setState(() {
                          _futureBuilderFuture =
                              _zoneController.queryRankFeed('init', widget.rid);
                        });
                      },
                    );
                  }
                } else {
                  // 骨架屏
                  return SliverGrid(
                    gridDelegate: SliverGridDelegateWithExtentAndRatio(
                        mainAxisSpacing: StyleString.safeSpace,
                        crossAxisSpacing: StyleString.safeSpace,
                        maxCrossAxisExtent: Grid.maxRowWidth * 2,
                        childAspectRatio: StyleString.aspectRatio * 2.4,
                        mainAxisExtent: 0),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      return const VideoCardHSkeleton();
                    }, childCount: 10),
                  );
                }
              },
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: MediaQuery.of(context).padding.bottom + 10,
            ),
          )
        ],
      ),
    );
  }

  void _removePopupDialog() {
    _zoneController.popupDialog.last?.remove();
    _zoneController.popupDialog.removeLast();
  }

  OverlayEntry _createPopupDialog(videoItem) {
    return OverlayEntry(
      builder: (context) => AnimatedDialog(
        closeFn: _removePopupDialog,
        videoItem: videoItem,
      ),
    );
  }
}
