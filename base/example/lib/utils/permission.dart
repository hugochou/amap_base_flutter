import 'package:permission_handler/permission_handler.dart';

extension PermissionMapActions on Map<Permission, PermissionStatus> {
  bool isGranted() =>
      values.every((element) => element == PermissionStatus.granted);
}
