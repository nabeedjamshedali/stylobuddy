/// Encodes/decodes between plain Dart values and the Firestore REST API's
/// typed `Value` JSON shape (`{"stringValue": ...}`, `{"integerValue": ...}`,
/// etc.) — the wire format `firestore.rules`' `is string`/`is int`/`is list`/
/// etc. checks actually see (F22_A17/A23/A30/A42 all depend on the rules
/// distinguishing `integerValue` from `doubleValue` from `stringValue`).
library;

/// A sentinel wrapping a raw already-encoded Firestore REST `Value` map, for
/// cases a plain Dart value can't express (e.g. a deliberately wrong-typed
/// `doubleValue` for an id, F22_A23's `id: 2` at a string-id doc).
class RawValue {
  const RawValue(this.value);
  final Map<String, dynamic> value;
}

/// A sentinel for an explicit Firestore `timestampValue`.
class TimestampValue {
  const TimestampValue(this.isoUtc);
  final String isoUtc;
}

Map<String, dynamic> encodeValue(Object? dartValue) {
  if (dartValue is RawValue) return dartValue.value;
  if (dartValue == null) return {'nullValue': null};
  if (dartValue is TimestampValue) {
    return {'timestampValue': dartValue.isoUtc};
  }
  if (dartValue is bool) return {'booleanValue': dartValue};
  if (dartValue is int) return {'integerValue': dartValue.toString()};
  if (dartValue is double) return {'doubleValue': dartValue};
  if (dartValue is String) return {'stringValue': dartValue};
  if (dartValue is List) {
    return {
      'arrayValue': {'values': dartValue.map(encodeValue).toList()},
    };
  }
  if (dartValue is Map) {
    return {
      'mapValue': {
        'fields': dartValue.map(
          (key, value) => MapEntry(key as String, encodeValue(value)),
        ),
      },
    };
  }
  throw ArgumentError('Cannot encode value of type ${dartValue.runtimeType}');
}

Map<String, dynamic> encodeFields(Map<String, Object?> fields) =>
    fields.map((key, value) => MapEntry(key, encodeValue(value)));

Object? decodeValue(Map<String, dynamic> value) {
  if (value.containsKey('nullValue')) return null;
  if (value.containsKey('booleanValue')) return value['booleanValue'];
  if (value.containsKey('integerValue')) {
    return int.parse(value['integerValue'] as String);
  }
  if (value.containsKey('doubleValue')) {
    return (value['doubleValue'] as num).toDouble();
  }
  if (value.containsKey('stringValue')) return value['stringValue'];
  if (value.containsKey('timestampValue')) return value['timestampValue'];
  if (value.containsKey('arrayValue')) {
    final values = (value['arrayValue'] as Map)['values'] as List? ?? [];
    return values
        .map((v) => decodeValue(v as Map<String, dynamic>))
        .toList();
  }
  if (value.containsKey('mapValue')) {
    final fields = (value['mapValue'] as Map)['fields'] as Map? ?? {};
    return fields.map(
      (key, v) =>
          MapEntry(key as String, decodeValue(v as Map<String, dynamic>)),
    );
  }
  throw ArgumentError('Cannot decode value: $value');
}

Map<String, Object?> decodeFields(Map<String, dynamic> document) {
  final fields = document['fields'] as Map<String, dynamic>? ?? {};
  return fields.map(
    (key, value) => MapEntry(key, decodeValue(value as Map<String, dynamic>)),
  );
}
