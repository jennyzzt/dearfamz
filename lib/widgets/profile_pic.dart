import 'dart:io';
import 'package:flutter/material.dart';

/// A reusable widget that displays a user profile picture.
///
/// [radius]: Optional circle avatar radius. Defaults to 50.
/// [selectedImageFile]: Local file if the user picks an image.
/// [photoUrl]: Network image URL if available.
/// [initialLetter]: Fallback letter if neither file nor URL is present.
/// [showCameraIcon]: Whether to show a small camera icon overlay.
/// [onCameraTap]: Callback when the camera icon is pressed.
class ProfilePic extends StatelessWidget {
  final double? radius;
  final File? selectedImageFile;
  final String? photoUrl;
  final String initialLetter;
  final bool showCameraIcon;
  final VoidCallback? onCameraTap;

  const ProfilePic({
    super.key,
    this.radius,
    this.selectedImageFile,
    this.photoUrl,
    required this.initialLetter,
    this.showCameraIcon = false,
    this.onCameraTap,
  });

  @override
  Widget build(BuildContext context) {
    // Use the provided radius or a default of 50
    final double avatarRadius = radius ?? 50.0;

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // 1) If a local image file is picked, show it
        if (selectedImageFile != null)
          CircleAvatar(
            radius: avatarRadius,
            backgroundImage: FileImage(selectedImageFile!),
          )

        // 2) Otherwise, if there's a photoUrl, show the network image
        else if (photoUrl != null && photoUrl!.isNotEmpty)
          CircleAvatar(
            radius: avatarRadius,
            backgroundImage: NetworkImage(photoUrl!),
          )

        // 3) Otherwise, show a circle with the user's initial
        else
          CircleAvatar(
            radius: avatarRadius,
            backgroundColor: Colors.green,
            child: Text(
              initialLetter,
              style: TextStyle(
                fontSize: avatarRadius * 0.6,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

        // 4) If showCameraIcon == true, place a small camera icon
        if (showCameraIcon)
          Positioned(
            bottom: 0,
            right: 0,
            child: InkWell(
              onTap: onCameraTap,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: const Icon(
                  Icons.camera_alt,
                  size: 20,
                  color: Colors.black,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
