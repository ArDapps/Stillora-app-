import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:stillora_mobile/features/store_screenshots/store_screenshots_state.dart';

/// The renderer has one hard requirement it cannot get wrong: **no alpha
/// channel**. Both stores reject a screenshot that carries transparency, and a
/// letterboxed "fit" render is exactly where one would creep in.
void main() {
  /// A plain 4:3 source with a distinctive centre pixel.
  img.Image source({int width = 400, int height = 300}) {
    final image = img.Image(width: width, height: height, numChannels: 4);
    img.fill(image, color: img.ColorRgba8(255, 0, 0, 255));
    return image;
  }

  img.Image render(
    img.Image src,
    int w,
    int h, {
    ShotFit fit = ShotFit.fit,
    ShotBackground background = ShotBackground.black,
  }) => StoreScreenshotsController.renderTo(
    src,
    w,
    h,
    fit: fit,
    background: background,
  );

  test('renders exactly the requested size', () {
    final out = render(source(), 1320, 2868);
    expect(out.width, 1320);
    expect(out.height, 2868);
  });

  test('a fit render carries no alpha channel', () {
    // 4:3 into 9:19.5 is the worst case — most of the frame is background.
    final out = render(source(), 1320, 2868, fit: ShotFit.fit);
    expect(
      out.numChannels,
      3,
      reason: 'a 4-channel canvas would ship transparency to the store',
    );
    expect(out.hasAlpha, isFalse);
  });

  test('a fill render carries no alpha channel either', () {
    final out = render(source(), 1080, 1920, fit: ShotFit.fill);
    expect(out.numChannels, 3);
    expect(out.hasAlpha, isFalse);
  });

  test('fit letterboxes with the chosen background, opaque', () {
    final out = render(
      source(),
      1000,
      2000,
      fit: ShotFit.fit,
      background: ShotBackground.white,
    );
    // The top edge is bar, not image: a 4:3 source fitted into a tall frame
    // leaves white above and below.
    final top = out.getPixel(500, 2);
    expect(top.r, 255);
    expect(top.g, 255);
    expect(top.b, 255);
    expect(top.a, 255, reason: 'the bar must be opaque');
  });

  test('fill leaves no bars — every edge is image', () {
    final out = render(
      source(),
      1000,
      2000,
      fit: ShotFit.fill,
      background: ShotBackground.white,
    );
    // Cover-scaled and centre-cropped, so the background never shows.
    for (final point in [(500, 2), (500, 1997), (2, 1000), (997, 1000)]) {
      final pixel = out.getPixel(point.$1, point.$2);
      expect(
        pixel.r,
        255,
        reason: 'red source should reach the edge at $point',
      );
      expect(pixel.g, 0);
      expect(pixel.b, 0);
    }
  });

  test('the midnight background is the app’s own dark, not pure black', () {
    final out = render(
      source(),
      1000,
      2000,
      background: ShotBackground.midnight,
    );
    final top = out.getPixel(500, 2);
    expect((top.r, top.g, top.b), (11, 11, 20));
  });

  test('encodes to a PNG that decodes back at the requested size', () {
    final out = render(source(), 416, 496);
    final bytes = img.encodePng(out);
    final decoded = img.decodePng(bytes)!;
    expect(decoded.width, 416);
    expect(decoded.height, 496);
  });

  test(
    'a source larger than the target is scaled down, not cropped, on fit',
    () {
      final big = source(width: 4000, height: 3000);
      final out = render(big, 400, 300, fit: ShotFit.fit);
      expect(out.width, 400);
      expect(out.height, 300);
      // Same aspect ratio in and out, so the image fills it edge to edge.
      final corner = out.getPixel(1, 1);
      expect(corner.r, 255);
    },
  );

  test('an extreme aspect ratio still produces a valid canvas', () {
    // A panorama into an Apple Watch frame is degenerate but must not throw or
    // produce a zero-width draw.
    final pano = source(width: 4000, height: 200);
    final out = render(pano, 422, 514, fit: ShotFit.fit);
    expect(out.width, 422);
    expect(out.height, 514);
    expect(out.numChannels, 3);
  });
}
