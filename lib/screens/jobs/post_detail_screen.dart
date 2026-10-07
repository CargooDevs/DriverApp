import 'package:flutter/material.dart';
import 'package:cargoo_shared/cargoo_shared.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;
  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _priceController = TextEditingController();
  Map<String, dynamic>? _post;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final row = await SupabaseService.client.from('posts').select().eq('post_id', widget.postId).maybeSingle();
    if (mounted) setState(() => _post = row);
  }

  Future<void> _propose() async {
    final price = double.tryParse(_priceController.text.replaceAll(',', '.'));
    if (price == null) return;
    setState(() => _sending = true);
    try {
      await SupabaseService.client.from('post_candidates').insert({
        'post_id': widget.postId,
        'driver_id': SupabaseService.uid,
        'proposed_price': price,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Proposta enviada! Aguarde a resposta do cliente.')));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _sending = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Não foi possível enviar: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_post == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final p = _post!;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalhe do pedido')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p['title'] ?? '', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            _InfoRow(icon: Icons.my_location, color: AppColors.success, text: p['pickup_address'] ?? ''),
            const SizedBox(height: 6),
            _InfoRow(icon: Icons.location_on, color: AppColors.error, text: p['dropoff_address'] ?? ''),
            const SizedBox(height: 16),
            if ((p['description'] ?? '').toString().isNotEmpty) ...[
              const Text('Descrição', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(p['description'], style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
            ],
            Wrap(spacing: 8, runSpacing: 8, children: [
              if (p['cargo_weight_kg'] != null) _Chip(text: '${p['cargo_weight_kg']} kg'),
              if (p['needs_helper'] == true) const _Chip(text: 'Precisa de ajudante'),
              if (p['is_fragile'] == true) const _Chip(text: 'Frágil'),
            ]),
            const Spacer(),
            CustomTextField(label: 'Sua proposta de preço (Kz)', hint: 'Ex: 5000', controller: _priceController, prefixIcon: Icons.attach_money, keyboardType: TextInputType.number),
            const SizedBox(height: 14),
            CustomButton(label: 'Enviar proposta', loading: _sending, onPressed: _propose),
          ]),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _InfoRow({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(children: [Icon(icon, size: 18, color: color), const SizedBox(width: 8), Expanded(child: Text(text, style: const TextStyle(fontSize: 13)))]);
  }
}

class _Chip extends StatelessWidget {
  final String text;
  const _Chip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(20)), child: Text(text, style: const TextStyle(fontSize: 11.5)));
  }
}
