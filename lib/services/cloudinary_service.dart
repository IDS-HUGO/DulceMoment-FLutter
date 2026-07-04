import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

/// Servicio para subir imágenes a Cloudinary.
///
/// Credenciales obtenidas del dashboard de Cloudinary.
/// Para mayor seguridad en producción, mueve estos valores a variables de
/// entorno o a un backend; no los incluyas en el código de la app publicada.
class CloudinaryService {
  static const _cloudName = 'xp7hpq2a';
  static const _apiKey = '791732821681932';
  static const _apiSecret = '6h7t4_6PeTCt_vPCak50vr8pVlY';
  static const _uploadPreset = 'dulce_moment'; // unsigned preset (opcional)

  // URL base de la API de upload
  static String get _uploadUrl =>
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';

  /// Sube un [File] de imagen a Cloudinary y devuelve la URL pública.
  /// Lanza [Exception] si algo falla.
  static Future<String> uploadImage(File imageFile) async {
    // Usamos upload firmado para mayor seguridad
    final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();

    // Firma: sha1("timestamp=<ts><apiSecret>")
    final signatureStr = 'timestamp=$timestamp$_apiSecret';
    final signature = sha1
        .convert(utf8.encode(signatureStr))
        .toString();

    final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));
    request.fields['api_key'] = _apiKey;
    request.fields['timestamp'] = timestamp;
    request.fields['signature'] = signature;
    request.fields['folder'] = 'dulce_moment/products';

    final imageBytes = await imageFile.readAsBytes();
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: 'product_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ),
    );

    final streamedResponse = await request.send().timeout(
      const Duration(seconds: 30),
      onTimeout: () => throw Exception('La subida de imagen tardó demasiado'),
    );
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(
          'Error Cloudinary (${response.statusCode}): ${body['error']?['message'] ?? response.body}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final secureUrl = json['secure_url'] as String?;
    if (secureUrl == null || secureUrl.isEmpty) {
      throw Exception('Cloudinary no devolvió una URL válida');
    }
    return secureUrl;
  }
}
