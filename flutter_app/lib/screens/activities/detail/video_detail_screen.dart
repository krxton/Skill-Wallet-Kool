// lib/screens/video_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/activity.dart';
import '../../../routes/app_routes.dart';

class VideoDetailScreen extends StatelessWidget {
  static const String routeName = '/video_detail';

  static const cream = Color(0xFFFFF5CD);
  static const sky = Color(0xFF0D92F4);
  static const deepGrey = Color(0xFF5D5D5D);

  final Activity activity;

  const VideoDetailScreen({
    super.key,
    required this.activity,
  });

  @override
  Widget build(BuildContext context) {
    final String htmlContent = activity.tiktokHtmlContent ?? '';
    final String videoUrl = activity.videoUrl ?? '';
    final String name = activity.name;
    final String content = activity.content;

    // 🐛 Debug: ตรวจสอบว่ามี content หรือไม่
    debugPrint('🎬 Video Detail Screen - ${activity.name}');
    debugPrint('  - Activity ID: ${activity.id}');
    debugPrint('  - tiktokHtmlContent (raw): ${activity.tiktokHtmlContent}');
    debugPrint(
        '  - htmlContent: ${htmlContent.isNotEmpty ? 'Present (${htmlContent.length} chars)' : 'EMPTY'}');
    debugPrint('  - thumbnailUrl: ${activity.thumbnailUrl ?? 'NULL'}');
    debugPrint('  - videoUrl: $videoUrl');

    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        title: Text(
          name,
          style: GoogleFonts.luckiestGuy(color: Colors.black),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
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

                            // 🚫 กันเด้งออกไป TikTok
                            supportMultipleWindows: false,
                            javaScriptCanOpenWindowsAutomatically: false,

                            disableVerticalScroll: true,
                            disableHorizontalScroll: true,
                            transparentBackground: false,

                            // iOS specific settings
                            allowsBackForwardNavigationGestures: false,
                            allowsLinkPreview: false,
                            isFraudulentWebsiteWarningEnabled: false,

                            // Allow mixed content (HTTP in HTTPS)
                            mixedContentMode:
                                MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,

                            // User agent to help with embed compatibility
                            userAgent:
                                'Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148',
                          ),
                          shouldOverrideUrlLoading:
                              (controller, navigationAction) async {
                            final url = navigationAction.request.url.toString();
                            final isMainFrame = navigationAction.isForMainFrame;

                            // อนุญาตเฉพาะ resources ที่จำเป็นสำหรับ embed
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
                                debugPrint('✅ Allowed: $url');
                                return NavigationActionPolicy.ALLOW;
                              }
                            }

                            // Block ทุก navigation ใน main frame (ป้องกันเด้งออก)
                            if (isMainFrame &&
                                !url.startsWith('data:') &&
                                !url.startsWith('about:')) {
                              debugPrint('🚫 Blocked main frame: $url');
                              return NavigationActionPolicy.CANCEL;
                            }

                            // Block tiktok URLs โดยตรง
                            if (url.contains('tiktok.com/@') ||
                                url.contains('tiktok.com/video') ||
                                url.contains('vm.tiktok.com') ||
                                url.contains('tiktok.com/music')) {
                              debugPrint('🚫 Blocked TikTok URL: $url');
                              return NavigationActionPolicy.CANCEL;
                            }

                            return NavigationActionPolicy.ALLOW;
                          },
                          onCreateWindow:
                              (controller, createWindowAction) async {
                            // Block popup windows
                            debugPrint('🚫 Blocked popup window');
                            return false;
                          },
                          onConsoleMessage: (controller, consoleMessage) {
                            debugPrint(
                              '🖥️ TikTok Console: ${consoleMessage.message}',
                            );
                          },
                        )
                      : _buildVideoPlaceholder(videoUrl),
                ),
              ),
            ),
            // SizedBox(
            //   height: 300,
            //   child: ClipRRect(
            //     borderRadius: BorderRadius.circular(20),
            //     child: htmlContent.isNotEmpty
            //         ? InAppWebView(
            //             initialData: InAppWebViewInitialData(
            //               data: htmlContent,
            //               mimeType: 'text/html',
            //               encoding: 'utf-8',
            //             ),
            //             initialSettings: InAppWebViewSettings(
            //               javaScriptEnabled: true,
            //               transparentBackground: true,
            //               mediaPlaybackRequiresUserGesture: false,
            //               allowsInlineMediaPlayback: true,
            //             ),
            //             onReceivedError: (controller, request, error) {
            //               debugPrint('❌ WebView Error: ${error.description}');
            //             },
            //             onConsoleMessage: (controller, consoleMessage) {
            //               debugPrint('🖥️ WebView Console: ${consoleMessage.message}');
            //             },
            //           )
            //         : _buildVideoPlaceholder(videoUrl),
            //   ),
            // ),
            const SizedBox(height: 24),
            Text(
              'ACTIVITY NAME:',
              style: GoogleFonts.luckiestGuy(fontSize: 18, color: sky),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: sky, width: 1),
              ),
              child: Text(
                name,
                style: GoogleFonts.luckiestGuy(
                  fontSize: 20,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'HOW TO PLAY / INSTRUCTIONS:',
              style: GoogleFonts.luckiestGuy(fontSize: 18, color: sky),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: sky, width: 1),
              ),
              child: Text(
                content,
                style: GoogleFonts.openSans(fontSize: 15, color: Colors.black),
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _buildInfoPill('Category: ${activity.category}', sky),
                _buildInfoPill('Difficulty: ${activity.difficulty}', sky),
                _buildInfoPill('Max Score: ${activity.maxScore}', Colors.green),
              ],
            ),
            const SizedBox(height: 20),
            Row(
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
                    label: Text(
                      'START',
                      style: GoogleFonts.luckiestGuy(fontSize: 20),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: sky,
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
                    label: Text(
                      'ADD',
                      style: GoogleFonts.luckiestGuy(fontSize: 20),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade400,
                      foregroundColor: deepGrey,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        text,
        style: GoogleFonts.openSans(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // 🆕 Placeholder สำหรับกรณีที่ไม่มี TikTok HTML Content
  Widget _buildVideoPlaceholder(String videoUrl) {
    return Container(
      color: deepGrey,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.video_library,
              size: 60, color: Colors.white.withOpacity(0.7)),
          const SizedBox(height: 16),
          Text(
            'Video Preview Not Available',
            style: GoogleFonts.luckiestGuy(color: Colors.white, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          if (videoUrl.isNotEmpty) ...[
            Text(
              'Open in Browser to Watch',
              style: GoogleFonts.openSans(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                final Uri url = Uri.parse(videoUrl);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                } else {
                  debugPrint('❌ Cannot launch URL: $videoUrl');
                }
              },
              icon: const Icon(Icons.open_in_browser, size: 18),
              label: Text('OPEN TIKTOK',
                  style: GoogleFonts.luckiestGuy(fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: deepGrey,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ] else
            Text(
              'No video URL available',
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
  * {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
  }

  html, body {
    background: black;
    width: 100%;
    height: 100%;
    overflow: hidden;
  }

  /* Main container */
  .video-container {
    position: relative;
    width: 100%;
    height: 100%;
    overflow: hidden;
    background: black;
  }

  /* TikTok content - scale up and shift to crop bottom UI elements */
  .tiktok-content {
    position: absolute;
    top: 50%;
    left: 50%;
    /* -42% = เลื่อนวิดีโอลงเพื่อตัดส่วนล่างมากขึ้น, scale 1.3 = ขยายเพื่อตัดขอบมากขึ้น */
    transform: translate(-50%, -42%) scale(1.25);
    width: 100%;
    height: 100%;
  }

  blockquote.tiktok-embed {
    margin: 0 !important;
    padding: 0 !important;
    max-width: 100% !important;
    min-width: 100% !important;
    width: 100% !important;
    height: 100% !important;
    border: none !important;
    background: black !important;
  }

  blockquote.tiktok-embed section {
    display: none !important;
  }

  iframe {
    width: 100% !important;
    height: 100% !important;
    border: none !important;
    display: block !important;
  }

  a, aside {
    display: none !important;
  }

  /* ===== BLOCKERS ===== */

  /* ด้านบน - บังชื่อผู้ใช้/โปรไฟล์ */
  .top-blocker {
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    height: 40%;
    background: linear-gradient(to bottom, rgba(0,0,0,0.9) 0%, transparent 100%);
    z-index: 100;
    pointer-events: auto;
  }

  /* ด้านขวา - บังปุ่ม like/comment/share */
  .right-blocker {
    position: absolute;
    top: 10%;
    right: 0;
    width: 20%;
    height: 75%;
    z-index: 100;
    pointer-events: auto;
  }

  /* ด้านล่าง - บัง description แต่เว้นมุมซ้ายสุดสำหรับปุ่ม replay */
  .bottom-center-blocker {
    position: absolute;
    bottom: 0;
    left: 100%;
    right: 0;
    height: 30%;
    background: linear-gradient(to top, rgba(0,0,0,0.85) 0%, rgba(0,0,0,0.5) 60%, transparent 100%);
    z-index: 100;
    pointer-events: auto;
  }

  /* มุมซ้ายล่าง - เว้นช่องสำหรับปุ่ม replay (pointer-events: none = กดทะลุได้) */
  .replay-area {
    position: absolute;
    bottom: 0;
    left: 0;
    width: 15%;
    height: 25%;
    z-index: 99;
    pointer-events: none;
  }
</style>

<script>
  // Block ทุก link click
  document.addEventListener('click', function(e) {
    const target = e.target;
    if (target.tagName === 'A' || target.closest('a')) {
      e.preventDefault();
      e.stopPropagation();
      return false;
    }
  }, true);

  // Block touch events บน links
  document.addEventListener('touchstart', function(e) {
    const target = e.target;
    if (target.tagName === 'A' || target.closest('a')) {
      e.preventDefault();
      e.stopPropagation();
      return false;
    }
  }, true);

  // ปรับ iframe เมื่อโหลดเสร็จ
  function adjustEmbed() {
    const iframe = document.querySelector('iframe');
    if (iframe) {
      iframe.style.cssText = 'width:100%!important;height:100%!important;border:none!important;';
    }
    // ซ่อน sections
    document.querySelectorAll('section').forEach(s => s.style.display = 'none');
  }

  const observer = new MutationObserver(adjustEmbed);
  observer.observe(document.body, { childList: true, subtree: true });

  setInterval(adjustEmbed, 300);
</script>
</head>

<body>
<div class="video-container">
  <div class="tiktok-content">
$rawHtml
  </div>
  <!-- Blockers -->
  <div class="top-blocker"></div>
  <div class="right-blocker"></div>
  <div class="bottom-center-blocker"></div>
  <div class="replay-area"></div>
</div>
</body>
</html>
''';
}
