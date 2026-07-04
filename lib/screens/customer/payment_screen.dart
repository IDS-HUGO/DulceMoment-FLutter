import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../models/order.dart';
import '../../state/orders_provider.dart';

class PaymentScreen extends StatefulWidget {
  final CakeOrder order;
  const PaymentScreen({super.key, required this.order});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _cardNameController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  bool _isSubmitting = false;
  bool _obscureCvv = true;
  String _cardType = '';

  late AnimationController _cardFlipCtrl;
  late Animation<double> _cardFlipAnim;

  @override
  void initState() {
    super.initState();
    _cardFlipCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _cardFlipAnim = CurvedAnimation(
        parent: _cardFlipCtrl, curve: Curves.easeInOut);
    _cardNumberController.addListener(_onCardNumberChanged);
    _cvvController.addListener(_onCvvFocus);
  }

  void _onCardNumberChanged() {
    final digits = _cardNumberController.text.replaceAll(RegExp(r'\D'), '');
    String type = '';
    if (digits.startsWith('4')) type = 'Visa';
    else if (digits.startsWith('5') || digits.startsWith('2')) type = 'MasterCard';
    else if (digits.startsWith('3')) type = 'Amex';
    if (type != _cardType) setState(() => _cardType = type);
  }

  void _onCvvFocus() {
    // Se podría usar FocusNode; aquí usamos cambio de texto como proxy
  }

  @override
  void dispose() {
    _cardNumberController.removeListener(_onCardNumberChanged);
    _cardNumberController.dispose();
    _cardNameController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cardFlipCtrl.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final ordersProvider = context.read<OrdersProvider>();
    final message = await ordersProvider.payOrder(
      order: widget.order,
      cardNumber: _cardNumberController.text,
      cardName: _cardNameController.text,
      securityCode: _cvvController.text,
      expiry: _expiryController.text,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (message != null) {
      Navigator.of(context).pop();
      DulceWidgets.showSuccess(context, message);
    } else {
      DulceWidgets.showError(
          context,
          ordersProvider.errorMessage ?? 'No se pudo procesar el pago');
    }
  }

  String _formatCardDisplay() {
    final digits = _cardNumberController.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return '•••• •••• •••• ••••';
    final padded = digits.padRight(16, '•');
    final groups = [
      padded.substring(0, 4),
      padded.substring(4, 8),
      padded.substring(8, 12),
      padded.substring(12, 16),
    ];
    return groups.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isWide = size.width > 600;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [DulceColors.cream, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // AppBar custom
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: DulceColors.chocolate.withOpacity(0.1),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.arrow_back_rounded,
                            color: DulceColors.chocolate, size: 20),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pago seguro',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: DulceColors.chocolateDark,
                          ),
                        ),
                        Text(
                          'Pedido #${widget.order.id}',
                          style: TextStyle(
                            fontSize: 12,
                            color: DulceColors.chocolateLight,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    const Icon(Icons.lock_rounded,
                        color: DulceColors.success, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      'SSL',
                      style: const TextStyle(
                        fontSize: 11,
                        color: DulceColors.success,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWide ? size.width * 0.2 : 20,
                    vertical: 12,
                  ),
                  child: Column(
                    children: [
                      // Tarjeta visual animada
                      AnimatedBuilder(
                        animation: _cardFlipAnim,
                        builder: (_, __) => _CreditCardVisual(
                          cardNumber: _formatCardDisplay(),
                          cardName: _cardNameController.text.isEmpty
                              ? 'NOMBRE APELLIDO'
                              : _cardNameController.text.toUpperCase(),
                          expiry: _expiryController.text.isEmpty
                              ? 'MM/YY'
                              : _expiryController.text,
                          cardType: _cardType,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Total
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: DulceColors.gradientPrimary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total a pagar',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  'Pago único',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '\$${widget.order.total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Formulario
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: DulceColors.chocolate.withOpacity(0.08),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _FieldLabel(
                                  icon: Icons.credit_card_rounded,
                                  label: 'Número de tarjeta'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _cardNumberController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(19),
                                  _CardNumberFormatter(),
                                ],
                                decoration: InputDecoration(
                                  hintText: '0000 0000 0000 0000',
                                  suffixIcon: _cardType.isNotEmpty
                                      ? Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Text(
                                            _cardType,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: DulceColors.chocolate,
                                            ),
                                          ),
                                        )
                                      : null,
                                ),
                                validator: (v) {
                                  final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
                                  return (digits.length < 13 || digits.length > 19)
                                      ? 'Número inválido'
                                      : null;
                                },
                              ),
                              const SizedBox(height: 16),
                              const _FieldLabel(
                                  icon: Icons.person_outline_rounded,
                                  label: 'Nombre en la tarjeta'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _cardNameController,
                                textCapitalization: TextCapitalization.characters,
                                decoration: const InputDecoration(
                                  hintText: 'Como aparece en tu tarjeta',
                                ),
                                validator: (v) => (v == null || v.trim().isEmpty)
                                    ? 'Requerido'
                                    : null,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const _FieldLabel(
                                            icon:
                                                Icons.calendar_today_outlined,
                                            label: 'Vencimiento'),
                                        const SizedBox(height: 8),
                                        TextFormField(
                                          controller: _expiryController,
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                            LengthLimitingTextInputFormatter(4),
                                            _ExpiryFormatter(),
                                          ],
                                          decoration: const InputDecoration(
                                              hintText: 'MM/YY'),
                                          validator: (v) {
                                            final digits = (v ?? '')
                                                .replaceAll(RegExp(r'\D'), '');
                                            if (digits.length != 4) {
                                              return 'Formato MM/YY';
                                            }
                                            final month =
                                                int.tryParse(digits.substring(0, 2)) ?? 0;
                                            final year =
                                                int.tryParse(digits.substring(2, 4)) ?? -1;
                                            if (month < 1 || month > 12) {
                                              return 'Mes inválido';
                                            }
                                            final currentYear =
                                                DateTime.now().year % 100;
                                            final currentMonth =
                                                DateTime.now().month;
                                            if (year < currentYear ||
                                                (year == currentYear &&
                                                    month < currentMonth)) {
                                              return 'Tarjeta vencida';
                                            }
                                            return null;
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const _FieldLabel(
                                            icon: Icons.lock_outline_rounded,
                                            label: 'CVV'),
                                        const SizedBox(height: 8),
                                        TextFormField(
                                          controller: _cvvController,
                                          keyboardType: TextInputType.number,
                                          obscureText: _obscureCvv,
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                            LengthLimitingTextInputFormatter(4),
                                          ],
                                          decoration: InputDecoration(
                                            hintText: '•••',
                                            suffixIcon: IconButton(
                                              icon: Icon(_obscureCvv
                                                  ? Icons.visibility_outlined
                                                  : Icons.visibility_off_outlined),
                                              onPressed: () => setState(() =>
                                                  _obscureCvv = !_obscureCvv),
                                            ),
                                          ),
                                          validator: (v) {
                                            final digits = (v ?? '')
                                                .replaceAll(RegExp(r'\D'), '');
                                            return (digits.length < 3 ||
                                                    digits.length > 4)
                                                ? 'CVV inválido'
                                                : null;
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Info de seguridad
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.security_rounded,
                              size: 14, color: DulceColors.chocolateLight),
                          const SizedBox(width: 5),
                          Text(
                            'Tus datos están protegidos con cifrado SSL',
                            style: TextStyle(
                              fontSize: 12,
                              color: DulceColors.chocolateLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Botón de pago
                      _PayButton(
                        onPressed: _isSubmitting ? null : _pay,
                        isLoading: _isSubmitting,
                        amount: widget.order.total,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreditCardVisual extends StatelessWidget {
  final String cardNumber;
  final String cardName;
  final String expiry;
  final String cardType;

  const _CreditCardVisual({
    required this.cardNumber,
    required this.cardName,
    required this.expiry,
    required this.cardType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 190,
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3E2723), Color(0xFF6D4C41), Color(0xFF8D6E63)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: DulceColors.chocolateDark.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Círculos decorativos
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            right: 20,
            top: 20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          ),
          // Contenido
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.credit_card_rounded,
                      color: Colors.white60, size: 28),
                  if (cardType.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        cardType,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
              Text(
                cardNumber,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  fontFamily: 'monospace',
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Titular',
                          style:
                              TextStyle(color: Colors.white54, fontSize: 10)),
                      Text(
                        cardName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Vence',
                          style:
                              TextStyle(color: Colors.white54, fontSize: 10)),
                      Text(
                        expiry,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FieldLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: DulceColors.chocolateLight),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: DulceColors.chocolateLight,
          ),
        ),
      ],
    );
  }
}

class _PayButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final double amount;

  const _PayButton({
    required this.onPressed,
    required this.isLoading,
    required this.amount,
  });

  @override
  State<_PayButton> createState() => _PayButtonState();
}

class _PayButtonState extends State<_PayButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          height: 58,
          decoration: BoxDecoration(
            gradient: widget.onPressed == null
                ? LinearGradient(
                    colors: [Colors.grey.shade300, Colors.grey.shade400])
                : DulceColors.gradientPrimary,
            borderRadius: BorderRadius.circular(14),
            boxShadow: widget.onPressed != null
                ? [
                    BoxShadow(
                      color: DulceColors.chocolate.withOpacity(0.5),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    )
                  ]
                : [],
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white))
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock_rounded,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Pagar \$${widget.amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Formateador de número de tarjeta con espacios
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// Formateador de fecha de vencimiento MM/YY
class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    String text = digits;
    if (digits.length >= 3) {
      text = '${digits.substring(0, 2)}/${digits.substring(2)}';
    } else if (digits.length == 2) {
      // Si el usuario borra, no agregamos barra
      if (oldValue.text.length > newValue.text.length) {
        text = digits;
      } else {
        text = '$digits/';
      }
    }
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
