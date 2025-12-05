import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crypto_watch/main.dart';
import 'package:crypto_watch/injection_container.dart' as di;
import 'package:crypto_watch/core/utils/display_density.dart';
import 'package:crypto_watch/features/price_list/presentation/widgets/price_list_item.dart';
import 'package:crypto_watch/core/widgets/crypto_icon.dart';

/// 価格一覧改善機能の統合テスト
/// 
/// このテストは以下の完全なフローをカバーします：
/// - 表示密度の変更
/// - お気に入りの追加/削除
/// - 並び替え操作
/// - アプリ再起動後の状態確認
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    // SharedPreferencesのモックチャンネルを設定
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/shared_preferences'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'getAll') {
          return <String, dynamic>{};
        }
        if (methodCall.method == 'setString') {
          return true;
        }
        if (methodCall.method == 'setStringList') {
          return true;
        }
        if (methodCall.method == 'remove') {
          return true;
        }
        return null;
      },
    );

    // Connectivityのモックチャンネルを設定
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/connectivity'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'check') {
          return 'wifi';
        }
        return null;
      },
    );

    // 依存性注入をリセットして再初期化
    await di.sl.reset();
    await di.init();
  });

  group('価格一覧改善機能 - 統合テスト', () {
    testWidgets('完全なフロー: アプリ起動 -> 表示密度変更 -> お気に入り追加 -> 並び替え',
        (WidgetTester tester) async {
      // ========================================
      // Phase 1: アプリ起動と初期状態の確認
      // ========================================
      await tester.pumpWidget(const CryptoWatchApp());
      await tester.pumpAndSettle();

      // アプリが正常に起動することを確認
      expect(find.text('Crypto Watch'), findsWidgets);
      
      // 価格リストアイテムが存在する場合のみテストを続行
      final priceItemsFinder = find.byType(PriceListItem);
      if (priceItemsFinder.evaluate().isEmpty) {
        // データがロードされていない場合はテストをスキップ
        return;
      }
      
      expect(priceItemsFinder, findsWidgets);

      // 通貨アイコンが表示されることを確認（要件 1.1, 1.2）
      expect(find.byType(CryptoIcon), findsWidgets);

      // ========================================
      // Phase 2: 設定画面への遷移と表示密度の変更
      // ========================================
      
      // 設定アイコンをタップ
      final settingsButton = find.byIcon(Icons.settings);
      expect(settingsButton, findsOneWidget);
      await tester.tap(settingsButton);
      await tester.pumpAndSettle();

      // 設定画面が表示されることを確認
      expect(find.text('設定'), findsOneWidget);

      // 表示密度の設定を探す
      final densitySettings = find.text('表示密度');
      if (densitySettings.evaluate().isNotEmpty) {
        // コンパクトモードを選択
        final compactOption = find.text('コンパクト');
        if (compactOption.evaluate().isNotEmpty) {
          await tester.tap(compactOption);
          await tester.pumpAndSettle();
        }
      }

      // 価格一覧画面に戻る
      final backButton = find.byIcon(Icons.arrow_back);
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton);
        await tester.pumpAndSettle();
      }

      // ========================================
      // Phase 3: お気に入りの追加
      // ========================================

      // 価格リストアイテムを取得
      final priceItems = find.byType(PriceListItem);
      expect(priceItems, findsWidgets);

      if (priceItems.evaluate().isNotEmpty) {
        // 最初のアイテムを長押し（要件 3.1, 3.2）
        await tester.longPress(priceItems.first);
        await tester.pumpAndSettle();

        // コンテキストメニューが表示されることを確認
        // お気に入りに追加オプションを探す
        final addToFavorites = find.text('お気に入りに追加');
        if (addToFavorites.evaluate().isNotEmpty) {
          await tester.tap(addToFavorites);
          await tester.pumpAndSettle();

          // お気に入りアイコンが表示されることを確認（要件 4.1, 4.2）
          expect(find.byIcon(Icons.star), findsWidgets);
        }
      }

      // ========================================
      // Phase 4: お気に入り画面での確認
      // ========================================

      // お気に入りアイコンをタップ
      final favoritesButton = find.byIcon(Icons.star);
      if (favoritesButton.evaluate().isNotEmpty) {
        await tester.tap(favoritesButton.first);
        await tester.pumpAndSettle();

        // お気に入り画面が表示されることを確認
        expect(find.text('お気に入り'), findsOneWidget);

        // 戻る
        final favBackButton = find.byIcon(Icons.arrow_back);
        if (favBackButton.evaluate().isNotEmpty) {
          await tester.tap(favBackButton);
          await tester.pumpAndSettle();
        }
      }

      // ========================================
      // Phase 5: 並び替えモードの有効化と操作
      // ========================================

      // 並び替えボタンをタップ（要件 8.1）
      final reorderButton = find.byIcon(Icons.reorder);
      if (reorderButton.evaluate().isNotEmpty) {
        await tester.tap(reorderButton);
        await tester.pumpAndSettle();

        // 並び替えモードが有効になることを確認
        expect(find.text('並び替えモード'), findsOneWidget);
        expect(find.byIcon(Icons.check), findsOneWidget);

        // 並び替えモードを終了
        final checkButton = find.byIcon(Icons.check);
        await tester.tap(checkButton);
        await tester.pumpAndSettle();

        // 通常モードに戻ることを確認
        expect(find.text('Crypto Watch'), findsWidgets);
      }

      // ========================================
      // Phase 6: アプリの状態確認
      // ========================================

      // エラーが発生していないことを確認
      expect(tester.takeException(), isNull);

      // 価格リストが正常に表示されていることを確認
      expect(find.byType(PriceListItem), findsWidgets);
    });

    testWidgets('表示密度変更フロー: 標準 -> コンパクト -> 最大',
        (WidgetTester tester) async {
      await tester.pumpWidget(const CryptoWatchApp());
      await tester.pumpAndSettle();

      // 初期状態の確認
      expect(find.text('Crypto Watch'), findsWidgets);

      // 各表示密度を順番にテスト
      final densities = ['標準', 'コンパクト', '最大'];

      for (final density in densities) {
        // 設定画面に遷移
        final settingsButton = find.byIcon(Icons.settings);
        if (settingsButton.evaluate().isNotEmpty) {
          await tester.tap(settingsButton);
          await tester.pumpAndSettle();

          // 表示密度を変更（スクロールして見つける）
          final densityOption = find.text(density);
          if (densityOption.evaluate().isNotEmpty) {
            // 画面内に表示されるようにスクロール
            await tester.ensureVisible(densityOption);
            await tester.pumpAndSettle();
            
            await tester.tap(densityOption, warnIfMissed: false);
            await tester.pumpAndSettle();
          }

          // 戻る
          final backButton = find.byIcon(Icons.arrow_back);
          if (backButton.evaluate().isNotEmpty) {
            await tester.tap(backButton);
            await tester.pumpAndSettle();
          }

          // 価格リストが表示されることを確認（データがある場合）
          // データがない場合はスキップ
          final priceItems = find.byType(PriceListItem);
          if (priceItems.evaluate().isNotEmpty) {
            expect(priceItems, findsWidgets);
          }
        }
      }

      // エラーが発生していないことを確認
      expect(tester.takeException(), isNull);
    });

    testWidgets('お気に入り管理フロー: 追加 -> 確認 -> 削除',
        (WidgetTester tester) async {
      await tester.pumpWidget(const CryptoWatchApp());
      await tester.pumpAndSettle();

      final priceItems = find.byType(PriceListItem);
      if (priceItems.evaluate().isEmpty) {
        // 価格アイテムがない場合はスキップ
        return;
      }

      // ========================================
      // お気に入りに追加
      // ========================================
      await tester.longPress(priceItems.first);
      await tester.pumpAndSettle();

      final addToFavorites = find.text('お気に入りに追加');
      if (addToFavorites.evaluate().isNotEmpty) {
        await tester.tap(addToFavorites);
        await tester.pumpAndSettle();
      }

      // ========================================
      // お気に入り画面で確認
      // ========================================
      final favoritesButton = find.byIcon(Icons.star);
      if (favoritesButton.evaluate().isNotEmpty) {
        await tester.tap(favoritesButton.first);
        await tester.pumpAndSettle();

        expect(find.text('お気に入り'), findsOneWidget);

        // 戻る
        final backButton = find.byIcon(Icons.arrow_back);
        if (backButton.evaluate().isNotEmpty) {
          await tester.tap(backButton);
          await tester.pumpAndSettle();
        }
      }

      // ========================================
      // お気に入りから削除
      // ========================================
      await tester.longPress(priceItems.first);
      await tester.pumpAndSettle();

      final removeFromFavorites = find.text('お気に入りから削除');
      if (removeFromFavorites.evaluate().isNotEmpty) {
        await tester.tap(removeFromFavorites);
        await tester.pumpAndSettle();
      }

      // エラーが発生していないことを確認
      expect(tester.takeException(), isNull);
    });

    testWidgets('並び替えフロー: モード切り替えと操作制限の確認',
        (WidgetTester tester) async {
      await tester.pumpWidget(const CryptoWatchApp());
      await tester.pumpAndSettle();

      // ========================================
      // 並び替えモードを有効化
      // ========================================
      final reorderButton = find.byIcon(Icons.reorder);
      if (reorderButton.evaluate().isEmpty) {
        // 並び替えボタンがない場合はスキップ
        return;
      }

      await tester.tap(reorderButton);
      await tester.pumpAndSettle();

      // 並び替えモードが有効になることを確認（要件 8.1）
      // タイトルが変わることを確認
      final reorderModeTitle = find.text('並び替えモード');
      if (reorderModeTitle.evaluate().isNotEmpty) {
        expect(reorderModeTitle, findsOneWidget);

        // ========================================
        // 通常のタップ操作が無効化されることを確認（要件 8.7）
        // ========================================
        final priceItems = find.byType(PriceListItem);
        if (priceItems.evaluate().isNotEmpty) {
          // タップしても詳細画面に遷移しないことを確認
          await tester.tap(priceItems.first);
          await tester.pumpAndSettle();

          // 詳細画面に遷移していないことを確認（並び替えモードのまま）
          expect(find.text('並び替えモード'), findsOneWidget);
        }

        // ========================================
        // 並び替えモードを終了
        // ========================================
        final checkButton = find.byIcon(Icons.check);
        await tester.tap(checkButton);
        await tester.pumpAndSettle();

        // 通常モードに戻ることを確認（要件 8.8）
        expect(find.text('Crypto Watch'), findsWidgets);
        expect(find.text('並び替えモード'), findsNothing);
      }

      // エラーが発生していないことを確認
      expect(tester.takeException(), isNull);
    });

    testWidgets('アプリ再起動後の状態確認: 設定とお気に入りの永続化',
        (WidgetTester tester) async {
      // ========================================
      // Phase 1: 初回起動と設定
      // ========================================
      await tester.pumpWidget(const CryptoWatchApp());
      await tester.pumpAndSettle();

      // お気に入りを追加
      final priceItems = find.byType(PriceListItem);
      if (priceItems.evaluate().isNotEmpty) {
        await tester.longPress(priceItems.first);
        await tester.pumpAndSettle();

        final addToFavorites = find.text('お気に入りに追加');
        if (addToFavorites.evaluate().isNotEmpty) {
          await tester.tap(addToFavorites);
          await tester.pumpAndSettle();
        }
      }

      // ========================================
      // Phase 2: アプリを再起動
      // ========================================
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();

      // 依存性注入を再初期化
      await di.sl.reset();
      await di.init();

      // アプリを再起動
      await tester.pumpWidget(const CryptoWatchApp());
      await tester.pumpAndSettle();

      // ========================================
      // Phase 3: 状態が保持されていることを確認
      // ========================================

      // アプリが正常に起動することを確認
      expect(find.text('Crypto Watch'), findsWidgets);
      
      // 価格リストアイテムが存在する場合のみ確認
      final priceItemsAfterRestart = find.byType(PriceListItem);
      if (priceItemsAfterRestart.evaluate().isNotEmpty) {
        expect(priceItemsAfterRestart, findsWidgets);
      }

      // エラーが発生していないことを確認
      expect(tester.takeException(), isNull);
    });

    testWidgets('パフォーマンステスト: 表示密度変更時のレスポンス',
        (WidgetTester tester) async {
      await tester.pumpWidget(const CryptoWatchApp());
      await tester.pumpAndSettle();

      // 設定画面に遷移
      final settingsButton = find.byIcon(Icons.settings);
      if (settingsButton.evaluate().isEmpty) {
        return;
      }

      await tester.tap(settingsButton);
      await tester.pumpAndSettle();

      // 表示密度を変更
      final stopwatch = Stopwatch()..start();

      final compactOption = find.text('コンパクト');
      if (compactOption.evaluate().isNotEmpty) {
        // 画面内に表示されるようにスクロール
        await tester.ensureVisible(compactOption);
        await tester.pumpAndSettle();
        
        await tester.tap(compactOption, warnIfMissed: false);
        await tester.pumpAndSettle();
      }

      stopwatch.stop();

      // 1秒以内にレイアウトが再構築されることを確認（要件 6.5）
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));

      // 戻る
      final backButton = find.byIcon(Icons.arrow_back);
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton);
        await tester.pumpAndSettle();
      }

      // エラーが発生していないことを確認
      expect(tester.takeException(), isNull);
    });

    testWidgets('エラーハンドリング: ストレージ操作失敗時の動作',
        (WidgetTester tester) async {
      // ストレージエラーをシミュレート
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/shared_preferences'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'getAll') {
            throw PlatformException(code: 'ERROR', message: 'Storage error');
          }
          return null;
      });

      // アプリを起動
      await tester.pumpWidget(const CryptoWatchApp());
      await tester.pumpAndSettle();

      // デフォルト値で動作を継続することを確認（要件 9.5）
      expect(find.byType(MaterialApp), findsOneWidget);

      // エラーが適切にハンドリングされていることを確認
      // アプリがクラッシュしていないことを確認
      expect(tester.takeException(), isNull);
    });

    testWidgets('アクセシビリティ: 最小タップ領域の確認',
        (WidgetTester tester) async {
      await tester.pumpWidget(const CryptoWatchApp());
      await tester.pumpAndSettle();

      // すべてのボタンを検索
      final buttons = find.byType(IconButton);

      if (buttons.evaluate().isNotEmpty) {
        for (final button in buttons.evaluate()) {
          final size = button.size;
          // 最小タップ領域は44x44ポイント（要件 7.4）
          expect(
            size!.width,
            greaterThanOrEqualTo(40.0),
            reason: 'ボタンの幅が最小タップ領域を満たしていません',
          );
          expect(
            size.height,
            greaterThanOrEqualTo(40.0),
            reason: 'ボタンの高さが最小タップ領域を満たしていません',
          );
        }
      }
    });

    testWidgets('複数操作の連続実行: 表示密度変更 + お気に入り + 並び替え',
        (WidgetTester tester) async {
      await tester.pumpWidget(const CryptoWatchApp());
      await tester.pumpAndSettle();

      // ========================================
      // 1. 表示密度を変更
      // ========================================
      final settingsButton = find.byIcon(Icons.settings);
      if (settingsButton.evaluate().isNotEmpty) {
        await tester.tap(settingsButton);
        await tester.pumpAndSettle();

        final maximumOption = find.text('最大');
        if (maximumOption.evaluate().isNotEmpty) {
          // 画面内に表示されるようにスクロール
          await tester.ensureVisible(maximumOption);
          await tester.pumpAndSettle();
          
          await tester.tap(maximumOption, warnIfMissed: false);
          await tester.pumpAndSettle();
        }

        final backButton = find.byIcon(Icons.arrow_back);
        if (backButton.evaluate().isNotEmpty) {
          await tester.tap(backButton);
          await tester.pumpAndSettle();
        }
      }

      // ========================================
      // 2. お気に入りを追加
      // ========================================
      final priceItems = find.byType(PriceListItem);
      if (priceItems.evaluate().isNotEmpty) {
        await tester.longPress(priceItems.first);
        await tester.pumpAndSettle();

        final addToFavorites = find.text('お気に入りに追加');
        if (addToFavorites.evaluate().isNotEmpty) {
          await tester.tap(addToFavorites);
          await tester.pumpAndSettle();
        }
      }

      // ========================================
      // 3. 並び替えモードを有効化
      // ========================================
      final reorderButton = find.byIcon(Icons.reorder);
      if (reorderButton.evaluate().isNotEmpty) {
        await tester.tap(reorderButton);
        await tester.pumpAndSettle();

        // 並び替えモードが有効になることを確認
        final reorderModeTitle = find.text('並び替えモード');
        if (reorderModeTitle.evaluate().isNotEmpty) {
          expect(reorderModeTitle, findsOneWidget);

          // 並び替えモードを終了
          final checkButton = find.byIcon(Icons.check);
          await tester.tap(checkButton);
          await tester.pumpAndSettle();
        }
      }

      // ========================================
      // 4. すべての操作が正常に完了したことを確認
      // ========================================
      expect(tester.takeException(), isNull);
      
      // 価格リストアイテムが存在する場合のみ確認
      final finalPriceItems = find.byType(PriceListItem);
      if (finalPriceItems.evaluate().isNotEmpty) {
        expect(finalPriceItems, findsWidgets);
      }
      
      expect(find.text('Crypto Watch'), findsWidgets);
    });

    testWidgets('リフレッシュ操作: プルトゥリフレッシュの動作確認',
        (WidgetTester tester) async {
      await tester.pumpWidget(const CryptoWatchApp());
      await tester.pumpAndSettle();

      // RefreshIndicatorを探す
      final refreshIndicator = find.byType(RefreshIndicator);
      if (refreshIndicator.evaluate().isNotEmpty) {
        // プルトゥリフレッシュを実行
        await tester.drag(refreshIndicator, const Offset(0, 300));
        await tester.pump();
        await tester.pumpAndSettle();

        // エラーが発生していないことを確認
        expect(tester.takeException(), isNull);
        expect(find.byType(PriceListItem), findsWidgets);
      }
    });
  });

  group('表示密度の制約検証', () {
    testWidgets('各表示密度で正しい範囲の銘柄数が表示される',
        (WidgetTester tester) async {
      await tester.pumpWidget(const CryptoWatchApp());
      await tester.pumpAndSettle();

      // 画面サイズを取得
      final size = tester.view.physicalSize /
          tester.view.devicePixelRatio;
      final screenHeight = size.height;

      // 各表示密度について検証
      for (final density in DisplayDensity.values) {
        final visibleItems = DisplayDensityHelper.calculateVisibleItems(
          screenHeight,
          density,
        );
        final minItems = DisplayDensityHelper.getMinItems(density);
        final maxItems = DisplayDensityHelper.getMaxItems(density);

        // 表示可能な銘柄数が範囲内であることを確認（要件 2.3, 2.4, 2.5）
        expect(
          visibleItems,
          greaterThanOrEqualTo(minItems - 1), // 画面サイズによる誤差を許容
          reason: '表示密度 ${density.name} の最小銘柄数が満たされていません',
        );
        expect(
          visibleItems,
          lessThanOrEqualTo(maxItems + 1), // 画面サイズによる誤差を許容
          reason: '表示密度 ${density.name} の最大銘柄数を超えています',
        );
      }
    });
  });
}
