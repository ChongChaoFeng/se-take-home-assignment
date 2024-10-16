import 'dart:async';
import 'order.dart';

class Bot {
  final int id;
  int status; // 1 - IDLE, 2 - WORKING(Processing)
  Order? currentOrder;
  Timer? timer;

  Bot(this.id)
      : status = 1,
        currentOrder = null;
}
