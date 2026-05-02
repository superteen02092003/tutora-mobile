enum MessageSender { me, other }

class MockChatMessage {
  const MockChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.time,
  });

  final int id;
  final MessageSender sender;
  final String text;
  final String time;
}

class MockConversation {
  const MockConversation({
    required this.id,
    required this.name,
    required this.subject,
    required this.preview,
    required this.time,
    this.unread = 0,
    this.online = false,
  });

  final int id;
  final String name;
  final String subject;
  final String preview;
  final String time;
  final int unread;
  final bool online;
}

const kTutorConversations = [
  MockConversation(
    id: 1,
    name: 'Minh Anh',
    subject: 'Toán 12',
    preview: 'Thầy ơi buổi chiều thứ 6 có dạy không ạ?',
    time: '09:41',
    unread: 2,
    online: true,
  ),
  MockConversation(
    id: 2,
    name: 'Hoàng Nam',
    subject: 'Lý 11',
    preview: 'Em đã hoàn thành bài tập chương 3 rồi ạ',
    time: 'hôm qua',
  ),
  MockConversation(
    id: 3,
    name: 'Thu Hà',
    subject: 'Hoá 10',
    preview: 'Cảm ơn thầy buổi hôm nay rất hay!',
    time: 'T3',
    online: true,
  ),
  MockConversation(
    id: 4,
    name: 'Quốc Bảo',
    subject: 'Toán 10',
    preview: 'Thầy có thể giải thích lại phần logarit không?',
    time: 'T2',
    unread: 5,
  ),
  MockConversation(
    id: 5,
    name: 'Linh Chi',
    subject: 'Anh văn B2',
    preview: 'Em gửi bài luận để thầy chấm ạ 📎',
    time: 'CN',
  ),
  MockConversation(
    id: 6,
    name: 'Tuấn Kiệt',
    subject: 'Vật lý 12',
    preview: 'OK thầy, em sẽ ôn lại phần dao động',
    time: 'T7',
    online: true,
  ),
];

const kTutorChatMessages = [
  MockChatMessage(
    id: 1,
    sender: MessageSender.other,
    text: 'Thầy ơi, tuần tới thầy có lịch dạy vào buổi sáng thứ 4 không ạ?',
    time: '09:10',
  ),
  MockChatMessage(
    id: 2,
    sender: MessageSender.me,
    text: 'Thứ 4 thầy có buổi 9h–11h, em muốn đặt lịch không?',
    time: '09:12',
  ),
  MockChatMessage(
    id: 3,
    sender: MessageSender.other,
    text: 'Dạ em muốn đặt ạ! Môn Toán 12 chương lượng giác ạ',
    time: '09:13',
  ),
  MockChatMessage(
    id: 4,
    sender: MessageSender.me,
    text: 'OK thầy đã tạo lịch cho em rồi. Em kiểm tra trong mục Lịch học nhé.',
    time: '09:15',
  ),
  MockChatMessage(
    id: 5,
    sender: MessageSender.other,
    text: 'Cảm ơn thầy nhiều ạ 🙏',
    time: '09:15',
  ),
  MockChatMessage(
    id: 6,
    sender: MessageSender.me,
    text: 'Ngoài ra em chuẩn bị trước bài tập trang 87 SGK nhé.',
    time: '09:16',
  ),
  MockChatMessage(
    id: 7,
    sender: MessageSender.other,
    text: 'Dạ thầy ơi buổi chiều thứ 6 có dạy không ạ?',
    time: '09:41',
  ),
];
