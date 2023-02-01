import 'dart:developer';
import 'dart:io';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:agora_rtc_rawdata/agora_rtc_rawdata.dart';
import 'package:agora_rtc_rawdata_example/config/agora.config.dart' as config;
import 'package:faceunity_ui/Faceunity_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: HomePage());
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agora Rawdata'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => LivePage()));
                },
                child: const Text('Video')),
          ],
        ),
      ),
    );
  }
}

class LivePage extends StatefulWidget {
  @override
  _LivePageState createState() => _LivePageState();
}

class _LivePageState extends State<LivePage> {
  late RtcEngine engine;
  bool startPreview = false, isJoined = false;
  List<int> remoteUid = [];

  @override
  void initState() {
    super.initState();
    this._initEngine();
  }

  @override
  void dispose() {
    super.dispose();
    this._deinitEngine();
  }

  _initEngine() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      await [Permission.microphone, Permission.camera].request();
    }
    engine = createAgoraRtcEngine();
    await engine.initialize(const RtcEngineContext(
      appId: config.appId,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));
    engine.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
        log('joinChannelSuccess ${connection.channelId} ${connection.localUid} $elapsed');
        setState(() {
          isJoined = true;
        });
      },
      onUserJoined: (RtcConnection connection, int uid, int elapsed) {
        log('userJoined  $remoteUid $elapsed');
        setState(() {
          remoteUid.add(uid);
        });
      },
      onUserOffline:
          (RtcConnection connection, int uid, UserOfflineReasonType reason) {
        log('userJoined  $uid $reason');
        setState(() {
          remoteUid.removeWhere((element) => element == uid);
        });
      },
    ));
    await engine.enableVideo();
    await engine.startPreview();
    setState(() {
      startPreview = true;
    });
    //
    var handle = await engine.getNativeHandle();
    await AgoraRtcRawdata.registerAudioFrameObserver(handle);
    await AgoraRtcRawdata.registerVideoFrameObserver(handle);
    //
    await engine.joinChannel(
      token: config.token,
      channelId: config.channelId,
      uid: config.uid,
      options: ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster),
    );

    //关闭本地声音
    await engine.muteLocalAudioStream(true);
    //关闭远程声音
    await engine.muteAllRemoteAudioStreams(true);

    VideoEncoderConfiguration videoConfig =
        VideoEncoderConfiguration(frameRate: 30);
    await engine.setVideoEncoderConfiguration(videoConfig);
  }

  _deinitEngine() async {
    await AgoraRtcRawdata.unregisterAudioFrameObserver();
    await AgoraRtcRawdata.unregisterVideoFrameObserver();
    await engine.release();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plugin example app'),
      ),
      body: Stack(
        children: [
          if (startPreview)
            AgoraVideoView(
              controller: VideoViewController(
                rtcEngine: engine,
                canvas: const VideoCanvas(uid: 0),
                useFlutterTexture: !Platform.isAndroid,
              ),
            ),
          Align(
            alignment: Alignment.topLeft,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.of(remoteUid.map(
                  (e) => Container(
                      width: 120,
                      height: 120,
                      child: AgoraVideoView(
                        controller: VideoViewController.remote(
                          rtcEngine: engine,
                          canvas: VideoCanvas(uid: e),
                          // localUid 必须要有，不然android显示不出
                          connection: RtcConnection(
                              channelId: config.channelId, localUid: 000),
                          useFlutterTexture: !Platform.isAndroid,
                        ),
                      )),
                )),
              ),
            ),
          ),
          //传camera 回调显示 UI，不传不显示
          FaceunityUI(
            cameraCallback: () => engine.switchCamera(),
          )
        ],
      ),
    );
  }
}
