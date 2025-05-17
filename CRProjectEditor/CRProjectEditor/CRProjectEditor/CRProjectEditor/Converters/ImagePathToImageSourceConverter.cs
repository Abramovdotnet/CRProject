using System;
using System.Globalization;
using System.IO;
using System.Windows;
using System.Windows.Data;
using System.Windows.Media;
using System.Windows.Media.Imaging;

namespace CRProjectEditor.Converters
{
    public class ImagePathToImageSourceConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            if (value is string imagePath && !string.IsNullOrEmpty(imagePath))
            {
                // The NpcModel.ImagePath should have already verified File.Exists.
                // If it returns a path, we attempt to load it.
                try
                {
                    Uri imageUri = new Uri(imagePath, UriKind.Absolute);
                    BitmapImage bitmapImage = new BitmapImage();
                    bitmapImage.BeginInit();
                    bitmapImage.UriSource = imageUri;
                    bitmapImage.CacheOption = BitmapCacheOption.OnLoad; // Load image immediately
                    bitmapImage.CreateOptions = BitmapCreateOptions.IgnoreImageCache; // Potentially useful for refresh
                    bitmapImage.EndInit();

                    // Check if the image loaded successfully (e.g., has dimensions)
                    if (bitmapImage.PixelHeight > 0 && bitmapImage.PixelWidth > 0)
                    {
                        return bitmapImage;
                    }
                    else
                    {
                        System.Diagnostics.Debug.WriteLine($"[ImagePathToImageSourceConverter] Loaded BitmapImage has zero dimensions for path: {imagePath}");
                        return DependencyProperty.UnsetValue; // Or a specific placeholder ImageSource
                    }
                }
                catch (Exception ex)
                {
                    // This can catch various issues: file not found (if NpcModel didn't check),
                    // access denied, invalid image format, etc.
                    System.Diagnostics.Debug.WriteLine($"[ImagePathToImageSourceConverter] Error loading image from path '{imagePath}': {ex.Message}");
                    return DependencyProperty.UnsetValue; // Return UnsetValue on any error
                }
            }

            // Value is null, not a string, or an empty string
            return DependencyProperty.UnsetValue; // Return UnsetValue for invalid/null input
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        { 
            throw new NotImplementedException();
        }
    }
} 