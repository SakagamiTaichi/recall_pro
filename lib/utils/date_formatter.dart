/// 日付フォーマットのユーティリティクラス
class DateFormatter {
  const DateFormatter._();

  /// 相対的な日付表示（例: 「たった今」「3時間前」「昨日」）
  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        if (diff.inMinutes == 0) {
          return 'たった今';
        }
        return '${diff.inMinutes}分前';
      }
      return '${diff.inHours}時間前';
    } else if (diff.inDays == 1) {
      return '昨日';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}日前';
    }
    return '${date.month}/${date.day}';
  }

  /// シンプルな日付表示（例: 「2024/1/15」）
  static String formatSimple(DateTime date) {
    return '${date.year}/${date.month}/${date.day}';
  }
}
