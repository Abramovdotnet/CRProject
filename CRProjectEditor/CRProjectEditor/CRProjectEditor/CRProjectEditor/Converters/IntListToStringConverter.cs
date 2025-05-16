using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Windows.Data;

namespace CRProjectEditor.Converters
{
    public class IntListToStringConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            if (value is List<int> list && list.Any())
            {
                return string.Join(", ", list);
            }
            return string.Empty; // Возвращаем пустую строку, если список null или пуст
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            // Для отображения обычно не требуется обратное преобразование
            throw new NotImplementedException();
        }
    }
} 