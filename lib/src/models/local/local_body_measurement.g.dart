// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_body_measurement.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetLocalBodyMeasurementCollection on Isar {
  IsarCollection<LocalBodyMeasurement> get localBodyMeasurements =>
      this.collection();
}

const LocalBodyMeasurementSchema = CollectionSchema(
  name: r'LocalBodyMeasurement',
  id: 5622246335451040436,
  properties: {
    r'biceps': PropertySchema(
      id: 0,
      name: r'biceps',
      type: IsarType.double,
    ),
    r'bodyFatPercentage': PropertySchema(
      id: 1,
      name: r'bodyFatPercentage',
      type: IsarType.double,
    ),
    r'calves': PropertySchema(
      id: 2,
      name: r'calves',
      type: IsarType.double,
    ),
    r'chest': PropertySchema(
      id: 3,
      name: r'chest',
      type: IsarType.double,
    ),
    r'date': PropertySchema(
      id: 4,
      name: r'date',
      type: IsarType.dateTime,
    ),
    r'firestoreId': PropertySchema(
      id: 5,
      name: r'firestoreId',
      type: IsarType.string,
    ),
    r'height': PropertySchema(
      id: 6,
      name: r'height',
      type: IsarType.double,
    ),
    r'hips': PropertySchema(
      id: 7,
      name: r'hips',
      type: IsarType.double,
    ),
    r'neck': PropertySchema(
      id: 8,
      name: r'neck',
      type: IsarType.double,
    ),
    r'shoulders': PropertySchema(
      id: 9,
      name: r'shoulders',
      type: IsarType.double,
    ),
    r'thighs': PropertySchema(
      id: 10,
      name: r'thighs',
      type: IsarType.double,
    ),
    r'userId': PropertySchema(
      id: 11,
      name: r'userId',
      type: IsarType.string,
    ),
    r'waist': PropertySchema(
      id: 12,
      name: r'waist',
      type: IsarType.double,
    ),
    r'weight': PropertySchema(
      id: 13,
      name: r'weight',
      type: IsarType.double,
    )
  },
  estimateSize: _localBodyMeasurementEstimateSize,
  serialize: _localBodyMeasurementSerialize,
  deserialize: _localBodyMeasurementDeserialize,
  deserializeProp: _localBodyMeasurementDeserializeProp,
  idName: r'id',
  indexes: {
    r'firestoreId': IndexSchema(
      id: 1863077355534729001,
      name: r'firestoreId',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'firestoreId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'userId': IndexSchema(
      id: -2005826577402374815,
      name: r'userId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'userId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _localBodyMeasurementGetId,
  getLinks: _localBodyMeasurementGetLinks,
  attach: _localBodyMeasurementAttach,
  version: '3.1.0+1',
);

int _localBodyMeasurementEstimateSize(
  LocalBodyMeasurement object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.firestoreId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.userId.length * 3;
  return bytesCount;
}

void _localBodyMeasurementSerialize(
  LocalBodyMeasurement object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.biceps);
  writer.writeDouble(offsets[1], object.bodyFatPercentage);
  writer.writeDouble(offsets[2], object.calves);
  writer.writeDouble(offsets[3], object.chest);
  writer.writeDateTime(offsets[4], object.date);
  writer.writeString(offsets[5], object.firestoreId);
  writer.writeDouble(offsets[6], object.height);
  writer.writeDouble(offsets[7], object.hips);
  writer.writeDouble(offsets[8], object.neck);
  writer.writeDouble(offsets[9], object.shoulders);
  writer.writeDouble(offsets[10], object.thighs);
  writer.writeString(offsets[11], object.userId);
  writer.writeDouble(offsets[12], object.waist);
  writer.writeDouble(offsets[13], object.weight);
}

LocalBodyMeasurement _localBodyMeasurementDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = LocalBodyMeasurement();
  object.biceps = reader.readDoubleOrNull(offsets[0]);
  object.bodyFatPercentage = reader.readDoubleOrNull(offsets[1]);
  object.calves = reader.readDoubleOrNull(offsets[2]);
  object.chest = reader.readDoubleOrNull(offsets[3]);
  object.date = reader.readDateTime(offsets[4]);
  object.firestoreId = reader.readStringOrNull(offsets[5]);
  object.height = reader.readDoubleOrNull(offsets[6]);
  object.hips = reader.readDoubleOrNull(offsets[7]);
  object.id = id;
  object.neck = reader.readDoubleOrNull(offsets[8]);
  object.shoulders = reader.readDoubleOrNull(offsets[9]);
  object.thighs = reader.readDoubleOrNull(offsets[10]);
  object.userId = reader.readString(offsets[11]);
  object.waist = reader.readDoubleOrNull(offsets[12]);
  object.weight = reader.readDoubleOrNull(offsets[13]);
  return object;
}

P _localBodyMeasurementDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDoubleOrNull(offset)) as P;
    case 1:
      return (reader.readDoubleOrNull(offset)) as P;
    case 2:
      return (reader.readDoubleOrNull(offset)) as P;
    case 3:
      return (reader.readDoubleOrNull(offset)) as P;
    case 4:
      return (reader.readDateTime(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readDoubleOrNull(offset)) as P;
    case 7:
      return (reader.readDoubleOrNull(offset)) as P;
    case 8:
      return (reader.readDoubleOrNull(offset)) as P;
    case 9:
      return (reader.readDoubleOrNull(offset)) as P;
    case 10:
      return (reader.readDoubleOrNull(offset)) as P;
    case 11:
      return (reader.readString(offset)) as P;
    case 12:
      return (reader.readDoubleOrNull(offset)) as P;
    case 13:
      return (reader.readDoubleOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _localBodyMeasurementGetId(LocalBodyMeasurement object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _localBodyMeasurementGetLinks(
    LocalBodyMeasurement object) {
  return [];
}

void _localBodyMeasurementAttach(
    IsarCollection<dynamic> col, Id id, LocalBodyMeasurement object) {
  object.id = id;
}

extension LocalBodyMeasurementByIndex on IsarCollection<LocalBodyMeasurement> {
  Future<LocalBodyMeasurement?> getByFirestoreId(String? firestoreId) {
    return getByIndex(r'firestoreId', [firestoreId]);
  }

  LocalBodyMeasurement? getByFirestoreIdSync(String? firestoreId) {
    return getByIndexSync(r'firestoreId', [firestoreId]);
  }

  Future<bool> deleteByFirestoreId(String? firestoreId) {
    return deleteByIndex(r'firestoreId', [firestoreId]);
  }

  bool deleteByFirestoreIdSync(String? firestoreId) {
    return deleteByIndexSync(r'firestoreId', [firestoreId]);
  }

  Future<List<LocalBodyMeasurement?>> getAllByFirestoreId(
      List<String?> firestoreIdValues) {
    final values = firestoreIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'firestoreId', values);
  }

  List<LocalBodyMeasurement?> getAllByFirestoreIdSync(
      List<String?> firestoreIdValues) {
    final values = firestoreIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'firestoreId', values);
  }

  Future<int> deleteAllByFirestoreId(List<String?> firestoreIdValues) {
    final values = firestoreIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'firestoreId', values);
  }

  int deleteAllByFirestoreIdSync(List<String?> firestoreIdValues) {
    final values = firestoreIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'firestoreId', values);
  }

  Future<Id> putByFirestoreId(LocalBodyMeasurement object) {
    return putByIndex(r'firestoreId', object);
  }

  Id putByFirestoreIdSync(LocalBodyMeasurement object,
      {bool saveLinks = true}) {
    return putByIndexSync(r'firestoreId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByFirestoreId(List<LocalBodyMeasurement> objects) {
    return putAllByIndex(r'firestoreId', objects);
  }

  List<Id> putAllByFirestoreIdSync(List<LocalBodyMeasurement> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'firestoreId', objects, saveLinks: saveLinks);
  }
}

extension LocalBodyMeasurementQueryWhereSort
    on QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement, QWhere> {
  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement, QAfterWhere>
      anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension LocalBodyMeasurementQueryWhere
    on QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement, QWhereClause> {
  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement, QAfterWhereClause>
      idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement, QAfterWhereClause>
      idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement, QAfterWhereClause>
      firestoreIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'firestoreId',
        value: [null],
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement, QAfterWhereClause>
      firestoreIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'firestoreId',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement, QAfterWhereClause>
      firestoreIdEqualTo(String? firestoreId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'firestoreId',
        value: [firestoreId],
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement, QAfterWhereClause>
      firestoreIdNotEqualTo(String? firestoreId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'firestoreId',
              lower: [],
              upper: [firestoreId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'firestoreId',
              lower: [firestoreId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'firestoreId',
              lower: [firestoreId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'firestoreId',
              lower: [],
              upper: [firestoreId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement, QAfterWhereClause>
      userIdEqualTo(String userId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'userId',
        value: [userId],
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement, QAfterWhereClause>
      userIdNotEqualTo(String userId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'userId',
              lower: [],
              upper: [userId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'userId',
              lower: [userId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'userId',
              lower: [userId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'userId',
              lower: [],
              upper: [userId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension LocalBodyMeasurementQueryFilter on QueryBuilder<LocalBodyMeasurement,
    LocalBodyMeasurement, QFilterCondition> {
  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> bicepsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'biceps',
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> bicepsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'biceps',
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> bicepsEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'biceps',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> bicepsGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'biceps',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> bicepsLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'biceps',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> bicepsBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'biceps',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> bodyFatPercentageIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'bodyFatPercentage',
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> bodyFatPercentageIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'bodyFatPercentage',
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> bodyFatPercentageEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'bodyFatPercentage',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> bodyFatPercentageGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'bodyFatPercentage',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> bodyFatPercentageLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'bodyFatPercentage',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> bodyFatPercentageBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'bodyFatPercentage',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> calvesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'calves',
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> calvesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'calves',
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> calvesEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'calves',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> calvesGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'calves',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> calvesLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'calves',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> calvesBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'calves',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> chestIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'chest',
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> chestIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'chest',
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> chestEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'chest',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> chestGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'chest',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> chestLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'chest',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> chestBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'chest',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> dateEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> dateGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> dateLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> dateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'date',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> firestoreIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'firestoreId',
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> firestoreIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'firestoreId',
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> firestoreIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'firestoreId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> firestoreIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'firestoreId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> firestoreIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'firestoreId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> firestoreIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'firestoreId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> firestoreIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'firestoreId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> firestoreIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'firestoreId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
          QAfterFilterCondition>
      firestoreIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'firestoreId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
          QAfterFilterCondition>
      firestoreIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'firestoreId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> firestoreIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'firestoreId',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> firestoreIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'firestoreId',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> heightIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'height',
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> heightIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'height',
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> heightEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'height',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> heightGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'height',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> heightLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'height',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> heightBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'height',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> hipsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'hips',
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> hipsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'hips',
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> hipsEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'hips',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> hipsGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'hips',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> hipsLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'hips',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> hipsBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'hips',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> neckIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'neck',
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> neckIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'neck',
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> neckEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'neck',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> neckGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'neck',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> neckLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'neck',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> neckBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'neck',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> shouldersIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'shoulders',
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> shouldersIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'shoulders',
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> shouldersEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'shoulders',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> shouldersGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'shoulders',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> shouldersLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'shoulders',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> shouldersBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'shoulders',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> thighsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'thighs',
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> thighsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'thighs',
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> thighsEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'thighs',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> thighsGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'thighs',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> thighsLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'thighs',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> thighsBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'thighs',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> userIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> userIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> userIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> userIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'userId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> userIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> userIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
          QAfterFilterCondition>
      userIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
          QAfterFilterCondition>
      userIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'userId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> userIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userId',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> userIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'userId',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> waistIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'waist',
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> waistIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'waist',
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> waistEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'waist',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> waistGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'waist',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> waistLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'waist',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> waistBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'waist',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> weightIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'weight',
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> weightIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'weight',
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> weightEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'weight',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> weightGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'weight',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> weightLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'weight',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement,
      QAfterFilterCondition> weightBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'weight',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }
}

extension LocalBodyMeasurementQueryObject on QueryBuilder<LocalBodyMeasurement,
    LocalBodyMeasurement, QFilterCondition> {}

extension LocalBodyMeasurementQueryLinks on QueryBuilder<LocalBodyMeasurement,
    LocalBodyMeasurement, QFilterCondition> {}

extension LocalBodyMeasurementQuerySortBy
    on QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement, QSortBy> {
  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement, QAfterSortBy>
      sortByBiceps() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'biceps', Sort.asc);
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement, QAfterSortBy>
      sortByBicepsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'biceps', Sort.desc);
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement, QAfterSortBy>
      sortByBodyFatPercentage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bodyFatPercentage', Sort.asc);
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement, QAfterSortBy>
      sortByBodyFatPercentageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bodyFatPercentage', Sort.desc);
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement, QAfterSortBy>
      sortByCalves() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'calves', Sort.asc);
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement, QAfterSortBy>
      sortByCalvesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'calves', Sort.desc);
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement, QAfterSortBy>
      sortByChest() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chest', Sort.asc);
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement, QAfterSortBy>
      sortByChestDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chest', Sort.desc);
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement, QAfterSortBy>
      sortByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement, QAfterSortBy>
      sortByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement, QAfterSortBy>
      sortByFirestoreId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'firestoreId', Sort.asc);
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement, QAfterSortBy>
      sortByFirestoreIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'firestoreId', Sort.desc);
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement, QAfterSortBy>
      sortByHeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'height', Sort.asc);
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement, QAfterSortBy>
      sortByHeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'height', Sort.desc);
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement, QAfterSortBy>
      sortByHips() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hips', Sort.asc);
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement, QAfterSortBy>
      sortByHipsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hips', Sort.desc);
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement, QAfterSortBy>
      sortByNeck() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'neck', Sort.asc);
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement, QAfterSortBy>
      sortByNeckDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'neck', Sort.desc);
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement, QAfterSortBy>
      sortByShoulders() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shoulders', Sort.asc);
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement, QAfterSortBy>
      sortByShouldersDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shoulders', Sort.desc);
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement, QAfterSortBy>
      sortByThighs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'thighs', Sort.asc);
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement, QAfterSortBy>
      sortByThighsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'thighs', Sort.desc);
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement, QAfterSortBy>
      sortByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.asc);
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement, QAfterSortBy>
      sortByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.desc);
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement, QAfterSortBy>
      sortByWaist() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'waist', Sort.asc);
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement, QAfterSortBy>
      sortByWaistDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'waist', Sort.desc);
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement, QAfterSortBy>
      sortByWeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weight', Sort.asc);
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement, QAfterSortBy>
      sortByWeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weight', Sort.desc);
    });
  }
}

extension LocalBodyMeasurementQuerySortThenBy
    on QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement, QSortThenBy> {
  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement, QAfterSortBy>
      thenByBiceps() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'biceps', Sort.asc);
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement, QAfterSortBy>
      thenByBicepsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'biceps', Sort.desc);
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement, QAfterSortBy>
      thenByBodyFatPercentage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bodyFatPercentage', Sort.asc);
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement, QAfterSortBy>
      thenByBodyFatPercentageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bodyFatPercentage', Sort.desc);
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement, QAfterSortBy>
      thenByCalves() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'calves', Sort.asc);
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement, QAfterSortBy>
      thenByCalvesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'calves', Sort.desc);
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement, QAfterSortBy>
      thenByChest() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chest', Sort.asc);
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement, QAfterSortBy>
      thenByChestDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chest', Sort.desc);
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement, QAfterSortBy>
      thenByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement, QAfterSortBy>
      thenByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement, QAfterSortBy>
      thenByFirestoreId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'firestoreId', Sort.asc);
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement, QAfterSortBy>
      thenByFirestoreIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'firestoreId', Sort.desc);
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement, QAfterSortBy>
      thenByHeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'height', Sort.asc);
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement, QAfterSortBy>
      thenByHeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'height', Sort.desc);
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement, QAfterSortBy>
      thenByHips() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hips', Sort.asc);
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement, QAfterSortBy>
      thenByHipsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hips', Sort.desc);
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement, QAfterSortBy>
      thenByNeck() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'neck', Sort.asc);
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement, QAfterSortBy>
      thenByNeckDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'neck', Sort.desc);
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement, QAfterSortBy>
      thenByShoulders() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shoulders', Sort.asc);
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement, QAfterSortBy>
      thenByShouldersDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shoulders', Sort.desc);
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement, QAfterSortBy>
      thenByThighs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'thighs', Sort.asc);
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement, QAfterSortBy>
      thenByThighsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'thighs', Sort.desc);
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement, QAfterSortBy>
      thenByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.asc);
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement, QAfterSortBy>
      thenByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.desc);
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement, QAfterSortBy>
      thenByWaist() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'waist', Sort.asc);
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement, QAfterSortBy>
      thenByWaistDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'waist', Sort.desc);
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement, QAfterSortBy>
      thenByWeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weight', Sort.asc);
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement, QAfterSortBy>
      thenByWeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weight', Sort.desc);
    });
  }
}

extension LocalBodyMeasurementQueryWhereDistinct
    on QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement, QDistinct> {
  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement, QDistinct>
      distinctByBiceps() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'biceps');
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement, QDistinct>
      distinctByBodyFatPercentage() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'bodyFatPercentage');
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement, QDistinct>
      distinctByCalves() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'calves');
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement, QDistinct>
      distinctByChest() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'chest');
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement, QDistinct>
      distinctByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'date');
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement, QDistinct>
      distinctByFirestoreId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'firestoreId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement, QDistinct>
      distinctByHeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'height');
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement, QDistinct>
      distinctByHips() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'hips');
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement, QDistinct>
      distinctByNeck() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'neck');
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement, QDistinct>
      distinctByShoulders() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'shoulders');
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement, QDistinct>
      distinctByThighs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'thighs');
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement, QDistinct>
      distinctByUserId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'userId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement, QDistinct>
      distinctByWaist() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'waist');
    });
  }

  QueryBuilder<LocalBodyMeasurement, LocalBodyMeasurement, QDistinct>
      distinctByWeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'weight');
    });
  }
}

extension LocalBodyMeasurementQueryProperty on QueryBuilder<
    LocalBodyMeasurement, LocalBodyMeasurement, QQueryProperty> {
  QueryBuilder<LocalBodyMeasurement, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<LocalBodyMeasurement, double?, QQueryOperations>
      bicepsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'biceps');
    });
  }

  QueryBuilder<LocalBodyMeasurement, double?, QQueryOperations>
      bodyFatPercentageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'bodyFatPercentage');
    });
  }

  QueryBuilder<LocalBodyMeasurement, double?, QQueryOperations>
      calvesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'calves');
    });
  }

  QueryBuilder<LocalBodyMeasurement, double?, QQueryOperations>
      chestProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'chest');
    });
  }

  QueryBuilder<LocalBodyMeasurement, DateTime, QQueryOperations>
      dateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'date');
    });
  }

  QueryBuilder<LocalBodyMeasurement, String?, QQueryOperations>
      firestoreIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'firestoreId');
    });
  }

  QueryBuilder<LocalBodyMeasurement, double?, QQueryOperations>
      heightProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'height');
    });
  }

  QueryBuilder<LocalBodyMeasurement, double?, QQueryOperations> hipsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'hips');
    });
  }

  QueryBuilder<LocalBodyMeasurement, double?, QQueryOperations> neckProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'neck');
    });
  }

  QueryBuilder<LocalBodyMeasurement, double?, QQueryOperations>
      shouldersProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'shoulders');
    });
  }

  QueryBuilder<LocalBodyMeasurement, double?, QQueryOperations>
      thighsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'thighs');
    });
  }

  QueryBuilder<LocalBodyMeasurement, String, QQueryOperations>
      userIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'userId');
    });
  }

  QueryBuilder<LocalBodyMeasurement, double?, QQueryOperations>
      waistProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'waist');
    });
  }

  QueryBuilder<LocalBodyMeasurement, double?, QQueryOperations>
      weightProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'weight');
    });
  }
}
