import 'dart:convert';

import 'package:digital_legacy_weaver/features/intent_builder/intent_builder_model.dart';

String buildIntentDocumentSignature(IntentDocumentModel document) {
  return jsonEncode(document.toMap());
}
