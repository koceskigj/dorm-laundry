import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/achievements_providers.dart';

class GiftFriendCard extends ConsumerWidget {
  const GiftFriendCard({super.key});

  String _prettyError(Object e) {
    if (e is FirebaseException) {
      final msg = e.message ?? 'Unknown Firebase error';
      return '${e.code}: $msg';
    }
    return e.toString().replaceFirst('Exception: ', '');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openGiftDialog(context, ref),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.card_giftcard, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Gift a friend',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openGiftDialog(BuildContext context, WidgetRef ref) async {
    final parentContext = context;

    final emailCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    String? errorText;
    bool loading = false;

    final myEmail = ref.read(myEmailProvider).valueOrNull ?? '';

    await showDialog<void>(
      context: parentContext,
      barrierDismissible: !loading,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setModalState) {
            Future<void> submit() async {
              setModalState(() {
                errorText = null;
                loading = true;
              });

              try {
                final email = emailCtrl.text.trim().toLowerCase();
                final amount = int.tryParse(amountCtrl.text.trim()) ?? -1;

                if (email.isEmpty || !email.contains('@')) {
                  throw Exception('Enter a valid email.');
                }
                if (myEmail.isNotEmpty && email == myEmail.toLowerCase()) {
                  throw Exception('You cannot gift coins to yourself.');
                }
                if (amount <= 0) {
                  throw Exception('Enter a valid amount.');
                }

                final myBalance = ref.read(pointsBalanceProvider);
                if (amount > myBalance) {
                  throw Exception('Not enough Goce coins.');
                }

                await ref.read(coinTransferServiceProvider).transferCoins(
                  recipientEmail: email,
                  amount: amount,
                );

                if (!dialogContext.mounted) return;
                Navigator.of(dialogContext).pop();

                if (!parentContext.mounted) return;
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  SnackBar(content: Text('Gift sent: $amount Goce Coins')),
                );
              } catch (e) {
                if (!dialogContext.mounted) return;
                setModalState(() {
                  errorText = _prettyError(e);
                  loading = false;
                });
              }
            }

            return AlertDialog(
              title: const Text('Gift a friend'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Friend email',
                      hintText: 'friend@example.com',
                    ),
                    enabled: !loading,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      hintText: 'e.g. 20',
                    ),
                    enabled: !loading,
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        errorText!,
                        style: TextStyle(color: Theme.of(dialogContext).colorScheme.error),
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: loading ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: loading ? null : submit,
                  child: loading
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text('Send'),
                ),
              ],
            );
          },
        );
      },
    );

    emailCtrl.dispose();
    amountCtrl.dispose();
  }
}