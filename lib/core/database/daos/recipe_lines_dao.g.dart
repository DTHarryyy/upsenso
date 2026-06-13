// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_lines_dao.dart';

// ignore_for_file: type=lint
mixin _$RecipeLinesDaoMixin on DatabaseAccessor<AppDatabase> {
  $RecipeLinesTableTable get recipeLinesTable =>
      attachedDatabase.recipeLinesTable;
  RecipeLinesDaoManager get managers => RecipeLinesDaoManager(this);
}

class RecipeLinesDaoManager {
  final _$RecipeLinesDaoMixin _db;
  RecipeLinesDaoManager(this._db);
  $$RecipeLinesTableTableTableManager get recipeLinesTable =>
      $$RecipeLinesTableTableTableManager(
        _db.attachedDatabase,
        _db.recipeLinesTable,
      );
}
