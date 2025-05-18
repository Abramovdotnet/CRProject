using System.Windows.Controls;
using CRProjectEditor.ViewModels;
using System.Windows;
using System.Windows.Input; // Для MouseButtonEventArgs

namespace CRProjectEditor.Views
{
    public partial class NPCsView : UserControl
    {
        public NPCsView()
        {
            InitializeComponent();
        }

        private void NpcsDataGrid_MouseDoubleClick(object sender, MouseButtonEventArgs e)
        {
            // Получаем ViewModel из DataContext
            if (DataContext is NPCsViewModel viewModel)
            {
                // Проверяем, может ли команда выполниться и выполняем ее
                // SelectedNpc уже должен быть установлен благодаря биндингу SelectedItem
                if (viewModel.EditNpcCommand.CanExecute(null))
                {
                    viewModel.EditNpcCommand.Execute(null);
                }
            }
        }
    }
} 