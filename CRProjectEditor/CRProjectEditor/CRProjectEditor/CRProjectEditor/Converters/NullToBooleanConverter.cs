using System;
using System.Globalization;
using System.Windows.Data;

namespace CRProjectEditor.Converters
{
    public class NullToBooleanConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            return value != null;
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            // ConvertBack не используется часто для этого конвертера, но можно реализовать, если нужно
            throw new NotImplementedException();
        }
    }
} 