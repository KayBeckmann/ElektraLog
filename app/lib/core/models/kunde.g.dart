// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kunde.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetKundeCollection on Isar {
  IsarCollection<Kunde> get kundes => this.collection();
}

const KundeSchema = CollectionSchema(
  name: r'Kunde',
  id: -666850294425302426,
  properties: {
    r'erstelltAm': PropertySchema(
      id: 0,
      name: r'erstelltAm',
      type: IsarType.dateTime,
    ),
    r'kontaktEmail': PropertySchema(
      id: 1,
      name: r'kontaktEmail',
      type: IsarType.string,
    ),
    r'kontaktTelefon': PropertySchema(
      id: 2,
      name: r'kontaktTelefon',
      type: IsarType.string,
    ),
    r'name': PropertySchema(
      id: 3,
      name: r'name',
      type: IsarType.string,
    ),
    r'ort': PropertySchema(
      id: 4,
      name: r'ort',
      type: IsarType.string,
    ),
    r'plz': PropertySchema(
      id: 5,
      name: r'plz',
      type: IsarType.string,
    ),
    r'strasse': PropertySchema(
      id: 6,
      name: r'strasse',
      type: IsarType.string,
    ),
    r'uuid': PropertySchema(
      id: 7,
      name: r'uuid',
      type: IsarType.string,
    )
  },
  estimateSize: _kundeEstimateSize,
  serialize: _kundeSerialize,
  deserialize: _kundeDeserialize,
  deserializeProp: _kundeDeserializeProp,
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
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _kundeGetId,
  getLinks: _kundeGetLinks,
  attach: _kundeAttach,
  version: '3.1.0+1',
);

int _kundeEstimateSize(
  Kunde object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.kontaktEmail;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.kontaktTelefon;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.name.length * 3;
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

void _kundeSerialize(
  Kunde object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.erstelltAm);
  writer.writeString(offsets[1], object.kontaktEmail);
  writer.writeString(offsets[2], object.kontaktTelefon);
  writer.writeString(offsets[3], object.name);
  writer.writeString(offsets[4], object.ort);
  writer.writeString(offsets[5], object.plz);
  writer.writeString(offsets[6], object.strasse);
  writer.writeString(offsets[7], object.uuid);
}

Kunde _kundeDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Kunde();
  object.erstelltAm = reader.readDateTimeOrNull(offsets[0]);
  object.id = id;
  object.kontaktEmail = reader.readStringOrNull(offsets[1]);
  object.kontaktTelefon = reader.readStringOrNull(offsets[2]);
  object.name = reader.readString(offsets[3]);
  object.ort = reader.readStringOrNull(offsets[4]);
  object.plz = reader.readStringOrNull(offsets[5]);
  object.strasse = reader.readStringOrNull(offsets[6]);
  object.uuid = reader.readString(offsets[7]);
  return object;
}

P _kundeDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _kundeGetId(Kunde object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _kundeGetLinks(Kunde object) {
  return [];
}

void _kundeAttach(IsarCollection<dynamic> col, Id id, Kunde object) {
  object.id = id;
}

extension KundeByIndex on IsarCollection<Kunde> {
  Future<Kunde?> getByUuid(String uuid) {
    return getByIndex(r'uuid', [uuid]);
  }

  Kunde? getByUuidSync(String uuid) {
    return getByIndexSync(r'uuid', [uuid]);
  }

  Future<bool> deleteByUuid(String uuid) {
    return deleteByIndex(r'uuid', [uuid]);
  }

  bool deleteByUuidSync(String uuid) {
    return deleteByIndexSync(r'uuid', [uuid]);
  }

  Future<List<Kunde?>> getAllByUuid(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return getAllByIndex(r'uuid', values);
  }

  List<Kunde?> getAllByUuidSync(List<String> uuidValues) {
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

  Future<Id> putByUuid(Kunde object) {
    return putByIndex(r'uuid', object);
  }

  Id putByUuidSync(Kunde object, {bool saveLinks = true}) {
    return putByIndexSync(r'uuid', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByUuid(List<Kunde> objects) {
    return putAllByIndex(r'uuid', objects);
  }

  List<Id> putAllByUuidSync(List<Kunde> objects, {bool saveLinks = true}) {
    return putAllByIndexSync(r'uuid', objects, saveLinks: saveLinks);
  }
}

extension KundeQueryWhereSort on QueryBuilder<Kunde, Kunde, QWhere> {
  QueryBuilder<Kunde, Kunde, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension KundeQueryWhere on QueryBuilder<Kunde, Kunde, QWhereClause> {
  QueryBuilder<Kunde, Kunde, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<Kunde, Kunde, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterWhereClause> idBetween(
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

  QueryBuilder<Kunde, Kunde, QAfterWhereClause> uuidEqualTo(String uuid) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'uuid',
        value: [uuid],
      ));
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterWhereClause> uuidNotEqualTo(String uuid) {
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
}

extension KundeQueryFilter on QueryBuilder<Kunde, Kunde, QFilterCondition> {
  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> erstelltAmIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'erstelltAm',
      ));
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> erstelltAmIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'erstelltAm',
      ));
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> erstelltAmEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'erstelltAm',
        value: value,
      ));
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> erstelltAmGreaterThan(
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

  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> erstelltAmLessThan(
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

  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> erstelltAmBetween(
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

  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> idBetween(
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

  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> kontaktEmailIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'kontaktEmail',
      ));
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> kontaktEmailIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'kontaktEmail',
      ));
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> kontaktEmailEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'kontaktEmail',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> kontaktEmailGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'kontaktEmail',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> kontaktEmailLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'kontaktEmail',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> kontaktEmailBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'kontaktEmail',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> kontaktEmailStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'kontaktEmail',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> kontaktEmailEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'kontaktEmail',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> kontaktEmailContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'kontaktEmail',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> kontaktEmailMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'kontaktEmail',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> kontaktEmailIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'kontaktEmail',
        value: '',
      ));
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> kontaktEmailIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'kontaktEmail',
        value: '',
      ));
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> kontaktTelefonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'kontaktTelefon',
      ));
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> kontaktTelefonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'kontaktTelefon',
      ));
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> kontaktTelefonEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'kontaktTelefon',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> kontaktTelefonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'kontaktTelefon',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> kontaktTelefonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'kontaktTelefon',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> kontaktTelefonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'kontaktTelefon',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> kontaktTelefonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'kontaktTelefon',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> kontaktTelefonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'kontaktTelefon',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> kontaktTelefonContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'kontaktTelefon',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> kontaktTelefonMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'kontaktTelefon',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> kontaktTelefonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'kontaktTelefon',
        value: '',
      ));
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> kontaktTelefonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'kontaktTelefon',
        value: '',
      ));
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> nameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> nameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> nameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> nameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'name',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> nameContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> nameMatches(String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> ortIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'ort',
      ));
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> ortIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'ort',
      ));
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> ortEqualTo(
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

  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> ortGreaterThan(
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

  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> ortLessThan(
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

  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> ortBetween(
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

  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> ortStartsWith(
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

  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> ortEndsWith(
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

  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> ortContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'ort',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> ortMatches(String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'ort',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> ortIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ort',
        value: '',
      ));
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> ortIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'ort',
        value: '',
      ));
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> plzIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'plz',
      ));
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> plzIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'plz',
      ));
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> plzEqualTo(
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

  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> plzGreaterThan(
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

  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> plzLessThan(
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

  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> plzBetween(
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

  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> plzStartsWith(
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

  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> plzEndsWith(
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

  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> plzContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'plz',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> plzMatches(String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'plz',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> plzIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'plz',
        value: '',
      ));
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> plzIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'plz',
        value: '',
      ));
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> strasseIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'strasse',
      ));
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> strasseIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'strasse',
      ));
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> strasseEqualTo(
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

  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> strasseGreaterThan(
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

  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> strasseLessThan(
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

  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> strasseBetween(
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

  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> strasseStartsWith(
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

  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> strasseEndsWith(
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

  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> strasseContains(
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

  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> strasseMatches(
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

  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> strasseIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'strasse',
        value: '',
      ));
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> strasseIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'strasse',
        value: '',
      ));
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> uuidEqualTo(
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

  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> uuidGreaterThan(
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

  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> uuidLessThan(
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

  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> uuidBetween(
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

  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> uuidStartsWith(
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

  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> uuidEndsWith(
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

  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> uuidContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> uuidMatches(String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'uuid',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> uuidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uuid',
        value: '',
      ));
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterFilterCondition> uuidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'uuid',
        value: '',
      ));
    });
  }
}

extension KundeQueryObject on QueryBuilder<Kunde, Kunde, QFilterCondition> {}

extension KundeQueryLinks on QueryBuilder<Kunde, Kunde, QFilterCondition> {}

extension KundeQuerySortBy on QueryBuilder<Kunde, Kunde, QSortBy> {
  QueryBuilder<Kunde, Kunde, QAfterSortBy> sortByErstelltAm() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'erstelltAm', Sort.asc);
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterSortBy> sortByErstelltAmDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'erstelltAm', Sort.desc);
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterSortBy> sortByKontaktEmail() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kontaktEmail', Sort.asc);
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterSortBy> sortByKontaktEmailDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kontaktEmail', Sort.desc);
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterSortBy> sortByKontaktTelefon() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kontaktTelefon', Sort.asc);
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterSortBy> sortByKontaktTelefonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kontaktTelefon', Sort.desc);
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterSortBy> sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterSortBy> sortByOrt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ort', Sort.asc);
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterSortBy> sortByOrtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ort', Sort.desc);
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterSortBy> sortByPlz() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'plz', Sort.asc);
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterSortBy> sortByPlzDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'plz', Sort.desc);
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterSortBy> sortByStrasse() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'strasse', Sort.asc);
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterSortBy> sortByStrasseDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'strasse', Sort.desc);
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterSortBy> sortByUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.asc);
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterSortBy> sortByUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.desc);
    });
  }
}

extension KundeQuerySortThenBy on QueryBuilder<Kunde, Kunde, QSortThenBy> {
  QueryBuilder<Kunde, Kunde, QAfterSortBy> thenByErstelltAm() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'erstelltAm', Sort.asc);
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterSortBy> thenByErstelltAmDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'erstelltAm', Sort.desc);
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterSortBy> thenByKontaktEmail() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kontaktEmail', Sort.asc);
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterSortBy> thenByKontaktEmailDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kontaktEmail', Sort.desc);
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterSortBy> thenByKontaktTelefon() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kontaktTelefon', Sort.asc);
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterSortBy> thenByKontaktTelefonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kontaktTelefon', Sort.desc);
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterSortBy> thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterSortBy> thenByOrt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ort', Sort.asc);
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterSortBy> thenByOrtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ort', Sort.desc);
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterSortBy> thenByPlz() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'plz', Sort.asc);
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterSortBy> thenByPlzDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'plz', Sort.desc);
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterSortBy> thenByStrasse() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'strasse', Sort.asc);
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterSortBy> thenByStrasseDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'strasse', Sort.desc);
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterSortBy> thenByUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.asc);
    });
  }

  QueryBuilder<Kunde, Kunde, QAfterSortBy> thenByUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.desc);
    });
  }
}

extension KundeQueryWhereDistinct on QueryBuilder<Kunde, Kunde, QDistinct> {
  QueryBuilder<Kunde, Kunde, QDistinct> distinctByErstelltAm() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'erstelltAm');
    });
  }

  QueryBuilder<Kunde, Kunde, QDistinct> distinctByKontaktEmail(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'kontaktEmail', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Kunde, Kunde, QDistinct> distinctByKontaktTelefon(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'kontaktTelefon',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Kunde, Kunde, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Kunde, Kunde, QDistinct> distinctByOrt(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ort', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Kunde, Kunde, QDistinct> distinctByPlz(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'plz', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Kunde, Kunde, QDistinct> distinctByStrasse(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'strasse', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Kunde, Kunde, QDistinct> distinctByUuid(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'uuid', caseSensitive: caseSensitive);
    });
  }
}

extension KundeQueryProperty on QueryBuilder<Kunde, Kunde, QQueryProperty> {
  QueryBuilder<Kunde, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Kunde, DateTime?, QQueryOperations> erstelltAmProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'erstelltAm');
    });
  }

  QueryBuilder<Kunde, String?, QQueryOperations> kontaktEmailProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'kontaktEmail');
    });
  }

  QueryBuilder<Kunde, String?, QQueryOperations> kontaktTelefonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'kontaktTelefon');
    });
  }

  QueryBuilder<Kunde, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<Kunde, String?, QQueryOperations> ortProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ort');
    });
  }

  QueryBuilder<Kunde, String?, QQueryOperations> plzProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'plz');
    });
  }

  QueryBuilder<Kunde, String?, QQueryOperations> strasseProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'strasse');
    });
  }

  QueryBuilder<Kunde, String, QQueryOperations> uuidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'uuid');
    });
  }
}
