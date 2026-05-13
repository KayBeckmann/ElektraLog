// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sichtpruefung.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetSichtpruefungCollection on Isar {
  IsarCollection<Sichtpruefung> get sichtpruefungs => this.collection();
}

const SichtpruefungSchema = CollectionSchema(
  name: r'Sichtpruefung',
  id: 6093404437489246741,
  properties: {
    r'checklisteJson': PropertySchema(
      id: 0,
      name: r'checklisteJson',
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
    r'maengel': PropertySchema(
      id: 3,
      name: r'maengel',
      type: IsarType.string,
    ),
    r'prueferName': PropertySchema(
      id: 4,
      name: r'prueferName',
      type: IsarType.string,
    ),
    r'pruefungDatum': PropertySchema(
      id: 5,
      name: r'pruefungDatum',
      type: IsarType.dateTime,
    ),
    r'uuid': PropertySchema(
      id: 6,
      name: r'uuid',
      type: IsarType.string,
    ),
    r'verteilerUuid': PropertySchema(
      id: 7,
      name: r'verteilerUuid',
      type: IsarType.string,
    )
  },
  estimateSize: _sichtpruefungEstimateSize,
  serialize: _sichtpruefungSerialize,
  deserialize: _sichtpruefungDeserialize,
  deserializeProp: _sichtpruefungDeserializeProp,
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
    r'verteilerUuid': IndexSchema(
      id: 7403232753648777000,
      name: r'verteilerUuid',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'verteilerUuid',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _sichtpruefungGetId,
  getLinks: _sichtpruefungGetLinks,
  attach: _sichtpruefungAttach,
  version: '3.1.0+1',
);

int _sichtpruefungEstimateSize(
  Sichtpruefung object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.checklisteJson;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.ergebnis.length * 3;
  {
    final value = object.maengel;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.prueferName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.uuid.length * 3;
  bytesCount += 3 + object.verteilerUuid.length * 3;
  return bytesCount;
}

void _sichtpruefungSerialize(
  Sichtpruefung object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.checklisteJson);
  writer.writeString(offsets[1], object.ergebnis);
  writer.writeDateTime(offsets[2], object.erstelltAm);
  writer.writeString(offsets[3], object.maengel);
  writer.writeString(offsets[4], object.prueferName);
  writer.writeDateTime(offsets[5], object.pruefungDatum);
  writer.writeString(offsets[6], object.uuid);
  writer.writeString(offsets[7], object.verteilerUuid);
}

Sichtpruefung _sichtpruefungDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Sichtpruefung();
  object.checklisteJson = reader.readStringOrNull(offsets[0]);
  object.ergebnis = reader.readString(offsets[1]);
  object.erstelltAm = reader.readDateTimeOrNull(offsets[2]);
  object.id = id;
  object.maengel = reader.readStringOrNull(offsets[3]);
  object.prueferName = reader.readStringOrNull(offsets[4]);
  object.pruefungDatum = reader.readDateTime(offsets[5]);
  object.uuid = reader.readString(offsets[6]);
  object.verteilerUuid = reader.readString(offsets[7]);
  return object;
}

P _sichtpruefungDeserializeProp<P>(
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
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readDateTime(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _sichtpruefungGetId(Sichtpruefung object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _sichtpruefungGetLinks(Sichtpruefung object) {
  return [];
}

void _sichtpruefungAttach(
    IsarCollection<dynamic> col, Id id, Sichtpruefung object) {
  object.id = id;
}

extension SichtpruefungByIndex on IsarCollection<Sichtpruefung> {
  Future<Sichtpruefung?> getByUuid(String uuid) {
    return getByIndex(r'uuid', [uuid]);
  }

  Sichtpruefung? getByUuidSync(String uuid) {
    return getByIndexSync(r'uuid', [uuid]);
  }

  Future<bool> deleteByUuid(String uuid) {
    return deleteByIndex(r'uuid', [uuid]);
  }

  bool deleteByUuidSync(String uuid) {
    return deleteByIndexSync(r'uuid', [uuid]);
  }

  Future<List<Sichtpruefung?>> getAllByUuid(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return getAllByIndex(r'uuid', values);
  }

  List<Sichtpruefung?> getAllByUuidSync(List<String> uuidValues) {
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

  Future<Id> putByUuid(Sichtpruefung object) {
    return putByIndex(r'uuid', object);
  }

  Id putByUuidSync(Sichtpruefung object, {bool saveLinks = true}) {
    return putByIndexSync(r'uuid', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByUuid(List<Sichtpruefung> objects) {
    return putAllByIndex(r'uuid', objects);
  }

  List<Id> putAllByUuidSync(List<Sichtpruefung> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'uuid', objects, saveLinks: saveLinks);
  }
}

extension SichtpruefungQueryWhereSort
    on QueryBuilder<Sichtpruefung, Sichtpruefung, QWhere> {
  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension SichtpruefungQueryWhere
    on QueryBuilder<Sichtpruefung, Sichtpruefung, QWhereClause> {
  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterWhereClause> idNotEqualTo(
      Id id) {
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

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterWhereClause> idBetween(
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

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterWhereClause> uuidEqualTo(
      String uuid) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'uuid',
        value: [uuid],
      ));
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterWhereClause> uuidNotEqualTo(
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

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterWhereClause>
      verteilerUuidEqualTo(String verteilerUuid) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'verteilerUuid',
        value: [verteilerUuid],
      ));
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterWhereClause>
      verteilerUuidNotEqualTo(String verteilerUuid) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'verteilerUuid',
              lower: [],
              upper: [verteilerUuid],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'verteilerUuid',
              lower: [verteilerUuid],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'verteilerUuid',
              lower: [verteilerUuid],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'verteilerUuid',
              lower: [],
              upper: [verteilerUuid],
              includeUpper: false,
            ));
      }
    });
  }
}

extension SichtpruefungQueryFilter
    on QueryBuilder<Sichtpruefung, Sichtpruefung, QFilterCondition> {
  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterFilterCondition>
      checklisteJsonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'checklisteJson',
      ));
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterFilterCondition>
      checklisteJsonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'checklisteJson',
      ));
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterFilterCondition>
      checklisteJsonEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'checklisteJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterFilterCondition>
      checklisteJsonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'checklisteJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterFilterCondition>
      checklisteJsonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'checklisteJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterFilterCondition>
      checklisteJsonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'checklisteJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterFilterCondition>
      checklisteJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'checklisteJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterFilterCondition>
      checklisteJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'checklisteJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterFilterCondition>
      checklisteJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'checklisteJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterFilterCondition>
      checklisteJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'checklisteJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterFilterCondition>
      checklisteJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'checklisteJson',
        value: '',
      ));
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterFilterCondition>
      checklisteJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'checklisteJson',
        value: '',
      ));
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterFilterCondition>
      ergebnisEqualTo(
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

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterFilterCondition>
      ergebnisGreaterThan(
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

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterFilterCondition>
      ergebnisLessThan(
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

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterFilterCondition>
      ergebnisBetween(
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

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterFilterCondition>
      ergebnisStartsWith(
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

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterFilterCondition>
      ergebnisEndsWith(
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

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterFilterCondition>
      ergebnisContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'ergebnis',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterFilterCondition>
      ergebnisMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'ergebnis',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterFilterCondition>
      ergebnisIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ergebnis',
        value: '',
      ));
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterFilterCondition>
      ergebnisIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'ergebnis',
        value: '',
      ));
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterFilterCondition>
      erstelltAmIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'erstelltAm',
      ));
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterFilterCondition>
      erstelltAmIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'erstelltAm',
      ));
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterFilterCondition>
      erstelltAmEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'erstelltAm',
        value: value,
      ));
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterFilterCondition>
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

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterFilterCondition>
      erstelltAmLessThan(
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

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterFilterCondition>
      erstelltAmBetween(
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

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterFilterCondition>
      idGreaterThan(
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

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterFilterCondition> idBetween(
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

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterFilterCondition>
      maengelIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'maengel',
      ));
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterFilterCondition>
      maengelIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'maengel',
      ));
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterFilterCondition>
      maengelEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'maengel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterFilterCondition>
      maengelGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'maengel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterFilterCondition>
      maengelLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'maengel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterFilterCondition>
      maengelBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'maengel',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterFilterCondition>
      maengelStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'maengel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterFilterCondition>
      maengelEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'maengel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterFilterCondition>
      maengelContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'maengel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterFilterCondition>
      maengelMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'maengel',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterFilterCondition>
      maengelIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'maengel',
        value: '',
      ));
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterFilterCondition>
      maengelIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'maengel',
        value: '',
      ));
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterFilterCondition>
      prueferNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'prueferName',
      ));
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterFilterCondition>
      prueferNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'prueferName',
      ));
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterFilterCondition>
      prueferNameEqualTo(
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

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterFilterCondition>
      prueferNameGreaterThan(
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

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterFilterCondition>
      prueferNameLessThan(
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

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterFilterCondition>
      prueferNameBetween(
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

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterFilterCondition>
      prueferNameStartsWith(
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

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterFilterCondition>
      prueferNameEndsWith(
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

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterFilterCondition>
      prueferNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'prueferName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterFilterCondition>
      prueferNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'prueferName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterFilterCondition>
      prueferNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'prueferName',
        value: '',
      ));
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterFilterCondition>
      prueferNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'prueferName',
        value: '',
      ));
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterFilterCondition>
      pruefungDatumEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'pruefungDatum',
        value: value,
      ));
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterFilterCondition>
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

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterFilterCondition>
      pruefungDatumLessThan(
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

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterFilterCondition>
      pruefungDatumBetween(
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

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterFilterCondition> uuidEqualTo(
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

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterFilterCondition>
      uuidGreaterThan(
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

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterFilterCondition>
      uuidLessThan(
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

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterFilterCondition> uuidBetween(
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

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterFilterCondition>
      uuidStartsWith(
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

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterFilterCondition>
      uuidEndsWith(
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

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterFilterCondition>
      uuidContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterFilterCondition> uuidMatches(
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

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterFilterCondition>
      uuidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uuid',
        value: '',
      ));
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterFilterCondition>
      uuidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'uuid',
        value: '',
      ));
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterFilterCondition>
      verteilerUuidEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'verteilerUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterFilterCondition>
      verteilerUuidGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'verteilerUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterFilterCondition>
      verteilerUuidLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'verteilerUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterFilterCondition>
      verteilerUuidBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'verteilerUuid',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterFilterCondition>
      verteilerUuidStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'verteilerUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterFilterCondition>
      verteilerUuidEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'verteilerUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterFilterCondition>
      verteilerUuidContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'verteilerUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterFilterCondition>
      verteilerUuidMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'verteilerUuid',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterFilterCondition>
      verteilerUuidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'verteilerUuid',
        value: '',
      ));
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterFilterCondition>
      verteilerUuidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'verteilerUuid',
        value: '',
      ));
    });
  }
}

extension SichtpruefungQueryObject
    on QueryBuilder<Sichtpruefung, Sichtpruefung, QFilterCondition> {}

extension SichtpruefungQueryLinks
    on QueryBuilder<Sichtpruefung, Sichtpruefung, QFilterCondition> {}

extension SichtpruefungQuerySortBy
    on QueryBuilder<Sichtpruefung, Sichtpruefung, QSortBy> {
  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterSortBy>
      sortByChecklisteJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'checklisteJson', Sort.asc);
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterSortBy>
      sortByChecklisteJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'checklisteJson', Sort.desc);
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterSortBy> sortByErgebnis() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ergebnis', Sort.asc);
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterSortBy>
      sortByErgebnisDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ergebnis', Sort.desc);
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterSortBy> sortByErstelltAm() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'erstelltAm', Sort.asc);
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterSortBy>
      sortByErstelltAmDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'erstelltAm', Sort.desc);
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterSortBy> sortByMaengel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maengel', Sort.asc);
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterSortBy> sortByMaengelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maengel', Sort.desc);
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterSortBy> sortByPrueferName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'prueferName', Sort.asc);
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterSortBy>
      sortByPrueferNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'prueferName', Sort.desc);
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterSortBy>
      sortByPruefungDatum() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pruefungDatum', Sort.asc);
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterSortBy>
      sortByPruefungDatumDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pruefungDatum', Sort.desc);
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterSortBy> sortByUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.asc);
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterSortBy> sortByUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.desc);
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterSortBy>
      sortByVerteilerUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'verteilerUuid', Sort.asc);
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterSortBy>
      sortByVerteilerUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'verteilerUuid', Sort.desc);
    });
  }
}

extension SichtpruefungQuerySortThenBy
    on QueryBuilder<Sichtpruefung, Sichtpruefung, QSortThenBy> {
  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterSortBy>
      thenByChecklisteJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'checklisteJson', Sort.asc);
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterSortBy>
      thenByChecklisteJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'checklisteJson', Sort.desc);
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterSortBy> thenByErgebnis() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ergebnis', Sort.asc);
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterSortBy>
      thenByErgebnisDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ergebnis', Sort.desc);
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterSortBy> thenByErstelltAm() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'erstelltAm', Sort.asc);
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterSortBy>
      thenByErstelltAmDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'erstelltAm', Sort.desc);
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterSortBy> thenByMaengel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maengel', Sort.asc);
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterSortBy> thenByMaengelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maengel', Sort.desc);
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterSortBy> thenByPrueferName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'prueferName', Sort.asc);
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterSortBy>
      thenByPrueferNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'prueferName', Sort.desc);
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterSortBy>
      thenByPruefungDatum() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pruefungDatum', Sort.asc);
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterSortBy>
      thenByPruefungDatumDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pruefungDatum', Sort.desc);
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterSortBy> thenByUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.asc);
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterSortBy> thenByUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.desc);
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterSortBy>
      thenByVerteilerUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'verteilerUuid', Sort.asc);
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QAfterSortBy>
      thenByVerteilerUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'verteilerUuid', Sort.desc);
    });
  }
}

extension SichtpruefungQueryWhereDistinct
    on QueryBuilder<Sichtpruefung, Sichtpruefung, QDistinct> {
  QueryBuilder<Sichtpruefung, Sichtpruefung, QDistinct>
      distinctByChecklisteJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'checklisteJson',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QDistinct> distinctByErgebnis(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ergebnis', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QDistinct> distinctByErstelltAm() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'erstelltAm');
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QDistinct> distinctByMaengel(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'maengel', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QDistinct> distinctByPrueferName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'prueferName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QDistinct>
      distinctByPruefungDatum() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'pruefungDatum');
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QDistinct> distinctByUuid(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'uuid', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Sichtpruefung, Sichtpruefung, QDistinct> distinctByVerteilerUuid(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'verteilerUuid',
          caseSensitive: caseSensitive);
    });
  }
}

extension SichtpruefungQueryProperty
    on QueryBuilder<Sichtpruefung, Sichtpruefung, QQueryProperty> {
  QueryBuilder<Sichtpruefung, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Sichtpruefung, String?, QQueryOperations>
      checklisteJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'checklisteJson');
    });
  }

  QueryBuilder<Sichtpruefung, String, QQueryOperations> ergebnisProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ergebnis');
    });
  }

  QueryBuilder<Sichtpruefung, DateTime?, QQueryOperations>
      erstelltAmProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'erstelltAm');
    });
  }

  QueryBuilder<Sichtpruefung, String?, QQueryOperations> maengelProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'maengel');
    });
  }

  QueryBuilder<Sichtpruefung, String?, QQueryOperations> prueferNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'prueferName');
    });
  }

  QueryBuilder<Sichtpruefung, DateTime, QQueryOperations>
      pruefungDatumProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'pruefungDatum');
    });
  }

  QueryBuilder<Sichtpruefung, String, QQueryOperations> uuidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'uuid');
    });
  }

  QueryBuilder<Sichtpruefung, String, QQueryOperations>
      verteilerUuidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'verteilerUuid');
    });
  }
}
