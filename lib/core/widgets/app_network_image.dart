import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile_emi_manager/app/theme/app_colors.dart';
import 'package:mobile_emi_manager/app/theme/app_dimensions.dart';
import 'package:mobile_emi_manager/core/widgets/app_loader.dart';

/// Reusable network image widget with loading, error, and empty URL states.
///
/// The backend provides URLs, not file data. This widget handles all edge
/// cases so individual widgets don't need to worry about them.
class AppNetworkImage extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;

  const AppNetworkImage({
    super.key,
    this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    final defaultPlaceholder = Container(
      width: width,
      height: height,
      color: AppColors.shimmerBase,
      child: const Center(
        child: AppShimmer(),
      ),
    );

    final defaultError = Container(
      width: width,
      height: height,
      color: AppColors.shimmerBase,
      child: const Icon(
        Icons.broken_image_outlined,
        color: AppColors.textDisabled,
        size: AppDimensions.iconLg,
      ),
    );

    if (url == null || url!.isEmpty) {
      return ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: errorWidget ?? defaultError,
      );
    }

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: CachedNetworkImage(
        imageUrl: url!,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => placeholder ?? defaultPlaceholder,
        errorWidget: (context, url, error) => errorWidget ?? defaultError,
      ),
    );
  }
}
