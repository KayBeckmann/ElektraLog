// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'standort.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetStandortCollection on Isar {
  IsarCollection<Standort> get standorts => this.collection();
}

const StandortSchema = CollectionSchema(
  name: r'Standort',
  id: -7338208850494411400,
  properties: {
    r'bezeichnung': PropertySchema(
      id: 0,
      name: r'bezeichnung',
      type: IsarType.string,
    ),
    r'erstelltAm': PropertySchema(
      id: 1,
      name: r'erstelltAm',
      type: IsarType.dateTime,
    ),
    r'kundeUuid': PropertySchema(
      id: 2,
      name: r'kundeUuid',
      type: IsarType.string,
    ),
    r'ort': PropertySchema(
      id: 3,
      name: r'ort',
      type: IsarType.string,
    ),
    r'plz': PropertySchema(
      id: 4,
      name: r'plz',
      type: IsarType.string,
    ),
    r'strasse': PropertySchema(
      id: 5,
      name: r'strasse',
      type: IsarType.string,
    ),
    r'uuid': PropertySchema(
      id: 6,
      name: r'uuid',
      type: IsarType.string,
    )
  },
  estimateSize: _standortEstimateSize,
  serialize: _standortSerialize,
  deserialize: _standortDeserialize,
  deserializeProp: _standortDeserializeProp,
  idName: r'id',
  indexes: {
    r'uuid': IndexSchema(
      id: 2134397340427724972,
      name: r'uuid',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'uuid',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'kundeUuid': IndexSchema(
      id: -3101483414972879484,
      name: r'kundeUuid',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'kundeUuid',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _standortGetId,
  getLinks: _standortGetLinks,
  attach: _standortAttach,
  version: '3.1.0+1',
);

int _standortEstimateSize(
  Standort object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.bezeichnung.length * 3;
  bytesCount += 3 + object.kundeUuid.length * 3;
  {
    final value = object.ort;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.plz;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.strasse;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.uuid.length * 3;
  return bytesCount;
}

void _standortSerialize(
  Standort object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.bezeichnung);
  writer.writeDateTime(offsets[1], object.erstelltAm);
  writer.writeString(offsets[2], object.kundeUuid);
  writer.writeString(offsets[3], object.ort);
  writer.writeString(offsets[4], object.plz);
  writer.writeString(offsets[5], object.strasse);
  writer.writeString(offsets[6], object.uuid);
}

Standort _standortDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Standort();
  object.bezeichnung = reader.readString(offsets[0]);
  object.erstelltAm = reader.readDateTimeOrNull(offsets[1]);
  object.id = id;
  object.kundeUuid = reader.readString(offsets[2]);
  object.ort = reader.readStringOrNull(offsets[3]);
  object.plz = reader.readStringOrNull(offsets[4]);
  object.strasse = reader.readStringOrNull(offsets[5]);
  object.uuid = reader.readString(offsets[6]);
  return object;
}

P _standortDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _standortGetId(Standort object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _standortGetLinks(Standort object) {
  return [];
}

void _standortAttach(IsarCollection<dynamic> col, Id id, Standort object) {
  object.id = id;
}

extension StandortByIndex on IsarCollection<Standort> {
  Future<Standort?> getByUuid(String uuid) {
    return getByIndex(r'uuid', [uuid]);
  }

  Standort? getByUuidSync(String uuid) {
    return getByIndexSync(r'uuid', [uuid]);
  }

  Future<bool> deleteByUuid(String uuid) {
    return deleteByIndex(r'uuid', [uuid]);
  }

  bool deleteByUuidSync(String uuid) {
    return deleteByIndexSync(r'uuid', [uuid]);
  }

  Future<List<Standort?>> getAllByUuid(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return getAllByIndex(r'uuid', values);
  }

  List<Standort?> getAllByUuidSync(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'uuid', values);
  }

  Future<int> deleteAllByUuid(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'uuid', values);
  }

  int deleteAllByUuidSync(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'uuid', values);
  }

  Future<Id> putByUuid(Standort object) {
    return putByIndex(r'uuid', object);
  }

  Id putByUuidSync(Standort object, {bool saveLinks = true}) {
    return putByIndexSync(r'uuid', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByUuid(List<Standort> objects) {
    return putAllByIndex(r'uuid', objects);
  }

  List<Id> putAllByUuidSync(List<Standort> objects, {bool saveLinks = true}) {
    return putAllByIndexSync(r'uuid', objects, saveLinks: saveLinks);
  }
}

extension StandortQueryWhereSort on QueryBuilder<Standort, Standort, QWhere> {
  QueryBuilder<Standort, Standort, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension StandortQueryWhere on QueryBuilder<Standort, Standort, QWhereClause> {
  QueryBuilder<Standort, Standort, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<Standort, Standort, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<Standort, Standort, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Standort, Standort, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Standort, Standort, QAfterWhereClause> idBetween(
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

  QueryBuilder<Standort, Standort, QAfterWhereClause> uuidEqualTo(String uuid) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'uuid',
        value: [uuid],
      ));
    });
  }

  QueryBuilder<Standort, Standort, QAfterWhereClause> uuidNotEqualTo(
      String uuid) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uuid',
              lower: [],
              upper: [uuid],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uuid',
              lower: [uuid],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uuid',
              lower: [uuid],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uuid',
              lower: [],
              upper: [uuid],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Standort, Standort, QAfterWhereClause> kundeUuidEqualTo(
      String kundeUuid) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'kundeUuid',
        value: [kundeUuid],
      ));
    });
  }

  QueryBuilder<Standort, Standort, QAfterWhereClause> kundeUuidNotEqualTo(
      String kundeUuid) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'kundeUuid',
              lower: [],
              upper: [kundeUuid],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'kundeUuid',
              lower: [kundeUuid],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'kundeUuid',
              lower: [kundeUuid],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'kundeUuid',
              lower: [],
              upper: [kundeUuid],
              includeUpper: false,
            ));
      }
    });
  }
}

extension StandortQueryFilter
    on QueryBuilder<Standort, Standort, QFilterCondition> {
  QueryBuilder<Standort, Standort, QAfterFilterCondition> bezeichnungEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'bezeichnung',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Standort, Standort, QAfterFilterCondition>
      bezeichnungGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'bezeichnung',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Standort, Standort, QAfterFilterCondition> bezeichnungLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'bezeichnung',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Standort, Standort, QAfterFilterCondition> bezeichnungBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'bezeichnung',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Standort, Standort, QAfterFilterCondition> bezeichnungStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'bezeichnung',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Standort, Standort, QAfterFilterCondition> bezeichnungEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'bezeichnung',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Standort, Standort, QAfterFilterCondition> bezeichnungContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'bezeichnung',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Standort, Standort, QAfterFilterCondition> bezeichnungMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'bezeichnung',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Standort, Standort, QAfterFilterCondition> bezeichnungIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'bezeichnung',
        value: '',
      ));
    });
  }

  QueryBuilder<Standort, Standort, QAfterFilterCondition>
      bezeichnungIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'bezeichnung',
        value: '',
      ));
    });
  }

  QueryBuilder<Standort, Standort, QAfterFilterCondition> erstelltAmIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'erstelltAm',
      ));
    });
  }

  QueryBuilder<Standort, Standort, QAfterFilterCondition>
      erstelltAmIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'erstelltAm',
      ));
    });
  }

  QueryBuilder<Standort, Standort, QAfterFilterCondition> erstelltAmEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'erstelltAm',
        value: value,
      ));
    });
  }

  QueryBuilder<Standort, Standort, QAfterFilterCondition> erstelltAmGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'erstelltAm',
        value: value,
      ));
    });
  }

  QueryBuilder<Standort, Standort, QAfterFilterCondition> erstelltAmLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'erstelltAm',
        value: value,
      ));
    });
  }

  QueryBuilder<Standort, Standort, QAfterFilterCondition> erstelltAmBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'erstelltAm',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Standort, Standort, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Standort, Standort, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<Standort, Standort, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<Standort, Standort, QAfterFilterCondition> idBetween(
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

  QueryBuilder<Standort, Standort, QAfterFilterCondition> kundeUuidEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'kundeUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Standort, Standort, QAfterFilterCondition> kundeUuidGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'kundeUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Standort, Standort, QAfterFilterCondition> kundeUuidLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'kundeUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Standort, Standort, QAfterFilterCondition> kundeUuidBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'kundeUuid',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Standort, Standort, QAfterFilterCondition> kundeUuidStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'kundeUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Standort, Standort, QAfterFilterCondition> kundeUuidEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'kundeUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Standort, Standort, QAfterFilterCondition> kundeUuidContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'kundeUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Standort, Standort, QAfterFilterCondition> kundeUuidMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'kundeUuid',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Standort, Standort, QAfterFilterCondition> kundeUuidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'kundeUuid',
        value: '',
      ));
    });
  }

  QueryBuilder<Standort, Standort, QAfterFilterCondition>
      kundeUuidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'kundeUuid',
        value: '',
      ));
    });
  }

  QueryBuilder<Standort, Standort, QAfterFilterCondition> ortIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'ort',
      ));
    });
  }

  QueryBuilder<Standort, Standort, QAfterFilterCondition> ortIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'ort',
      ));
    });
  }

  QueryBuilder<Standort, Standort, QAfterFilterCondition> ortEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ort',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Standort, Standort, QAfterFilterCondition> ortGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'ort',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Standort, Standort, QAfterFilterCondition> ortLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'ort',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Standort, Standort, QAfterFilterCondition> ortBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'ort',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Standort, Standort, QAfterFilterCondition> ortStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'ort',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Standort, Standort, QAfterFilterCondition> ortEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'ort',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Standort, Standort, QAfterFilterCondition> ortContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'ort',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Standort, Standort, QAfterFilterCondition> ortMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'ort',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Standort, Standort, QAfterFilterCondition> ortIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ort',
        value: '',
      ));
    });
  }

  QueryBuilder<Standort, Standort, QAfterFilterCondition> ortIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'ort',
        value: '',
      ));
    });
  }

  QueryBuilder<Standort, Standort, QAfterFilterCondition> plzIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'plz',
      ));
    });
  }

  QueryBuilder<Standort, Standort, QAfterFilterCondition> plzIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'plz',
      ));
    });
  }

  QueryBuilder<Standort, Standort, QAfterFilterCondition> plzEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'plz',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Standort, Standort, QAfterFilterCondition> plzGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'plz',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Standort, Standort, QAfterFilterCondition> plzLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'plz',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Standort, Standort, QAfterFilterCondition> plzBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'plz',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Standort, Standort, QAfterFilterCondition> plzStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'plz',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Standort, Standort, QAfterFilterCondition> plzEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'plz',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Standort, Standort, QAfterFilterCondition> plzContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'plz',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Standort, Standort, QAfterFilterCondition> plzMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'plz',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Standort, Standort, QAfterFilterCondition> plzIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'plz',
        value: '',
      ));
    });
  }

  QueryBuilder<Standort, Standort, QAfterFilterCondition> plzIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'plz',
        value: '',
      ));
    });
  }

  QueryBuilder<Standort, Standort, QAfterFilterCondition> strasseIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'strasse',
      ));
    });
  }

  QueryBuilder<Standort, Standort, QAfterFilterCondition> strasseIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'strasse',
      ));
    });
  }

  QueryBuilder<Standort, Standort, QAfterFilterCondition> strasseEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'strasse',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Standort, Standort, QAfterFilterCondition> strasseGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'strasse',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Standort, Standort, QAfterFilterCondition> strasseLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'strasse',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Standort, Standort, QAfterFilterCondition> strasseBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'strasse',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Standort, Standort, QAfterFilterCondition> strasseStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'strasse',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Standort, Standort, QAfterFilterCondition> strasseEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'strasse',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Standort, Standort, QAfterFilterCondition> strasseContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'strasse',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Standort, Standort, QAfterFilterCondition> strasseMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'strasse',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Standort, Standort, QAfterFilterCondition> strasseIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'strasse',
        value: '',
      ));
    });
  }

  QueryBuilder<Standort, Standort, QAfterFilterCondition> strasseIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'strasse',
        value: '',
      ));
    });
  }

  QueryBuilder<Standort, Standort, QAfterFilterCondition> uuidEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Standort, Standort, QAfterFilterCondition> uuidGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Standort, Standort, QAfterFilterCondition> uuidLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Standort, Standort, QAfterFilterCondition> uuidBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'uuid',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Standort, Standort, QAfterFilterCondition> uuidStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Standort, Standort, QAfterFilterCondition> uuidEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Standort, Standort, QAfterFilterCondition> uuidContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Standort, Standort, QAfterFilterCondition> uuidMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'uuid',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Standort, Standort, QAfterFilterCondition> uuidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uuid',
        value: '',
      ));
    });
  }

  QueryBuilder<Standort, Standort, QAfterFilterCondition> uuidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'uuid',
        value: '',
      ));
    });
  }
}

extension StandortQueryObject
    on QueryBuilder<Standort, Standort, QFilterCondition> {}

extension StandortQueryLinks
    on QueryBuilder<Standort, Standort, QFilterCondition> {}

extension StandortQuerySortBy on QueryBuilder<Standort, Standort, QSortBy> {
  QueryBuilder<Standort, Standort, QAfterSortBy> sortByBezeichnung() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bezeichnung', Sort.asc);
    });
  }

  QueryBuilder<Standort, Standort, QAfterSortBy> sortByBezeichnungDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bezeichnung', Sort.desc);
    });
  }

  QueryBuilder<Standort, Standort, QAfterSortBy> sortByErstelltAm() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'erstelltAm', Sort.asc);
    });
  }

  QueryBuilder<Standort, Standort, QAfterSortBy> sortByErstelltAmDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'erstelltAm', Sort.desc);
    });
  }

  QueryBuilder<Standort, Standort, QAfterSortBy> sortByKundeUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kundeUuid', Sort.asc);
    });
  }

  QueryBuilder<Standort, Standort, QAfterSortBy> sortByKundeUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kundeUuid', Sort.desc);
    });
  }

  QueryBuilder<Standort, Standort, QAfterSortBy> sortByOrt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ort', Sort.asc);
    });
  }

  QueryBuilder<Standort, Standort, QAfterSortBy> sortByOrtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ort', Sort.desc);
    });
  }

  QueryBuilder<Standort, Standort, QAfterSortBy> sortByPlz() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'plz', Sort.asc);
    });
  }

  QueryBuilder<Standort, Standort, QAfterSortBy> sortByPlzDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'plz', Sort.desc);
    });
  }

  QueryBuilder<Standort, Standort, QAfterSortBy> sortByStrasse() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'strasse', Sort.asc);
    });
  }

  QueryBuilder<Standort, Standort, QAfterSortBy> sortByStrasseDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'strasse', Sort.desc);
    });
  }

  QueryBuilder<Standort, Standort, QAfterSortBy> sortByUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.asc);
    });
  }

  QueryBuilder<Standort, Standort, QAfterSortBy> sortByUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.desc);
    });
  }
}

extension StandortQuerySortThenBy
    on QueryBuilder<Standort, Standort, QSortThenBy> {
  QueryBuilder<Standort, Standort, QAfterSortBy> thenByBezeichnung() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bezeichnung', Sort.asc);
    });
  }

  QueryBuilder<Standort, Standort, QAfterSortBy> thenByBezeichnungDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bezeichnung', Sort.desc);
    });
  }

  QueryBuilder<Standort, Standort, QAfterSortBy> thenByErstelltAm() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'erstelltAm', Sort.asc);
    });
  }

  QueryBuilder<Standort, Standort, QAfterSortBy> thenByErstelltAmDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'erstelltAm', Sort.desc);
    });
  }

  QueryBuilder<Standort, Standort, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Standort, Standort, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Standort, Standort, QAfterSortBy> thenByKundeUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kundeUuid', Sort.asc);
    });
  }

  QueryBuilder<Standort, Standort, QAfterSortBy> thenByKundeUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kundeUuid', Sort.desc);
    });
  }

  QueryBuilder<Standort, Standort, QAfterSortBy> thenByOrt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ort', Sort.asc);
    });
  }

  QueryBuilder<Standort, Standort, QAfterSortBy> thenByOrtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ort', Sort.desc);
    });
  }

  QueryBuilder<Standort, Standort, QAfterSortBy> thenByPlz() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'plz', Sort.asc);
    });
  }

  QueryBuilder<Standort, Standort, QAfterSortBy> thenByPlzDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'plz', Sort.desc);
    });
  }

  QueryBuilder<Standort, Standort, QAfterSortBy> thenByStrasse() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'strasse', Sort.asc);
    });
  }

  QueryBuilder<Standort, Standort, QAfterSortBy> thenByStrasseDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'strasse', Sort.desc);
    });
  }

  QueryBuilder<Standort, Standort, QAfterSortBy> thenByUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.asc);
    });
  }

  QueryBuilder<Standort, Standort, QAfterSortBy> thenByUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.desc);
    });
  }
}

extension StandortQueryWhereDistinct
    on QueryBuilder<Standort, Standort, QDistinct> {
  QueryBuilder<Standort, Standort, QDistinct> distinctByBezeichnung(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'bezeichnung', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Standort, Standort, QDistinct> distinctByErstelltAm() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'erstelltAm');
    });
  }

  QueryBuilder<Standort, Standort, QDistinct> distinctByKundeUuid(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'kundeUuid', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Standort, Standort, QDistinct> distinctByOrt(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ort', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Standort, Standort, QDistinct> distinctByPlz(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'plz', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Standort, Standort, QDistinct> distinctByStrasse(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'strasse', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Standort, Standort, QDistinct> distinctByUuid(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'uuid', caseSensitive: caseSensitive);
    });
  }
}

extension StandortQueryProperty
    on QueryBuilder<Standort, Standort, QQueryProperty> {
  QueryBuilder<Standort, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Standort, String, QQueryOperations> bezeichnungProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'bezeichnung');
    });
  }

  QueryBuilder<Standort, DateTime?, QQueryOperations> erstelltAmProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'erstelltAm');
    });
  }

  QueryBuilder<Standort, String, QQueryOperations> kundeUuidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'kundeUuid');
    });
  }

  QueryBuilder<Standort, String?, QQueryOperations> ortProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ort');
    });
  }

  QueryBuilder<Standort, String?, QQueryOperations> plzProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'plz');
    });
  }

  QueryBuilder<Standort, String?, QQueryOperations> strasseProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'strasse');
    });
  }

  QueryBuilder<Standort, String, QQueryOperations> uuidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'uuid');
    });
  }
}
