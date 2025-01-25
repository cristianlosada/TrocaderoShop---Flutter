import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import 'package:crypto/crypto.dart'; // Asegúrate de importar la librería

class PayUService {
  final String apiKey = '4Vj8eK4rloUd272L48hsrarnUA';
  final String apiLogin = 'pRRXKOl8ikMmt9u';
  final String merchantId = '508029';
  final String accountId = '512321';
  final String baseUrl =
      'https://sandbox.api.payulatam.com/payments-api/4.0/service.cgi'; // URL para pruebas

  final String cardNumber = '5120697176068275';
  final String securityCode = '777';
  final String expirationDate = '2025/05';
  final String cardHolderName = 'APPROVED';

  Future<Map<String, dynamic>> createTransaction({
    required String referenceCode,
    required double amount,
    required String currency,
    required String buyerEmail,
    required String buyerName,
  }) async {
    final Map<String, dynamic> payload = {
      "language": "es",
      "command": "SUBMIT_TRANSACTION",
      "merchant": {
        "apiKey": apiKey,
        "apiLogin": apiLogin,
      },
      "transaction": {
        "order": {
          "accountId": accountId,
          "referenceCode": referenceCode,
          "description": "Compra en mi tienda Flutter",
          "language": "es",
          "signature": generateSignature(referenceCode, amount, currency),
          "notifyUrl": "http://www.tuweb.com/confirmacion",
          "additionalValues": {
            "TX_VALUE": {"value": amount, "currency": currency},
          },
          "buyer": {
            "emailAddress": buyerEmail,
            "fullName": buyerName,
          },
        },
        "creditCard": {
          "number": cardNumber, // Número de la tarjeta
          "securityCode": securityCode, // Código de seguridad (CVV)
          "expirationDate":
              expirationDate, // Fecha de expiración en formato AAAA/MM
          "name": cardHolderName, // Nombre del titular
        },
        "type": "AUTHORIZATION_AND_CAPTURE",
        "paymentMethod": "MASTERCARD", // Cambiar según tarjeta de prueba
        "paymentCountry": "CO",
        "ipAddress": "192.168.1.1", // Cambiar si es necesario
      },
      "test": true, // Cambia a false para producción
    };

    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {"Content-Type": "application/json"},
        body: json.encode(payload),
      );
      print('Headers: ${response.headers}');
      print('Body: ${response.body}');
      print('Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Verifica si la respuesta es XML
        if (response.body.startsWith('<')) {
          final parsedXml = xml.XmlDocument.parse(response.body);

          // Extrae el código de estado principal
          final codeElement = parsedXml.findAllElements('code');
          if (codeElement.isNotEmpty && codeElement.first.text == "SUCCESS") {
            // Procesa el estado de la transacción
            final transactionResponse =
                parsedXml.findAllElements('transactionResponse');
            if (transactionResponse.isNotEmpty) {
              final stateElement =
                  transactionResponse.first.findElements('state');
              if (stateElement.isNotEmpty &&
                  stateElement.first.innerText == "APPROVED") {
                String extractElementText(
                    xml.XmlElement element, String tagName) {
                  final tag = element.findElements(tagName);
                  return tag.isNotEmpty
                      ? tag.first.innerText
                      : ''; // Retorna vacío si no se encuentra
                }

                return {
                  "transactionResponse": {
                    "transactionId": extractElementText(
                        transactionResponse.first, 'transactionId'),
                    "state":
                        extractElementText(transactionResponse.first, 'state'),
                    "orderId": extractElementText(
                        transactionResponse.first, 'orderId'),
                    "authorizationCode": extractElementText(
                        transactionResponse.first, 'authorizationCode'),
                    "responseMessage": extractElementText(
                        transactionResponse.first, 'responseMessage'),
                    "operationDate": extractElementText(
                        transactionResponse.first, 'operationDate'),
                  }
                };
              } else {
                final responseCodeElement =
                    transactionResponse.first.findElements('responseCode');
                final responseMessageElement =
                    transactionResponse.first.findElements('responseMessage');
                return {
                  "error": responseMessageElement.isNotEmpty
                      ? responseMessageElement.first.text
                      : "Error en la transacción: ${responseCodeElement.first.text}"
                };
              }
            } else {
              return {
                "error": "No se encontró el elemento 'transactionResponse'"
              };
            }
          } else {
            return {
              "error":
                  "Código no exitoso: ${codeElement.isNotEmpty ? codeElement.first.text : 'desconocido'}"
            };
          }
        } else {
          return {"error": "Formato de respuesta desconocido"};
        }
      } else {
        return {"error": "Error ${response.statusCode}"};
      }
    } catch (e) {
      return {"error": e.toString()};
    }
  }

  String generateSignature(
      String referenceCode, double amount, String currency) {
    final String signaturePlain =
        "$apiKey~$merchantId~$referenceCode~$amount~$currency";
    return md5.convert(utf8.encode(signaturePlain)).toString(); // Usa MD5
  }
}
