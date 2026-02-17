import 'package:freezed_annotation/freezed_annotation.dart';

part 'ai_judgment_model.freezed.dart';
part 'ai_judgment_model.g.dart';

/// AI判定結果モデル
@freezed
class AiJudgmentModel with _$AiJudgmentModel {
  const factory AiJudgmentModel({
    required AiJudgmentType judgment, // correct/partial/incorrect
    required String reason, // 判定理由（日本語）
    @Default([])
    @JsonKey(name: 'suggested_answers')
    List<SuggestedAnswer> suggestedAnswers, // 提案表現リスト
  }) = _AiJudgmentModel;

  factory AiJudgmentModel.fromJson(Map<String, dynamic> json) =>
      _$AiJudgmentModelFromJson(json);
}

/// AI判定タイプ
enum AiJudgmentType {
  @JsonValue('correct')
  correct,
  @JsonValue('partial')
  partial,
  @JsonValue('incorrect')
  incorrect,
}

/// 提案表現
@freezed
class SuggestedAnswer with _$SuggestedAnswer {
  const factory SuggestedAnswer({
    required String sentence, // 英語表現
    required String point, // ポイント（日本語）
  }) = _SuggestedAnswer;

  factory SuggestedAnswer.fromJson(Map<String, dynamic> json) =>
      _$SuggestedAnswerFromJson(json);
}
