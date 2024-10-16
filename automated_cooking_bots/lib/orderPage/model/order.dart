class Order {
  final int id; // Increment ID (Unique)
  final int type; // 1 - Normal, 2 - VIP
  int status; // 1 - PENDING, 2 - PROCESSING, 3 - COMPLETE
  Duration processingTime;

  Order(this.id, this.type)
      : status = 1,
        processingTime = Duration(seconds: 10);
}
