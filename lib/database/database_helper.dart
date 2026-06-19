import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'db_constants.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, DbConstants.dbName);
    return openDatabase(
      path,
      version: DbConstants.dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      final tables = [
        DbConstants.tAccounts,
        DbConstants.tTransactions,
        DbConstants.tPersons,
        DbConstants.tLoans,
        DbConstants.tPayments,
      ];

      for (final table in tables) {
        try {
          await db.execute(
            'ALTER TABLE $table ADD COLUMN ${DbConstants.cUserId} TEXT',
          );
        } catch (_) {}
      }
    }

    if (oldVersion < 3) {
      try {
        await db.execute(
          'ALTER TABLE ${DbConstants.tTransactions} '
          'ADD COLUMN ${DbConstants.cTxnCustomCategory} TEXT',
        );
      } catch (_) {}
    }

    if (oldVersion < 4) {
      try {
        await db.execute(
          'ALTER TABLE ${DbConstants.tAccounts} '
          'ADD COLUMN ${DbConstants.cAccCreditLimit} REAL DEFAULT 0',
        );
      } catch (_) {}

      try {
        await db.execute(
          'ALTER TABLE ${DbConstants.tAccounts} '
          'ADD COLUMN ${DbConstants.cAccOutstandingAmt} REAL DEFAULT 0',
        );
      } catch (_) {}
    }

    if (oldVersion < 5) {
      try {
        await db.execute(
          'ALTER TABLE ${DbConstants.tTransactions} ADD COLUMN subtitle TEXT',
        );
      } catch (_) {}

      try {
        await db.execute(
          'ALTER TABLE ${DbConstants.tTransactions} ADD COLUMN category_id TEXT',
        );
      } catch (_) {}

      try {
        await db.execute(
          'ALTER TABLE ${DbConstants.tTransactions} ADD COLUMN category_name TEXT DEFAULT "કેટેગરી"',
        );
      } catch (_) {}

      try {
        await db.execute(
          'ALTER TABLE ${DbConstants.tTransactions} ADD COLUMN category_emoji TEXT DEFAULT "📁"',
        );
      } catch (_) {}

      try {
        await db.execute(
          'ALTER TABLE ${DbConstants.tTransactions} ADD COLUMN linked_credit_card_account_id TEXT',
        );
      } catch (_) {}
    }

    if (oldVersion < 6) {
      try {
        await db.execute(
          'ALTER TABLE ${DbConstants.tLoans} '
          'ADD COLUMN ${DbConstants.cLoanAccountId} TEXT',
        );
      } catch (_) {}
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${DbConstants.tAccounts} (
        ${DbConstants.cId}                TEXT PRIMARY KEY,
        ${DbConstants.cUserId}            TEXT NOT NULL,
        ${DbConstants.cAccName}           TEXT NOT NULL,
        ${DbConstants.cAccType}           TEXT NOT NULL,
        ${DbConstants.cAccBalance}        REAL DEFAULT 0,
        ${DbConstants.cAccColor}          TEXT,
        ${DbConstants.cAccIcon}           TEXT,
        ${DbConstants.cAccIsActive}       INTEGER DEFAULT 1,
        ${DbConstants.cAccCreditLimit}    REAL DEFAULT 0,
        ${DbConstants.cAccOutstandingAmt} REAL DEFAULT 0,
        ${DbConstants.cCreatedAt}         TEXT NOT NULL,
        ${DbConstants.cUpdatedAt}         TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DbConstants.tTransactions} (
        ${DbConstants.cId}                            TEXT PRIMARY KEY,
        ${DbConstants.cUserId}                        TEXT NOT NULL,
        ${DbConstants.cTxnTitle}                      TEXT NOT NULL,
        ${DbConstants.cTxnSubtitle}                   TEXT,
        ${DbConstants.cTxnAmount}                     REAL NOT NULL,
        ${DbConstants.cTxnType}                       TEXT NOT NULL,
        ${DbConstants.cTxnCategoryId}                 TEXT,
        ${DbConstants.cTxnCategoryName}               TEXT NOT NULL DEFAULT 'કેટેગરી',
        ${DbConstants.cTxnCategoryEmoji}              TEXT NOT NULL DEFAULT '📁',
        ${DbConstants.cTxnCustomCategory}             TEXT,
        ${DbConstants.cTxnAccId}                      TEXT NOT NULL,
        ${DbConstants.cTxnLinkedCreditCardAccountId}  TEXT,
        ${DbConstants.cTxnDate}                       TEXT NOT NULL,
        ${DbConstants.cTxnNote}                       TEXT,
        ${DbConstants.cCreatedAt}                     TEXT NOT NULL,
        FOREIGN KEY (${DbConstants.cTxnAccId})
          REFERENCES ${DbConstants.tAccounts}(${DbConstants.cId}),
        FOREIGN KEY (${DbConstants.cTxnLinkedCreditCardAccountId})
          REFERENCES ${DbConstants.tAccounts}(${DbConstants.cId})
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DbConstants.tPersons} (
        ${DbConstants.cId}          TEXT PRIMARY KEY,
        ${DbConstants.cUserId}      TEXT NOT NULL,
        ${DbConstants.cPerName}     TEXT NOT NULL,
        ${DbConstants.cPerPhone}    TEXT,
        ${DbConstants.cPerNote}     TEXT,
        ${DbConstants.cCreatedAt}   TEXT NOT NULL,
        ${DbConstants.cUpdatedAt}   TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DbConstants.tLoans} (
        ${DbConstants.cId}                TEXT PRIMARY KEY,
        ${DbConstants.cUserId}            TEXT NOT NULL,
        ${DbConstants.cLoanPersonId}      TEXT NOT NULL,
        ${DbConstants.cLoanAccountId}     TEXT,
        ${DbConstants.cLoanType}          TEXT NOT NULL,
        ${DbConstants.cLoanPrincipal}     REAL NOT NULL,
        ${DbConstants.cLoanInterestRate}  REAL DEFAULT 0,
        ${DbConstants.cLoanInterestType}  TEXT NOT NULL,
        ${DbConstants.cLoanPeriod}        TEXT NOT NULL,
        ${DbConstants.cLoanStartDate}     TEXT NOT NULL,
        ${DbConstants.cLoanEndDate}       TEXT,
        ${DbConstants.cLoanPaymentStyle}  TEXT NOT NULL,
        ${DbConstants.cLoanEmiAmount}     REAL DEFAULT 0,
        ${DbConstants.cLoanEmiDay}        INTEGER DEFAULT 1,
        ${DbConstants.cLoanTotalMonths}   INTEGER DEFAULT 0,
        ${DbConstants.cLoanStatus}        TEXT DEFAULT 'active',
        ${DbConstants.cLoanNote}          TEXT,
        ${DbConstants.cCreatedAt}         TEXT NOT NULL,
        ${DbConstants.cUpdatedAt}         TEXT NOT NULL,
        FOREIGN KEY (${DbConstants.cLoanPersonId})
          REFERENCES ${DbConstants.tPersons}(${DbConstants.cId}),
        FOREIGN KEY (${DbConstants.cLoanAccountId})
          REFERENCES ${DbConstants.tAccounts}(${DbConstants.cId})
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DbConstants.tPayments} (
        ${DbConstants.cId}            TEXT PRIMARY KEY,
        ${DbConstants.cUserId}        TEXT NOT NULL,
        ${DbConstants.cPayLoanId}     TEXT NOT NULL,
        ${DbConstants.cPayAmount}     REAL NOT NULL,
        ${DbConstants.cPayDate}       TEXT NOT NULL,
        ${DbConstants.cPayTowards}    TEXT NOT NULL,
        ${DbConstants.cPayNote}       TEXT,
        ${DbConstants.cPayAccountId}  TEXT,
        ${DbConstants.cCreatedAt}     TEXT NOT NULL,
        FOREIGN KEY (${DbConstants.cPayLoanId})
          REFERENCES ${DbConstants.tLoans}(${DbConstants.cId}),
        FOREIGN KEY (${DbConstants.cPayAccountId})
          REFERENCES ${DbConstants.tAccounts}(${DbConstants.cId})
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DbConstants.tSettings} (
        ${DbConstants.cSetKey}   TEXT PRIMARY KEY,
        ${DbConstants.cSetValue} TEXT NOT NULL
      )
    ''');

    await _insertDefaults(db);
  }

  Future<void> _insertDefaults(Database db) async {
    final now = DateTime.now().toIso8601String();

    final accounts = [
      {
        DbConstants.cId: 'acc_cash',
        DbConstants.cUserId: 'system',
        DbConstants.cAccName: 'રોકડ',
        DbConstants.cAccType: 'cash',
        DbConstants.cAccBalance: 0.0,
        DbConstants.cAccColor: '#01696F',
        DbConstants.cAccIcon: '💵',
        DbConstants.cAccIsActive: 1,
        DbConstants.cAccCreditLimit: 0.0,
        DbConstants.cAccOutstandingAmt: 0.0,
        DbConstants.cCreatedAt: now,
        DbConstants.cUpdatedAt: now,
      },
      {
        DbConstants.cId: 'acc_bank',
        DbConstants.cUserId: 'system',
        DbConstants.cAccName: 'બૅન્ક',
        DbConstants.cAccType: 'bank',
        DbConstants.cAccBalance: 0.0,
        DbConstants.cAccColor: '#006494',
        DbConstants.cAccIcon: '🏦',
        DbConstants.cAccIsActive: 1,
        DbConstants.cAccCreditLimit: 0.0,
        DbConstants.cAccOutstandingAmt: 0.0,
        DbConstants.cCreatedAt: now,
        DbConstants.cUpdatedAt: now,
      },
      {
        DbConstants.cId: 'acc_upi',
        DbConstants.cUserId: 'system',
        DbConstants.cAccName: 'UPI / વૉલેટ',
        DbConstants.cAccType: 'upi',
        DbConstants.cAccBalance: 0.0,
        DbConstants.cAccColor: '#E07B39',
        DbConstants.cAccIcon: '📲',
        DbConstants.cAccIsActive: 1,
        DbConstants.cAccCreditLimit: 0.0,
        DbConstants.cAccOutstandingAmt: 0.0,
        DbConstants.cCreatedAt: now,
        DbConstants.cUpdatedAt: now,
      },
    ];

    for (final acc in accounts) {
      await db.insert(DbConstants.tAccounts, acc);
    }

    final settings = [
      {DbConstants.cSetKey: DbConstants.kLanguage, DbConstants.cSetValue: 'gu'},
      {
        DbConstants.cSetKey: DbConstants.kTheme,
        DbConstants.cSetValue: 'system'
      },
      {
        DbConstants.cSetKey: DbConstants.kPinEnabled,
        DbConstants.cSetValue: 'false'
      },
      {DbConstants.cSetKey: DbConstants.kCurrency, DbConstants.cSetValue: '₹'},
      {
        DbConstants.cSetKey: DbConstants.kOnboarded,
        DbConstants.cSetValue: 'false'
      },
    ];

    for (final s in settings) {
      await db.insert(DbConstants.tSettings, s);
    }
  }

  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return db.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getAll(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
  }) async {
    final db = await database;
    return db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
    );
  }

  Future<Map<String, dynamic>?> getById(String table, String id) async {
    final db = await database;
    final result = await db.query(
      table,
      where: '${DbConstants.cId} = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> update(String table, Map<String, dynamic> data, String id) async {
    final db = await database;
    return db.update(
      table,
      data,
      where: '${DbConstants.cId} = ?',
      whereArgs: [id],
    );
  }

  Future<int> delete(String table, String id) async {
    final db = await database;
    return db.delete(
      table,
      where: '${DbConstants.cId} = ?',
      whereArgs: [id],
    );
  }

  Future<String?> getSetting(String key) async {
    final db = await database;
    final result = await db.query(
      DbConstants.tSettings,
      where: '${DbConstants.cSetKey} = ?',
      whereArgs: [key],
    );
    return result.isNotEmpty
        ? result.first[DbConstants.cSetValue] as String
        : null;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      DbConstants.tSettings,
      {DbConstants.cSetKey: key, DbConstants.cSetValue: value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>> exportAll() async {
    final db = await database;
    return {
      'accounts': await db.query(DbConstants.tAccounts),
      'transactions': await db.query(DbConstants.tTransactions),
      'persons': await db.query(DbConstants.tPersons),
      'loans': await db.query(DbConstants.tLoans),
      'payments': await db.query(DbConstants.tPayments),
      'settings': await db.query(DbConstants.tSettings),
    };
  }

  Future<void> importAll(Map<String, dynamic> data) async {
    final db = await database;
    await db.transaction((txn) async {
      for (final table in [
        DbConstants.tPayments,
        DbConstants.tLoans,
        DbConstants.tTransactions,
        DbConstants.tPersons,
        DbConstants.tAccounts,
        DbConstants.tSettings,
      ]) {
        await txn.delete(table);
      }

      for (final acc in data['accounts'] as List) {
        await txn.insert(
          DbConstants.tAccounts,
          Map<String, dynamic>.from(acc),
        );
      }

      for (final txnData in data['transactions'] as List) {
        await txn.insert(
          DbConstants.tTransactions,
          Map<String, dynamic>.from(txnData),
        );
      }

      for (final p in data['persons'] as List) {
        await txn.insert(
          DbConstants.tPersons,
          Map<String, dynamic>.from(p),
        );
      }

      for (final loan in data['loans'] as List) {
        await txn.insert(
          DbConstants.tLoans,
          Map<String, dynamic>.from(loan),
        );
      }

      for (final pay in data['payments'] as List) {
        await txn.insert(
          DbConstants.tPayments,
          Map<String, dynamic>.from(pay),
        );
      }

      for (final s in data['settings'] as List) {
        await txn.insert(
          DbConstants.tSettings,
          Map<String, dynamic>.from(s),
        );
      }
    });
  }
}
