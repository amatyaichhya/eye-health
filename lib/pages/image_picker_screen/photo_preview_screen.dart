part of 'image_picker_screen.dart';

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
      showAppToast(
        context,
        'Photo ${removedIndex + 1} removed',
        type: AppToastType.success,
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
                    onPressed: () {
                      widget.onPhotosUpdated(_photos);
                      widget.onDone();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text(
                      'Done',
                      style: TextStyle(color: Colors.white),
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
