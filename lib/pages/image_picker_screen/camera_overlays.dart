part of 'image_picker_screen.dart';

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
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 28,
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
                                            color: Color(0xFF6BB3E0),
                                            width: 3,
                                          )
                                          : BorderSide.none,
                                  bottom:
                                      index >= 2
                                          ? const BorderSide(
                                            color: Color(0xFF6BB3E0),
                                            width: 3,
                                          )
                                          : BorderSide.none,
                                  left:
                                      index % 2 == 0
                                          ? const BorderSide(
                                            color: Color(0xFF6BB3E0),
                                            width: 3,
                                          )
                                          : BorderSide.none,
                                  right:
                                      index % 2 == 1
                                          ? const BorderSide(
                                            color: Color(0xFF6BB3E0),
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
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              behavior: HitTestBehavior.opaque,
              child: const SizedBox(
                width: 20,
                height: 20,
                child: Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 20,
                ),
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

