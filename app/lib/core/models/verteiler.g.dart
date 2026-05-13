// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'verteiler.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetVerteilerCollection on Isar {
  IsarCollection<Verteiler> get verteilers => this.collection();
}

const VerteilerSchema = CollectionSchema(
  name: r'Verteiler',
  id: -2273114785259014486,
  properties: {
    r'anlagendatenJson': PropertySchema(
      id: 0,
      name: r'anlagendatenJson',
      type: IsarType.string,
    ),
    r'bemerkung': PropertySchema(
      id: 1,
      name: r'bemerkung',
      type: IsarType.string,
    ),
    r'bezeichnung': PropertySchema(
      id: 2,
      name: r'bezeichnung',
      type: IsarType.string,
    ),
    r'erstelltAm': PropertySchema(
      id: 3,
      name: r'erstelltAm',
      type: IsarType.dateTime,
    ),
    r'standortUuid': PropertySchema(
      id: 4,
      name: r'standortUuid',
      type: IsarType.string,
    ),
    r'uuid': PropertySchema(
      id: 5,
      name: r'uuid',
      type: IsarType.string,
    )
  },
  estimateSize: _verteilerEstimateSize,
  serialize: _verteilerSerialize,
  deserialize: _verteilerDeserialize,
  deserializeProp: _verteilerDeserializeProp,
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
    r'standortUuid': IndexSchema(
      id: 4869555325236517280,
      name: r'standortUuid',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'standortUuid',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _verteilerGetId,
  getLinks: _verteilerGetLinks,
  attach: _verteilerAttach,
  version: '3.1.0+1',
);

int _verteilerEstimateSize(
  Verteiler object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.anlagendatenJson;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.bemerkung;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.bezeichnung.length * 3;
  bytesCount += 3 + object.standortUuid.length * 3;
  bytesCount += 3 + object.uuid.length * 3;
  return bytesCount;
}

void _verteilerSerialize(
  Verteiler object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.anlagendatenJson);
  writer.writeString(offsets[1], object.bemerkung);
  writer.writeString(offsets[2], object.bezeichnung);
  writer.writeDateTime(offsets[3], object.erstelltAm);
  writer.writeString(offsets[4], object.standortUuid);
  writer.writeString(offsets[5], object.uuid);
}

Verteiler _verteilerDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Verteiler();
  object.anlagendatenJson = reader.readStringOrNull(offsets[0]);
  object.bemerkung = reader.readStringOrNull(offsets[1]);
  object.bezeichnung = reader.readString(offsets[2]);
  object.erstelltAm = reader.readDateTimeOrNull(offsets[3]);
  object.id = id;
  object.standortUuid = reader.readString(offsets[4]);
  object.uuid = reader.readString(offsets[5]);
  return object;
}

P _verteilerDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _verteilerGetId(Verteiler object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _verteilerGetLinks(Verteiler object) {
  return [];
}

void _verteilerAttach(IsarCollection<dynamic> col, Id id, Verteiler object) {
  object.id = id;
}

extension VerteilerByIndex on IsarCollection<Verteiler> {
  Future<Verteiler?> getByUuid(String uuid) {
    return getByIndex(r'uuid', [uuid]);
  }

  Verteiler? getByUuidSync(String uuid) {
    return getByIndexSync(r'uuid', [uuid]);
  }

  Future<bool> deleteByUuid(String uuid) {
    return deleteByIndex(r'uuid', [uuid]);
  }

  bool deleteByUuidSync(String uuid) {
    return deleteByIndexSync(r'uuid', [uuid]);
  }

  Future<List<Verteiler?>> getAllByUuid(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return getAllByIndex(r'uuid', values);
  }

  List<Verteiler?> getAllByUuidSync(List<String> uuidValues) {
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

  Future<Id> putByUuid(Verteiler object) {
    return putByIndex(r'uuid', object);
  }

  Id putByUuidSync(Verteiler object, {bool saveLinks = true}) {
    return putByIndexSync(r'uuid', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByUuid(List<Verteiler> objects) {
    return putAllByIndex(r'uuid', objects);
  }

  List<Id> putAllByUuidSync(List<Verteiler> objects, {bool saveLinks = true}) {
    return putAllByIndexSync(r'uuid', objects, saveLinks: saveLinks);
  }
}

extension VerteilerQueryWhereSort
    on QueryBuilder<Verteiler, Verteiler, QWhere> {
  QueryBuilder<Verteiler, Verteiler, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension VerteilerQueryWhere
    on QueryBuilder<Verteiler, Verteiler, QWhereClause> {
  QueryBuilder<Verteiler, Verteiler, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<Verteiler, Verteiler, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<Verteiler, Verteiler, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Verteiler, Verteiler, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Verteiler, Verteiler, QAfterWhereClause> idBetween(
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

  QueryBuilder<Verteiler, Verteiler, QAfterWhereClause> uuidEqualTo(
      String uuid) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'uuid',
        value: [uuid],
      ));
    });
  }

  QueryBuilder<Verteiler, Verteiler, QAfterWhereClause> uuidNotEqualTo(
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

  QueryBuilder<Verteiler, Verteiler, QAfterWhereClause> standortUuidEqualTo(
      String standortUuid) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'standortUuid',
        value: [standortUuid],
      ));
    });
  }

  QueryBuilder<Verteiler, Verteiler, QAfterWhereClause> standortUuidNotEqualTo(
      String standortUuid) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'standortUuid',
              lower: [],
              upper: [standortUuid],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'standortUuid',
              lower: [standortUuid],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'standortUuid',
              lower: [standortUuid],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'standortUuid',
              lower: [],
              upper: [standortUuid],
              includeUpper: false,
            ));
      }
    });
  }
}

extension VerteilerQueryFilter
    on QueryBuilder<Verteiler, Verteiler, QFilterCondition> {
  QueryBuilder<Verteiler, Verteiler, QAfterFilterCondition>
      anlagendatenJsonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'anlagendatenJson',
      ));
    });
  }

  QueryBuilder<Verteiler, Verteiler, QAfterFilterCondition>
      anlagendatenJsonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'anlagendatenJson',
      ));
    });
  }

  QueryBuilder<Verteiler, Verteiler, QAfterFilterCondition>
      anlagendatenJsonEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'anlagendatenJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Verteiler, Verteiler, QAfterFilterCondition>
      anlagendatenJsonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'anlagendatenJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Verteiler, Verteiler, QAfterFilterCondition>
      anlagendatenJsonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'anlagendatenJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Verteiler, Verteiler, QAfterFilterCondition>
      anlagendatenJsonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'anlagendatenJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Verteiler, Verteiler, QAfterFilterCondition>
      anlagendatenJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'anlagendatenJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Verteiler, Verteiler, QAfterFilterCondition>
      anlagendatenJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'anlagendatenJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Verteiler, Verteiler, QAfterFilterCondition>
      anlagendatenJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'anlagendatenJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Verteiler, Verteiler, QAfterFilterCondition>
      anlagendatenJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'anlagendatenJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Verteiler, Verteiler, QAfterFilterCondition>
      anlagendatenJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'anlagendatenJson',
        value: '',
      ));
    });
  }

  QueryBuilder<Verteiler, Verteiler, QAfterFilterCondition>
      anlagendatenJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'anlagendatenJson',
        value: '',
      ));
    });
  }

  QueryBuilder<Verteiler, Verteiler, QAfterFilterCondition> bemerkungIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'bemerkung',
      ));
    });
  }

  QueryBuilder<Verteiler, Verteiler, QAfterFilterCondition>
      bemerkungIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'bemerkung',
      ));
    });
  }

  QueryBuilder<Verteiler, Verteiler, QAfterFilterCondition> bemerkungEqualTo(
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

  QueryBuilder<Verteiler, Verteiler, QAfterFilterCondition>
      bemerkungGreaterThan(
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

  QueryBuilder<Verteiler, Verteiler, QAfterFilterCondition> bemerkungLessThan(
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

  QueryBuilder<Verteiler, Verteiler, QAfterFilterCondition> bemerkungBetween(
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

  QueryBuilder<Verteiler, Verteiler, QAfterFilterCondition> bemerkungStartsWith(
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

  QueryBuilder<Verteiler, Verteiler, QAfterFilterCondition> bemerkungEndsWith(
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

  QueryBuilder<Verteiler, Verteiler, QAfterFilterCondition> bemerkungContains(
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

  QueryBuilder<Verteiler, Verteiler, QAfterFilterCondition> bemerkungMatches(
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

  QueryBuilder<Verteiler, Verteiler, QAfterFilterCondition> bemerkungIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'bemerkung',
        value: '',
      ));
    });
  }

  QueryBuilder<Verteiler, Verteiler, QAfterFilterCondition>
      bemerkungIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'bemerkung',
        value: '',
      ));
    });
  }

  QueryBuilder<Verteiler, Verteiler, QAfterFilterCondition> bezeichnungEqualTo(
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

  QueryBuilder<Verteiler, Verteiler, QAfterFilterCondition>
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

  QueryBuilder<Verteiler, Verteiler, QAfterFilterCondition> bezeichnungLessThan(
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

  QueryBuilder<Verteiler, Verteiler, QAfterFilterCondition> bezeichnungBetween(
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

  QueryBuilder<Verteiler, Verteiler, QAfterFilterCondition>
      bezeichnungStartsWith(
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

  QueryBuilder<Verteiler, Verteiler, QAfterFilterCondition> bezeichnungEndsWith(
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

  QueryBuilder<Verteiler, Verteiler, QAfterFilterCondition> bezeichnungContains(
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

  QueryBuilder<Verteiler, Verteiler, QAfterFilterCondition> bezeichnungMatches(
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

  QueryBuilder<Verteiler, Verteiler, QAfterFilterCondition>
      bezeichnungIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'bezeichnung',
        value: '',
      ));
    });
  }

  QueryBuilder<Verteiler, Verteiler, QAfterFilterCondition>
      bezeichnungIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'bezeichnung',
        value: '',
      ));
    });
  }

  QueryBuilder<Verteiler, Verteiler, QAfterFilterCondition> erstelltAmIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'erstelltAm',
      ));
    });
  }

  QueryBuilder<Verteiler, Verteiler, QAfterFilterCondition>
      erstelltAmIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'erstelltAm',
      ));
    });
  }

  QueryBuilder<Verteiler, Verteiler, QAfterFilterCondition> erstelltAmEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'erstelltAm',
        value: value,
      ));
    });
  }

  QueryBuilder<Verteiler, Verteiler, QAfterFilterCondition>
      erstelltAmGreaterThan(
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

  QueryBuilder<Verteiler, Verteiler, QAfterFilterCondition> erstelltAmLessThan(
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

  QueryBuilder<Verteiler, Verteiler, QAfterFilterCondition> erstelltAmBetween(
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

  QueryBuilder<Verteiler, Verteiler, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Verteiler, Verteiler, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<Verteiler, Verteiler, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<Verteiler, Verteiler, QAfterFilterCondition> idBetween(
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

  QueryBuilder<Verteiler, Verteiler, QAfterFilterCondition> standortUuidEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'standortUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Verteiler, Verteiler, QAfterFilterCondition>
      standortUuidGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'standortUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Verteiler, Verteiler, QAfterFilterCondition>
      standortUuidLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'standortUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Verteiler, Verteiler, QAfterFilterCondition> standortUuidBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'standortUuid',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Verteiler, Verteiler, QAfterFilterCondition>
      standortUuidStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'standortUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Verteiler, Verteiler, QAfterFilterCondition>
      standortUuidEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'standortUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Verteiler, Verteiler, QAfterFilterCondition>
      standortUuidContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'standortUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Verteiler, Verteiler, QAfterFilterCondition> standortUuidMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'standortUuid',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Verteiler, Verteiler, QAfterFilterCondition>
      standortUuidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'standortUuid',
        value: '',
      ));
    });
  }

  QueryBuilder<Verteiler, Verteiler, QAfterFilterCondition>
      standortUuidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'standortUuid',
        value: '',
      ));
    });
  }

  QueryBuilder<Verteiler, Verteiler, QAfterFilterCondition> uuidEqualTo(
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

  QueryBuilder<Verteiler, Verteiler, QAfterFilterCondition> uuidGreaterThan(
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

  QueryBuilder<Verteiler, Verteiler, QAfterFilterCondition> uuidLessThan(
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

  QueryBuilder<Verteiler, Verteiler, QAfterFilterCondition> uuidBetween(
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

  QueryBuilder<Verteiler, Verteiler, QAfterFilterCondition> uuidStartsWith(
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

  QueryBuilder<Verteiler, Verteiler, QAfterFilterCondition> uuidEndsWith(
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

  QueryBuilder<Verteiler, Verteiler, QAfterFilterCondition> uuidContains(
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

  QueryBuilder<Verteiler, Verteiler, QAfterFilterCondition> uuidMatches(
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

  QueryBuilder<Verteiler, Verteiler, QAfterFilterCondition> uuidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uuid',
        value: '',
      ));
    });
  }

  QueryBuilder<Verteiler, Verteiler, QAfterFilterCondition> uuidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'uuid',
        value: '',
      ));
    });
  }
}

extension VerteilerQueryObject
    on QueryBuilder<Verteiler, Verteiler, QFilterCondition> {}

extension VerteilerQueryLinks
    on QueryBuilder<Verteiler, Verteiler, QFilterCondition> {}

extension VerteilerQuerySortBy on QueryBuilder<Verteiler, Verteiler, QSortBy> {
  QueryBuilder<Verteiler, Verteiler, QAfterSortBy> sortByAnlagendatenJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'anlagendatenJson', Sort.asc);
    });
  }

  QueryBuilder<Verteiler, Verteiler, QAfterSortBy>
      sortByAnlagendatenJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'anlagendatenJson', Sort.desc);
    });
  }

  QueryBuilder<Verteiler, Verteiler, QAfterSortBy> sortByBemerkung() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bemerkung', Sort.asc);
    });
  }

  QueryBuilder<Verteiler, Verteiler, QAfterSortBy> sortByBemerkungDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bemerkung', Sort.desc);
    });
  }

  QueryBuilder<Verteiler, Verteiler, QAfterSortBy> sortByBezeichnung() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bezeichnung', Sort.asc);
    });
  }

  QueryBuilder<Verteiler, Verteiler, QAfterSortBy> sortByBezeichnungDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bezeichnung', Sort.desc);
    });
  }

  QueryBuilder<Verteiler, Verteiler, QAfterSortBy> sortByErstelltAm() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'erstelltAm', Sort.asc);
    });
  }

  QueryBuilder<Verteiler, Verteiler, QAfterSortBy> sortByErstelltAmDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'erstelltAm', Sort.desc);
    });
  }

  QueryBuilder<Verteiler, Verteiler, QAfterSortBy> sortByStandortUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'standortUuid', Sort.asc);
    });
  }

  QueryBuilder<Verteiler, Verteiler, QAfterSortBy> sortByStandortUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'standortUuid', Sort.desc);
    });
  }

  QueryBuilder<Verteiler, Verteiler, QAfterSortBy> sortByUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.asc);
    });
  }

  QueryBuilder<Verteiler, Verteiler, QAfterSortBy> sortByUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.desc);
    });
  }
}

extension VerteilerQuerySortThenBy
    on QueryBuilder<Verteiler, Verteiler, QSortThenBy> {
  QueryBuilder<Verteiler, Verteiler, QAfterSortBy> thenByAnlagendatenJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'anlagendatenJson', Sort.asc);
    });
  }

  QueryBuilder<Verteiler, Verteiler, QAfterSortBy>
      thenByAnlagendatenJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'anlagendatenJson', Sort.desc);
    });
  }

  QueryBuilder<Verteiler, Verteiler, QAfterSortBy> thenByBemerkung() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bemerkung', Sort.asc);
    });
  }

  QueryBuilder<Verteiler, Verteiler, QAfterSortBy> thenByBemerkungDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bemerkung', Sort.desc);
    });
  }

  QueryBuilder<Verteiler, Verteiler, QAfterSortBy> thenByBezeichnung() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bezeichnung', Sort.asc);
    });
  }

  QueryBuilder<Verteiler, Verteiler, QAfterSortBy> thenByBezeichnungDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bezeichnung', Sort.desc);
    });
  }

  QueryBuilder<Verteiler, Verteiler, QAfterSortBy> thenByErstelltAm() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'erstelltAm', Sort.asc);
    });
  }

  QueryBuilder<Verteiler, Verteiler, QAfterSortBy> thenByErstelltAmDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'erstelltAm', Sort.desc);
    });
  }

  QueryBuilder<Verteiler, Verteiler, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Verteiler, Verteiler, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Verteiler, Verteiler, QAfterSortBy> thenByStandortUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'standortUuid', Sort.asc);
    });
  }

  QueryBuilder<Verteiler, Verteiler, QAfterSortBy> thenByStandortUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'standortUuid', Sort.desc);
    });
  }

  QueryBuilder<Verteiler, Verteiler, QAfterSortBy> thenByUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.asc);
    });
  }

  QueryBuilder<Verteiler, Verteiler, QAfterSortBy> thenByUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.desc);
    });
  }
}

extension VerteilerQueryWhereDistinct
    on QueryBuilder<Verteiler, Verteiler, QDistinct> {
  QueryBuilder<Verteiler, Verteiler, QDistinct> distinctByAnlagendatenJson(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'anlagendatenJson',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Verteiler, Verteiler, QDistinct> distinctByBemerkung(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'bemerkung', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Verteiler, Verteiler, QDistinct> distinctByBezeichnung(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'bezeichnung', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Verteiler, Verteiler, QDistinct> distinctByErstelltAm() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'erstelltAm');
    });
  }

  QueryBuilder<Verteiler, Verteiler, QDistinct> distinctByStandortUuid(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'standortUuid', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Verteiler, Verteiler, QDistinct> distinctByUuid(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'uuid', caseSensitive: caseSensitive);
    });
  }
}

extension VerteilerQueryProperty
    on QueryBuilder<Verteiler, Verteiler, QQueryProperty> {
  QueryBuilder<Verteiler, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Verteiler, String?, QQueryOperations>
      anlagendatenJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'anlagendatenJson');
    });
  }

  QueryBuilder<Verteiler, String?, QQueryOperations> bemerkungProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'bemerkung');
    });
  }

  QueryBuilder<Verteiler, String, QQueryOperations> bezeichnungProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'bezeichnung');
    });
  }

  QueryBuilder<Verteiler, DateTime?, QQueryOperations> erstelltAmProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'erstelltAm');
    });
  }

  QueryBuilder<Verteiler, String, QQueryOperations> standortUuidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'standortUuid');
    });
  }

  QueryBuilder<Verteiler, String, QQueryOperations> uuidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'uuid');
    });
  }
}
