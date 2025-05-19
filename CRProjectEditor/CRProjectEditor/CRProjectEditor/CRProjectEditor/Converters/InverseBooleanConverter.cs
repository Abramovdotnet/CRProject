using System;
using System.Globalization;
using System.Windows.Data;

namespace CRProjectEditor.Converters
{
    public class InverseBooleanConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            if (value is bool boolValue)
            {
                return !boolValue;
            }
            return value; // Or throw new ArgumentException("Value must be a boolean");
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            if (value is bool boolValue)
            {
                return !boolValue;
            }
            return value; // Or throw new ArgumentException("Value must be a boolean");
        }
    }
} 