import 'dart:io';

import 'package:camera/camera.dart';
import 'package:eye_health/pages/image_processing_screen/image_processing_screen.dart';
import 'package:eye_health/theme/app_theme.dart';
import 'package:eye_health/utils/utility_methods/app_toast.dart';
import 'package:eye_health/utils/utility_methods/color_print.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

part 'camera_overlays.dart';
part 'photo_preview_screen.dart';

class ImagePickerScreen extends StatefulWidget {
  /// When true, opens the system gallery immediately (upload flow).
  final bool openGalleryOnStart;

  /// Max fundus images the user can select / capture.
  final int maxPhotos;

  const ImagePickerScreen({
    super.key,
    this.openGalleryOnStart = false,
    this.maxPhotos = 5,
  });

  @override
  State<ImagePickerScreen> createState() => _ImagePickerScreenState();
}

class _ImagePickerScreenState extends State<ImagePickerScreen> {
  static const String _screenTitle = 'Capture Fundus Photos';
  static const Duration _debounceDelay = Duration(
    milliseconds: 500,
  ); // Debounce delay

  int get _maxPhotos => widget.maxPhotos;

  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  bool _isLoading = true;
  String? _errorMessage;
  int _selectedCameraIndex = 0;
  final ImagePicker _imagePicker = ImagePicker();
  List<XFile> _recentImages = [];
  List<XFile> _selectedPhotos = []; // Store multiple selected photos

  // Debouncing flags
  bool _isCapturing = false;
  bool _isFlipping = false;
  bool _isPickingFromGallery = false;
  bool _isProcessingDone = false;
  DateTime? _lastButtonPress;

  // UI Mode flags
  bool _showPhotoManagement =
      false; // Toggle between clean capture and review mode

  @override
  void initState() {
    super.initState();
    // Set full screen mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _initializeCamera();
    _loadRecentImages();

    if (widget.openGalleryOnStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pickFromGallery(fromUploadEntry: true);
      });
    }
  }

  bool _canPressButton() {
    final now = DateTime.now();
    if (_lastButtonPress != null &&
        now.difference(_lastButtonPress!) < _debounceDelay) {
      return false;
    }
    _lastButtonPress = now;
    return true;
  }

  void _togglePhotoManagement() {
    if (!_canPressButton()) return;

    setState(() {
      _showPhotoManagement = !_showPhotoManagement;
    });
    HapticFeedback.selectionClick();
  }

  Future<void> _initializeCamera() async {
    try {
      // Request camera permission
      final cameraPermission = await Permission.camera.request();
      if (cameraPermission.isDenied) {
        setState(() {
          _errorMessage = 'Camera permission denied';
          _isLoading = false;
        });
        return;
      }

      // Get available cameras
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() {
          _errorMessage = 'No cameras available';
          _isLoading = false;
        });
        return;
      }

      // Initialize camera controller
      _cameraController = CameraController(
        _cameras[_selectedCameraIndex],
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      colorPrint('Camera initialization error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to initialize camera: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadRecentImages() async {
    try {
      final List<XFile> images = [];
      // Note: For a real app, you might want to load actual recent images
      // from the device gallery using a plugin like photo_manager
      setState(() {
        _recentImages = images;
      });
    } catch (e) {
      colorPrint('Error loading recent images: $e');
    }
  }

  Future<void> _flipCamera() async {
    if (!_canPressButton() || _isFlipping || _cameras.length <= 1) {
      return;
    }

    setState(() {
      _isFlipping = true;
      _isLoading = true;
    });

    try {
      await _cameraController?.dispose();

      _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;

      _cameraController = CameraController(
        _cameras[_selectedCameraIndex],
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isFlipping = false;
        });
      }
    } catch (e) {
      colorPrint('Error flipping camera: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to flip camera';
          _isLoading = false;
          _isFlipping = false;
        });
      }
    }
  }

  Future<void> _capturePhoto() async {
    if (!_canPressButton() ||
        _isCapturing ||
        _cameraController == null ||
        !_cameraController!.value.isInitialized) {
      if (_isCapturing) {
        _showMessage('Please wait, capturing photo...');
      } else {
        _showMessage('Camera not ready', type: AppToastType.error);
      }
      return;
    }

    if (_selectedPhotos.length >= _maxPhotos) {
      _showMessage(
        'Maximum $_maxPhotos photos allowed',
        type: AppToastType.error,
      );
      return;
    }

    setState(() {
      _isCapturing = true;
    });

    try {
      final XFile photo = await _cameraController!.takePicture();
      colorPrint('Photo captured: ${photo.path}');

      if (mounted) {
        setState(() {
          _selectedPhotos.add(photo);
          _isCapturing = false;
          // Auto-show photo management after first photo
          if (_selectedPhotos.length == 1) {
            _showPhotoManagement = true;
          }
        });
        _showMessage(
          'Photo ${_selectedPhotos.length} captured!',
          type: AppToastType.success,
        );

        // Add haptic feedback
        HapticFeedback.lightImpact();

        // Debug log
        colorPrint(
          'Photo management mode: $_showPhotoManagement, Photos: ${_selectedPhotos.length}',
        );
      }
    } catch (e) {
      colorPrint('Error capturing photo: $e');
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
      _showMessage('Failed to capture photo', type: AppToastType.error);
    }
  }

  Future<void> _pickFromGallery({bool fromUploadEntry = false}) async {
    if (!_canPressButton() || _isPickingFromGallery) {
      if (_isPickingFromGallery) {
        _showMessage('Please wait, opening gallery...');
      }
      return;
    }

    setState(() {
      _isPickingFromGallery = true;
    });

    try {
      final int remainingSlots = _maxPhotos - _selectedPhotos.length;

      if (remainingSlots <= 0) {
        _showMessage(
          'Maximum $_maxPhotos photos already selected',
          type: AppToastType.error,
        );
        return;
      }

      final List<XFile> images = await _imagePicker.pickMultiImage(
        imageQuality: 80,
        limit: remainingSlots,
      );

      if (images.isNotEmpty) {
        colorPrint('${images.length} images selected from gallery');
        setState(() {
          _selectedPhotos.addAll(images);
          if (_selectedPhotos.length > _maxPhotos) {
            _selectedPhotos = _selectedPhotos.take(_maxPhotos).toList();
          }
          _showPhotoManagement = true;
        });
        final added =
            images.length > remainingSlots ? remainingSlots : images.length;
        _showMessage(
          '$added photo${added == 1 ? '' : 's'} added (max $_maxPhotos)',
          type: AppToastType.success,
        );
      } else if (fromUploadEntry && mounted && _selectedPhotos.isEmpty) {
        Navigator.pop(context);
      }
    } catch (e) {
      colorPrint('Error picking from gallery: $e');
      _showMessage(
        'Failed to pick images from gallery',
        type: AppToastType.error,
      );
      if (fromUploadEntry && mounted && _selectedPhotos.isEmpty) {
        Navigator.pop(context);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPickingFromGallery = false;
        });
      }
    }
  }

  void _removePhoto(int index) {
    if (!_canPressButton()) return;

    setState(() {
      _selectedPhotos.removeAt(index);
      // Hide management if no photos remain
      if (_selectedPhotos.isEmpty) {
        _showPhotoManagement = false;
      }
    });
    _showMessage('Photo removed', type: AppToastType.success);
    HapticFeedback.selectionClick();
  }

  void _previewPhotos() {
    if (!_canPressButton()) return;

    if (_selectedPhotos.isEmpty) {
      _showMessage('No photos to preview', type: AppToastType.error);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => _MultiPhotoPreviewScreen(
              photos: _selectedPhotos,
              onPhotosUpdated: (updatedPhotos) {
                setState(() {
                  _selectedPhotos = updatedPhotos;
                });
              },
              onDone: _proceedWithPhotos,
            ),
      ),
    );
  }

  void _proceedWithPhotos() {
    if (!_canPressButton() || _isProcessingDone) {
      if (_isProcessingDone) {
        _showMessage('Please wait, processing...');
      }
      return;
    }

    if (_selectedPhotos.isEmpty) {
      _showMessage('No photos to process', type: AppToastType.error);
      return;
    }

    setState(() {
      _isProcessingDone = true;
    });

    final photos = List<XFile>.from(_selectedPhotos);

    // Clear picker/preview from the stack so Back returns to home.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => PhotoProcessingScreen(photos: photos),
      ),
      (route) => route.isFirst,
    );
  }

  void _clearAllPhotos() {
    if (!_canPressButton()) return;

    _showClearConfirmation();
  }

  void _showClearConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Clear All Photos',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Are you sure you want to remove all ${_selectedPhotos.length} photos? This action cannot be undone.',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _performClearAllPhotos();
              },
              child: const Text(
                'Clear All',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _performClearAllPhotos() {
    setState(() {
      _selectedPhotos.clear();
      _showPhotoManagement = false; // Hide management when no photos
    });
    _showMessage('All photos cleared', type: AppToastType.success);
    HapticFeedback.mediumImpact();
  }

  void _showMessage(
    String message, {
    AppToastType type = AppToastType.info,
  }) {
    showAppToast(context, message, type: type);
  }

  void _exitFullScreen() {
    if (!_canPressButton()) return;

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    Navigator.pop(context);
  }

  @override
  void dispose() {
    // Restore system UI when leaving
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Full screen camera preview
          Positioned.fill(child: _buildCameraPreview()),
          // Top overlay with back button, title, and photo counter
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _TopOverlay(
              title: _screenTitle,
              photoCount: _selectedPhotos.length,
              maxPhotos: _maxPhotos,
              onBackPressed: _exitFullScreen,
              onClearPressed:
                  _selectedPhotos.isNotEmpty ? _clearAllPhotos : null,
              onPhotoCountTap:
                  _selectedPhotos.isNotEmpty ? _togglePhotoManagement : null,
              showPhotoManagement: _showPhotoManagement,
            ),
          ),
          // Bottom overlay with controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _BottomOverlay(
              recentImages: _recentImages,
              selectedPhotos: _selectedPhotos,
              onGalleryTap: _pickFromGallery,
              onCaptureTap: _capturePhoto,
              onFlipTap: _flipCamera,
              onPreviewTap: _previewPhotos,
              onRemovePhoto: _removePhoto,
              onDoneTap: _proceedWithPhotos,
              canFlip: _cameras.length > 1 && !_isFlipping,
              canCapture: _selectedPhotos.length < _maxPhotos && !_isCapturing,
              canGallery: !_isPickingFromGallery,
              canDone: _selectedPhotos.isNotEmpty && !_isProcessingDone,
              isCapturing: _isCapturing,
              isFlipping: _isFlipping,
              isPickingGallery: _isPickingFromGallery,
              isProcessingDone: _isProcessingDone,
              showPhotoManagement: _showPhotoManagement,
            ),
          ),
          // Center guidance overlay
          if (_isCameraInitialized)
            _CenterGuidanceOverlay(
              photoCount: _selectedPhotos.length,
              maxPhotos: _maxPhotos,
              showPhotoManagement: _showPhotoManagement,
            ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (_isLoading) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (_errorMessage != null) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _initializeCamera,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isCameraInitialized || _cameraController == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Text(
            'Initializing camera...',
            style: TextStyle(color: Colors.white54, fontSize: 18),
          ),
        ),
      );
    }

    // Stack the camera preview with a debug overlay
    return CameraPreview(_cameraController!);
  }
}
