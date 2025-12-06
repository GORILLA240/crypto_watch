import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/price_alert.dart';
import '../bloc/alerts_bloc.dart';
import '../bloc/alerts_event.dart';
import '../bloc/alerts_state.dart';
import '../widgets/alert_form.dart';

/// アラート管理画面
class AlertsPage extends StatelessWidget {
  const AlertsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AlertsBloc>(),
      child: const _AlertsPageContent(),
    );
  }
}

class _AlertsPageContent extends StatelessWidget {
  const _AlertsPageContent();

  void _showCreateAlertDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'アラートを作成',
          style: TextStyle(color: Colors.white),
        ),
        content: AlertForm(
          symbol: 'BTC',
          onSubmit: (upperLimit, lowerLimit) {
            final alert = PriceAlert(
              id: const Uuid().v4(),
              symbol: 'BTC',
              upperLimit: upperLimit,
              lowerLimit: lowerLimit,
              isEnabled: true,
              createdAt: DateTime.now(),
            );

            context.read<AlertsBloc>().add(CreateAlertEvent(alert: alert));
            Navigator.of(dialogContext).pop();

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('アラートを作成しました'),
                backgroundColor: Colors.green,
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'アラート',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          iconSize: 20,
          padding: const EdgeInsets.all(8),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: BlocConsumer<AlertsBloc, AlertsState>(
        listener: (context, state) {
          if (state is AlertsTriggered) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${state.triggeredAlerts.length}件のアラートが発火しました',
                ),
                backgroundColor: Colors.orange,
              ),
            );
          }

          if (state is AlertsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          // TODO: アラートリストを表示する実装を追加
          // 現在はプレースホルダーUI
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.notifications_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: const Text(
                      'アラートがありません',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: ElevatedButton.icon(
                      onPressed: () => _showCreateAlertDialog(context),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('アラートを作成'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateAlertDialog(context),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
