// lib/screens/activities/detail/physical_video_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/activity.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/palette.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/info_badges.dart';

class PhysicalVideoScreen extends StatelessWidget {
  static const String routeName = '/video_detail';

  final Activity activity;

  const PhysicalVideoScreen({
    super.key,
    required this.activity,
  });

  @override
  Widget build(BuildContext context) {
    final String htmlContent = activity.tiktokHtmlContent ?? '';
    final String videoUrl = activity.videoUrl ?? '';
    final String name = activity.name;
    final String content = activity.content;

    debugPrint('🎬 Physical Video Screen - ${activity.name}');

    return Scaffold(
      backgroundColor: Palette.cream,
      appBar: AppBar(
        title: Text(name, style: AppTextStyles.heading(22, color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AspectRatio(
                    aspectRatio: 9 / 16,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        color: Colors.black,
                        child: htmlContent.isNotEmpty
                            ? InAppWebView(
                                initialData: InAppWebViewInitialData(
                                  data: buildResponsiveTikTokHtml(htmlContent),
                                  mimeType: 'text/html',
                                  encoding: 'utf-8',
                                ),
                                initialSettings: InAppWebViewSettings(
                                  javaScriptEnabled: true,
                                  mediaPlaybackRequiresUserGesture: false,
                                  allowsInlineMediaPlayback: true,
                                  supportMultipleWindows: false,
                                  javaScriptCanOpenWindowsAutomatically: false,
                                  disableVerticalScroll: true,
                                  disableHorizontalScroll: true,
                                  transparentBackground: false,
                                  allowsBackForwardNavigationGestures: false,
                                  allowsLinkPreview: false,
                                  isFraudulentWebsiteWarningEnabled: false,
                                  mixedContentMode:
                                      MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
                                  userAgent:
                                      'Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148',
                                ),
                                shouldOverrideUrlLoading:
                                    (controller, navigationAction) async {
                                  final url =
                                      navigationAction.request.url.toString();
                                  final isMainFrame =
                                      navigationAction.isForMainFrame;

                                  final allowedPatterns = [
                                    'about:blank',
                                    'embed.js',
                                    'embed.tiktok.com',
                                    'lf16-tiktok',
                                    'musical.ly',
                                    'byteoversea',
                                    'byteimg',
                                    'ibytedtos',
                                  ];

                                  for (final pattern in allowedPatterns) {
                                    if (url.contains(pattern)) {
                                      return NavigationActionPolicy.ALLOW;
                                    }
                                  }

                                  if (isMainFrame &&
                                      !url.startsWith('data:') &&
                                      !url.startsWith('about:')) {
                                    return NavigationActionPolicy.CANCEL;
                                  }

                                  if (url.contains('tiktok.com/@') ||
                                      url.contains('tiktok.com/video') ||
                                      url.contains('vm.tiktok.com') ||
                                      url.contains('tiktok.com/music')) {
                                    return NavigationActionPolicy.CANCEL;
                                  }

                                  return NavigationActionPolicy.ALLOW;
                                },
                                onCreateWindow:
                                    (controller, createWindowAction) async {
                                  return false;
                                },
                              )
                            : _buildVideoPlaceholder(context, videoUrl),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    AppLocalizations.of(context)!.videodetail_activityNameLabel,
                    style: AppTextStyles.heading(18, color: Palette.sky),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Palette.sky, width: 1),
                    ),
                    child: Text(
                      name,
                      style: AppTextStyles.heading(20, color: Colors.black),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    AppLocalizations.of(context)!.videodetail_howToPlayLabel,
                    style: AppTextStyles.heading(18, color: Palette.sky),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Palette.sky, width: 1),
                    ),
                    child: Text(
                      content,
                      style: AppTextStyles.body(15),
                    ),
                  ),
                  const SizedBox(height: 20),
                  InfoBadges(activity: activity),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          // Sticky START/ADD buttons
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            decoration: BoxDecoration(
              color: Palette.cream,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.physicalActivity,
                        arguments: activity,
                      );
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: Text(AppLocalizations.of(context)!.common_start,
                        style: AppTextStyles.heading(20, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Palette.sky,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Implement Add to Diary/Favorite Logic
                    },
                    icon: const Icon(Icons.add_circle_outline),
                    label: Text(AppLocalizations.of(context)!.videodetail_addBtn,
                        style: AppTextStyles.heading(20, color: Palette.deepGrey)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade400,
                      foregroundColor: Palette.deepGrey,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlaceholder(BuildContext context, String videoUrl) {
    return Container(
      color: Palette.deepGrey,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.video_library,
              size: 60, color: Colors.white.withValues(alpha: 0.7)),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.videodetail_previewNotAvailable,
            style: AppTextStyles.heading(16, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          if (videoUrl.isNotEmpty) ...[
            Text(
              AppLocalizations.of(context)!.videodetail_openInBrowser,
              style: GoogleFonts.openSans(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                final Uri url = Uri.parse(videoUrl);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
              icon: const Icon(Icons.open_in_browser, size: 18),
              label: Text(AppLocalizations.of(context)!.videodetail_openTiktok,
                  style: AppTextStyles.heading(14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Palette.deepGrey,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ] else
            Text(
              AppLocalizations.of(context)!.videodetail_noVideoUrl,
              style: GoogleFonts.openSans(color: Colors.white70, fontSize: 12),
            ),
        ],
      ),
    );
  }
}

String buildResponsiveTikTokHtml(String rawHtml) {
  return '''
<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  html, body { background: black; width: 100%; height: 100%; overflow: hidden; }
  .video-container { position: relative; width: 100%; height: 100%; overflow: hidden; background: black; }
  .tiktok-content {
    position: absolute; top: 50%; left: 50%;
    transform: translate(-50%, -42%) scale(1.25);
    width: 100%; height: 100%;
  }
  blockquote.tiktok-embed { margin:0!important; padding:0!important; max-width:100%!important; min-width:100%!important; width:100%!important; height:100%!important; border:none!important; background:black!important; }
  blockquote.tiktok-embed section { display: none !important; }
  iframe { width:100%!important; height:100%!important; border:none!important; display:block!important; }
  a, aside { display: none !important; }
  .top-blocker { position:absolute; top:0; left:0; right:0; height:40%; background:linear-gradient(to bottom, rgba(0,0,0,0.9) 0%, transparent 100%); z-index:100; pointer-events:auto; }
  .right-blocker { position:absolute; top:10%; right:0; width:20%; height:75%; z-index:100; pointer-events:auto; }
  .bottom-center-blocker { position:absolute; bottom:0; left:100%; right:0; height:30%; background:linear-gradient(to top, rgba(0,0,0,0.85) 0%, rgba(0,0,0,0.5) 60%, transparent 100%); z-index:100; pointer-events:auto; }
  .replay-area { position:absolute; bottom:0; left:0; width:15%; height:25%; z-index:99; pointer-events:none; }
</style>
<script>
  document.addEventListener('click', function(e) { const t=e.target; if(t.tagName==='A'||t.closest('a')){e.preventDefault();e.stopPropagation();return false;} }, true);
  document.addEventListener('touchstart', function(e) { const t=e.target; if(t.tagName==='A'||t.closest('a')){e.preventDefault();e.stopPropagation();return false;} }, true);
  function adjustEmbed(){const f=document.querySelector('iframe');if(f)f.style.cssText='width:100%!important;height:100%!important;border:none!important;';document.querySelectorAll('section').forEach(s=>s.style.display='none');}
  const observer=new MutationObserver(adjustEmbed);observer.observe(document.body,{childList:true,subtree:true});
  setInterval(adjustEmbed,300);
</script>
</head>
<body>
<div class="video-container">
  <div class="tiktok-content">$rawHtml</div>
  <div class="top-blocker"></div>
  <div class="right-blocker"></div>
  <div class="bottom-center-blocker"></div>
  <div class="replay-area"></div>
</div>
</body>
</html>
''';
}
