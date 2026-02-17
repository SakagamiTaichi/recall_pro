import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../config/env_config.dart';
import '../model/ai_judgment_model.dart';
import '../utils/api_exception.dart';
import '../utils/dio_client.dart';

part 'ai_judgment_repository.g.dart';

/// AI判定のリポジトリ
/// Dify APIとの通信を担当
class AiJudgmentRepository {
  static const String _baseUrl = 'https://api.dify.ai/v1';
  static const String _workflowEndpoint = '/workflows/run';

  final Dio _dio;
  final String _apiKey;
  final String _userId;

  AiJudgmentRepository(this._dio, this._apiKey, this._userId);

  /// AI判定を実行
  Future<AiJudgmentModel> judgeAnswer({
    required String question, // 日本語問題文
    required String modelAnswer, // 模範解答（英語）
    required String userAnswer, // ユーザー回答（英語）
  }) async {
    try {
      final response = await _dio.post(
        '$_baseUrl$_workflowEndpoint',
        data: {
          'inputs': {
            'question': question,
            'model_answer': modelAnswer,
            'user_answer': userAnswer,
          },
          'response_mode': 'blocking',
          'user': _userId,
        },
        options: Options(headers: {'Authorization': 'Bearer $_apiKey'}),
      );

      // Dify APIレスポンス構造: { "data": { "outputs": { "output": { ... } } } }
      final outputs =
          response.data['data']['outputs']['output'] as Map<String, dynamic>;
      return AiJudgmentModel.fromJson(outputs);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } on FormatException catch (e) {
      // ignore: avoid_print
      print('[AI JUDGMENT ERROR] FormatException: $e');
      throw ApiException(
        message: 'レスポンスの解析に失敗しました',
        responseData: e.toString(),
      );
    } catch (e, stackTrace) {
      // ignore: avoid_print
      print('[AI JUDGMENT ERROR] Unexpected error: $e');
      // ignore: avoid_print
      print('[AI JUDGMENT ERROR] Stack trace: $stackTrace');
      throw ApiException(
        message: '予期しないエラーが発生しました',
        responseData: e.toString(),
      );
    }
  }
}

/// AiJudgmentRepositoryのプロバイダー
@riverpod
AiJudgmentRepository aiJudgmentRepository(Ref ref) {
  final dio = ref.watch(dioClientProvider);
  return AiJudgmentRepository(dio, EnvConfig.difyApiKey, EnvConfig.fixedUserId);
}
