import 'package:image_picker/image_picker.dart';

import 'receipt_ocr_mobile.dart' if (dart.library.html) 'receipt_ocr_web.dart';

abstract class ReceiptOcr {
  Future<String> extractText(XFile imageFile);
}

ReceiptOcr createReceiptOcr() => ReceiptOcrImpl();
