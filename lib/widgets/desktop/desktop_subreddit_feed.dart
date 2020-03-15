import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pagewise/flutter_pagewise.dart';
import 'package:fritter_for_reddit/exports.dart';
import 'package:fritter_for_reddit/helpers/functions/conversion_functions.dart';
import 'package:fritter_for_reddit/helpers/functions/hex_to_color_class.dart';
import 'package:fritter_for_reddit/models/postsfeed/posts_feed_entity.dart';
import 'package:fritter_for_reddit/widgets/comments/comments_page.dart';
import 'package:fritter_for_reddit/widgets/common/go_to_subreddit.dart';
import 'package:fritter_for_reddit/widgets/desktop/desktop_feed_list_item.dart';
import 'package:fritter_for_reddit/widgets/drawer/drawer.dart';
import 'package:fritter_for_reddit/widgets/feed/feed_list_item.dart';

import 'package:fritter_for_reddit/widgets/feed/post_controls.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DesktopSubredditFeed extends StatefulWidget {
  final String pageTitle;

  DesktopSubredditFeed({this.pageTitle = ""});

  @override
  _DesktopSubredditFeedState createState() => _DesktopSubredditFeedState();
}

// TODO : implement posting to subreddits
class _DesktopSubredditFeedState extends State<DesktopSubredditFeed>
    with TickerProviderStateMixin {
  ScrollController _controller;
  String sortSelectorValue = "Best";
  GlobalKey key = new GlobalKey();

  @override
  void initState() {
    _controller = new ScrollController();
    _controller.addListener(_scrollListener);
    super.initState();
  }

  void _scrollListener() async {
    if (_controller.position.maxScrollExtent - _controller.offset <= 400 &&
        Provider.of<FeedProvider>(context, listen: false).loadMorePostsState !=
            ViewState.Busy) {
      Provider.of<FeedProvider>(context, listen: false).loadMorePosts();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  FeedProvider get feedProvider =>
      Provider.of<FeedProvider>(context, listen: false);

  @override
  Widget build(BuildContext context) {
    return Consumer<FeedProvider>(
      builder: (BuildContext context, FeedProvider model, _) {
        return CustomScrollView(
          controller: _controller,
          physics: AlwaysScrollableScrollPhysics(),
          slivers: <Widget>[
            SliverAppBar(
              iconTheme: Theme.of(context).iconTheme,
              actions: <Widget>[
                PopupMenuButton<String>(
                  key: key,
                  icon: Icon(
                    Icons.sort,
                  ),
                  onSelected: (value) {
                    final RenderBox box = key.currentContext.findRenderObject();
                    final positionDropDown = box.localToGlobal(Offset.zero);
                    // print(
                    if (value == "Top") {
                      sortSelectorValue = "Top";
                      showMenu(
                        position: RelativeRect.fromLTRB(
                          positionDropDown.dx,
                          positionDropDown.dy,
                          0,
                          0,
                        ),
                        context: context,
                        items: <String>[
                          'Day',
                          'Week',
                          'Month',
                          'Year',
                          'All',
                        ].map((value) {
                          return PopupMenuItem<String>(
                            value: value,
                            child: ListTile(
                              title: Text(value),
                              onTap: () {
                                Navigator.of(context, rootNavigator: false)
                                    .pop();

                                model.fetchPostsListing(
                                  currentSort: "/top/.json?sort=top&t=$value",
                                  currentSubreddit: model.sub,
                                  loadingTop: true,
                                );
                              },
                            ),
                          );
                        }).toList(),
                      );
                    } else if (value == 'Close' || value == sortSelectorValue) {
                    } else {
                      sortSelectorValue = value;
                      feedProvider.fetchPostsListing(
                        currentSort: value,
                        currentSubreddit: model.sub,
                        loadingTop: false,
                      );
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    return <String>[
                      'Best',
                      'Hot',
                      'Top',
                      'New',
                      'Controversial',
                      'Rising'
                    ].map((String value) {
                      return new PopupMenuItem<String>(
                        value: value,
                        child: new Text(value),
                      );
                    }).toList();
                  },
                  onCanceled: () {},
                  initialValue: sortSelectorValue,
                ),
                IconButton(
                  icon: Icon(Icons.info_outline),
                  color: Theme.of(context).iconTheme.color,
                  onPressed: () {
                    showSubInformationSheet(context);
                  },
                )
              ],
              pinned: true,
              snap: true,
              floating: true,
              primary: true,
              elevation: 0,
              brightness: MediaQuery.of(context).platformBrightness,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              textTheme: Theme.of(context).textTheme,
              centerTitle: true,
              title: model.currentPage != CurrentPage.FrontPage
                  ? Text(
                      '/r/' + model.sub.toString(),
                      textAlign: TextAlign.center,
                    )
                  : Text('Frontpage', textAlign: TextAlign.center),
            ),
            FeedList(feedProvider: model)
          ],
        );
//        return ListView.builder(
//          itemBuilder: (BuildContext context, int index) {
//            var item = model.postFeed.data.children[index].data;
//            return Material(
//              borderRadius: BorderRadius.circular(0.0),
//              clipBehavior: Clip.antiAlias,
//              color: Theme.of(context).cardColor,
//              child: InkWell(
//                enableFeedback: false,
//                onDoubleTap: () {
//                  if (item.isSelf == false) {
//                    launchURL(Theme.of(context).primaryColor, item.url);
//                  }
//                },
//                onTap: () {
//                  _openComments(item, context, index);
//                },
//                child: Column(
//                  children: <Widget>[
//                    FeedCard(
//                      item,
//                    ),
//                    PostControls(
//                      postData: item,
//                    ),
//                  ],
//                ),
//              ),
//            );
//          },
//          controller: _controller,
//          itemCount: model.postFeed.data.children.length,
//          cacheExtent: 20,
//          addAutomaticKeepAlives: false,
//        );
      },
    );
  }

  void showSubInformationSheet(BuildContext context) {
    final feedProvider = Provider.of<FeedProvider>(context, listen: false);
    showCupertinoModalPopup(
      context: context,
      useRootNavigator: true,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
            builder: (BuildContext context, ScrollController controller) {
          return Material(
            child: Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(context).scaffoldBackgroundColor),
              padding: const EdgeInsets.all(8.0),
              child: Consumer(
                builder: (BuildContext context, FeedProvider model, _) {
                  var headerColor = MediaQuery.of(context).platformBrightness ==
                          Brightness.dark
                      ? TransparentHexColor("#000000", "80")
                      : TransparentHexColor("#FFFFFF", "aa");

                  if (feedProvider.subredditInformationEntity != null &&
                      feedProvider.subredditInformationEntity.data
                              .bannerBackgroundColor !=
                          "") {
                    headerColor = TransparentHexColor(
                      feedProvider.subredditInformationEntity.data
                          .bannerBackgroundColor,
                      "50",
                    );
                  }
                  return Container(
                    // Don't wrap this in any SafeArea widgets, use padding instead
                    padding: EdgeInsets.all(0),
                    color: headerColor,
                    // Use Stack and Positioned to create the toolbar slide up effect when scrolled up
                    child: feedProvider != null
                        ? feedProvider.state == ViewState.Idle
                            ? feedProvider.currentPage == CurrentPage.FrontPage
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      RaisedButton(
                                        child: Text('Logout'),
                                        onPressed: () {
                                          SharedPreferences.getInstance()
                                              .then((value) => value.clear());
                                        },
                                      ),
                                      Row(
                                        children: <Widget>[
                                          Text(
                                            'Front Page',
                                            style: Theme.of(context)
                                                .textTheme
                                                .headline
                                                .copyWith(
                                                    fontWeight:
                                                        FontWeight.bold),
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.chevron_right),
                                            onPressed: () {
                                              return Navigator.of(context,
                                                      rootNavigator: false)
                                                  .push(
                                                CupertinoPageRoute(
                                                  maintainState: true,
                                                  builder: (context) =>
                                                      LeftDrawer(
                                                    mode: Mode.desktop,
                                                  ),
                                                  fullscreenDialog: false,
                                                ),
                                              );
                                            },
                                            color:
                                                Theme.of(context).accentColor,
                                          )
                                        ],
                                      ),
                                    ],
                                  )
                                : Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0,
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: <Widget>[
                                        SizedBox(
                                          height: 24,
                                        ),
                                        feedProvider.subredditInformationEntity !=
                                                null
                                            ? CircleAvatar(
                                                maxRadius: 24,
                                                minRadius: 24,
                                                backgroundImage: feedProvider
                                                            .subredditInformationEntity
                                                            .data
                                                            .communityIcon !=
                                                        ""
                                                    ? CachedNetworkImageProvider(
                                                        feedProvider
                                                            .subredditInformationEntity
                                                            .data
                                                            .communityIcon,
                                                      )
                                                    : feedProvider
                                                                .subredditInformationEntity
                                                                .data
                                                                .iconImg !=
                                                            ""
                                                        ? CachedNetworkImageProvider(
                                                            feedProvider
                                                                .subredditInformationEntity
                                                                .data
                                                                .iconImg,
                                                          )
                                                        : AssetImage(
                                                            'assets/default_icon.png'),
                                                backgroundColor: feedProvider
                                                            .subredditInformationEntity
                                                            .data
                                                            .primaryColor ==
                                                        ""
                                                    ? Theme.of(context)
                                                        .accentColor
                                                    : HexColor(
                                                        feedProvider
                                                            .subredditInformationEntity
                                                            .data
                                                            .primaryColor,
                                                      ),
                                              )
                                            : Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: <Widget>[
                                                  Row(
                                                    children: <Widget>[
                                                      Text(
                                                        widget.pageTitle,
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .headline
                                                            .copyWith(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                        feedProvider.subredditInformationEntity !=
                                                null
                                            ? Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: <Widget>[
                                                  SizedBox(
                                                    height: 8,
                                                  ),
                                                  Text(
                                                    feedProvider
                                                        .subredditInformationEntity
                                                        .data
                                                        .displayNamePrefixed,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .headline
                                                        .copyWith(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                    overflow: TextOverflow.fade,
                                                    textAlign: TextAlign.center,
                                                    softWrap: false,
                                                  ),
                                                  Text(
                                                    getRoundedToThousand(
                                                            feedProvider
                                                                .subredditInformationEntity
                                                                .data
                                                                .subscribers) +
                                                        " Subscribers",
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .subhead,
                                                  ),
                                                  SizedBox(
                                                    height: 8,
                                                  ),
                                                  feedProvider
                                                              .subredditInformationEntity
                                                              .data
                                                              .userIsSubscriber !=
                                                          null
                                                      ? FlatButton(
                                                          textColor:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .body1
                                                                  .color,
                                                          child: feedProvider
                                                                      .partialState ==
                                                                  ViewState.Busy
                                                              ? Container(
                                                                  width: 24.0,
                                                                  height: 24.0,
                                                                  child: Center(
                                                                    child:
                                                                        CircularProgressIndicator(),
                                                                  ),
                                                                )
                                                              : Text(
                                                                  feedProvider
                                                                          .subredditInformationEntity
                                                                          .data
                                                                          .userIsSubscriber
                                                                      ? 'Subscribed'
                                                                      : 'Join',
                                                                ),
                                                          onPressed: () {
                                                            feedProvider
                                                                .changeSubscriptionStatus(
                                                              feedProvider
                                                                  .subredditInformationEntity
                                                                  .data
                                                                  .name,
                                                              !feedProvider
                                                                  .subredditInformationEntity
                                                                  .data
                                                                  .userIsSubscriber,
                                                            );
                                                          },
                                                        )
                                                      : Container(),
                                                ],
                                              )
                                            : Container(),
                                        SizedBox(
                                          height: 24.0,
                                        )
                                      ],
                                    ),
                                  )
                            : Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: CircularProgressIndicator(),
                                ),
                              )
                        : Padding(
                            padding: EdgeInsets.symmetric(
                                vertical: 32, horizontal: 16),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Front Page',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headline
                                      .copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                  );
                },
              ),
            ),
          );
        });
      },
    );
  }
}

class DesktopPostCard extends StatelessWidget {
  const DesktopPostCard({
    Key key,
    @required this.item,
  }) : super(key: key);

  final PostsFeedDataChildrenData item;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        DesktopFeedCard(
          item,
        ),
        PostControls(
          postData: item,
        ),
      ],
    );
  }
}

class FeedList extends StatelessWidget {
  final FeedProvider feedProvider;

  bool get hasError =>
      feedProvider.subredditInformationError ||
      feedProvider.feedInformationError;

  const FeedList({Key key, @required this.feedProvider}) : super(key: key);

  @override
  Widget build2(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(),
    );
  }

  @override
  Widget build(BuildContext context) {
    SliverChildDelegate sliverChildDelegate;
    if (hasError) {
      sliverChildDelegate = SliverChildListDelegate([
        Column(
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            Icon(Icons.error_outline),
            Text("Couldn't Load subreddit")
          ],
        )
      ]);
    } else {
      if (feedProvider.state == ViewState.Idle &&
          Provider.of<UserInformationProvider>(context, listen: false).state ==
              ViewState.Idle) {
        sliverChildDelegate = SliverChildBuilderDelegate(
          (BuildContext context, int index) {
            if (index == feedProvider.postFeed.data.children.length * 2) {
              bool isLoading =
                  feedProvider.loadMorePostsState == ViewState.Busy;
              if (isLoading) {
                return Material(
                  color: Theme.of(context).cardColor,
                  child: Column(
                    children: <Widget>[
                      ListTile(
                        title: Center(child: CircularProgressIndicator()),
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).padding.bottom * 2,
                      ),
                    ],
                  ),
                );
              } else {
                return Container();
              }
            }

            if (index % 2 == 1) {
              return Divider();
            }
            var item = feedProvider.postFeed.data.children[(index ~/ 2)].data;
            return InkWell(
              onDoubleTap: () {
                if (item.isSelf == false) {
                  launchURL(Theme.of(context).primaryColor, item.url);
                }
              },
              onTap: () {
                _openComments(item, context, index);
              },
              child: DesktopPostCard(item: item),
            );
          },
          childCount: feedProvider.postFeed.data.children.length * 2 + 1,
        );
      } else {
        sliverChildDelegate = SliverChildListDelegate([
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: LinearProgressIndicator(),
          )
        ]);
      }
    }
    return SliverList(
      delegate: sliverChildDelegate,
    );
  }

  void _openComments(
      PostsFeedDataChildrenData item, BuildContext context, int index) {
    Provider.of<CommentsProvider>(context, listen: false).fetchComments(
      requestingRefresh: false,
      subredditName: item.subreddit,
      postId: item.id,
      sort: item.suggestedSort != null
          ? changeCommentSortConvertToEnum[item.suggestedSort]
          : CommentSortTypes.Best,
    );
    Navigator.of(context).push(
//      PageRouteBuilder(
//        pageBuilder: (BuildContext context, _, __) {
//          return CommentsSheet(item);
//        },
//        fullscreenDialog: false,
//        opaque: true,
//        transitionsBuilder:
//            (context, primaryanimation, secondaryanimation, child) {
//          return FadeTransition(
//            child: child,
//            opacity: CurvedAnimation(
//              parent: primaryanimation,
//              curve: Curves.easeInToLinear,
//              reverseCurve: Curves.linearToEaseOut,
//            ),
//          );
//        },
//        transitionDuration: Duration(
//          milliseconds: 250,
//        ),
//      ),

      CupertinoPageRoute(
        maintainState: true,
        builder: (BuildContext context) {
          return CommentsScreen(
            postData: item,
          );
        },
      ),
    );
  }
}
