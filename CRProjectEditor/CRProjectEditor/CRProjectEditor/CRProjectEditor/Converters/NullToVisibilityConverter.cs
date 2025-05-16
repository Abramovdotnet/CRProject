using System;
using System.Globalization;
using System.Windows;
using System.Windows.Data;

namespace CRProjectEditor.Converters
{
    public class NullToVisibilityConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            return value == null ? Visibility.Collapsed : Visibility.Visible;
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            // ConvertBack is not used for this converter, so throw an exception or return DoNothing.
            // For visibility, it typically doesn't make sense to convert back.
            return Binding.DoNothing; // Or throw new NotSupportedException();
        }
    }
} 