import 'package:flutter/material.dart';

import 'package:sisantri/shared/models/jadwal_model.dart';
import 'kegiatan_header.dart';
import 'kegiatan_empty_state.dart';
import 'kegiatan_list_item.dart';

class DashboardUpcomingKegiatan extends StatelessWidget {
  final List<JadwalModel> kegiatan;

  const DashboardUpcomingKegiatan({super.key, required this.kegiatan});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const KegiatanHeader(),
        const SizedBox(height: 16),
        if (kegiatan.isEmpty)
          const KegiatanEmptyState()
        else
          ...kegiatan.take(3).map((item) => KegiatanListItem(item: item)),
      ],
    );
  }
}
