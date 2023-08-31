// import 'dart:io';
// import 'dart:ui';

// void main() async{
//   // Get the device wallpaper information.
//   WallpaperInfo wallpaperInfo = await WallpaperManager.instance.getWallpaperInfo();

//   // Print the wallpaper information.
//   print('Wallpaper size: ${wallpaperInfo.size}');
//   print('Wallpaper format: ${wallpaperInfo.format}');
//   print('Wallpaper location: ${wallpaperInfo.location}');
// }
import 'dart:typed_data';


String intToIpAddress(int ipInt) {
  return List.generate(4, (index) => ((ipInt >> (index * 8)) & 0xFF).toString())
      .reversed
      .join('.');
}

int ipAddressToInt(String ipAddress) {
  List<String> parts = ipAddress.split('.');
  int result = 0;
  for (int i = 0; i < 4; i++) {
    result += int.parse(parts[i]) * (256 << (i * 8));
  }
  return result;
}

int ipToInt(String ipAddress) {
  List<int> byteList = ipAddress.split('.').map(int.parse).toList();
  ByteData data = ByteData(4);

  for (int i = 0; i < byteList.length; i++) {
    data.setUint8(i, byteList[i]);
  }

  // Apply a mask to ensure the result is positive
  int result = data.getInt32(0) & 0xFFFFFFFF;

  return result;
}

/// Method to convert an int back to the corresponding IP address string
String intToIP(int ipInt) {
  List<int> ipBytesList = [];
  for (int i = 0; i < 4; i++) {
    ipBytesList.add((ipInt >> ((3 - i) * 8)) & 255);
  }
  return ipBytesList.join('.');
}

void main(List<String> args) {
  print(ipToInt("192.168.0.180"));
  print(intToIpAddress(ipToInt("192.168.0.180")));
}
