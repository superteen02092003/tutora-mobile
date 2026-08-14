import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/features/student/data/datasources/material_datasource.dart';

/// Tài liệu của một lớp học — tab "Tài liệu" trong chi tiết lớp.
final FutureProviderFamily<List<LearningMaterialDto>, int>
materialListProvider = FutureProvider.family<List<LearningMaterialDto>, int>((
  ref,
  bookingId,
) {
  return ref.read(materialDatasourceProvider).getByBooking(bookingId);
});
