const modelViewer = document.querySelector('model-viewer');

modelViewer.addEventListener('click', (event) => {
  // Lấy thông tin vị trí click
  // Lưu ý: Việc phát hiện chính xác tên "LivingRoom_Light" rất phức tạp trong WebView
  // nên ở đây ta sẽ bắt sự kiện click vào mô hình và gửi tín hiệu về Flutter.
  
  // Gửi thông báo về Flutter qua kênh tên là "SmartHomeChannel"
  if (SmartHomeChannel) {
    SmartHomeChannel.postMessage('LIVING_ROOM_LIGHT_CLICKED');
  }
});