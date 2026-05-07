typedef FilterOption = ({String key, String label});

const List<FilterOption> teachingModeOptions = [
  (key: 'online', label: 'Online'),
  (key: 'offline', label: 'Tại nhà'),
  (key: 'hybrid', label: 'Kết hợp'),
];

const List<FilterOption> cityOptions = [
  (key: 'hochiminh', label: 'TP. Hồ Chí Minh'),
  (key: 'hanoi', label: 'Hà Nội'),
  (key: 'danang', label: 'Đà Nẵng'),
  (key: 'cantho', label: 'Cần Thơ'),
  (key: 'haiphong', label: 'Hải Phòng'),
  (key: 'binhduong', label: 'Bình Dương'),
  (key: 'dongnai', label: 'Đồng Nai'),
];

const List<FilterOption> budgetOptions = [
  (key: 'under_50', label: 'Dưới 50k/h'),
  (key: '50_100', label: '50–100k/h'),
  (key: '100_200', label: '100–200k/h'),
  (key: '200_500', label: '200–500k/h'),
  (key: 'over_500', label: 'Trên 500k/h'),
];

const List<FilterOption> sortByOptions = [
  (key: 'rating_desc', label: 'Đánh giá cao nhất'),
  (key: 'price_asc', label: 'Giá thấp nhất'),
  (key: 'price_desc', label: 'Giá cao nhất'),
  (key: 'experience_desc', label: 'Nhiều kinh nghiệm'),
];

const List<double> minRatingOptions = [4.0, 4.5, 4.8];

String filterLabel(List<FilterOption> options, String? key) {
  if (key == null) return '';
  return options
      .firstWhere(
        (o) => o.key == key,
        orElse: () => (key: key, label: key),
      )
      .label;
}
