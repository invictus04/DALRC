import 'dart:developer';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PinataService {
  static Future<String?> uploadFileToPinata(File file) async {
    try {
      final dio = Dio();
      final pinataJwt = dotenv.env['PINATA_JWT_TOKEN'] ?? '';
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: file.path.split('/').last),
      });

      final response = await dio.post(
        'https://api.pinata.cloud/pinning/pinFileToIPFS',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $pinataJwt',
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data['IpfsHash'];
      } else {
        log('Pinata upload failed with status ${response.statusCode}: ${response.data}');
        return null;
      }
    } on DioException catch (e) {
      log('Dio error uploading to Pinata: ${e.response?.statusCode} - ${e.response?.data} || ${e.message}');
      return e.message.toString();
    } catch (e) {
      log('Error uploading to Pinata: $e');
      return e.toString();
    }
  }


  static String getFileUrl(String cid) {
    final gateway = dotenv.env['PINATA_GATEWAY'] ?? 'https://gateway.pinata.cloud';
    return '$gateway/ipfs/$cid';
  }
}
