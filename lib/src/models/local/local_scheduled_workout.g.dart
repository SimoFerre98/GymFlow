// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_scheduled_workout.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetLocalScheduledWorkoutCollection on Isar {
  IsarCollection<LocalScheduledWorkout> get localScheduledWorkouts =>
      this.collection();
}

const LocalScheduledWorkoutSchema = CollectionSchema(
  name: r'LocalScheduledWorkout',
  id: -1687375391162016085,
  properties: {
    r'firestoreId': PropertySchema(
      id: 0,
      name: r'firestoreId',
      type: IsarType.string,
    ),
    r'isCompleted': PropertySchema(
      id: 1,
      name: r'isCompleted',
      type: IsarType.bool,
    ),
    r'scheduledDate': PropertySchema(
      id: 2,
      name: r'scheduledDate',
      type: IsarType.dateTime,
    ),
    r'userId': PropertySchema(
      id: 3,
      name: r'userId',
      type: IsarType.string,
    ),
    r'workoutName': PropertySchema(
      id: 4,
      name: r'workoutName',
      type: IsarType.string,
    ),
    r'workoutTemplateId': PropertySchema(
      id: 5,
      name: r'workoutTemplateId',
      type: IsarType.string,
    )
  },
  estimateSize: _localScheduledWorkoutEstimateSize,
  serialize: _localScheduledWorkoutSerialize,
  deserialize: _localScheduledWorkoutDeserialize,
  deserializeProp: _localScheduledWorkoutDeserializeProp,
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
  getId: _localScheduledWorkoutGetId,
  getLinks: _localScheduledWorkoutGetLinks,
  attach: _localScheduledWorkoutAttach,
  version: '3.1.0+1',
);

int _localScheduledWorkoutEstimateSize(
  LocalScheduledWorkout object,
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
  bytesCount += 3 + object.workoutName.length * 3;
  bytesCount += 3 + object.workoutTemplateId.length * 3;
  return bytesCount;
}

void _localScheduledWorkoutSerialize(
  LocalScheduledWorkout object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.firestoreId);
  writer.writeBool(offsets[1], object.isCompleted);
  writer.writeDateTime(offsets[2], object.scheduledDate);
  writer.writeString(offsets[3], object.userId);
  writer.writeString(offsets[4], object.workoutName);
  writer.writeString(offsets[5], object.workoutTemplateId);
}

LocalScheduledWorkout _localScheduledWorkoutDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = LocalScheduledWorkout();
  object.firestoreId = reader.readStringOrNull(offsets[0]);
  object.id = id;
  object.isCompleted = reader.readBool(offsets[1]);
  object.scheduledDate = reader.readDateTime(offsets[2]);
  object.userId = reader.readString(offsets[3]);
  object.workoutName = reader.readString(offsets[4]);
  object.workoutTemplateId = reader.readString(offsets[5]);
  return object;
}

P _localScheduledWorkoutDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readBool(offset)) as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _localScheduledWorkoutGetId(LocalScheduledWorkout object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _localScheduledWorkoutGetLinks(
    LocalScheduledWorkout object) {
  return [];
}

void _localScheduledWorkoutAttach(
    IsarCollection<dynamic> col, Id id, LocalScheduledWorkout object) {
  object.id = id;
}

extension LocalScheduledWorkoutByIndex
    on IsarCollection<LocalScheduledWorkout> {
  Future<LocalScheduledWorkout?> getByFirestoreId(String? firestoreId) {
    return getByIndex(r'firestoreId', [firestoreId]);
  }

  LocalScheduledWorkout? getByFirestoreIdSync(String? firestoreId) {
    return getByIndexSync(r'firestoreId', [firestoreId]);
  }

  Future<bool> deleteByFirestoreId(String? firestoreId) {
    return deleteByIndex(r'firestoreId', [firestoreId]);
  }

  bool deleteByFirestoreIdSync(String? firestoreId) {
    return deleteByIndexSync(r'firestoreId', [firestoreId]);
  }

  Future<List<LocalScheduledWorkout?>> getAllByFirestoreId(
      List<String?> firestoreIdValues) {
    final values = firestoreIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'firestoreId', values);
  }

  List<LocalScheduledWorkout?> getAllByFirestoreIdSync(
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

  Future<Id> putByFirestoreId(LocalScheduledWorkout object) {
    return putByIndex(r'firestoreId', object);
  }

  Id putByFirestoreIdSync(LocalScheduledWorkout object,
      {bool saveLinks = true}) {
    return putByIndexSync(r'firestoreId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByFirestoreId(List<LocalScheduledWorkout> objects) {
    return putAllByIndex(r'firestoreId', objects);
  }

  List<Id> putAllByFirestoreIdSync(List<LocalScheduledWorkout> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'firestoreId', objects, saveLinks: saveLinks);
  }
}

extension LocalScheduledWorkoutQueryWhereSort
    on QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout, QWhere> {
  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout, QAfterWhere>
      anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension LocalScheduledWorkoutQueryWhere on QueryBuilder<LocalScheduledWorkout,
    LocalScheduledWorkout, QWhereClause> {
  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout, QAfterWhereClause>
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

  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout, QAfterWhereClause>
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

  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout, QAfterWhereClause>
      firestoreIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'firestoreId',
        value: [null],
      ));
    });
  }

  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout, QAfterWhereClause>
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

  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout, QAfterWhereClause>
      firestoreIdEqualTo(String? firestoreId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'firestoreId',
        value: [firestoreId],
      ));
    });
  }

  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout, QAfterWhereClause>
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

  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout, QAfterWhereClause>
      userIdEqualTo(String userId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'userId',
        value: [userId],
      ));
    });
  }

  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout, QAfterWhereClause>
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

extension LocalScheduledWorkoutQueryFilter on QueryBuilder<
    LocalScheduledWorkout, LocalScheduledWorkout, QFilterCondition> {
  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout,
      QAfterFilterCondition> firestoreIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'firestoreId',
      ));
    });
  }

  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout,
      QAfterFilterCondition> firestoreIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'firestoreId',
      ));
    });
  }

  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout,
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

  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout,
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

  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout,
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

  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout,
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

  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout,
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

  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout,
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

  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout,
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

  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout,
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

  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout,
      QAfterFilterCondition> firestoreIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'firestoreId',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout,
      QAfterFilterCondition> firestoreIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'firestoreId',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout,
      QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout,
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

  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout,
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

  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout,
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

  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout,
      QAfterFilterCondition> isCompletedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isCompleted',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout,
      QAfterFilterCondition> scheduledDateEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'scheduledDate',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout,
      QAfterFilterCondition> scheduledDateGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'scheduledDate',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout,
      QAfterFilterCondition> scheduledDateLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'scheduledDate',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout,
      QAfterFilterCondition> scheduledDateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'scheduledDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout,
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

  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout,
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

  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout,
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

  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout,
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

  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout,
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

  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout,
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

  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout,
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

  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout,
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

  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout,
      QAfterFilterCondition> userIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userId',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout,
      QAfterFilterCondition> userIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'userId',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout,
      QAfterFilterCondition> workoutNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'workoutName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout,
      QAfterFilterCondition> workoutNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'workoutName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout,
      QAfterFilterCondition> workoutNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'workoutName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout,
      QAfterFilterCondition> workoutNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'workoutName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout,
      QAfterFilterCondition> workoutNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'workoutName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout,
      QAfterFilterCondition> workoutNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'workoutName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout,
          QAfterFilterCondition>
      workoutNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'workoutName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout,
          QAfterFilterCondition>
      workoutNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'workoutName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout,
      QAfterFilterCondition> workoutNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'workoutName',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout,
      QAfterFilterCondition> workoutNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'workoutName',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout,
      QAfterFilterCondition> workoutTemplateIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'workoutTemplateId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout,
      QAfterFilterCondition> workoutTemplateIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'workoutTemplateId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout,
      QAfterFilterCondition> workoutTemplateIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'workoutTemplateId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout,
      QAfterFilterCondition> workoutTemplateIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'workoutTemplateId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout,
      QAfterFilterCondition> workoutTemplateIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'workoutTemplateId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout,
      QAfterFilterCondition> workoutTemplateIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'workoutTemplateId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout,
          QAfterFilterCondition>
      workoutTemplateIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'workoutTemplateId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout,
          QAfterFilterCondition>
      workoutTemplateIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'workoutTemplateId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout,
      QAfterFilterCondition> workoutTemplateIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'workoutTemplateId',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout,
      QAfterFilterCondition> workoutTemplateIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'workoutTemplateId',
        value: '',
      ));
    });
  }
}

extension LocalScheduledWorkoutQueryObject on QueryBuilder<
    LocalScheduledWorkout, LocalScheduledWorkout, QFilterCondition> {}

extension LocalScheduledWorkoutQueryLinks on QueryBuilder<LocalScheduledWorkout,
    LocalScheduledWorkout, QFilterCondition> {}

extension LocalScheduledWorkoutQuerySortBy
    on QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout, QSortBy> {
  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout, QAfterSortBy>
      sortByFirestoreId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'firestoreId', Sort.asc);
    });
  }

  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout, QAfterSortBy>
      sortByFirestoreIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'firestoreId', Sort.desc);
    });
  }

  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout, QAfterSortBy>
      sortByIsCompleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCompleted', Sort.asc);
    });
  }

  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout, QAfterSortBy>
      sortByIsCompletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCompleted', Sort.desc);
    });
  }

  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout, QAfterSortBy>
      sortByScheduledDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scheduledDate', Sort.asc);
    });
  }

  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout, QAfterSortBy>
      sortByScheduledDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scheduledDate', Sort.desc);
    });
  }

  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout, QAfterSortBy>
      sortByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.asc);
    });
  }

  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout, QAfterSortBy>
      sortByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.desc);
    });
  }

  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout, QAfterSortBy>
      sortByWorkoutName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'workoutName', Sort.asc);
    });
  }

  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout, QAfterSortBy>
      sortByWorkoutNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'workoutName', Sort.desc);
    });
  }

  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout, QAfterSortBy>
      sortByWorkoutTemplateId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'workoutTemplateId', Sort.asc);
    });
  }

  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout, QAfterSortBy>
      sortByWorkoutTemplateIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'workoutTemplateId', Sort.desc);
    });
  }
}

extension LocalScheduledWorkoutQuerySortThenBy
    on QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout, QSortThenBy> {
  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout, QAfterSortBy>
      thenByFirestoreId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'firestoreId', Sort.asc);
    });
  }

  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout, QAfterSortBy>
      thenByFirestoreIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'firestoreId', Sort.desc);
    });
  }

  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout, QAfterSortBy>
      thenByIsCompleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCompleted', Sort.asc);
    });
  }

  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout, QAfterSortBy>
      thenByIsCompletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCompleted', Sort.desc);
    });
  }

  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout, QAfterSortBy>
      thenByScheduledDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scheduledDate', Sort.asc);
    });
  }

  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout, QAfterSortBy>
      thenByScheduledDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scheduledDate', Sort.desc);
    });
  }

  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout, QAfterSortBy>
      thenByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.asc);
    });
  }

  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout, QAfterSortBy>
      thenByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.desc);
    });
  }

  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout, QAfterSortBy>
      thenByWorkoutName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'workoutName', Sort.asc);
    });
  }

  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout, QAfterSortBy>
      thenByWorkoutNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'workoutName', Sort.desc);
    });
  }

  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout, QAfterSortBy>
      thenByWorkoutTemplateId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'workoutTemplateId', Sort.asc);
    });
  }

  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout, QAfterSortBy>
      thenByWorkoutTemplateIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'workoutTemplateId', Sort.desc);
    });
  }
}

extension LocalScheduledWorkoutQueryWhereDistinct
    on QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout, QDistinct> {
  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout, QDistinct>
      distinctByFirestoreId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'firestoreId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout, QDistinct>
      distinctByIsCompleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isCompleted');
    });
  }

  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout, QDistinct>
      distinctByScheduledDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'scheduledDate');
    });
  }

  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout, QDistinct>
      distinctByUserId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'userId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout, QDistinct>
      distinctByWorkoutName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'workoutName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalScheduledWorkout, LocalScheduledWorkout, QDistinct>
      distinctByWorkoutTemplateId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'workoutTemplateId',
          caseSensitive: caseSensitive);
    });
  }
}

extension LocalScheduledWorkoutQueryProperty on QueryBuilder<
    LocalScheduledWorkout, LocalScheduledWorkout, QQueryProperty> {
  QueryBuilder<LocalScheduledWorkout, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<LocalScheduledWorkout, String?, QQueryOperations>
      firestoreIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'firestoreId');
    });
  }

  QueryBuilder<LocalScheduledWorkout, bool, QQueryOperations>
      isCompletedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isCompleted');
    });
  }

  QueryBuilder<LocalScheduledWorkout, DateTime, QQueryOperations>
      scheduledDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'scheduledDate');
    });
  }

  QueryBuilder<LocalScheduledWorkout, String, QQueryOperations>
      userIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'userId');
    });
  }

  QueryBuilder<LocalScheduledWorkout, String, QQueryOperations>
      workoutNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'workoutName');
    });
  }

  QueryBuilder<LocalScheduledWorkout, String, QQueryOperations>
      workoutTemplateIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'workoutTemplateId');
    });
  }
}
