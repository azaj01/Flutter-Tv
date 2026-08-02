// dart format width=80

/// GENERATED CODE - DO NOT MODIFY BY HAND
/// *****************************************************
///  FlutterGen
/// *****************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: deprecated_member_use,directives_ordering,implicit_dynamic_list_literal,unnecessary_import

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart' as _svg;
import 'package:lottie/lottie.dart' as _lottie;
import 'package:vector_graphics/vector_graphics.dart' as _vg;

class $AssetsAnimationGen {
  const $AssetsAnimationGen();

  /// File path: assets/animation/loading.json
  LottieGenImage get loading =>
      const LottieGenImage('assets/animation/loading.json');

  /// File path: assets/animation/not_found.json
  LottieGenImage get notFound =>
      const LottieGenImage('assets/animation/not_found.json');

  /// File path: assets/animation/spinner.json
  LottieGenImage get spinner =>
      const LottieGenImage('assets/animation/spinner.json');

  /// File path: assets/animation/splash_loading.json
  LottieGenImage get splashLoading =>
      const LottieGenImage('assets/animation/splash_loading.json');

  /// List of all assets
  List<LottieGenImage> get values =>
      [loading, notFound, spinner, splashLoading];
}

class $AssetsIconsGen {
  const $AssetsIconsGen();

  /// File path: assets/icons/Tiwee.png
  AssetGenImage get tiwee => const AssetGenImage('assets/icons/Tiwee.png');

  /// File path: assets/icons/alarm.svg
  SvgGenImage get alarm => const SvgGenImage('assets/icons/alarm.svg');

  /// File path: assets/icons/animation.svg
  SvgGenImage get animation => const SvgGenImage('assets/icons/animation.svg');

  /// File path: assets/icons/auto.svg
  SvgGenImage get auto => const SvgGenImage('assets/icons/auto.svg');

  /// File path: assets/icons/business.svg
  SvgGenImage get business => const SvgGenImage('assets/icons/business.svg');

  /// File path: assets/icons/comedy.svg
  SvgGenImage get comedy => const SvgGenImage('assets/icons/comedy.svg');

  /// File path: assets/icons/cooking.svg
  SvgGenImage get cooking => const SvgGenImage('assets/icons/cooking.svg');

  /// File path: assets/icons/education.svg
  SvgGenImage get education => const SvgGenImage('assets/icons/education.svg');

  /// File path: assets/icons/entertainment.svg
  SvgGenImage get entertainment =>
      const SvgGenImage('assets/icons/entertainment.svg');

  /// File path: assets/icons/family.svg
  SvgGenImage get family => const SvgGenImage('assets/icons/family.svg');

  /// File path: assets/icons/kids.svg
  SvgGenImage get kids => const SvgGenImage('assets/icons/kids.svg');

  /// File path: assets/icons/life_style.svg
  SvgGenImage get lifeStyle => const SvgGenImage('assets/icons/life_style.svg');

  /// File path: assets/icons/movie.svg
  SvgGenImage get movie => const SvgGenImage('assets/icons/movie.svg');

  /// File path: assets/icons/music.svg
  SvgGenImage get music => const SvgGenImage('assets/icons/music.svg');

  /// File path: assets/icons/news.svg
  SvgGenImage get news => const SvgGenImage('assets/icons/news.svg');

  /// File path: assets/icons/parent_control.svg
  SvgGenImage get parentControl =>
      const SvgGenImage('assets/icons/parent_control.svg');

  /// File path: assets/icons/parent_lock.svg
  SvgGenImage get parentLock =>
      const SvgGenImage('assets/icons/parent_lock.svg');

  /// File path: assets/icons/popcorn.svg
  SvgGenImage get popcorn => const SvgGenImage('assets/icons/popcorn.svg');

  /// File path: assets/icons/relaxation.svg
  SvgGenImage get relaxation =>
      const SvgGenImage('assets/icons/relaxation.svg');

  /// File path: assets/icons/religious.svg
  SvgGenImage get religious => const SvgGenImage('assets/icons/religious.svg');

  /// File path: assets/icons/saved.svg
  SvgGenImage get saved => const SvgGenImage('assets/icons/saved.svg');

  /// File path: assets/icons/science.svg
  SvgGenImage get science => const SvgGenImage('assets/icons/science.svg');

  /// File path: assets/icons/setting.svg
  SvgGenImage get setting => const SvgGenImage('assets/icons/setting.svg');

  /// File path: assets/icons/shop.svg
  SvgGenImage get shop => const SvgGenImage('assets/icons/shop.svg');

  /// File path: assets/icons/sport.svg
  SvgGenImage get sport => const SvgGenImage('assets/icons/sport.svg');

  /// File path: assets/icons/tv.svg
  SvgGenImage get tv => const SvgGenImage('assets/icons/tv.svg');

  /// File path: assets/icons/update.svg
  SvgGenImage get update => const SvgGenImage('assets/icons/update.svg');

  /// List of all assets
  List<dynamic> get values => [
        tiwee,
        alarm,
        animation,
        auto,
        business,
        comedy,
        cooking,
        education,
        entertainment,
        family,
        kids,
        lifeStyle,
        movie,
        music,
        news,
        parentControl,
        parentLock,
        popcorn,
        relaxation,
        religious,
        saved,
        science,
        setting,
        shop,
        sport,
        tv,
        update
      ];
}

abstract final class Assets {
  static const $AssetsAnimationGen animation = $AssetsAnimationGen();
  static const $AssetsIconsGen icons = $AssetsIconsGen();
}

class AssetGenImage {
  const AssetGenImage(
    this._assetName, {
    this.size,
    this.flavors = const {},
    this.animation,
  });

  final String _assetName;

  final Size? size;
  final Set<String> flavors;
  final AssetGenImageAnimation? animation;

  Image image({
    Key? key,
    AssetBundle? bundle,
    ImageFrameBuilder? frameBuilder,
    ImageErrorWidgetBuilder? errorBuilder,
    String? semanticLabel,
    bool excludeFromSemantics = false,
    double? scale,
    double? width,
    double? height,
    Color? color,
    Animation<double>? opacity,
    BlendMode? colorBlendMode,
    BoxFit? fit,
    AlignmentGeometry alignment = Alignment.center,
    ImageRepeat repeat = ImageRepeat.noRepeat,
    Rect? centerSlice,
    bool matchTextDirection = false,
    bool gaplessPlayback = true,
    bool isAntiAlias = false,
    String? package,
    FilterQuality filterQuality = FilterQuality.medium,
    int? cacheWidth,
    int? cacheHeight,
  }) {
    return Image.asset(
      _assetName,
      key: key,
      bundle: bundle,
      frameBuilder: frameBuilder,
      errorBuilder: errorBuilder,
      semanticLabel: semanticLabel,
      excludeFromSemantics: excludeFromSemantics,
      scale: scale,
      width: width,
      height: height,
      color: color,
      opacity: opacity,
      colorBlendMode: colorBlendMode,
      fit: fit,
      alignment: alignment,
      repeat: repeat,
      centerSlice: centerSlice,
      matchTextDirection: matchTextDirection,
      gaplessPlayback: gaplessPlayback,
      isAntiAlias: isAntiAlias,
      package: package,
      filterQuality: filterQuality,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
    );
  }

  ImageProvider provider({
    AssetBundle? bundle,
    String? package,
  }) {
    return AssetImage(
      _assetName,
      bundle: bundle,
      package: package,
    );
  }

  String get path => _assetName;

  String get keyName => _assetName;
}

class AssetGenImageAnimation {
  const AssetGenImageAnimation({
    required this.isAnimation,
    required this.duration,
    required this.frames,
  });

  final bool isAnimation;
  final Duration duration;
  final int frames;
}

class SvgGenImage {
  const SvgGenImage(
    this._assetName, {
    this.size,
    this.flavors = const {},
  }) : _isVecFormat = false;

  const SvgGenImage.vec(
    this._assetName, {
    this.size,
    this.flavors = const {},
  }) : _isVecFormat = true;

  final String _assetName;
  final Size? size;
  final Set<String> flavors;
  final bool _isVecFormat;

  _svg.SvgPicture svg({
    Key? key,
    bool matchTextDirection = false,
    AssetBundle? bundle,
    String? package,
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    AlignmentGeometry alignment = Alignment.center,
    bool allowDrawingOutsideViewBox = false,
    WidgetBuilder? placeholderBuilder,
    String? semanticsLabel,
    bool excludeFromSemantics = false,
    _svg.SvgTheme? theme,
    _svg.ColorMapper? colorMapper,
    ColorFilter? colorFilter,
    Clip clipBehavior = Clip.hardEdge,
    @deprecated Color? color,
    @deprecated BlendMode colorBlendMode = BlendMode.srcIn,
    @deprecated bool cacheColorFilter = false,
  }) {
    final _svg.BytesLoader loader;
    if (_isVecFormat) {
      loader = _vg.AssetBytesLoader(
        _assetName,
        assetBundle: bundle,
        packageName: package,
      );
    } else {
      loader = _svg.SvgAssetLoader(
        _assetName,
        assetBundle: bundle,
        packageName: package,
        theme: theme,
        colorMapper: colorMapper,
      );
    }
    return _svg.SvgPicture(
      loader,
      key: key,
      matchTextDirection: matchTextDirection,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      allowDrawingOutsideViewBox: allowDrawingOutsideViewBox,
      placeholderBuilder: placeholderBuilder,
      semanticsLabel: semanticsLabel,
      excludeFromSemantics: excludeFromSemantics,
      colorFilter: colorFilter ??
          (color == null ? null : ColorFilter.mode(color, colorBlendMode)),
      clipBehavior: clipBehavior,
      cacheColorFilter: cacheColorFilter,
    );
  }

  String get path => _assetName;

  String get keyName => _assetName;
}

class LottieGenImage {
  const LottieGenImage(
    this._assetName, {
    this.flavors = const {},
  });

  final String _assetName;
  final Set<String> flavors;

  _lottie.LottieBuilder lottie({
    Animation<double>? controller,
    bool? animate,
    _lottie.FrameRate? frameRate,
    bool? repeat,
    bool? reverse,
    _lottie.LottieDelegates? delegates,
    _lottie.LottieOptions? options,
    void Function(_lottie.LottieComposition)? onLoaded,
    _lottie.LottieImageProviderFactory? imageProviderFactory,
    Key? key,
    AssetBundle? bundle,
    Widget Function(
      BuildContext,
      Widget,
      _lottie.LottieComposition?,
    )? frameBuilder,
    ImageErrorWidgetBuilder? errorBuilder,
    double? width,
    double? height,
    BoxFit? fit,
    AlignmentGeometry? alignment,
    String? package,
    bool? addRepaintBoundary,
    FilterQuality? filterQuality,
    void Function(String)? onWarning,
    _lottie.LottieDecoder? decoder,
    _lottie.RenderCache? renderCache,
    bool? backgroundLoading,
  }) {
    return _lottie.Lottie.asset(
      _assetName,
      controller: controller,
      animate: animate,
      frameRate: frameRate,
      repeat: repeat,
      reverse: reverse,
      delegates: delegates,
      options: options,
      onLoaded: onLoaded,
      imageProviderFactory: imageProviderFactory,
      key: key,
      bundle: bundle,
      frameBuilder: frameBuilder,
      errorBuilder: errorBuilder,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      package: package,
      addRepaintBoundary: addRepaintBoundary,
      filterQuality: filterQuality,
      onWarning: onWarning,
      decoder: decoder,
      renderCache: renderCache,
      backgroundLoading: backgroundLoading,
    );
  }

  String get path => _assetName;

  String get keyName => _assetName;
}
