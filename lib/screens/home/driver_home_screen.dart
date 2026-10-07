import 'package:flutter/material.dart';
import 'package:cargoo_shared/cargoo_shared.dart';
import 'package:intl/intl.dart';
import '../jobs/post_detail_screen.dart';
import '../active/active_ride_screen.dart';
import '../wallet/wallet_screen.dart';
import '../profile/driver_profile_screen.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  bool _online = false;
  int _tab = 1;
  String? _driverName;

  @override
  void initState() {
    super.initState();
    _loadDriverStatus();
  }

  Future<void> _loadDriverStatus() async {
    final driverId = SupabaseService.uid;
    if (driverId == null) return;
    try {
      final driver = await SupabaseService.client
          .from('drivers')
          .select('is_online')
          .eq('driver_id', driverId)
          .maybeSingle();
      if (!mounted || driver == null) return;
      setState(() {
        _online = driver['is_online'] == true;
        _driverName =
            SupabaseService.currentUser?.userMetadata?['name'] as String?;
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Não foi possível carregar o seu estado de disponibilidade.')),
        );
      }
    }
  }

  Future<void> _toggleOnline(bool value) async {
    final driverId = SupabaseService.uid;
    if (driverId == null) return;
    final previous = _online;
    setState(() => _online = value);
    try {
      await SupabaseService.client
          .from('drivers')
          .update({'is_online': value}).eq('driver_id', driverId);
    } catch (_) {
      if (!mounted) return;
      setState(() => _online = previous);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Não foi possível atualizar a disponibilidade.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _DriverOverview(
        name: _driverName ?? 'Motorista',
        online: _online,
        onOnlineChanged: _toggleOnline,
        onSelectTab: (index) => setState(() => _tab = index),
      ),
      const _JobsTab(),
      const WalletScreen(embedded: true),
      DriverProfileScreen(
        embedded: true,
        onOpenWallet: () => setState(() => _tab = 2),
      ),
    ];

    return Scaffold(
      appBar: _tab == 3
          ? null
          : AppBar(
              title: const Text('cargoo.',
                  style: TextStyle(
                      color: AppColors.secondary,
                      fontSize: 25,
                      fontWeight: FontWeight.w800)),
              actions: [
                IconButton(
                  tooltip: 'Notificações',
                  onPressed: () {},
                  icon: const Icon(Icons.notifications_none_rounded,
                      color: AppColors.secondary),
                ),
                const SizedBox(width: 8),
              ],
            ),
      body: IndexedStack(index: _tab, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        backgroundColor: AppColors.surface,
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Início'),
          NavigationDestination(
              icon: Icon(Icons.work_outline),
              selectedIcon: Icon(Icons.work),
              label: 'Pedidos'),
          NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: Icon(Icons.account_balance_wallet),
              label: 'Carteira'),
          NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Conta'),
        ],
      ),
    );
  }
}

class _DriverOverview extends StatelessWidget {
  final String name;
  final bool online;
  final ValueChanged<bool> onOnlineChanged;
  final ValueChanged<int> onSelectTab;

  const _DriverOverview(
      {required this.name,
      required this.online,
      required this.onOnlineChanged,
      required this.onSelectTab});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Text('Olá, $name',
              style: const TextStyle(
                  color: AppColors.secondary,
                  fontSize: 26,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text('Pronto para o próximo trabalho?',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider)),
            child: Row(children: [
              Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                      color:
                          online ? AppColors.success : AppColors.textSecondary,
                      shape: BoxShape.circle)),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(
                      online ? 'Disponível para pedidos' : 'Está offline',
                      style: const TextStyle(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w700))),
              Switch(
                  value: online,
                  activeThumbColor: AppColors.success,
                  onChanged: onOnlineChanged),
            ]),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(20)),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [
                Icon(Icons.local_shipping_outlined,
                    color: AppColors.primary, size: 22),
                SizedBox(width: 8),
                Text('A sua jornada',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 14),
              const Text('Encontre pedidos e faça a sua proposta.',
                  style: TextStyle(
                      color: Color(0xFFB8C2D3), fontSize: 14, height: 1.4)),
              const SizedBox(height: 18),
              SizedBox(
                height: 48,
                child: FilledButton.icon(
                  onPressed: () => onSelectTab(1),
                  style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.secondary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14))),
                  icon: const Icon(Icons.search_rounded),
                  label: const Text('Ver pedidos disponíveis',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 22),
          const Text('Hoje',
              style: TextStyle(
                  color: AppColors.secondary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          const Row(children: [
            Expanded(
                child: _OverviewMetric(
                    icon: Icons.route_outlined, label: 'Viagens', value: '—')),
            SizedBox(width: 12),
            Expanded(
                child: _OverviewMetric(
                    icon: Icons.payments_outlined,
                    label: 'Ganhos',
                    value: '— Kz')),
          ]),
          const SizedBox(height: 22),
          const Text('Acesso rápido',
              style: TextStyle(
                  color: AppColors.secondary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          _QuickLink(
              icon: Icons.work_outline,
              title: 'Quadro de pedidos',
              subtitle: 'Veja cargas e corridas disponíveis',
              onTap: () => onSelectTab(1)),
          _QuickLink(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Carteira',
              subtitle: 'Consulte o saldo e os movimentos',
              onTap: () => onSelectTab(2)),
        ],
      ),
    );
  }
}

class _OverviewMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _OverviewMetric(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: AppColors.primaryDark),
        const SizedBox(height: 14),
        Text(value,
            style: const TextStyle(
                color: AppColors.secondary,
                fontSize: 21,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label,
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      ]),
    );
  }
}

class _QuickLink extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickLink(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
              color: const Color(0xFFFFF1E8),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: AppColors.primaryDark)),
      title: Text(title,
          style: const TextStyle(
              color: AppColors.secondary, fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }
}

class _JobsTab extends StatefulWidget {
  const _JobsTab();

  @override
  State<_JobsTab> createState() => _JobsTabState();
}

class _JobsTabState extends State<_JobsTab>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  List<Map<String, dynamic>> _posts = [];
  List<Map<String, dynamic>> _rides = [];
  Map<String, dynamic>? _activeRide;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _subscribePosts();
    _subscribeRides();
    _checkActiveRide();
  }

  void _subscribePosts() {
    SupabaseService.client
        .from('posts')
        .stream(primaryKey: ['post_id'])
        .eq('status', 'open')
        .listen((rows) {
          if (mounted) {
            setState(() {
              _posts = rows;
              _loading = false;
            });
          }
        });
  }

  void _subscribeRides() {
    SupabaseService.client
        .from('rides')
        .stream(primaryKey: ['ride_id'])
        .eq('status', 'searching')
        .listen((rows) {
          if (mounted) {
            setState(() => _rides =
                rows.where((r) => r['ride_type'] == 'passenger').toList());
          }
        });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkActiveRide() async {
    final driverId = SupabaseService.uid;
    if (driverId == null) return;
    final row = await SupabaseService.client
        .from('rides')
        .select()
        .eq('driver_id', driverId)
        .inFilter('status',
            ['driver_assigned', 'picking_up', 'in_transit']).maybeSingle();
    if (mounted) setState(() => _activeRide = row);
  }

  Future<void> _acceptRide(String rideId) async {
    final driverId = SupabaseService.uid;
    await SupabaseService.client
        .from('rides')
        .update({'driver_id': driverId, 'status': 'driver_assigned'}).eq(
            'ride_id', rideId);
    if (mounted) {
      Navigator.of(context)
          .push(MaterialPageRoute(
              builder: (_) => ActiveRideScreen(rideId: rideId)))
          .then((_) => _checkActiveRide());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_activeRide != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.local_shipping,
                size: 56, color: AppColors.primary),
            const SizedBox(height: 16),
            const Text('Você tem uma entrega em curso',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            CustomButton(
                label: 'Continuar entrega',
                onPressed: () {
                  Navigator.of(context)
                      .push(MaterialPageRoute(
                          builder: (_) => ActiveRideScreen(
                              rideId: _activeRide!['ride_id'])))
                      .then((_) => _checkActiveRide());
                }),
          ]),
        ),
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 4),
        child: Text('Pedidos disponíveis',
            style: TextStyle(
                color: AppColors.secondary,
                fontSize: 24,
                fontWeight: FontWeight.w800)),
      ),
      const Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 14),
        child: Text('Escolha um trabalho e envie a sua proposta.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
              color: const Color(0xFFF4F6F9),
              borderRadius: BorderRadius.circular(14)),
          child: TabBar(
            controller: _tabController,
            dividerColor: Colors.transparent,
            indicator: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x1F12233F),
                      blurRadius: 4,
                      offset: Offset(0, 1))
                ]),
            labelColor: AppColors.secondary,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle:
                const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            tabs: const [Tab(text: 'Cargas'), Tab(text: 'Corridas')],
          ),
        ),
      ),
      const SizedBox(height: 8),
      Expanded(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary))
            : TabBarView(controller: _tabController, children: [
                _posts.isEmpty
                    ? const _EmptyJobs(
                        icon: Icons.inventory_2_outlined,
                        message: 'Nenhum pedido de carga disponível agora.')
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                        itemCount: _posts.length,
                        itemBuilder: (context, i) {
                          final p = _posts[i];
                          return _JobCard(
                            title: p['title'] ?? '',
                            subtitle:
                                '${p['pickup_address'] ?? ''} → ${p['dropoff_address'] ?? ''}',
                            detail: [
                              if (p['cargo_weight_kg'] != null)
                                '${p['cargo_weight_kg']} kg',
                              if (p['is_fragile'] == true) 'Frágil',
                              if (p['needs_helper'] == true)
                                'Precisa de ajudante',
                            ].join(' · '),
                            trailing: 'Propor preço',
                            icon: Icons.inventory_2_outlined,
                            onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => PostDetailScreen(
                                        postId: p['post_id']))),
                          );
                        },
                      ),
                _rides.isEmpty
                    ? const _EmptyJobs(
                        icon: Icons.local_taxi_outlined,
                        message: 'Nenhuma corrida disponível agora.')
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                        itemCount: _rides.length,
                        itemBuilder: (context, i) {
                          final r = _rides[i];
                          return _JobCard(
                            title: r['drop_off'] ?? '',
                            subtitle: 'De: ${r['pick_up'] ?? ''}',
                            detail: r['total_fare'] == null
                                ? 'Corrida de passageiro'
                                : 'Valor estimado · Kz ${NumberFormat('#,##0', 'en_US').format(r['total_fare'])}',
                            trailing: 'Aceitar',
                            icon: Icons.local_taxi_outlined,
                            onTap: () => _acceptRide(r['ride_id']),
                          );
                        },
                      ),
              ]),
      ),
    ]);
  }
}

class _EmptyJobs extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyJobs({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                  color: const Color(0xFFFFF1E8),
                  borderRadius: BorderRadius.circular(20)),
              child: Icon(icon, color: AppColors.primaryDark, size: 30)),
          const SizedBox(height: 14),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 14, height: 1.4)),
        ]),
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String detail;
  final String trailing;
  final IconData icon;
  final VoidCallback onTap;

  const _JobCard({
    required this.title,
    required this.subtitle,
    required this.detail,
    required this.trailing,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.secondary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6F9),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: AppColors.secondary, size: 19),
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          const Icon(Icons.route_outlined,
              size: 18, color: AppColors.primaryDark),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.secondary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ]),
        if (detail.isNotEmpty) ...[
          const SizedBox(height: 7),
          Text(
            detail,
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(0, 42),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.secondary,
              textStyle:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
            onPressed: onTap,
            child: Text(trailing),
          ),
        ),
      ]),
    );
  }
}
