import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import 'receipt_ocr.dart';

class ReceiptOcrImpl implements ReceiptOcr {
  @override
  Future<String> extractText(XFile imageFile) async {
    final recognizer = TextRecognizer();
    try {
      final inputImage = InputImage.fromFilePath(imageFile.path);
      final recognizedText = await recognizer.processImage(inputImage);
      return recognizedText.text;
    } finally {
      await recognizer.close();
    }
  }
}
