import 'dart:io';
import 'package:dio/dio.dart';

class PinataService {
  static Future<String?> uploadFileToPinata(File file, String jwtToken) async {
    try {
      final dio = Dio();
      
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: file.path.split('/').last),
      });

      final response = await dio.post(
        'https://api.pinata.cloud/pinning/pinFileToIPFS',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $jwtToken',
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data['IpfsHash'];
      } else {
        print('Pinata upload failed with status ${response.statusCode}: ${response.data}');
        return null;
      }
    } on DioException catch (e) {
      print('Dio error uploading to Pinata: ${e.response?.statusCode} - ${e.response?.data} || ${e.message}');
      return null;
    } catch (e) {
      print('Error uploading to Pinata: $e');
      return null;
    }
  }
}
