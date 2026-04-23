import 'package:image_picker/image_picker.dart';

import 'receipt_ocr.dart';

class ReceiptOcrImpl implements ReceiptOcr {
  @override
  Future<String> extractText(XFile imageFile) async {
    throw UnsupportedError(
      'Receipt OCR is not available in the web build yet.',
    );
  }
}
