import 'package:get/get.dart';

class TrierController extends GetxController {
  var isVisible = false.obs;

  void toggleVisibility() {
    isVisible.value = !isVisible.value;
  }
}