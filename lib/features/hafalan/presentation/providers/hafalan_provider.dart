import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/hafalan_repository_impl.dart';
import '../../domain/entities/hafalan_materi.dart';
import '../../domain/entities/hafalan_progress.dart';
import '../../domain/repositories/hafalan_repository.dart';

// Repository provider
final hafalanRepositoryProvider = Provider<HafalanRepository>((ref) {
  return HafalanRepositoryImpl();
});

// ==================== MATERI PROVIDERS ====================

// Get all materi
final allMateriProvider = FutureProvider<List<HafalanMateri>>((ref) async {
  final repository = ref.watch(hafalanRepositoryProvider);
  return repository.getAllMateri();
});

// Get materi by type
final materiByTipeProvider = FutureProvider.family<List<HafalanMateri>, String>(
  (ref, tipe) async {
    final repository = ref.watch(hafalanRepositoryProvider);
    return repository.getMateriByTipe(tipe);
  },
);

// Get materi by ID
final materiByIdProvider = FutureProvider.family<HafalanMateri?, String>((
  ref,
  id,
) async {
  final repository = ref.watch(hafalanRepositoryProvider);
  return repository.getMateriById(id);
});

// ==================== PROGRESS PROVIDERS ====================

// Get progress by santri
final progressBySantriProvider =
    FutureProvider.family<List<HafalanProgress>, String>((ref, santriId) async {
      final repository = ref.watch(hafalanRepositoryProvider);
      return repository.getProgressBySantri(santriId);
    });

// Get progress with materi (combined)
final progressWithMateriProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      santriId,
    ) async {
      final repository = ref.watch(hafalanRepositoryProvider);
      return repository.getProgressWithMateri(santriId);
    });

// Get pending confirmations for guru
final pendingConfirmationsProvider = FutureProvider<List<Map<String, dynamic>>>(
  (ref) async {
    final repository = ref.watch(hafalanRepositoryProvider);
    return repository.getPendingConfirmations();
  },
);

// Get statistics by santri
final statisticsBySantriProvider =
    FutureProvider.family<Map<String, int>, String>((ref, santriId) async {
      final repository = ref.watch(hafalanRepositoryProvider);
      return repository.getStatisticsBySantri(santriId);
    });

// ==================== MUTATION PROVIDERS ====================

// State notifier for creating/updating materi
class MateriNotifier extends StateNotifier<AsyncValue<void>> {
  MateriNotifier(this.repository) : super(const AsyncValue.data(null));

  final HafalanRepository repository;

  Future<void> createMateri(HafalanMateri materi) async {
    state = const AsyncValue.loading();
    try {
      await repository.createMateri(materi);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateMateri(HafalanMateri materi) async {
    state = const AsyncValue.loading();
    try {
      await repository.updateMateri(materi);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteMateri(String id) async {
    state = const AsyncValue.loading();
    try {
      await repository.deleteMateri(id);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final materiNotifierProvider =
    StateNotifierProvider<MateriNotifier, AsyncValue<void>>((ref) {
      final repository = ref.watch(hafalanRepositoryProvider);
      return MateriNotifier(repository);
    });

// State notifier for creating/updating progress
class ProgressNotifier extends StateNotifier<AsyncValue<void>> {
  ProgressNotifier(this.repository) : super(const AsyncValue.data(null));

  final HafalanRepository repository;

  Future<void> createProgress(HafalanProgress progress) async {
    state = const AsyncValue.loading();
    try {
      await repository.createProgress(progress);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateProgress(HafalanProgress progress) async {
    state = const AsyncValue.loading();
    try {
      await repository.updateProgress(progress);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteProgress(String id) async {
    state = const AsyncValue.loading();
    try {
      await repository.deleteProgress(id);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // Mulai hafalan (santri)
  Future<void> mulaiHafalan(
    String santriId,
    String santriName,
    String materiId,
  ) async {
    state = const AsyncValue.loading();
    try {
      final progress = HafalanProgress(
        id: '',
        santriId: santriId,
        materiId: materiId,
        santriName: santriName,
        status: 'proses',
        tanggalMulai: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await repository.createProgress(progress);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // Konfirmasi hafalan (guru)
  Future<void> konfirmasiHafalan({
    required String progressId,
    required String santriId,
    required String materiId,
    required String guruId,
    required String guruName,
    required String santriName,
    required int nilai,
    required String status,
    String? catatan,
  }) async {
    state = const AsyncValue.loading();
    try {
      // Get existing progress or create new
      var progress = await repository.getProgressBySantriAndMateri(
        santriId,
        materiId,
      );

      if (progress == null) {
        // Create new progress
        progress = HafalanProgress(
          id: '',
          santriId: santriId,
          santriName: santriName,
          materiId: materiId,
          status: status,
          tanggalMulai: DateTime.now(),
          tanggalSelesai: status == 'selesai' ? DateTime.now() : null,
          guruPengujiId: guruId,
          guruPengujiName: guruName,
          catatan: catatan,
          nilai: nilai,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await repository.createProgress(progress);
      } else {
        // Update existing progress
        final updated = progress.copyWith(
          status: status,
          tanggalSelesai: status == 'selesai'
              ? DateTime.now()
              : progress.tanggalSelesai,
          guruPengujiId: guruId,
          guruPengujiName: guruName,
          catatan: catatan,
          nilai: nilai,
          updatedAt: DateTime.now(),
        );
        await repository.updateProgress(updated);
      }

      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final progressNotifierProvider =
    StateNotifierProvider<ProgressNotifier, AsyncValue<void>>((ref) {
      final repository = ref.watch(hafalanRepositoryProvider);
      return ProgressNotifier(repository);
    });
