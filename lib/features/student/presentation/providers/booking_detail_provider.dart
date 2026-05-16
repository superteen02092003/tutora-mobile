import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/features/student/data/datasources/booking_datasource.dart';

final bookingDetailProvider = FutureProviderFamily<BookingDetailDto, int>((
  ref,
  bookingId,
) async {
  final ds = ref.read(bookingDatasourceProvider);
  return ds.getBookingDetail(bookingId);
});
