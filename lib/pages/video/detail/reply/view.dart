import 'package:PiliPalaX/common/widgets/http_error.dart';
import 'package:PiliPalaX/pages/video/detail/reply_new/reply_page.dart';
import 'package:easy_debounce/easy_throttle.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:PiliPalaX/common/skeleton/video_reply.dart';
import 'package:PiliPalaX/models/common/reply_type.dart';
import 'package:PiliPalaX/pages/video/detail/index.dart';
import 'package:PiliPalaX/utils/feed_back.dart';
import 'package:PiliPalaX/utils/id_utils.dart';
import 'package:get/get_navigation/src/dialog/dialog_route.dart';
import 'controller.dart';
import 'widgets/reply_item.dart';

class VideoReplyPanel extends StatefulWidget {
  final String? bvid;
  final int? oid;
  final int rpid;
  final String? replyLevel;
  final String heroTag;

  const VideoReplyPanel({
    this.bvid,
    this.oid,
    this.rpid = 0,
    this.replyLevel,
    required this.heroTag,
    super.key,
  });

  @override
  State<VideoReplyPanel> createState() => _VideoReplyPanelState();
}

class _VideoReplyPanelState extends State<VideoReplyPanel>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  late VideoReplyController _videoReplyController;
  late AnimationController fabAnimationCtr;

  late final _savedReplies = {};

  bool _isFabVisible = true;
  String replyLevel = '1';
  late String heroTag;

  // 添加页面缓存
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // int oid = widget.bvid != null ? IdUtils.bv2av(widget.bvid!) : 0;
    // heroTag = Get.arguments['heroTag'];
    heroTag = widget.heroTag;
    replyLevel = widget.replyLevel ?? '1';
    if (replyLevel == '2') {
      _videoReplyController = Get.put(
          VideoReplyController(widget.oid, widget.rpid.toString(), replyLevel),
          tag: widget.rpid.toString());
    } else {
      _videoReplyController = Get.find<VideoReplyController>(tag: heroTag);
    }

    fabAnimationCtr = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));

    fabAnimationCtr.forward();
    scrollListener();
  }

  @override
  void dispose() {
    _videoReplyController.scrollController.removeListener(() {});
    fabAnimationCtr.dispose();
    // _videoReplyController.scrollController.dispose();
    super.dispose();
  }

  void scrollListener() {
    _videoReplyController.scrollController.addListener(
      () {
        if (_videoReplyController.scrollController.position.pixels >=
            _videoReplyController.scrollController.position.maxScrollExtent -
                300) {
          EasyThrottle.throttle('replylist', const Duration(milliseconds: 200),
              () {
            _videoReplyController.onLoad();
          });
        }

        final ScrollDirection direction =
            _videoReplyController.scrollController.position.userScrollDirection;
        if (direction == ScrollDirection.forward) {
          if (mounted) {
            _showFab();
          }
        } else if (direction == ScrollDirection.reverse) {
          if (mounted) {
            _hideFab();
          }
        }
      },
    );
  }

  void _showFab() {
    if (!_isFabVisible) {
      _isFabVisible = true;
      fabAnimationCtr.forward();
    }
  }

  void _hideFab() {
    if (_isFabVisible) {
      _isFabVisible = false;
      fabAnimationCtr.reverse();
    }
  }

  // 展示二级回复
  void replyReply(replyItem) {
    final VideoDetailController videoDetailCtr =
        Get.find<VideoDetailController>(tag: heroTag);
    if (replyItem != null) {
      videoDetailCtr.oid.value = replyItem.oid;
      videoDetailCtr.fRpid = replyItem.rpid!;
      videoDetailCtr.firstFloor = replyItem;
      videoDetailCtr.showReplyReplyPanel();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return RefreshIndicator(
      onRefresh: () async {
        await _videoReplyController.queryReplyList(type: 'init');
      },
      child: Stack(
        children: [
          CustomScrollView(
            controller: _videoReplyController.scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            key: const PageStorageKey<String>('评论'),
            slivers: <Widget>[
              SliverPersistentHeader(
                pinned: false,
                floating: true,
                delegate: _MySliverPersistentHeaderDelegate(
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.fromLTRB(12, 0, 6, 0),
                    color: Theme.of(context).colorScheme.surface,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Obx(
                          () => Text(
                            '${_videoReplyController.sortTypeLabel.value}评论',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        SizedBox(
                          height: 35,
                          child: TextButton.icon(
                            onPressed: () =>
                                _videoReplyController.queryBySort(),
                            icon: const Icon(Icons.sort, size: 16),
                            label: Obx(
                              () => Text(
                                _videoReplyController.sortTypeLabel.value,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
              FutureBuilder(
                future: _videoReplyController.futureBuilderFuture,
                builder: (BuildContext context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    var data = snapshot.data;
                    if (data['status']) {
                      // 请求成功
                      return Obx(
                        () => _videoReplyController.isLoadingMore &&
                                _videoReplyController.replyList.isEmpty
                            ? SliverList(
                                delegate: SliverChildBuilderDelegate(
                                    (BuildContext context, index) {
                                  return const VideoReplySkeleton();
                                }, childCount: 5),
                              )
                            : SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (BuildContext context, index) {
                                    double bottom =
                                        MediaQuery.of(context).padding.bottom;
                                    if (index ==
                                        _videoReplyController
                                            .replyList.length) {
                                      return Container(
                                        padding:
                                            EdgeInsets.only(bottom: bottom),
                                        height: bottom + 100,
                                        child: Center(
                                          child: Obx(
                                            () => Text(
                                              _videoReplyController
                                                  .noMore.value,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .outline,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    } else {
                                      return ReplyItem(
                                        replyItem: _videoReplyController
                                            .replyList[index],
                                        showReplyRow: true,
                                        replyLevel: replyLevel,
                                        replyReply: (replyItem) =>
                                            replyReply(replyItem),
                                        replyType: ReplyType.video,
                                        onReply: () {
                                          dynamic oid = _videoReplyController
                                              .replyList[index].oid;
                                          dynamic root = _videoReplyController
                                              .replyList[index].rpid;
                                          dynamic parent = _videoReplyController
                                              .replyList[index].rpid;
                                          dynamic key = oid + root + parent;
                                          Navigator.of(context)
                                              .push(
                                            GetDialogRoute(
                                              pageBuilder: (buildContext,
                                                  animation,
                                                  secondaryAnimation) {
                                                return ReplyPage(
                                                  oid: oid,
                                                  root: root,
                                                  parent: parent,
                                                  replyType: ReplyType.video,
                                                  replyItem:
                                                      _videoReplyController
                                                          .replyList[index],
                                                  savedReply:
                                                      _savedReplies[key],
                                                  onSaveReply: (reply) {
                                                    _savedReplies[key] = reply;
                                                  },
                                                );
                                              },
                                              transitionDuration:
                                                  const Duration(
                                                      milliseconds: 500),
                                              transitionBuilder: (context,
                                                  animation,
                                                  secondaryAnimation,
                                                  child) {
                                                const begin = Offset(0.0, 1.0);
                                                const end = Offset.zero;
                                                const curve = Curves.linear;

                                                var tween = Tween(
                                                        begin: begin, end: end)
                                                    .chain(CurveTween(
                                                        curve: curve));

                                                return SlideTransition(
                                                  position:
                                                      animation.drive(tween),
                                                  child: child,
                                                );
                                              },
                                            ),
                                          )
                                              .then((value) {
                                            // 完成评论，数据添加
                                            if (value != null &&
                                                value['data'] != null) {
                                              _savedReplies[key] = null;
                                            }
                                          });
                                        },
                                        onDelete: (rpid, frpid) {
                                          _videoReplyController.replyList.value =
                                              frpid == null
                                                  ? _videoReplyController
                                                      .replyList
                                                      .where((item) =>
                                                          item.rpid != rpid)
                                                      .toList()
                                                  : _videoReplyController
                                                      .replyList
                                                      .map((item) {
                                                      if (item.rpid == frpid) {
                                                        return item
                                                          ..replies = item
                                                              .replies
                                                              ?.where((reply) =>
                                                                  reply.rpid !=
                                                                  rpid)
                                                              .toList();
                                                      } else {
                                                        return item;
                                                      }
                                                    }).toList();
                                        },
                                      );
                                    }
                                  },
                                  childCount:
                                      _videoReplyController.replyList.length +
                                          1,
                                ),
                              ),
                      );
                    } else {
                      // 请求错误
                      return HttpError(
                        errMsg: data['msg'],
                        fn: () {
                          setState(() {
                            _videoReplyController.futureBuilderFuture =
                                _videoReplyController.queryReplyList();
                          });
                        },
                      );
                    }
                  } else {
                    // 骨架屏
                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                          (BuildContext context, index) {
                        return const VideoReplySkeleton();
                      }, childCount: 5),
                    );
                  }
                },
              ),
            ],
          ),
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 14,
            right: 14,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 2),
                end: const Offset(0, 0),
              ).animate(CurvedAnimation(
                parent: fabAnimationCtr,
                curve: Curves.easeInOut,
              )),
              child: FloatingActionButton(
                heroTag: null,
                onPressed: () {
                  feedBack();
                  dynamic oid = _videoReplyController.aid ??
                      IdUtils.bv2av(Get.parameters['bvid']!);
                  Navigator.of(context)
                      .push(
                    GetDialogRoute(
                      pageBuilder:
                          (buildContext, animation, secondaryAnimation) {
                        return ReplyPage(
                          oid: oid,
                          root: 0,
                          parent: 0,
                          replyType: ReplyType.video,
                          savedReply: _savedReplies[oid],
                          onSaveReply: (reply) {
                            _savedReplies[oid] = reply;
                          },
                        );
                      },
                      transitionDuration: const Duration(milliseconds: 500),
                      transitionBuilder:
                          (context, animation, secondaryAnimation, child) {
                        const begin = Offset(0.0, 1.0);
                        const end = Offset.zero;
                        const curve = Curves.linear;

                        var tween = Tween(begin: begin, end: end)
                            .chain(CurveTween(curve: curve));

                        return SlideTransition(
                          position: animation.drive(tween),
                          child: child,
                        );
                      },
                    ),
                  )
                      .then(
                    (value) {
                      // 完成评论，数据添加
                      if (value != null && value['data'] != null) {
                        _savedReplies[oid] = null;
                        _videoReplyController.replyList
                            .insert(0, value['data']);
                      }
                    },
                  );
                  // showModalBottomSheet(
                  //   context: context,
                  //   isScrollControlled: true,
                  //   builder: (BuildContext context) {
                  //     return VideoReplyNewDialog(
                  //       oid: _videoReplyController.aid ??
                  //           IdUtils.bv2av(Get.parameters['bvid']!),
                  //       root: 0,
                  //       parent: 0,
                  //       replyType: ReplyType.video,
                  //     );
                  //   },
                  // ).then(
                  //   (value) => {
                  //     // 完成评论，数据添加
                  //     if (value != null && value['data'] != null)
                  //       {
                  //         _videoReplyController.replyList
                  //             .insert(0, value['data'])
                  //       }
                  //   },
                  // );
                },
                tooltip: '发表评论',
                child: const Icon(Icons.reply),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MySliverPersistentHeaderDelegate extends SliverPersistentHeaderDelegate {
  _MySliverPersistentHeaderDelegate({required this.child});
  final double _minExtent = 45;
  final double _maxExtent = 45;
  final Widget child;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    //创建child子组件
    //shrinkOffset：child偏移值minExtent~maxExtent
    //overlapsContent：SliverPersistentHeader覆盖其他子组件返回true，否则返回false
    return child;
  }

  //SliverPersistentHeader最大高度
  @override
  double get maxExtent => _maxExtent;

  //SliverPersistentHeader最小高度
  @override
  double get minExtent => _minExtent;

  @override
  bool shouldRebuild(covariant _MySliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}
