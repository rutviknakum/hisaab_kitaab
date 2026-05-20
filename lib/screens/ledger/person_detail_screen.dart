import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_colors.dart';
import '../../models/ledger_person_model.dart';
import '../../models/loan_model.dart';
import '../../providers/loan_provider.dart';
import '../../providers/settings_provider.dart';
import 'add_person_screen.dart';
import 'add_loan_screen.dart';
import 'add_payment_screen.dart';

class PersonDetailScreen extends StatelessWidget {
  final LedgerPersonModel person;
  const PersonDetailScreen({super.key, required this.person});

  @override
  Widget build(BuildContext context) {
    return Consumer2<LoanProvider, SettingsProvider>(
      builder: (ctx, loanP, settP, _) {
        final cur = settP.currency;
        final loans = loanP.loansOfPerson(person.id);
        final net = loanP.personNetBalance(person.id);

        return Scaffold(
          appBar: AppBar(
            title: Text(
              person.name,
              style: const TextStyle(
                fontFamily: 'NotoSansGujarati',
                fontWeight: FontWeight.w800,
              ),
            ),
            actions: [
              if (person.phone != null)
                IconButton(
                  icon: const Icon(Icons.call_rounded),
                  onPressed: () => _call(person.phone!),
                  tooltip: 'Call',
                ),
              IconButton(
                icon: const Icon(Icons.edit_rounded),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddPersonScreen(existing: person),
                  ),
                ),
              ),
            ],
          ),
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _PersonHeader(
                  person: person,
                  net: net,
                  currency: cur,
                ),
              ),
              SliverToBoxAdapter(
                child: _NetBalanceSummary(
                  loanP: loanP,
                  personId: person.id,
                  currency: cur,
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      const Text(
                        'Loans',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
              loans.isEmpty
                  ? SliverToBoxAdapter(child: _buildNoLoans(context))
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => _LoanCard(
                          loan: loans[i],
                          loanP: loanP,
                          currency: cur,
                          person: person,
                        ),
                        childCount: loans.length,
                      ),
                    ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          ),
          floatingActionButton: SafeArea(
            child: Material(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(18),
              elevation: 6,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddLoanScreen(personId: person.id),
                  ),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.add, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'લોન ઉમેરો',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'NotoSansGujarati',
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        );
      },
    );
  }

  Widget _buildNoLoans(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Text('📋', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            '${person.name} સાથે કોઈ loan નથી',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'NotoSansGujarati',
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _call(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }
}

// ── Person Header ──────────────────────────────
class _PersonHeader extends StatelessWidget {
  final LedgerPersonModel person;
  final double net;
  final String currency;

  const _PersonHeader({
    required this.person,
    required this.net,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = net >= 0;
    final color = net == 0
        ? AppColors.primary
        : isPositive
            ? AppColors.income
            : AppColors.expense;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: Text(
                person.name[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'NotoSansGujarati',
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  person.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'NotoSansGujarati',
                  ),
                ),
                if (person.phone != null)
                  Text(
                    person.phone!,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                if (person.note != null)
                  Text(
                    person.note!,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 11,
                      fontFamily: 'NotoSansGujarati',
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                net == 0
                    ? 'Clear! ✅'
                    : '$currency${NumberFormat('#,##,##0', 'en_IN').format(net.abs())}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              Text(
                net == 0
                    ? 'બધું clear'
                    : isPositive
                        ? 'મળવાનું'
                        : 'આપવાનું',
                style: const TextStyle(
                  color: Colors.white70,
                  fontFamily: 'NotoSansGujarati',
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Net Balance Summary ────────────────────────
class _NetBalanceSummary extends StatelessWidget {
  final LoanProvider loanP;
  final String personId;
  final String currency;

  const _NetBalanceSummary({
    required this.loanP,
    required this.personId,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final loans = loanP.loansOfPerson(personId);
    if (loans.isEmpty) return const SizedBox.shrink();

    double toReceive = 0;
    double toPay = 0;

    for (final l in loans) {
      final out = loanP.outstandingAmount(l.id);
      if (out <= 0) continue;
      if (l.type == LoanType.gave) {
        toReceive += out;
      } else {
        toPay += out;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (toReceive > 0)
            Expanded(
              child: _SummaryMini(
                label: 'ઉઘરાણી',
                amount: '$currency${_fmt(toReceive)}',
                color: AppColors.income,
                bgColor: AppColors.incomeLight,
                icon: '💸',
              ),
            ),
          if (toReceive > 0 && toPay > 0) const SizedBox(width: 10),
          if (toPay > 0)
            Expanded(
              child: _SummaryMini(
                label: 'ઉધાર',
                amount: '$currency${_fmt(toPay)}',
                color: AppColors.expense,
                bgColor: AppColors.expenseLight,
                icon: '🤲',
              ),
            ),
        ],
      ),
    );
  }

  String _fmt(double v) => NumberFormat('#,##,##0', 'en_IN').format(v);
}

class _SummaryMini extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;
  final Color bgColor;
  final String icon;

  const _SummaryMini({
    required this.label,
    required this.amount,
    required this.color,
    required this.bgColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontFamily: 'NotoSansGujarati',
                  color: color.withOpacity(0.8),
                ),
              ),
              Text(
                amount,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Loan Card ──────────────────────────────────
class _LoanCard extends StatefulWidget {
  final LoanModel loan;
  final LoanProvider loanP;
  final String currency;
  final LedgerPersonModel person;

  const _LoanCard({
    required this.loan,
    required this.loanP,
    required this.currency,
    required this.person,
  });

  @override
  State<_LoanCard> createState() => _LoanCardState();
}

class _LoanCardState extends State<_LoanCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final loan = widget.loan;
    final loanP = widget.loanP;
    final cur = widget.currency;
    final isClosed = loan.status == LoanStatus.closed;
    final isGave = loan.type == LoanType.gave;
    final color = isGave ? AppColors.income : AppColors.expense;
    final outstanding = loanP.outstandingAmount(loan.id);
    final paid = loanP.totalPaid(loan.id);

    final shownInterest =
        loan.paymentStyle == PaymentStyle.fixed && loan.totalMonths > 0
            ? loan.projectedInterest()
            : loan.accruedInterest;

    final totalAmount = loan.principal + shownInterest;

    final progress =
        totalAmount > 0 ? (paid / totalAmount).clamp(0.0, 1.0) : 0.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isClosed ? Colors.grey.withOpacity(0.2) : color.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${loan.type.icon} ${loan.type.label}',
                          style: TextStyle(
                            fontSize: 10,
                            color: color,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'NotoSansGujarati',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          loan.interestType.label,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isClosed
                              ? AppColors.incomeLight
                              : AppColors.warningLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isClosed ? '✅ Closed' : '🔄 Active',
                          style: TextStyle(
                            fontSize: 10,
                            color:
                                isClosed ? AppColors.income : AppColors.warning,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _AmountItem(
                          label: 'Principal',
                          amount: '$cur${_fmt(loan.principal)}',
                          color: Colors.grey.shade700,
                        ),
                      ),
                      Expanded(
                        child: _AmountItem(
                          label: 'વ્યાજ',
                          amount: '$cur${_fmt(shownInterest)}',
                          color: AppColors.warning,
                        ),
                      ),
                      Expanded(
                        child: _AmountItem(
                          label: 'બાકી',
                          amount: '$cur${_fmt(outstanding)}',
                          color: isClosed ? AppColors.income : color,
                          large: true,
                        ),
                      ),
                    ],
                  ),
                  if (!isClosed && totalAmount > 0) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: Colors.grey.withOpacity(0.15),
                              valueColor: AlwaysStoppedAnimation(color),
                              minHeight: 6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(progress * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 11,
                            color: color,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 11, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('dd MMM yyyy').format(loan.startDate),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      if (loan.interestRate > 0) ...[
                        const SizedBox(width: 12),
                        Icon(Icons.percent,
                            size: 11, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          '${loan.interestRate}% ${loan.period.label}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                      const Spacer(),
                      Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: 18,
                        color: Colors.grey.shade400,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            _LoanExpandedSection(
              loan: loan,
              loanP: loanP,
              currency: cur,
              person: widget.person,
            ),
          ],
        ],
      ),
    );
  }

  String _fmt(double v) => NumberFormat('#,##,##0.00', 'en_IN').format(v);
}

class _LoanExpandedSection extends StatelessWidget {
  final LoanModel loan;
  final LoanProvider loanP;
  final String currency;
  final LedgerPersonModel person;

  const _LoanExpandedSection({
    required this.loan,
    required this.loanP,
    required this.currency,
    required this.person,
  });

  @override
  Widget build(BuildContext context) {
    final payments = loanP.paymentsOfLoan(loan.id);
    final isClosed = loan.status == LoanStatus.closed;
    final isFixedEmi =
        loan.paymentStyle == PaymentStyle.fixed && loan.totalMonths > 0;
    final schedule =
        isFixedEmi ? loanP.emiSchedule(loan) : <Map<String, dynamic>>[];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (!isClosed)
                Expanded(
                  child: _ActionBtn(
                    label: 'Payment ઉમેરો',
                    icon: Icons.payments_rounded,
                    color: AppColors.primary,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddPaymentScreen(loan: loan),
                      ),
                    ),
                  ),
                ),
              if (!isClosed) const SizedBox(width: 8),
              Expanded(
                child: _ActionBtn(
                  label: 'Loan Edit',
                  icon: Icons.edit_rounded,
                  color: AppColors.accent,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddLoanScreen(
                        personId: person.id,
                        existing: loan,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _ActionBtn(
                label: 'Delete',
                icon: Icons.delete_rounded,
                color: AppColors.expense,
                onTap: () => _confirmDelete(context),
                compact: true,
              ),
            ],
          ),
          if (isFixedEmi && schedule.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'EMI Schedule',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            const SizedBox(height: 8),
            ...schedule.take(6).map(
                  (emi) => _EmiRow(
                    emi: emi,
                    currency: currency,
                  ),
                ),
            if (schedule.length > 6)
              TextButton(
                onPressed: () => _showFullSchedule(context, schedule),
                child: Text(
                  'બધા ${schedule.length} EMI જુઓ →',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontFamily: 'NotoSansGujarati',
                    fontSize: 12,
                  ),
                ),
              ),
          ],
          if (payments.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const Text(
                  'Payment History',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                const Spacer(),
                Text(
                  '${payments.length} payments',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...payments.map(
              (p) => _PaymentRow(
                payment: p,
                currency: currency,
                onDelete: () => loanP.deletePayment(p.id),
              ),
            ),
          ],
          if (loan.note != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Text('📝', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      loan.note!,
                      style: const TextStyle(
                        fontFamily: 'NotoSansGujarati',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Loan કાઢો?',
          style: TextStyle(fontFamily: 'NotoSansGujarati'),
        ),
        content: const Text(
          'આ loan અને તેના બધા payments ભૂંસાઈ જશે.',
          style: TextStyle(fontFamily: 'NotoSansGujarati'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'ના',
              style: TextStyle(fontFamily: 'NotoSansGujarati'),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expense,
              foregroundColor: Colors.white,
            ),
            child: const Text(
              'હા, કાઢો',
              style: TextStyle(fontFamily: 'NotoSansGujarati'),
            ),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      await loanP.deleteLoan(loan.id);
    }
  }

  void _showFullSchedule(
    BuildContext context,
    List<Map<String, dynamic>> schedule,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (_, ctrl) => Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Full EMI Schedule',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: ctrl,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: schedule.length,
                itemBuilder: (_, i) => _EmiRow(
                  emi: schedule[i],
                  currency: currency,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmiRow extends StatelessWidget {
  final Map<String, dynamic> emi;
  final String currency;

  const _EmiRow({required this.emi, required this.currency});

  @override
  Widget build(BuildContext context) {
    final isPaid = emi['is_paid'] as bool;
    final isOverdue = emi['is_overdue'] as bool;
    final dueDate = emi['due_date'] as DateTime;
    final amount = emi['amount'] as double;
    final month = emi['month'] as int;

    Color statusColor;
    String statusIcon;
    if (isPaid) {
      statusColor = AppColors.income;
      statusIcon = '✅';
    } else if (isOverdue) {
      statusColor = AppColors.expense;
      statusIcon = '⚠️';
    } else {
      statusColor = Colors.grey.shade400;
      statusIcon = '⏳';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isPaid
            ? AppColors.incomeLight.withOpacity(0.4)
            : isOverdue
                ? AppColors.expenseLight
                : Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: statusColor.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Text(statusIcon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'EMI $month',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              Text(
                DateFormat('dd MMM yyyy').format(dueDate),
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            '$currency${NumberFormat('#,##,##0.00', 'en_IN').format(amount)}',
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  final dynamic payment;
  final String currency;
  final VoidCallback onDelete;

  const _PaymentRow({
    required this.payment,
    required this.currency,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.incomeLight.withOpacity(0.4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Text('💳', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                payment.note ?? 'Payment',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontFamily: 'NotoSansGujarati',
                  fontSize: 12,
                ),
              ),
              Text(
                DateFormat('dd MMM yyyy').format(payment.paymentDate),
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
              ),
            ],
          ),
          const Spacer(),
          Text(
            '$currency${NumberFormat('#,##,##0.00', 'en_IN').format(payment.amount)}',
            style: const TextStyle(
              color: AppColors.income,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onDelete,
            child: Icon(Icons.delete_outline,
                size: 16, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}

class _AmountItem extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;
  final bool large;

  const _AmountItem({
    required this.label,
    required this.amount,
    required this.color,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          amount,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: large ? 15 : 13,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool compact;

  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 15),
            if (!compact) ...[
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'NotoSansGujarati',
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
