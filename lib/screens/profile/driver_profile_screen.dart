import 'package:flutter/material.dart';
import 'package:cargoo_shared/cargoo_shared.dart';
import '../auth/driver_login_screen.dart';

class DriverProfileScreen extends StatefulWidget {
  final bool embedded;
  final VoidCallback? onOpenWallet;

  const DriverProfileScreen(
      {super.key, this.embedded = false, this.onOpenWallet});

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  Map<String, dynamic>? _driver;
  Map<String, dynamic>? _vehicle;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final driverId = SupabaseService.uid;
    if (driverId == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    try {
      final driver = await SupabaseService.client
          .from('drivers')
          .select('full_name, phone, email, license_number, status, fleet_id')
          .eq('driver_id', driverId)
          .maybeSingle();
      final vehicle = await SupabaseService.client
          .from('vehicles')
          .select('vehicle_type_id, plate_number, brand, model, year')
          .eq('driver_id', driverId)
          .limit(1)
          .maybeSingle();
      if (mounted) {
        setState(() {
          _driver = driver;
          _vehicle = vehicle;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String get _name {
    final fullName = _driver?['full_name'] as String?;
    final metadataName =
        SupabaseService.currentUser?.userMetadata?['name'] as String?;
    return (fullName?.trim().isNotEmpty ?? false)
        ? fullName!.trim()
        : metadataName ?? 'Motorista Cargoo';
  }

  String get _phone =>
      _driver?['phone'] as String? ??
      SupabaseService.currentUser?.userMetadata?['phone'] as String? ??
      SupabaseService.currentUser?.email ??
      '';

  String get _status {
    switch (_driver?['status'] as String? ?? 'pending') {
      case 'verified':
        return 'Motorista verificado';
      case 'rejected':
        return 'Verificação recusada';
      case 'suspended':
        return 'Conta suspensa';
      default:
        return 'Verificação pendente';
    }
  }

  Color get _statusColor => _driver?['status'] == 'verified'
      ? AppColors.success
      : _driver?['status'] == 'rejected' || _driver?['status'] == 'suspended'
          ? AppColors.error
          : AppColors.warning;

  void _showDocuments() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Documentos',
                    style: TextStyle(
                        color: AppColors.secondary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 18),
                const Text('Carta de condução',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                    (_driver?['license_number'] as String?)
                                ?.trim()
                                .isNotEmpty ==
                            true
                        ? _driver!['license_number'] as String
                        : 'Ainda não informado',
                    style: const TextStyle(
                        color: AppColors.secondary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                Row(children: [
                  Icon(Icons.circle, size: 9, color: _statusColor),
                  const SizedBox(width: 8),
                  Text(_status,
                      style: TextStyle(
                          color: _statusColor, fontWeight: FontWeight.w700))
                ]),
              ]),
        ),
      ),
    );
  }

  void _showSupport() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.support_agent,
            color: AppColors.primaryDark, size: 30),
        title: const Text('Ajuda e suporte'),
        content: const Text(
            'Para obter ajuda com a sua conta ou veículo, contacte a equipa Cargoo pelos canais oficiais de suporte.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fechar'))
        ],
      ),
    );
  }

  Future<void> _signOut() async {
    try {
      await SupabaseService.client.auth.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const DriverLoginScreen()),
          (route) => false,
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Não foi possível terminar a sessão. Tente novamente.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehicleTitle = _vehicle == null
        ? 'Veículo não cadastrado'
        : '${_vehicle!['brand'] ?? ''} ${_vehicle!['model'] ?? ''}'.trim();
    final vehicleType = VehicleType.fallback
        .where((type) => type.id == _vehicle?['vehicle_type_id'])
        .firstOrNull;

    final content = _loading
        ? const Center(
            child: CircularProgressIndicator(color: AppColors.primary))
        : SafeArea(
            top: !widget.embedded,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                const Text('Conta',
                    style: TextStyle(
                        color: AppColors.secondary,
                        fontSize: 28,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 22),
                Row(children: [
                  CircleAvatar(
                      radius: 34,
                      backgroundColor: AppColors.secondary,
                      child: Text(_initials(_name),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700))),
                  const SizedBox(width: 14),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(_name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: AppColors.secondary,
                                fontSize: 19,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text(_phone,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 13)),
                        const SizedBox(height: 8),
                        _StatusLabel(label: _status, color: _statusColor),
                      ])),
                ]),
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: const Color(0xFFF4F6F9),
                      borderRadius: BorderRadius.circular(18)),
                  child: Row(children: [
                    Container(
                        width: 62,
                        height: 56,
                        decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(13)),
                        child: Icon(
                            vehicleType?.icon ?? Icons.local_shipping_outlined,
                            color: AppColors.secondary,
                            size: 34)),
                    const SizedBox(width: 14),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(
                              vehicleTitle.isEmpty
                                  ? 'Veículo não cadastrado'
                                  : vehicleTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 3),
                          Text(
                              vehicleType?.name ??
                                  'Adicione os dados do veículo',
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13)),
                          if (_vehicle?['plate_number'] != null) ...[
                            const SizedBox(height: 8),
                            Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    border:
                                        Border.all(color: AppColors.secondary),
                                    borderRadius: BorderRadius.circular(8)),
                                child: Text(_vehicle!['plate_number'] as String,
                                    style: const TextStyle(
                                        color: AppColors.secondary,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5))),
                          ],
                        ])),
                  ]),
                ),
                const SizedBox(height: 20),
                _AccountTile(
                    icon: Icons.description_outlined,
                    title: 'Documentos',
                    subtitle: _status,
                    onTap: _showDocuments),
                _AccountTile(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Pagamentos e carteira',
                    subtitle: 'Saldo e movimentos',
                    onTap: widget.onOpenWallet),
                _AccountTile(
                    icon: Icons.groups_outlined,
                    title: 'Frota',
                    subtitle: _driver?['fleet_id'] == null
                        ? 'Motorista independente'
                        : 'Associado a uma frota',
                    onTap: () => _showInfo(
                        'Frota',
                        _driver?['fleet_id'] == null
                            ? 'A sua conta está registada como motorista independente.'
                            : 'ID da frota: ${_driver!['fleet_id']}')),
                _AccountTile(
                    icon: Icons.support_agent_outlined,
                    title: 'Ajuda e suporte',
                    onTap: _showSupport),
                const SizedBox(height: 16),
                TextButton.icon(
                    onPressed: _signOut,
                    icon: const Icon(Icons.logout),
                    label: const Text('Terminar sessão'),
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.error,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 12),
                        textStyle: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700))),
              ],
            ),
          );

    if (widget.embedded) return content;
    return Scaffold(appBar: AppBar(title: const Text('Conta')), body: content);
  }

  String _initials(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'M';
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }

  void _showInfo(String title, String message) {
    showDialog<void>(
        context: context,
        builder: (context) =>
            AlertDialog(title: Text(title), content: Text(message), actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Fechar'))
            ]));
  }
}

class _StatusLabel extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusLabel({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w700)),
        ]),
      );
}

class _AccountTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  const _AccountTile(
      {required this.icon, required this.title, this.subtitle, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
      leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
              color: const Color(0xFFF4F6F9),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: AppColors.secondary)),
      title: Text(title,
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.secondary)),
      subtitle: subtitle == null
          ? null
          : Text(subtitle!,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }
}
