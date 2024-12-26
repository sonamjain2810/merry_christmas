import 'dart:async';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'AdManager/ad_helper.dart';
import 'data/Images.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'data/Strings.dart';
import 'utils/SizeConfig.dart';
import 'utils/pass_data_between_screens.dart';

/*
how to pass data into another screen watch this video
https://www.youtube.com/watch?v=d5PpeNb-dOY
 */

// ignore: must_be_immutable
// ignore: late
class ImageDetailPage extends StatefulWidget {
  int? index;
  ImageDetailPage();
  @override
  _ImageDetailPageState createState() => _ImageDetailPageState();
}

class _ImageDetailPageState extends State<ImageDetailPage> {
  String? type;
  int? defaultIndex;
  
  BannerAd? _bannerAd;

  StreamSubscription? _subscription;

  var filePath;
  var BASE64_IMAGE;

  @override
  void initState() {
    super.initState();
    loadBannerAd().load();
  }

  BannerAd loadBannerAd() {
    return BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _bannerAd = ad as BannerAd;
          });
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('Failed to load a banner ad: ${err.message}');
          ad.dispose();
        },
      ),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
    _bannerAd?.dispose();
  }

  bool visible = false;

  loadProgress() {
    if (visible == true) {
      setState(() {
        visible = false;
      });
    } else {
      setState(() {
        visible = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as PassDataBetweenScreens;
    type = args.title;
    defaultIndex = int.parse(args.message);

    return PageView.builder(
      controller: PageController(
          initialPage: defaultIndex!, keepPage: true, viewportFraction: 1),
      itemBuilder: (context, index) {
        return Scaffold(
          appBar: AppBar(
              title: Text(
            "Image No. ${index + 1}",
            style: Theme.of(context).appBarTheme.toolbarTextStyle,
          )),
          body: SafeArea(
            child: SingleChildScrollView(
              child: Container(
                alignment: Alignment.center,
                margin: EdgeInsets.symmetric(
                    vertical: 1.93 * SizeConfig.widthMultiplier,
                    horizontal: 1.93 * SizeConfig.widthMultiplier),
                child: Card(
                  child: Container(
                      padding:
                          EdgeInsets.all(1.93 * SizeConfig.widthMultiplier),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          CachedNetworkImage(
                            imageUrl: Images.imagesPath[index],
                            placeholder: (context, url) =>
                                const CircularProgressIndicator(),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.error),
                            fadeOutDuration: const Duration(seconds: 1),
                            fadeInDuration: const Duration(seconds: 3),
                          ),
                          Padding(
                            padding: EdgeInsets.all(
                                1.93 * SizeConfig.widthMultiplier),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: <Widget>[
                                Visibility(
                                    maintainSize: true,
                                    maintainAnimation: true,
                                    maintainState: true,
                                    visible: visible,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Text(
                                          "We are downloading your image to share.. \nKeep Patience Thanks!!",
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                        const CircularProgressIndicator(),
                                      ],
                                    )),
                                Builder(builder: (BuildContext context) {
                                  return ElevatedButton(
                                    onPressed: () async {
                                      setState(() {});
                                      loadProgress();
                                      await shareJPGImageFromUrl(
                                          context, index);
                                      loadProgress();
                                    },
                                    child: const Text('Share'),
                                  );
                                })
                              ],
                            ),
                          ),
                        ],
                      )),
                ),
              ),
            ),
          ),
          bottomNavigationBar: BottomAppBar(
            child: _bannerAd != null
                ? SizedBox(
                    width: _bannerAd!.size.width.toDouble(),
                    height: _bannerAd!.size.height.toDouble(),
                    child: AdWidget(
                      ad: _bannerAd!,
                    ),
                  )
                : Container(),
          ),
        );
      },
    );
  }

  Future<void> shareJPGImageFromUrl(BuildContext context, int index) async {
    try {

      var request =
          await HttpClient().getUrl(Uri.parse(Images.imagesPath[index]));
      var response = await request.close();
      Uint8List bytes = await consolidateHttpClientResponseBytes(response);
      final tempDir = await getTemporaryDirectory();
      final path = '${tempDir.path}/image.jpg';
      File(path).writeAsBytesSync(bytes);
      final files = <XFile>[];
      final box = context.findRenderObject() as RenderBox?;
      files.add(XFile(path, name: "image"));

      await Share.shareXFiles([files[0]],
          text:
              "Image Shared with ${Strings.appName}\nDownload App Now: ${Strings.appUrl}",
          subject: "subject",
          sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size);
      //await Share.shareFiles([path]);
    } catch (e) {
      print('error: $e');
    }
  }

  void onImageDowloadButtonPressed() async {
    var response = await http.get(Images.imagesPath[defaultIndex!] as Uri);
    //filePath = await ImagePickerSaver.saveFile(fileData: response.bodyBytes);
  }

  void onImageShareButtonPressed() async {
    var response = await http.get(Images.imagesPath[defaultIndex!] as Uri);
    //filePath = await ImagePickerSaver.saveFile(fileData: response.bodyBytes);
    print(filePath);

    BASE64_IMAGE = filePath;

    final ByteData bytes = await rootBundle.load(BASE64_IMAGE);
    //await Share.file('test.png', bytes, 'my image title');
  }
}
