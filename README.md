# હિસાબ કિતાબ

ગુજરાતી ભાષામાં બનાવેલ એક સરળ, સુંદર અને ઉપયોગી Flutter એપ, જેમાં રોજિંદા આવક-જાવક, ખાતાં, ઉધાર-ઉઘરાણી અને રિપોર્ટ્સ મેનેજ કરી શકાય છે. એપમાં Provider-based state management, local-first architecture પરથી Supabase-backed sync તરફનું માળખું, અને Gujarati-friendly UI પર ખાસ ધ્યાન આપવામાં આવ્યું છે.

## મુખ્ય વિશેષતાઓ

- આવક અને ખર્ચના વ્યવહારો ઉમેરો, સુધારો અને કાઢી નાખો.
- અલગ-અલગ ખાતાં બનાવો, જેમ કે રોકડ, બૅન્ક, UPI / વૉલેટ.
- કુલ બેલેન્સ, મહિનાવાર આવક અને ખર્ચનો સારાંશ જુઓ.
- ઉધાર-ઉઘરાણી માટે વ્યક્તિઓ, લોન અને પેમેન્ટ્સ મેનેજ કરો.
- EMI અને overdue items જેવી માહિતી track કરો.
- ગુજરાતી UI સાથે સરળ અને mobile-friendly design.
- Refresh આધારિત data reload support.
- Supabase integration માટે તૈયાર database structure.

## Screens

- Home dashboard
- Transactions
- Add income / expense
- Accounts
- Ledger / Loan management
- Reports
- Settings

## Tech Stack

| Layer | Technology |
|------|------------|
| App framework | Flutter |
| Language | Dart |
| State management | Provider |
| Local database | SQLite |
| Cloud backend | Supabase |
| Formatting | intl |
| ID generation | uuid |

## Project Structure

```text
lib/
├── core/
├── database/
├── models/
│   ├── account_model.dart
│   ├── ledger_person_model.dart
│   ├── loan_model.dart
│   ├── loan_payment_model.dart
│   └── transaction_model.dart
├── providers/
│   ├── account_provider.dart
│   ├── loan_provider.dart
│   ├── settings_provider.dart
│   ├── theme_provider.dart
│   └── transaction_provider.dart
├── screens/
├── widgets/
└── main.dart
```

## મુખ્ય Modules

### 1. Transactions
દૈનિક આવક અને ખર્ચ add કરવા, category પ્રમાણે track કરવા અને recent activity જોવા માટે.

### 2. Accounts
ખાતાં પ્રમાણે balance track કરવા માટે, જેમ કે Cash, Bank અને UPI.

### 3. Ledger
કોઈ વ્યક્તિને આપેલું કે લીધેલું ઉધાર manage કરવા માટે.

### 4. Loan Payments
ચુકવણી history, outstanding amount અને EMI schedule track કરવા માટે.

### 5. Reports
મહિનાવાર અને વર્ષવાર analysis માટે data-friendly structure.

## Setup Instructions

### 1. Repository clone કરો

```bash
git clone https://github.com/rutviknakum/hisaab_kitaab.git
cd hisaab_kitaab
```

### 2. Packages install કરો

```bash
flutter pub get
```

### 3. Supabase setup કરો

`main.dart` અથવા config file માં તમારું Supabase URL અને anon key મૂકો.

```dart
const supabaseUrl = 'YOUR_SUPABASE_URL';
const supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```

### 4. Database tables બનાવો

નીચે મુજબ tables જરૂરી છે:

- `profiles`
- `accounts`
- `transactions`
- `ledger_persons`
- `loans`
- `loan_payments`

દરેક table માં `user_id` based data isolation રાખવું યોગ્ય રહેશે.

### 5. App run કરો

```bash
flutter run
```

## Suggested Supabase Schema

આ project માટે નીચેના પ્રકારના columns સામાન્ય રીતે ઉપયોગી છે:

| Table | Important columns |
|------|-------------------|
| accounts | id, user_id, name, type, balance, color, icon, is_active, created_at, updated_at |
| transactions | id, user_id, account_id, type, category, amount, note, date, created_at, updated_at |
| ledger_persons | id, user_id, name, phone, note, created_at, updated_at |
| loans | id, user_id, person_id, type, total_amount, start_date, status, payment_style |
| loan_payments | id, user_id, loan_id, amount, payment_date, towards, note, created_at |

## UI Highlights

- Gujarati typography-friendly interface
- Clean dashboard with balance overview
- Income and expense summary cards
- Ledger summary cards
- Empty states for new users
- Exit confirmation support on home screen

## Current Development Direction

આ project local database થી cloud-backed architecture તરફ આગળ વધી રહ્યું છે. Accounts, transactions અને ledger-related modules ને Supabase સાથે જોડવા માટે structure તૈયાર છે. Multi-user data separation માટે `user_id` based filtering project નો મહત્વનો ભાગ છે.

## Future Improvements

- Authentication flow ને વધુ polish કરવો
- Full Supabase sync અને realtime updates
- Export / backup support
- Charts અને advanced reports
- Search અને filters વધુ શક્તિશાળી બનાવવાં
- Dark mode polish
- Notification reminders for EMI / overdue

## Why this project matters

આ એપ ખાસ કરીને એવા users માટે ઉપયોગી છે જેમને રોજિંદા હિસાબ, ઉધાર-ઉઘરાણી અને personal finance ને પોતાની ભાષામાં manage કરવું છે. Gujarati-first experience આ project ને અલગ ઓળખ આપે છે.

## Contributing

Suggestions, issues અને pull requests welcome છે.

```bash
git checkout -b feature/your-feature-name
```

પછી changes commit કરો અને pull request બનાવો.

## License

This project is intended for personal and educational use unless specified otherwise by the repository owner.
