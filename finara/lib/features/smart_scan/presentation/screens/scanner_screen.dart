import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/utils/logger.dart';
import 'package:finara/features/smart_scan/presentation/controllers/scanner_controller.dart';
import 'package:finara/features/smart_scan/domain/upi_parser.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> with WidgetsBindingObserver {
  CameraController? _cameraController;
  final BarcodeScanner _barcodeScanner = BarcodeScanner(formats: [BarcodeFormat.qrCode]);
  
  bool _isCameraInitialized = false;
  bool _isProcessingFrame = false;
  bool _isLoading = false;
  bool _isTakingPicture = false;
  List<CameraDescription> _cameras = [];
  DateTime _lastFrameTime = DateTime.now();
  
  final _log = AppLogger.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _barcodeScanner.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _cameraController;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.stopImageStream();
    } else if (state == AppLifecycleState.resumed) {
      _startImageStream();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        _log.error('No cameras available', null);
        return;
      }

      final camera = _cameras.first;
      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await _cameraController!.initialize();
      if (!mounted) return;

      setState(() {
        _isCameraInitialized = true;
      });

      _startImageStream();
    } catch (e, st) {
      _log.error('Failed to initialize camera', e, st);
    }
  }

  void _startImageStream() {
    if (_cameraController != null && !_cameraController!.value.isStreamingImages) {
      _cameraController!.startImageStream(_processCameraImage);
    }
  }

  void _stopImageStream() {
    if (_cameraController != null && _cameraController!.value.isStreamingImages) {
      _cameraController!.stopImageStream();
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_cameraController == null) return null;
    final camera = _cameras.first;
    final sensorOrientation = camera.sensorOrientation;
    
    final InputImageRotation? rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    if (rotation == null) return null;

    final InputImageFormat? format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null || (Platform.isAndroid && format != InputImageFormat.nv21) || (Platform.isIOS && format != InputImageFormat.bgra8888)) {
      return null;
    }

    if (image.planes.isEmpty) return null;

    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());

    final metadata = InputImageMetadata(
      size: imageSize,
      rotation: rotation,
      format: format,
      bytesPerRow: image.planes[0].bytesPerRow,
    );

    return InputImage.fromBytes(bytes: bytes, metadata: metadata);
  }

  Future<void> _processCameraImage(CameraImage image) async {
    final now = DateTime.now();
    // Throttle ML processing to 2 frames per second to prevent camera preview lag
    if (now.difference(_lastFrameTime).inMilliseconds < 500) return;
    
    if (_isProcessingFrame || _isTakingPicture || _isLoading) return;
    _isProcessingFrame = true;
    _lastFrameTime = now;

    final inputImage = _inputImageFromCameraImage(image);
    if (inputImage == null) {
      _isProcessingFrame = false;
      return;
    }
    
    try {
      final barcodes = await _barcodeScanner.processImage(inputImage);
      if (barcodes.isNotEmpty) {
        final String? code = barcodes.first.rawValue;
        if (code != null && UpiParser.parseUri(code) != null) {
          _log.info('Valid UPI QR Code detected');
          
          _stopImageStream();
          setState(() { _isLoading = true; });
          
          final result = await ref.read(scannerControllerProvider.notifier).processUpiQr(code);
          if (mounted) {
            if (result != null) {
              _log.info('UPI QR processed successfully, draft ID: $result');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Draft saved. Opening UPI app...')),
              );
              context.pop();
              return; 
            } else {
              _log.warning('Failed to parse UPI data');
              setState(() { _isLoading = false; });
              _startImageStream();
            }
          }
        }
      }
    } catch (e, st) {
      _log.error('Error processing camera image for barcode', e, st);
    } finally {
      _isProcessingFrame = false;
    }
  }

  Future<void> _captureReceipt() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    if (_isTakingPicture) return;

    setState(() { _isTakingPicture = true; _isLoading = true; });
    _stopImageStream();

    try {
      _log.info('Shutter button clicked - taking picture');
      final XFile imageFile = await _cameraController!.takePicture();
      _log.info('Picture taken: ${imageFile.path}');

      final result = await ref.read(scannerControllerProvider.notifier).processReceiptImage(imageFile.path);
      if (mounted) {
        if (result != null) {
          _log.info('Receipt image processed successfully, draft ID: $result');
          context.pushReplacement('/add-transaction?editId=$result');
        } else {
          _log.error('Failed to extract data from receipt image', null);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to extract data from image')),
          );
          _startImageStream();
        }
      }
    } catch (e, st) {
      _log.error('Failed to capture receipt', e, st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to take picture')),
        );
        _startImageStream();
      }
    } finally {
      if (mounted) {
        setState(() { _isTakingPicture = false; _isLoading = false; });
      }
    }
  }

  Future<void> _pickImage() async {
    _log.info('Gallery button clicked - picking image for receipt scan');
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null && mounted) {
      _log.info('Image picked: ${image.path}');
      setState(() { _isTakingPicture = true; _isLoading = true; });
      _stopImageStream();
      
      final result = await ref.read(scannerControllerProvider.notifier).processReceiptImage(image.path);
      if (mounted) {
        if (result != null) {
          _log.info('Receipt image processed successfully, draft ID: $result');
          context.pushReplacement('/add-transaction?editId=$result');
        } else {
          _log.error('Failed to extract data from receipt image', null);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to extract data from image')),
          );
          _startImageStream();
        }
      }
      if (mounted) {
        setState(() { _isTakingPicture = false; _isLoading = false; });
      }
    } else {
      _log.info('Image picking cancelled');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Smart Scan', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library, color: Colors.white),
            tooltip: 'Pick Receipt from Gallery',
            onPressed: _isTakingPicture ? null : _pickImage,
          )
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_isCameraInitialized && _cameraController != null)
            CameraPreview(_cameraController!)
          else
            const Center(child: CircularProgressIndicator(color: AppColors.accentViolet)),
            
          SafeArea(
            child: Column(
              children: [
                const Spacer(),
                
                // Instructions
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Point at QR to auto-scan\nor press button to capture receipt',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
                
                // Shutter Button
                Padding(
                  padding: const EdgeInsets.only(bottom: 32.0),
                  child: GestureDetector(
                    onTap: _isTakingPicture ? null : _captureReceipt,
                    child: Container(
                      height: 80,
                      width: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        color: _isTakingPicture ? Colors.grey : Colors.white.withOpacity(0.3),
                      ),
                      child: _isTakingPicture 
                        ? const Padding(
                            padding: EdgeInsets.all(24.0),
                            child: CircularProgressIndicator(color: AppColors.accentViolet),
                          )
                        : const Center(
                            child: Icon(Icons.camera_alt, color: Colors.white, size: 36),
                          ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
