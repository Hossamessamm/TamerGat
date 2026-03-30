import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/app_theme.dart';
import '../widgets/modern_legal_content.dart';

/// Full-screen legal document loaded from [assetPath], rendered with structured cards.
class LegalDocumentScreen extends StatefulWidget {
  final String title;
  final String assetPath;

  const LegalDocumentScreen({
    super.key,
    required this.title,
    required this.assetPath,
  });

  @override
  State<LegalDocumentScreen> createState() => _LegalDocumentScreenState();
}

class _LegalDocumentScreenState extends State<LegalDocumentScreen> {
  late Future<String> _future;

  @override
  void initState() {
    super.initState();
    _future = rootBundle.loadString(widget.assetPath);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            color: Colors.white,
            tooltip: 'Back',
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(widget.title),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        body: FutureBuilder<String>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Could not load document.\n${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            final text = snapshot.data ?? '';
            final blocks = buildModernLegalContent(text);

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryColor.withValues(alpha: 0.92),
                            const Color(0xFF1E3A5F),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withValues(alpha: 0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.gavel_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.title,
                                  style: GoogleFonts.notoSans(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'TamerGAT — read the full policy below.',
                                  style: GoogleFonts.notoSans(
                                    color: Colors.white.withValues(alpha: 0.88),
                                    fontSize: 13,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => blocks[index],
                      childCount: blocks.length,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
