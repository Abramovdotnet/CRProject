using CRProjectEditor.Models;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;

namespace CRProjectEditor.Views
{
    public partial class AssetView : UserControl
    {
        public AssetView()
        {
            InitializeComponent();
        }

        private void Asset_MouseDown(object sender, MouseButtonEventArgs e)
        {
            if (e.LeftButton == MouseButtonState.Pressed && sender is FrameworkElement fe && fe.DataContext is AssetDisplayInfo assetInfo)
            {
                DragDrop.DoDragDrop(fe, assetInfo, DragDropEffects.Copy);
            }
        }
    }
} 