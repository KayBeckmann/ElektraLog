// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'verteiler_komponente.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetVerteilerKomponenteCollection on Isar {
  IsarCollection<VerteilerKomponente> get verteilerKomponentes =>
      this.collection();
}

const VerteilerKomponenteSchema = CollectionSchema(
  name: r'VerteilerKomponente',
  id: 3120273361414190260,
  properties: {
    r'bezeichnung': PropertySchema(
      id: 0,
      name: r'bezeichnung',
      type: IsarType.string,
    ),
    r'eigenschaftenJson': PropertySchema(
      id: 1,
      name: r'eigenschaftenJson',
      type: IsarType.string,
    ),
    r'erstelltAm': PropertySchema(
      id: 2,
      name: r'erstelltAm',
      type: IsarType.dateTime,
    ),
    r'parentUuid': PropertySchema(
      id: 3,
      name: r'parentUuid',
      type: IsarType.string,
    ),
    r'position': PropertySchema(
      id: 4,
      name: r'position',
      type: IsarType.long,
    ),
    r'typ': PropertySchema(
      id: 5,
      name: r'typ',
      type: IsarType.string,
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
  estimateSize: _verteilerKomponenteEstimateSize,
  serialize: _verteilerKomponenteSerialize,
  deserialize: _verteilerKomponenteDeserialize,
  deserializeProp: _verteilerKomponenteDeserializeProp,
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
  getId: _verteilerKomponenteGetId,
  getLinks: _verteilerKomponenteGetLinks,
  attach: _verteilerKomponenteAttach,
  version: '3.1.0+1',
);

int _verteilerKomponenteEstimateSize(
  VerteilerKomponente object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.bezeichnung.length * 3;
  {
    final value = object.eigenschaftenJson;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.parentUuid;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.typ.length * 3;
  bytesCount += 3 + object.uuid.length * 3;
  bytesCount += 3 + object.verteilerUuid.length * 3;
  return bytesCount;
}

void _verteilerKomponenteSerialize(
  VerteilerKomponente object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.bezeichnung);
  writer.writeString(offsets[1], object.eigenschaftenJson);
  writer.writeDateTime(offsets[2], object.erstelltAm);
  writer.writeString(offsets[3], object.parentUuid);
  writer.writeLong(offsets[4], object.position);
  writer.writeString(offsets[5], object.typ);
  writer.writeString(offsets[6], object.uuid);
  writer.writeString(offsets[7], object.verteilerUuid);
}

VerteilerKomponente _verteilerKomponenteDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = VerteilerKomponente();
  object.bezeichnung = reader.readString(offsets[0]);
  object.eigenschaftenJson = reader.readStringOrNull(offsets[1]);
  object.erstelltAm = reader.readDateTimeOrNull(offsets[2]);
  object.id = id;
  object.parentUuid = reader.readStringOrNull(offsets[3]);
  object.position = reader.readLong(offsets[4]);
  object.typ = reader.readString(offsets[5]);
  object.uuid = reader.readString(offsets[6]);
  object.verteilerUuid = reader.readString(offsets[7]);
  return object;
}

P _verteilerKomponenteDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _verteilerKomponenteGetId(VerteilerKomponente object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _verteilerKomponenteGetLinks(
    VerteilerKomponente object) {
  return [];
}

void _verteilerKomponenteAttach(
    IsarCollection<dynamic> col, Id id, VerteilerKomponente object) {
  object.id = id;
}

extension VerteilerKomponenteByIndex on IsarCollection<VerteilerKomponente> {
  Future<VerteilerKomponente?> getByUuid(String uuid) {
    return getByIndex(r'uuid', [uuid]);
  }

  VerteilerKomponente? getByUuidSync(String uuid) {
    return getByIndexSync(r'uuid', [uuid]);
  }

  Future<bool> deleteByUuid(String uuid) {
    return deleteByIndex(r'uuid', [uuid]);
  }

  bool deleteByUuidSync(String uuid) {
    return deleteByIndexSync(r'uuid', [uuid]);
  }

  Future<List<VerteilerKomponente?>> getAllByUuid(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return getAllByIndex(r'uuid', values);
  }

  List<VerteilerKomponente?> getAllByUuidSync(List<String> uuidValues) {
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

  Future<Id> putByUuid(VerteilerKomponente object) {
    return putByIndex(r'uuid', object);
  }

  Id putByUuidSync(VerteilerKomponente object, {bool saveLinks = true}) {
    return putByIndexSync(r'uuid', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByUuid(List<VerteilerKomponente> objects) {
    return putAllByIndex(r'uuid', objects);
  }

  List<Id> putAllByUuidSync(List<VerteilerKomponente> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'uuid', objects, saveLinks: saveLinks);
  }
}

extension VerteilerKomponenteQueryWhereSort
    on QueryBuilder<VerteilerKomponente, VerteilerKomponente, QWhere> {
  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension VerteilerKomponenteQueryWhere
    on QueryBuilder<VerteilerKomponente, VerteilerKomponente, QWhereClause> {
  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterWhereClause>
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

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterWhereClause>
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

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterWhereClause>
      uuidEqualTo(String uuid) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'uuid',
        value: [uuid],
      ));
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterWhereClause>
      uuidNotEqualTo(String uuid) {
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

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterWhereClause>
      verteilerUuidEqualTo(String verteilerUuid) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'verteilerUuid',
        value: [verteilerUuid],
      ));
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterWhereClause>
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

extension VerteilerKomponenteQueryFilter on QueryBuilder<VerteilerKomponente,
    VerteilerKomponente, QFilterCondition> {
  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterFilterCondition>
      bezeichnungEqualTo(
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

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterFilterCondition>
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

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterFilterCondition>
      bezeichnungLessThan(
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

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterFilterCondition>
      bezeichnungBetween(
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

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterFilterCondition>
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

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterFilterCondition>
      bezeichnungEndsWith(
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

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterFilterCondition>
      bezeichnungContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'bezeichnung',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterFilterCondition>
      bezeichnungMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'bezeichnung',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterFilterCondition>
      bezeichnungIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'bezeichnung',
        value: '',
      ));
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterFilterCondition>
      bezeichnungIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'bezeichnung',
        value: '',
      ));
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterFilterCondition>
      eigenschaftenJsonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'eigenschaftenJson',
      ));
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterFilterCondition>
      eigenschaftenJsonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'eigenschaftenJson',
      ));
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterFilterCondition>
      eigenschaftenJsonEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'eigenschaftenJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterFilterCondition>
      eigenschaftenJsonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'eigenschaftenJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterFilterCondition>
      eigenschaftenJsonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'eigenschaftenJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterFilterCondition>
      eigenschaftenJsonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'eigenschaftenJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterFilterCondition>
      eigenschaftenJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'eigenschaftenJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterFilterCondition>
      eigenschaftenJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'eigenschaftenJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterFilterCondition>
      eigenschaftenJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'eigenschaftenJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterFilterCondition>
      eigenschaftenJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'eigenschaftenJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterFilterCondition>
      eigenschaftenJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'eigenschaftenJson',
        value: '',
      ));
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterFilterCondition>
      eigenschaftenJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'eigenschaftenJson',
        value: '',
      ));
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterFilterCondition>
      erstelltAmIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'erstelltAm',
      ));
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterFilterCondition>
      erstelltAmIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'erstelltAm',
      ));
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterFilterCondition>
      erstelltAmEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'erstelltAm',
        value: value,
      ));
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterFilterCondition>
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

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterFilterCondition>
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

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterFilterCondition>
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

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterFilterCondition>
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

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterFilterCondition>
      idLessThan(
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

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterFilterCondition>
      idBetween(
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

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterFilterCondition>
      parentUuidIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'parentUuid',
      ));
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterFilterCondition>
      parentUuidIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'parentUuid',
      ));
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterFilterCondition>
      parentUuidEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'parentUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterFilterCondition>
      parentUuidGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'parentUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterFilterCondition>
      parentUuidLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'parentUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterFilterCondition>
      parentUuidBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'parentUuid',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterFilterCondition>
      parentUuidStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'parentUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterFilterCondition>
      parentUuidEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'parentUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterFilterCondition>
      parentUuidContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'parentUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterFilterCondition>
      parentUuidMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'parentUuid',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterFilterCondition>
      parentUuidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'parentUuid',
        value: '',
      ));
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterFilterCondition>
      parentUuidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'parentUuid',
        value: '',
      ));
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterFilterCondition>
      positionEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'position',
        value: value,
      ));
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterFilterCondition>
      positionGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'position',
        value: value,
      ));
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterFilterCondition>
      positionLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'position',
        value: value,
      ));
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterFilterCondition>
      positionBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'position',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterFilterCondition>
      typEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'typ',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterFilterCondition>
      typGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'typ',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterFilterCondition>
      typLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'typ',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterFilterCondition>
      typBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'typ',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterFilterCondition>
      typStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'typ',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterFilterCondition>
      typEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'typ',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterFilterCondition>
      typContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'typ',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterFilterCondition>
      typMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'typ',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterFilterCondition>
      typIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'typ',
        value: '',
      ));
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterFilterCondition>
      typIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'typ',
        value: '',
      ));
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterFilterCondition>
      uuidEqualTo(
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

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterFilterCondition>
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

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterFilterCondition>
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

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterFilterCondition>
      uuidBetween(
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

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterFilterCondition>
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

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterFilterCondition>
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

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterFilterCondition>
      uuidContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterFilterCondition>
      uuidMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'uuid',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterFilterCondition>
      uuidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uuid',
        value: '',
      ));
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterFilterCondition>
      uuidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'uuid',
        value: '',
      ));
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterFilterCondition>
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

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterFilterCondition>
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

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterFilterCondition>
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

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterFilterCondition>
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

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterFilterCondition>
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

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterFilterCondition>
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

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterFilterCondition>
      verteilerUuidContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'verteilerUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterFilterCondition>
      verteilerUuidMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'verteilerUuid',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterFilterCondition>
      verteilerUuidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'verteilerUuid',
        value: '',
      ));
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterFilterCondition>
      verteilerUuidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'verteilerUuid',
        value: '',
      ));
    });
  }
}

extension VerteilerKomponenteQueryObject on QueryBuilder<VerteilerKomponente,
    VerteilerKomponente, QFilterCondition> {}

extension VerteilerKomponenteQueryLinks on QueryBuilder<VerteilerKomponente,
    VerteilerKomponente, QFilterCondition> {}

extension VerteilerKomponenteQuerySortBy
    on QueryBuilder<VerteilerKomponente, VerteilerKomponente, QSortBy> {
  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterSortBy>
      sortByBezeichnung() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bezeichnung', Sort.asc);
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterSortBy>
      sortByBezeichnungDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bezeichnung', Sort.desc);
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterSortBy>
      sortByEigenschaftenJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eigenschaftenJson', Sort.asc);
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterSortBy>
      sortByEigenschaftenJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eigenschaftenJson', Sort.desc);
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterSortBy>
      sortByErstelltAm() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'erstelltAm', Sort.asc);
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterSortBy>
      sortByErstelltAmDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'erstelltAm', Sort.desc);
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterSortBy>
      sortByParentUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'parentUuid', Sort.asc);
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterSortBy>
      sortByParentUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'parentUuid', Sort.desc);
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterSortBy>
      sortByPosition() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'position', Sort.asc);
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterSortBy>
      sortByPositionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'position', Sort.desc);
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterSortBy>
      sortByTyp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'typ', Sort.asc);
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterSortBy>
      sortByTypDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'typ', Sort.desc);
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterSortBy>
      sortByUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.asc);
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterSortBy>
      sortByUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.desc);
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterSortBy>
      sortByVerteilerUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'verteilerUuid', Sort.asc);
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterSortBy>
      sortByVerteilerUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'verteilerUuid', Sort.desc);
    });
  }
}

extension VerteilerKomponenteQuerySortThenBy
    on QueryBuilder<VerteilerKomponente, VerteilerKomponente, QSortThenBy> {
  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterSortBy>
      thenByBezeichnung() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bezeichnung', Sort.asc);
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterSortBy>
      thenByBezeichnungDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bezeichnung', Sort.desc);
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterSortBy>
      thenByEigenschaftenJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eigenschaftenJson', Sort.asc);
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterSortBy>
      thenByEigenschaftenJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eigenschaftenJson', Sort.desc);
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterSortBy>
      thenByErstelltAm() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'erstelltAm', Sort.asc);
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterSortBy>
      thenByErstelltAmDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'erstelltAm', Sort.desc);
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterSortBy>
      thenByParentUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'parentUuid', Sort.asc);
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterSortBy>
      thenByParentUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'parentUuid', Sort.desc);
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterSortBy>
      thenByPosition() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'position', Sort.asc);
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterSortBy>
      thenByPositionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'position', Sort.desc);
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterSortBy>
      thenByTyp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'typ', Sort.asc);
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterSortBy>
      thenByTypDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'typ', Sort.desc);
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterSortBy>
      thenByUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.asc);
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterSortBy>
      thenByUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.desc);
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterSortBy>
      thenByVerteilerUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'verteilerUuid', Sort.asc);
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QAfterSortBy>
      thenByVerteilerUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'verteilerUuid', Sort.desc);
    });
  }
}

extension VerteilerKomponenteQueryWhereDistinct
    on QueryBuilder<VerteilerKomponente, VerteilerKomponente, QDistinct> {
  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QDistinct>
      distinctByBezeichnung({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'bezeichnung', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QDistinct>
      distinctByEigenschaftenJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'eigenschaftenJson',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QDistinct>
      distinctByErstelltAm() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'erstelltAm');
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QDistinct>
      distinctByParentUuid({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'parentUuid', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QDistinct>
      distinctByPosition() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'position');
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QDistinct>
      distinctByTyp({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'typ', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QDistinct>
      distinctByUuid({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'uuid', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<VerteilerKomponente, VerteilerKomponente, QDistinct>
      distinctByVerteilerUuid({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'verteilerUuid',
          caseSensitive: caseSensitive);
    });
  }
}

extension VerteilerKomponenteQueryProperty
    on QueryBuilder<VerteilerKomponente, VerteilerKomponente, QQueryProperty> {
  QueryBuilder<VerteilerKomponente, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<VerteilerKomponente, String, QQueryOperations>
      bezeichnungProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'bezeichnung');
    });
  }

  QueryBuilder<VerteilerKomponente, String?, QQueryOperations>
      eigenschaftenJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'eigenschaftenJson');
    });
  }

  QueryBuilder<VerteilerKomponente, DateTime?, QQueryOperations>
      erstelltAmProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'erstelltAm');
    });
  }

  QueryBuilder<VerteilerKomponente, String?, QQueryOperations>
      parentUuidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'parentUuid');
    });
  }

  QueryBuilder<VerteilerKomponente, int, QQueryOperations> positionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'position');
    });
  }

  QueryBuilder<VerteilerKomponente, String, QQueryOperations> typProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'typ');
    });
  }

  QueryBuilder<VerteilerKomponente, String, QQueryOperations> uuidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'uuid');
    });
  }

  QueryBuilder<VerteilerKomponente, String, QQueryOperations>
      verteilerUuidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'verteilerUuid');
    });
  }
}
