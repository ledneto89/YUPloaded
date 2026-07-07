import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
static FirebaseOptions get currentPlatform {
if (kIsWeb) {
return web;
}
switch (defaultTargetPlatform) {
case TargetPlatform.android:
return android;
case TargetPlatform.iOS:
return ios;
default:
return web;
}
}

// WEB 
static const FirebaseOptions web = FirebaseOptions(
apiKey: 'AIzaSyCzXrKhVOB3qpYApP1e9exx4Gj40WODkFw',
appId: '1:1008183283303:web:2cbbc0db6723032d060ec2',
messagingSenderId: '1008183283303',
projectId: 'yuploaded-998bb',
storageBucket: 'yuploaded-998bb.firebasestorage.app',
);

// ANDROID 
static const FirebaseOptions android = FirebaseOptions(
apiKey: 'AIzaSyCzXrKhVOB3qpYApP1e9exx4Gj40WODkFw',
appId: '1:1008183283303:android:58c3546b761de5ad060ec2',
messagingSenderId: '1008183283303',
projectId: 'yuploaded-998bb',
storageBucket: 'yuploaded-998bb.firebasestorage.app',
);

// iOS 
static const FirebaseOptions ios = FirebaseOptions(
apiKey: 'AIzaSyCzXrKhVOB3qpYApP1e9exx4Gj40WODkFw',
appId: '1:1008183283303:ios:39f086cd444e50e9060ec2',
messagingSenderId: '1008183283303',
projectId: 'yuploaded-998bb',
storageBucket: 'yuploaded-998bb.firebasestorage.app',
iosBundleId: 'com.yuploaded.app',
);
}
