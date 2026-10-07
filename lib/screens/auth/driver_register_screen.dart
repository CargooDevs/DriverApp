import 'package:flutter/material.dart';
import 'package:cargoo_shared/cargoo_shared.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../home/driver_home_screen.dart';

class DriverRegisterScreen extends StatefulWidget {
  const DriverRegisterScreen({super.key});

  @override
  State<DriverRegisterScreen> createState() => _DriverRegisterScreenState();
}

class _DriverRegisterScreenState extends State<DriverRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _licenseController = TextEditingController();
  final _plateController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  VehicleType? _selectedType;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedType = VehicleType.fallback.first;
  }

  Widget _field({
    required String label,
    required String hint,
    required TextEditingController controller,
    IconData? icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(
              color: AppColors.secondary, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        decoration: InputDecoration(
            hintText: hint, prefixIcon: icon == null ? null : Icon(icon)),
        validator: validator,
      ),
    ]);
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // O trigger `on_auth_user_created_driver` (SQL) já cria a linha em
      // `drivers` automaticamente quando user_type = 'driver'.
      final auth = await SupabaseService.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        data: {
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'user_type': 'driver'
        },
      );

      if (auth.user != null) {
        await SupabaseService.client
            .from('drivers')
            .update({'license_number': _licenseController.text.trim()}).eq(
                'driver_id', auth.user!.id);

        if (_plateController.text.trim().isNotEmpty) {
          await SupabaseService.client.from('vehicles').insert({
            'driver_id': auth.user!.id,
            'vehicle_type_id': _selectedType!.id,
            'plate_number': _plateController.text.trim(),
            'brand': _brandController.text.trim(),
            'model': _modelController.text.trim(),
          });
        }
      }

      if (auth.user != null && mounted) {
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const DriverHomeScreen()));
      }
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(
          () => _error = 'Não foi possível criar a conta. Tente novamente.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _licenseController.dispose();
    _plateController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tornar-se motorista',
            style: TextStyle(fontWeight: FontWeight.w700)),
        leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back)),
        backgroundColor: AppColors.surface,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Seu próximo turno começa aqui',
                              style: TextStyle(
                                  color: AppColors.secondary,
                                  fontSize: 26,
                                  height: 1.15,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: 8),
                          const Text(
                              'Preencha os seus dados. A nossa equipa verificará os documentos antes de liberar o modo online.',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                  height: 1.45)),
                          const SizedBox(height: 28),
                          const _RegistrationSectionTitle(
                              title: 'DADOS PESSOAIS'),
                          const SizedBox(height: 14),
                          _field(
                            label: 'Nome completo',
                            hint: 'Como você se chama?',
                            controller: _nameController,
                            icon: Icons.person_outline,
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                    ? 'Informe o seu nome.'
                                    : null,
                          ),
                          const SizedBox(height: 16),
                          _field(
                            label: 'Telefone',
                            hint: '+244 9XX XXX XXX',
                            controller: _phoneController,
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            validator: (value) =>
                                value == null || value.trim().length < 6
                                    ? 'Informe um telefone válido.'
                                    : null,
                          ),
                          const SizedBox(height: 16),
                          _field(
                            label: 'E-mail',
                            hint: 'voce@exemplo.com',
                            controller: _emailController,
                            icon: Icons.mail_outline,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) =>
                                value == null || !value.trim().contains('@')
                                    ? 'Informe um e-mail válido.'
                                    : null,
                          ),
                          const SizedBox(height: 16),
                          _field(
                            label: 'Senha',
                            hint: 'Pelo menos 6 caracteres',
                            controller: _passwordController,
                            icon: Icons.lock_outline,
                            obscureText: true,
                            validator: (value) => value == null ||
                                    value.length < 6
                                ? 'A senha deve ter pelo menos 6 caracteres.'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          _field(
                            label: 'Carta de condução',
                            hint: 'Número do documento',
                            controller: _licenseController,
                            icon: Icons.badge_outlined,
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                    ? 'Informe o número da carta.'
                                    : null,
                          ),
                          const SizedBox(height: 28),
                          const _RegistrationSectionTitle(
                              title: 'O SEU VEÍCULO'),
                          const SizedBox(height: 6),
                          const Text(
                              'Escolha o tipo para receber pedidos compatíveis.',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13)),
                          const SizedBox(height: 14),
                          LayoutBuilder(builder: (context, constraints) {
                            final itemWidth = (constraints.maxWidth - 24) / 4;
                            return Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: VehicleType.fallback.map((vehicle) {
                                  final selected =
                                      vehicle.id == _selectedType?.id;
                                  return SizedBox(
                                    width: itemWidth,
                                    child: ChoiceChip(
                                      avatar: Icon(
                                          Icons.local_shipping_outlined,
                                          size: 17,
                                          color: selected
                                              ? AppColors.primaryDark
                                              : AppColors.secondary),
                                      label: Text(vehicle.name,
                                          overflow: TextOverflow.ellipsis),
                                      selected: selected,
                                      onSelected: (_) => setState(
                                          () => _selectedType = vehicle),
                                      selectedColor: const Color(0xFFFFF1E8),
                                      labelStyle: TextStyle(
                                          color: selected
                                              ? AppColors.primaryDark
                                              : AppColors.secondary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12),
                                      side: BorderSide(
                                          color: selected
                                              ? AppColors.primary
                                              : AppColors.divider),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14)),
                                    ),
                                  );
                                }).toList());
                          }),
                          const SizedBox(height: 16),
                          Row(children: [
                            Expanded(
                                child: _field(
                                    label: 'Marca',
                                    hint: 'Ex.: Toyota',
                                    controller: _brandController)),
                            const SizedBox(width: 12),
                            Expanded(
                                child: _field(
                                    label: 'Modelo',
                                    hint: 'Ex.: Hiace',
                                    controller: _modelController)),
                          ]),
                          const SizedBox(height: 16),
                          _field(
                              label: 'Matrícula',
                              hint: 'LD-00-00-XX',
                              controller: _plateController,
                              icon: Icons.directions_car_outlined),
                          if (_error != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                  color:
                                      AppColors.error.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12)),
                              child: Text(_error!,
                                  style: const TextStyle(
                                      color: AppColors.error, fontSize: 13)),
                            ),
                          ],
                        ]),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(top: BorderSide(color: AppColors.divider))),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      onPressed: _loading ? null : _register,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.secondary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        textStyle: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      child: _loading
                          ? const SizedBox.square(
                              dimension: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.4, color: AppColors.secondary))
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                  Text('Enviar para análise'),
                                  Icon(Icons.arrow_forward)
                                ]),
                    ),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _RegistrationSectionTitle extends StatelessWidget {
  final String title;

  const _RegistrationSectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1));
  }
}
