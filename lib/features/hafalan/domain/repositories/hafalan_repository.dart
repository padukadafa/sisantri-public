import '../entities/hafalan_materi.dart';
import '../entities/hafalan_progress.dart';

/// Repository interface untuk hafalan
abstract class HafalanRepository {
  // Materi methods
  Future<List<HafalanMateri>> getAllMateri();
  Future<List<HafalanMateri>> getMateriByTipe(String tipe);
  Future<HafalanMateri?> getMateriById(String id);
  Future<void> createMateri(HafalanMateri materi);
  Future<void> updateMateri(HafalanMateri materi);
  Future<void> deleteMateri(String id);

  // Progress methods
  Future<List<HafalanProgress>> getProgressBySantri(String santriId);
  Future<List<HafalanProgress>> getProgressByMateri(String materiId);
  Future<HafalanProgress?> getProgressBySantriAndMateri(
    String santriId,
    String materiId,
  );
  Future<void> createProgress(HafalanProgress progress);
  Future<void> updateProgress(HafalanProgress progress);
  Future<void> deleteProgress(String id);

  // Combined queries
  Future<List<Map<String, dynamic>>> getProgressWithMateri(String santriId);
  Future<List<Map<String, dynamic>>> getPendingConfirmations();

  // Statistics
  Future<Map<String, int>> getStatisticsBySantri(String santriId);
}
