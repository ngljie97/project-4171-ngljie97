import 'dart:async';
import 'dart:io';

import 'package:alert_dialog/alert_dialog.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:platform_device_id/platform_device_id.dart';
import 'package:prompt_dialog/prompt_dialog.dart';

const String serverAddress = 'http://192.168.10.113:56733';

Future<void> main() async {
  runApp(
    MaterialApp(
      theme: ThemeData.dark(),
      home: const KetsuHome(),
    ),
  );
}

// A screen that allows users to take a picture using a given camera.
class KetsuHome extends StatefulWidget {
  const KetsuHome({
    Key? key,
  }) : super(key: key);

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<KetsuHome> {
  late Future<String> _serverUp;

  @override
  void initState() {
    super.initState();
    _serverUp = check_server_status();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<String> check_server_status() async {
    var response = await http.get(Uri.parse('$serverAddress/'));

    return response.body;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('KETSU - Select file')),
      // You must wait until the controller is initialized before displaying the
      // camera preview. Use a FutureBuilder to display a loading spinner until the
      // controller has finished initializing.
      body: FutureBuilder<String>(
          future: _serverUp,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return SelectionMenuWidget();
            }
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const <Widget>[
                  SizedBox(
                    width: 360,
                    height: 360,
                    child: CircularProgressIndicator(),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Text(
                      'Connecting to server...',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 38,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
    );
  }
}

class SelectionMenuWidget extends StatelessWidget {
  final ImagePicker _picker = ImagePicker();

  SelectionMenuWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraint) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: IconButton(
                  iconSize: constraint.maxHeight / 3,
                  icon: const Icon(
                    Icons.drive_folder_upload,
                  ),
                  tooltip: 'Choose from file',
                  onPressed: () async {
                    try {
                      final image = await _picker.pickImage(
                          source: ImageSource.gallery,
                          maxHeight: 360,
                          maxWidth: 360,
                          imageQuality: 50);

                      if (image != null) {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ProcessPictureState(
                              // Pass the automatically generated path to
                              // the DisplayPictureScreen widget.
                              imageFile: File(image.path),
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      // If an error occurs, log the error to the console.
                      print(e);
                    }
                  },
                ),
              ),
            ),
            Divider(
              color: Colors.white,
              thickness: 3,
              indent: constraint.maxHeight / 9,
              endIndent: constraint.maxHeight / 9,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: IconButton(
                  iconSize: constraint.maxHeight / 3,
                  icon: const Icon(
                    Icons.camera_alt,
                  ),
                  tooltip: 'Take a picture',
                  onPressed: () async {
                    try {
                      final image = await _picker.pickImage(
                          source: ImageSource.camera,
                          maxHeight: 360,
                          maxWidth: 360,
                          imageQuality: 100);
                      if (image != null) {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ProcessPictureState(
                              // Pass the automatically generated path to
                              // the DisplayPictureScreen widget.
                              imageFile: File(image.path),
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      // If an error occurs, log the error to the console.
                      print(e);
                    }
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// A widget that displays the picture taken by the user.
class ProcessPictureState extends StatelessWidget {
  final File imageFile;

  const ProcessPictureState({
    Key? key,
    required this.imageFile,
  }) : super(key: key);

  static bool isImage(String path) {
    final mimeType = lookupMimeType(path);

    if (mimeType == null) {
      return false;
    } else {
      return mimeType.startsWith('image/');
    }
  }

  static Future<void> addImageToRequest(
      File imageFile, http.MultipartRequest request) async {
    // convert image to bytes
    List<int> fileBytes = [];
    try {
      fileBytes = imageFile.readAsBytesSync();
    } catch (e) {
      print(e);
    }

    // process file meta information
    String? clientDeviceId = await PlatformDeviceId.getDeviceId;
    String fileType = imageFile.path.split('.').last;
    String mimeType = lookupMimeType(imageFile.path)!;

    String fileName = '$clientDeviceId.$fileType';

    var multipartFile = http.MultipartFile.fromBytes(
      'file',
      fileBytes,
      filename: fileName,
      contentType: MediaType.parse(mimeType),
    );

    // add the process image to the request
    request.files.add(multipartFile);
  }

  static Future<String> getImageClassification(File imageFile) async {
    if (isImage(imageFile.path)) {
      // create a http POST request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$serverAddress/Classify'),
      );

      await addImageToRequest(imageFile, request);

      // send the request to server and await response with image recognition result
      final response = await request.send();
      String classification = await response.stream.bytesToString();

      return classification;
    }

    return 'File error!';
  }

  void dispose() {
    imageFile.delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('KETSU - Result')),
      // The image is stored as a file on the device. Use the `Image.file`
      // constructor with the given path to display the image.
      body: FutureBuilder<String>(
        future: getImageClassification(imageFile),
        builder: (context, snapshot) {
          Widget child;
          String displayText;

          if (snapshot.hasData) {
            child = Image.file(imageFile);
            displayText = '${snapshot.data}';
          } else {
            child = const CircularProgressIndicator();
            displayText = 'Awaiting results...';
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                SizedBox(
                  width: 360,
                  height: 360,
                  child: child,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    displayText,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 38,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          String? input = await prompt(
            context,
            title: const Text('What was the photo of?'),
            initialValue: '',
            isSelectedInitialValue: false,
            textOK: const Text('OK'),
            textCancel: const Text('Cancel'),
            validator: (String? value) {
              if (value == null || value.isEmpty) {
                return 'Please enter some text';
              }
              return null;
            },
            textCapitalization: TextCapitalization.words,
            textAlign: TextAlign.center,
          );

          if (input != null) {
            var request = http.MultipartRequest(
              'POST',
              Uri.parse('$serverAddress/Submit'),
            );

            request.fields.addAll({'class_name': input});
            await addImageToRequest(imageFile, request);

            // send the request to server and await response with image recognition result
            final response = await request.send();

            if (response.statusCode == 200) {
              alert(
                context,
                title: const Text('Success!'),
                content: const Text(
                    'Your image has been added successfully to the neural network! Thank you!'),
                textOK: const Text('OK'),
              );
            }
          }
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.announcement),
      ),
    );
  }
}
