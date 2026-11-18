import 'dart:io';

import 'package:camera/camera.dart';
import 'package:eye_health/pages/image_processing_screen/image_processing_screen.dart';
import 'package:eye_health/pages/image_processing_screen/static_image_processing_screen.dart';
import 'package:eye_health/utils/utility_methods/color_print.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class ImagePickerScreen extends StatefulWidget {
  const ImagePickerScreen({super.key});

  @override
  State<ImagePickerScreen> createState() => _ImagePickerScreenState();
}

class _ImagePickerScreenState extends State<ImagePickerScreen> {
  static const String _screenTitle = 'Capture Fundus Photos';
  static const int _maxPhotos = 1; // Maximum photos allowed
  static const Duration _debounceDelay = Duration(
    milliseconds: 500,
  ); // Debounce delay

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
        _showMessage('Camera not ready');
      }
      return;
    }

    if (_selectedPhotos.length >= _maxPhotos) {
      _showMessage('Maximum $_maxPhotos photos allowed');
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
        _showMessage('Photo ${_selectedPhotos.length} captured!');

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
      _showMessage('Failed to capture photo');
    }
  }

  Future<void> _pickFromGallery() async {
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
        _showMessage('Maximum $_maxPhotos photos already selected');
        return;
      }

      List<XFile> images = [];

      if (remainingSlots == 1) {
        // Use single image picker when only 1 slot remains
        final XFile? image = await _imagePicker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 80,
        );
        if (image != null) {
          images = [image];
        }
      } else {
        // Use multi-image picker when 2 or more slots remain
        images = await _imagePicker.pickMultiImage(
          imageQuality: 80,
          limit: remainingSlots,
        );
      }

      if (images.isNotEmpty) {
        colorPrint('${images.length} images selected from gallery');
        setState(() {
          _selectedPhotos.addAll(images);
          if (_selectedPhotos.length > _maxPhotos) {
            _selectedPhotos = _selectedPhotos.take(_maxPhotos).toList();
          }
          // Show photo management when photos are added
          _showPhotoManagement = true;
        });
        _showMessage('${images.length} photos added!');
      }
    } catch (e) {
      colorPrint('Error picking from gallery: $e');
      _showMessage('Failed to pick images from gallery');
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
    _showMessage('Photo removed');
    HapticFeedback.selectionClick();
  }

  void _previewPhotos() {
    if (!_canPressButton()) return;

    if (_selectedPhotos.isEmpty) {
      _showMessage('No photos to preview');
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
      _showMessage('No photos to process');
      return;
    }

    setState(() {
      _isProcessingDone = true;
    });

    // Navigate to results/processing page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return PhotoProcessingScreen(photos: _selectedPhotos);
          // return StaticImageProcessingScreen(photos: _selectedPhotos);
        },
      ),
    ).then((_) {
      // Reset the flag when returning from processing screen
      if (mounted) {
        setState(() {
          _isProcessingDone = false;
        });
      }
    });
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
                  color: Colors.red,
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
    _showMessage('All photos cleared');
    HapticFeedback.mediumImpact();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
      ),
    );
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

class _TopOverlay extends StatelessWidget {
  final String title;
  final int photoCount;
  final int maxPhotos;
  final VoidCallback onBackPressed;
  final VoidCallback? onClearPressed;
  final VoidCallback? onPhotoCountTap;
  final bool showPhotoManagement;

  const _TopOverlay({
    required this.title,
    required this.photoCount,
    required this.maxPhotos,
    required this.onBackPressed,
    this.onClearPressed,
    this.onPhotoCountTap,
    required this.showPhotoManagement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 20,
        right: 20,
        bottom: 10,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withOpacity(0.7), Colors.transparent],
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBackPressed,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (photoCount > 0)
                  GestureDetector(
                    onTap: onPhotoCountTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            showPhotoManagement
                                ? AppColors.primary
                                : Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            showPhotoManagement
                                ? Icons.visibility
                                : Icons.photo_library,
                            color:
                                showPhotoManagement
                                    ? Colors.white
                                    : Colors.white70,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$photoCount of $maxPhotos photos',
                            style: TextStyle(
                              color:
                                  showPhotoManagement
                                      ? Colors.white
                                      : Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (onPhotoCountTap != null) ...[
                            const SizedBox(width: 4),
                            Icon(
                              showPhotoManagement
                                  ? Icons.keyboard_arrow_down
                                  : Icons.keyboard_arrow_up,
                              color:
                                  showPhotoManagement
                                      ? Colors.white
                                      : Colors.white70,
                              size: 16,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (onClearPressed != null)
            GestureDetector(
              onTap: onClearPressed,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Text(
                  'Clear',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CenterGuidanceOverlay extends StatelessWidget {
  final int photoCount;
  final int maxPhotos;
  final bool showPhotoManagement;

  const _CenterGuidanceOverlay({
    required this.photoCount,
    required this.maxPhotos,
    required this.showPhotoManagement,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Viewfinder frame - show minimal version in photo management mode
          Container(
            width: showPhotoManagement ? 150 : 250,
            height: showPhotoManagement ? 150 : 250,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.white.withOpacity(
                  showPhotoManagement ? 0.3 : 0.8,
                ),
                width: showPhotoManagement ? 1 : 2,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                showPhotoManagement
                    ? null
                    : Stack(
                      children: [
                        // Corner indicators - only show in capture mode
                        ...List.generate(4, (index) {
                          return Positioned(
                            top: index < 2 ? 8 : null,
                            bottom: index >= 2 ? 8 : null,
                            left: index % 2 == 0 ? 8 : null,
                            right: index % 2 == 1 ? 8 : null,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                border: Border(
                                  top:
                                      index < 2
                                          ? const BorderSide(
                                            color: AppColors.primary,
                                            width: 3,
                                          )
                                          : BorderSide.none,
                                  bottom:
                                      index >= 2
                                          ? const BorderSide(
                                            color: AppColors.primary,
                                            width: 3,
                                          )
                                          : BorderSide.none,
                                  left:
                                      index % 2 == 0
                                          ? const BorderSide(
                                            color: AppColors.primary,
                                            width: 3,
                                          )
                                          : BorderSide.none,
                                  right:
                                      index % 2 == 1
                                          ? const BorderSide(
                                            color: AppColors.primary,
                                            width: 3,
                                          )
                                          : BorderSide.none,
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
          ),
          // Guidance text - show different messages based on mode
          if (!showPhotoManagement) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Text(
                _getGuidanceText(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getGuidanceText() {
    if (photoCount == 0) {
      return 'Position the affected area within the frame';
    } else if (photoCount < maxPhotos) {
      return 'Photo ${photoCount} captured - Continue or tap counter to review';
    } else {
      return 'Maximum photos reached - Tap counter to review';
    }
  }
}

class _BottomOverlay extends StatelessWidget {
  final List<XFile> recentImages;
  final List<XFile> selectedPhotos;
  final VoidCallback onGalleryTap;
  final VoidCallback onCaptureTap;
  final VoidCallback onFlipTap;
  final VoidCallback onPreviewTap;
  final Function(int) onRemovePhoto;
  final VoidCallback onDoneTap;
  final bool canFlip;
  final bool canCapture;
  final bool canGallery;
  final bool canDone;
  final bool isCapturing;
  final bool isFlipping;
  final bool isPickingGallery;
  final bool isProcessingDone;
  final bool showPhotoManagement;

  const _BottomOverlay({
    required this.recentImages,
    required this.selectedPhotos,
    required this.onGalleryTap,
    required this.onCaptureTap,
    required this.onFlipTap,
    required this.onPreviewTap,
    required this.onRemovePhoto,
    required this.onDoneTap,
    required this.canFlip,
    required this.canCapture,
    required this.canGallery,
    required this.canDone,
    required this.isCapturing,
    required this.isFlipping,
    required this.isPickingGallery,
    required this.isProcessingDone,
    required this.showPhotoManagement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 20,
        top: 20,
        left: 20,
        right: 20,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black.withOpacity(0.8), Colors.transparent],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Selected photos strip - only show when in photo management mode
          if (showPhotoManagement && selectedPhotos.isNotEmpty) ...[
            _SelectedPhotosStrip(
              selectedPhotos: selectedPhotos,
              onRemovePhoto: onRemovePhoto,
              onPreviewTap: onPreviewTap,
            ),
            const SizedBox(height: 20),
          ],
          // Control buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Gallery Button
              _ControlButton(
                icon: Icons.photo_library,
                label: isPickingGallery ? 'Opening...' : 'Gallery',
                onTap: onGalleryTap,
                enabled: canGallery,
                isLoading: isPickingGallery,
              ),
              // Capture Button
              GestureDetector(
                onTap: canCapture ? onCaptureTap : null,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: canCapture ? Colors.white : Colors.grey,
                    border: Border.all(
                      color: canCapture ? Colors.grey[300]! : Colors.grey[600]!,
                      width: 6,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child:
                      isCapturing
                          ? const SizedBox(
                            width: 30,
                            height: 30,
                            child: CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 3,
                            ),
                          )
                          : Icon(
                            Icons.camera_alt,
                            color: canCapture ? Colors.black : Colors.grey[600],
                            size: 35,
                          ),
                ),
              ),
              // Flip Camera Button
              _ControlButton(
                icon: Icons.flip_camera_ios,
                label: isFlipping ? 'Flipping...' : 'Flip',
                onTap: canFlip ? onFlipTap : () {},
                enabled: canFlip,
                isLoading: isFlipping,
              ),
            ],
          ),
          // Done Button - only show when in photo management mode
          if (showPhotoManagement && selectedPhotos.isNotEmpty) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: canDone ? onDoneTap : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: canDone ? AppColors.primary : Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isProcessingDone) ...[
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Text(
                      isProcessingDone
                          ? 'Processing...'
                          : 'Done (${selectedPhotos.length} photos)',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SelectedPhotosStrip extends StatelessWidget {
  final List<XFile> selectedPhotos;
  final Function(int) onRemovePhoto;
  final VoidCallback onPreviewTap;

  const _SelectedPhotosStrip({
    required this.selectedPhotos,
    required this.onRemovePhoto,
    required this.onPreviewTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Selected Photos (${selectedPhotos.length})',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (selectedPhotos.isNotEmpty)
              GestureDetector(
                onTap: onPreviewTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Text(
                    'Preview All',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: selectedPhotos.length,
            itemBuilder: (context, index) {
              return _SelectedPhotoItem(
                photo: selectedPhotos[index],
                index: index,
                onRemove: () => onRemovePhoto(index),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SelectedPhotoItem extends StatelessWidget {
  final XFile photo;
  final int index;
  final VoidCallback onRemove;

  const _SelectedPhotoItem({
    required this.photo,
    required this.index,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      margin: const EdgeInsets.only(right: 12),
      child: Stack(
        children: [
          // Photo
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(
                File(photo.path),
                fit: BoxFit.cover,
                width: 80,
                height: 80,
              ),
            ),
          ),
          // Photo number
          Positioned(
            top: 4,
            left: 4,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          // Remove button
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1),
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool enabled;
  final bool isLoading;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.enabled = true,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  enabled
                      ? Colors.white.withOpacity(0.2)
                      : Colors.white.withOpacity(0.1),
              border: Border.all(
                color:
                    enabled
                        ? Colors.white.withOpacity(0.3)
                        : Colors.white.withOpacity(0.1),
                width: 2,
              ),
            ),
            child:
                isLoading
                    ? const SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(
                        color: Colors.black,
                        strokeWidth: 3,
                      ),
                    )
                    : Icon(
                      icon,
                      color: enabled ? Colors.white : Colors.white54,
                      size: 28,
                    ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: enabled ? Colors.white : Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _MultiPhotoPreviewScreen extends StatefulWidget {
  final List<XFile> photos;
  final Function(List<XFile>) onPhotosUpdated;
  final VoidCallback onDone;

  const _MultiPhotoPreviewScreen({
    required this.photos,
    required this.onPhotosUpdated,
    required this.onDone,
  });

  @override
  State<_MultiPhotoPreviewScreen> createState() =>
      _MultiPhotoPreviewScreenState();
}

class _MultiPhotoPreviewScreenState extends State<_MultiPhotoPreviewScreen> {
  late PageController _pageController;
  int _currentIndex = 0;
  late List<XFile> _photos;

  @override
  void initState() {
    super.initState();
    _photos = List.from(widget.photos);
    _pageController = PageController();
  }

  void _removeCurrentPhoto() {
    if (_photos.isNotEmpty) {
      _showRemoveConfirmation();
    }
  }

  void _showRemoveConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Remove Photo',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Are you sure you want to remove photo ${_currentIndex + 1}?',
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
                _performRemovePhoto();
              },
              child: const Text('Remove', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _performRemovePhoto() {
    if (_photos.isNotEmpty) {
      final removedIndex = _currentIndex;

      setState(() {
        _photos.removeAt(_currentIndex);

        // Adjust current index after removal
        if (_photos.isEmpty) {
          _currentIndex = 0;
        } else if (_currentIndex >= _photos.length) {
          _currentIndex = _photos.length - 1;
        }
        // If we removed the last photo and there are still photos, stay at the new last photo
        // If we removed a photo in the middle, the next photo will slide into its place
      });

      // Update the parent with the new photo list
      widget.onPhotosUpdated(_photos);

      // Show feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Photo ${removedIndex + 1} removed'),
          backgroundColor: AppColors.primaryDark,
          duration: const Duration(seconds: 2),
        ),
      );

      if (_photos.isEmpty) {
        // No photos left, go back to camera
        Navigator.pop(context);
      } else {
        // Navigate to the appropriate page
        // Use a small delay to ensure the PageView has updated its itemCount
        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted && _pageController.hasClients) {
            _pageController.animateToPage(
              _currentIndex,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_photos.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'No photos to preview',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Photo ${_currentIndex + 1} of ${_photos.length}'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _removeCurrentPhoto,
            icon: const Icon(Icons.delete, color: Colors.red),
          ),
        ],
      ),
      body: Column(
        children: [
          // Photo viewer
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemCount: _photos.length,
              itemBuilder: (context, index) {
                return Center(
                  child: Image.file(
                    File(_photos[index].path),
                    fit: BoxFit.contain,
                  ),
                );
              },
            ),
          ),
          // Photo indicators
          if (_photos.length > 1)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_photos.length, (index) {
                  return Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          index == _currentIndex
                              ? AppColors.primary
                              : Colors.white54,
                    ),
                  );
                }),
              ),
            ),
          // Action buttons
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onPhotosUpdated(_photos);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[600],
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text(
                      'Back to Camera',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: ElevatedButton(
                    onPressed: widget.onDone,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: Text(
                      'Done',
                      style: const TextStyle(color: Colors.white),
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

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
