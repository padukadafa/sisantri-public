import 'package:flutter/material.dart';
import 'package:sisantri/features/shared/announcement/data/models/announcement_model.dart';
import 'package:sisantri/features/shared/announcement/presentation/pages/announcement_detail_page.dart';
import 'announcement_card_header.dart';
import 'announcement_card_content.dart';
import 'announcement_card_chips.dart';
import 'announcement_card_footer.dart';

/// Widget untuk menampilkan card pengumuman individual
class AnnouncementCard extends StatelessWidget {
  final AnnouncementModel pengumuman;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleStatus;

  const AnnouncementCard({
    super.key,
    required this.pengumuman,
    this.onTap,
    this.onDelete,
    this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: pengumuman.isHighPriority ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: pengumuman.isHighPriority
            ? const BorderSide(color: Colors.red, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AnnouncementDetailPage(announcement: pengumuman),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: AnnouncementCardHeader(pengumuman: pengumuman),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      if (value == 'delete' && onDelete != null) {
                        onDelete!();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red, size: 20),
                            SizedBox(width: 8),
                            Text('Hapus'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),

              AnnouncementCardContent(pengumuman: pengumuman),
              const SizedBox(height: 12),

              AnnouncementCardChips(pengumuman: pengumuman),
              const SizedBox(height: 8),

              AnnouncementCardFooter(pengumuman: pengumuman),
            ],
          ),
        ),
      ),
    );
  }
}
