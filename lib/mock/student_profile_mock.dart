class StudentProfileMock {
  const StudentProfileMock({
    required this.name,
    required this.email,
    required this.phone,
    required this.grade,
    required this.school,
    required this.joined,
    required this.totalSessions,
    required this.totalHours,
    required this.tutorCount,
    required this.subjects,
    required this.wallet,
    required this.history,
    required this.transactions,
  });

  final String name;
  final String email;
  final String phone;
  final String grade;
  final String school;
  final String joined;
  final int totalSessions;
  final int totalHours;
  final int tutorCount;
  final List<String> subjects;
  final StudentWalletMock wallet;
  final List<StudentHistoryMock> history;
  final List<StudentTxMock> transactions;
}

class StudentWalletMock {
  const StudentWalletMock({
    required this.balance,
    required this.escrow,
  });

  final int balance;
  final int escrow;
}

class StudentHistoryMock {
  const StudentHistoryMock({
    required this.id,
    required this.tutorName,
    required this.subject,
    required this.date,
    required this.hours,
    required this.amount,
    required this.refunded,
  });

  final int id;
  final String tutorName;
  final String subject;
  final String date;
  final int hours;
  final int amount;
  final bool refunded;
}

enum StudentTxType { topup, escrow, refund }

class StudentTxMock {
  const StudentTxMock({
    required this.id,
    required this.type,
    required this.label,
    required this.amount,
    required this.date,
    required this.method,
  });

  final int id;
  final StudentTxType type;
  final String label;
  final int amount;
  final String date;
  final String method;
}

const kStudentProfile = StudentProfileMock(
  name: 'Nguyễn Minh Anh',
  email: 'minhanh@gmail.com',
  phone: '0912 345 678',
  grade: 'Lớp 12',
  school: 'THPT Gia Định',
  joined: 'Tháng 3, 2026',
  totalSessions: 14,
  totalHours: 28,
  tutorCount: 4,
  subjects: ['Toán', 'Lý', 'Hoá'],
  wallet: StudentWalletMock(balance: 880000, escrow: 440000),
  history: [
    StudentHistoryMock(
      id: 1,
      tutorName: 'Trần Minh Đức',
      subject: 'Toán 12',
      date: '28/4',
      hours: 2,
      amount: 400000,
      refunded: false,
    ),
    StudentHistoryMock(
      id: 2,
      tutorName: 'Lê Thị Hoa',
      subject: 'Lý 11',
      date: '24/4',
      hours: 2,
      amount: 360000,
      refunded: false,
    ),
    StudentHistoryMock(
      id: 3,
      tutorName: 'Phạm Hải Long',
      subject: 'Anh B2',
      date: '20/4',
      hours: 3,
      amount: 750000,
      refunded: false,
    ),
    StudentHistoryMock(
      id: 4,
      tutorName: 'Trần Minh Đức',
      subject: 'Toán 12',
      date: '16/4',
      hours: 2,
      amount: 400000,
      refunded: true,
    ),
  ],
  transactions: [
    StudentTxMock(
      id: 1,
      type: StudentTxType.topup,
      label: 'Nạp tiền ví',
      amount: 1000000,
      date: '01/05',
      method: 'MoMo',
    ),
    StudentTxMock(
      id: 2,
      type: StudentTxType.escrow,
      label: 'Giữ escrow · Toán 12',
      amount: -440000,
      date: '02/05',
      method: 'Escrow',
    ),
    StudentTxMock(
      id: 3,
      type: StudentTxType.refund,
      label: 'Hoàn tiền · Lý 11',
      amount: 360000,
      date: '24/04',
      method: 'Ví',
    ),
    StudentTxMock(
      id: 4,
      type: StudentTxType.escrow,
      label: 'Giữ escrow · Anh B2',
      amount: -750000,
      date: '20/04',
      method: 'Escrow',
    ),
    StudentTxMock(
      id: 5,
      type: StudentTxType.topup,
      label: 'Nạp tiền ví',
      amount: 2000000,
      date: '15/04',
      method: 'VNPay',
    ),
  ],
);
