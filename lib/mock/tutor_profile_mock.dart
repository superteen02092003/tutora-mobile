class TutorProfileMock {
  const TutorProfileMock({
    required this.name,
    required this.email,
    required this.phone,
    required this.subjects,
    required this.bio,
    required this.rating,
    required this.reviews,
    required this.verified,
    required this.joined,
    required this.totalSessions,
    required this.totalHours,
    required this.completionRate,
    required this.wallet,
    required this.bank,
    required this.transactions,
  });

  final String name;
  final String email;
  final String phone;
  final List<String> subjects;
  final String bio;
  final double rating;
  final int reviews;
  final bool verified;
  final String joined;
  final int totalSessions;
  final int totalHours;
  final String completionRate;
  final TutorWalletMock wallet;
  final TutorBankMock bank;
  final List<TutorTransactionMock> transactions;
}

class TutorWalletMock {
  const TutorWalletMock({
    required this.available,
    required this.pending,
    required this.thisMonth,
    required this.withdrawn,
  });

  final int available;
  final int pending;
  final int thisMonth;
  final int withdrawn;
}

class TutorBankMock {
  const TutorBankMock({
    required this.bankName,
    required this.accountNumber,
    required this.holder,
    required this.shortCode,
  });

  final String bankName;
  final String accountNumber;
  final String holder;
  final String shortCode;
}

enum TutorTxType { release, withdraw, pending }

class TutorTransactionMock {
  const TutorTransactionMock({
    required this.id,
    required this.type,
    required this.label,
    required this.amount,
    required this.date,
    required this.note,
  });

  final int id;
  final TutorTxType type;
  final String label;
  final int amount;
  final String date;
  final String note;
}

const kTutorProfile = TutorProfileMock(
  name: 'Trần Minh Đức',
  email: 'minhduc.tutor@gmail.com',
  phone: '0987 654 321',
  subjects: ['Toán 12', 'Toán 11', 'Toán 10'],
  bio: 'Giáo viên THPT 8 năm kinh nghiệm, chuyên luyện thi THPT QG môn Toán.',
  rating: 4.9,
  reviews: 128,
  verified: true,
  joined: 'Tháng 1, 2025',
  totalSessions: 128,
  totalHours: 256,
  completionRate: '98%',
  wallet: TutorWalletMock(
    available: 1640000,
    pending: 440000,
    thisMonth: 1200000,
    withdrawn: 800000,
  ),
  bank: TutorBankMock(
    bankName: 'Vietcombank',
    accountNumber: '••••  ••••  4821',
    holder: 'TRAN MINH DUC',
    shortCode: 'VCB',
  ),
  transactions: [
    TutorTransactionMock(
      id: 1,
      type: TutorTxType.release,
      label: 'Giải ngân · Toán 12 (Minh Anh)',
      amount: 400000,
      date: '28/04',
      note: 'Hoàn thành',
    ),
    TutorTransactionMock(
      id: 2,
      type: TutorTxType.release,
      label: 'Giải ngân · Anh B2 (Linh Chi)',
      amount: 500000,
      date: '22/04',
      note: 'Hoàn thành',
    ),
    TutorTransactionMock(
      id: 3,
      type: TutorTxType.pending,
      label: 'Chờ giải ngân · Toán 12',
      amount: 440000,
      date: '02/05',
      note: 'Escrow',
    ),
    TutorTransactionMock(
      id: 4,
      type: TutorTxType.withdraw,
      label: 'Rút về Vietcombank',
      amount: -800000,
      date: '15/04',
      note: 'Thành công',
    ),
    TutorTransactionMock(
      id: 5,
      type: TutorTxType.release,
      label: 'Giải ngân · Lý 11 (Hoàng Nam)',
      amount: 360000,
      date: '10/04',
      note: 'Hoàn thành',
    ),
  ],
);
