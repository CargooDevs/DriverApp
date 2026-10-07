import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cargoo_shared/cargoo_shared.dart';

class ActiveRideScreen extends StatefulWidget {
  final String rideId;
  const ActiveRideScreen({super.key, required this.rideId});

  @override
  State<ActiveRideScreen> createState() => _ActiveRideScreenState();
}

class _ActiveRideScreenState extends State<ActiveRideScreen> {
  Ride? _ride;
  Map<String, dynamic>? _client;
  StreamSubscription<List<Map<String, dynamic>>>? _rideSubscription;
  bool _updating = false;

  final _flow = const [
    RideStatus.driverAssigned,
    RideStatus.pickingUp,
    RideStatus.inTransit,
    RideStatus.delivered
  ];

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  void _subscribe() {
    _rideSubscription = SupabaseService.client
        .from('rides')
        .stream(primaryKey: ['ride_id'])
        .eq('ride_id', widget.rideId)
        .listen((rows) async {
          if (rows.isEmpty || !mounted) return;
          final ride = Ride.fromMap(rows.first);
          setState(() => _ride = ride);
          if (_client == null) {
            try {
              final client = await SupabaseService.client
                  .from('users')
                  .select()
                  .eq('user_id', ride.userId)
                  .maybeSingle();
              if (mounted) setState(() => _client = client);
            } catch (_) {
              // The ride remains usable when profile visibility is restricted.
            }
          }
        });
  }

  @override
  void dispose() {
    _rideSubscription?.cancel();
    super.dispose();
  }

  Future<void> _advance() async {
    if (_ride == null || _updating) return;
    final currentIndex = _flow.indexOf(_ride!.status);
    if (currentIndex < 0 || currentIndex >= _flow.length - 1) return;
    final next = _flow[currentIndex + 1];
    setState(() => _updating = true);
    try {
      await SupabaseService.client
          .from('rides')
          .update({'status': next.toDb()}).eq('ride_id', widget.rideId);
      if (next == RideStatus.delivered && mounted) {
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Não foi possível atualizar a viagem. Tente novamente.')),
        );
      }
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  Future<void> _openChat() async {
    final ride = _ride!;
    final convId = ride.convId ??
        await getOrCreateConversation(
            userId: ride.userId, driverId: SupabaseService.uid!);
    if (!mounted) return;
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ChatScreen(
            convId: convId,
            otherPartyName: _client?['name'] ?? 'Cliente',
            isDriver: true,
            otherUserId: ride.userId)));
  }

  String _actionLabel(RideStatus s) {
    switch (s) {
      case RideStatus.driverAssigned:
        return 'Confirmar chegada ao local';
      case RideStatus.pickingUp:
        return 'Iniciar viagem';
      case RideStatus.inTransit:
        return 'Marcar como entregue';
      default:
        return 'Concluído';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_ride == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final ride = _ride!;
    final currentStep = _flow.indexOf(ride.status).clamp(0, _flow.length - 1);
    final isCargo = ride.rideType == RideType.cargo;

    return Scaffold(
      appBar: AppBar(
        title: Text(isCargo ? 'Entrega em curso' : 'Corrida em curso',
            style: const TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            tooltip: 'Abrir conversa',
            onPressed: _openChat,
            icon: const Icon(Icons.chat_bubble_outline),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(20)),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(18)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle)),
                            const SizedBox(width: 7),
                            Text(ride.status.label,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12)),
                          ]),
                        ),
                        const SizedBox(height: 18),
                        Text(_stageTitle(ride.status),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                height: 1.2,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        Text(
                            isCargo
                                ? 'Entrega de carga'
                                : 'Transporte de passageiro',
                            style: const TextStyle(
                                color: Color(0xFFB8C2D3), fontSize: 14)),
                        const SizedBox(height: 22),
                        Row(
                            children: List.generate(_flow.length, (index) {
                          final complete = index <= currentStep;
                          return Expanded(
                              child: Padding(
                            padding: EdgeInsets.only(
                                right: index == _flow.length - 1 ? 0 : 6),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                      height: 4,
                                      decoration: BoxDecoration(
                                          color: complete
                                              ? AppColors.primary
                                              : const Color(0xFF465875),
                                          borderRadius:
                                              BorderRadius.circular(2))),
                                  const SizedBox(height: 7),
                                  Text(_stepLabel(index),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          color: complete
                                              ? Colors.white
                                              : const Color(0xFFB8C2D3),
                                          fontSize: 10,
                                          fontWeight: complete
                                              ? FontWeight.w700
                                              : FontWeight.w400)),
                                ]),
                          ));
                        })),
                      ]),
                ),
                const SizedBox(height: 18),
                Row(children: [
                  const CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.secondary,
                      child: Icon(Icons.person_outline, color: Colors.white)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(_client?['name'] ?? 'Cliente',
                            style: const TextStyle(
                                color: AppColors.secondary,
                                fontSize: 16,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        const Text('Cliente',
                            style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 13)),
                      ])),
                  IconButton.filledTonal(
                      onPressed: _openChat,
                      tooltip: 'Conversar com o cliente',
                      icon: const Icon(Icons.chat_bubble_outline)),
                ]),
                const SizedBox(height: 18),
                _RouteCard(
                    pickUp: ride.pickUp,
                    dropOff: ride.dropOff,
                    currentStep: currentStep),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: const Color(0xFFFFF1E8),
                      borderRadius: BorderRadius.circular(16)),
                  child: Row(children: [
                    Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(13)),
                        child: const Icon(Icons.payments_outlined,
                            color: AppColors.primaryDark)),
                    const SizedBox(width: 12),
                    const Expanded(
                        child: Text('Valor da viagem',
                            style: TextStyle(
                                color: AppColors.secondary,
                                fontWeight: FontWeight.w600))),
                    Text('Kz ${ride.totalFare.toStringAsFixed(0)}',
                        style: const TextStyle(
                            color: AppColors.secondary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800)),
                  ]),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
            decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.divider))),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: _updating ? null : _advance,
                style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.secondary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                child: _updating
                    ? const SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.4, color: AppColors.secondary))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                            Text(_actionLabel(ride.status)),
                            const Icon(Icons.arrow_forward)
                          ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  String _stageTitle(RideStatus status) {
    switch (status) {
      case RideStatus.driverAssigned:
        return 'A caminho da recolha';
      case RideStatus.pickingUp:
        return 'Confirme a recolha';
      case RideStatus.inTransit:
        return 'A caminho do destino';
      case RideStatus.delivered:
        return 'Viagem concluída';
      default:
        return status.label;
    }
  }

  String _stepLabel(int index) =>
      const ['Recolha', 'A recolher', 'Em trânsito', 'Concluído'][index];
}

class _RouteCard extends StatelessWidget {
  final String pickUp;
  final String dropOff;
  final int currentStep;

  const _RouteCard(
      {required this.pickUp, required this.dropOff, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final currentAddress = currentStep < 2 ? pickUp : dropOff;
    final caption = currentStep < 2 ? 'Local de recolha' : 'Local de entrega';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider)),
      child: Column(children: [
        Row(children: [
          const Icon(Icons.my_location, color: AppColors.success, size: 20),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                const Text('RECOLHA',
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(pickUp,
                    style: const TextStyle(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w600))
              ])),
        ]),
        Padding(
            padding: const EdgeInsets.only(left: 9),
            child: Align(
                alignment: Alignment.centerLeft,
                child:
                    Container(width: 2, height: 22, color: AppColors.divider))),
        Row(children: [
          const Icon(Icons.location_on_outlined,
              color: AppColors.primaryDark, size: 20),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                const Text('DESTINO',
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(dropOff,
                    style: const TextStyle(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w600))
              ])),
        ]),
        const SizedBox(height: 14),
        Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: const Color(0xFFF4F6F9),
                borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              const Icon(Icons.near_me_outlined,
                  color: AppColors.primaryDark, size: 18),
              const SizedBox(width: 8),
              Expanded(
                  child: Text('$caption: $currentAddress',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500)))
            ])),
      ]),
    );
  }
}
