import 'package:flutter/material.dart';
import 'package:flutter_provider_app/exports.dart';
import 'package:flutter_provider_app/models/postsfeed/posts_feed_entity.dart';
import 'package:flutter_provider_app/providers/comments_provider.dart';
import 'package:flutter_provider_app/widgets/comment_list_item.dart';
import 'package:flutter_provider_app/widgets/feed_card.dart';

class CommentsSheet extends StatefulWidget {
  final PostsFeedDataChildrenData item;
  CommentsSheet(this.item);

  @override
  _CommentsSheetState createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      maxChildSize: 1,
      minChildSize: 0.4,
      initialChildSize: 1,
      expand: false,
      builder: (BuildContext context, ScrollController controller) {
        return Consumer(
          builder: (BuildContext context, CommentsProvider model, _) {
            return Scaffold(
              body: CustomScrollView(
                physics: BouncingScrollPhysics(),
                controller: controller,
                slivers: <Widget>[
                  SliverPersistentHeader(
                    pinned: true,
                    floating: true,
                    delegate: _TranslucentSliverAppBarDelegate(
                        MediaQuery.of(context).padding),
                  ),
                  SliverList(
                    delegate: SliverChildListDelegate([
                      Column(
                        children: <Widget>[
                          SizedBox(
                            height: 8.0,
                          ),
                          widget.item.isSelf
                              ? FeedCardSelfText(widget.item, true)
                              : FeedCardImage(widget.item),
                          SizedBox(
                            height: 32,
                          ),
                        ],
                      ),
                    ]),
                  ),
                  SliverList(
                    delegate: model.state == ViewState.Busy
                        ? SliverChildListDelegate(
                            <Widget>[
                              Center(
                                child: CircularProgressIndicator(),
                              )
                            ],
                          )
                        : SliverChildBuilderDelegate(
                            (BuildContext context, int index) {
                              var item = model.commentsList.elementAt(index);
                              return CommentItem(
                                item,
                              );
                            },
                            childCount: model.commentsList.length,
                          ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _TranslucentSliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  /// This is required to calculate the height of the bar
  final EdgeInsets safeAreaPadding;

  _TranslucentSliverAppBarDelegate(this.safeAreaPadding);

  @override
  double get minExtent => safeAreaPadding.top;

  @override
  double get maxExtent => minExtent + 100;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      // Don't wrap this in any SafeArea widgets, use padding instead
      padding: EdgeInsets.only(top: safeAreaPadding.top),
      height: maxExtent,
      color: Colors.transparent,
      // Use Stack and Positioned to create the toolbar slide up effect when scrolled up
      child: Stack(
        overflow: Overflow.clip,
        children: <Widget>[
          Positioned(
            bottom: 0,
            right: 16,
            child: SizedBox(
              height: 48,
              width: 48,
              child: InkWell(
                child: SizedBox(
                  height: 48,
                  width: 48,
                  child: Material(
                    borderRadius: BorderRadius.circular(100),
                    elevation: 5,
                    color: Colors.white,
                    child: Icon(
                      Icons.close,
                      color: Colors.black,
                    ),
                  ),
                ),
                borderRadius: BorderRadius.circular(100),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_TranslucentSliverAppBarDelegate old) {
    return maxExtent != old.maxExtent ||
        minExtent != old.minExtent ||
        safeAreaPadding != old.safeAreaPadding;
  }
}
