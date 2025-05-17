using System;
using System.Globalization;
using System.Windows;
using System.Windows.Data;

namespace CRProjectEditor.Converters
{
    [ValueConversion(typeof(object), typeof(Visibility))]
    public class NullToVisibilityConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            return value == null ? Visibility.Collapsed : Visibility.Visible;
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            // ConvertBack is not used in this scenario, so a simple implementation is sufficient.
            return value is Visibility visibility && visibility == Visibility.Visible;
        }
    }
} 