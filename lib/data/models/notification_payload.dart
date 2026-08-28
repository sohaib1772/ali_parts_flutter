class NotificationPayload {
  final String? id;
  final String? title;
  final String? body;
  final String? type;
  final String? link;
  final String? orderId;

  NotificationPayload({
    this.id,
    this.title,
    this.body,
    this.type,
    this.link,
    this.orderId,
  });

  factory NotificationPayload.fromJson(Map<String, dynamic> json) {
    return NotificationPayload(
      id: json['id'] as String?,
      title: json['title'] as String?,
      body: json['body'] as String?,
      type: json['type'] as String?,
      link: json['link'] as String?,
      orderId: json['order_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'type': type,
    'link': link,
    'order_id': orderId,
  };
}
