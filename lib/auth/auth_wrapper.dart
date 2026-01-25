import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'auth_service.dart';

/// 認証状態に応じて表示を切り替えるラッパーWidget
class AuthWrapper extends ConsumerWidget {
  final Widget child;

  const AuthWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          // ログインしていない場合は自動的に匿名ログイン
          return const _AutoSignInScreen();
        }
        // ログイン済みの場合は子Widgetを表示
        return child;
      },
      loading: () => const _LoadingScreen(),
      error: (error, stack) => _ErrorScreen(error: error),
    );
  }
}

/// 自動ログイン画面
class _AutoSignInScreen extends ConsumerStatefulWidget {
  const _AutoSignInScreen();

  @override
  ConsumerState<_AutoSignInScreen> createState() => _AutoSignInScreenState();
}

class _AutoSignInScreenState extends ConsumerState<_AutoSignInScreen> {
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // 画面表示後に自動ログイン
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _signInAnonymously();
    });
  }

  Future<void> _signInAnonymously() async {
    try {
      await ref.read(authServiceProvider).signInAnonymously();
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '予期しないエラーが発生しました';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _signInAnonymously,
                icon: const Icon(Icons.refresh),
                label: const Text('再試行'),
              ),
            ],
          ),
        ),
      );
    }

    return const _LoadingScreen(message: '認証中...');
  }
}

/// ローディング画面
class _LoadingScreen extends StatelessWidget {
  final String message;

  const _LoadingScreen({this.message = '読み込み中...'});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

/// エラー画面
class _ErrorScreen extends StatelessWidget {
  final Object error;

  const _ErrorScreen({required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'エラーが発生しました',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
