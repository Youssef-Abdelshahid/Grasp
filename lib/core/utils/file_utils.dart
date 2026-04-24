import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/app_colors.dart';

class FileUtils {
  FileUtils._();

  static String fileExtension(String fileName) {
    final lastDot = fileName.lastIndexOf('.');
    if (lastDot == -1 || lastDot == fileName.length - 1) {
      return '';
    }
    return fileName.substring(lastDot + 1).toUpperCase();
  }

  static String formatBytes(int bytes) {
    if (bytes <= 0) {
      return '0 B';
    }

    const suffixes = ['B', 'KB', 'MB', 'GB'];
    double value = bytes.toDouble();
    int suffixIndex = 0;

    while (value >= 1024 && suffixIndex < suffixes.length - 1) {
      value /= 1024;
      suffixIndex++;
    }

    final digits = value >= 10 ? 0 : 1;
    return '${value.toStringAsFixed(digits)} ${suffixes[suffixIndex]}';
  }

  static String formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date.toLocal());
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('MMM d, yyyy • h:mm a').format(date.toLocal());
  }

  static IconData iconForExtension(String extension) {
    switch (extension.toUpperCase()) {
      case 'PDF':
        return Icons.picture_as_pdf_rounded;
      case 'PPT':
      case 'PPTX':
        return Icons.slideshow_rounded;
      case 'DOC':
      case 'DOCX':
        return Icons.description_rounded;
      case 'MP4':
      case 'MOV':
      case 'AVI':
        return Icons.video_library_rounded;
      case 'PNG':
      case 'JPG':
      case 'JPEG':
        return Icons.image_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  static Color colorForExtension(String extension) {
    switch (extension.toUpperCase()) {
      case 'PDF':
        return AppColors.rose;
      case 'PPT':
      case 'PPTX':
        return AppColors.amber;
      case 'DOC':
      case 'DOCX':
        return AppColors.cyan;
      case 'MP4':
      case 'MOV':
      case 'AVI':
        return AppColors.violet;
      default:
        return AppColors.primary;
    }
  }
}
