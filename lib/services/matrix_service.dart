import 'package:matrix/matrix.dart';
import 'package:flutter/foundation.dart';

// Database Engines
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

class MatrixService {
  static final MatrixService instance = MatrixService._internal();
  factory MatrixService() => instance;
  MatrixService._internal();

  Client? client;

  Future<void> init() async {
    // 1. Pick the right Database Factory for the platform
    DatabaseFactory dbFactory;
    if (kIsWeb) {
      dbFactory = databaseFactoryFfiWeb;
    } else {
      sqfliteFfiInit();
      dbFactory = databaseFactoryFfi;
    }

    // 2. Open the Database (Memory for now to avoid file issues)
    // In a real app, you would give this a real path like 'resistance_chat.db'
    final rawDatabase = await dbFactory.openDatabase(inMemoryDatabasePath);

    // 3. Initialize the Matrix Database Wrapper
    final matrixDatabase = await MatrixSdkDatabase.init(
      'resistance_client',
      database: rawDatabase,
    );

    // 4. Create the Client with the new 'database' parameter
    client = Client(
      'Resistance App',
      database: matrixDatabase, // <--- This is the fix!
    );

    await client!.init();
  }

  Future<void> login(String username, String password) async {
    if (client == null) await init();
    
    // Use the official Matrix server or your own
    await client!.checkHomeserver(Uri.parse("https://matrix.org"));
    
    await client!.login(
      LoginType.mLoginPassword,
      password: password,
      identifier: AuthenticationUserIdentifier(user: username),
    );
  }
}
