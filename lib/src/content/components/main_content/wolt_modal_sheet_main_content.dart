import 'package:flutter/material.dart';
import 'package:wolt_modal_sheet/src/content/components/main_content/wolt_modal_sheet_hero_image.dart';
import 'package:wolt_modal_sheet/src/theme/wolt_modal_sheet_default_theme_data.dart';
import 'package:wolt_modal_sheet/src/utils/drag_scroll_behavior.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

/// The main content widget within the scrollable modal sheet.
///
/// This widget is responsible for displaying the main content of the scrollable modal sheet.
/// It handles the scroll behavior, page layout, and interactions within the modal sheet.
class WoltModalSheetMainContent extends StatefulWidget {
  final ValueNotifier<double> currentScrollPosition;
  final GlobalKey pageTitleKey;
  final SliverWoltModalSheetPage page;
  final WoltModalType woltModalType;

  const WoltModalSheetMainContent({
    required this.currentScrollPosition,
    required this.pageTitleKey,
    required this.page,
    required this.woltModalType,
    Key? key,
  }) : super(key: key);

  @override
  State<WoltModalSheetMainContent> createState() =>
      _WoltModalSheetMainContentState();
}

class _WoltModalSheetMainContentState extends State<WoltModalSheetMainContent> {
  late ScrollController scrollController;

  @override
  void initState() {
    super.initState();
    scrollController = widget.page.scrollController ??
        ScrollController(
            initialScrollOffset: widget.currentScrollPosition.value);
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context).extension<WoltModalSheetThemeData>();
    final defaultThemeData = WoltModalSheetDefaultThemeData(context);
    final page = widget.page;
    final heroImageHeight = page.heroImage == null
        ? 0.0
        : (page.heroImageHeight ??
            themeData?.heroImageHeight ??
            defaultThemeData.heroImageHeight);
    final pageHasTopBarLayer = page.hasTopBarLayer ??
        themeData?.hasTopBarLayer ??
        defaultThemeData.hasTopBarLayer;
    final isTopBarLayerAlwaysVisible =
        pageHasTopBarLayer && page.isTopBarLayerAlwaysVisible == true;
    final navBarHeight = page.navBarHeight ??
        themeData?.navBarHeight ??
        defaultThemeData.navBarHeight;
    final topBarHeight = pageHasTopBarLayer ||
            page.leadingNavBarWidget != null ||
            page.trailingNavBarWidget != null
        ? navBarHeight
        : 0.0;
    final scrollView = CustomScrollView(
      scrollBehavior: const DragScrollBehavior(),
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      controller: scrollController,
      slivers: [
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index == 0) {
                final heroImage = page.heroImage;
                return heroImage != null
                    ? WoltModalSheetHeroImage(
                        topBarHeight: topBarHeight,
                        heroImage: heroImage,
                        heroImageHeight: heroImageHeight,
                      )
                    // If top bar layer is always visible, the padding is explicitly added to the
                    // scroll view since top bar will not be integrated to scroll view at all.
                    // Otherwise, we implicitly create a spacing as a part of the scroll view.
                    : SizedBox(
                        height: isTopBarLayerAlwaysVisible ? 0 : topBarHeight);
              } else {
                final pageTitle = page.pageTitle;
                return KeyedSubtree(
                  key: widget.pageTitleKey,
                  child: pageTitle ?? const SizedBox.shrink(),
                );
              }
            },
            childCount: 2,
          ),
        ),
        ...page.mainContentSlivers,
        if (page.forceMaxHeight)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: SizedBox.shrink(),
          ),
      ],
    );
    return NotificationListener<ScrollNotification>(
      onNotification: (scrollNotification) {
        final isVerticalScrollNotification =
            scrollNotification is ScrollUpdateNotification &&
                scrollNotification.metrics.axis == Axis.vertical;
        if (isVerticalScrollNotification) {
          widget.currentScrollPosition.value =
              scrollNotification.metrics.pixels;
        }
        return false;
      },
      child: Padding(
        // The scroll view should be padded by the height of the top bar layer if it's always
        // visible. Otherwise, over scroll effect will not be visible due to the top bar layer.
        padding:
            EdgeInsets.only(top: isTopBarLayerAlwaysVisible ? topBarHeight : 0),
        child: scrollView,
      ),
    );
  }
}
