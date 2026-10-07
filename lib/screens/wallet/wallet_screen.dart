import 'package:flutter/material.dart';
import 'package:cargoo_shared/cargoo_shared.dart';
import 'package:intl/intl.dart';

class WalletScreen extends StatefulWidget {
  final bool embedded;
  const WalletScreen({super.key, this.embedded = false});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  double _balance = 0;
  List<DriverCashLedgerEntry> _entries = [];
  bool _loading = true;
  int _period = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final driverId = SupabaseService.uid;
      if (driverId == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      final driver = await SupabaseService.client
          .from('drivers')
          .select('driver_cash_bal')
          .eq('driver_id', driverId)
          .maybeSingle();
      final rows = await SupabaseService.client
          .from('driver_cash_ledger')
          .select()
          .eq('driver_id', driverId)
          .order('date', ascending: false);
      if (mounted) {
        setState(() {
          _balance = (driver?['driver_cash_bal'] as num?)?.toDouble() ?? 0;
          _entries = (rows as List)
              .map((r) =>
                  DriverCashLedgerEntry.fromMap(r as Map<String, dynamic>))
              .toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  DateTime _periodStart(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    if (_period == 0) return today;
    if (_period == 1) return today.subtract(Duration(days: today.weekday - 1));
    return DateTime(now.year, now.month);
  }

  List<DriverCashLedgerEntry> get _periodEntries {
    final start = _periodStart(DateTime.now());
    return _entries
        .where((entry) => entry.date != null && !entry.date!.isBefore(start))
        .toList();
  }

  double get _periodNet =>
      _periodEntries.fold(0, (total, entry) => total + entry.amount);

  String get _periodLabel {
    switch (_period) {
      case 0:
        return 'Hoje';
      case 1:
        return 'Esta semana';
      default:
        return 'Este mês';
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredEntries = _periodEntries;
    final content = _loading
        ? const Center(
            child: CircularProgressIndicator(color: AppColors.primary))
        : RefreshIndicator(
            onRefresh: _load,
            color: AppColors.primary,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                const Text('Ganhos',
                    style: TextStyle(
                        color: AppColors.secondary,
                        fontSize: 28,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                      color: const Color(0xFFF4F6F9),
                      borderRadius: BorderRadius.circular(14)),
                  child: Row(
                      children: List.generate(3, (index) {
                    final selected = _period == index;
                    return Expanded(
                        child: GestureDetector(
                      onTap: () => setState(() => _period = index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        height: 42,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            color: selected ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: selected
                                ? const [
                                    BoxShadow(
                                        color: Color(0x1F12233F),
                                        blurRadius: 4,
                                        offset: Offset(0, 1))
                                  ]
                                : null),
                        child: Text(const ['Hoje', 'Semana', 'Mês'][index],
                            style: TextStyle(
                                color: selected
                                    ? AppColors.secondary
                                    : AppColors.textSecondary,
                                fontSize: 14,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500)),
                      ),
                    ));
                  })),
                ),
                const SizedBox(height: 24),
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(
                      '${_periodNet < 0 ? '-' : ''}${NumberFormat('#,##0', 'en_US').format(_periodNet.abs())}',
                      style: const TextStyle(
                          color: AppColors.secondary,
                          fontSize: 38,
                          height: 1,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(width: 8),
                  const Padding(
                      padding: EdgeInsets.only(bottom: 3),
                      child: Text('Kz',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 17))),
                ]),
                const SizedBox(height: 7),
                Text('Variação líquida · $_periodLabel',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 14)),
                const SizedBox(height: 20),
                _LedgerChart(entries: filteredEntries),
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(18)),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Saldo atual',
                            style: TextStyle(
                                color: Color(0xFFB8C2D3), fontSize: 13)),
                        const SizedBox(height: 6),
                        Text(
                            'Kz ${NumberFormat('#,##0', 'en_US').format(_balance)}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        const Text('Disponível na sua carteira Cargoo',
                            style: TextStyle(
                                color: Color(0xFFB8C2D3), fontSize: 12)),
                      ]),
                ),
                const SizedBox(height: 24),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Movimentos',
                          style: TextStyle(
                              color: AppColors.secondary,
                              fontSize: 18,
                              fontWeight: FontWeight.w700)),
                      Text('${filteredEntries.length}',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 13)),
                    ]),
                const SizedBox(height: 10),
                if (filteredEntries.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 28),
                    decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.divider)),
                    child: const Column(children: [
                      Icon(Icons.receipt_long_outlined,
                          color: AppColors.textSecondary, size: 28),
                      SizedBox(height: 10),
                      Text('Sem movimentos neste período.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 13)),
                    ]),
                  )
                else
                  ...filteredEntries.map((entry) => _LedgerTile(entry: entry)),
              ],
            ),
          );

    if (widget.embedded) {
      return SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: content),
        ]),
      );
    }
    return Scaffold(
        appBar: AppBar(title: const Text('Carteira')), body: content);
  }
}

class _LedgerChart extends StatelessWidget {
  final List<DriverCashLedgerEntry> entries;

  const _LedgerChart({required this.entries});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weekStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final dailyTotals = List<double>.generate(7, (index) {
      final day = weekStart.add(Duration(days: index));
      return entries.where((entry) {
        final date = entry.date;
        return date != null &&
            date.year == day.year &&
            date.month == day.month &&
            date.day == day.day;
      }).fold(0, (total, entry) => total + entry.amount.abs());
    });
    final maxValue = dailyTotals.fold<double>(
        0, (maximum, amount) => amount > maximum ? amount : maximum);
    const labels = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

    return SizedBox(
      height: 146,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (index) {
          final amount = dailyTotals[index];
          final barHeight = maxValue == 0 ? 8.0 : 16 + (amount / maxValue * 82);
          final day = weekStart.add(Duration(days: index));
          final isToday = DateTime(now.year, now.month, now.day) == day;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        height: barHeight,
                        decoration: BoxDecoration(
                          color: isToday
                              ? AppColors.primary
                              : const Color(0xFFCCD3DD),
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(7)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    labels[index],
                    style: TextStyle(
                      color: isToday
                          ? AppColors.secondary
                          : AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _LedgerTile extends StatelessWidget {
  final DriverCashLedgerEntry entry;

  const _LedgerTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final positive = entry.amount >= 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider)),
      child: Row(children: [
        Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: positive
                    ? const Color(0xFFE7F4EC)
                    : const Color(0xFFFDECEA),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(
                positive ? Icons.south_west_rounded : Icons.north_east_rounded,
                color: positive ? AppColors.success : AppColors.error,
                size: 19)),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(positive ? 'Crédito' : 'Débito',
              style: const TextStyle(
                  color: AppColors.secondary, fontWeight: FontWeight.w700)),
          if (entry.date != null) ...[
            const SizedBox(height: 3),
            Text(DateFormat('dd/MM/yyyy · HH:mm').format(entry.date!),
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 11)),
          ],
        ])),
        Text(
            '${positive ? '+' : '-'} Kz ${NumberFormat('#,##0', 'en_US').format(entry.amount.abs())}',
            style: TextStyle(
                color: positive ? AppColors.success : AppColors.error,
                fontSize: 13,
                fontWeight: FontWeight.w700)),
      ]),
    );
  }
}
