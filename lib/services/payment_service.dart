import '../core/supabase_config.dart';

/// NOTA IMPORTANTE:
/// El proyecto original delega el cobro real a un backend propio que habla
/// con Stripe/Mercado Pago. Aquí, sin ese backend, se valida la tarjeta
/// localmente (Luhn) y se registra el pago directo en Supabase.
///
/// Para procesar cobros reales desde Flutter + Supabase, lo correcto es
/// crear una Supabase Edge Function (Deno) que reciba los datos de la
/// tarjeta/payment method y hable con Stripe usando la secret key del
/// lado servidor, y llamarla aquí con `supabase.functions.invoke(...)`.
class PaymentService {
  Future<String> payOrder({
    required int orderId,
    required double amount,
    required String cardNumber,
    required String cardName,
    required String securityCode,
    required String expiry,
  }) async {
    final digits = cardNumber.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 13 || digits.length > 19 || cardName.trim().isEmpty || !_isValidCardNumber(digits)) {
      throw ArgumentError('Tarjeta inválida');
    }

    final cvv = securityCode.replaceAll(RegExp(r'\D'), '');
    if (cvv.length < 3 || cvv.length > 4) {
      throw ArgumentError('CVV inválido');
    }

    final expiryDigits = expiry.replaceAll(RegExp(r'\D'), '');
    if (expiryDigits.length != 4) {
      throw ArgumentError('Fecha de expiración inválida');
    }
    final month = int.tryParse(expiryDigits.substring(0, 2)) ?? 0;
    final yearTwoDigits = int.tryParse(expiryDigits.substring(2, 4)) ?? -1;
    if (month < 1 || month > 12 || yearTwoDigits < 0 || yearTwoDigits > 99) {
      throw ArgumentError('Fecha de expiración inválida');
    }

    final last4 = digits.substring(digits.length - 4);

    // Llamada real recomendada (comentada) a una Edge Function que cobre
    // de verdad contra Stripe/Mercado Pago:
    //
    // final result = await supabase.functions.invoke('charge-order', body: {
    //   'order_id': orderId,
    //   'card_number': digits,
    //   'exp_month': month,
    //   'exp_year': 2000 + yearTwoDigits,
    //   'cvc': cvv,
    // });

    await supabase.from('payments').insert({
      'order_id': orderId,
      'amount': amount,
      'status': 'approved',
      'card_last4': last4,
    });

    return 'Pago aprobado • ****$last4';
  }

  bool _isValidCardNumber(String digitsOnly) {
    var sum = 0;
    var alternate = false;
    for (var i = digitsOnly.length - 1; i >= 0; i--) {
      var n = int.tryParse(digitsOnly[i]);
      if (n == null) return false;
      if (alternate) {
        n *= 2;
        if (n > 9) n -= 9;
      }
      sum += n;
      alternate = !alternate;
    }
    return sum % 10 == 0;
  }
}
