import 'dart:convert';

import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'home.dart';

extension FancyString on String {
  Uint8List get utf8Encoded => utf8.encode(this);
}

extension FancyBytes on List<int> {
  String get utf8Decoded => utf8.decode(this);
  String get hexEncoded => hex.encode(this);
  // String get base64Encoded => base64.encode(this);
  int at(int index, {int or}) => index < length ? this[index] : or;
}

extension DeviceUpdateStream on Stream<StatusUpdate> {
  Stream<StatusUpdate> forId(int id) => where((update) => update.id == id);
}
