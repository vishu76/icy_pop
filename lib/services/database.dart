import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static const _databaseName = "location.db";
  static const _databaseVersion = 1;
  static const _tableName = "location_table";

  static const columnId = 'id';
  static const columnLatitude = 'latitude';
  static const columnLongitude = 'longitude';
  static const columnTimestamp = 'timestamp'; // New column for timestamp

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    // Lazy initialization of the database
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(path,
        version: _databaseVersion, onCreate: _onCreate);
  }

  // Creating the location table with timestamp column
  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnLatitude REAL NOT NULL,
        $columnLongitude REAL NOT NULL,
        $columnTimestamp TEXT NOT NULL
      )
    ''');
  }

  // Inserting location data with timestamp
  Future<int> insertLocation(double latitude, double longitude) async {
    Database db = await database;
    Map<String, dynamic> row = {
      columnLatitude: latitude,
      columnLongitude: longitude,
      columnTimestamp: DateTime.now().toIso8601String(), // Add the current timestamp
    };
    return await db.insert(_tableName, row);
  }

  // Fetching all stored location data including timestamp
  Future<List<Map<String, dynamic>>> getLocation() async {
    Database db = await database;
    return await db.query(_tableName);
  }
}
