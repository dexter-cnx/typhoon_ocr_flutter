import 'dart:io';

abstract class TyphoonProvider {
  Future<String> extractRaw({
    required File image,
    required String prompt,
    required String mode,
  });
}
