class DbConstants {
  DbConstants._();

  static const String dbName = 'hisaab_kitaab.db';
  static const int dbVersion = 3;

  // ── Table Names ───────────────────────────────
  static const String tAccounts = 'accounts';
  static const String tTransactions = 'transactions';
  static const String tCategories = 'categories';
  static const String tCustomCategories = 'custom_categories';
  static const String tPersons = 'ledger_persons';
  static const String tLoans = 'loans';
  static const String tPayments = 'loan_payments';
  static const String tSettings = 'settings';

  // ── Common Columns ────────────────────────────
  static const String cId = 'id';
  static const String cUserId = 'user_id';
  static const String cCreatedAt = 'created_at';
  static const String cUpdatedAt = 'updated_at';

  // ── Accounts ──────────────────────────────────
  static const String cAccName = 'name';
  static const String cAccType = 'type';
  static const String cAccBalance = 'balance';
  static const String cAccColor = 'color';
  static const String cAccIcon = 'icon';
  static const String cAccIsActive = 'is_active';

  // ── Transactions ──────────────────────────────
  static const String cTxnTitle = 'title';
  static const String cTxnAmount = 'amount';
  static const String cTxnType = 'type';
  static const String cTxnCategory = 'category';
  static const String cTxnCustomCategory = 'custom_category';
  static const String cTxnAccId = 'account_id';
  static const String cTxnDate = 'date';
  static const String cTxnNote = 'note';

  // ── Custom Categories ─────────────────────────
  static const String cCatName = 'name';
  static const String cCatType = 'type';

  // ── Ledger Persons ────────────────────────────
  static const String cPerName = 'name';
  static const String cPerPhone = 'phone';
  static const String cPerNote = 'note';

  // ── Loans ─────────────────────────────────────
  static const String cLoanPersonId = 'person_id';
  static const String cLoanType = 'type';
  static const String cLoanPrincipal = 'principal';
  static const String cLoanInterestRate = 'interest_rate';
  static const String cLoanInterestType = 'interest_type';
  static const String cLoanPeriod = 'period';
  static const String cLoanStartDate = 'start_date';
  static const String cLoanEndDate = 'end_date';
  static const String cLoanPaymentStyle = 'payment_style';
  static const String cLoanEmiAmount = 'emi_amount';
  static const String cLoanEmiDay = 'emi_day';
  static const String cLoanTotalMonths = 'total_months';
  static const String cLoanStatus = 'status';
  static const String cLoanNote = 'note';

  // ── Loan Payments ─────────────────────────────
  static const String cPayLoanId = 'loan_id';
  static const String cPayAmount = 'amount';
  static const String cPayDate = 'payment_date';
  static const String cPayTowards = 'towards';
  static const String cPayNote = 'note';

  // ── Settings ──────────────────────────────────
  static const String cSetKey = 'key';
  static const String cSetValue = 'value';

  // ── Setting Keys ──────────────────────────────
  static const String kLanguage = 'language';
  static const String kTheme = 'theme';
  static const String kPinEnabled = 'pin_enabled';
  static const String kPinHash = 'pin_hash';
  static const String kLastBackup = 'last_backup';
  static const String kCurrency = 'currency';
  static const String kOnboarded = 'onboarded';
}
