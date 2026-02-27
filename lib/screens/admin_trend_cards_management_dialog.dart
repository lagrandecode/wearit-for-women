import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/trend_card.dart';
import '../services/trend_card_service.dart';
import '../utils/haptic_feedback_helper.dart';
import '../widgets/floating_message.dart';
import '../constants/app_constants.dart';
import 'admin_trend_card_dialog.dart';

class AdminTrendCardsManagementDialog extends StatefulWidget {
  const AdminTrendCardsManagementDialog({super.key});

  @override
  State<AdminTrendCardsManagementDialog> createState() => _AdminTrendCardsManagementDialogState();
}

class _AdminTrendCardsManagementDialogState extends State<AdminTrendCardsManagementDialog> {
  final _trendCardService = TrendCardService();

  Future<void> _deleteCard(TrendCard card) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Card'),
        content: Text('Are you sure you want to delete this trend card?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        HapticFeedbackHelper.tap();
        await _trendCardService.deleteTrendCard(card.id);
        if (mounted) {
          FloatingMessage.show(
            context,
            message: 'Card deleted successfully',
            icon: Icons.check_circle,
            backgroundColor: AppConstants.successColor,
            iconColor: Colors.white,
          );
          HapticFeedbackHelper.mediumImpact();
        }
      } catch (e) {
        if (mounted) {
          FloatingMessage.show(
            context,
            message: 'Error deleting card: $e',
            icon: Icons.error_outline,
            backgroundColor: Colors.red,
            iconColor: Colors.white,
          );
          HapticFeedbackHelper.heavyImpact();
        }
      }
    }
  }

  Future<void> _editCard(TrendCard card) async {
    final result = await showDialog(
      context: context,
      builder: (context) => AdminTrendCardDialog(card: card),
    );

    if (result == true && mounted) {
      FloatingMessage.show(
        context,
        message: 'Card updated successfully',
        icon: Icons.check_circle,
        backgroundColor: AppConstants.successColor,
        iconColor: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Manage Trend Cards',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<List<TrendCard>>(
                stream: _trendCardService.getTrendCards(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  }

                  final cards = snapshot.data ?? [];

                  if (cards.isEmpty) {
                    return Center(
                      child: Text(
                        'No trend cards yet.\nTap + to add one.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.spaceGrotesk(),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: cards.length,
                    itemBuilder: (context, index) {
                      final card = cards[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey.shade200,
                            child: Icon(
                              card.mediaType == 'video'
                                  ? Icons.videocam
                                  : Icons.image,
                            ),
                          ),
                          title: Text(
                            'Card ${index + 1}',
                            style: GoogleFonts.spaceGrotesk(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            card.prompt.length > 50
                                ? '${card.prompt.substring(0, 50)}...'
                                : card.prompt,
                            style: GoogleFonts.spaceGrotesk(fontSize: 12),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Wrap(
                            spacing: 4,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _editCard(card),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteCard(card),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await showDialog(
                  context: context,
                  builder: (context) => const AdminTrendCardDialog(),
                );

                if (result == true && mounted) {
                  FloatingMessage.show(
                    context,
                    message: 'Card added successfully',
                    icon: Icons.check_circle,
                    backgroundColor: AppConstants.successColor,
                    iconColor: Colors.white,
                  );
                }
              },
              icon: const Icon(Icons.add),
              label: Text(
                'Add New Card',
                style: GoogleFonts.spaceGrotesk(
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
