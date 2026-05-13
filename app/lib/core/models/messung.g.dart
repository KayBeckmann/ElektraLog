// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'messung.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetMessungCollection on Isar {
  IsarCollection<Messung> get messungs => this.collection();
}

const MessungSchema = CollectionSchema(
  name: r'Messung',
  id: 3261143891735855274,
  properties: {
    r'bemerkung': PropertySchema(
      id: 0,
      name: r'bemerkung',
      type: IsarType.string,
    ),
    r'ergebnis': PropertySchema(
      id: 1,
      name: r'ergebnis',
      type: IsarType.string,
    ),
    r'erstelltAm': PropertySchema(
      id: 2,
      name: r'erstelltAm',
      type: IsarType.dateTime,
    ),
    r'komponenteUuid': PropertySchema(
      id: 3,
      name: r'komponenteUuid',
      type: IsarType.string,
    ),
    r'messwertJson': PropertySchema(
      id: 4,
      name: r'messwertJson',
      type: IsarType.string,
    ),
    r'norm': PropertySchema(
      id: 5,
      name: r'norm',
      type: IsarType.string,
    ),
    r'prueferName': PropertySchema(
      id: 6,
      name: r'prueferName',
      type: IsarType.string,
    ),
    r'pruefungDatum': PropertySchema(
      id: 7,
      name: r'pruefungDatum',
      type: IsarType.dateTime,
    ),
    r'uuid': PropertySchema(
      id: 8,
      name: r'uuid',
      type: IsarType.string,
    )
  },
  estimateSize: _messungEstimateSize,
  serialize: _messungSerialize,
  deserialize: _messungDeserialize,
  deserializeProp: _messungDeserializeProp,
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
    r'komponenteUuid': IndexSchema(
      id: 971582836230083509,
      name: r'komponenteUuid',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'komponenteUuid',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _messungGetId,
  getLinks: _messungGetLinks,
  attach: _messungAttach,
  version: '3.1.0+1',
);

int _messungEstimateSize(
  Messung object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.bemerkung;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.ergebnis.length * 3;
  bytesCount += 3 + object.komponenteUuid.length * 3;
  {
    final value = object.messwertJson;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.norm.length * 3;
  {
    final value = object.prueferName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.uuid.length * 3;
  return bytesCount;
}

void _messungSerialize(
  Messung object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.bemerkung);
  writer.writeString(offsets[1], object.ergebnis);
  writer.writeDateTime(offsets[2], object.erstelltAm);
  writer.writeString(offsets[3], object.komponenteUuid);
  writer.writeString(offsets[4], object.messwertJson);
  writer.writeString(offsets[5], object.norm);
  writer.writeString(offsets[6], object.prueferName);
  writer.writeDateTime(offsets[7], object.pruefungDatum);
  writer.writeString(offsets[8], object.uuid);
}

Messung _messungDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Messung();
  object.bemerkung = reader.readStringOrNull(offsets[0]);
  object.ergebnis = reader.readString(offsets[1]);
  object.erstelltAm = reader.readDateTimeOrNull(offsets[2]);
  object.id = id;
  object.komponenteUuid = reader.readString(offsets[3]);
  object.messwertJson = reader.readStringOrNull(offsets[4]);
  object.norm = reader.readString(offsets[5]);
  object.prueferName = reader.readStringOrNull(offsets[6]);
  object.pruefungDatum = reader.readDateTime(offsets[7]);
  object.uuid = reader.readString(offsets[8]);
  return object;
}

P _messungDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readDateTime(offset)) as P;
    case 8:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _messungGetId(Messung object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _messungGetLinks(Messung object) {
  return [];
}

void _messungAttach(IsarCollection<dynamic> col, Id id, Messung object) {
  object.id = id;
}

extension MessungByIndex on IsarCollection<Messung> {
  Future<Messung?> getByUuid(String uuid) {
    return getByIndex(r'uuid', [uuid]);
  }

  Messung? getByUuidSync(String uuid) {
    return getByIndexSync(r'uuid', [uuid]);
  }

  Future<bool> deleteByUuid(String uuid) {
    return deleteByIndex(r'uuid', [uuid]);
  }

  bool deleteByUuidSync(String uuid) {
    return deleteByIndexSync(r'uuid', [uuid]);
  }

  Future<List<Messung?>> getAllByUuid(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return getAllByIndex(r'uuid', values);
  }

  List<Messung?> getAllByUuidSync(List<String> uuidValues) {
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

  Future<Id> putByUuid(Messung object) {
    return putByIndex(r'uuid', object);
  }

  Id putByUuidSync(Messung object, {bool saveLinks = true}) {
    return putByIndexSync(r'uuid', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByUuid(List<Messung> objects) {
    return putAllByIndex(r'uuid', objects);
  }

  List<Id> putAllByUuidSync(List<Messung> objects, {bool saveLinks = true}) {
    return putAllByIndexSync(r'uuid', objects, saveLinks: saveLinks);
  }
}

extension MessungQueryWhereSort on QueryBuilder<Messung, Messung, QWhere> {
  QueryBuilder<Messung, Messung, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension MessungQueryWhere on QueryBuilder<Messung, Messung, QWhereClause> {
  QueryBuilder<Messung, Messung, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<Messung, Messung, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<Messung, Messung, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Messung, Messung, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Messung, Messung, QAfterWhereClause> idBetween(
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

  QueryBuilder<Messung, Messung, QAfterWhereClause> uuidEqualTo(String uuid) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'uuid',
        value: [uuid],
      ));
    });
  }

  QueryBuilder<Messung, Messung, QAfterWhereClause> uuidNotEqualTo(
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

  QueryBuilder<Messung, Messung, QAfterWhereClause> komponenteUuidEqualTo(
      String komponenteUuid) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'komponenteUuid',
        value: [komponenteUuid],
      ));
    });
  }

  QueryBuilder<Messung, Messung, QAfterWhereClause> komponenteUuidNotEqualTo(
      String komponenteUuid) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'komponenteUuid',
              lower: [],
              upper: [komponenteUuid],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'komponenteUuid',
              lower: [komponenteUuid],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'komponenteUuid',
              lower: [komponenteUuid],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'komponenteUuid',
              lower: [],
              upper: [komponenteUuid],
              includeUpper: false,
            ));
      }
    });
  }
}

extension MessungQueryFilter
    on QueryBuilder<Messung, Messung, QFilterCondition> {
  QueryBuilder<Messung, Messung, QAfterFilterCondition> bemerkungIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'bemerkung',
      ));
    });
  }

  QueryBuilder<Messung, Messung, QAfterFilterCondition> bemerkungIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'bemerkung',
      ));
    });
  }

  QueryBuilder<Messung, Messung, QAfterFilterCondition> bemerkungEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'bemerkung',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Messung, Messung, QAfterFilterCondition> bemerkungGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'bemerkung',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Messung, Messung, QAfterFilterCondition> bemerkungLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'bemerkung',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Messung, Messung, QAfterFilterCondition> bemerkungBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'bemerkung',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Messung, Messung, QAfterFilterCondition> bemerkungStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'bemerkung',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Messung, Messung, QAfterFilterCondition> bemerkungEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'bemerkung',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Messung, Messung, QAfterFilterCondition> bemerkungContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'bemerkung',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Messung, Messung, QAfterFilterCondition> bemerkungMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'bemerkung',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Messung, Messung, QAfterFilterCondition> bemerkungIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'bemerkung',
        value: '',
      ));
    });
  }

  QueryBuilder<Messung, Messung, QAfterFilterCondition> bemerkungIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'bemerkung',
        value: '',
      ));
    });
  }

  QueryBuilder<Messung, Messung, QAfterFilterCondition> ergebnisEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ergebnis',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Messung, Messung, QAfterFilterCondition> ergebnisGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'ergebnis',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Messung, Messung, QAfterFilterCondition> ergebnisLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'ergebnis',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Messung, Messung, QAfterFilterCondition> ergebnisBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'ergebnis',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Messung, Messung, QAfterFilterCondition> ergebnisStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'ergebnis',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Messung, Messung, QAfterFilterCondition> ergebnisEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'ergebnis',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Messung, Messung, QAfterFilterCondition> ergebnisContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'ergebnis',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Messung, Messung, QAfterFilterCondition> ergebnisMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'ergebnis',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Messung, Messung, QAfterFilterCondition> ergebnisIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ergebnis',
        value: '',
      ));
    });
  }

  QueryBuilder<Messung, Messung, QAfterFilterCondition> ergebnisIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'ergebnis',
        value: '',
      ));
    });
  }

  QueryBuilder<Messung, Messung, QAfterFilterCondition> erstelltAmIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'erstelltAm',
      ));
    });
  }

  QueryBuilder<Messung, Messung, QAfterFilterCondition> erstelltAmIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'erstelltAm',
      ));
    });
  }

  QueryBuilder<Messung, Messung, QAfterFilterCondition> erstelltAmEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'erstelltAm',
        value: value,
      ));
    });
  }

  QueryBuilder<Messung, Messung, QAfterFilterCondition> erstelltAmGreaterThan(
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

  QueryBuilder<Messung, Messung, QAfterFilterCondition> erstelltAmLessThan(
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

  QueryBuilder<Messung, Messung, QAfterFilterCondition> erstelltAmBetween(
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

  QueryBuilder<Messung, Messung, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Messung, Messung, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<Messung, Messung, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<Messung, Messung, QAfterFilterCondition> idBetween(
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

  QueryBuilder<Messung, Messung, QAfterFilterCondition> komponenteUuidEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'komponenteUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Messung, Messung, QAfterFilterCondition>
      komponenteUuidGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'komponenteUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Messung, Messung, QAfterFilterCondition> komponenteUuidLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'komponenteUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Messung, Messung, QAfterFilterCondition> komponenteUuidBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'komponenteUuid',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Messung, Messung, QAfterFilterCondition>
      komponenteUuidStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'komponenteUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Messung, Messung, QAfterFilterCondition> komponenteUuidEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'komponenteUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Messung, Messung, QAfterFilterCondition> komponenteUuidContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'komponenteUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Messung, Messung, QAfterFilterCondition> komponenteUuidMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'komponenteUuid',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Messung, Messung, QAfterFilterCondition>
      komponenteUuidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'komponenteUuid',
        value: '',
      ));
    });
  }

  QueryBuilder<Messung, Messung, QAfterFilterCondition>
      komponenteUuidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'komponenteUuid',
        value: '',
      ));
    });
  }

  QueryBuilder<Messung, Messung, QAfterFilterCondition> messwertJsonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'messwertJson',
      ));
    });
  }

  QueryBuilder<Messung, Messung, QAfterFilterCondition>
      messwertJsonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'messwertJson',
      ));
    });
  }

  QueryBuilder<Messung, Messung, QAfterFilterCondition> messwertJsonEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'messwertJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Messung, Messung, QAfterFilterCondition> messwertJsonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'messwertJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Messung, Messung, QAfterFilterCondition> messwertJsonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'messwertJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Messung, Messung, QAfterFilterCondition> messwertJsonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'messwertJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Messung, Messung, QAfterFilterCondition> messwertJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'messwertJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Messung, Messung, QAfterFilterCondition> messwertJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'messwertJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Messung, Messung, QAfterFilterCondition> messwertJsonContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'messwertJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Messung, Messung, QAfterFilterCondition> messwertJsonMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'messwertJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Messung, Messung, QAfterFilterCondition> messwertJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'messwertJson',
        value: '',
      ));
    });
  }

  QueryBuilder<Messung, Messung, QAfterFilterCondition>
      messwertJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'messwertJson',
        value: '',
      ));
    });
  }

  QueryBuilder<Messung, Messung, QAfterFilterCondition> normEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'norm',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Messung, Messung, QAfterFilterCondition> normGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'norm',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Messung, Messung, QAfterFilterCondition> normLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'norm',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Messung, Messung, QAfterFilterCondition> normBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'norm',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Messung, Messung, QAfterFilterCondition> normStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'norm',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Messung, Messung, QAfterFilterCondition> normEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'norm',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Messung, Messung, QAfterFilterCondition> normContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'norm',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Messung, Messung, QAfterFilterCondition> normMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'norm',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Messung, Messung, QAfterFilterCondition> normIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'norm',
        value: '',
      ));
    });
  }

  QueryBuilder<Messung, Messung, QAfterFilterCondition> normIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'norm',
        value: '',
      ));
    });
  }

  QueryBuilder<Messung, Messung, QAfterFilterCondition> prueferNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'prueferName',
      ));
    });
  }

  QueryBuilder<Messung, Messung, QAfterFilterCondition> prueferNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'prueferName',
      ));
    });
  }

  QueryBuilder<Messung, Messung, QAfterFilterCondition> prueferNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'prueferName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Messung, Messung, QAfterFilterCondition> prueferNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'prueferName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Messung, Messung, QAfterFilterCondition> prueferNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'prueferName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Messung, Messung, QAfterFilterCondition> prueferNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'prueferName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Messung, Messung, QAfterFilterCondition> prueferNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'prueferName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Messung, Messung, QAfterFilterCondition> prueferNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'prueferName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Messung, Messung, QAfterFilterCondition> prueferNameContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'prueferName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Messung, Messung, QAfterFilterCondition> prueferNameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'prueferName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Messung, Messung, QAfterFilterCondition> prueferNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'prueferName',
        value: '',
      ));
    });
  }

  QueryBuilder<Messung, Messung, QAfterFilterCondition>
      prueferNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'prueferName',
        value: '',
      ));
    });
  }

  QueryBuilder<Messung, Messung, QAfterFilterCondition> pruefungDatumEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'pruefungDatum',
        value: value,
      ));
    });
  }

  QueryBuilder<Messung, Messung, QAfterFilterCondition>
      pruefungDatumGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'pruefungDatum',
        value: value,
      ));
    });
  }

  QueryBuilder<Messung, Messung, QAfterFilterCondition> pruefungDatumLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'pruefungDatum',
        value: value,
      ));
    });
  }

  QueryBuilder<Messung, Messung, QAfterFilterCondition> pruefungDatumBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'pruefungDatum',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Messung, Messung, QAfterFilterCondition> uuidEqualTo(
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

  QueryBuilder<Messung, Messung, QAfterFilterCondition> uuidGreaterThan(
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

  QueryBuilder<Messung, Messung, QAfterFilterCondition> uuidLessThan(
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

  QueryBuilder<Messung, Messung, QAfterFilterCondition> uuidBetween(
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

  QueryBuilder<Messung, Messung, QAfterFilterCondition> uuidStartsWith(
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

  QueryBuilder<Messung, Messung, QAfterFilterCondition> uuidEndsWith(
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

  QueryBuilder<Messung, Messung, QAfterFilterCondition> uuidContains(
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

  QueryBuilder<Messung, Messung, QAfterFilterCondition> uuidMatches(
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

  QueryBuilder<Messung, Messung, QAfterFilterCondition> uuidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uuid',
        value: '',
      ));
    });
  }

  QueryBuilder<Messung, Messung, QAfterFilterCondition> uuidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'uuid',
        value: '',
      ));
    });
  }
}

extension MessungQueryObject
    on QueryBuilder<Messung, Messung, QFilterCondition> {}

extension MessungQueryLinks
    on QueryBuilder<Messung, Messung, QFilterCondition> {}

extension MessungQuerySortBy on QueryBuilder<Messung, Messung, QSortBy> {
  QueryBuilder<Messung, Messung, QAfterSortBy> sortByBemerkung() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bemerkung', Sort.asc);
    });
  }

  QueryBuilder<Messung, Messung, QAfterSortBy> sortByBemerkungDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bemerkung', Sort.desc);
    });
  }

  QueryBuilder<Messung, Messung, QAfterSortBy> sortByErgebnis() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ergebnis', Sort.asc);
    });
  }

  QueryBuilder<Messung, Messung, QAfterSortBy> sortByErgebnisDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ergebnis', Sort.desc);
    });
  }

  QueryBuilder<Messung, Messung, QAfterSortBy> sortByErstelltAm() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'erstelltAm', Sort.asc);
    });
  }

  QueryBuilder<Messung, Messung, QAfterSortBy> sortByErstelltAmDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'erstelltAm', Sort.desc);
    });
  }

  QueryBuilder<Messung, Messung, QAfterSortBy> sortByKomponenteUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'komponenteUuid', Sort.asc);
    });
  }

  QueryBuilder<Messung, Messung, QAfterSortBy> sortByKomponenteUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'komponenteUuid', Sort.desc);
    });
  }

  QueryBuilder<Messung, Messung, QAfterSortBy> sortByMesswertJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'messwertJson', Sort.asc);
    });
  }

  QueryBuilder<Messung, Messung, QAfterSortBy> sortByMesswertJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'messwertJson', Sort.desc);
    });
  }

  QueryBuilder<Messung, Messung, QAfterSortBy> sortByNorm() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'norm', Sort.asc);
    });
  }

  QueryBuilder<Messung, Messung, QAfterSortBy> sortByNormDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'norm', Sort.desc);
    });
  }

  QueryBuilder<Messung, Messung, QAfterSortBy> sortByPrueferName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'prueferName', Sort.asc);
    });
  }

  QueryBuilder<Messung, Messung, QAfterSortBy> sortByPrueferNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'prueferName', Sort.desc);
    });
  }

  QueryBuilder<Messung, Messung, QAfterSortBy> sortByPruefungDatum() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pruefungDatum', Sort.asc);
    });
  }

  QueryBuilder<Messung, Messung, QAfterSortBy> sortByPruefungDatumDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pruefungDatum', Sort.desc);
    });
  }

  QueryBuilder<Messung, Messung, QAfterSortBy> sortByUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.asc);
    });
  }

  QueryBuilder<Messung, Messung, QAfterSortBy> sortByUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.desc);
    });
  }
}

extension MessungQuerySortThenBy
    on QueryBuilder<Messung, Messung, QSortThenBy> {
  QueryBuilder<Messung, Messung, QAfterSortBy> thenByBemerkung() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bemerkung', Sort.asc);
    });
  }

  QueryBuilder<Messung, Messung, QAfterSortBy> thenByBemerkungDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bemerkung', Sort.desc);
    });
  }

  QueryBuilder<Messung, Messung, QAfterSortBy> thenByErgebnis() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ergebnis', Sort.asc);
    });
  }

  QueryBuilder<Messung, Messung, QAfterSortBy> thenByErgebnisDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ergebnis', Sort.desc);
    });
  }

  QueryBuilder<Messung, Messung, QAfterSortBy> thenByErstelltAm() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'erstelltAm', Sort.asc);
    });
  }

  QueryBuilder<Messung, Messung, QAfterSortBy> thenByErstelltAmDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'erstelltAm', Sort.desc);
    });
  }

  QueryBuilder<Messung, Messung, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Messung, Messung, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Messung, Messung, QAfterSortBy> thenByKomponenteUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'komponenteUuid', Sort.asc);
    });
  }

  QueryBuilder<Messung, Messung, QAfterSortBy> thenByKomponenteUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'komponenteUuid', Sort.desc);
    });
  }

  QueryBuilder<Messung, Messung, QAfterSortBy> thenByMesswertJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'messwertJson', Sort.asc);
    });
  }

  QueryBuilder<Messung, Messung, QAfterSortBy> thenByMesswertJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'messwertJson', Sort.desc);
    });
  }

  QueryBuilder<Messung, Messung, QAfterSortBy> thenByNorm() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'norm', Sort.asc);
    });
  }

  QueryBuilder<Messung, Messung, QAfterSortBy> thenByNormDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'norm', Sort.desc);
    });
  }

  QueryBuilder<Messung, Messung, QAfterSortBy> thenByPrueferName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'prueferName', Sort.asc);
    });
  }

  QueryBuilder<Messung, Messung, QAfterSortBy> thenByPrueferNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'prueferName', Sort.desc);
    });
  }

  QueryBuilder<Messung, Messung, QAfterSortBy> thenByPruefungDatum() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pruefungDatum', Sort.asc);
    });
  }

  QueryBuilder<Messung, Messung, QAfterSortBy> thenByPruefungDatumDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pruefungDatum', Sort.desc);
    });
  }

  QueryBuilder<Messung, Messung, QAfterSortBy> thenByUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.asc);
    });
  }

  QueryBuilder<Messung, Messung, QAfterSortBy> thenByUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.desc);
    });
  }
}

extension MessungQueryWhereDistinct
    on QueryBuilder<Messung, Messung, QDistinct> {
  QueryBuilder<Messung, Messung, QDistinct> distinctByBemerkung(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'bemerkung', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Messung, Messung, QDistinct> distinctByErgebnis(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ergebnis', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Messung, Messung, QDistinct> distinctByErstelltAm() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'erstelltAm');
    });
  }

  QueryBuilder<Messung, Messung, QDistinct> distinctByKomponenteUuid(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'komponenteUuid',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Messung, Messung, QDistinct> distinctByMesswertJson(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'messwertJson', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Messung, Messung, QDistinct> distinctByNorm(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'norm', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Messung, Messung, QDistinct> distinctByPrueferName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'prueferName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Messung, Messung, QDistinct> distinctByPruefungDatum() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'pruefungDatum');
    });
  }

  QueryBuilder<Messung, Messung, QDistinct> distinctByUuid(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'uuid', caseSensitive: caseSensitive);
    });
  }
}

extension MessungQueryProperty
    on QueryBuilder<Messung, Messung, QQueryProperty> {
  QueryBuilder<Messung, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Messung, String?, QQueryOperations> bemerkungProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'bemerkung');
    });
  }

  QueryBuilder<Messung, String, QQueryOperations> ergebnisProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ergebnis');
    });
  }

  QueryBuilder<Messung, DateTime?, QQueryOperations> erstelltAmProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'erstelltAm');
    });
  }

  QueryBuilder<Messung, String, QQueryOperations> komponenteUuidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'komponenteUuid');
    });
  }

  QueryBuilder<Messung, String?, QQueryOperations> messwertJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'messwertJson');
    });
  }

  QueryBuilder<Messung, String, QQueryOperations> normProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'norm');
    });
  }

  QueryBuilder<Messung, String?, QQueryOperations> prueferNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'prueferName');
    });
  }

  QueryBuilder<Messung, DateTime, QQueryOperations> pruefungDatumProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'pruefungDatum');
    });
  }

  QueryBuilder<Messung, String, QQueryOperations> uuidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'uuid');
    });
  }
}
