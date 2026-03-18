import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/ayah.dart';
import '../models/surah.dart';

class QuranDatabase {
  QuranDatabase();

  static const String _dbName = 'quran_recitation_training.db';
  static const int _dbVersion = 1;

  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _openDatabase();
    return _database!;
  }

  Future<Database> _openDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE surahs(
            number INTEGER PRIMARY KEY,
            name_ar TEXT NOT NULL,
            name_en TEXT NOT NULL,
            ayah_count INTEGER NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE ayahs(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            surah_number INTEGER NOT NULL,
            ayah_number INTEGER NOT NULL,
            text_ar TEXT NOT NULL,
            audio_url TEXT NOT NULL,
            UNIQUE(surah_number, ayah_number) ON CONFLICT REPLACE
          )
        ''');
      },
    );
  }

  Future<List<Surah>> getSurahs() async {
    final db = await database;
    final rows = await db.query('surahs', orderBy: 'number ASC');
    return rows.map(Surah.fromDb).toList(growable: false);
  }

  Future<void> upsertSurahs(List<Surah> surahs) async {
    if (surahs.isEmpty) {
      return;
    }

    final db = await database;
    final batch = db.batch();
    for (final surah in surahs) {
      batch.insert(
        'surahs',
        surah.toDb(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Ayah>> getAyahsForSurah(int surahNumber) async {
    final db = await database;
    final rows = await db.query(
      'ayahs',
      where: 'surah_number = ?',
      whereArgs: [surahNumber],
      orderBy: 'ayah_number ASC',
    );
    return rows.map(Ayah.fromDb).toList(growable: false);
  }

  Future<void> upsertAyahs(List<Ayah> ayahs) async {
    if (ayahs.isEmpty) {
      return;
    }

    final db = await database;
    final batch = db.batch();
    for (final ayah in ayahs) {
      batch.insert(
        'ayahs',
        ayah.toDb(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
