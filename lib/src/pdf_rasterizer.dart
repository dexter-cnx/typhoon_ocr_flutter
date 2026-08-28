import 'dart:typed_data';

import 'package:printing/printing.dart';

/// Converts PDF bytes into an ordered stream of PNG page images.
///
/// Page images must be emitted in the same order as the source PDF. The
/// callback is injectable so tests and advanced consumers can replace the
/// platform PDF renderer when needed.
typedef PdfPageRasterizer = Stream<Uint8List> Function(
  Uint8List pdfBytes,
  double dpi,
);

/// Default PDF page rasterizer backed by the Flutter `printing` plugin.
///
/// Each page is emitted as PNG bytes in source-document order.
Stream<Uint8List> defaultPdfPageRasterizer(
  Uint8List pdfBytes,
  double dpi,
) async* {
  await for (final page in Printing.raster(pdfBytes, dpi: dpi)) {
    yield await page.toPng();
  }
}
