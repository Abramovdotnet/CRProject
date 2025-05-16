using System;
using System.Globalization;
using System.Windows.Data;
using System.Windows.Media;

namespace CRProjectEditor.Converters
{
    public class AlternatingRowBackgroundConverter : IValueConverter
    {
        public Brush? EvenRowBrush { get; set; }
        public Brush? OddRowBrush { get; set; }

        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            if (value is int alternationIndex)
            {
                return alternationIndex % 2 == 0 ? EvenRowBrush : OddRowBrush;
            }
            return Brushes.Transparent; // Или какой-то Brush по умолчанию
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }
} 