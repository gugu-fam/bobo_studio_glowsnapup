import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class UploadResult {
	final String id;
	final String url;

	UploadResult({required this.id, required this.url});

	factory UploadResult.fromJson(Map<String, dynamic> j) => UploadResult(id: j['id'] as String, url: j['url'] as String);
}

class UploadMeta {
	final String? filename;
	final Map<String, String>? tags;

	UploadMeta({this.filename, this.tags});
}

class PhotoStudioService {
	final http.Client _client;
	final Uri endpoint;
	final Duration timeout;

	PhotoStudioService({http.Client? client, Uri? endpoint, Duration? timeout})
			: _client = client ?? http.Client(),
				endpoint = endpoint ?? Uri.parse('https://example.local/api/v1/photos'),
				timeout = timeout ?? const Duration(seconds: 10);

	// Stub: convert image (e.g., resize/encode) and return converted File
	Future<File> convertImage(File input, {int quality = 80}) async {
		// In real implementation, perform conversion. For now return the same file.
		return input;
	}

	// Stub: save edited image to storage. Return true on success.
	Future<bool> saveEditedImage(File edited) async {
		// In real implementation, write to disk or upload. For now pretend success.
		return true;
	}

	// Upload photo to server with multipart/form-data. Returns UploadResult on success.
	// Retries once on 5xx responses.
	Future<UploadResult> uploadPhoto(File file, UploadMeta meta, {String? bearerToken}) async {
		int attempts = 0;
		while (true) {
			attempts += 1;
			try {
				final uri = endpoint;
				final request = http.MultipartRequest('POST', uri);
				if (bearerToken != null) request.headers['Authorization'] = 'Bearer $bearerToken';
				final filename = meta.filename ?? file.path.split(Platform.pathSeparator).last;
				request.files.add(await http.MultipartFile.fromPath('file', file.path, filename: filename));
				if (meta.tags != null) {
					request.fields.addAll(meta.tags!);
				}

				final streamed = await _client.send(request).timeout(timeout);
				final resp = await http.Response.fromStream(streamed);

				if (resp.statusCode >= 200 && resp.statusCode < 300) {
					final body = json.decode(resp.body) as Map<String, dynamic>;
					return UploadResult.fromJson(body);
				}

				if (resp.statusCode >= 500 && attempts < 2) {
					// retry once
					continue;
				}

				// treat 4xx and non-retriable 5xx as error
				throw HttpException('Upload failed: ${resp.statusCode} ${resp.reasonPhrase}');
			} on SocketException catch (e) {
				if (attempts < 2) continue;
				rethrow;
			} on http.ClientException catch (e) {
				if (attempts < 2) continue;
				rethrow;
			} on TimeoutException catch (e) {
				if (attempts < 2) continue;
				rethrow;
			}
		}
	}
}
