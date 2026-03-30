import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../utils/http_client_helper.dart';

/// A widget that loads network images with SSL certificate handling
class SecureNetworkImage extends StatefulWidget {
  final String? imageUrl;
  final BoxFit? fit;
  final AlignmentGeometry? alignment;
  final Widget? placeholder;
  final Widget? errorWidget;
  final double? width;
  final double? height;

  const SecureNetworkImage({
    super.key,
    required this.imageUrl,
    this.fit,
    this.alignment,
    this.placeholder,
    this.errorWidget,
    this.width,
    this.height,
  });

  @override
  State<SecureNetworkImage> createState() => _SecureNetworkImageState();
}

class _SecureNetworkImageState extends State<SecureNetworkImage> {
  Uint8List? _imageData;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(SecureNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    if (widget.imageUrl == null || widget.imageUrl!.isEmpty) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
      _imageData = null;
    });

    try {
      final response = await HttpClientHelper.get(
        Uri.parse(widget.imageUrl!),
      );

      if (response.statusCode == 200) {
        setState(() {
          _imageData = response.bodyBytes;
          _isLoading = false;
          _hasError = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    } catch (e) {
      print('Error loading image: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: widget.placeholder ??
            const Center(
              child: CircularProgressIndicator(),
            ),
      );
    }

    if (_hasError || _imageData == null) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: widget.errorWidget ??
            const Center(
              child: Icon(Icons.error_outline, color: Colors.grey),
            ),
      );
    }

    return Image.memory(
      _imageData!,
      fit: widget.fit,
      alignment: widget.alignment ?? Alignment.center,
      width: widget.width,
      height: widget.height,
    );
  }
}


