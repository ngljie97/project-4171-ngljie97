# CZ4171 - Course Project
## Offloading AI inference from IoT device to the cloud.

## Flutter Android application
The Android application is developed using the Flutter Android framework. It can be used to take photo or select a photo to upload to the server for the image recognition.

### How to use:
The source code can be imported into Android Studio with the Flutter plugin installed and it can be run or compiled into .apk

## Python Server backend
The backend server is coded using Python, together with Flask and RESTful API, to communicate with the Android client. The server upon receiving the image, will perform image prcessing and recognition on the server, and reply with the result of the image recognition. 

### Setting up
Run the start.sh found in the `backend` directory

By Ng Li Jie
